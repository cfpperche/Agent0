#!/usr/bin/env bash
# Scenario: an edit to a shipped path that introduces an anthill ref
# fires the propagation-advisory: anthill line.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
HOOK="$AGENT0_ROOT/.agent0/hooks/propagation-advise.sh"

TMPDIR_T="$(mktemp -d -t pa-02-XXXXXX)"
trap 'rm -rf "$TMPDIR_T"' EXIT
export CLAUDE_PROJECT_DIR="$TMPDIR_T"

payload="$(jq -n \
  --arg fp "$TMPDIR_T/.claude/skills/foo/SKILL.md" \
  --arg new "This template ports the anthill-fpa skill." \
  '{tool_name: "Edit", tool_input: {file_path: $fp, new_string: $new}}')"

stderr_capture="$(mktemp)"
exit_code=0
printf '%s' "$payload" | bash "$HOOK" 2>"$stderr_capture" || exit_code=$?

if [ "$exit_code" -ne 0 ]; then
  printf 'FAIL: hook exited %d\n' "$exit_code"
  exit 1
fi

if ! grep -q "propagation-advisory: anthill" "$stderr_capture"; then
  printf 'FAIL: missing propagation-advisory: anthill line\n'
  cat "$stderr_capture"
  rm -f "$stderr_capture"
  exit 1
fi

rm -f "$stderr_capture"
echo "PASS: 02-anthill-triggers"
