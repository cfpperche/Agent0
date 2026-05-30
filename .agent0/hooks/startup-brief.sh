#!/usr/bin/env bash
# SessionStart hook: emit one bounded Agent0 startup brief.
#
# This is the only model-visible SessionStart hook registered by Agent0. Older
# readout scripts stay callable as helpers/tests, but the live runtime receives
# one summary-first block instead of several separate hook-context blocks.

set -uo pipefail

INPUT="$(cat 2>/dev/null || true)"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_memory-hook-lib.sh
. "$SCRIPT_DIR/_memory-hook-lib.sh"

PROJECT_DIR="$(memory_project_dir "$INPUT")"
SESSION_STATE_ROOT="$PROJECT_DIR/.agent0/.session-state"
SESSION_FILE="$PROJECT_DIR/.agent0/HANDOFF.md"
MAX_BYTES="${AGENT0_STARTUP_BRIEF_MAX_BYTES:-6000}"
MAX_LINES="${AGENT0_STARTUP_BRIEF_MAX_LINES:-80}"
REMINDER_LIMIT="${AGENT0_STARTUP_REMINDER_LIMIT:-5}"
REMINDER_TEXT_MAX="${AGENT0_STARTUP_REMINDER_TEXT_MAX:-220}"
HANDOFF_SECTION_LINES="${AGENT0_STARTUP_HANDOFF_SECTION_LINES:-2}"
TODAY="$(date -u +%Y-%m-%d)"

hook_event() {
  if command -v jq >/dev/null 2>&1 && [ -n "$INPUT" ]; then
    printf '%s' "$INPUT" | jq -r '.hook_event_name // "SessionStart"' 2>/dev/null || printf 'SessionStart'
  else
    printf 'SessionStart'
  fi
}

init_session_state() {
  local session_id_raw="" session_id state_dir
  if [[ -n "$INPUT" ]] && command -v jq >/dev/null 2>&1; then
    session_id_raw="$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null || true)"
  fi

  if [[ -n "$session_id_raw" && "$session_id_raw" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    session_id="$session_id_raw"
  else
    session_id="unknown"
  fi

  state_dir="$SESSION_STATE_ROOT/$session_id"
  mkdir -p "$state_dir"
  touch "$state_dir/started-at"
  rm -f "$state_dir/nagged"
  touch "$state_dir/edited-files.txt"

  if git -C "$PROJECT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    git -C "$PROJECT_DIR" status --porcelain >"$state_dir/start-porcelain.txt" 2>/dev/null || true
  fi

  find "$SESSION_STATE_ROOT" -mindepth 1 -maxdepth 1 -type d -mtime +7 -exec rm -rf {} + 2>/dev/null || true
}

section_body() {
  local heading="$1" file="$2"
  awk -v heading="$heading" '
    $0 == "## " heading { in_section=1; next }
    in_section && /^## / { exit }
    in_section { print }
  ' "$file" 2>/dev/null
}

summarize_handoff_section() {
  local heading="$1" body line display count=0
  body="$(section_body "$heading" "$SESSION_FILE")"
  # Flatten-safe sub-section marker (spec 125): '▸' makes Current State /
  # Active Work / Next Actions distinguishable from content bullets even when
  # the renderer collapses newlines into one physical line.
  printf '%s\n' "▸ $heading:"
  if [ -z "$body" ]; then
    printf '  - (empty)\n'
    return 0
  fi
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    case "$line" in
      "---"|"# "*|"_"*) continue ;;
    esac
    display="${line#- }"
    printf '  - %s\n' "$display"
    count=$((count + 1))
    [ "$count" -ge "$HANDOFF_SECTION_LINES" ] && break
  done <<EOF
$body
EOF
  [ "$count" -gt 0 ] || printf '  - (empty)\n'
}

summarize_handoff() {
  if [ ! -f "$SESSION_FILE" ]; then
    printf '=== handoff ===\n'
    printf "%s\n" "- '.agent0/HANDOFF.md' missing; create it to enable handoff."
    return 0
  fi

  printf '=== handoff ===\n'
  summarize_handoff_section "Current State"
  summarize_handoff_section "Active Work"
  summarize_handoff_section "Next Actions"
  printf 'Full handoff: .agent0/HANDOFF.md\n'
}

githooks_advisory() {
  if [[ -d "$PROJECT_DIR/.githooks" && "${CLAUDE_SKIP_GITHOOKS_HINT:-0}" != "1" ]]; then
    local current_hookspath
    current_hookspath="$(git -C "$PROJECT_DIR" config --get core.hooksPath 2>/dev/null || true)"
    if [[ "$current_hookspath" != ".githooks" ]]; then
      printf '=== githooks ===\n'
      printf 'Native git hooks NOT activated (gitleaks pre-commit inert).\n'
      printf 'Run once: git config core.hooksPath .githooks\n'
    fi
  fi
}

helper_output() {
  local script="$1"
  [ -x "$SCRIPT_DIR/$script" ] || return 0
  printf '%s' "$INPUT" | env -u CLAUDE_PROJECT_DIR AGENT0_PROJECT_DIR="$PROJECT_DIR" bash "$SCRIPT_DIR/$script" 2>/dev/null || true
}

summarize_reminders() {
  if [[ "${CLAUDE_SKIP_REMINDERS_READOUT:-0}" = "1" || "${AGENT0_SKIP_REMINDERS_READOUT:-0}" = "1" ]]; then
    return 0
  fi

  local out body total=0 line entry="" due="" include
  out="$(helper_output reminders-readout.sh)"
  body="$(printf '%s\n' "$out" | awk '
    /^=== REMINDERS ===$/ { in_body=1; next }
    /^=== end REMINDERS ===$/ { in_body=0; next }
    in_body { print }
  ')"
  [ -n "$body" ] || return 0
  if printf '%s\n' "$body" | grep -qx '(no pending reminders)'; then
    return 0
  fi

  printf '=== reminders ===\n'

  flush_reminder() {
    local compact
    [ -n "$entry" ] || return 0
    include=0
    if [ -z "$due" ] || [[ "$due" < "$TODAY" || "$due" == "$TODAY" ]]; then
      include=1
    fi
    if [ "$include" -eq 1 ]; then
      total=$((total + 1))
      if [ "$total" -le "$REMINDER_LIMIT" ]; then
        compact="${entry%%$'\n'*}"
        if [ "${#compact}" -gt "$REMINDER_TEXT_MAX" ]; then
          compact="${compact:0:REMINDER_TEXT_MAX}..."
        fi
        [ -n "$due" ] && compact+=" - due: $due"
        printf '%s\n' "$compact"
      fi
    fi
  }

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    case "$line" in
      "- ["*)
        flush_reminder
        entry="$line"$'\n'
        due=""
        ;;
      "  "*|"    "*)
        entry+="$line"$'\n'
        case "$line" in
          *"due: "*) due="${line##*due: }" ;;
        esac
        ;;
    esac
  done <<EOF
$body
EOF
  flush_reminder
  if [ "$total" -eq 0 ]; then
    printf '(no due or unscheduled reminders)\n'
  elif [ "$total" -gt "$REMINDER_LIMIT" ]; then
    printf '... %s more reminder(s); run /remind list for the full list.\n' "$((total - REMINDER_LIMIT))"
  fi
}

summarize_routines() {
  if [[ "${CLAUDE_SKIP_ROUTINES_READOUT:-0}" = "1" || "${AGENT0_SKIP_ROUTINES_READOUT:-0}" = "1" ]]; then
    return 0
  fi

  local out
  out="$(helper_output routines-readout.sh)"
  [ -n "$out" ] || return 0
  printf '%s\n' "$out"
}

summarize_memory_decay() {
  local out
  out="$(helper_output memory-decay-readout.sh)"
  [ -n "$out" ] || return 0
  if printf '%s\n' "$out" | grep -qxF '(no stale entries)'; then
    return 0
  fi
  printf '%s\n' "$out"
}

context_pointer() {
  printf '=== context ===\n'
  printf 'Rules live in .agent0/context/rules/. Prompt turns receive bounded capsules from context-inject.sh.\n'
  printf 'For full inventory: AGENT0_CONTEXT_DIAGNOSTIC=1 bash .agent0/hooks/context-inject.sh <payload.json\n'
}

trim_lines() {
  awk -v max="$MAX_LINES" 'NR <= max { print } NR == max + 1 { print "... output truncated by AGENT0_STARTUP_BRIEF_MAX_LINES" }'
}

trim_bytes() {
  if [ "${#1}" -le "$MAX_BYTES" ]; then
    printf '%s' "$1"
    return 0
  fi
  printf '%s\n... output truncated by AGENT0_STARTUP_BRIEF_MAX_BYTES\n' "${1:0:MAX_BYTES}"
}

emit_context() {
  local msg="$1" event="$2"
  [ -n "$msg" ] || exit 0
  if [ "$(memory_runtime "$INPUT")" = "codex-cli" ]; then
    printf '%s' "$msg"
  elif command -v jq >/dev/null 2>&1; then
    jq -n --arg event "$event" --arg msg "$msg" '{
      hookSpecificOutput: { hookEventName: $event, additionalContext: $msg }
    }' 2>/dev/null || printf '%s' "$msg"
  else
    printf '%s' "$msg"
  fi
}

build_brief() {
  local out trimmed
  out=$'AGENT0_STARTUP_BRIEF\n'
  out+="event: $(hook_event)"$'\n'
  out+=$'mode: summary\n'
  out+=$'budget: 6000 bytes / 80 lines by default\n\n'
  out+="$(summarize_handoff)"$'\n'
  out+="$(githooks_advisory)"$'\n'
  out+="$(summarize_reminders)"$'\n'
  out+="$(summarize_routines)"$'\n'
  out+="$(summarize_memory_decay)"$'\n'
  out+="$(context_pointer)"$'\n'
  out+=$'END_AGENT0_STARTUP_BRIEF\n'

  trimmed="$(printf '%s' "$out" | trim_lines)"
  trim_bytes "$trimmed"
}

init_session_state
emit_context "$(build_brief)" "$(hook_event)"
