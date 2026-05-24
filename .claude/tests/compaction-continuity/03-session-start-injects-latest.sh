#!/usr/bin/env bash
# .claude/tests/compaction-continuity/03-session-start-injects-latest.sh
# Scenario 3: SessionStart on source=compact injects the latest snapshot.
#
# Given multiple snapshots exist with distinct lex order, when SessionStart fires
# with source=compact, then session-start.sh reads the lex-greatest file and
# injects it inside === compact-history === banners. Older snapshots must NOT
# appear in the injected content.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
HOOK="$AGENT0_ROOT/.claude/hooks/session-start.sh"

TMPDIR="$(mktemp -d -t spec-081-03-XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$TMPDIR/.claude/.compact-history"
HISTORY_DIR="$TMPDIR/.claude/.compact-history"

# Three snapshot files with distinct lex order. Filenames carry the year so
# 2026-12-...  >  2026-05-...  >  2026-01-... lexicographically. Content
# carries a unique sentinel string per file to allow grep-based assertion.
echo "OLDEST_SENTINEL" > "$HISTORY_DIR/2026-01-01T00-00-00Z-1-00001.md"
echo "MIDDLE_SENTINEL" > "$HISTORY_DIR/2026-05-15T12-00-00Z-2-00002.md"
echo "NEWEST_SENTINEL" > "$HISTORY_DIR/2026-12-31T23-59-59Z-3-00003.md"

export CLAUDE_PROJECT_DIR="$TMPDIR"
STDIN='{"source":"compact","session_id":"test-081-03"}'

output="$(printf '%s' "$STDIN" | bash "$HOOK" 2>&1)"

# Newest must be injected
if ! printf '%s' "$output" | grep -q 'NEWEST_SENTINEL'; then
  printf 'FAIL: session-start did not inject the lex-greatest snapshot\n'
  printf '----- output -----\n%s\n----- end -----\n' "$output"
  exit 1
fi

# Older snapshots must NOT appear
if printf '%s' "$output" | grep -q 'OLDEST_SENTINEL'; then
  printf 'FAIL: oldest snapshot leaked into output\n'
  exit 1
fi
if printf '%s' "$output" | grep -q 'MIDDLE_SENTINEL'; then
  printf 'FAIL: middle snapshot leaked into output\n'
  exit 1
fi

# Banner shape must be present
if ! printf '%s' "$output" | grep -q '=== compact-history'; then
  printf 'FAIL: opening banner missing\n'
  exit 1
fi
if ! printf '%s' "$output" | grep -q '=== end compact-history'; then
  printf 'FAIL: closing banner missing\n'
  exit 1
fi

printf 'PASS\n'
exit 0
