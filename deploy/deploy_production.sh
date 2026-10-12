#!/bin/bash
set -euo pipefail

# ============================================================
# EventFlow Production Deployment Script
# Run on VPS as: bash deploy_production.sh [commit_sha]
#
# SAFE: Never creates .env, never recreates DB, never
# overwrites secrets. Idempotent — safe to run repeatedly.
#
# Frontend serving model: `next build` + `next start` on
# 127.0.0.1:3000 (systemd unit eventflow-frontend.service),
# proxied by nginx. Static export (out/) is NOT produced.
# ============================================================

DEPLOY_USER="eventflow"
DEPLOY_DIR="/home/${DEPLOY_USER}"
REPO_DIR="${DEPLOY_DIR}/eventflow"
BACKEND_DIR="${DEPLOY_DIR}/python/eventflow-api"
MEDIA_DIR="${DEPLOY_DIR}/media"
LOG_DIR="${BACKEND_DIR}/logs"
REQUESTED_SHA="${1:-}"

log()  { echo "[$(date '+%H:%M:%S')] $*"; }
fail() { log "FATAL: $*"; exit 1; }

log "============================================"
log "  EventFlow Production Deployment"
log "============================================"

# ----------------------------------------------------------
# 0. Pre-flight checks
# ----------------------------------------------------------
log "[0/11] Pre-flight checks..."

if [ "$(id -u)" -eq 0 ]; then
    fail "Do not run as root. Use: sudo -u ${DEPLOY_USER} bash $0"
fi

if [ ! -d "${REPO_DIR}/.git" ]; then
    fail "Repository not found at ${REPO_DIR}"
fi

if [ ! -d "${BACKEND_DIR}/venv" ]; then
    fail "Python virtualenv not found at ${BACKEND_DIR}/venv"
fi

if [ ! -f "${BACKEND_DIR}/.env" ]; then
    fail ".env not found at ${BACKEND_DIR}/.env — cannot deploy without it"
fi

# Node.js >= 20 is required to build AND serve the frontend (next start)
if ! command -v node >/dev/null 2>&1; then
    fail "node not found — install Node.js 20+ (e.g. via nodesource) before deploying"
fi
NODE_MAJOR=$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)
if [ "${NODE_MAJOR}" -lt 20 ]; then
    fail "Node $(node -v) is too old — Next.js 16 requires Node >= 20"
fi
if ! command -v npm >/dev/null 2>&1; then
    fail "npm not found — cannot build frontend"
fi

# Verify sudo access is available (needed for systemctl/nginx)
if ! sudo -n true 2>/dev/null; then
    fail "Sudo access not configured for ${DEPLOY_USER}. Grant NOPASSWD for: systemctl (eventflow.service, eventflow-frontend.service, nginx), nginx -t, cmp, cp, install, crontab"
fi

# Record current commit for rollback
PREVIOUS_SHA=$(cd "${REPO_DIR}" && git rev-parse HEAD 2>/dev/null || echo "unknown")
log "Previous commit: ${PREVIOUS_SHA}"

# ----------------------------------------------------------
# 1. Update repository
# ----------------------------------------------------------
log "[1/11] Updating repository..."
cd "${REPO_DIR}"
git fetch origin --quiet
git checkout master --quiet
git reset --hard origin/master --quiet
CURRENT_SHA=$(git rev-parse HEAD)
log "Current commit: ${CURRENT_SHA}"

if [ -n "${REQUESTED_SHA}" ] && [ "${CURRENT_SHA}" != "${REQUESTED_SHA}" ]; then
    log "WARNING: Expected ${REQUESTED_SHA} but got ${CURRENT_SHA}"
fi

# ----------------------------------------------------------
# 2. Backend — sync code from the checkout
#    (Gunicorn runs from BACKEND_DIR, not REPO_DIR/backend,
#     so without this step backend code never updates.)
# ----------------------------------------------------------
log "[2/11] Syncing backend code to ${BACKEND_DIR}..."
if [ ! -f "${REPO_DIR}/backend/manage.py" ]; then
    fail "Not a backend checkout: ${REPO_DIR}/backend/manage.py missing"
fi

# --delete makes the sync authoritative. Excluded paths are protected from
# deletion (rsync does not delete files it was told to exclude), which keeps
# .env, venv/, logs/, staticfiles/ and any local database intact.
rsync -a --delete \
    --exclude='.env' \
    --exclude='venv/' \
    --exclude='logs/' \
    --exclude='staticfiles/' \
    --exclude='media/' \
    --exclude='__pycache__/' \
    --exclude='*.pyc' \
    --exclude='.pytest_cache/' \
    --exclude='*.sqlite3' \
    "${REPO_DIR}/backend/" "${BACKEND_DIR}/"
log "  Backend code synced (secrets/venv/logs preserved)"

# ----------------------------------------------------------
# 3. Backend — install dependencies
# ----------------------------------------------------------
log "[3/11] Installing Python dependencies..."
cd "${BACKEND_DIR}"
source venv/bin/activate
pip install -r requirements/production.txt --quiet --upgrade

# ----------------------------------------------------------
# 4. Backend — Django system check
# ----------------------------------------------------------
log "[4/11] Running Django check..."
python manage.py check --deploy 2>&1 || log "WARNING: check --deploy reported warnings (non-fatal)"

# ----------------------------------------------------------
# 5. Backend — run migrations
# ----------------------------------------------------------
log "[5/11] Running migrations..."
python manage.py migrate --noinput

# ----------------------------------------------------------
# 6. Backend — collect static files
# ----------------------------------------------------------
log "[6/11] Collecting static files..."
python manage.py collectstatic --noinput

# Verify admin static files exist
if ls staticfiles/admin/css/base.*.css >/dev/null 2>&1; then
    log "  Static files verified"
else
    log "  WARNING: Admin static files not found after collectstatic"
fi

# ----------------------------------------------------------
# 7. Frontend — build (.next, served by `next start`)
# ----------------------------------------------------------
log "[7/11] Building frontend..."
cd "${REPO_DIR}/frontend"

# NEXT_PUBLIC_API_URL is inlined at build time and the build fails without
# it (next.config.mjs). Source of truth: frontend/.env.production, with
# backend .env as a fallback so a single deploy env can drive both.
FRONTEND_ENV_FILE="${REPO_DIR}/frontend/.env.production"
NEXT_API_URL=""
if [ -f "${FRONTEND_ENV_FILE}" ]; then
    NEXT_API_URL=$(sed -n 's/^NEXT_PUBLIC_API_URL=//p' "${FRONTEND_ENV_FILE}" | tail -1)
fi
if [ -z "${NEXT_API_URL}" ] && [ -f "${BACKEND_DIR}/.env" ]; then
    NEXT_API_URL=$(sed -n 's/^NEXT_PUBLIC_API_URL=//p' "${BACKEND_DIR}/.env" | tail -1)
fi
if [ -z "${NEXT_API_URL}" ]; then
    fail "NEXT_PUBLIC_API_URL is not set. Create ${FRONTEND_ENV_FILE} (copy frontend/.env.production.example) or add NEXT_PUBLIC_API_URL=<https://api.YOUR-DOMAIN/api/v1> to ${BACKEND_DIR}/.env"
fi
export NEXT_PUBLIC_API_URL="${NEXT_API_URL}"
log "  NEXT_PUBLIC_API_URL=${NEXT_API_URL}"

npm ci --silent
npm run build

if [ -f ".next/BUILD_ID" ]; then
    log "  Frontend build OK (.next/BUILD_ID=$(cat .next/BUILD_ID))"
else
    fail "Frontend build produced no .next/BUILD_ID — next build did not complete"
fi

# ----------------------------------------------------------
# 8. Services — install units, restart Gunicorn + Next.js
# ----------------------------------------------------------
log "[8/11] Installing systemd units and restarting services..."

UNIT_CHANGED=false
install_unit() {
    local src="$1" name="$2"
    if sudo -n cmp -s "${src}" "/etc/systemd/system/${name}" 2>/dev/null; then
        log "  ${name} unchanged"
    else
        sudo -n cp "${src}" "/etc/systemd/system/${name}"
        log "  ${name} installed/updated"
        UNIT_CHANGED=true
    fi
}

install_unit "${REPO_DIR}/deploy/systemd/eventflow.service" "eventflow.service"
install_unit "${REPO_DIR}/deploy/systemd/eventflow-frontend.service" "eventflow-frontend.service"

if [ "${UNIT_CHANGED}" = true ]; then
    sudo -n systemctl daemon-reload
fi
sudo -n systemctl enable eventflow.service eventflow-frontend.service >/dev/null 2>&1 || true

restart_service() {
    local svc="$1"
    sudo -n systemctl restart "${svc}"
    sleep 2
    if sudo -n systemctl is-active --quiet "${svc}"; then
        log "  [OK] ${svc} restarted"
    else
        sudo -n journalctl -u "${svc}" --no-pager -n 20 || true
        fail "${svc} is not running after restart"
    fi
}

restart_service eventflow.service
restart_service eventflow-frontend.service

# ----------------------------------------------------------
# 9. Reload Nginx (safe — only reload, never recreate config)
# ----------------------------------------------------------
log "[9/11] Reloading Nginx..."
if sudo -n nginx -t 2>&1; then
    sudo -n systemctl reload nginx
    log "  Nginx reloaded"
else
    log "  WARNING: Nginx config test failed — skipping reload"
fi

# The frontend is proxied to 127.0.0.1:3000 now. If the installed nginx
# config still serves static files from public_html, the app will 404 even
# though this script succeeded — detect and say so loudly.
if [ -f /etc/nginx/sites-enabled/eventflow ] || [ -f /etc/nginx/sites-available/eventflow ]; then
    if ! sudo -n grep -q "eventflow_frontend" /etc/nginx/sites-available/eventflow 2>/dev/null; then
        log "  WARNING: installed nginx config has no 'eventflow_frontend' upstream."
        log "          It probably still serves static public_html (old model)."
        log "          Render the current template with:"
        log "            deploy/scripts/render_nginx_config.sh <API_HOST> <APP_HOST> <MEDIA_HOST>"
    fi
fi

# ----------------------------------------------------------
# 10. Cron jobs (reminders, reports, backups)
# ----------------------------------------------------------
log "[10/11] Installing cron jobs..."
CRON_SRC="${REPO_DIR}/deploy/scripts/crontab.txt"
if command -v crontab >/dev/null 2>&1 && [ -f "${CRON_SRC}" ]; then
    CURRENT_CRON=$(sudo -n -u "${DEPLOY_USER}" crontab -l 2>/dev/null || true)
    if printf '%s' "${CURRENT_CRON}" | grep -q "# eventflow-cron-v1"; then
        log "  crontab already installed (marker present) — leaving as-is"
    elif [ -n "${CURRENT_CRON}" ]; then
        # Preserve any existing entries, append ours once
        { printf '%s\n' "${CURRENT_CRON}"; cat "${CRON_SRC}"; } | sudo -n -u "${DEPLOY_USER}" crontab -
        log "  crontab appended (existing entries preserved)"
    else
        sudo -n -u "${DEPLOY_USER}" crontab "${CRON_SRC}"
        log "  crontab installed"
    fi
fi

# Backup/restore helpers referenced by the crontab (path: ~/scripts/backup.sh)
mkdir -p "${DEPLOY_DIR}/scripts"
for script in backup.sh restore.sh; do
    src="${REPO_DIR}/deploy/scripts/${script}"
    if [ -f "${src}" ]; then
        sudo -n install -m 750 -o "${DEPLOY_USER}" -g "${DEPLOY_USER}" \
            "${src}" "${DEPLOY_DIR}/scripts/${script}"
    fi
done
log "  backup/restore scripts installed in ${DEPLOY_DIR}/scripts"

# ----------------------------------------------------------
# 11. Verify services + health checks
# ----------------------------------------------------------
log "[11/11] Verifying services..."

SERVICES_OK=true
for svc in eventflow.service eventflow-frontend.service nginx; do
    if sudo -n systemctl is-active --quiet "$svc"; then
        log "  [OK] ${svc}"
    else
        log "  [FAIL] ${svc}"
        SERVICES_OK=false
    fi
done

log "Running health checks..."

HEALTH_OK=true

check_url() {
    local label="$1" url="$2" expect="$3"
    local status
    status=$(curl -s -o /dev/null -w "%{http_code}" "${url}" 2>/dev/null || echo "000")
    if [ "${status}" = "${expect}" ]; then
        log "  [OK] ${label} → ${status}"
    else
        log "  [FAIL] ${label} → ${status} (expected ${expect})"
        HEALTH_OK=false
    fi
}

# Direct-to-process checks: bypass nginx so they are independent of the
# Host header / server_name configuration (loopback is always in
# ALLOWED_HOSTS — see config/settings/production.py).
check_url "gunicorn /live/  (127.0.0.1:8000)" "http://127.0.0.1:8000/live/"  "200"
check_url "gunicorn /ready/ (127.0.0.1:8000)" "http://127.0.0.1:8000/ready/" "200"
check_url "next start /     (127.0.0.1:3000)" "http://127.0.0.1:3000/"       "200"

# Optional end-to-end check through nginx once the operator has set
# HEALTH_HOST (e.g. HEALTH_HOST=api.example.com) — never guessed here.
if [ -n "${HEALTH_HOST:-}" ]; then
    status=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: ${HEALTH_HOST}" http://127.0.0.1/live/ 2>/dev/null || echo "000")
    if [ "${status}" = "200" ]; then
        log "  [OK] nginx /live/ via Host:${HEALTH_HOST} → 200"
    else
        log "  [FAIL] nginx /live/ via Host:${HEALTH_HOST} → ${status}"
        HEALTH_OK=false
    fi
fi

# ----------------------------------------------------------
# Summary
# ----------------------------------------------------------
echo ""
log "============================================"
if [ "${SERVICES_OK}" = true ] && [ "${HEALTH_OK}" = true ]; then
    log "  DEPLOYMENT SUCCESSFUL"
    log "  Commit: ${CURRENT_SHA}"
    log "============================================"
    exit 0
else
    log "  DEPLOYMENT COMPLETED WITH WARNINGS"
    log "  Commit: ${CURRENT_SHA}"
    log "  Previous: ${PREVIOUS_SHA}"
    log "============================================"
    log ""
    log "To rollback, run on the VPS:"
    log "  cd ${REPO_DIR} && git checkout ${PREVIOUS_SHA} && git reset --hard HEAD"
    log "  Then re-run this script."
    exit 1
fi
