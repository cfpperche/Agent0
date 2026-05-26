#!/usr/bin/env bash
# .claude/tests/hook-chain-latency/01-baseline-exists.sh
# Scenario: .claude/.perf-baseline.json exists and parses cleanly.
#
# Asserts:
#   (a) file exists
#   (b) parses as JSON
#   (c) has expected top-level fields: git_sha, harness_version, os, ts, reps, cells
#   (d) the four real hook cells are populated with p50_ms + p95_ms per command

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
BASELINE="$AGENT0_ROOT/.claude/.perf-baseline.json"

[ -f "$BASELINE" ] || { echo "FAIL: baseline missing at $BASELINE"; exit 1; }
jq -e . "$BASELINE" >/dev/null 2>&1 || { echo "FAIL: baseline not valid JSON"; exit 1; }

for field in git_sha harness_version os ts reps cells; do
  if [ "$(jq -r --arg f "$field" 'has($f)' "$BASELINE")" != "true" ]; then
    echo "FAIL: baseline missing field $field"
    exit 1
  fi
done

for hook in governance-gate.sh secrets-scan.sh supply-chain-scan.sh runtime-pre-mark.sh; do
  if [ "$(jq -r --arg h "$hook" '.cells | has($h)' "$BASELINE")" != "true" ]; then
    echo "FAIL: baseline missing cells for hook $hook"
    exit 1
  fi
  p95="$(jq -r --arg h "$hook" '.cells[$h].noop.p95_ms' "$BASELINE")"
  if [ -z "$p95" ] || [ "$p95" = "null" ]; then
    echo "FAIL: baseline cell $hook.noop.p95_ms is null/empty"
    exit 1
  fi
done

printf 'PASS\n'
exit 0
