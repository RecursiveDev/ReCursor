#!/usr/bin/env bash
set -euo pipefail

DEVICE_ID=""
SKIP_PUB_GET=false
SKIP_RUN=false
STRICT_ANALYZE=false
APPLY_PROJECT_FIXES=false
ALL_FILES=false
RUN_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--device)
      DEVICE_ID="$2"
      shift 2
      ;;
    --skip-pub-get)
      SKIP_PUB_GET=true
      shift
      ;;
    --skip-run)
      SKIP_RUN=true
      shift
      ;;
    --strict-analyze)
      STRICT_ANALYZE=true
      shift
      ;;
    --apply-project-fixes)
      APPLY_PROJECT_FIXES=true
      shift
      ;;
    --all-files)
      ALL_FILES=true
      shift
      ;;
    --)
      shift
      RUN_ARGS=("$@")
      break
      ;;
    *)
      RUN_ARGS+=("$1")
      shift
      ;;
  esac
done

run_step() {
  local name="$1"
  shift
  echo "==> $name"
  "$@"
}

map_changed_dart_files() {
  git diff --name-only --diff-filter=ACMR -- ':(glob)apps/mobile/**/*.dart'
  git ls-files --others --exclude-standard -- ':(glob)apps/mobile/**/*.dart'
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_DIR="$REPO_ROOT/apps/mobile"

mapfile -t CHANGED_DART_FILES < <(
  if [[ "$ALL_FILES" == true ]]; then
    true
  else
    cd "$REPO_ROOT"
    map_changed_dart_files | grep -E '^apps/mobile/.*\.dart$' | grep -Ev '\.(g|freezed)\.dart$' | sort -u || true
  fi
)

RELATIVE_CHANGED_DART_FILES=()
for file in "${CHANGED_DART_FILES[@]}"; do
  RELATIVE_CHANGED_DART_FILES+=("${file#apps/mobile/}")
done

cd "$APP_DIR"

if [[ "$SKIP_PUB_GET" != true ]]; then
  run_step "flutter pub get" flutter pub get
fi

if [[ "$ALL_FILES" == true ]]; then
  run_step "dart format ." dart format .
elif [[ ${#CHANGED_DART_FILES[@]} -gt 0 ]]; then
  run_step "dart format changed files" dart format "${RELATIVE_CHANGED_DART_FILES[@]}"
else
  echo "No changed Dart files detected; skipping dart format. Use --all-files for a project-wide pass."
fi

if [[ "$APPLY_PROJECT_FIXES" == true ]]; then
  run_step "dart fix --apply" dart fix --apply
else
  run_step "dart fix --dry-run" dart fix --dry-run
fi

ANALYZE_COMMAND=(flutter analyze)
if [[ "$STRICT_ANALYZE" != true ]]; then
  ANALYZE_COMMAND+=(--no-fatal-infos --no-fatal-warnings)
fi

if [[ "$ALL_FILES" == true ]]; then
  run_step "flutter analyze" "${ANALYZE_COMMAND[@]}"
elif [[ ${#CHANGED_DART_FILES[@]} -gt 0 ]]; then
  run_step "flutter analyze changed files" "${ANALYZE_COMMAND[@]}" "${RELATIVE_CHANGED_DART_FILES[@]}"
else
  echo "No changed Dart files detected; skipping flutter analyze. Use --all-files for a project-wide pass."
fi

if [[ "$SKIP_RUN" == true ]]; then
  echo "Skipping flutter run because --skip-run was provided."
  exit 0
fi

RUN_COMMAND=(flutter run)
if [[ -n "$DEVICE_ID" ]]; then
  RUN_COMMAND+=(-d "$DEVICE_ID")
fi
if [[ ${#RUN_ARGS[@]} -gt 0 ]]; then
  RUN_COMMAND+=("${RUN_ARGS[@]}")
fi

run_step "flutter run" "${RUN_COMMAND[@]}"
