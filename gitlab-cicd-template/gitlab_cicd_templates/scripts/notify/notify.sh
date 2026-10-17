#!/usr/bin/env bash
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/../common/log.sh"
STATUS=${NOTIFY_STATUS:-success}
MESSAGE="${APP_NAME:-application} pipeline ${STATUS}: ${CI_PIPELINE_URL:-local run}"
if [ -n "${NOTIFY_WEBHOOK_URL:-}" ]; then
  payload=$(printf '{"text":"%s"}' "$(printf '%s' "$MESSAGE" | sed 's/\\/\\\\/g; s/"/\\"/g')")
  curl --fail --silent --show-error --header 'Content-Type: application/json' \
    --data "$payload" "$NOTIFY_WEBHOOK_URL"
else
  log_info "$MESSAGE"
fi
