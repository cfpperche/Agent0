#!/usr/bin/env bash
# Scenario 7: missing HANDOFF.md falls back to non-pointer legacy SESSION.md.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
START_HOOK="$AGENT0_ROOT/.claude/hooks/session-start.sh"

TMPDIR="$(mktemp -d -t spec-092-07-XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$TMPDIR/.claude"
cat > "$TMPDIR/.claude/SESSION.md" <<'EOF'
# Legacy session

LEGACY_SESSION_SENTINEL
EOF

export CLAUDE_PROJECT_DIR="$TMPDIR"
output="$(printf '%s' '{"source":"startup","session_id":"test-092-07"}' | bash "$START_HOOK" 2>&1)"

if ! printf '%s' "$output" | grep -q '=== SESSION.md (handoff from prior session) ==='; then
  printf 'FAIL: legacy SESSION.md banner missing\n%s\n' "$output"
  exit 1
fi
if ! printf '%s' "$output" | grep -q 'LEGACY_SESSION_SENTINEL'; then
  printf 'FAIL: legacy SESSION.md content missing\n%s\n' "$output"
  exit 1
fi
if ! printf '%s' "$output" | grep -q 'migration-advisory: .claude/SESSION.md is legacy; create .agent0/HANDOFF.md to migrate'; then
  printf 'FAIL: migration advisory missing\n%s\n' "$output"
  exit 1
fi
if printf '%s' "$output" | grep -q 'handoff-advisory'; then
  printf 'FAIL: missing-handoff advisory emitted despite legacy fallback\n%s\n' "$output"
  exit 1
fi

printf 'PASS\n'
exit 0
