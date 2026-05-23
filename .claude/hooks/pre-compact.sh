#!/usr/bin/env bash
# PreCompact hook: snapshot the last N real user turns + assistant text/tool_use
# into a per-event file under .claude/.compact-history/ so the SessionStart
# hook (source=compact) can re-inject the raw signal that /compact's summarizer
# would otherwise compress away.
#
# Captures verbatim: user messages, assistant text, tool names + truncated args.
# Drops: tool_result bodies (stale post-compact), assistant thinking blocks.
#
# Filename shape: <ISO-second>-<pid>-<rand5>.md — lex order equals chrono order
# across seconds; the pid+random5 suffix is the tie-breaker for the (rare)
# case of two compactions in the same UTC second. Bash 3.2 / BSD-compatible
# (no GNU-only `date +%N`). Retention: compactHistory.keepLast in
# .claude/settings.json (default 20).

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
HISTORY_DIR="$PROJECT_DIR/.claude/.compact-history"
printf -v RAND_PAD '%05d' "$RANDOM"
NOTES_FILE="$HISTORY_DIR/$(date -u +%Y-%m-%dT%H-%M-%SZ)-$$-$RAND_PAD.md"
TURNS_TO_KEEP=12

INPUT="$(cat 2>/dev/null || true)"
TRANSCRIPT_PATH=""
TRIGGER="unknown"
CUSTOM=""
if [[ -n "$INPUT" ]]; then
  TRANSCRIPT_PATH="$(printf '%s' "$INPUT" | jq -r '.transcript_path // ""' 2>/dev/null || true)"
  TRIGGER="$(printf '%s' "$INPUT" | jq -r '.trigger // "unknown"' 2>/dev/null || echo unknown)"
  CUSTOM="$(printf '%s' "$INPUT" | jq -r '.custom_instructions // ""' 2>/dev/null || true)"
fi

[[ -n "$TRANSCRIPT_PATH" && -f "$TRANSCRIPT_PATH" ]] || exit 0

GIT_BRANCH=""
GIT_STATUS=""
if git -C "$PROJECT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
  GIT_BRANCH="$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null || true)"
  GIT_STATUS="$(git -C "$PROJECT_DIR" status --porcelain 2>/dev/null || true)"
fi

TURNS_MD="$(jq -rs --argjson n "$TURNS_TO_KEEP" '
  . as $all
  | [range(0; length) as $i
     | select($all[$i].type == "user"
              and (($all[$i].message.content // null) | type == "string"))
     | $i] as $boundaries
  | ($boundaries | length) as $count
  | (if $count == 0 then 0
     elif $count > $n then $boundaries[$count - $n]
     else $boundaries[0]
     end) as $start
  | $all[$start:]
  | map(
      if .type == "user" and ((.message.content // null) | type == "string") then
        "\n\n### USER\n\n" + .message.content
      elif .type == "assistant" then
        ([(.message.content // [])[]
          | if .type == "text" then
              "\n\n### ASSISTANT\n\n" + (.text // "")
            elif .type == "tool_use" then
              "\n\n`[tool: " + (.name // "?") + " " + ((.input // {}) | tostring | .[0:200]) + "]`"
            else empty end
         ] | add) // ""
      else "" end
    )
  | join("")
' "$TRANSCRIPT_PATH" 2>/dev/null || true)"

mkdir -p "$HISTORY_DIR"

{
  echo "# Pre-compact snapshot"
  echo
  echo "Captured by \`.claude/hooks/pre-compact.sh\` immediately before context compaction."
  echo "Last $TURNS_TO_KEEP user turns + assistant text/tool_use, verbatim. Tool outputs and thinking blocks dropped (stale post-compact)."
  echo
  echo "**Trigger:** \`$TRIGGER\`  "
  echo "**Generated:** $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [[ -n "$CUSTOM" && "$CUSTOM" != "null" ]]; then
    echo
    echo "**User compact instructions:**"
    echo
    echo "> $CUSTOM"
  fi
  if [[ -n "$GIT_BRANCH" ]]; then
    echo
    echo "**Branch:** \`$GIT_BRANCH\`"
    if [[ -n "$GIT_STATUS" ]]; then
      echo
      echo "**Uncommitted changes:**"
      echo
      echo '```'
      printf '%s\n' "$GIT_STATUS"
      echo '```'
    else
      echo "(working tree clean)"
    fi
  fi
  echo
  echo "---"
  printf '%s\n' "$TURNS_MD"
} > "$NOTES_FILE"

# Retention: prune oldest snapshots beyond compactHistory.keepLast (default 20).
# Per-write trim — no continuous sweep. ls -1t sorts by mtime descending; we
# delete tail entries past the cap. xargs -r is a no-op when the pipe is empty
# (guards against `rm -f` with zero args on some platforms).
KEEP_LAST="$(jq -r '.compactHistory.keepLast // 20' "$PROJECT_DIR/.claude/settings.json" 2>/dev/null || echo 20)"
if ! [[ "$KEEP_LAST" =~ ^[0-9]+$ ]] || [[ "$KEEP_LAST" -lt 1 ]]; then
  KEEP_LAST=20
fi
ls -1t "$HISTORY_DIR"/*.md 2>/dev/null | tail -n +$((KEEP_LAST + 1)) | xargs -r rm -f 2>/dev/null || true

exit 0
