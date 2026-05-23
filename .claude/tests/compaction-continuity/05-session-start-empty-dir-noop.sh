#!/usr/bin/env bash
# .claude/tests/compaction-continuity/05-session-start-empty-dir-noop.sh
# Spec 081 — graceful no-op edge case.
#
# Given source=compact AND no .compact-history/ dir (or empty), when SessionStart
# fires, then no banner is emitted and exit is 0.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
HOOK="$AGENT0_ROOT/.claude/hooks/session-start.sh"

TMPDIR="$(mktemp -d -t spec-081-05-XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$TMPDIR/.claude"
# NO .compact-history/ dir, NO SESSION.md
export CLAUDE_PROJECT_DIR="$TMPDIR"
STDIN='{"source":"compact","session_id":"test-081-05a"}'

# Branch A — directory missing entirely
exit_code=0
output="$(printf '%s' "$STDIN" | bash "$HOOK" 2>&1)" || exit_code=$?
if [ "$exit_code" -ne 0 ]; then
  printf 'FAIL: branch-A hook exited non-zero on missing dir (exit=%d)\n' "$exit_code"
  printf 'output: %s\n' "$output"
  exit 1
fi
if printf '%s' "$output" | grep -q 'compact-history'; then
  printf 'FAIL: branch-A banner emitted when dir is missing\n'
  printf 'output: %s\n' "$output"
  exit 1
fi

# Branch B — directory present but empty
mkdir -p "$TMPDIR/.claude/.compact-history"
STDIN_B='{"source":"compact","session_id":"test-081-05b"}'
exit_code=0
output="$(printf '%s' "$STDIN_B" | bash "$HOOK" 2>&1)" || exit_code=$?
if [ "$exit_code" -ne 0 ]; then
  printf 'FAIL: branch-B hook exited non-zero on empty dir (exit=%d)\n' "$exit_code"
  printf 'output: %s\n' "$output"
  exit 1
fi
if printf '%s' "$output" | grep -q 'Pre-compact snapshot'; then
  printf 'FAIL: branch-B inject body emitted when dir is empty\n'
  exit 1
fi

printf 'PASS\n'
exit 0
