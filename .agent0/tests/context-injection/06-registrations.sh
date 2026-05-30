#!/usr/bin/env bash
set -euo pipefail

ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
command -v jq >/dev/null 2>&1 || { echo "SKIP: jq missing"; exit 0; }

if ! jq -e '.hooks.SessionStart[]?.hooks[]? | select((.command // "") | contains("context-inject.sh"))' "$ROOT/.claude/settings.json" >/dev/null; then
  printf 'FAIL: Claude SessionStart missing context-inject registration\n'
  exit 1
fi

if ! jq -e '.hooks.UserPromptSubmit[]?.hooks[]? | select((.command // "") | contains("context-inject.sh"))' "$ROOT/.claude/settings.json" >/dev/null; then
  printf 'FAIL: Claude UserPromptSubmit missing context-inject registration\n'
  exit 1
fi

if ! jq -e '.hooks.SessionStart[]?.hooks[]? | select((.command // "") | contains("context-inject.sh"))' "$ROOT/.codex/hooks.json" >/dev/null; then
  printf 'FAIL: Codex hooks.json missing context-inject SessionStart registration\n'
  exit 1
fi

if ! jq -e '.hooks.UserPromptSubmit[]?.hooks[]? | select((.command // "") | contains("context-inject.sh"))' "$ROOT/.codex/hooks.json" >/dev/null; then
  printf 'FAIL: Codex hooks.json missing context-inject UserPromptSubmit registration\n'
  exit 1
fi

if grep -qE '^\s*\[\[hooks\.|context-inject\.sh' "$ROOT/.codex/config.toml.example"; then
  printf 'FAIL: Codex config template still carries inline Agent0 hook blocks\n'
  exit 1
fi

if jq -e '.hooks[][]?.hooks[]? | select((.command // "") | contains("propagation-advise.sh"))' "$ROOT/.codex/hooks.json" >/dev/null; then
  printf 'FAIL: Codex hooks.json must not register maintainer-only propagation-advise.sh\n'
  exit 1
fi

echo "PASS: 06-registrations"
