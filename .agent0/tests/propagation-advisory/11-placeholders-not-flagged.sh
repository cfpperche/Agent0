#!/usr/bin/env bash
# Scenario: legitimate placeholder forms (NNN-<slug>, 001-<slug>, 002-foundation,
# 003-*, MEMORY.md, <topic>.md) do NOT trigger advisories — they're the
# scaffold/index/placeholder shapes the discipline explicitly preserves.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
HOOK="$AGENT0_ROOT/.agent0/hooks/propagation-advise.sh"

TMPDIR_T="$(mktemp -d -t pa-11-XXXXXX)"
trap 'rm -rf "$TMPDIR_T"' EXIT
export CLAUDE_PROJECT_DIR="$TMPDIR_T"

clean_content='Specs follow the docs/specs/NNN-<slug>/ convention.
The /product skill scaffolds docs/specs/001-<slug>/ + docs/specs/002-foundation/ + docs/specs/003-* infra children.
Memory index lives at .agent0/memory/MEMORY.md.
A rule may reference .agent0/memory/<topic>.md placeholders.'

payload="$(jq -n \
  --arg fp "$TMPDIR_T/.claude/rules/foo.md" \
  --arg new "$clean_content" \
  '{tool_name: "Edit", tool_input: {file_path: $fp, new_string: $new}}')"

stderr_capture="$(mktemp)"
exit_code=0
printf '%s' "$payload" | bash "$HOOK" 2>"$stderr_capture" || exit_code=$?

if [ "$exit_code" -ne 0 ]; then
  printf 'FAIL: hook exited %d\n' "$exit_code"
  rm -f "$stderr_capture"
  exit 1
fi

if [ -s "$stderr_capture" ]; then
  printf 'FAIL: placeholder forms triggered advisories (expected silent):\n'
  cat "$stderr_capture"
  rm -f "$stderr_capture"
  exit 1
fi

rm -f "$stderr_capture"
echo "PASS: 11-placeholders-not-flagged"
