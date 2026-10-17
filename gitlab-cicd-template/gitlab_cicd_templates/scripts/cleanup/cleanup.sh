#!/usr/bin/env bash
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/../common/log.sh"
ROOT=${CI_PROJECT_DIR:-$(pwd)}
rm -rf "$ROOT/.gitlab-cicd-template"
log_info "Removed temporary template checkout"
