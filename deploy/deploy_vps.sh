#!/bin/bash
set -euo pipefail

# ============================================================
# EventFlow VPS Deployment Script (IP-based, no domain)
# Run as root: VPS_IP=<your.server.ip> bash deploy_vps.sh
#
# VPS_IP is REQUIRED and must be passed in — this script refuses to
# guess or hardcode a server address.
#
# Frontend model: `next build` + `next start` on 127.0.0.1:3000 behind
# nginx (deploy/nginx/eventflow-ip.conf). No static out/ directory.
# ============================================================

VPS_IP="${VPS_IP:-}"
if [ -z "${VPS_IP}" ]; then
    echo "ERROR: VPS_IP is required (the public IPv4/IPv6 of this server)." >&2
    echo "  Usage: VPS_IP=203.0.113.10 bash $0" >&2
    exit 1
fi
if ! printf '%s' "${VPS_IP}" | grep -Eq '^[A-Za-z0-9.:-]+$'; then
    echo "ERROR: VPS_IP '${VPS_IP}' contains unexpected characters." >&2
    exit 1
fi

DEPLOY_USER="eventflow"
DEPLOY_DIR="/home/eventflow"
BACKEND_DIR="${DEPLOY_DIR}/python/eventflow-api"
REPO_DIR="${DEPLOY_DIR}/eventflow"
MEDIA_DIR="${DEPLOY_DIR}/media"
LOG_DIR="${BACKEND_DIR}/logs"

# API base URL baked into the frontend at build time (IP mode => http).
NEXT_PUBLIC_API_URL="${NEXT_PUBLIC_API_URL:-http://${VPS_IP}/api/v1}"

echo "============================================"
echo "  EventFlow VPS Deployment"
echo "  VPS IP: ${VPS_IP}"
echo "  API URL: ${NEXT_PUBLIC_API_URL}"
echo "============================================"
echo ""

# Step 1: System packages
echo "[1/16] Installing system packages..."
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    nginx mariadb-server redis-server \
    python3 python3-venv python3-pip \
    python3-dev default-libmysqlclient-dev build-essential \
    certbot curl git ufw rsync

# Node.js >= 20 (frontend build AND `next start`)
if ! command -v node >/dev/null 2>&1; then
    echo "  Node.js not found — installing Node.js 20 (nodesource)..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nodejs
fi
NODE_MAJOR=$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)
if [ "${NODE_MAJOR}" -lt 20 ]; then
    echo "ERROR: Node $(node -v) is too old — Next.js 16 requires Node >= 20." >&2
    echo "  Install Node 20+: https://nodejs.org or nodesource setup_20.x" >&2
    exit 1
fi
echo "  Node $(node -v)"

# Step 2: Start and enable services
echo "[2/16] Starting MySQL and Redis..."
systemctl start mariadb
systemctl enable mariadb
systemctl start redis-server
systemctl enable redis-server

# Step 3: Create MySQL database and user
echo "[3/16] Setting up MySQL database..."
DB_PASSWORD=$(python3 -c "import secrets;print(secrets.token_urlsafe(20))")
mysql -e "CREATE DATABASE IF NOT EXISTS eventflow CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER IF NOT EXISTS 'eventflow'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';"
mysql -e "GRANT ALL PRIVILEGES ON eventflow.* TO 'eventflow'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"
echo "  Database user: eventflow"

# Step 4: Create deployment user
echo "[4/16] Creating deployment user..."
if ! id -u "${DEPLOY_USER}" >/dev/null 2>&1; then
    useradd --system --shell /bin/bash --home-dir "${DEPLOY_DIR}" "${DEPLOY_USER}"
fi

# Step 5: Create directory structure
echo "[5/16] Creating directories..."
mkdir -p "${BACKEND_DIR}" "${MEDIA_DIR}" "${LOG_DIR}" "${REPO_DIR}"
mkdir -p "${MEDIA_DIR}/tenants/logos" "${MEDIA_DIR}/tenants/settings"
mkdir -p "${MEDIA_DIR}/venues" "${MEDIA_DIR}/invoices/logos"
mkdir -p "${MEDIA_DIR}/invoices/pdf" "${MEDIA_DIR}/contracts/pdf"
mkdir -p "${MEDIA_DIR}/branding/logos" "${MEDIA_DIR}/branding/favicons"
mkdir -p "${BACKEND_DIR}/staticfiles"
mkdir -p "${DEPLOY_DIR}/scripts" "${DEPLOY_DIR}/backups/daily" "${DEPLOY_DIR}/backups/weekly"
chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "${DEPLOY_DIR}"

# Step 6: Copy project files
echo "[6/16] Copy project files..."
# Look for the project in common locations
PROJECT_SRC=""
for candidate in /tmp/eventflow-deploy /root/eventflow /home/*/eventflow /opt/eventflow; do
    if [ -d "$candidate/backend" ] || [ -f "$candidate/manage.py" ]; then
        PROJECT_SRC="$candidate"
        break
    fi
done

if [ -z "${PROJECT_SRC}" ]; then
    echo "  ERROR: Cannot find EventFlow project files."
    echo "  Upload your project to /tmp/eventflow-deploy/ first:"
    echo "    scp -r /home/builddastaan/EventFlow root@${VPS_IP}:/tmp/eventflow-deploy/"
    exit 1
fi

echo "  Found project at: ${PROJECT_SRC}"

# Keep a stable checkout at ${REPO_DIR} — systemd units and the CD script
# (deploy_production.sh) both run from there.
if [ "${PROJECT_SRC%/}" != "${REPO_DIR%/}" ]; then
    rsync -a --delete \
        --exclude='.git' --exclude='node_modules' --exclude='.next' \
        --exclude='out' --exclude='venv' --exclude='logs' \
        --exclude='staticfiles' --exclude='.env' --exclude='media' \
        --exclude='__pycache__' --exclude='*.pyc' \
        "${PROJECT_SRC}/" "${REPO_DIR}/"
    echo "  Project synced to ${REPO_DIR}"
else
    echo "  Project already at ${REPO_DIR}"
fi
chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "${REPO_DIR}"

# Backend runtime tree (what Gunicorn executes)
if [ ! -f "${REPO_DIR}/backend/manage.py" ] && [ ! -f "${PROJECT_SRC}/manage.py" ]; then
    echo "  ERROR: no backend/manage.py found in ${PROJECT_SRC}" >&2
    exit 1
fi
if [ -f "${REPO_DIR}/backend/manage.py" ]; then
    rsync -a --delete \
        --exclude='.env' --exclude='venv/' --exclude='logs/' \
        --exclude='staticfiles/' --exclude='media/' \
        --exclude='__pycache__/' --exclude='*.pyc' --exclude='*.sqlite3' \
        "${REPO_DIR}/backend/" "${BACKEND_DIR}/"
else
    rsync -a --delete \
        --exclude='.env' --exclude='venv/' --exclude='logs/' \
        --exclude='staticfiles/' --exclude='media/' \
        --exclude='__pycache__/' --exclude='*.pyc' --exclude='*.sqlite3' \
        "${PROJECT_SRC}/" "${BACKEND_DIR}/"
fi

# Step 7: Set up Python virtual environment
echo "[7/16] Setting up Python virtual environment..."
if [ ! -d "${BACKEND_DIR}/venv" ]; then
    sudo -u "${DEPLOY_USER}" python3 -m venv "${BACKEND_DIR}/venv"
fi
sudo -u "${DEPLOY_USER}" "${BACKEND_DIR}/venv/bin/pip" install --upgrade pip --quiet
sudo -u "${DEPLOY_USER}" "${BACKEND_DIR}/venv/bin/pip" install -r "${BACKEND_DIR}/requirements/production.txt" --quiet

# Step 8: Generate production .env
echo "[8/16] Generating .env..."
if [ ! -f "${BACKEND_DIR}/.env" ]; then
    ENCRYPTION_KEY=$(python3 -c "import secrets,base64;print(base64.b64encode(secrets.token_bytes(32)).decode())")
    SECRET_KEY=$(python3 -c "import secrets;print(secrets.token_urlsafe(50))")
    cat > "${BACKEND_DIR}/.env" << EOF
DJANGO_SETTINGS_MODULE=config.settings.production
DJANGO_SECRET_KEY=${SECRET_KEY}
DJANGO_ALLOWED_HOSTS=${VPS_IP},localhost,127.0.0.1
DJANGO_DEBUG=False
DB_NAME=eventflow
DB_USER=eventflow
DB_PASSWORD=${DB_PASSWORD}
DB_HOST=127.0.0.1
DB_PORT=3306
REDIS_URL=redis://127.0.0.1:6379/0
ENCRYPTION_KEY=${ENCRYPTION_KEY}
CORS_ALLOWED_ORIGINS=http://${VPS_IP}
CSRF_TRUSTED_ORIGINS=http://${VPS_IP}
DEFAULT_FROM_EMAIL=noreply@eventflow.local
# Frontend build input for deploy_production.sh (not a secret)
NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL}
EOF
    chmod 600 "${BACKEND_DIR}/.env"
    chown "${DEPLOY_USER}:${DEPLOY_USER}" "${BACKEND_DIR}/.env"
    echo "  .env created with generated secrets."
else
    echo "  .env already exists, skipping."
fi

# Step 9: Run Django migrations
echo "[9/16] Running Django migrations..."
cd "${BACKEND_DIR}"
sudo -u "${DEPLOY_USER}" "${BACKEND_DIR}/venv/bin/python" manage.py migrate --noinput

# Step 10: Collect static files
echo "[10/16] Collecting static files..."
sudo -u "${DEPLOY_USER}" "${BACKEND_DIR}/venv/bin/python" manage.py collectstatic --noinput

# Step 11: Create logs directory
echo "[11/16] Setting up logs..."
mkdir -p "${LOG_DIR}"
chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "${LOG_DIR}"

# Step 12: Validate deployment
echo "[12/16] Validating deployment..."
sudo -u "${DEPLOY_USER}" "${BACKEND_DIR}/venv/bin/python" manage.py validate_deployment || true

# Step 13: Install systemd services (from the repo — single source of truth)
echo "[13/16] Installing systemd services..."
cp "${REPO_DIR}/deploy/systemd/eventflow.service" /etc/systemd/system/
cp "${REPO_DIR}/deploy/systemd/eventflow-frontend.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable eventflow eventflow-frontend

# Step 14: Configure Nginx (IP-based config, no placeholders)
echo "[14/16] Configuring Nginx..."
cp "${REPO_DIR}/deploy/nginx/eventflow-ip.conf" /etc/nginx/sites-available/eventflow
ln -sf /etc/nginx/sites-available/eventflow /etc/nginx/sites-enabled/eventflow
rm -f /etc/nginx/sites-enabled/default

if nginx -t 2>&1; then
    systemctl reload nginx
    echo "  Nginx configured."
else
    echo "  ERROR: Nginx config test failed!"
    nginx -t
    exit 1
fi

# Step 15: Configure firewall
echo "[15/16] Configuring UFW firewall..."
ufw --force reset >/dev/null 2>&1 || true
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8080/tcp
ufw --force enable

# Step 16: Build frontend, set permissions, start services
echo "[16/16] Building frontend and starting services..."
export NEXT_PUBLIC_API_URL
cd "${REPO_DIR}/frontend"
sudo -u "${DEPLOY_USER}" npm ci --silent
sudo -u "${DEPLOY_USER}" npm run build
if [ ! -f ".next/BUILD_ID" ]; then
    echo "  ERROR: frontend build produced no .next/BUILD_ID" >&2
    exit 1
fi
echo "  Frontend built (.next/BUILD_ID=$(cat .next/BUILD_ID))"

# Backup helpers referenced by the crontab
install -m 750 -o "${DEPLOY_USER}" -g "${DEPLOY_USER}" \
    "${REPO_DIR}/deploy/scripts/backup.sh" "${DEPLOY_DIR}/scripts/backup.sh"
install -m 750 -o "${DEPLOY_USER}" -g "${DEPLOY_USER}" \
    "${REPO_DIR}/deploy/scripts/restore.sh" "${DEPLOY_DIR}/scripts/restore.sh"

chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "${BACKEND_DIR}"
chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "${REPO_DIR}"
chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "${MEDIA_DIR}"
chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "${LOG_DIR}"
chmod 600 "${BACKEND_DIR}/.env"
chmod 750 "${LOG_DIR}"

# Cron jobs (reminders, reports, backups)
if command -v crontab >/dev/null 2>&1; then
    sudo -u "${DEPLOY_USER}" crontab "${REPO_DIR}/deploy/scripts/crontab.txt"
    echo "  Crontab installed."
fi

systemctl restart eventflow
systemctl restart eventflow-frontend

# Verification
echo ""
echo "============================================"
echo "  DEPLOYMENT COMPLETE"
echo "============================================"
echo ""

echo "Service Status:"
for svc in eventflow eventflow-frontend nginx mariadb redis-server; do
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
        echo "  [OK] $svc"
    else
        echo "  [FAIL] $svc"
    fi
done

echo ""
echo "Direct health checks (bypass nginx):"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/live/ || echo 000)
echo "  gunicorn /live/  -> ${STATUS} (expect 200)"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3000/ || echo 000)
echo "  next start /     -> ${STATUS} (expect 200)"

echo ""
echo "Access URLs:"
echo "  Frontend + API: http://${VPS_IP}/"
echo "  Django Admin:   http://${VPS_IP}/admin/"
echo "  Media files:    http://${VPS_IP}:8080/ (public trees only)"
echo "  Health check:   http://${VPS_IP}/health/"
echo "  Readiness:      http://${VPS_IP}/ready/"
echo ""

echo "IMPORTANT: Save these credentials (also in ${BACKEND_DIR}/.env):"
echo "  DB_USER=eventflow"
echo "  DB_PASSWORD=<see ${BACKEND_DIR}/.env>"
echo ""
echo "To create a superuser:"
echo "  cd ${BACKEND_DIR}"
echo "  sudo -u ${DEPLOY_USER} ${BACKEND_DIR}/venv/bin/python manage.py createsuperuser"
