#!/usr/bin/env bash
# Scenario: an edit to a non-shipped path (docs/specs/, .claude/memory/)
# is silent even with leak patterns — those paths don't propagate.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
HOOK="$AGENT0_ROOT/.claude/hooks/propagation-advise.sh"

TMPDIR_T="$(mktemp -d -t pa-06-XXXXXX)"
trap 'rm -rf "$TMPDIR_T"' EXIT
export CLAUDE_PROJECT_DIR="$TMPDIR_T"

# Edit to docs/specs/ (Agent0's own spec dir, doesn't propagate)
payload1="$(jq -n \
  --arg fp "$TMPDIR_T/docs/specs/090-foo/spec.md" \
  --arg new "Refs spec 080, anthill, and /home/goat/Agent0 freely." \
  '{tool_name: "Edit", tool_input: {file_path: $fp, new_string: $new}}')"

# Edit to .claude/memory/ (project-local memory, doesn't propagate)
payload2="$(jq -n \
  --arg fp "$TMPDIR_T/.claude/memory/foo.md" \
  --arg new "Refs spec 080 and anthill." \
  '{tool_name: "Edit", tool_input: {file_path: $fp, new_string: $new}}')"

for pl in "$payload1" "$payload2"; do
  stderr_capture="$(mktemp)"
  exit_code=0
  printf '%s' "$pl" | bash "$HOOK" 2>"$stderr_capture" || exit_code=$?

  if [ "$exit_code" -ne 0 ]; then
    printf 'FAIL: hook exited %d\n' "$exit_code"
    rm -f "$stderr_capture"
    exit 1
  fi

  if [ -s "$stderr_capture" ]; then
    printf 'FAIL: expected silent on non-shipped path, got:\n'
    cat "$stderr_capture"
    rm -f "$stderr_capture"
    exit 1
  fi
  rm -f "$stderr_capture"
done

echo "PASS: 06-non-consumer-path-silent"
