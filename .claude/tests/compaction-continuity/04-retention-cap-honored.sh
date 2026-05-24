#!/usr/bin/env bash
# .claude/tests/compaction-continuity/04-retention-cap-honored.sh
# Scenario 4: retention cap honored.
#
# Given .claude/settings.json carries compactHistory.keepLast: 3 AND
# .compact-history/ contains 5 snapshots (built by running pre-compact 5x),
# then exactly the 3 most-recent files remain on disk after the last run.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
HOOK="$AGENT0_ROOT/.claude/hooks/pre-compact.sh"

TMPDIR="$(mktemp -d -t spec-081-04-XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$TMPDIR/.claude"
TRANSCRIPT="$TMPDIR/transcript.jsonl"
echo '{"type":"user","message":{"content":"x"}}' >"$TRANSCRIPT"

# Low keepLast to test trim with few iterations
cat >"$TMPDIR/.claude/settings.json" <<'EOF'
{
  "compactHistory": { "keepLast": 3 }
}
EOF

STDIN="$(printf '{"transcript_path":"%s","trigger":"test","custom_instructions":""}' "$TRANSCRIPT")"

export CLAUDE_PROJECT_DIR="$TMPDIR"

# 5 invocations with 1s sleep between → strict mtime ordering for ls -t
for i in 1 2 3 4 5; do
  printf '%s' "$STDIN" | bash "$HOOK"
  if [ "$i" -lt 5 ]; then
    sleep 1
  fi
done

HISTORY_DIR="$TMPDIR/.claude/.compact-history"
count="$(ls -1 "$HISTORY_DIR"/*.md 2>/dev/null | wc -l)"
if [ "$count" -ne 3 ]; then
  printf 'FAIL: expected 3 snapshots after keepLast=3 trim, found %d\n' "$count"
  ls -la "$HISTORY_DIR"
  exit 1
fi

# Default-cap branch: omit compactHistory.keepLast entirely → defaults to 20.
# Run 2 more invocations into a fresh tmp; expect both surviving (< 20).
TMPDIR2="$(mktemp -d -t spec-081-04b-XXXXXX)"
trap 'rm -rf "$TMPDIR" "$TMPDIR2"' EXIT
mkdir -p "$TMPDIR2/.claude"
echo '{}' >"$TMPDIR2/.claude/settings.json"
echo '{"type":"user","message":{"content":"y"}}' >"$TMPDIR2/transcript.jsonl"
STDIN2="$(printf '{"transcript_path":"%s","trigger":"test","custom_instructions":""}' "$TMPDIR2/transcript.jsonl")"
export CLAUDE_PROJECT_DIR="$TMPDIR2"
printf '%s' "$STDIN2" | bash "$HOOK"
sleep 1
printf '%s' "$STDIN2" | bash "$HOOK"

count2="$(ls -1 "$TMPDIR2/.claude/.compact-history"/*.md 2>/dev/null | wc -l)"
if [ "$count2" -ne 2 ]; then
  printf 'FAIL: default keepLast=20 should keep both of 2 snapshots, found %d\n' "$count2"
  exit 1
fi

printf 'PASS\n'
exit 0
