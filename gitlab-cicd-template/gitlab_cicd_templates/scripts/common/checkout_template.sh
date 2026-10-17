#!/usr/bin/env bash
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/log.sh"

: "${CI_PROJECT_DIR:=$(pwd)}"
: "${TEMPLATE_PROJECT_PATH:=YOUR_GROUP/gitlab-cicd-template}"
: "${TEMPLATE_REF:=v1.0.0}"
TEMPLATE_DIR="${CI_PROJECT_DIR}/.gitlab-cicd-template"

if [ -d "$TEMPLATE_DIR/.git" ]; then
  log_info "Template checkout already exists at $TEMPLATE_DIR"
  exit 0
fi
if [ "$TEMPLATE_PROJECT_PATH" = "YOUR_GROUP/gitlab-cicd-template" ]; then
  fail "Set TEMPLATE_PROJECT_PATH to the GitLab namespace/project path"
fi
: "${CI_SERVER_HOST:?CI_SERVER_HOST is required}"
: "${CI_JOB_TOKEN:?CI_JOB_TOKEN is required}"

git clone --depth 1 --branch "$TEMPLATE_REF" \
  "https://gitlab-ci-token:${CI_JOB_TOKEN}@${CI_SERVER_HOST}/${TEMPLATE_PROJECT_PATH}.git" \
  "$TEMPLATE_DIR"
log_info "Checked out template $TEMPLATE_PROJECT_PATH@$TEMPLATE_REF"
