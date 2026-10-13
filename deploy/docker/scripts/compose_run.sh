#!/bin/bash
set -euo pipefail
# Tag-aware compose entry point for callers that run one-off containers
# outside a deployment: cron (crontab.txt) and ad-hoc operator commands.
#
# Cron lines used to invoke `docker compose … run --rm backend …` directly,
# which resolves EVENTFLOW_TAG from the external .env file — i.e. "local",
# an image that is never built by deploy_compose.sh. Scheduled jobs therefore
# either failed to find an image or silently ran stale code. Going through
# lib.sh's compose() resolves the tag from the recorded deploy state instead.
#
# Usage: compose_run.sh <docker compose subcommand…>
#   compose_run.sh run --rm backend python manage.py send_event_reminders
#   compose_run.sh ps

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

compose "$@"
