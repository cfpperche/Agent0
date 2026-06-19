#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib.sh"
echo "07-budget-and-progress"

TMPDIR="$(mktemp -d -t claude-exec-budget-XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

make_fake_claude "$TMPDIR/bin"
ARGS="$TMPDIR/args.txt"
STDIN_FILE="$TMPDIR/stdin.txt"
STATE="$TMPDIR/state"

CLAUDE_EXEC_STATE_DIR="$STATE" \
FAKE_CLAUDE_ARGS="$ARGS" \
FAKE_CLAUDE_STDIN="$STDIN_FILE" \
FAKE_CLAUDE_SLEEP=2 \
PATH="$TMPDIR/bin:$PATH" \
  bash "$AGENT0_ROOT/.agent0/skills/claude-exec/scripts/claude-exec.sh" \
    --permission-mode default \
    --max-budget-usd 0.05 \
    --timeout 5 \
    --progress-interval 1 \
    --slug budget-progress \
    --task "Budget and progress test" > "$TMPDIR/out.txt" 2> "$TMPDIR/err.txt"

assert_arg_order "$ARGS" "--max-budget-usd" "0.05" "passes max budget to claude"
assert_contains "$TMPDIR/err.txt" "still running" "emits a progress heartbeat"
assert_contains "$TMPDIR/err.txt" "elapsed=" "heartbeat includes elapsed seconds"
assert_contains "$TMPDIR/err.txt" "stdout_bytes=" "heartbeat includes stdout byte count"

RUN_DIR="$(ls -d "$STATE"/*budget-progress 2>/dev/null | head -1)"
assert_contains "$RUN_DIR/metadata.json" '"max_budget_usd": "0.05"' "metadata records max budget"
assert_contains "$RUN_DIR/metadata.json" '"timeout_seconds": 5' "metadata records timeout setting"
assert_contains "$RUN_DIR/metadata.json" '"progress_interval_seconds": 1' "metadata records progress interval"
assert_contains "$RUN_DIR/metadata.json" '"timed_out": false' "metadata records non-timeout completion"
assert_contains "$RUN_DIR/metadata.json" '"elapsed_seconds":' "metadata records elapsed seconds"
assert_contains "$STATE/runs.jsonl" '"max_budget_usd":"0.05"' "aggregate log records max budget"

set +e
CLAUDE_EXEC_STATE_DIR="$TMPDIR/bad-state" \
FAKE_CLAUDE_ARGS="$TMPDIR/bad-args.txt" \
FAKE_CLAUDE_STDIN="$TMPDIR/bad-stdin.txt" \
PATH="$TMPDIR/bin:$PATH" \
  bash "$AGENT0_ROOT/.agent0/skills/claude-exec/scripts/claude-exec.sh" \
    --permission-mode default \
    --max-budget-usd nope \
    --task "Bad budget" > "$TMPDIR/bad.out" 2> "$TMPDIR/bad.err"
bad_status=$?
set -e

[ "$bad_status" -ne 0 ] && ok "invalid budget exits non-zero" || no "invalid budget exits non-zero"
assert_contains "$TMPDIR/bad.err" "invalid --max-budget-usd" "invalid budget error is explicit"
assert_no_path "$TMPDIR/bad-args.txt" "invalid budget blocks before invoking claude"
assert_no_path "$TMPDIR/bad-state" "invalid budget creates no runtime state"

set +e
CLAUDE_EXEC_STATE_DIR="$TMPDIR/bad-progress-state" \
FAKE_CLAUDE_ARGS="$TMPDIR/bad-progress-args.txt" \
FAKE_CLAUDE_STDIN="$TMPDIR/bad-progress-stdin.txt" \
PATH="$TMPDIR/bin:$PATH" \
  bash "$AGENT0_ROOT/.agent0/skills/claude-exec/scripts/claude-exec.sh" \
    --permission-mode default \
    --progress-interval nope \
    --task "Bad progress" > "$TMPDIR/bad-progress.out" 2> "$TMPDIR/bad-progress.err"
bad_progress_status=$?
set -e

[ "$bad_progress_status" -ne 0 ] && ok "invalid progress interval exits non-zero" || no "invalid progress interval exits non-zero"
assert_contains "$TMPDIR/bad-progress.err" "invalid --progress-interval" "invalid progress interval error is explicit"
assert_no_path "$TMPDIR/bad-progress-args.txt" "invalid progress interval blocks before invoking claude"
assert_no_path "$TMPDIR/bad-progress-state" "invalid progress interval creates no runtime state"

# A budget-exceeded (error) result must not look like a silent death: the
# errors[] text is surfaced into last-message.md and the subtype is reported.
ERR_STATE="$TMPDIR/err-state"
set +e
CLAUDE_EXEC_STATE_DIR="$ERR_STATE" \
FAKE_CLAUDE_ARGS="$TMPDIR/err-args.txt" \
FAKE_CLAUDE_STDIN="$TMPDIR/err-stdin.txt" \
FAKE_CLAUDE_ERROR_SUBTYPE="error_max_budget_usd" \
FAKE_CLAUDE_ERROR_MSG="Reached maximum budget (\$0.5)" \
FAKE_CLAUDE_EXIT=1 \
PATH="$TMPDIR/bin:$PATH" \
  bash "$AGENT0_ROOT/.agent0/skills/claude-exec/scripts/claude-exec.sh" \
    --permission-mode default \
    --max-budget-usd 0.50 \
    --slug budget-exceeded \
    --task "Burn the budget" > "$TMPDIR/err.out" 2> "$TMPDIR/err2.err"
err_status=$?
set -e

[ "$err_status" -eq 1 ] && ok "propagates claude error exit code" || no "propagates claude error exit code"
ERR_RUN_DIR="$(ls -d "$ERR_STATE"/*budget-exceeded 2>/dev/null | head -1)"
assert_contains "$ERR_RUN_DIR/last-message.md" "Reached maximum budget" "surfaces budget error into last-message"
assert_contains "$ERR_RUN_DIR/last-message.md" "error_max_budget_usd" "last-message names the error subtype"
assert_contains "$TMPDIR/err.out" "result_subtype=error_max_budget_usd" "bridge stdout reports result_subtype"
assert_contains "$ERR_RUN_DIR/metadata.json" '"result_subtype": "error_max_budget_usd"' "metadata records result subtype"
assert_contains "$ERR_RUN_DIR/metadata.json" '"is_error": true' "metadata records error flag"

# Default budget guard: omitting --max-budget-usd still passes a guard to claude.
DEF_STATE="$TMPDIR/def-state"
CLAUDE_EXEC_STATE_DIR="$DEF_STATE" \
FAKE_CLAUDE_ARGS="$TMPDIR/def-args.txt" \
FAKE_CLAUDE_STDIN="$TMPDIR/def-stdin.txt" \
PATH="$TMPDIR/bin:$PATH" \
  bash "$AGENT0_ROOT/.agent0/skills/claude-exec/scripts/claude-exec.sh" \
    --permission-mode default \
    --slug default-budget \
    --task "Default budget" > "$TMPDIR/def.out" 2> "$TMPDIR/def.err"
assert_contains "$TMPDIR/def-args.txt" "<--max-budget-usd>" "applies a default budget guard when none is passed"
DEF_RUN_DIR="$(ls -d "$DEF_STATE"/*default-budget 2>/dev/null | head -1)"
assert_contains "$DEF_RUN_DIR/metadata.json" '"max_budget_usd": "2.00"' "default budget defaults to 2.00"

# An explicit env override sets the default budget.
ENV_STATE="$TMPDIR/env-state"
CLAUDE_EXEC_STATE_DIR="$ENV_STATE" \
CLAUDE_EXEC_MAX_BUDGET_USD="5.00" \
FAKE_CLAUDE_ARGS="$TMPDIR/env-args.txt" \
FAKE_CLAUDE_STDIN="$TMPDIR/env-stdin.txt" \
PATH="$TMPDIR/bin:$PATH" \
  bash "$AGENT0_ROOT/.agent0/skills/claude-exec/scripts/claude-exec.sh" \
    --permission-mode default \
    --slug env-budget \
    --task "Env budget" > "$TMPDIR/env.out" 2> "$TMPDIR/env.err"
ENV_RUN_DIR="$(ls -d "$ENV_STATE"/*env-budget 2>/dev/null | head -1)"
assert_contains "$ENV_RUN_DIR/metadata.json" '"max_budget_usd": "5.00"' "env var overrides the default budget"

finish
