#!/bin/bash
set -euo pipefail

# ============================================================
# EventFlow Post-Deployment Verification
# Runs ON the VPS after deploy_production.sh (CI/CD calls it over SSH).
#
# Read-mostly by design: it never migrates, restarts, reloads or writes.
# It verifies that the deployment actually landed:
#   1. systemd units are active
#   2. nginx configuration is valid (nginx -t)
#   3. database reachable + no unapplied migrations
#   4. HTTP health endpoints on loopback (gunicorn, next start)
#   5. static files served, media server answering
#   6. full smoke_test.sh
#
# Exit 0 = every check passed; exit 1 = at least one check failed.
# ============================================================

DEPLOY_USER="${DEPLOY_USER:-eventflow}"
REPO_DIR="${REPO_DIR:-/home/${DEPLOY_USER}/eventflow}"
BACKEND_DIR="${BACKEND_DIR:-/home/${DEPLOY_USER}/python/eventflow-api}"
API_BASE="http://127.0.0.1:8000"
FRONTEND_BASE="http://127.0.0.1:3000"
MEDIA_BASE="http://127.0.0.1:8080"

PASS=0
FAIL=0

ok()   { echo "  [OK]   $*"; PASS=$((PASS + 1)); }
bad()  { echo "  [FAIL] $*"; FAIL=$((FAIL + 1)); }

check_url() {
    local label="$1" url="$2" want="$3" code
    # curl still writes %{http_code} (000) when the connection fails, so
    # don't append another 000 — only default when nothing was printed.
    code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 "${url}" 2>/dev/null || true)
    code="${code:-000}"
    if [ "${code}" = "${want}" ]; then
        ok "${label} → ${code}"
    else
        bad "${label} → ${code} (expected ${want})"
    fi
}

echo "=== EventFlow post-deployment verification ==="
echo "Repo:    ${REPO_DIR}"
echo "Backend: ${BACKEND_DIR}"
echo ""

# 1. systemd services ------------------------------------------------
echo "1. systemd services"
for svc in eventflow.service eventflow-frontend.service nginx; do
    if sudo -n systemctl is-active --quiet "${svc}"; then
        ok "${svc} active"
    else
        bad "${svc} not active"
        sudo -n systemctl --no-pager --full status "${svc}" 2>/dev/null | sed -n '1,8p' || true
        sudo -n journalctl -u "${svc}" --no-pager -n 15 2>/dev/null || true
    fi
done

# 2. nginx configuration --------------------------------------------
echo "2. nginx configuration"
if sudo -n nginx -t; then
    ok "nginx -t"
else
    bad "nginx -t reported errors"
fi

# 3. database + migration status ------------------------------------
echo "3. database connectivity and migration status"
if [ ! -x "${BACKEND_DIR}/venv/bin/python" ]; then
    bad "python missing at ${BACKEND_DIR}/venv/bin/python (venv not installed?)"
else
    # `migrate --check` queries the django_migrations table: exit 0 means the
    # DB is reachable and fully migrated, non-zero means unapplied migrations
    # or a database error — both fail this check.
    if mig_out=$(cd "${BACKEND_DIR}" && ./venv/bin/python manage.py migrate --check 2>&1); then
        ok "database reachable, no unapplied migrations"
    else
        bad "unapplied migrations or database unreachable"
        printf '%s\n' "${mig_out}" | sed 's/^/         /'
    fi
fi

# 4. HTTP health on loopback ----------------------------------------
echo "4. HTTP health endpoints"
check_url "gunicorn /live/"   "${API_BASE}/live/"   "200"
check_url "gunicorn /ready/"  "${API_BASE}/ready/"  "200"
check_url "gunicorn /health/" "${API_BASE}/health/" "200"
check_url "next start /"      "${FRONTEND_BASE}/"   "200"

# 5. static + media ---------------------------------------------------
echo "5. static and media"
shopt -s nullglob
admin_css=("${BACKEND_DIR}"/staticfiles/admin/css/base.*.css)
shopt -u nullglob
if [ "${#admin_css[@]}" -gt 0 ]; then
    rel="${admin_css[0]#${BACKEND_DIR}/staticfiles/}"
    check_url "static /${rel}" "${API_BASE}/static/${rel}" "200"
else
    bad "no hashed admin css under ${BACKEND_DIR}/staticfiles/admin/css (run collectstatic)"
fi

# Media server on :8080 answers (200 for allowlisted files, 403/404 for
# everything else by design — see deploy/nginx/eventflow-ip.conf).
media_code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "${MEDIA_BASE}/" 2>/dev/null || true)
media_code="${media_code:-000}"
case "${media_code}" in
    200|403|404) ok "media server :${MEDIA_BASE##*:} responding (${media_code})" ;;
    *)           bad "media server :${MEDIA_BASE##*:} → ${media_code}" ;;
esac

# 6. full smoke test ---------------------------------------------------
echo "6. smoke_test.sh"
SMOKE="${REPO_DIR}/deploy/scripts/smoke_test.sh"
if [ -f "${SMOKE}" ]; then
    if bash "${SMOKE}" "${API_BASE}" "${FRONTEND_BASE}" "${MEDIA_BASE}"; then
        ok "smoke_test.sh passed"
    else
        bad "smoke_test.sh reported failures"
    fi
else
    bad "smoke_test.sh not found at ${SMOKE}"
fi

# Summary --------------------------------------------------------------
echo ""
echo "=== Verification summary ==="
echo "Passed: ${PASS}"
echo "Failed: ${FAIL}"
if [ "${FAIL}" -gt 0 ]; then
    echo "STATUS: VERIFICATION FAILED"
    exit 1
fi
echo "STATUS: VERIFICATION PASSED"
