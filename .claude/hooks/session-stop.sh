#!/usr/bin/env bash
# Stop hook: block once per session if the repo has uncommitted changes but
# SESSION.md was not updated during this session.
#
# Escape hatch: set CLAUDE_SKIP_SESSION_HOOKS=1 to disable.

set -euo pipefail

[[ "${CLAUDE_SKIP_SESSION_HOOKS:-0}" == "1" ]] && exit 0

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
STATE_DIR="$PROJECT_DIR/.claude/.session-state"
SESSION_FILE="$PROJECT_DIR/.claude/SESSION.md"
STARTED_AT="$STATE_DIR/started-at"
NAGGED="$STATE_DIR/nagged"

# No session-start marker → nothing to enforce.
[[ -f "$STARTED_AT" ]] || exit 0

# Already nagged this session → don't loop.
if [[ -f "$NAGGED" && "$NAGGED" -nt "$STARTED_AT" ]]; then
  exit 0
fi

# Not a git repo → can't detect changes, skip enforcement.
git -C "$PROJECT_DIR" rev-parse --git-dir >/dev/null 2>&1 || exit 0

# No uncommitted changes → no work to log.
if [[ -z "$(git -C "$PROJECT_DIR" status --porcelain 2>/dev/null)" ]]; then
  exit 0
fi

# SESSION.md updated during this session → all good.
if [[ -f "$SESSION_FILE" && "$SESSION_FILE" -nt "$STARTED_AT" ]]; then
  exit 0
fi

# Block once and re-prompt the model.
touch "$NAGGED"
cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"Stop","decision":"block","additionalContext":"Before ending this session: the repo has uncommitted changes but SESSION.md was not updated this session. Update SESSION.md (Current state / WIP / Next steps / Decisions & gotchas) so the next session can pick up where this one left off. Then end your turn normally — this hook will not block again this session."}}
JSON
