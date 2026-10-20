#!/bin/bash
# Shared helpers for the Docker deployment scripts (sourced, not executed).
#
# Sourced by:
#   deploy/docker/deploy_compose.sh  (via scp'd sibling copy on first deploy)
#   deploy/docker/scripts/{verify,backup,restore,rollback}.sh  (from the repo)
#
# Overridable by the caller: REPO_DIR, ENV_FILE, STATE_DIR, EVENTFLOW_TAG.

: "${REPO_DIR:=/srv/baseify/eventflow/repo}"
: "${ENV_FILE:=/srv/baseify/eventflow/.env}"
: "${STATE_DIR:=/srv/baseify/eventflow}"

COMPOSE_FILE="${REPO_DIR}/deploy/docker/eventflow/docker-compose.yml"

log()  { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*"; }
fail() { printf '[%s] ERROR: %s\n' "$(date +%H:%M:%S)" "$*" >&2; exit 1; }

# The image tag every compose call in this process must use.
#
# deploy_compose.sh and rollback.sh export EVENTFLOW_TAG themselves — they
# know the tag they are switching to and must never be overridden. Everything
# else (verify.sh, restore.sh, backup.sh, cron) resolves to the last
# successfully deployed SHA recorded in ${STATE_DIR}/.current_sha, because the
# .env default (EVENTFLOW_TAG=local) names an image that usually does not
# exist or is stale. Falling back to "local" is only correct when nothing has
# ever been deployed on this host.
eventflow_tag() {
    if [ -z "${EVENTFLOW_TAG:-}" ]; then
        local recorded
        recorded="$(cat "${STATE_DIR}/.current_sha" 2>/dev/null || true)"
        EVENTFLOW_TAG="${recorded:-local}"
        export EVENTFLOW_TAG
    fi
    printf '%s\n' "$EVENTFLOW_TAG"
}

# All compose invocations go through this: external env file (secrets stay
# outside git), pinned file path, EVENTFLOW_TAG resolved by eventflow_tag().
compose() {
    [ -f "$COMPOSE_FILE" ] || fail "compose file not found: $COMPOSE_FILE"
    [ -f "$ENV_FILE" ] || fail "env file not found: $ENV_FILE (run bootstrap_vps.sh)"
    eventflow_tag >/dev/null
    docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" "$@"
}

# ---------------------------------------------------------------------------
# Container registry (GHCR)
# ---------------------------------------------------------------------------
# The application images are BUILT AND PUBLISHED by CI
# (.github/workflows/ci.yml) and PULLED by this host. The VPS never runs
# `docker build` — that is what exhausted the 9.8 GB disk during the
# Next.js build.
#
# The image names below MUST stay in sync with
# deploy/docker/eventflow/docker-compose.yml (guarded by a unit test).

# GitHub account that owns the GHCR packages.
EVENTFLOW_PACKAGE_OWNER="nadeemmx"

# Read one KEY=VALUE from the external env file WITHOUT sourcing it: the
# file holds secrets and is never evaluated as code.
env_file_value() {
    local key="$1" file="${2:-$ENV_FILE}" line
    [ -f "$file" ] || return 1
    line="$(grep -E "^[[:space:]]*${key}=" "$file" | tail -n 1 || true)"
    [ -n "$line" ] || return 1
    line="${line#*=}"
    line="${line%$'\r'}"
    case "$line" in
        \"*\") line="${line#\"}"; line="${line%\"}" ;;
        \'*\') line="${line#\'}"; line="${line%\'}" ;;
    esac
    printf '%s\n' "$line"
}

# Registry host. Shell environment wins over the external env file, which
# wins over the default — the same precedence Compose applies.
EVENTFLOW_REGISTRY="${EVENTFLOW_REGISTRY:-$(env_file_value EVENTFLOW_REGISTRY || echo ghcr.io)}"
APP_IMAGE_BACKEND="${EVENTFLOW_REGISTRY}/${EVENTFLOW_PACKAGE_OWNER}/eventflow-backend"
APP_IMAGE_FRONTEND="${EVENTFLOW_REGISTRY}/${EVENTFLOW_PACKAGE_OWNER}/eventflow-frontend"

# Full image reference (registry + name + deployed tag) of a compose service.
app_image_ref() {
    local service="$1" tag
    tag="$(eventflow_tag)"
    case "$service" in
        backend)  printf '%s:%s\n' "$APP_IMAGE_BACKEND"  "$tag" ;;
        frontend) printf '%s:%s\n' "$APP_IMAGE_FRONTEND" "$tag" ;;
        *) fail "unknown application service: ${service}" ;;
    esac
}

# Registry host of the application images (e.g. ghcr.io).
registry_host() {
    printf '%s\n' "${APP_IMAGE_BACKEND%%/*}"
}

# ---------------------------------------------------------------------------
# Registry authentication
# ---------------------------------------------------------------------------
# GHCR packages are PRIVATE by default (GitHub's default for a first
# publish), so the host normally needs a read credential. Two supported
# setups, in order of preference:
#
#   1. The packages are switched to PUBLIC (Settings → Packages →
#      eventflow-backend → Change visibility → Public). The pull is then
#      anonymous and the VPS holds no registry credential at all.
#      Recommended here: the repository is public and the images contain no
#      secrets (no .env, no keys — see backend/.dockerignore).
#   2. A classic PAT with `read:packages` is stored on the VPS at
#      ${STATE_DIR}/.ghcr-token (mode 0600) and read here through
#      `--password-stdin`, so the token never appears in argv, in a log line
#      or in the process list. That file is the ONLY copy: the login uses an
#      ephemeral DOCKER_CONFIG that is deleted as soon as the pull is done.
#
# A credential that is already in the Docker config (the operator ran
# `docker login ghcr.io` as the deploy user) is used as-is.
EVENTFLOW_REGISTRY_TOKEN_FILE="${EVENTFLOW_REGISTRY_TOKEN_FILE:-${STATE_DIR}/.ghcr-token}"
EVENTFLOW_REGISTRY_USERNAME="${EVENTFLOW_REGISTRY_USERNAME:-${EVENTFLOW_PACKAGE_OWNER}}"

# Log in to the container registry using the token file, if there is one.
# Returns 1 when no token file exists (anonymous pull is then attempted).
registry_login() {
    local host="${1:-$(registry_host)}"
    local token_file="${EVENTFLOW_REGISTRY_TOKEN_FILE}"
    local user="${EVENTFLOW_REGISTRY_USERNAME}"
    local mode tmp token

    [ -f "$token_file" ] || return 1

    mode="$(stat -c '%a' "$token_file" 2>/dev/null || echo '')"
    case "$mode" in
        400|600) : ;;
        '') fail "cannot stat the registry token file ${token_file} — refusing to use it" ;;
        *)  fail "registry token file ${token_file} has mode ${mode}; it must be 0600 (chmod 600) — refusing to use it" ;;
    esac

    # A token file written with `echo`/a heredoc ends in a newline, and
    # `docker login --password-stdin` would send that newline as part of
    # the password (the login would fail with a confusing 401). Strip it.
    token="$(tr -d '\r\n' < "$token_file")"
    [ -n "$token" ] || fail "the registry token file ${token_file} is empty"

    tmp="$(mktemp -d)"
    chmod 700 "$tmp"
    # A previous login in this process left a credential behind — remove it
    # before creating a new one (a retry must not leave two copies).
    if [ -n "${REGISTRY_TMP_CONFIG:-}" ] && [ -d "${REGISTRY_TMP_CONFIG}" ]; then
        rm -rf "${REGISTRY_TMP_CONFIG}"
    fi
    # DOCKER_CONFIG points at the throwaway directory BEFORE the login, so
    # the credential is never written to ~/.docker/config.json.
    export DOCKER_CONFIG="$tmp"
    REGISTRY_TMP_CONFIG="$tmp"
    # The trap removes the directory when the script exits; the variable is
    # expanded when the trap runs, so it always removes the latest one.
    trap 'registry_disconnect' EXIT
    if ! printf '%s' "$token" | docker login "$host" --username "$user" --password-stdin >/dev/null 2>&1; then
        unset token
        registry_disconnect
        fail "registry login to ${host} failed using the credential in ${token_file}"
    fi
    unset token
    log "authenticated to ${host} (credential from ${token_file}, ephemeral docker config)"
    return 0
}

# Drop the ephemeral registry credential again. The token file stays the
# only copy; the throwaway docker config is removed as soon as the pull is
# done (and at the latest when the script exits).
registry_disconnect() {
    local tmp="${REGISTRY_TMP_CONFIG:-}"
    [ -n "$tmp" ] && rm -rf "$tmp"
    REGISTRY_TMP_CONFIG=""
    if [ -n "${DOCKER_CONFIG:-}" ] && [ "${DOCKER_CONFIG}" = "$tmp" ]; then
        unset DOCKER_CONFIG
    fi
    return 0
}

# ---------------------------------------------------------------------------
# Image identity
# ---------------------------------------------------------------------------
# The registry manifest digests docker recorded for a local image
# (e.g. sha256:abc…), one per line. Empty when the image was never pulled
# from a registry.
image_repo_digests() {
    local ref="$1"
    docker image inspect --format '{{range .RepoDigests}}{{println .}}{{end}}' "$ref" 2>/dev/null \
        | sed 's/.*@//' || true
}

# The registry manifest digest docker recorded for a local image
# (e.g. sha256:abc…). Empty when the image was never pulled from a registry.
image_repo_digest() {
    local ref="$1"
    image_repo_digests "$ref" | head -n 1
}

# True when the image carries the given registry digest.
image_has_digest() {
    local ref="$1" expected="$2" d
    [ -n "$expected" ] || return 0
    while read -r d; do
        [ -n "$d" ] || continue
        [ "$d" = "$expected" ] && return 0
    done <<EOF
$(image_repo_digests "$ref")
EOF
    return 1
}

# A single label of a local image ("" when the image has no labels).
image_label() {
    local ref="$1" key="$2" value
    value="$(docker image inspect --format "{{ if .Config.Labels }}{{ index .Config.Labels \"${key}\" }}{{ end }}" "$ref" 2>/dev/null || true)"
    printf '%s\n' "$value"
}

# Prove that a pulled image is the one CI published for this commit.
#   $1 = service (backend|frontend)
#   $2 = expected commit SHA (the image tag)
#   $3 = expected registry digest (optional — set by the deploy workflow
#        from the digest CI recorded; empty means "not available")
verify_image_identity() {
    local service="$1" tag="$2" expected_digest="${3:-}"
    local ref revision digest

    ref="$(app_image_ref "$service")"
    if ! docker image inspect "$ref" >/dev/null 2>&1; then
        fail "image ${ref} is not present after the pull"
    fi

    revision="$(image_label "$ref" "org.opencontainers.image.revision")"
    if [ -z "$revision" ]; then
        # Images published before the GHCR flow carry no revision label.
        log "note: ${ref} has no org.opencontainers.image.revision label — skipping the commit check"
    elif [ "$revision" != "$tag" ]; then
        fail "image ${ref} was built from commit ${revision}, not ${tag} — refusing to run it"
    fi

    if [ -n "$expected_digest" ]; then
        digest="$(image_repo_digest "$ref")"
        if [ -z "$digest" ]; then
            fail "image ${ref} carries no registry digest — it was not pulled from ${EVENTFLOW_REGISTRY}"
        fi
        if ! image_has_digest "$ref" "$expected_digest"; then
            fail "image ${ref} digest ${digest} does not match the digest published by CI (${expected_digest}) — refusing to run it"
        fi
        log "verified ${ref} (digest ${digest})"
    fi
}

# The frontend bundle has the API origin baked in at BUILD time (CI). Verify
# that the pulled image was built with the origin this deployment expects.
#   $1 = "yes" (strict — a mismatch aborts) or "no" (informational).
# A rollback to an older commit may legitimately carry an older origin, so
# the rollback path asks for the informational mode.
verify_frontend_api_origin() {
    local strict="${1:-yes}"
    local expected="${EVENTFLOW_EXPECTED_API_URL:-}"
    local ref baked
    [ -n "$expected" ] || return 0
    ref="$(app_image_ref frontend)"
    baked="$(image_label "$ref" "io.eventflow.next-public-api-url")"
    if [ -z "$baked" ]; then
        log "note: ${ref} has no io.eventflow.next-public-api-url label — skipping the API origin check"
        return 0
    fi
    if [ "$baked" != "$expected" ]; then
        if [ "$strict" = "yes" ]; then
            fail "frontend image ${ref} was built with API origin ${baked}, expected ${expected} — refusing to run it"
        fi
        log "note: frontend image ${ref} carries API origin ${baked} (expected ${expected})"
        return 0
    fi
    log "verified frontend API origin ${baked}"
}

# ---------------------------------------------------------------------------
# Pulling the application images
# ---------------------------------------------------------------------------
# Pull the exact images for a tag. The server never builds.
#   $1 = tag (commit SHA)
#   $2 = "strict" (default) or "allow-legacy-local"
#        strict            — the image MUST come from the registry (deploy)
#        allow-legacy-local — a locally built image of the same commit is
#                             accepted as a fallback (rollback across the
#                             migration from "build on the VPS" to GHCR)
#   $3 = expected backend registry digest (optional; empty = not checked)
#   $4 = expected frontend registry digest (optional; empty = not checked)
#   $5 = "yes"/"no" — strict check of the API origin baked into the frontend
# Returns 0 on success, 1 on failure (the caller decides how to react).
pull_app_images() {
    local tag="${1:-$(eventflow_tag)}"
    local mode="${2:-strict}"
    local expected_backend="${3:-}"
    local expected_frontend="${4:-}"
    local strict_api="${5:-yes}"
    local output svc pulled=1

    export EVENTFLOW_TAG="$tag"

    if output="$(compose pull backend frontend 2>&1)"; then
        log "pulled ${APP_IMAGE_BACKEND}:${tag} and ${APP_IMAGE_FRONTEND}:${tag}"
    else
        log "registry pull failed: $(printf '%s' "$output" | tail -n 3 | tr '\n' ' ')"
        pulled=0
        # A private package needs a credential: try the token file (if any)
        # and pull again. The retry is what makes a private package work —
        # its success must be honoured (a successful retry used to fall
        # through into the failure branch below and aborted the deploy).
        if registry_login "$(registry_host)"; then
            if output="$(compose pull backend frontend 2>&1)"; then
                log "pulled ${APP_IMAGE_BACKEND}:${tag} and ${APP_IMAGE_FRONTEND}:${tag} (after authenticating to ${EVENTFLOW_REGISTRY})"
                pulled=1
            else
                output="$(printf '%s' "$output" | tail -n 5)"
            fi
        else
            output="$(printf '%s' "$output" | tail -n 5)"
        fi

        if [ "$pulled" != "1" ]; then
            if [ "$mode" = "allow-legacy-local" ] && retag_legacy_images "$tag"; then
                log "using the locally built images of ${tag} (not available in the registry)"
            else
                printf '%s\n' "$output" >&2
                log "could not pull the application images for ${tag} from ${EVENTFLOW_REGISTRY}."
                log "If the package is private, give the deploy user read access:"
                log "  * make the GHCR package public (Settings → Packages → eventflow-backend → Change visibility → Public), or"
                log "  * store a classic PAT with 'read:packages' at ${EVENTFLOW_REGISTRY_TOKEN_FILE} (mode 0600, owner ${EVENTFLOW_REGISTRY_USERNAME})."
                return 1
            fi
        fi
    fi

    for svc in backend frontend; do
        case "$svc" in
            backend)  verify_image_identity backend  "$tag" "$expected_backend" ;;
            frontend) verify_image_identity frontend "$tag" "$expected_frontend" ;;
        esac
    done
    verify_frontend_api_origin "$strict_api"
    # The images are local now — drop the ephemeral registry credential
    # again (the token file stays the only copy).
    registry_disconnect
    return 0
}

# Re-tag the images that were BUILT on this host before the GHCR flow, so a
# rollback across the migration still finds them. Only the exact tag is
# touched; nothing is deleted.
retag_legacy_images() {
    local tag="$1" svc legacy found=0
    for svc in backend frontend; do
        case "$svc" in
            backend)  legacy="eventflow-backend" ;;
            frontend) legacy="eventflow-frontend" ;;
        esac
        if docker image inspect "${legacy}:${tag}" >/dev/null 2>&1; then
            docker tag "${legacy}:${tag}" "$(app_image_ref "$svc")" >/dev/null 2>&1 || true
            log "re-tagged the local image ${legacy}:${tag} as $(app_image_ref "$svc")"
            found=1
        fi
    done
    [ "$found" = "1" ]
}

# ---------------------------------------------------------------------------
# Disk space
# ---------------------------------------------------------------------------
# Free space (MB) on the filesystem that holds the Docker data.
docker_free_mb() {
    local dir
    dir="$(docker info --format '{{.DockerRootDir}}' 2>/dev/null || echo /var/lib/docker)"
    df -Pm "$dir" 2>/dev/null | awk 'NR==2 {print $4}'
}

# Make sure there is room for the pull. The build cache is dead weight now
# that images are pulled instead of built, so it is reclaimed — but ONLY
# when the disk is tight. Never touches images, containers or volumes.
ensure_free_space() {
    local need_mb="${1:-1024}" free
    free="$(docker_free_mb)"
    [ -n "$free" ] || return 0
    if [ "$free" -ge "$need_mb" ]; then
        log "docker filesystem: ${free} MB free"
        return 0
    fi
    log "docker filesystem has only ${free} MB free — reclaiming the (now unused) build cache"
    docker builder prune -f >/dev/null 2>&1 || log "note: 'docker builder prune' failed — continuing"
    free="$(docker_free_mb)"
    if [ -n "$free" ] && [ "$free" -lt 512 ]; then
        fail "only ${free} MB free on the Docker filesystem — the image pull cannot succeed. Free space (df -h /var/lib/docker) and retry."
    fi
    log "docker filesystem: ${free} MB free after reclaiming the build cache"
}

# Remove superseded application images. This is NOT `docker system prune -a`:
# only the application image names are considered, the current and the
# previous tag are kept, images that a container still references are kept,
# and no container, volume or database is ever touched.
prune_app_images() {
    local keep_current="${1:-}" keep_previous="${2:-}"
    local base ref tag
    for base in "$APP_IMAGE_BACKEND" "$APP_IMAGE_FRONTEND" "eventflow-backend" "eventflow-frontend"; do
        while read -r ref; do
            [ -n "$ref" ] || continue
            tag="${ref##*:}"
            [ "$tag" = "$keep_current" ]  && continue
            [ "$tag" = "$keep_previous" ] && continue
            if [ -n "$(docker ps -a --filter "ancestor=${ref}" --format '{{.ID}}' 2>/dev/null | head -n 1)" ]; then
                log "keeping ${ref} (a container still references it)"
                continue
            fi
            if docker image rm "$ref" >/dev/null 2>&1; then
                log "removed superseded image ${ref}"
            fi
        done <<EOF
$(docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | awk -v p="${base}:" 'index($0, p) == 1')
EOF
    done
}

# ---------------------------------------------------------------------------
# Health gates
# ---------------------------------------------------------------------------
# Wait until the whole stack answers correctly through nginx.
#   wait_health [attempts]
# Checks: frontend /, backend /live/ + /ready/, API auth (401), media :8080.
wait_health() {
    local attempts="${1:-30}" i code_live code_ready code_front code_api code_media
    for ((i = 1; i <= attempts; i++)); do
        code_live=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://127.0.0.1/live/ 2>/dev/null || echo 000)
        code_ready=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://127.0.0.1/ready/ 2>/dev/null || echo 000)
        code_front=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://127.0.0.1/ 2>/dev/null || echo 000)
        code_api=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://127.0.0.1/api/v1/tenants/ 2>/dev/null || echo 000)
        code_media=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://127.0.0.1:8080/ 2>/dev/null || echo 000)
        if [ "$code_live" = "200" ] && [ "$code_ready" = "200" ] && [ "$code_front" = "200" ] \
            && [ "$code_api" = "401" ] && [ "$code_media" = "404" ]; then
            log "health OK on attempt ${i}/${attempts} (live=${code_live} ready=${code_ready} front=${code_front} api=${code_api} media=${code_media})"
            return 0
        fi
        sleep 5
    done
    log "health checks still failing after ${attempts} attempts (live=${code_live} ready=${code_ready} front=${code_front} api=${code_api} media=${code_media})"
    return 1
}

# Graceful nginx reload so it re-resolves upstream container addresses.
# Non-fatal right after a cold start (the pid file may not exist yet — the
# health gate is the authoritative check).
nginx_reload() {
    if compose exec -T nginx nginx -s reload 2>/dev/null; then
        log "nginx reloaded (upstream addresses refreshed)"
    else
        log "note: nginx reload skipped (fresh start or nginx not running yet)"
    fi
}
