#!/bin/bash
set -euo pipefail

# ============================================================
# EventFlow VPS Deployment Script (IP-based, no domain)
# Run as root: bash deploy_vps.sh
# VPS: 31.42.125.6
# ============================================================

VPS_IP="31.42.125.6"
DEPLOY_USER="eventflow"
DEPLOY_DIR="/home/eventflow"
BACKEND_DIR="${DEPLOY_DIR}/python/eventflow-api"
FRONTEND_DIR="${DEPLOY_DIR}/frontend/public_html"
MEDIA_DIR="${DEPLOY_DIR}/media"
LOG_DIR="${BACKEND_DIR}/logs"

echo "============================================"
echo "  EventFlow VPS Deployment"
echo "  VPS IP: ${VPS_IP}"
echo "============================================"
echo ""

# Step 1: System packages
echo "[1/16] Installing system packages..."
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    nginx mariadb-server redis-server \
    python3 python3-venv python3-pip \
    python3-dev default-libmysqlclient-dev build-essential \
    certbot curl git ufw

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
echo "  Database password: ${DB_PASSWORD}"

# Step 4: Create deployment user
echo "[4/16] Creating deployment user..."
if ! id -u "${DEPLOY_USER}" >/dev/null 2>&1; then
    useradd --system --shell /bin/bash --home-dir "${DEPLOY_DIR}" "${DEPLOY_USER}"
fi

# Step 5: Create directory structure
echo "[5/16] Creating directories..."
mkdir -p "${BACKEND_DIR}" "${FRONTEND_DIR}" "${MEDIA_DIR}" "${LOG_DIR}"
mkdir -p "${MEDIA_DIR}/tenants/logos" "${MEDIA_DIR}/tenants/settings"
mkdir -p "${MEDIA_DIR}/venues" "${MEDIA_DIR}/invoices/logos"
mkdir -p "${MEDIA_DIR}/invoices/pdf" "${MEDIA_DIR}/contracts/pdf"
mkdir -p "${MEDIA_DIR}/branding/logos" "${MEDIA_DIR}/branding/favicons"
mkdir -p "${BACKEND_DIR}/staticfiles"
mkdir -p "${DEPLOY_DIR}/scripts" "${DEPLOY_DIR}/backups/daily" "${DEPLOY_DIR}/backups/weekly"
chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "${DEPLOY_DIR}"

# Step 6: Copy project files
echo "[6/16] Copying project files..."
# Look for the project in common locations
PROJECT_SRC=""
for candidate in /tmp/eventflow-deploy /root/eventflow /home/*/eventflow /opt/eventflow; do
    if [ -d "$candidate/backend" ] || [ -d "$candidate/manage.py" ]; then
        PROJECT_SRC="$candidate"
        break
    fi
done

if [ -z "$PROJECT_SRC" ]; then
    echo "  ERROR: Cannot find EventFlow project files."
    echo "  Upload your project to /tmp/eventflow-deploy/ first:"
    echo "    scp -r /home/builddastaan/EventFlow root@${VPS_IP}:/tmp/eventflow-deploy/"
    exit 1
fi

echo "  Found project at: ${PROJECT_SRC}"

# Copy backend
if [ -d "${PROJECT_SRC}/backend" ]; then
    rsync -av --exclude='__pycache__' --exclude='*.pyc' --exclude='.env' --exclude='node_modules' \
        "${PROJECT_SRC}/backend/" "${BACKEND_DIR}/"
elif [ -f "${PROJECT_SRC}/manage.py" ]; then
    rsync -av --exclude='__pycache__' --exclude='*.pyc' --exclude='.env' --exclude='node_modules' \
        "${PROJECT_SRC}/" "${BACKEND_DIR}/"
fi

# Copy frontend build (if exists)
if [ -d "${PROJECT_SRC}/frontend-build" ]; then
    rsync -av "${PROJECT_SRC}/frontend-build/" "${FRONTEND_DIR}/"
elif [ -d "${PROJECT_SRC}/frontend/out" ]; then
    rsync -av "${PROJECT_SRC}/frontend/out/" "${FRONTEND_DIR}/"
elif [ -d "${PROJECT_SRC}/frontend/public_html" ]; then
    rsync -av "${PROJECT_SRC}/frontend/public_html/" "${FRONTEND_DIR}/"
else
    echo "  WARNING: No frontend build found. Building frontend..."
    if [ -d "${PROJECT_SRC}/frontend" ] && command -v npm &>/dev/null; then
        cd "${PROJECT_SRC}/frontend"
        npm install --silent
        npm run build
        if [ -d "out" ]; then
            rsync -av out/ "${FRONTEND_DIR}/"
        fi
    else
        echo "  Skipping frontend build (npm not available)."
    fi
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
DJANGO_ALLOWED_HOSTS=${VPS_IP}
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

# Step 13: Install systemd service
echo "[13/16] Installing systemd service..."
cat > /etc/systemd/system/eventflow.service << SERVICEEOF
[Unit]
Description=EventFlow Django API
Requires=network.target redis-server.service mariadb.service
After=network.target redis-server.service mariadb.service

[Service]
Type=notify
NotifyAccess=all
User=${DEPLOY_USER}
Group=${DEPLOY_USER}
WorkingDirectory=${BACKEND_DIR}
ExecStart=${BACKEND_DIR}/venv/bin/gunicorn config.wsgi:application -c gunicorn.conf.py
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s TERM \$MAINPID
Restart=on-failure
RestartSec=5
TimeoutStartSec=60
TimeoutStopSec=30
TimeoutReloadSec=30

EnvironmentFile=${BACKEND_DIR}/.env

NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=read-only
ReadWritePaths=${MEDIA_DIR} ${BACKEND_DIR}/staticfiles ${LOG_DIR}
PrivateTmp=yes
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectControlGroups=yes

LimitNOFILE=65535
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
SERVICEEOF

systemctl daemon-reload
systemctl enable eventflow

# Step 14: Configure Nginx
echo "[14/16] Configuring Nginx..."
cat > /etc/nginx/sites-available/eventflow << 'NGINXEOF'
server_tokens off;

upstream eventflow_backend {
    server 127.0.0.1:8000 fail_timeout=0;
    keepalive 32;
}

limit_req_zone $binary_remote_addr zone=api_auth:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=api_general:10m rate=30r/s;
limit_req_zone $binary_remote_addr zone=webhook:10m rate=20r/s;

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    client_max_body_size 10M;

    location ~ /\.(env|git|htaccess|htpasswd|svn) {
        deny all;
        return 404;
    }

    location ~* \.(php|php[0-9s]*|phtml|pht|phps|cgi|pl|py|asp|aspx|jsp|sh|bash|exe|bat|cmd|com|msi|scr|vbs|vbe|ps1|dll|hta)$ {
        deny all;
        return 404;
    }

    root /home/eventflow/frontend/public_html;
    index index.html;

    location / {
        try_files $uri $uri/ @api;
    }

    location @api {
        limit_req zone=api_general burst=50 nodelay;
        proxy_pass http://eventflow_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Request-ID $request_id;
        proxy_redirect off;
        proxy_buffering off;
        proxy_read_timeout 120s;
        proxy_connect_timeout 5s;
    }

    location /api/v1/auth/ {
        limit_req zone=api_auth burst=10 nodelay;
        proxy_pass http://eventflow_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Request-ID $request_id;
        proxy_redirect off;
        proxy_buffering off;
    }

    location /api/v1/payments/webhook/ {
        limit_req zone=webhook burst=20 nodelay;
        proxy_pass http://eventflow_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Request-ID $request_id;
        proxy_redirect off;
        proxy_buffering off;
    }

    location /health/ {
        proxy_pass http://eventflow_backend;
        proxy_set_header Host $host;
        access_log off;
    }

    location /ready/ {
        proxy_pass http://eventflow_backend;
        proxy_set_header Host $host;
        access_log off;
    }

    location /live/ {
        proxy_pass http://eventflow_backend;
        proxy_set_header Host $host;
        access_log off;
    }

    location /admin/ {
        proxy_pass http://eventflow_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /_next/static/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_min_length 1000;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml text/javascript image/svg+xml;
}

server {
    listen 8080;
    listen [::]:8080;
    server_name _;

    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;

    root /home/eventflow/media;

    location ~ /\.(env|git|htaccess|htpasswd|svn) {
        deny all;
        return 404;
    }

    location ~* \.(jpg|jpeg|png|gif|webp|pdf)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    location ~* \.(php|php[0-9s]*|phtml|pht|phps|cgi|pl|py|asp|aspx|jsp|sh|bash|exe|bat|cmd|com|msi|scr|vbs|vbe|ps1|dll|hta)$ {
        deny all;
        return 404;
    }

    autoindex off;

    location / {
        try_files $uri $uri/ =404;
    }
}
NGINXEOF

ln -sf /etc/nginx/sites-available/eventflow /etc/nginx/sites-enabled/eventflow
rm -f /etc/nginx/sites-enabled/default

if nginx -t 2>&1; then
    systemctl reload nginx
    echo "  Nginx configured."
else
    echo "  ERROR: Nginx config test failed!"
    nginx -t
fi

# Step 15: Configure firewall
echo "[15/16] Configuring UFW firewall..."
ufw --force reset >/dev/null 2>&1 || true
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 8080/tcp
ufw --force enable

# Step 16: Set permissions and start
echo "[16/16] Final permissions and start..."
chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "${BACKEND_DIR}"
chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "${MEDIA_DIR}"
chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "${LOG_DIR}"
chmod 600 "${BACKEND_DIR}/.env"
chmod 750 "${LOG_DIR}"

systemctl restart eventflow

# Verification
echo ""
echo "============================================"
echo "  DEPLOYMENT COMPLETE"
echo "============================================"
echo ""

echo "Service Status:"
for svc in eventflow nginx mariadb redis-server; do
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
        echo "  [OK] $svc"
    else
        echo "  [FAIL] $svc"
    fi
done

echo ""
echo "Quick Verification:"
echo "  curl -s http://${VPS_IP}/health/ && echo"
echo "  curl -s http://${VPS_IP}:8080/"
echo ""

echo "Access URLs:"
echo "  Frontend + API: http://${VPS_IP}/"
echo "  Django Admin:   http://${VPS_IP}/admin/"
echo "  Media files:    http://${VPS_IP}:8080/"
echo "  Health check:   http://${VPS_IP}/health/"
echo "  Readiness:      http://${VPS_IP}/ready/"
echo ""

echo "IMPORTANT: Save these credentials:"
echo "  DB_USER=eventflow"
echo "  DB_PASSWORD=${DB_PASSWORD}"
echo ""
echo "To create a superuser:"
echo "  cd ${BACKEND_DIR}"
echo "  sudo -u ${DEPLOY_USER} ${BACKEND_DIR}/venv/bin/python manage.py createsuperuser"
