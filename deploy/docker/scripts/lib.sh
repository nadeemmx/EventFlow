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
