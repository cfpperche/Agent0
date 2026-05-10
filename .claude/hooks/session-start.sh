#!/usr/bin/env bash
# SessionStart hook: inject SESSION.md into context and reset session-start marker.
#
# Fires on: startup, resume, clear, compact.
# The marker timestamp is what the Stop hook compares against to decide whether
# SESSION.md was updated during this session.

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
STATE_DIR="$PROJECT_DIR/.claude/.session-state"
SESSION_FILE="$PROJECT_DIR/.claude/SESSION.md"

mkdir -p "$STATE_DIR"
touch "$STATE_DIR/started-at"
rm -f "$STATE_DIR/nagged"

if [[ -f "$SESSION_FILE" ]]; then
  printf '=== SESSION.md (handoff from prior session) ===\n'
  cat "$SESSION_FILE"
  printf '\n=== end SESSION.md ===\n'
fi
