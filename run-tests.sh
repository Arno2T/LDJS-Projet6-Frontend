#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${1:-.}"
RESULTS_DIR="test-results"

log() { echo "[INFO] $*"; }
error() { echo "[ERROR] $*" >&2; }

cd "$PROJECT_DIR" || { error "Dossier introuvable: $PROJECT_DIR"; exit 1; }
log "Projet: $(pwd)"

detect_project_type() {
  if [ -f package.json ]; then
    echo "node"
  elif [ -f pyproject.toml ] || [ -f requirements.txt ]; then
    echo "python"
  else
    echo "unknown"
  fi
}

detect_node_framework() {
  if grep -q '"react"' package.json; then
    echo "React"
  elif grep -q '"@nestjs/core"' package.json; then
    echo "Node.js (NestJS)"
  else
    echo "Node.js"
  fi
}

PROJECT_TYPE="$(detect_project_type)"
log "Type de projet détecté: $PROJECT_TYPE"

if [ "$PROJECT_TYPE" = "unknown" ]; then
  error "Aucun package.json, pyproject.toml ou requirements.txt trouvé"
  exit 1
fi

if [ "$PROJECT_TYPE" = "node" ]; then
  log "Application détectée: $(detect_node_framework)"
fi

REQUIRED_NODE_MAJOR=22

check_node_deps() {
  for cmd in node npm; do
    if ! command -v "$cmd" > /dev/null; then
      error "$cmd n'est pas installé"
      exit 1
    fi
  done

  local node_major
  node_major="$(node -p 'process.versions.node.split(".")[0]')"
  if [ "$node_major" -lt "$REQUIRED_NODE_MAJOR" ]; then
    error "Node $REQUIRED_NODE_MAJOR+ requis (version actuelle : $(node -v))"
    exit 1
  fi
  log "Node $(node -v) / npm $(npm -v)"

  if [ ! -d node_modules ]; then
    log "node_modules absent : installation avec npm ci"
    npm ci
  fi
}

check_python_deps() {
  for cmd in python3 pytest; do
    if ! command -v "$cmd" > /dev/null; then
      error "$cmd n'est pas installé"
      exit 1
    fi
  done
  log "$(python3 --version) / pytest $(pytest --version 2>&1)"
}

if [ "$PROJECT_TYPE" = "node" ]; then
  check_node_deps
else
  check_python_deps
fi

clean_previous_results() {
  log "Nettoyage des anciens rapports"
  rm -rf "${RESULTS_DIR:?}" coverage
  mkdir -p "$RESULTS_DIR"
}

clean_previous_results

run_node_tests() {
  log "Lancement des tests Jest"
  JEST_JUNIT_OUTPUT_DIR="$(pwd)/$RESULTS_DIR" \
  JEST_JUNIT_OUTPUT_NAME="junit.xml" \
    npm test -- --ci --reporters=default --reporters=jest-junit
}

run_python_tests() {
  log "Lancement des tests pytest"
  pytest --junitxml="$RESULTS_DIR/junit.xml"
}

TEST_STATUS=0
if [ "$PROJECT_TYPE" = "node" ]; then
  run_node_tests || TEST_STATUS=$?
else
  run_python_tests || TEST_STATUS=$?
fi

if [ ! -f "$RESULTS_DIR/junit.xml" ]; then
  error "Aucun rapport JUnit généré dans $RESULTS_DIR/"
  exit 1
fi
log "Rapport généré : $RESULTS_DIR/junit.xml"

if [ "$TEST_STATUS" -ne 0 ]; then
  error "Des tests ont échoué (code de sortie : $TEST_STATUS)"
  exit "$TEST_STATUS"
fi

log "Tous les tests sont passés"