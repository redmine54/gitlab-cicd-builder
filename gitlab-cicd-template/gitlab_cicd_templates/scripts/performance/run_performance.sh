#!/usr/bin/env bash
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/../common/log.sh"
: "${PERFORMANCE_URL:?PERFORMANCE_URL is required}"
REPORT_DIR=${REPORT_DIR:-reports}
mkdir -p "$REPORT_DIR"
if [ -n "${PERFORMANCE_COMMAND:-}" ]; then
  sh -c "$PERFORMANCE_COMMAND"
elif command -v hey >/dev/null 2>&1; then
  hey -n "${PERFORMANCE_REQUESTS:-100}" -c "${PERFORMANCE_CONCURRENCY:-5}" \
    -o json -m GET "$PERFORMANCE_URL" > "$REPORT_DIR/performance.json"
else
  fail "Set PERFORMANCE_COMMAND or install hey"
fi
log_info "Performance check completed for $PERFORMANCE_URL"
