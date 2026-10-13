#!/bin/bash
set -euo pipefail
# EventFlow — Docker Compose deployment. Runs ON the VPS as the deploy user.
#
# Invoked by .github/workflows/deploy.yml AFTER the production approval gate:
#     scp deploy_compose.sh deploy/docker/scripts/lib.sh  →  /tmp/
#     NEXT_PUBLIC_API_URL='http://…' bash /tmp/eventflow_deploy.sh <sha>
#
# Flow (safe to retry; idempotent):
#   1. clone/fetch the repo and check out <sha>
#   2. `docker compose config -q` — fail before touching anything
#   3. build images tagged with the sha (eventflow-{backend,frontend}:<sha>)
#   4. start MariaDB/Redis, run migrations + `migrate --check`
#   5. `up -d` the app stack, graceful nginx reload
#   6. health gate through nginx (frontend, live, ready, API auth, media)
#   7. record <sha> as current; on health failure roll back automatically
#      to the previous known-good tag (if its images still exist)
#
# Secrets: read from ENV_FILE outside the repository. Nothing is printed.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# On the VPS the workflow scp's lib.sh next to this script; once the repo
# exists we prefer the repo copy (same content, versioned with the SHA).
if [ -f "${SCRIPT_DIR}/lib.sh" ]; then
    # shellcheck source=deploy/docker/scripts/lib.sh
    source "${SCRIPT_DIR}/lib.sh"
elif [ -f "${REPO_DIR:-/srv/baseify/eventflow/repo}/deploy/docker/scripts/lib.sh" ]; then
    source "${REPO_DIR:-/srv/baseify/eventflow/repo}/deploy/docker/scripts/lib.sh"
else
    echo "ERROR: lib.sh not found next to $0 nor in the repo" >&2
    exit 1
fi

REPO_URL="${REPO_URL:-https://github.com/nadeemmx/EventFlow.git}"

TAG="${1:-}"
[ -n "$TAG" ] || fail "usage: $0 <commit-sha>"
command -v curl >/dev/null 2>&1 || fail "curl is required (bootstrap_vps.sh installs it)"
command -v docker >/dev/null 2>&1 || fail "docker is not installed (run deploy/bootstrap/bootstrap_vps.sh)"
docker compose version >/dev/null 2>&1 || fail "docker compose plugin is missing"
[ -n "${NEXT_PUBLIC_API_URL:-}" ] || fail "NEXT_PUBLIC_API_URL must be set (CI repository variable)"

# Every compose call in this run — including the `config` validation below —
# must target the tag being deployed, never the .env default ("local").
export EVENTFLOW_TAG="$TAG"

# ---- 1. source checkout at the requested SHA -------------------------------
if [ ! -d "${REPO_DIR}/.git" ]; then
    log "cloning ${REPO_URL} → ${REPO_DIR}"
    git clone --quiet "$REPO_URL" "$REPO_DIR"
fi
cd "$REPO_DIR"
git fetch --quiet origin
if ! git cat-file -e "${TAG}^{commit}" 2>/dev/null; then
    fail "commit ${TAG} not found after fetch — was it pushed to master?"
fi

LAST_GOOD="$(cat "${STATE_DIR}/.current_sha" 2>/dev/null || true)"
log "deploying ${TAG} (last known good: ${LAST_GOOD:-none})"
git -c advice.detachedHead=false checkout --quiet --detach "$TAG"

# ---- 2. validate the stack definition BEFORE building ----------------------
compose config -q || fail "docker compose config validation failed"

# ---- 3. build images tagged with the commit SHA ---------------------------
# (EVENTFLOW_TAG was exported right after the preflight checks.)
log "building eventflow-backend:${TAG} and eventflow-frontend:${TAG}"
compose build backend frontend

# ---- 4. database up + migrations (explicit, never hidden in entrypoints) ---
log "starting MariaDB/Redis and applying migrations"
compose up -d mariadb redis
compose run --rm backend python manage.py migrate --noinput
if ! compose run --rm backend python manage.py migrate --check; then
    fail "migrate --check reports unapplied migrations — refusing to continue"
fi

# ---- 5. switch the application stack --------------------------------------
log "starting app stack with tag ${TAG}"
compose up -d
nginx_reload

# ---- 6. health gate (frontend, backend live/ready, API auth, media port) ---
log "waiting for health checks (max 150s)"
if ! wait_health 30; then
    log "HEALTH GATE FAILED for ${TAG}"
    if [ -n "$LAST_GOOD" ] && [ "$LAST_GOOD" != "$TAG" ] \
        && docker image inspect "eventflow-backend:${LAST_GOOD}" >/dev/null 2>&1 \
        && docker image inspect "eventflow-frontend:${LAST_GOOD}" >/dev/null 2>&1; then
        log "auto-rollback: previous known-good tag ${LAST_GOOD}"
        git -c advice.detachedHead=false checkout --quiet --detach "$LAST_GOOD"
        export EVENTFLOW_TAG="$LAST_GOOD"
        compose up -d
        nginx_reload
        if wait_health 12; then
            printf '%s\n' "$LAST_GOOD" > "${STATE_DIR}/.current_sha"
            printf '%s\n' "$TAG" > "${STATE_DIR}/.last_failed_sha"
            fail "deployment of ${TAG} failed health checks; rolled back to ${LAST_GOOD}"
        fi
        fail "deployment of ${TAG} failed AND rollback to ${LAST_GOOD} is unhealthy — inspect on the VPS: docker compose --env-file ${ENV_FILE} -f ${COMPOSE_FILE} ps"
    fi
    fail "deployment of ${TAG} failed health checks (no previous good tag available) — inspect: docker compose --env-file ${ENV_FILE} -f ${COMPOSE_FILE} ps && docker compose … logs backend"
fi

# ---- 7. record state -------------------------------------------------------
printf '%s\n' "$TAG" > "${STATE_DIR}/.current_sha"
if [ -n "$LAST_GOOD" ] && [ "$LAST_GOOD" != "$TAG" ]; then
    printf '%s\n' "$LAST_GOOD" > "${STATE_DIR}/.previous_sha"
fi
log "deployed ${TAG} successfully"
