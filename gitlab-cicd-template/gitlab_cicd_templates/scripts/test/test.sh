#!/usr/bin/env bash
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/../common/log.sh"
KIND=${1:?Usage: test.sh <vue|react|springboot|tomcat|python|was|liberty>}
ROOT=${CI_PROJECT_DIR:-$(pwd)}
FRONTEND_DIR=${FRONTEND_DIR:-frontend}
BACKEND_DIR=${BACKEND_DIR:-backend}
MIN_COVERAGE=${TEST_COVERAGE_MIN:-0}
case "$MIN_COVERAGE" in *[!0-9.]*|'') fail "TEST_COVERAGE_MIN must be a percentage" ;; esac

case "$KIND" in
  vue|react)
    cd "$ROOT/$FRONTEND_DIR"
    npm test -- --run
    ;;
  springboot|tomcat|was|liberty)
    cd "$ROOT/$BACKEND_DIR"
    if [ -x ./mvnw ]; then ./mvnw -B test
    elif command -v mvn >/dev/null 2>&1; then mvn -B test
    elif [ -x ./gradlew ]; then ./gradlew test
    else fail "Maven or Gradle wrapper is required in $BACKEND_DIR"; fi
    ;;
  python)
    PYTHON_DIR=${PYTHON_DIR:-.}
    cd "$ROOT/$PYTHON_DIR"
    if [ "$MIN_COVERAGE" != "0" ] && [ "$MIN_COVERAGE" != "0.0" ]; then
      python -m coverage run -m pytest -q
    else
      python -m pytest -q
    fi
    ;;
  *) fail "Unsupported test kind: $KIND" ;;
esac

if [ "$MIN_COVERAGE" != "0" ] && [ "$MIN_COVERAGE" != "0.0" ]; then
  if [ "$KIND" = python ]; then
    python -m coverage report --fail-under="$MIN_COVERAGE"
  elif [ -f "$ROOT/$BACKEND_DIR/target/site/jacoco/jacoco.xml" ]; then
    coverage=$(awk '
      /<counter type="LINE"/ {
        line=$0; sub(/^.*missed="/, "", line); sub(/".*/, "", line); missed += line
        line=$0; sub(/^.*covered="/, "", line); sub(/".*/, "", line); covered += line
      }
      END { if (covered + missed == 0) exit 2; printf "%.2f", covered * 100 / (covered + missed) }
    ' "$ROOT/$BACKEND_DIR/target/site/jacoco/jacoco.xml") || fail "Could not read JaCoCo line coverage"
    awk -v actual="$coverage" -v minimum="$MIN_COVERAGE" 'BEGIN { exit !(actual >= minimum) }' \
      || fail "Line coverage ${coverage}% is below required ${MIN_COVERAGE}%"
    log_info "Line coverage ${coverage}% meets ${MIN_COVERAGE}% minimum"
  else
    fail "Coverage threshold is set but no supported coverage report was produced"
  fi
fi
log_info "$KIND tests completed"
