#!/usr/bin/env bash
# .claude/hooks/memory-events-journal.sh
# PostToolUse(Edit|Write|MultiEdit) hook: appends one JSONL event to
# .claude/.memory-events.jsonl per memory-entry write, then regenerates
# .claude/memory/MEMORY.md from the current entries via memory-project.sh.
#
# Scope: .claude/memory/*.md, excluding MEMORY.md (which is the derived
# projection, gated separately by memory-index-gate.sh).
#
# Exit codes: always 0. Fail-open on any step (missing jq, unwritable
# journal, projection error) — emit one `memory-journal-advisory:` line
# to stderr and exit 0. The PreToolUse gate is the only blocking part
# of spec 083; this PostToolUse half is signal-only.
#
# Spec: docs/specs/083-memory-events-journal/
# Rule: .claude/rules/memory-placement.md § Event journal

set -uo pipefail

INPUT="$(cat 2>/dev/null || true)"
[ -z "$INPUT" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
MEMORY_DIR="$PROJECT_DIR/.claude/memory"
JOURNAL="$PROJECT_DIR/.claude/.memory-events.jsonl"
PROJECTOR="$PROJECT_DIR/.claude/tools/memory-project.sh"

FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
[ -z "$FILE_PATH" ] && exit 0

# Path scoping: must live under $MEMORY_DIR/ and end in .md.
case "$FILE_PATH" in
  "$MEMORY_DIR"/*.md) ;;
  *) exit 0 ;;
esac

base="$(basename "$FILE_PATH")"

# Skip MEMORY.md — the projection target, gated upstream by memory-index-gate.sh.
[ "$base" = "MEMORY.md" ] && exit 0

ENTRY_ID="${base%.md}"

# One-time "journal empty" advisory: if the journal doesn't exist yet,
# the contributor likely hasn't run memory-backfill.sh; the first edit
# would otherwise be recorded as `add` even for entries that have existed
# for weeks. Emit a hint before writing the first line.
if [ ! -e "$JOURNAL" ]; then
  printf 'memory-journal-advisory: journal empty; run `bash .claude/tools/memory-backfill.sh` once to seed history for the existing entries (otherwise first edits will misrecord as add)\n' >&2
fi

# event_type: if the journal already has an `add` for this entry_id → update;
# else → add. Read-only jq search; fail-safe if journal is missing/unparseable.
event_type="add"
if [ -e "$JOURNAL" ]; then
  prior="$(jq -c --arg id "$ENTRY_ID" 'select(.entry_id == $id and .event_type == "add")' "$JOURNAL" 2>/dev/null | head -1 || true)"
  [ -n "$prior" ] && event_type="update"
fi

ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
session_id="$(printf '%s' "$INPUT" | jq -r '.session_id // ""' 2>/dev/null || true)"
tool_use_id="$(printf '%s' "$INPUT" | jq -r '.tool_use_id // ""' 2>/dev/null || true)"
agent_type="$(printf '%s' "$INPUT" | jq -r '.agent_type // ""' 2>/dev/null || true)"
tool_name="$(printf '%s' "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null || true)"

actor="parent"
[ -n "$agent_type" ] && actor="$agent_type"

mkdir -p "$(dirname "$JOURNAL")" 2>/dev/null || true
audit_line="$(jq -c -n \
  --arg ts "$ts" \
  --arg event_type "$event_type" \
  --arg entry_id "$ENTRY_ID" \
  --arg actor "$actor" \
  --arg session_id "$session_id" \
  --arg tool_use_id "$tool_use_id" \
  --arg tool "$tool_name" \
  '{ts:$ts, event_type:$event_type, entry_id:$entry_id, actor:$actor, session_id:$session_id, tool_use_id:$tool_use_id, tool:$tool}' 2>/dev/null || true)"

if [ -z "$audit_line" ]; then
  printf 'memory-journal-advisory: failed to build event line (jq error)\n' >&2
  exit 0
fi

if ! { printf '%s\n' "$audit_line" >> "$JOURNAL"; } 2>/dev/null; then
  printf 'memory-journal-advisory: journal append failed (unwritable: %s)\n' "$JOURNAL" >&2
  exit 0
fi

# Regenerate MEMORY.md via the projection helper. Fail-open if the projector
# is missing or errors — the journal is already updated; index drift recovers
# on the next entry edit when the projector becomes available.
if [ -x "$PROJECTOR" ]; then
  if ! bash "$PROJECTOR" >/dev/null 2>&1; then
    printf 'memory-journal-advisory: projection failed (memory-project.sh exit non-zero); MEMORY.md may be stale\n' >&2
  fi
else
  printf 'memory-journal-advisory: projector %s not found or not executable; MEMORY.md may be stale\n' "$PROJECTOR" >&2
fi

exit 0
