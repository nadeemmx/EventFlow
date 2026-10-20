#!/bin/bash
set -euo pipefail
# Rollback the EventFlow Docker stack to a previous commit SHA.
#
# Usage:
#   rollback.sh              # → .previous_sha (last known good)
#   rollback.sh <commit-sha> # → an explicit earlier SHA
#
# The images of the target tag are PULLED from the container registry (the
# server never builds). A locally built image of the same commit is accepted
# as a fallback, so a rollback across the migration from "build on the VPS"
# to GHCR still works. The repo checkout is moved to the target SHA so
# compose/config match the running images.

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

CURRENT="$(cat "${STATE_DIR}/.current_sha" 2>/dev/null || true)"
if [ "$CURRENT" = "$TARGET" ]; then
    fail "already running ${TARGET}"
fi

log "rolling back: ${CURRENT:-unknown} → ${TARGET}"
git -c advice.detachedHead=false checkout --quiet --detach "$TARGET"

compose config -q || fail "compose config invalid at ${TARGET}"

# Pull the exact images of the target commit. Without this the rollback would
# depend on the images still being on disk, which is not guaranteed now that
# every deploy pulls what it needs.
#
# The digests are optional: export EVENTFLOW_EXPECTED_BACKEND_DIGEST /
# EVENTFLOW_EXPECTED_FRONTEND_DIGEST to pin them (the deploy workflow passes
# the digests of the commit it deploys; the auto-rollback inside
# deploy_compose.sh must NOT reuse them — they belong to the failed commit).
if ! pull_app_images "$TARGET" allow-legacy-local \
        "${EVENTFLOW_EXPECTED_BACKEND_DIGEST:-}" \
        "${EVENTFLOW_EXPECTED_FRONTEND_DIGEST:-}" \
        no; then
    fail "no image available for ${TARGET} — cannot roll back to it (the commit must have been published to the registry)"
fi

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
