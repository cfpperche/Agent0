#!/usr/bin/env bash
# Scenario: shared MCP recipes hint uses runtime-aware install pointers.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
HOOK="$AGENT0_ROOT/.agent0/hooks/mcp-recipes-hint.sh"
TMPDIR="$(mktemp -d -t multi-readouts-mcp-XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

touch "$TMPDIR/next.config.js"

payload_claude="$(printf '{"hook_event_name":"SessionStart","source":"startup","cwd":"%s"}' "$TMPDIR")"
out_claude="$(printf '%s' "$payload_claude" | CLAUDE_PROJECT_DIR="$TMPDIR" bash "$HOOK")"

if ! printf '%s\n' "$out_claude" | grep -q '^=== mcp-recipes ===$'; then
  printf 'FAIL: missing Claude mcp-recipes frame\n%s\n' "$out_claude"
  exit 1
fi
if ! printf '%s\n' "$out_claude" | grep -q 'copy + uncomment from .mcp.json.example'; then
  printf 'FAIL: Claude pointer did not use .mcp.json.example\n%s\n' "$out_claude"
  exit 1
fi
if ! printf '%s\n' "$out_claude" | grep -q 'next-devtools-mcp'; then
  printf 'FAIL: Claude run missing Next.js recipe\n%s\n' "$out_claude"
  exit 1
fi

payload_codex="$(printf '{"hook_event_name":"SessionStart","source":"startup","cwd":"%s"}' "$TMPDIR")"
out_codex="$(printf '%s' "$payload_codex" | env -u CLAUDE_PROJECT_DIR -u AGENT0_PROJECT_DIR bash "$HOOK")"

if ! printf '%s\n' "$out_codex" | grep -q '^=== mcp-recipes ===$'; then
  printf 'FAIL: missing Codex mcp-recipes frame\n%s\n' "$out_codex"
  exit 1
fi
if ! printf '%s\n' "$out_codex" | grep -q 'copy + uncomment from .codex/config.toml.example'; then
  printf 'FAIL: Codex pointer did not use .codex/config.toml.example\n%s\n' "$out_codex"
  exit 1
fi
if ! printf '%s\n' "$out_codex" | grep -q 'next-devtools-mcp'; then
  printf 'FAIL: Codex run missing Next.js recipe\n%s\n' "$out_codex"
  exit 1
fi

echo "PASS: 03-mcp-recipes-fixture"
