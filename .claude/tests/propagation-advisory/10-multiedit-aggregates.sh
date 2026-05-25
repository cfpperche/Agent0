#!/usr/bin/env bash
# Scenario: MultiEdit with multiple edits, each carrying leak patterns,
# produces advisories aggregated across all edits.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
HOOK="$AGENT0_ROOT/.claude/hooks/propagation-advise.sh"

TMPDIR_T="$(mktemp -d -t pa-10-XXXXXX)"
trap 'rm -rf "$TMPDIR_T"' EXIT
export CLAUDE_PROJECT_DIR="$TMPDIR_T"

payload="$(jq -n \
  --arg fp "$TMPDIR_T/.claude/rules/foo.md" \
  '{tool_name: "MultiEdit", tool_input: {
    file_path: $fp,
    edits: [
      {old_string: "x", new_string: "First chunk: spec 080 ref."},
      {old_string: "y", new_string: "Second chunk: anthill ref."},
      {old_string: "z", new_string: "Third chunk: clean text."}
    ]
  }}')"

stderr_capture="$(mktemp)"
exit_code=0
printf '%s' "$payload" | bash "$HOOK" 2>"$stderr_capture" || exit_code=$?

if [ "$exit_code" -ne 0 ]; then
  printf 'FAIL: hook exited %d\n' "$exit_code"
  rm -f "$stderr_capture"
  exit 1
fi

if ! grep -q "propagation-advisory: spec-NNN" "$stderr_capture"; then
  printf 'FAIL: missing spec-NNN advisory from MultiEdit\n'
  cat "$stderr_capture"
  rm -f "$stderr_capture"
  exit 1
fi

if ! grep -q "propagation-advisory: anthill" "$stderr_capture"; then
  printf 'FAIL: missing anthill advisory from MultiEdit\n'
  cat "$stderr_capture"
  rm -f "$stderr_capture"
  exit 1
fi

rm -f "$stderr_capture"
echo "PASS: 10-multiedit-aggregates"
