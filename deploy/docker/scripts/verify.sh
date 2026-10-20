#!/bin/bash
set -euo pipefail
# Post-deployment verification ON the VPS (runs from the repo checkout as
# the deploy user). Invoked by .github/workflows/deploy.yml after
# deploy_compose.sh. Independent re-check of what the deploy script asserted.
#
# Verifies: container states/health, nginx config, HTTP behavior through
# nginx, migration state, media mount writability, image tags.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/../lib.sh"

cd "$REPO_DIR"
FAILED=0
note() { log "$*"; }
check_failed() { log "FAIL: $*"; FAILED=1; }

# ---- 1. containers running + healthy ---------------------------------------
for svc in mariadb redis backend frontend nginx; do
    cid=$(compose ps -q "$svc" 2>/dev/null || true)
    if [ -z "$cid" ]; then
        check_failed "service ${svc} has no container"
        continue
    fi
    state=$(docker inspect --format '{{.State.Status}}' "$cid")
    health=$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$cid")
    if [ "$state" != "running" ]; then
        check_failed "service ${svc} state=${state}"
        continue
    fi
    # mariadb/redis/backend/frontend/nginx all define healthchecks.
    if [ "$health" != "healthy" ]; then
        check_failed "service ${svc} health=${health}"
        continue
    fi
    note "OK ${svc}: running/healthy"
done

# ---- 2. nginx config valid inside the container ----------------------------
if compose exec -T nginx nginx -t >/dev/null 2>&1; then
    note "OK nginx -t inside container"
else
    check_failed "nginx -t failed inside container"
fi

# ---- 3. HTTP behavior through nginx ----------------------------------------
expect() {
    local label="$1" path="$2" want="$3" url="$4" code="000"
    code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "$url" 2>/dev/null || true)
    if [ "${code:-000}" = "$want" ]; then
        note "OK ${label} → ${code}"
    else
        check_failed "${label} → ${code} (expected ${want}) at ${url}"
    fi
}
expect "frontend /"          "/"                  "200" "http://127.0.0.1/"
expect "backend /live/"      "/live/"             "200" "http://127.0.0.1/live/"
expect "backend /ready/"     "/ready/"            "200" "http://127.0.0.1/ready/"
expect "API requires auth"   "/api/v1/tenants/"   "401" "http://127.0.0.1/api/v1/tenants/"
expect "media port 8080"     "/"                  "404" "http://127.0.0.1:8080/"
expect "nginx self-check"    "/nginx-health"       "200" "http://127.0.0.1/nginx-health"

# ---- 4. migrations fully applied -------------------------------------------
if compose run --rm backend python manage.py migrate --check >/dev/null 2>&1; then
    note "OK migrate --check (no pending migrations)"
else
    check_failed "migrate --check reports pending migrations"
fi

# ---- 5. media mount writable by the app user -------------------------------
if compose exec -T backend python -c "import os,sys; sys.exit(0 if os.access('/home/eventflow/media', os.W_OK) else 1)" 2>/dev/null; then
    note "OK /home/eventflow/media writable inside backend container"
else
    check_failed "/home/eventflow/media missing or not writable in backend"
fi

# ---- 6. running images match the recorded deploy SHA -----------------------
# The images are pulled from the container registry, so the reference is
# <registry>/nadeemmx/eventflow-<service>:<sha>.
current=$(cat "${STATE_DIR}/.current_sha" 2>/dev/null || echo "")
if [ -n "$current" ]; then
    for svc in backend frontend; do
        ref="$(app_image_ref "$svc")"
        if docker image inspect "$ref" >/dev/null 2>&1; then
            note "OK image ${ref} present"
        else
            check_failed "image ${ref} not found"
        fi
    done
else
    note "note: no .current_sha recorded yet"
fi

# ---- 6b. the running containers use exactly those images ------------------
if [ -n "$current" ]; then
    for svc in backend frontend; do
        cid=$(compose ps -q "$svc" 2>/dev/null || true)
        [ -n "$cid" ] || continue
        running=$(docker inspect --format '{{.Config.Image}}' "$cid" 2>/dev/null || echo "")
        expected="$(app_image_ref "$svc")"
        if [ "$running" = "$expected" ]; then
            note "OK ${svc} container runs ${running}"
        else
            check_failed "${svc} container runs ${running:-<unknown>} instead of ${expected}"
        fi
    done
fi

# ---- 7. one-off containers resolve to the deployed tag ---------------------
# compose() (lib.sh) is what `migrate --check` above and every cron job call.
# It must select the SHA that is actually deployed; the .env default
# (EVENTFLOW_TAG=local) names an image that was never built by the deploy.
resolved="$(eventflow_tag)"
if [ -z "$current" ]; then
    note "note: no recorded deploy SHA — compose tag resolves to ${resolved}"
elif [ "$resolved" = "$current" ]; then
    note "OK compose tag ${resolved} matches the deployed SHA"
else
    check_failed "compose tag ${resolved} does not match the deployed SHA ${current} (one-off containers would run the wrong image)"
fi

if [ "$FAILED" -ne 0 ]; then
    fail "post-deployment verification found problems (see FAIL lines above)"
fi
log "post-deployment verification passed"
