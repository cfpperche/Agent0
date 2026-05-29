#!/usr/bin/env bash
# Scenario: CLAUDE_SKIP_PROPAGATION_ADVISE=1 short-circuits the hook entirely.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
HOOK="$AGENT0_ROOT/.agent0/hooks/propagation-advise.sh"

TMPDIR_T="$(mktemp -d -t pa-09-XXXXXX)"
trap 'rm -rf "$TMPDIR_T"' EXIT
export CLAUDE_PROJECT_DIR="$TMPDIR_T"
export CLAUDE_SKIP_PROPAGATION_ADVISE=1

payload="$(jq -n \
  --arg fp "$TMPDIR_T/.claude/rules/foo.md" \
  --arg new "Refs spec 080, anthill, /home/goat/foo, .agent0/memory/cc-platform-hooks.md." \
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
  printf 'FAIL: expected silent under opt-out env var, got:\n'
  cat "$stderr_capture"
  rm -f "$stderr_capture"
  exit 1
fi

rm -f "$stderr_capture"
echo "PASS: 09-env-opt-out-silent"
