#!/usr/bin/env bash
# Scenario: an edit to a shipped path with a spec-NNN ref fires the
# propagation-advisory: spec-NNN line. Hook exits 0 regardless.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
HOOK="$AGENT0_ROOT/.claude/hooks/propagation-advise.sh"

# Use a tempdir as CLAUDE_PROJECT_DIR so the file_path resolves relative to it.
TMPDIR_T="$(mktemp -d -t pa-01-XXXXXX)"
trap 'rm -rf "$TMPDIR_T"' EXIT
export CLAUDE_PROJECT_DIR="$TMPDIR_T"

payload="$(jq -n \
  --arg fp "$TMPDIR_T/.claude/rules/foo.md" \
  --arg new "This refs spec 080 and spec 075 work." \
  '{tool_name: "Edit", tool_input: {file_path: $fp, new_string: $new}}')"

stderr_capture="$(mktemp)"
exit_code=0
printf '%s' "$payload" | bash "$HOOK" 2>"$stderr_capture" || exit_code=$?

if [ "$exit_code" -ne 0 ]; then
  printf 'FAIL: hook exited %d (expected 0)\n' "$exit_code"
  exit 1
fi

if ! grep -q "propagation-advisory: spec-NNN" "$stderr_capture"; then
  printf 'FAIL: missing propagation-advisory: spec-NNN line\n'
  printf 'stderr was:\n'
  cat "$stderr_capture"
  rm -f "$stderr_capture"
  exit 1
fi

rm -f "$stderr_capture"
echo "PASS: 01-spec-nnn-triggers"
