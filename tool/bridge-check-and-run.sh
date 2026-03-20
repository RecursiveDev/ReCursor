#!/usr/bin/env bash
set -euo pipefail

SKIP_INSTALL=false
SKIP_RUN=false
ALL_FILES=false
RUN_SCRIPT="dev"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-install)
      SKIP_INSTALL=true
      shift
      ;;
    --skip-run)
      SKIP_RUN=true
      shift
      ;;
    --all-files)
      ALL_FILES=true
      shift
      ;;
    --run-script)
      RUN_SCRIPT="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

run_step() {
  local name="$1"
  shift
  echo "==> $name"
  "$@"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BRIDGE_DIR="$REPO_ROOT/packages/bridge"
NODE_MODULES_DIR="$BRIDGE_DIR/node_modules"

mapfile -t CHANGED_FILES < <(
  if [[ "$ALL_FILES" == true ]]; then
    true
  else
    cd "$REPO_ROOT"
    {
      git diff --name-only --diff-filter=ACMR
      git ls-files --others --exclude-standard
    } | grep -E '^packages/bridge/' \
      | grep -Ev '^packages/bridge/(dist|node_modules)/' \
      | grep -E '\.(ts|js|cjs|mjs|json)$' \
      | sort -u || true
  fi
)

RELATIVE_CHANGED_FILES=()
for file in "${CHANGED_FILES[@]}"; do
  RELATIVE_CHANGED_FILES+=("${file#packages/bridge/}")
done

cd "$BRIDGE_DIR"

if [[ "$SKIP_INSTALL" != true && ! -d "$NODE_MODULES_DIR" ]]; then
  run_step "npm ci" npm ci
elif [[ "$SKIP_INSTALL" != true ]]; then
  echo "node_modules already exists; skipping npm ci. Use a clean install manually when needed."
fi

if [[ "$ALL_FILES" == true ]]; then
  run_step "npm run format" npm run format
elif [[ ${#CHANGED_FILES[@]} -gt 0 ]]; then
  run_step "prettier changed files" npm exec prettier -- --write "${RELATIVE_CHANGED_FILES[@]}"
else
  echo "No changed bridge files detected; skipping prettier. Use --all-files for a project-wide pass."
fi

run_step "npm run typecheck" npm run typecheck
run_step "npm test -- --passWithNoTests --runInBand" npm test -- --passWithNoTests --runInBand
run_step "npm run build" npm run build

if [[ "$SKIP_RUN" == true ]]; then
  echo "Skipping npm run because --skip-run was provided."
  exit 0
fi

run_step "npm run $RUN_SCRIPT" npm run "$RUN_SCRIPT"
