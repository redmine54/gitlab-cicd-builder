#!/usr/bin/env bash
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/../common/log.sh"
ROOT=${CI_PROJECT_DIR:-$(pwd)}
OUTPUT_DIR=${DEPLOY_OUTPUT_DIR:-build-output/deploy}
mkdir -p "$ROOT/$OUTPUT_DIR"
if [ -n "${DEPLOY_COMMAND:-}" ]; then
  log_info "Running application-provided deployment command"
  sh -c "$DEPLOY_COMMAND"
else
  [ -d "$ROOT/build-output" ] || fail "No build-output directory; configure the build or DEPLOY_COMMAND"
  cp -R "$ROOT/build-output/." "$ROOT/$OUTPUT_DIR/"
  log_warn "Artifacts staged at $OUTPUT_DIR; configure DEPLOY_COMMAND for an actual deployment"
fi
