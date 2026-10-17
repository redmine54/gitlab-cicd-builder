#!/usr/bin/env bash
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/../common/log.sh"
KIND=${1:?Usage: build.sh <vue|react|springboot|tomcat|python|was|liberty>}
ROOT=${CI_PROJECT_DIR:-$(pwd)}
FRONTEND_DIR=${FRONTEND_DIR:-frontend}
BACKEND_DIR=${BACKEND_DIR:-backend}

case "$KIND" in
  vue|react)
    [ -f "$ROOT/$FRONTEND_DIR/package.json" ] || fail "Missing $FRONTEND_DIR/package.json"
    cd "$ROOT/$FRONTEND_DIR"
    if [ -f package-lock.json ]; then npm ci; else npm install; fi
    npm run build
    mkdir -p "$ROOT/build-output/frontend"
    cp -R dist/. "$ROOT/build-output/frontend/"
    ;;
  springboot|tomcat|was|liberty)
    [ -d "$ROOT/$BACKEND_DIR" ] || fail "Missing backend directory: $BACKEND_DIR"
    cd "$ROOT/$BACKEND_DIR"
    if [ -x ./mvnw ]; then ./mvnw -B -DskipTests package
    elif command -v mvn >/dev/null 2>&1; then mvn -B -DskipTests package
    elif [ -x ./gradlew ]; then ./gradlew build -x test
    else fail "Maven or Gradle wrapper is required in $BACKEND_DIR"; fi
    mkdir -p "$ROOT/build-output/backend"
    find "$ROOT/$BACKEND_DIR/target" -maxdepth 1 \( -name '*.jar' -o -name '*.war' -o -name '*.ear' \) \
      -exec cp {} "$ROOT/build-output/backend/" \;
    ;;
  python)
    PYTHON_DIR=${PYTHON_DIR:-.}
    cd "$ROOT/$PYTHON_DIR"
    python -m compileall -q .
    mkdir -p "$ROOT/build-output"
    tar -czf "$ROOT/build-output/python-app.tar.gz" --exclude=.git --exclude=__pycache__ .
    ;;
  *) fail "Unsupported build kind: $KIND" ;;
esac
log_info "$KIND build completed"
