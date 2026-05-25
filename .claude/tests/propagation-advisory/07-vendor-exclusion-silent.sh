#!/usr/bin/env bash
# Scenario: edits inside .claude/skills/*/vendor/ are silent — vendor content
# has its own provenance and may legitimately carry upstream refs.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
HOOK="$AGENT0_ROOT/.claude/hooks/propagation-advise.sh"

TMPDIR_T="$(mktemp -d -t pa-07-XXXXXX)"
trap 'rm -rf "$TMPDIR_T"' EXIT
export CLAUDE_PROJECT_DIR="$TMPDIR_T"

payload="$(jq -n \
  --arg fp "$TMPDIR_T/.claude/skills/product/vendor/open-design/foo.md" \
  --arg new "Vendored anthill content with spec 027 ref intact." \
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
  printf 'FAIL: expected silent on vendor path, got:\n'
  cat "$stderr_capture"
  rm -f "$stderr_capture"
  exit 1
fi

rm -f "$stderr_capture"
echo "PASS: 07-vendor-exclusion-silent"
