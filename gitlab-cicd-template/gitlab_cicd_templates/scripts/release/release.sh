#!/usr/bin/env bash
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/../common/log.sh"
REPORT_DIR=${REPORT_DIR:-reports}
mkdir -p "$REPORT_DIR"
VERSION=${RELEASE_VERSION:-${CI_COMMIT_TAG:-}}
[ -n "$VERSION" ] || VERSION="${CI_COMMIT_SHORT_SHA:-local}"
printf 'name=%s\nversion=%s\ncommit=%s\n' "${APP_NAME:-application}" "$VERSION" "${CI_COMMIT_SHA:-unknown}" \
  > "$REPORT_DIR/release.txt"
if [ -n "${GITLAB_RELEASE_TOKEN:-}" ] && [ -n "${CI_API_V4_URL:-}" ] && [ -n "${CI_PROJECT_ID:-}" ]; then
  curl --fail --silent --show-error --request POST \
    --header "PRIVATE-TOKEN: $GITLAB_RELEASE_TOKEN" \
    --data-urlencode "name=${APP_NAME:-application} ${VERSION}" \
    --data-urlencode "tag_name=$VERSION" \
    --data-urlencode "ref=${CI_COMMIT_SHA:-}" \
    "$CI_API_V4_URL/projects/$CI_PROJECT_ID/releases"
else
  log_warn "Release metadata created locally; set GITLAB_RELEASE_TOKEN to publish a GitLab Release"
fi
log_info "Release metadata written to $REPORT_DIR/release.txt"
