#!/usr/bin/env bash
# .claude/tests/compaction-continuity/01-first-compaction-creates-file.sh
# Spec 081 — Scenario 1: first compaction creates a new file in .compact-history/.
#
# Given an empty .claude/.compact-history/ (or no dir at all), when pre-compact.sh
# fires, then a single file matching <ISO>-<pid>-<rand5>.md is created.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
HOOK="$AGENT0_ROOT/.claude/hooks/pre-compact.sh"

TMPDIR="$(mktemp -d -t spec-081-01-XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$TMPDIR/.claude"
TRANSCRIPT="$TMPDIR/transcript.jsonl"
cat >"$TRANSCRIPT" <<'EOF'
{"type":"user","message":{"content":"hello"}}
{"type":"assistant","message":{"content":[{"type":"text","text":"hi back"}]}}
EOF

STDIN="$(printf '{"transcript_path":"%s","trigger":"test","custom_instructions":""}' "$TRANSCRIPT")"

export CLAUDE_PROJECT_DIR="$TMPDIR"
printf '%s' "$STDIN" | bash "$HOOK"

HISTORY_DIR="$TMPDIR/.claude/.compact-history"
if [ ! -d "$HISTORY_DIR" ]; then
  printf 'FAIL: .compact-history/ was not created\n'
  exit 1
fi

count="$(ls -1 "$HISTORY_DIR"/*.md 2>/dev/null | wc -l)"
if [ "$count" -ne 1 ]; then
  printf 'FAIL: expected 1 snapshot file, found %d\n' "$count"
  ls -la "$HISTORY_DIR"
  exit 1
fi

# Filename shape: YYYY-MM-DDTHH-MM-SSZ-<pid>-<5digit>.md
fname="$(basename "$(ls -1 "$HISTORY_DIR"/*.md | head -1)")"
if ! [[ "$fname" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}-[0-9]{2}-[0-9]{2}Z-[0-9]+-[0-9]{5}\.md$ ]]; then
  printf 'FAIL: filename %s does not match <ISO>-<pid>-<5digit>.md shape\n' "$fname"
  exit 1
fi

# Content has the captured user turn verbatim
if ! grep -q 'hello' "$HISTORY_DIR"/*.md; then
  printf 'FAIL: snapshot missing the user turn content\n'
  exit 1
fi

printf 'PASS\n'
exit 0
