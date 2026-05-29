#!/usr/bin/env bash
# .claude/tests/supply-chain/02-skip-not-install.sh
# V3 (spec 109) — Scenario: non-dep Bash command exits silently with NO audit row.
#
# Under the broad `Bash` matcher (spec 109) the hook runs on every Bash command,
# so the former per-non-install `skip-not-install` audit row was dropped (it would
# turn the log into a shell-activity firehose; mirrors 108's `skip-not-commit`
# drop). This test now asserts the inverse of the old V2 behavior:
#   (a) hook exits 0
#   (b) no stderr output
#   (c) NO audit row is written (log file absent or zero rows after all cases)
#
# Cases (none is a recognised <manager> <verb> <packages> triple):
#   "npm test"          — "test" is not an npm verb
#   "npm install"       — bare lockfile-resolve, no packages, no dirty manifest
#   "npm install --help"— flag-only, no packages collected
#   "ls -la"            — not a package manager at all
# TMPDIR is not a git repo, so the bare-install dirty-manifest probe never fires.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
HOOK="$AGENT0_ROOT/.agent0/hooks/supply-chain-preflight.sh"

TMPDIR="$(mktemp -d -t spec-109-V3-XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

export CLAUDE_PROJECT_DIR="$TMPDIR"
export CLAUDE_SUPPLY_CHAIN_BLOCK=0  # advisory mode — assert silence holds in either mode

AUDIT_LOG="$TMPDIR/.agent0/supply-chain-audit.jsonl"

run_case() {
  local label="$1"
  local cmd="$2"
  local stdin_json stderr_file hook_exit

  stdin_json="$(jq -cn --arg c "$cmd" '{tool_input:{command:$c}, session_id:"V3-session"}')"
  stderr_file="$TMPDIR/stderr.txt"
  : > "$stderr_file"  # truncate per case

  hook_exit=0
  printf '%s' "$stdin_json" | bash "$HOOK" 2>"$stderr_file" || hook_exit=$?

  if [ "$hook_exit" -ne 0 ]; then
    printf 'FAIL [%s]: hook exit=%d, want 0\n' "$label" "$hook_exit"
    exit 1
  fi
  if [ -s "$stderr_file" ]; then
    printf 'FAIL [%s]: expected silent (no stderr), got:\n%s\n' "$label" "$(cat "$stderr_file")"
    exit 1
  fi
}

run_case "npm test"        "npm test"
run_case "npm install"     "npm install"
run_case "npm install -h"  "npm install --help"
run_case "ls"              "ls -la"

# No detection in any case → NO audit row should have been written. The log file
# is either absent (never created) or has zero lines.
if [ -e "$AUDIT_LOG" ]; then
  line_count=$(wc -l < "$AUDIT_LOG")
  if [ "$line_count" -ne 0 ]; then
    printf 'FAIL: expected 0 audit rows (skip-not-install dropped in spec 109), got %d\n' "$line_count"
    cat "$AUDIT_LOG"
    exit 1
  fi
fi

printf 'PASS\n'
exit 0
