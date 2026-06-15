#!/usr/bin/env bash
# .agent0/tests/validator-contract/run-all.sh

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
export AGENT0_ROOT

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

results=""
any_fail=0
tmpout="$(mktemp -t validator-contract-run-all-XXXXXX)"
trap 'rm -f "$tmpout"' EXIT

for script in "$SCRIPT_DIR"/[0-9][0-9]-*.sh; do
  name="$(basename "$script")"
  script_exit=0
  bash "$script" >"$tmpout" 2>&1 || script_exit=$?
  if [ "$script_exit" -eq 0 ]; then
    results="$results
  $name  PASS"
  else
    cat "$tmpout"
    results="$results
  $name  FAIL"
    any_fail=1
  fi
done

printf '\n=== validator-contract scenario results ===\n'
printf '%s\n' "$results"
printf '===========================================\n'

if [ "$any_fail" -eq 0 ]; then
  printf 'All scenarios PASS.\n'
  exit 0
fi

printf 'One or more scenarios FAILED.\n'
exit 1
