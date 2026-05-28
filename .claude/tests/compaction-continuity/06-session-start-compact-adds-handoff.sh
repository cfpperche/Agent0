#!/usr/bin/env bash
# Scenario 6: source=compact injects both HANDOFF.md and compact-history.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
HOOK="$AGENT0_ROOT/.agent0/hooks/session-start.sh"

TMPDIR="$(mktemp -d -t spec-092-cc-06-XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$TMPDIR/.agent0" "$TMPDIR/.claude/.compact-history"
cat > "$TMPDIR/.agent0/HANDOFF.md" <<'EOF'
# Session handoff

HANDOFF_COMPACT_SENTINEL
EOF
echo "COMPACT_HISTORY_SENTINEL" > "$TMPDIR/.claude/.compact-history/2026-05-26T00-00-00Z-1-00001.md"

export CLAUDE_PROJECT_DIR="$TMPDIR"
STDIN='{"source":"compact","session_id":"test-092-cc-06"}'

output="$(printf '%s' "$STDIN" | bash "$HOOK" 2>&1)"

if ! printf '%s' "$output" | grep -q '=== HANDOFF.md (canonical handoff) ==='; then
  printf 'FAIL: HANDOFF.md banner missing\n%s\n' "$output"
  exit 1
fi
if ! printf '%s' "$output" | grep -q 'HANDOFF_COMPACT_SENTINEL'; then
  printf 'FAIL: HANDOFF.md content missing\n%s\n' "$output"
  exit 1
fi
if ! printf '%s' "$output" | grep -q '=== compact-history'; then
  printf 'FAIL: compact-history banner missing\n%s\n' "$output"
  exit 1
fi
if ! printf '%s' "$output" | grep -q 'COMPACT_HISTORY_SENTINEL'; then
  printf 'FAIL: compact-history content missing\n%s\n' "$output"
  exit 1
fi

printf 'PASS\n'
exit 0
