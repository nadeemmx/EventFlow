#!/bin/bash
set -euo pipefail
# Restore for the EventFlow Docker stack (DESTRUCTIVE — guarded).
#
# Usage:
#   restore.sh db   <eventflow-db-TS.sql.gz> --yes
#   restore.sh media <eventflow-media-TS.tar.gz> --yes
#
# Safety rails:
#   * refuses without --yes (prints exactly what it will do)
#   * takes a FRESH automatic backup before touching anything
#   * db:    stops backend+frontend, DROPs/CREATEs the database, loads the
#            dump, restarts, re-applies migrations, runs the health gate
#   * media: stops backend+frontend+nginx, replaces the media tree, restarts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/../lib.sh"

MODE="${1:-}"
FILE="${2:-}"
CONFIRM="${3:-}"

usage() { fail "usage: restore.sh db|media <archive> --yes"; }
[ -n "$MODE" ] && [ -n "$FILE" ] || usage
[ -f "$FILE" ] || fail "file not found: ${FILE}"
if [ "$CONFIRM" != "--yes" ]; then
    echo "REFUSING: this is a DESTRUCTIVE restore (${MODE}: ${FILE})." >&2
    echo "A fresh automatic backup will be taken first. Re-run as:" >&2
    echo "  $0 ${MODE} ${FILE} --yes" >&2
    exit 2
fi
gzip -t "$FILE" || fail "archive failed gzip integrity check: ${FILE}"

cd "$REPO_DIR"
log "taking a fresh pre-restore backup…"
"${SCRIPT_DIR}/backup.sh"

case "$MODE" in
db)
    set -a; # shellcheck disable=SC1090
    . "$ENV_FILE"; set +a
    : "${DB_NAME:=eventflow}"
    : "${DB_USER:=eventflow}"
    [ -n "${DB_PASSWORD:-}" ] || fail "DB_PASSWORD missing from ${ENV_FILE}"

    log "stopping backend + frontend (schema swap window)…"
    compose stop backend frontend

    log "dropping and recreating database ${DB_NAME}…"
    compose exec -T -e "MYSQL_PWD=${DB_PASSWORD}" mariadb \
        -u"${DB_USER}" -e "DROP DATABASE IF EXISTS \`${DB_NAME}\`; CREATE DATABASE \`${DB_NAME}\`;"

    log "loading ${FILE}…"
    gzip -dc "$FILE" | compose exec -T -e "MYSQL_PWD=${DB_PASSWORD}" mariadb \
        -u"${DB_USER}" "${DB_NAME}"

    log "restarting stack and re-applying migrations…"
    compose start backend frontend
    # compose() resolves EVENTFLOW_TAG from the recorded deploy SHA (lib.sh),
    # so migrations run in the image that is serving traffic — not the .env
    # default ("local").
    compose run --rm backend python manage.py migrate --noinput
    nginx_reload
    wait_health 30 || fail "restore completed but health gate failed — inspect: docker compose … ps / logs"
    log "db restore complete and healthy"
    ;;
media)
    MEDIA_DIR="${EVENTFLOW_MEDIA_DIR:-/srv/baseify/eventflow/media}"
    log "stopping backend + frontend + nginx (media swap)…"
    compose stop backend frontend nginx

    log "replacing ${MEDIA_DIR} contents…"
    find "$MEDIA_DIR" -mindepth 1 -delete
    tar -xzf "$FILE" -C "$(dirname "$MEDIA_DIR")"
    # Restore ownership for the container app user (uid 10001).
    chown -R 10001:10001 "$MEDIA_DIR"

    log "restarting stack…"
    compose start nginx backend frontend
    nginx_reload
    wait_health 30 || fail "restore completed but health gate failed — inspect: docker compose … ps / logs"
    log "media restore complete and healthy"
    ;;
*)
    usage
    ;;
esac
