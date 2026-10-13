#!/bin/bash
set -euo pipefail
# Rollback the EventFlow Docker stack to a previous commit SHA.
#
# Usage:
#   rollback.sh              # → .previous_sha (last known good)
#   rollback.sh <commit-sha> # → an explicit earlier SHA
#
# Requirements: images for the target tag must already exist on this host
# (they do for any tag previously deployed here). The repo checkout is moved
# to the target SHA so compose/config match the running images.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/../lib.sh"

cd "$REPO_DIR"

TARGET="${1:-$(cat "${STATE_DIR}/.previous_sha" 2>/dev/null || true)}"
[ -n "$TARGET" ] || fail "no target SHA (neither argument nor ${STATE_DIR}/.previous_sha)"
git cat-file -e "${TARGET}^{commit}" 2>/dev/null || fail "commit ${TARGET} not found locally"

# Pin the tag for this whole run: every compose call below (config, up) must
# use the rollback target, never the .env default ("local") and never the
# state file's still-current SHA.
export EVENTFLOW_TAG="$TARGET"

for img in eventflow-backend eventflow-frontend; do
    docker image inspect "${img}:${TARGET}" >/dev/null 2>&1 \
        || fail "image ${img}:${TARGET} not present — cannot roll back to it (only previously deployed tags are available)"
done

CURRENT="$(cat "${STATE_DIR}/.current_sha" 2>/dev/null || true)"
if [ "$CURRENT" = "$TARGET" ]; then
    fail "already running ${TARGET}"
fi

log "rolling back: ${CURRENT:-unknown} → ${TARGET}"
git -c advice.detachedHead=false checkout --quiet --detach "$TARGET"

compose config -q || fail "compose config invalid at ${TARGET}"
compose up -d
nginx_reload

if ! wait_health 30; then
    fail "rollback to ${TARGET} is unhealthy — previous state was ${CURRENT:-unknown}; inspect with: docker compose --env-file ${ENV_FILE} -f ${COMPOSE_FILE} ps"
fi

# Swap recorded state: target becomes current; the SHA we rolled back FROM
# becomes the "previous" (so a re-roll-forward works).
printf '%s\n' "$TARGET" > "${STATE_DIR}/.current_sha"
if [ -n "$CURRENT" ] && [ "$CURRENT" != "$TARGET" ]; then
    printf '%s\n' "$CURRENT" > "${STATE_DIR}/.previous_sha"
fi
log "rollback to ${TARGET} complete and healthy"
