#!/usr/bin/env bash
# .claude/tests/hook-chain-latency/03-regression-fires.sh
# Scenario: artificial slowdown injected into a hook triggers --check failure.
#
# Strategy:
#   1. Make a tmp copy of .claude/hooks/ with a sleep injected into governance-gate.sh.
#   2. Run bench-hooks.sh --check against that tmp tree with a tight tolerance.
#   3. Expect exit non-zero with a regression message naming the offending cell.
#
# Verifies the regression alarm contract documented in
# .claude/memory/hook-chain-latency.md § Regression check.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
BENCH="$AGENT0_ROOT/.claude/tools/bench-hooks.sh"
BASELINE="$AGENT0_ROOT/.claude/.perf-baseline.json"

TMPDIR="$(mktemp -d -t hcl-regression-XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

# Mirror enough of the project tree for the bench to run:
mkdir -p "$TMPDIR/.claude/hooks" "$TMPDIR/.claude/tools"
cp "$AGENT0_ROOT/.claude/hooks/"*.sh "$TMPDIR/.claude/hooks/"
cp "$BENCH" "$TMPDIR/.claude/tools/bench-hooks.sh"
cp "$BASELINE" "$TMPDIR/.claude/.perf-baseline.json"
chmod +x "$TMPDIR/.claude/tools/bench-hooks.sh"

# Inject a 100ms sleep into governance-gate.sh after its shebang/setup. The
# baseline's governance-gate.noop p95 is ~20ms; +100ms is well past the 25%
# default tolerance.
SLOW_HOOK="$TMPDIR/.claude/hooks/governance-gate.sh"
awk '
  NR == 1 { print; next }
  !inserted && /^set -uo pipefail/ {
    print
    print "sleep 0.1  # injected by 03-regression-fires.sh"
    inserted = 1
    next
  }
  { print }
' "$AGENT0_ROOT/.claude/hooks/governance-gate.sh" > "$SLOW_HOOK"
chmod +x "$SLOW_HOOK"

# Run --check against the slow tree. CLAUDE_PROJECT_DIR points at TMPDIR so
# the bench reads the slow hooks. We expect exit 2 + stderr REGRESSION line.
exit_code=0
stderr_file="$TMPDIR/stderr.txt"
CLAUDE_PROJECT_DIR="$TMPDIR" bash "$TMPDIR/.claude/tools/bench-hooks.sh" \
  --check --reps 20 --tolerance 25 --quiet 2>"$stderr_file" >/dev/null || exit_code=$?

if [ "$exit_code" -eq 0 ]; then
  echo "FAIL: expected --check to exit non-zero against slowed hook"
  cat "$stderr_file"
  exit 1
fi

if ! grep -q "REGRESSION.*governance-gate.sh" "$stderr_file"; then
  echo "FAIL: expected stderr to name 'REGRESSION ... governance-gate.sh', got:"
  cat "$stderr_file"
  exit 1
fi

printf 'PASS\n'
exit 0
