#!/usr/bin/env bash
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
PRE_SCRIPT="$ROOT/gitlab_cicd_templates/scripts/common/pre/common_pre.sh"
APP_NAME=smoke APP_TYPE=python PRE_SECRET_SCAN_ENABLED=false \
  PRE_DEPENDENCY_SCAN_ENABLED=false PRE_SBOM_ENABLED=false PRE_LICENSE_ENABLED=false \
  PRE_SAST_ENABLED=false "$PRE_SCRIPT"
if APP_NAME=smoke APP_TYPE=unknown PRE_SECRET_SCAN_ENABLED=false \
  PRE_DEPENDENCY_SCAN_ENABLED=false PRE_SBOM_ENABLED=false PRE_LICENSE_ENABLED=false \
  PRE_SAST_ENABLED=false "$PRE_SCRIPT"; then
  printf '[ERROR] unsupported APP_TYPE unexpectedly passed\n' >&2
  exit 1
fi
printf '[INFO] common_pre smoke tests passed\n'
