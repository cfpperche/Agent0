#!/usr/bin/env bash
# Scenario: factual project memory is git-tracked.
# Asserts:
#   (a) .agent0/memory/ exists as a directory
#   (b) git ls-files includes the migrated agent0-purpose.md + visibility-intent.md

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"

if [ ! -d "$AGENT0_ROOT/.agent0/memory" ]; then
  printf 'FAIL: .agent0/memory/ does not exist at %s\n' "$AGENT0_ROOT/.agent0/memory"
  exit 1
fi

tracked="$(git -C "$AGENT0_ROOT" ls-files .agent0/memory/ 2>/dev/null || true)"

for expected in agent0-purpose.md visibility-intent.md; do
  if ! printf '%s' "$tracked" | grep -q "\.agent0/memory/$expected"; then
    printf 'FAIL: .agent0/memory/%s not git-tracked\n' "$expected"
    printf 'git ls-files output:\n%s\n' "$tracked"
    exit 1
  fi
done

echo "PASS: 01-files-are-git-tracked"
