#!/usr/bin/env bash
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/../common/log.sh"
ROOT=${CI_PROJECT_DIR:-$(pwd)}
PLAYWRIGHT_DIR=${PLAYWRIGHT_DIR:-playwright}
STARTUP_PID=
BACKEND_PID=
cleanup() {
  result=$?
  trap - EXIT INT TERM
  [ -z "$STARTUP_PID" ] || kill "$STARTUP_PID" 2>/dev/null || true
  [ -z "$BACKEND_PID" ] || kill "$BACKEND_PID" 2>/dev/null || true
  wait 2>/dev/null || true
  exit "$result"
}
trap cleanup EXIT INT TERM

if [ -n "${BACKEND_STARTUP_COMMAND:-}" ]; then
  sh -c "$BACKEND_STARTUP_COMMAND" &
  BACKEND_PID=$!
fi
if [ -n "${STARTUP_COMMAND:-}" ]; then
  sh -c "$STARTUP_COMMAND" &
  STARTUP_PID=$!
fi

if [ -n "${STARTUP_URL:-}" ]; then
  attempts=${STARTUP_WAIT_ATTEMPTS:-60}
  until curl --fail --silent "$STARTUP_URL" >/dev/null; do
    attempts=$((attempts - 1))
    [ "$attempts" -gt 0 ] || fail "Application did not become ready at $STARTUP_URL"
    sleep 2
  done
fi
[ -f "$ROOT/$PLAYWRIGHT_DIR/package.json" ] || fail "Missing $PLAYWRIGHT_DIR/package.json"
cd "$ROOT/$PLAYWRIGHT_DIR"
if [ -f package-lock.json ]; then npm ci; else npm install; fi
npx playwright install --with-deps chromium
npx playwright test
