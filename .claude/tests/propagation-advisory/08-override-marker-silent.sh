#!/usr/bin/env bash
# Scenario: edit content carrying a valid # OVERRIDE: propagation-exempt:
# marker bypasses the scan entirely, even with leak patterns present.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
HOOK="$AGENT0_ROOT/.claude/hooks/propagation-advise.sh"

TMPDIR_T="$(mktemp -d -t pa-08-XXXXXX)"
trap 'rm -rf "$TMPDIR_T"' EXIT
export CLAUDE_PROJECT_DIR="$TMPDIR_T"

# Override marker on its own line, then leak prose. ≥10 char reason.
new_content="# OVERRIDE: propagation-exempt: documenting historical spec 080 context
This intentionally mentions spec 080 and anthill for archive purposes."

payload="$(jq -n \
  --arg fp "$TMPDIR_T/.claude/rules/historical-note.md" \
  --arg new "$new_content" \
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
  printf 'FAIL: expected silent under override marker, got:\n'
  cat "$stderr_capture"
  rm -f "$stderr_capture"
  exit 1
fi

rm -f "$stderr_capture"
echo "PASS: 08-override-marker-silent"
