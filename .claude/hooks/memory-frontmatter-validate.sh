#!/usr/bin/env bash
# .claude/hooks/memory-frontmatter-validate.sh
# PostToolUse(Edit|Write|MultiEdit) hook: validates the YAML frontmatter shape
# of project-memory entries (`.claude/memory/*.md`, except MEMORY.md). Emits
# a non-blocking `memory-frontmatter-advisory:` line to stderr for each issue
# and always exits 0. Matches the `tdd-advisory:` / `lint-advisory:` family
# (see .claude/rules/delegation.md § Advisories).
#
# Schema authority: .claude/rules/memory-placement.md § Frontmatter schema
#
# bash 3.2-compatible: no associative arrays, no mapfile.

set -uo pipefail

INPUT="$(cat 2>/dev/null || true)"
[ -z "$INPUT" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
[ -z "$FILE_PATH" ] && exit 0

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
MEMORY_DIR="$PROJECT_DIR/.claude/memory"

# Path scoping: must live under $MEMORY_DIR/ and end in .md.
case "$FILE_PATH" in
  "$MEMORY_DIR"/*.md) ;;
  *) exit 0 ;;
esac

# Skip MEMORY.md — it is the lazy-read index, carries no frontmatter by design.
[ "$(basename "$FILE_PATH")" = "MEMORY.md" ] && exit 0

# Fail-open on unreadable file (e.g., concurrent delete).
[ -r "$FILE_PATH" ] || exit 0

REL="${FILE_PATH#$PROJECT_DIR/}"
SCHEMA_REF=".claude/rules/memory-placement.md § Frontmatter schema"

emit() {
  printf 'memory-frontmatter-advisory: %s: %s — see %s\n' "$REL" "$1" "$SCHEMA_REF" >&2
}

# Frontmatter must open with '---' on line 1.
FIRST_LINE="$(head -n1 "$FILE_PATH" 2>/dev/null || true)"
if [ "$FIRST_LINE" != "---" ]; then
  emit "no frontmatter block (expected '---' at line 1)"
  exit 0
fi

# Closing fence must exist somewhere after line 1.
SECOND_FENCE_LINE="$(awk 'NR>1 && /^---$/{print NR; exit}' "$FILE_PATH" 2>/dev/null || true)"
if [ -z "$SECOND_FENCE_LINE" ]; then
  emit "frontmatter unparseable: missing closing '---'"
  exit 0
fi

# Extract the body between fences.
FM_BODY="$(awk 'NR==1{next} /^---$/{exit} {print}' "$FILE_PATH" 2>/dev/null || true)"

# Walk frontmatter line by line. State machine: top-level vs nested-in-metadata.
HAS_NAME=0
HAS_DESC=0
HAS_TYPE=0
UNKNOWN_TOP=""
UNKNOWN_NESTED=""
IN_METADATA=0

while IFS= read -r line; do
  case "$line" in
    "") continue ;;
    \#*) continue ;;
  esac

  # Top-level key: column-0 [a-z_]+ followed by ':'.
  if printf '%s' "$line" | grep -qE '^[a-z_][a-z0-9_]*:'; then
    key="$(printf '%s' "$line" | sed -E 's/^([a-z_][a-z0-9_]*):.*/\1/')"
    case "$key" in
      name) HAS_NAME=1; IN_METADATA=0 ;;
      description) HAS_DESC=1; IN_METADATA=0 ;;
      metadata) IN_METADATA=1 ;;
      *) UNKNOWN_TOP="$UNKNOWN_TOP $key"; IN_METADATA=0 ;;
    esac
    continue
  fi

  # Nested key: exactly 2-space indent + [a-z_]+ followed by ':'. Only
  # meaningful inside the metadata block.
  if [ "$IN_METADATA" = "1" ] && printf '%s' "$line" | grep -qE '^  [a-z_][a-z0-9_]*:'; then
    key="$(printf '%s' "$line" | sed -E 's/^  ([a-z_][a-z0-9_]*):.*/\1/')"
    case "$key" in
      type) HAS_TYPE=1 ;;
      created_at|last_accessed|confirmed_count) ;;
      *) UNKNOWN_NESTED="$UNKNOWN_NESTED metadata.$key" ;;
    esac
    continue
  fi

  # Deeper indent / malformed line — tolerated (advisory,
  # not a YAML validator; downstream consumers catch real shape failures).
done <<EOF
$FM_BODY
EOF

# Required-field advisories.
[ "$HAS_NAME" = "0" ] && emit "missing required field 'name'"
[ "$HAS_DESC" = "0" ] && emit "missing required field 'description'"
[ "$HAS_TYPE" = "0" ] && emit "missing required field 'metadata.type'"

# Unknown-field advisories (typo guard).
for k in $UNKNOWN_TOP; do
  emit "unknown field '$k' — typo guard, allowed top-level: name, description, metadata"
done
for k in $UNKNOWN_NESTED; do
  emit "unknown field '$k' — typo guard, allowed metadata.*: type, created_at, last_accessed, confirmed_count"
done

exit 0
