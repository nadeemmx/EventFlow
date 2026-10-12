#!/bin/bash
set -euo pipefail

# EventFlow VPS Deployment Script
# This script deploys the EventFlow application to a VPS
# Run as root or with sudo

DEPLOY_USER="eventflow"
DEPLOY_DIR="/home/eventflow"
BACKEND_DIR="${DEPLOY_DIR}/python/eventflow-api"
FRONTEND_DIR="${DEPLOY_DIR}/frontend/public_html"
MEDIA_DIR="${DEPLOY_DIR}/media"
LOG_DIR="${BACKEND_DIR}/logs"
REPO_DIR="${DEPLOY_DIR}/eventflow"

# Domains (override via environment — this script never invents one).
API_HOST="${API_HOST:-api.eventflow.com}"
APP_HOST="${APP_HOST:-app.eventflow.com}"
MEDIA_HOST="${MEDIA_HOST:-media.eventflow.com}"
CERT_NAME="${CERT_NAME:-eventflow.com}"

echo "=== EventFlow VPS Deployment ==="
echo "  API:   ${API_HOST}"
echo "  App:   ${APP_HOST}"
echo "  Media: ${MEDIA_HOST}"
echo ""

# Detect MySQL/MariaDB service name
MYSQL_SERVICE="mysql"
if systemctl list-unit-files | grep -q mariadb.service; then
    MYSQL_SERVICE="mariadb"
fi

# Detect Redis service name
REDIS_SERVICE="redis-server"
if systemctl list-unit-files | grep -q redis.service; then
    REDIS_SERVICE="redis"
fi

# 1. Create deployment user
echo "[1/14] Creating deployment user..."
if ! id -u "${DEPLOY_USER}" >/dev/null 2>&1; then
    useradd --system --shell /bin/bash --home-dir "${DEPLOY_DIR}" "${DEPLOY_USER}"
    echo "User '${DEPLOY_USER}' created."
else
    echo "User '${DEPLOY_USER}' already exists."
fi

# 2. Create directory structure
echo "[2/14] Creating directory structure..."
mkdir -p "${BACKEND_DIR}" "${FRONTEND_DIR}" "${MEDIA_DIR}" "${LOG_DIR}"
mkdir -p "${MEDIA_DIR}/tenants/logos" "${MEDIA_DIR}/tenants/settings"
mkdir -p "${MEDIA_DIR}/venues" "${MEDIA_DIR}/invoices/logos"
mkdir -p "${MEDIA_DIR}/invoices/pdf" "${MEDIA_DIR}/contracts/pdf"
mkdir -p "${MEDIA_DIR}/branding/logos" "${MEDIA_DIR}/branding/favicons"
mkdir -p "${BACKEND_DIR}/staticfiles"
mkdir -p "${DEPLOY_DIR}/scripts"
mkdir -p "${DEPLOY_DIR}/backups/daily" "${DEPLOY_DIR}/backups/weekly"
chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "${DEPLOY_DIR}"

# 3. Copy project + backend files
echo "[3/14] Copying project files..."
rsync -a --exclude='__pycache__' --exclude='*.pyc' --exclude='.env' \
    --exclude='node_modules' --exclude='.next' --exclude='out' \
    --exclude='venv' --exclude='logs' --exclude='staticfiles' \
    /tmp/eventflow-deploy/ "${REPO_DIR}/"
rsync -a --delete --exclude='__pycache__' --exclude='*.pyc' --exclude='.env' \
    --exclude='venv' --exclude='logs' --exclude='staticfiles' \
    --exclude='*.sqlite3' \
    "${REPO_DIR}/backend/" "${BACKEND_DIR}/"

# 4. Set up Python virtual environment
echo "[4/14] Setting up Python virtual environment..."
if [ ! -d "${BACKEND_DIR}/venv" ]; then
    sudo -u "${DEPLOY_USER}" python3 -m venv "${BACKEND_DIR}/venv"
fi
sudo -u "${DEPLOY_USER}" "${BACKEND_DIR}/venv/bin/pip" install --upgrade pip
sudo -u "${DEPLOY_USER}" "${BACKEND_DIR}/venv/bin/pip" install -r "${BACKEND_DIR}/requirements/production.txt"

# 5. Install system dependencies
echo "[5/14] Installing system dependencies..."
apt-get update -qq
apt-get install -y -qq nginx certbot python3-certbot-nginx mariadb-server redis-server

# 6. Configure environment
echo "[6/14] Configuring environment..."
if [ ! -f "${BACKEND_DIR}/.env" ]; then
    ENCRYPTION_KEY=$(python3 -c "import secrets,base64;print(base64.b64encode(secrets.token_bytes(32)).decode())")
    SECRET_KEY=$(python3 -c "import secrets;print(secrets.token_urlsafe(50))")
    DB_PASSWORD=$(python3 -c "import secrets;print(secrets.token_urlsafe(20))")
    cat > "${BACKEND_DIR}/.env" << EOF
DJANGO_SETTINGS_MODULE=config.settings.production
DJANGO_SECRET_KEY=${SECRET_KEY}
DJANGO_ALLOWED_HOSTS=${API_HOST},localhost,127.0.0.1
DJANGO_DEBUG=False
DB_NAME=eventflow
DB_USER=eventflow
DB_PASSWORD=${DB_PASSWORD}
DB_HOST=127.0.0.1
DB_PORT=3306
REDIS_URL=redis://127.0.0.1:6379/0
ENCRYPTION_KEY=${ENCRYPTION_KEY}
CORS_ALLOWED_ORIGINS=https://${APP_HOST}
CSRF_TRUSTED_ORIGINS=https://${APP_HOST},https://${API_HOST}
DEFAULT_FROM_EMAIL=noreply@${CERT_NAME}
# Frontend build input (read by deploy_production.sh as a fallback when
# frontend/.env.production is absent). Not a secret.
NEXT_PUBLIC_API_URL=https://${API_HOST}/api/v1
EOF
    chmod 600 "${BACKEND_DIR}/.env"
    chown "${DEPLOY_USER}:${DEPLOY_USER}" "${BACKEND_DIR}/.env"
    echo "Environment file created. IMPORTANT: Review and update ${BACKEND_DIR}/.env"
fi

# 7. Create logs directory
echo "[7/14] Creating logs directory..."
mkdir -p "${LOG_DIR}"
chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "${LOG_DIR}"

# 8. Run Django setup
echo "[8/14] Running Django setup..."
cd "${BACKEND_DIR}"
sudo -u "${DEPLOY_USER}" "${BACKEND_DIR}/venv/bin/python" manage.py migrate --noinput
sudo -u "${DEPLOY_USER}" "${BACKEND_DIR}/venv/bin/python" manage.py collectstatic --noinput
sudo -u "${DEPLOY_USER}" "${BACKEND_DIR}/venv/bin/python" manage.py reencrypt_fields --dry-run || true

# 9. Build + install frontend (`next build` / `next start`)
echo "[9/14] Building frontend..."
# NEXT_PUBLIC_API_URL is inlined at build time; next.config.mjs fails the
# build if it is missing/localhost.
export NEXT_PUBLIC_API_URL="${NEXT_PUBLIC_API_URL:-https://${API_HOST}/api/v1}"

if ! command -v node >/dev/null 2>&1; then
    echo "ERROR: node not found. Install Node.js 20+ first, e.g.:" >&2
    echo "  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash - && apt-get install -y nodejs" >&2
    exit 1
fi
NODE_MAJOR=$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)
if [ "${NODE_MAJOR}" -lt 20 ]; then
    echo "ERROR: Node $(node -v) is too old — Next.js 16 requires Node >= 20" >&2
    exit 1
fi

cd "${REPO_DIR}/frontend"
npm ci --silent
npm run build
if [ ! -f ".next/BUILD_ID" ]; then
    echo "ERROR: frontend build produced no .next/BUILD_ID" >&2
    exit 1
fi
echo "  Frontend built (.next/BUILD_ID=$(cat .next/BUILD_ID))"

# 10. Install systemd services
echo "[10/14] Installing systemd services..."
cp "${REPO_DIR}/deploy/systemd/eventflow.service" /etc/systemd/system/
cp "${REPO_DIR}/deploy/systemd/eventflow-frontend.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable eventflow eventflow-frontend

# 11. Configure Nginx (rendered from the domain template)
echo "[11/14] Configuring Nginx..."
bash "${REPO_DIR}/deploy/scripts/render_nginx_config.sh" \
    "${API_HOST}" "${APP_HOST}" "${MEDIA_HOST}" "${CERT_NAME}" \
    -o /etc/nginx/sites-available/eventflow
ln -sf /etc/nginx/sites-available/eventflow /etc/nginx/sites-enabled/eventflow
rm -f /etc/nginx/sites-enabled/default
if nginx -t 2>&1; then
    systemctl reload nginx
    echo "Nginx configured successfully."
else
    echo "ERROR: Nginx configuration test failed!" >&2
    exit 1
fi

# 12. Install cron jobs + backup scripts
echo "[12/14] Installing cron jobs..."
cp "${REPO_DIR}/deploy/scripts/crontab.txt" /tmp/crontab_eventflow.txt
sudo -u "${DEPLOY_USER}" crontab /tmp/crontab_eventflow.txt
rm /tmp/crontab_eventflow.txt
# The crontab calls ~/scripts/backup.sh — install the helpers alongside
install -m 750 -o "${DEPLOY_USER}" -g "${DEPLOY_USER}" \
    "${REPO_DIR}/deploy/scripts/backup.sh" "${DEPLOY_DIR}/scripts/backup.sh"
install -m 750 -o "${DEPLOY_USER}" -g "${DEPLOY_USER}" \
    "${REPO_DIR}/deploy/scripts/restore.sh" "${DEPLOY_DIR}/scripts/restore.sh"

# 13. Set proper permissions
echo "[13/14] Setting permissions..."
chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "${BACKEND_DIR}"
chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "${MEDIA_DIR}"
chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "${LOG_DIR}"
chmod 600 "${BACKEND_DIR}/.env"
chmod 750 "${BACKEND_DIR}/logs"

# 14. Start services
echo "[14/14] Starting services..."
systemctl start "${REDIS_SERVICE}" && systemctl enable "${REDIS_SERVICE}"
systemctl start "${MYSQL_SERVICE}" && systemctl enable "${MYSQL_SERVICE}"
systemctl restart eventflow
systemctl restart eventflow-frontend

# Verify services
echo ""
echo "Verifying services..."
if systemctl is-active --quiet eventflow; then
    echo "  EventFlow API: running"
else
    echo "  ERROR: EventFlow API failed to start!" >&2
    systemctl status eventflow --no-pager || true
    exit 1
fi

if systemctl is-active --quiet eventflow-frontend; then
    echo "  EventFlow Frontend: running"
else
    echo "  ERROR: EventFlow frontend failed to start!" >&2
    systemctl status eventflow-frontend --no-pager || true
    exit 1
fi

if systemctl is-active --quiet "${REDIS_SERVICE}"; then
    echo "  Redis: running"
else
    echo "  WARNING: Redis not running"
fi

if systemctl is-active --quiet "${MYSQL_SERVICE}"; then
    echo "  MySQL/MariaDB: running"
else
    echo "  WARNING: MySQL/MariaDB not running"
fi

if systemctl is-active --quiet nginx; then
    echo "  Nginx: running"
else
    echo "  WARNING: Nginx not running"
fi

# Set up Let's Encrypt (interactive)
echo ""
echo "=== TLS Certificate Setup ==="
echo "Run the following to set up HTTPS:"
echo "  certbot --nginx -d ${APP_HOST} -d ${API_HOST} -d ${MEDIA_HOST}"
echo ""
echo "=== Deployment Complete ==="
echo "Backend: https://${API_HOST}"
echo "Frontend: https://${APP_HOST}"
echo "Media: https://${MEDIA_HOST}"
echo ""
echo "IMPORTANT: Review ${BACKEND_DIR}/.env and update database credentials!"
echo "Note: set NEXT_PUBLIC_API_URL in ${BACKEND_DIR}/.env (or"
echo "frontend/.env.production) to match https://${API_HOST}/api/v1 if you change domains."
