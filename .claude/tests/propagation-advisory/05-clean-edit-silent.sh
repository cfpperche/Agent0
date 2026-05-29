#!/usr/bin/env bash
# Scenario: a clean edit to a shipped path produces no advisory output.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
HOOK="$AGENT0_ROOT/.agent0/hooks/propagation-advise.sh"

TMPDIR_T="$(mktemp -d -t pa-05-XXXXXX)"
trap 'rm -rf "$TMPDIR_T"' EXIT
export CLAUDE_PROJECT_DIR="$TMPDIR_T"

payload="$(jq -n \
  --arg fp "$TMPDIR_T/.claude/rules/foo.md" \
  --arg new "Clean content with no upstream-internal pointers." \
  '{tool_name: "Edit", tool_input: {file_path: $fp, new_string: $new}}')"

stderr_capture="$(mktemp)"
exit_code=0
printf '%s' "$payload" | bash "$HOOK" 2>"$stderr_capture" || exit_code=$?

if [ "$exit_code" -ne 0 ]; then
  printf 'FAIL: hook exited %d\n' "$exit_code"
  exit 1
fi

if [ -s "$stderr_capture" ]; then
  printf 'FAIL: expected silent stderr, got:\n'
  cat "$stderr_capture"
  rm -f "$stderr_capture"
  exit 1
fi

rm -f "$stderr_capture"
echo "PASS: 05-clean-edit-silent"
