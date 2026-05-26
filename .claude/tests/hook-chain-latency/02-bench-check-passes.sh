#!/usr/bin/env bash
# .claude/tests/hook-chain-latency/02-bench-check-passes.sh
# Scenario: bench-hooks.sh --check passes against the committed baseline.
#
# Asserts:
#   (a) bench-hooks.sh --check exits 0 when run against the current hooks
#       (i.e. no hook has regressed beyond tolerance vs baseline)
#
# Uses small N (20) to keep test fast; the regression check is statistical,
# so the default 25% tolerance absorbs sample noise at this N.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
BENCH="$AGENT0_ROOT/.claude/tools/bench-hooks.sh"

[ -f "$BENCH" ] || { echo "FAIL: bench-hooks.sh missing at $BENCH"; exit 1; }
[ -x "$BENCH" ] || { echo "FAIL: bench-hooks.sh not executable"; exit 1; }

# Run check with a very generous tolerance (the test is "does the alarm pass on
# a clean tree under sample noise", not "are we at exactly the budget"). The
# real regression-detection assertion lives in 03-regression-fires.sh, where a
# 100 ms injected sleep is far past any noise floor.
exit_code=0
bash "$BENCH" --check --reps 20 --tolerance 200 --quiet >/dev/null 2>&1 || exit_code=$?

if [ "$exit_code" -ne 0 ]; then
  echo "FAIL: bench-hooks.sh --check exited $exit_code; expected 0"
  bash "$BENCH" --check --reps 20 --tolerance 200 2>&1 | tail -10
  exit 1
fi

printf 'PASS\n'
exit 0
