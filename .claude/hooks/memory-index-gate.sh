#!/usr/bin/env bash
# .claude/hooks/memory-index-gate.sh
# PreToolUse(Edit|Write|MultiEdit) hook: blocks raw edits to
# .claude/memory/MEMORY.md unless the tool input carries
# `# OVERRIDE: memory-index-edit: <reason ≥10 chars>`.
# Override-bypassed edits are recorded as `manual-edit` events in
# .claude/.memory-events.jsonl.
#
# Exit codes: 0 = allow, 2 = block (Claude Code re-prompts the agent with stderr).
# jq is a hard dependency; if missing, the hook fails closed (exit 2) — matches
# delegation-gate.sh convention.
#
# Spec: docs/specs/083-memory-events-journal/
# Rule: .claude/rules/memory-placement.md § Event journal

set -uo pipefail

INPUT="$(cat 2>/dev/null || true)"
[ -z "$INPUT" ] && exit 0

if ! command -v jq >/dev/null 2>&1; then
  cat >&2 <<'EOF'
memory-index-gate: jq not found.
Failing closed (exit 2) — install jq to restore MEMORY.md edit capability.
EOF
  exit 2
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
MEMORY_DIR="$PROJECT_DIR/.claude/memory"
INDEX_PATH="$MEMORY_DIR/MEMORY.md"
JOURNAL="$PROJECT_DIR/.claude/.memory-events.jsonl"

FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null || true)"
[ -z "$FILE_PATH" ] && exit 0

# Scope: only fire on MEMORY.md (the projected index). Entry-file edits go
# through the journal hook on PostToolUse instead.
if [ "$FILE_PATH" != "$INDEX_PATH" ]; then
  exit 0
fi

# Override marker: grep across the serialized tool_input so the marker can
# appear in `new_string`, `content`, or any nested `edits[].new_string` field.
# Convention: prefix `# OVERRIDE: memory-index-edit: ` + reason; both inline
# (raw line) and HTML-comment (<!-- ... -->) forms match this pattern.
TOOL_INPUT_BLOB="$(printf '%s' "$INPUT" | jq -c '.tool_input // {}' 2>/dev/null || true)"

override_present=0
override_reason=""
override_too_short=0

raw_match="$(printf '%s' "$TOOL_INPUT_BLOB" | grep -oE '(# OVERRIDE: memory-index-edit: |<!-- OVERRIDE: memory-index-edit: )[^"\\]+' | head -1 || true)"
if [ -n "$raw_match" ]; then
  override_present=1
  # Strip whichever prefix form matched.
  reason="${raw_match#'# OVERRIDE: memory-index-edit: '}"
  reason="${reason#'<!-- OVERRIDE: memory-index-edit: '}"
  # Strip a trailing HTML-comment terminator and trailing whitespace.
  reason="$(printf '%s' "$reason" | sed -e 's/[[:space:]]*-->[[:space:]]*$//' -e 's/[[:space:]]*$//')"
  if [ ${#reason} -ge 10 ]; then
    override_reason="$reason"
  else
    override_too_short=1
  fi
fi

if [ "$override_present" -eq 0 ]; then
  cat >&2 <<'EOF'
memory-index-gate: blocked [raw-edit-without-override]

Direct edits to .claude/memory/MEMORY.md are gated — the index is a derived
view, regenerated from the entries' frontmatter.

To update MEMORY.md, do one of:

  1. Edit the underlying entry file (.claude/memory/<slug>.md), then run:
     bash .claude/tools/memory-project.sh
     (any entry edit through Edit/Write/MultiEdit auto-regenerates too)

  2. If a manual MEMORY.md edit is genuinely needed (cleanup, migration),
     include this marker in the edit content (inline or HTML comment):

       # OVERRIDE: memory-index-edit: <reason ≥10 chars>

     or

       <!-- OVERRIDE: memory-index-edit: <reason ≥10 chars> -->

     The bypass is recorded in .claude/.memory-events.jsonl as a
     `manual-edit` event with the reason as a field.

Spec: docs/specs/083-memory-events-journal/spec.md
Rule: .claude/rules/memory-placement.md § Event journal
EOF
  exit 2
fi

if [ "$override_too_short" -eq 1 ]; then
  cat >&2 <<'EOF'
memory-index-gate: blocked [override-reason-too-short]

An `# OVERRIDE: memory-index-edit:` marker was found, but the reason was
shorter than 10 characters after trimming. Lengthen the reason to a
greppable justification a future maintainer can audit.

Spec: docs/specs/083-memory-events-journal/spec.md
EOF
  exit 2
fi

# Override accepted — record the bypass before allowing the edit through.
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
  --arg event_type "manual-edit" \
  --arg entry_id "MEMORY.md" \
  --arg actor "$actor" \
  --arg session_id "$session_id" \
  --arg tool_use_id "$tool_use_id" \
  --arg tool "$tool_name" \
  --arg reason "$override_reason" \
  '{ts:$ts, event_type:$event_type, entry_id:$entry_id, actor:$actor, session_id:$session_id, tool_use_id:$tool_use_id, tool:$tool, reason:$reason}' 2>/dev/null || true)"

if [ -n "$audit_line" ]; then
  printf '%s\n' "$audit_line" >> "$JOURNAL" 2>/dev/null || true
fi

exit 0
