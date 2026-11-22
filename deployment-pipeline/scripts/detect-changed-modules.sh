#!/usr/bin/env bash
# Detect environment-deployments/* module roots changed between two git refs.
# Usage: detect-changed-modules.sh <base_sha> <head_sha>
# Prints one MODULE_PATH per line (e.g. environment-deployments/dev/dev-s3)

set -euo pipefail

BASE_SHA="${1:?base sha required}"
HEAD_SHA="${2:?head sha required}"
ROOT="${GITHUB_WORKSPACE:-$(pwd)}"

cd "$ROOT"

CHANGED_FILES=$(git diff --name-only "$BASE_SHA" "$HEAD_SHA" || true)

if [[ -z "$CHANGED_FILES" ]]; then
  echo "No changed files between $BASE_SHA and $HEAD_SHA" >&2
  exit 0
fi

MODULES=()

# Direct changes under environment-deployments/<env>/<module>/
while IFS= read -r file; do
  if [[ "$file" =~ ^environment-deployments/[^/]+/[^/]+/ ]]; then
    module_path=$(echo "$file" | cut -d/ -f1-3)
    MODULES+=("$module_path")
  fi
done <<< "$CHANGED_FILES"

# reusable-modules/<name>/ changed → plan every deployment that sources that module
REUSABLE_CHANGED=()
while IFS= read -r file; do
  if [[ "$file" =~ ^reusable-modules/([^/]+)/ ]]; then
    REUSABLE_CHANGED+=("${BASH_REMATCH[1]}")
  fi
done <<< "$CHANGED_FILES"

if [[ ${#REUSABLE_CHANGED[@]} -gt 0 ]]; then
  unique_reusable=$(printf '%s\n' "${REUSABLE_CHANGED[@]}" | sort -u)
  while IFS= read -r mod; do
    [[ -z "$mod" ]] && continue
    while IFS= read -r tf; do
      if grep -qE "source\s*=\s*\".*reusable-modules/${mod}" "$tf" 2>/dev/null; then
        module_path=$(echo "$tf" | cut -d/ -f1-3)
        MODULES+=("$module_path")
      fi
    done < <(find environment-deployments -type f -name '*.tf' 2>/dev/null || true)
  done <<< "$unique_reusable"
fi

if [[ ${#MODULES[@]} -eq 0 ]]; then
  echo "No environment-deployments modules affected." >&2
  exit 0
fi

printf '%s\n' "${MODULES[@]}" | sort -u
