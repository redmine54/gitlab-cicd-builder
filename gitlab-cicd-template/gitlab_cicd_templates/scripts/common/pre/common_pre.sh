#!/usr/bin/env bash
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/../log.sh"
ROOT=${CI_PROJECT_DIR:-$(pwd)}
REPORT_DIR=${REPORT_DIR:-reports}
CHECK_FAILURE=0
mkdir -p "$ROOT/$REPORT_DIR"

enabled() { [ "$(printf '%s' "${1:-true}" | tr '[:upper:]' '[:lower:]')" = "true" ]; }
run_optional() {
  label=$1
  shift
  if "$@"; then
    log_info "$label completed"
  else
    result=$?
    log_error "$label failed"
    CHECK_FAILURE=1
    if [ "${POLICY_GATE_FAIL_FAST:-true}" = "true" ]; then exit "$result"; fi
  fi
}

if enabled "${PRE_VALIDATE_ENABLED:-true}"; then
  : "${APP_NAME:?APP_NAME must be set by the application pipeline}"
  : "${APP_TYPE:?APP_TYPE must be set by the application pipeline}"
  case "$APP_TYPE" in
    tomcat|springboot|vue-springboot|react-springboot|python|was|liberty) ;;
    *) fail "Unsupported APP_TYPE: $APP_TYPE" ;;
  esac
  log_info "Validated APP_NAME=$APP_NAME APP_TYPE=$APP_TYPE"
fi

if enabled "${PRE_SECRET_SCAN_ENABLED:-true}"; then
  if command -v trivy >/dev/null 2>&1; then
    run_optional "Secret scan" trivy fs --scanners secret --exit-code 1 --format json \
      --output "$ROOT/$REPORT_DIR/pre-secrets.json" "$ROOT"
  else
    if find "$ROOT" -type d \( -name .git -o -name node_modules -o -name target \
      -o -name .gitlab-cicd-template \) -prune -o -type f \
      -exec grep -nHE '(password|secret|token|api[_-]?key)[[:space:]]*[:=][[:space:]]*[^[:space:]]{16,}' {} + \
      > "$ROOT/$REPORT_DIR/pre-secrets.txt"; then
      if [ "${SECRET_SCAN_FAIL_ON_FOUND:-true}" = "true" ]; then
        CHECK_FAILURE=1
        log_error "Potential hard-coded secret found; see $REPORT_DIR/pre-secrets.txt"
        if [ "${POLICY_GATE_FAIL_FAST:-true}" = "true" ]; then exit 1; fi
      fi
    else
      log_info "Fallback secret scan found no matches"
    fi
  fi
fi

if enabled "${PRE_DEPENDENCY_SCAN_ENABLED:-true}"; then
  if [ -f "$ROOT/frontend/package-lock.json" ] && command -v npm >/dev/null 2>&1; then
    run_optional "Dependency scan" sh -c "cd '$ROOT/frontend' && npm audit --audit-level='${CVE_FAIL_SEVERITY:-high}'"
  elif [ -f "$ROOT/requirements.txt" ] && command -v pip-audit >/dev/null 2>&1; then
    run_optional "Dependency scan" pip-audit -r "$ROOT/requirements.txt"
  else
    log_warn "No supported dependency audit input/tool found; dependency scan skipped"
  fi
fi

if enabled "${PRE_SBOM_ENABLED:-false}"; then
  if command -v trivy >/dev/null 2>&1; then
    trivy fs --format cyclonedx --output "$ROOT/$REPORT_DIR/sbom.cdx.json" "$ROOT"
  elif command -v syft >/dev/null 2>&1; then
    syft "$ROOT" -o cyclonedx-json > "$ROOT/$REPORT_DIR/sbom.cdx.json"
  else
    log_warn "Trivy or Syft is required for SBOM generation"
  fi
fi

if enabled "${PRE_LICENSE_ENABLED:-false}"; then
  if [ -n "${LICENSE_DENY_LIST:-}" ] && [ -f "$ROOT/frontend/package-lock.json" ] && command -v npx >/dev/null 2>&1; then
    npx --yes license-checker --production --json > "$ROOT/$REPORT_DIR/licenses.json"
    node - "$ROOT/$REPORT_DIR/licenses.json" "$LICENSE_DENY_LIST" <<'NODE'
const fs = require('node:fs')
const packages = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'))
const denied = process.argv[3].split(',').map((item) => item.trim()).filter(Boolean)
for (const [name, metadata] of Object.entries(packages)) {
  const licenses = Array.isArray(metadata.licenses) ? metadata.licenses : [metadata.licenses || metadata.license]
  for (const license of licenses.filter(Boolean)) {
    if (denied.includes(license)) {
      console.error(`Denied license ${license} found in ${name}`)
      process.exitCode = 1
    }
  }
}
NODE
    result=$?
    if [ "$result" -ne 0 ]; then
      CHECK_FAILURE=1
      if [ "${POLICY_GATE_FAIL_FAST:-true}" = "true" ]; then exit "$result"; fi
    fi
  else
    log_warn "License check requires LICENSE_DENY_LIST and a supported package manifest"
  fi
fi

if enabled "${PRE_SAST_ENABLED:-false}"; then
  if command -v semgrep >/dev/null 2>&1; then
    case "${SAST_FAIL_SEVERITY:-HIGH}" in
      CRITICAL|HIGH) sast_severity=ERROR ;;
      MEDIUM) sast_severity=WARNING ;;
      LOW|INFO) sast_severity=INFO ;;
      *) fail "Unsupported SAST_FAIL_SEVERITY: $SAST_FAIL_SEVERITY" ;;
    esac
    run_optional "SAST" semgrep scan --config auto --severity "$sast_severity" --error \
      --json --output "$ROOT/$REPORT_DIR/sast.json" "$ROOT"
  else
    log_warn "Semgrep is not installed; SAST skipped"
  fi
fi

if enabled "${PRE_POLICY_GATE_ENABLED:-true}"; then
  [ "$CHECK_FAILURE" -eq 0 ] || fail "One or more Pre checks failed"
  log_info "Pre policy gate passed"
fi
