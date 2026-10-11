#!/bin/bash
set -euo pipefail

# EventFlow restore script — the counterpart to backup.sh.
#
# A backup nobody has rehearsed restoring is not a recovery plan
# (QA-TEST-REPORT.md P1-3), so this is written to be run on a schedule as
# much as in an emergency: rehearse into a scratch database quarterly.
#
# It is deliberately destructive-proof. Nothing is written until the archive
# has been integrity-checked, and a live restore additionally refuses to run
# without --yes, so a fat-fingered invocation cannot wipe production.
#
# Usage:
#   restore.sh --list                          # show available backups
#   restore.sh --verify  <db.sql.gz>           # integrity-check an archive
#   restore.sh --restore-to <db> --yes <db.sql.gz>   # restore DB into <db>
#   restore.sh --dry-run  --restore-to <db> --yes <db.sql.gz>
#
# Exit codes: 0 ok, 1 usage/error, 2 refused (safety), 3 verification failed.

BACKUP_DIR="${BACKUP_DIR:-/home/eventflow/backups}"
DAILY_DIR="${BACKUP_DIR}/daily"
DB_USER="${DB_USER:-eventflow}"
MEDIA_DIR="${MEDIA_DIR:-/home/eventflow/media}"
MYSQL_BIN="${MYSQL_BIN:-mysql}"

die()  { echo "ERROR: $*" >&2; exit 1; }
fail() { echo "ERROR: $*" >&2; exit 3; }
refuse(){ echo "REFUSED: $*" >&2; exit 2; }

usage() {
    sed -n '3,22p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
}

verify_archive() {
    local f="$1"
    [ -f "$f" ] || fail "not a file: $f"
    case "$f" in
        *.sql.gz|*.tar.gz) ;;
        *) fail "unrecognised archive type: $f (expected *.sql.gz or *.tar.gz)" ;;
    esac
    gzip -t "$f" 2>/dev/null || fail "gzip integrity check FAILED: $f"
    # For a DB dump, also confirm it actually decompresses to SQL, not garbage.
    if [[ "$f" == *.sql.gz ]]; then
        gunzip -c "$f" | head -c 512 | grep -q . || fail "archive decompresses to nothing: $f"
    fi
    echo "OK: $f passed integrity checks"
}

list_backups() {
    echo "Database backups in ${DAILY_DIR}:"
    ls -lt "${DAILY_DIR}"/db_*.sql.gz 2>/dev/null || echo "  (none)"
    echo
    echo "Weekly backups in ${BACKUP_DIR}/weekly:"
    ls -lt "${BACKUP_DIR}"/weekly/db_*.sql.gz 2>/dev/null || echo "  (none)"
}

restore_db() {
    local src="$1" target_db="$2" dry_run="${3:-}"

    verify_archive "$src"

    if [ "${dry_run}" != "--dry-run" ]; then
        [ "${ASSUME_YES:-}" = "--yes" ] || refuse \
            "restoring into '${target_db}' will OVERWRITE it. Re-run with --yes once you have confirmed the target."
    fi

    echo "Restoring $(basename "$src") -> database '${target_db}'..."
    if [ "${dry_run}" = "--dry-run" ]; then
        echo "[dry-run] would execute: gunzip -c $src | ${MYSQL_BIN} -u ${DB_USER} ${target_db}"
        # Count statements without executing, as a sanity signal.
        echo "[dry-run] uncompressed bytes: $(gunzip -c "$src" | wc -c)"
        return 0
    fi

    gunzip -c "$src" | "${MYSQL_BIN}" -u "${DB_USER}" "${target_db}"
    echo "Restore complete into '${target_db}'."
    echo "Rehearsal checklist:"
    echo "  1. ${MYSQL_BIN} -u ${DB_USER} -e 'SHOW TABLES;' ${target_db} | wc -l   # expect > 0"
    echo "  2. Point a staging app at ${target_db} and run the smoke test."
}

restore_media() {
    local src="$1" dry_run="${2:-}"
    verify_archive "$src"
    if [ "${dry_run}" = "--dry-run" ]; then
        echo "[dry-run] would extract $(basename "$src") over ${MEDIA_DIR}"
        return 0
    fi
    [ "${ASSUME_YES:-}" = "--yes" ] || refuse "extracting media overwrites ${MEDIA_DIR}; re-run with --yes."
    tar xzf "$src" -C "$(dirname "${MEDIA_DIR}")"
    echo "Media restored into ${MEDIA_DIR}."
}

# --- argument parsing -----------------------------------------------------
ACTION=""; TARGET_DB=""; SRC=""; DRY=""
while [ $# -gt 0 ]; do
    case "$1" in
        --list)        ACTION="list" ;;
        --verify)      ACTION="verify" ;;
        --restore-to)  ACTION="db"; TARGET_DB="${2:?--restore-to needs a database name}"; shift ;;
        --restore-media) ACTION="media" ;;
        --yes)         ASSUME_YES="--yes" ;;
        --dry-run)     DRY="--dry-run" ;;
        -h|--help)     usage ;;
        -*)            die "unknown flag: $1" ;;
        *)             SRC="$1" ;;
    esac
    shift
done

export ASSUME_YES

case "${ACTION}" in
    list)     list_backups ;;
    verify)   [ -n "${SRC}" ] || usage; verify_archive "$SRC" ;;
    db)       [ -n "${SRC}" ] || usage; restore_db "$SRC" "$TARGET_DB" "$DRY" ;;
    media)    [ -n "${SRC}" ] || usage; restore_media "$SRC" "$DRY" ;;
    *)        usage ;;
esac
