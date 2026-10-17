#!/usr/bin/env bash
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/../common/log.sh"
ROOT=${CI_PROJECT_DIR:-$(pwd)}
REPORT_DIR=${REPORT_DIR:-reports}
mkdir -p "$ROOT/$REPORT_DIR"
TOOLS=${SECURITY_TOOLS:-trivy}
IFS=','
for tool in $TOOLS; do
  case "$tool" in
    trivy)
      command -v trivy >/dev/null 2>&1 || fail "SECURITY_TOOLS includes trivy but trivy is not installed"
      trivy fs --scanners vuln,secret,misconfig --severity "${CVE_FAIL_SEVERITY:-HIGH,CRITICAL}" \
        --exit-code 1 --format json --output "$ROOT/$REPORT_DIR/trivy.json" "$ROOT"
      ;;
    dependency-check)
      command -v dependency-check.sh >/dev/null 2>&1 || fail "dependency-check.sh is not installed"
      case "${CVE_FAIL_SEVERITY:-high}" in
        critical|CRITICAL) fail_cvss=9 ;;
        high|HIGH) fail_cvss=7 ;;
        medium|MEDIUM) fail_cvss=4 ;;
        low|LOW) fail_cvss=0 ;;
        *) fail "Unsupported CVE_FAIL_SEVERITY: $CVE_FAIL_SEVERITY" ;;
      esac
      dependency-check.sh --scan "$ROOT" --format JSON --out "$ROOT/$REPORT_DIR/dependency-check" \
        --failOnCVSS "$fail_cvss"
      ;;
    container-scan)
      : "${CONTAINER_IMAGE:?CONTAINER_IMAGE is required for container-scan}"
      command -v trivy >/dev/null 2>&1 || fail "trivy is required for container-scan"
      trivy image --severity "${CVE_FAIL_SEVERITY:-HIGH,CRITICAL}" --exit-code 1 \
        --format json --output "$ROOT/$REPORT_DIR/container-scan.json" "$CONTAINER_IMAGE"
      ;;
    *) fail "Unsupported security tool: $tool" ;;
  esac
done
unset IFS
log_info "Security scans completed: $TOOLS"
