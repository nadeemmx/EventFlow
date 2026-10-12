#!/bin/bash
set -euo pipefail

# ============================================================
# Render deploy/nginx/eventflow.conf (a template with at-sign
# placeholders, e.g. the API hostname token) into an installable
# nginx config.
#
# Usage:
#   render_nginx_config.sh [API_HOST] [APP_HOST] [MEDIA_HOST] [CERT_NAME] [-o OUTPUT]
#
# All arguments are optional and can also be provided as environment
# variables of the same name. Defaults preserve the historical values
# (api./app./media.eventflow.com, cert live-dir eventflow.com) — override
# them with YOUR domains. This script never invents a domain.
#
# Examples:
#   render_nginx_config.sh api.example.com www.example.com media.example.com example.com \
#       -o /etc/nginx/sites-available/eventflow
#   API_HOST=api.example.com APP_HOST=www.example.com \
#       render_nginx_config.sh > /tmp/eventflow.conf
#
# No external dependencies (pure sed). Inputs are validated to bare
# hostnames first, so substitution values can never contain shell or
# nginx syntax; nginx runtime variables ($host, $uri, ...) are never
# touched because only the four placeholder names are replaced.
# ============================================================

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TEMPLATE="${SCRIPT_DIR}/../nginx/eventflow.conf"
OUTPUT=""

usage() {
    sed -n '3,25p' "$0" | sed 's/^# \{0,1\}//'
    exit "${1:-1}"
}

POSITIONAL=()
while [ $# -gt 0 ]; do
    case "$1" in
        -o|--output) OUTPUT="${2:?-o needs a file path}"; shift ;;
        -h|--help) usage 0 ;;
        -*) echo "ERROR: unknown flag $1" >&2; usage ;;
        *) POSITIONAL+=("$1") ;;
    esac
    shift
done

API_HOST="${POSITIONAL[0]:-${API_HOST:-api.eventflow.com}}"
APP_HOST="${POSITIONAL[1]:-${APP_HOST:-app.eventflow.com}}"
MEDIA_HOST="${POSITIONAL[2]:-${MEDIA_HOST:-media.eventflow.com}}"
CERT_NAME="${POSITIONAL[3]:-${CERT_NAME:-eventflow.com}}"

[ -f "${TEMPLATE}" ] || { echo "ERROR: template not found: ${TEMPLATE}" >&2; exit 1; }

# Hostnames/cert names: letters, digits, dots, dashes only. This both
# validates input and guarantees nothing can smuggle shell/nginx syntax
# (spaces, quotes, $, &, |, braces) into the rendered config.
validate_token() {
    local name="$1" value="$2"
    if ! printf '%s' "${value}" | grep -Eq '^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?$'; then
        echo "ERROR: invalid ${name}: '${value}' (expected a bare hostname)" >&2
        exit 1
    fi
}

validate_token API_HOST "${API_HOST}"
validate_token APP_HOST "${APP_HOST}"
validate_token MEDIA_HOST "${MEDIA_HOST}"
validate_token CERT_NAME "${CERT_NAME}"

RENDERED=$(sed \
    -e "s|@API_HOST@|${API_HOST}|g" \
    -e "s|@APP_HOST@|${APP_HOST}|g" \
    -e "s|@MEDIA_HOST@|${MEDIA_HOST}|g" \
    -e "s|@CERT_NAME@|${CERT_NAME}|g" \
    "${TEMPLATE}")

# Never ship a config with unresolved placeholders
if printf '%s' "${RENDERED}" | grep -Eq '@[A-Z_][A-Z_]*@'; then
    echo "ERROR: unresolved placeholders remain in rendered config:" >&2
    printf '%s' "${RENDERED}" | grep -Eo '@[A-Z_][A-Z_]*@' | sort -u >&2
    exit 1
fi

if [ -n "${OUTPUT}" ]; then
    printf '%s\n' "${RENDERED}" > "${OUTPUT}"
    echo "Rendered ${TEMPLATE} -> ${OUTPUT}" >&2
    echo "  API_HOST=${API_HOST} APP_HOST=${APP_HOST} MEDIA_HOST=${MEDIA_HOST} CERT_NAME=${CERT_NAME}" >&2
    echo "Next: nginx -t && systemctl reload nginx" >&2
else
    printf '%s\n' "${RENDERED}"
fi
