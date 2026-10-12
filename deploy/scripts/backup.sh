#!/bin/bash
set -euo pipefail

# EventFlow VPS Backup Script
# Schedule via cron: 0 2 * * * /home/eventflow/scripts/backup.sh
# Keeps 7 daily backups, 4 weekly backups

BACKUP_DIR="${BACKUP_DIR:-/home/eventflow/backups}"
DB_NAME="${DB_NAME:-eventflow}"
DB_USER="${DB_USER:-eventflow}"
MEDIA_DIR="${MEDIA_DIR:-/home/eventflow/media}"
LOG_DIR="/home/eventflow/python/eventflow-api/logs"
RETENTION_DAYS=7
WEEKLY_RETENTION=4

# Off-site copy target. Leave OFFSITE_REMOTE unset to skip (with a loud
# warning). Set it to an rsync destination, e.g. "backup@backuphost:eventflow/".
# A failed off-site copy exits non-zero so cron's mail/monitoring sees it,
# but never rolls back the local backup that already succeeded.
OFFSITE_REMOTE="${OFFSITE_REMOTE:-}"
OFFSITE_TIMEOUT="${OFFSITE_TIMEOUT:-3600}"

DATE=$(date +%Y%m%d_%H%M%S)
DAILY_DIR="${BACKUP_DIR}/daily"
WEEKLY_DIR="${BACKUP_DIR}/weekly"

# Database credentials from the backend .env (mysqldump under cron has no
# interactive prompt and no ~/.my.cnf). The password goes into a 600 temp
# defaults file that is removed on exit — never on argv, never echoed.
ENV_FILE="${ENV_FILE:-/home/eventflow/python/eventflow-api/.env}"
DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-3306}"

MYSQL_CNF=""
cleanup() { if [ -n "${MYSQL_CNF}" ]; then rm -f "${MYSQL_CNF}"; fi; }
trap cleanup EXIT

if [ -f "${ENV_FILE}" ]; then
    ENV_DB_USER=$(sed -n 's/^DB_USER=//p' "${ENV_FILE}" | tail -1)
    ENV_DB_NAME=$(sed -n 's/^DB_NAME=//p' "${ENV_FILE}" | tail -1)
    ENV_DB_PASS=$(sed -n 's/^DB_PASSWORD=//p' "${ENV_FILE}" | tail -1)
    ENV_DB_HOST=$(sed -n 's/^DB_HOST=//p' "${ENV_FILE}" | tail -1)
    ENV_DB_PORT=$(sed -n 's/^DB_PORT=//p' "${ENV_FILE}" | tail -1)
    DB_USER="${DB_USER_OVERRIDE:-${ENV_DB_USER:-${DB_USER}}}"
    DB_NAME="${ENV_DB_NAME:-${DB_NAME}}"
    DB_PASSWORD="${ENV_DB_PASS}"
    DB_HOST="${ENV_DB_HOST:-${DB_HOST}}"
    DB_PORT="${ENV_DB_PORT:-${DB_PORT}}"
fi

MYSQL_ARGS=()
if [ -n "${DB_PASSWORD:-}" ]; then
    MYSQL_CNF=$(mktemp)
    chmod 600 "${MYSQL_CNF}"
    {
        echo "[client]"
        echo "user=${DB_USER}"
        echo "password=${DB_PASSWORD}"
        echo "host=${DB_HOST}"
        echo "port=${DB_PORT}"
    } > "${MYSQL_CNF}"
    MYSQL_ARGS=(--defaults-extra-file="${MYSQL_CNF}")
else
    echo "[$(date)] WARNING: no DB_PASSWORD found in ${ENV_FILE} — trying passwordless auth." >&2
fi

mkdir -p "${DAILY_DIR}" "${WEEKLY_DIR}"

echo "[$(date)] Starting backup..."

# 1. Database backup
# --skip-lock avoids table locking issues with mixed InnoDB/MyISAM
echo "[$(date)] Backing up database..."
mysqldump "${MYSQL_ARGS[@]+"${MYSQL_ARGS[@]}"}" --skip-lock --routines --triggers \
    "${DB_NAME}" | gzip > "${DAILY_DIR}/db_${DATE}.sql.gz"

# 2. Media backup
echo "[$(date)] Backing up media..."
tar czf "${DAILY_DIR}/media_${DATE}.tar.gz" -C "$(dirname ${MEDIA_DIR})" "$(basename ${MEDIA_DIR})" 2>/dev/null || true

# 3. Configuration backup (EXCLUDES .env with secrets)
echo "[$(date)] Backing up configuration..."
tar czf "${DAILY_DIR}/config_${DATE}.tar.gz" \
    -C "$(dirname ${BACKEND_DIR:-/home/eventflow/python/eventflow-api})" \
    gunicorn.conf.py 2>/dev/null || true

# 4. Cleanup old daily backups
echo "[$(date)] Cleaning up old daily backups..."
find "${DAILY_DIR}" -name "db_*.sql.gz" -mtime +${RETENTION_DAYS} -delete 2>/dev/null || true
find "${DAILY_DIR}" -name "media_*.tar.gz" -mtime +${RETENTION_DAYS} -delete 2>/dev/null || true
find "${DAILY_DIR}" -name "config_*.tar.gz" -mtime +${RETENTION_DAYS} -delete 2>/dev/null || true

# 5. Weekly backup (Sundays)
if [ $(date +%u) -eq 7 ]; then
    echo "[$(date)] Creating weekly backup..."
    cp "${DAILY_DIR}/db_${DATE}.sql.gz" "${WEEKLY_DIR}/"
    # Cleanup old weekly backups
    find "${WEEKLY_DIR}" -name "db_*.sql.gz" -mtime +$((WEEKLY_RETENTION * 7)) -delete 2>/dev/null || true
fi

# 6. Verify backup integrity
LATEST_DB=$(ls -t "${DAILY_DIR}"/db_*.sql.gz 2>/dev/null | head -1)
if [ -n "${LATEST_DB}" ]; then
    if gzip -t "${LATEST_DB}" 2>/dev/null; then
        echo "[$(date)] Backup verified: ${LATEST_DB}"
    else
        echo "[$(date)] ERROR: Backup verification failed!" >&2
        exit 1
    fi
else
    echo "[$(date)] ERROR: No database backup found!" >&2
    exit 1
fi

# 7. Copy off-site so a host loss does not take the backups with it
if [ -n "${OFFSITE_REMOTE}" ]; then
    echo "[$(date)] Copying backups off-site to ${OFFSITE_REMOTE}..."
    if rsync -a --timeout="${OFFSITE_TIMEOUT}" \
        "${DAILY_DIR}/" "${OFFSITE_REMOTE}/daily/" \
        && rsync -a --timeout="${OFFSITE_TIMEOUT}" \
        "${WEEKLY_DIR}/" "${OFFSITE_REMOTE}/weekly/"; then
        echo "[$(date)] Off-site copy OK."
    else
        # Local backup is still good — report loudly rather than deleting it.
        echo "[$(date)] ERROR: off-site copy FAILED (local backup retained)." >&2
        exit 1
    fi
else
    echo "[$(date)] WARNING: OFFSITE_REMOTE is unset — backups exist only on this host." >&2
    echo "[$(date)]          Set OFFSITE_REMOTE (rsync target) so a host loss is survivable." >&2
fi

echo "[$(date)] Backup complete."
