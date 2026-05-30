#!/usr/bin/env bash
set -euo pipefail

ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
HOOK="$ROOT/.agent0/hooks/context-inject.sh"

out="$(
  AGENT0_PROJECT_DIR="$ROOT" bash "$HOOK" <<JSON
{"hook_event_name":"UserPromptSubmit","cwd":"$ROOT","prompt":"vamos mexer em docs/specs e seguir SDD"}
JSON
)"

for needle in \
  "mode: prompt-selected" \
  "source: .agent0/context/rules/spec-driven.md" \
  "# Spec-driven development"; do
  if ! printf '%s\n' "$out" | grep -qF "$needle"; then
    printf 'FAIL: missing prompt-selected spec needle: %s\n%s\n' "$needle" "$out"
    exit 1
  fi
done

echo "PASS: 03-userprompt-selects-spec"
