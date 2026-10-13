#!/bin/bash
set -euo pipefail
# =============================================================================
# Baseify / EventFlow — idempotent fresh-Ubuntu VPS bootstrap
# =============================================================================
# Run AS ROOT on a freshly installed Ubuntu VPS (safe to re-run; every step
# checks before it changes anything). It prepares the host for the Docker
# Compose deployment flow:
#
#   1. Docker Engine + Compose plugin (official Docker apt repository)
#   2. Dedicated deploy user (docker group ONLY — no sudoers rules needed)
#   3. SSH public-key setup for the deploy user (+ root, additive)
#   4. UFW firewall: SSH/80/8080/443 — enabled only after the rules exist
#   5. Directory layout under /srv/baseify for this and future SaaS products
#   6. Production secrets generated ON the server into /srv/baseify/eventflow/.env
#      (mode 0600, never printed, never committed, re-runs keep the file)
#   7. Docker log rotation, cron-log directory, 2G swap (fresh VPS default)
#   8. Cron jobs (DB/media backup + scheduled management commands)
#   9. Optional --harden-ssh: disable password auth AFTER the key is confirmed
#      installed (root access stays key-based; run only once your key login
#      works)
#
# Usage:
#   bash deploy/bootstrap/bootstrap_vps.sh \
#       --authorized-key "ssh-ed25519 AAAA… comment" \
#       [--deploy-user deploy] [--ssh-port 22] [--no-ufw] [--no-swap] [--harden-ssh]
#
# Nothing here disables SSH host-key verification, exposes MariaDB/Redis, or
# removes root access. After this script: verify deploy-user SSH login, THEN
# (optionally) --harden-ssh, then trigger the first deployment via GitHub.
# =============================================================================

log()  { printf '[bootstrap] %s\n' "$*"; }
fail() { printf '[bootstrap] ERROR: %s\n' "$*" >&2; exit 1; }
warn() { printf '[bootstrap] WARN: %s\n' "$*" >&2; }

[ "$(id -u)" -eq 0 ] || fail "run as root (sudo bash $0 …)"

DEPLOY_USER="deploy"
SSH_PORT="22"
AUTHORIZED_KEY=""
AUTHORIZED_KEY_FILE=""
ENABLE_UFW=1
ENABLE_SWAP=1
HARDEN_SSH=0
BASE_DIR="/srv/baseify"

while [ $# -gt 0 ]; do
    case "$1" in
        --deploy-user)        DEPLOY_USER="${2:?}"; shift 2 ;;
        --ssh-port)           SSH_PORT="${2:?}"; shift 2 ;;
        --authorized-key)     AUTHORIZED_KEY="${2:?}"; shift 2 ;;
        --authorized-key-file) AUTHORIZED_KEY_FILE="${2:?}"; shift 2 ;;
        --no-ufw)             ENABLE_UFW=0; shift ;;
        --no-swap)            ENABLE_SWAP=0; shift ;;
        --harden-ssh)         HARDEN_SSH=1; shift ;;
        -h|--help)            sed -n '2,30p' "$0"; exit 0 ;;
        *) fail "unknown argument: $1 (see --help)" ;;
    esac
done

if [ -z "$AUTHORIZED_KEY" ] && [ -n "$AUTHORIZED_KEY_FILE" ]; then
    AUTHORIZED_KEY="$(cat "$AUTHORIZED_KEY_FILE")"
fi
if [ -n "$AUTHORIZED_KEY" ]; then
    case "$AUTHORIZED_KEY" in
        ssh-ed25519*|ssh-rsa*|ecdsa-sha2-*) : ;;
        *) fail "--authorized-key must be an OpenSSH PUBLIC key (starts with ssh-ed25519 / ssh-rsa / ecdsa-sha2-…)" ;;
    esac
fi

[ -f /etc/os-release ] || fail "cannot detect OS (/etc/os-release missing)"
# shellcheck disable=SC1091
. /etc/os-release
case "${ID:-}" in
    ubuntu) : ;;
    *) fail "unsupported OS '${ID:-unknown}' — this bootstrap targets Ubuntu" ;;
esac

command -v curl >/dev/null 2>&1 || { log "installing curl/ca-certificates/git/ufw/openssl"; apt-get update -qq && apt-get install -y -qq ca-certificates curl git ufw openssl; }

# -----------------------------------------------------------------------------
# 1. Docker Engine + Compose plugin (official apt repository)
# -----------------------------------------------------------------------------
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    log "Docker already installed: $(docker --version) / $(docker compose version | head -1)"
else
    log "installing Docker Engine + Compose plugin from download.docker.com"
    install -m 0755 -d /etc/apt/keyrings
    if [ ! -f /etc/apt/keyrings/docker.asc ]; then
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        chmod a+r /etc/apt/keyrings/docker.asc
    fi
    ARCH="$(dpkg --print-architecture)"
    CODENAME="${VERSION_CODENAME:-}"
    [ -n "$CODENAME" ] || fail "cannot determine Ubuntu codename from /etc/os-release"
    DOCKER_LIST="/etc/apt/sources.list.d/docker.list"
    if [ ! -f "$DOCKER_LIST" ]; then
        echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${CODENAME} stable" > "$DOCKER_LIST"
    fi
    apt-get update -qq
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi
systemctl enable --now docker >/dev/null 2>&1 || true
docker info >/dev/null 2>&1 || fail "docker daemon is not running (systemctl status docker)"
log "Docker OK: $(docker --version)"

# -----------------------------------------------------------------------------
# 2. Deploy user — docker group only, NO sudo rules (least privilege).
#    NOTE (printed too): membership in the docker group is equivalent to
#    root — that is inherent to Docker's socket model; the account has no
#    sudoers entry and no other elevated rights.
# -----------------------------------------------------------------------------
if id -u "$DEPLOY_USER" >/dev/null 2>&1; then
    log "user ${DEPLOY_USER} already exists"
else
    useradd --create-home --shell /bin/bash "$DEPLOY_USER"
    log "created user ${DEPLOY_USER}"
fi
usermod -aG docker "$DEPLOY_USER"
log "user ${DEPLOY_USER} in docker group (no sudoers entries added)"

# -----------------------------------------------------------------------------
# 3. SSH keys (additive — root access is preserved; nothing is removed)
# -----------------------------------------------------------------------------
if [ -n "$AUTHORIZED_KEY" ]; then
    for target in "$DEPLOY_USER" root; do
        home="$(getent passwd "$target" | cut -d: -f6)"
        [ -n "$home" ] || fail "cannot resolve home for ${target}"
        install -d -m 700 -o "$target" -g "$target" "${home}/.ssh"
        auth="${home}/.ssh/authorized_keys"
        touch "$auth"
        if grep -qxF "$AUTHORIZED_KEY" "$auth" 2>/dev/null; then
            log "key already present for ${target}"
        else
            printf '%s\n' "$AUTHORIZED_KEY" >> "$auth"
            log "key installed for ${target}"
        fi
        chown "$target:$target" "$auth"
        chmod 600 "$auth"
    done
else
    warn "no --authorized-key given: skipping key installation (add your key manually before enabling UFW/hardening)"
fi

# -----------------------------------------------------------------------------
# 4. Firewall — rules are added BEFORE enabling, SSH port is always allowed
# -----------------------------------------------------------------------------
if [ "$ENABLE_UFW" -eq 1 ]; then
    command -v ufw >/dev/null 2>&1 || { apt-get update -qq && apt-get install -y -qq ufw; }
    # Include whatever port sshd actually listens on (in case it is not 22).
    real_ssh_port="$SSH_PORT"
    if [ -r /etc/ssh/sshd_config ]; then
        detected="$(awk '/^[[:space:]]*Port[[:space:]]+/ {print $2; exit}' /etc/ssh/sshd_config || true)"
        [ -n "$detected" ] && real_ssh_port="$detected"
    fi
    ufw allow "${real_ssh_port}/tcp" comment 'SSH' >/dev/null
    [ "$real_ssh_port" = "22" ] || ufw allow 22/tcp comment 'SSH' >/dev/null
    ufw allow 80/tcp  comment 'HTTP'  >/dev/null
    ufw allow 443/tcp comment 'HTTPS (future)' >/dev/null
    ufw allow 8080/tcp comment 'EventFlow media' >/dev/null
    log "UFW rules staged (ssh ${real_ssh_port}, 80, 443, 8080); enabling…"
    ufw --force enable >/dev/null
    log "UFW active: $(ufw status | head -1)"
else
    log "UFW skipped (--no-ufw)"
fi

# -----------------------------------------------------------------------------
# 5. Directory layout (per-product isolation under /srv/baseify)
#    /srv/baseify/eventflow/{repo,media,backups,logs} + .env (0600)
# -----------------------------------------------------------------------------
install -d -m 755 -o root -g root "$BASE_DIR"
install -d -m 755 -o "$DEPLOY_USER" -g "$DEPLOY_USER" \
    "$BASE_DIR/eventflow" \
    "$BASE_DIR/eventflow/repo" \
    "$BASE_DIR/eventflow/backups" \
    "$BASE_DIR/eventflow/logs"
# Media must be writable by the CONTAINER's app user (uid/gid 10001).
install -d -m 755 -o 10001 -g 10001 "$BASE_DIR/eventflow/media"
log "directory layout ready under ${BASE_DIR}/eventflow"

# -----------------------------------------------------------------------------
# 6. Secrets — generated on the server, only if missing, never printed
# -----------------------------------------------------------------------------
ENV_FILE="$BASE_DIR/eventflow/.env"
if [ -f "$ENV_FILE" ]; then
    log "env file exists — keeping existing secrets (${ENV_FILE})"
else
    umask 077
    _secret_key="$(openssl rand -hex 32)"
    _enc_key="$(openssl rand -base64 32)"
    _db_password="$(openssl rand -hex 24)"
    _redis_password="$(openssl rand -hex 24)"
    cat > "$ENV_FILE" <<EOF
# Generated by bootstrap_vps.sh on $(date -u +%Y-%m-%dT%H:%M:%SZ) — mode 0600.
# IP-only HTTP test configuration (no domain yet). When a domain + HTTPS
# exist: update hosts/origins here and flip SESSION_COOKIE_SECURE,
# CSRF_COOKIE_SECURE and SECURE_HSTS_PRELOAD to true.
DJANGO_SECRET_KEY=${_secret_key}
ENCRYPTION_KEY=${_enc_key}
DJANGO_ALLOWED_HOSTS=194.77.89.95,localhost,127.0.0.1
CSRF_TRUSTED_ORIGINS=http://194.77.89.95
CORS_ALLOWED_ORIGINS=http://194.77.89.95
SESSION_COOKIE_SECURE=false
CSRF_COOKIE_SECURE=false
SECURE_HSTS_PRELOAD=false
DB_NAME=eventflow
DB_USER=eventflow
DB_PASSWORD=${_db_password}
REDIS_PASSWORD=${_redis_password}
NEXT_PUBLIC_API_URL=http://194.77.89.95/api/v1
EMAIL_HOST=
EMAIL_PORT=587
EMAIL_HOST_USER=
EMAIL_HOST_PASSWORD=
EMAIL_USE_TLS=true
DEFAULT_FROM_EMAIL=noreply@eventflow.com
SENTRY_DSN=
JWT_ACCESS_TOKEN_LIFETIME=60
JWT_REFRESH_TOKEN_LIFETIME=1440
EVENTFLOW_TAG=local
EVENTFLOW_MEDIA_DIR=${BASE_DIR}/eventflow/media
EOF
    unset _secret_key _enc_key _db_password _redis_password
    chown "$DEPLOY_USER:$DEPLOY_USER" "$ENV_FILE"
    chmod 600 "$ENV_FILE"
    log "generated ${ENV_FILE} (values NOT displayed; mode 0600)"
fi

# -----------------------------------------------------------------------------
# 7a. Docker log rotation (only when no daemon.json exists — never clobber)
# -----------------------------------------------------------------------------
if [ -f /etc/docker/daemon.json ]; then
    log "/etc/docker/daemon.json exists — left untouched (merge log rotation manually if absent)"
else
    printf '{\n  "log-driver": "json-file",\n  "log-opts": {"max-size": "10m", "max-file": "3"}\n}\n' > /etc/docker/daemon.json
    systemctl restart docker
    log "docker log rotation enabled (10m x 3)"
fi

# -----------------------------------------------------------------------------
# 7b. Swap — `next build` on a small VPS needs breathing room
# -----------------------------------------------------------------------------
if [ "$ENABLE_SWAP" -eq 1 ]; then
    if swapon --show | grep -q .; then
        log "swap already present — skipping"
    else
        fallocate -l 2G /swapfile
        chmod 600 /swapfile
        mkswap /swapfile >/dev/null
        swapon /swapfile
        grep -q '/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
        log "2G swap created at /swapfile"
    fi
else
    log "swap skipped (--no-swap)"
fi

# -----------------------------------------------------------------------------
# 7c. Clone the repository (public) so cron/deploys have the scripts
# -----------------------------------------------------------------------------
REPO_DIR="$BASE_DIR/eventflow/repo"
if [ -d "${REPO_DIR}/.git" ]; then
    log "repository already cloned — fetching"
    git -C "$REPO_DIR" fetch --quiet origin || warn "git fetch failed (network?) — existing checkout kept"
else
    # Empty pre-created dir from step 5 must go before clone.
    rmdir "$REPO_DIR" 2>/dev/null || true
    if [ -d "$REPO_DIR" ]; then
        warn "${REPO_DIR} exists and is not a git clone — leaving it for deploy_compose.sh to reconcile"
    else
        git clone --quiet https://github.com/nadeemmx/EventFlow.git "$REPO_DIR"
        chown -R "$DEPLOY_USER:$DEPLOY_USER" "$REPO_DIR"
        log "repository cloned to ${REPO_DIR}"
    fi
fi

# -----------------------------------------------------------------------------
# 8. Cron jobs (marker-guarded — re-runs do not duplicate)
# -----------------------------------------------------------------------------
CRON_FILE="${REPO_DIR}/deploy/docker/crontab.txt"
if [ -f "$CRON_FILE" ]; then
    current_cron="$(crontab -u "$DEPLOY_USER" -l 2>/dev/null || true)"
    if printf '%s' "$current_cron" | grep -q 'eventflow-docker-cron-v1'; then
        log "cron jobs already installed (marker found)"
    else
        { printf '%s\n' "$current_cron"; cat "$CRON_FILE"; } | crontab -u "$DEPLOY_USER" -
        log "cron jobs installed for ${DEPLOY_USER} (backup 02:00 + scheduled commands)"
    fi
else
    warn "crontab template not found at ${CRON_FILE} — install it after the first clone"
fi

# -----------------------------------------------------------------------------
# 9. Optional SSH hardening (OPT-IN; run only after key login is verified)
# -----------------------------------------------------------------------------
if [ "$HARDEN_SSH" -eq 1 ]; then
    root_auth="/root/.ssh/authorized_keys"
    deploy_auth="$(getent passwd "$DEPLOY_USER" | cut -d: -f6)/.ssh/authorized_keys"
    if [ ! -s "$root_auth" ] || [ ! -s "$deploy_auth" ]; then
        fail "--harden-ssh refused: authorized_keys missing/empty for root or ${DEPLOY_USER} — confirm key login works first"
    fi
    mkdir -p /etc/ssh/sshd_config.d
    cat > /etc/ssh/sshd_config.d/99-baseify.conf <<'EOF'
# Baseify hardening (bootstrap_vps.sh --harden-ssh): key-only auth.
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
EOF
    sshd -t || { rm -f /etc/ssh/sshd_config.d/99-baseify.conf; fail "sshd config test failed — hardening NOT applied"; }
    systemctl reload ssh 2>/dev/null || systemctl reload sshd 2>/dev/null || true
    log "SSH hardened: password auth disabled (key-based root + ${DEPLOY_USER} access retained)"
else
    log "SSH hardening skipped (default). Verify key login for ${DEPLOY_USER}, then re-run with --harden-ssh"
fi

# -----------------------------------------------------------------------------
log "DONE. Summary (no secrets shown):"
log "  user      : ${DEPLOY_USER} (docker group only; docker ≈ root — inherent to Docker)"
log "  layout    : ${BASE_DIR}/eventflow/{repo,media,backups,logs} + .env (0600)"
log "  firewall  : $(ufw status 2>/dev/null | head -1 || echo 'ufw not enabled')"
log "  next steps:"
log "    1. Verify SSH:  ssh -p ${SSH_PORT} ${DEPLOY_USER}@<server-ip>   (must succeed)"
log "    2. Optionally:  bash $0 --harden-ssh … (disable password auth)"
log "    3. Deploy via the GitHub 'Deploy' workflow (approval gate required)."
log "    4. When a domain exists: obtain TLS, update .env hosts/origins and"
log "       set SESSION_COOKIE_SECURE/CSRF_COOKIE_SECURE/SECURE_HSTS_PRELOAD=true."
