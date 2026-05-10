#!/usr/bin/env bash
# SessionStart hook: inject context appropriate to the start source.
#
# - startup / resume / clear → SESSION.md (cross-session handoff)
# - compact                  → COMPACT_NOTES.md (in-session WIP at moment of compact)
#
# Always resets the session-start marker that the Stop hook compares against.

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
STATE_DIR="$PROJECT_DIR/.claude/.session-state"
SESSION_FILE="$PROJECT_DIR/.claude/SESSION.md"
NOTES_FILE="$PROJECT_DIR/.claude/COMPACT_NOTES.md"

mkdir -p "$STATE_DIR"
touch "$STATE_DIR/started-at"
rm -f "$STATE_DIR/nagged"

SOURCE="startup"
INPUT="$(cat 2>/dev/null || true)"
if [[ -n "$INPUT" ]]; then
  SOURCE="$(printf '%s' "$INPUT" | jq -r '.source // "startup"' 2>/dev/null || echo startup)"
fi

if [[ "$SOURCE" == "compact" && -f "$NOTES_FILE" ]]; then
  printf '=== COMPACT_NOTES.md (pre-compact snapshot — raw signal /compact would have lost) ===\n'
  cat "$NOTES_FILE"
  printf '\n=== end COMPACT_NOTES.md ===\n'
elif [[ -f "$SESSION_FILE" ]]; then
  printf '=== SESSION.md (handoff from prior session) ===\n'
  cat "$SESSION_FILE"
  printf '\n=== end SESSION.md ===\n'
fi
