#!/usr/bin/env bash
# Scenario: tracked Codex hooks.json registers SessionStart readouts.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
CONFIG="$AGENT0_ROOT/.codex/hooks.json"

if ! command -v jq >/dev/null 2>&1; then
  printf 'SKIP: jq missing\n'
  exit 0
fi

if ! jq -e . "$CONFIG" >/dev/null; then
  printf 'FAIL: .codex/hooks.json is not valid JSON\n'
  exit 1
fi

required=(
  ".agent0/hooks/memory-decay-readout.sh"
  ".agent0/hooks/reminders-readout.sh"
  ".agent0/hooks/routines-readout.sh"
)

for needle in "${required[@]}"; do
  if ! jq -e --arg needle "$needle" '.hooks.SessionStart[]?.hooks[]? | select((.command // "") | contains($needle))' "$CONFIG" >/dev/null; then
    printf 'FAIL: missing SessionStart command: %s\n' "$needle"
    exit 1
  fi
done

echo "PASS: 05-hooks-json-parse"
