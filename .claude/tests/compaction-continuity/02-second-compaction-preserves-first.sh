#!/usr/bin/env bash
# .claude/tests/compaction-continuity/02-second-compaction-preserves-first.sh
# Scenario 2: second compaction preserves the first.
#
# Given one snapshot already exists, when pre-compact fires again, then two
# distinct files exist (the old one is NOT overwritten — the design failure of
# the legacy single-file model).

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
HOOK="$AGENT0_ROOT/.claude/hooks/pre-compact.sh"

TMPDIR="$(mktemp -d -t spec-081-02-XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$TMPDIR/.claude"
TRANSCRIPT="$TMPDIR/transcript.jsonl"
echo '{"type":"user","message":{"content":"hello"}}' >"$TRANSCRIPT"

STDIN="$(printf '{"transcript_path":"%s","trigger":"test","custom_instructions":""}' "$TRANSCRIPT")"

export CLAUDE_PROJECT_DIR="$TMPDIR"

# Two sequential invocations
printf '%s' "$STDIN" | bash "$HOOK"
# 1-second sleep ensures distinct ISO-second prefix → strict lex order proof
sleep 1
printf '%s' "$STDIN" | bash "$HOOK"

HISTORY_DIR="$TMPDIR/.claude/.compact-history"
count="$(ls -1 "$HISTORY_DIR"/*.md 2>/dev/null | wc -l)"
if [ "$count" -ne 2 ]; then
  printf 'FAIL: expected 2 snapshot files, found %d\n' "$count"
  ls -la "$HISTORY_DIR"
  exit 1
fi

# Strict-increasing lex order (because sleep 1 guaranteed distinct prefix)
first="$(ls -1 "$HISTORY_DIR"/*.md | head -1)"
last="$(ls -1 "$HISTORY_DIR"/*.md | tail -1)"
if [ "$first" = "$last" ]; then
  printf 'FAIL: ls reported one file twice\n'
  exit 1
fi

# Both files must be non-empty (no truncation)
for f in "$HISTORY_DIR"/*.md; do
  if [ ! -s "$f" ]; then
    printf 'FAIL: snapshot %s is empty\n' "$f"
    exit 1
  fi
done

printf 'PASS\n'
exit 0
