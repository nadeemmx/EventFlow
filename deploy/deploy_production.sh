#!/bin/bash
set -euo pipefail

# ============================================================
# EventFlow Production Deployment Script
# Run on VPS as: bash deploy_production.sh [commit_sha]
#
# SAFE: Never creates .env, never recreates DB, never
# overwrites secrets. Idempotent — safe to run repeatedly.
# ============================================================

DEPLOY_USER="eventflow"
DEPLOY_DIR="/home/${DEPLOY_USER}"
REPO_DIR="${DEPLOY_DIR}/eventflow"
BACKEND_DIR="${DEPLOY_DIR}/python/eventflow-api"
FRONTEND_DIR="${DEPLOY_DIR}/frontend/public_html"
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
log "[0/10] Pre-flight checks..."

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

# Record current commit for rollback
PREVIOUS_SHA=$(cd "${REPO_DIR}" && git rev-parse HEAD 2>/dev/null || echo "unknown")
log "Previous commit: ${PREVIOUS_SHA}"

# ----------------------------------------------------------
# 1. Update repository
# ----------------------------------------------------------
log "[1/10] Updating repository..."
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
# 2. Backend — install dependencies
# ----------------------------------------------------------
log "[2/10] Installing Python dependencies..."
cd "${BACKEND_DIR}"
source venv/bin/activate
pip install -r requirements/production.txt --quiet --upgrade

# ----------------------------------------------------------
# 3. Backend — Django system check
# ----------------------------------------------------------
log "[3/10] Running Django check..."
python manage.py check --deploy 2>&1 || log "WARNING: check --deploy reported warnings (non-fatal)"

# ----------------------------------------------------------
# 4. Backend — run migrations
# ----------------------------------------------------------
log "[4/10] Running migrations..."
python manage.py migrate --noinput

# ----------------------------------------------------------
# 5. Backend — collect static files
# ----------------------------------------------------------
log "[5/10] Collecting static files..."
python manage.py collectstatic --noinput

# Verify admin static files exist
if ls staticfiles/admin/css/base.*.css >/dev/null 2>&1; then
    log "  Static files verified"
else
    log "  WARNING: Admin static files not found after collectstatic"
fi

# ----------------------------------------------------------
# 6. Frontend — build
# ----------------------------------------------------------
log "[6/10] Building frontend..."
cd "${REPO_DIR}/frontend"

if command -v npm &>/dev/null; then
    npm ci --silent
    npm run build

    if [ -d "out" ]; then
        # Atomic frontend deploy: build to temp dir, then swap
        TEMP_DIR=$(mktemp -d)
        cp -a out/* "${TEMP_DIR}/"
        rm -rf "${FRONTEND_DIR:?}"/*
        mv "${TEMP_DIR}"/* "${FRONTEND_DIR}/"
        rm -rf "${TEMP_DIR}"
        log "  Frontend deployed to ${FRONTEND_DIR}"
    else
        fail "Frontend build produced no output (expected 'out/' directory)"
    fi
else
    fail "npm not found — cannot build frontend"
fi

# ----------------------------------------------------------
# 7. Backend — restart Gunicorn
# ----------------------------------------------------------
log "[7/10] Restarting Gunicorn..."
if systemctl is-active --quiet eventflow.service; then
    systemctl restart eventflow.service
    sleep 2
    if systemctl is-active --quiet eventflow.service; then
        log "  Gunicorn restarted successfully"
    else
        log "  WARNING: Gunicorn failed to start after restart"
        journalctl -u eventflow.service --no-pager -n 20
        fail "Gunicorn is not running after restart"
    fi
else
    systemctl start eventflow.service
    sleep 2
    if systemctl is-active --quiet eventflow.service; then
        log "  Gunicorn started"
    else
        fail "Gunicorn failed to start"
    fi
fi

# ----------------------------------------------------------
# 8. Reload Nginx (safe — only reload, never recreate config)
# ----------------------------------------------------------
log "[8/10] Reloading Nginx..."
if nginx -t 2>&1; then
    systemctl reload nginx
    log "  Nginx reloaded"
else
    log "  WARNING: Nginx config test failed — skipping reload"
fi

# ----------------------------------------------------------
# 9. Verify services
# ----------------------------------------------------------
log "[9/10] Verifying services..."

SERVICES_OK=true
for svc in eventflow.service nginx; do
    if systemctl is-active --quiet "$svc"; then
        log "  [OK] ${svc}"
    else
        log "  [FAIL] ${svc}"
        SERVICES_OK=false
    fi
done

# ----------------------------------------------------------
# 10. Health check
# ----------------------------------------------------------
log "[10/10] Running health checks..."

HEALTH_OK=true

# Liveness
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1/live/ 2>/dev/null || echo "000")
if [ "${STATUS}" = "200" ]; then
    log "  [OK] /live/ → 200"
else
    log "  [FAIL] /live/ → ${STATUS}"
    HEALTH_OK=false
fi

# Readiness
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1/ready/ 2>/dev/null || echo "000")
if [ "${STATUS}" = "200" ]; then
    log "  [OK] /ready/ → 200"
else
    log "  [FAIL] /ready/ → ${STATUS}"
    HEALTH_OK=false
fi

# Frontend
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1/ 2>/dev/null || echo "000")
if [ "${STATUS}" = "200" ] || [ "${STATUS}" = "301" ] || [ "${STATUS}" = "302" ]; then
    log "  [OK] / → ${STATUS}"
else
    log "  [FAIL] / → ${STATUS}"
    HEALTH_OK=false
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
