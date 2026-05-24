#!/usr/bin/env bash
# .claude/tools/memory-project.sh
# Regenerates .claude/memory/MEMORY.md from the current entries' YAML frontmatter.
# Reads `name` + `description` per the 082 schema and emits one bullet per entry
# sorted by filename slug.
#
# Idempotent + deterministic: re-running on an unchanged corpus produces
# byte-identical output. LC_ALL=C locks sort order cross-machine.
#
# Spec: docs/specs/083-memory-events-journal/
# Schema: .claude/rules/memory-placement.md § Frontmatter schema

set -uo pipefail
LC_ALL=C

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
MEMORY_DIR="$PROJECT_DIR/.claude/memory"
INDEX_PATH="$MEMORY_DIR/MEMORY.md"

if [ ! -d "$MEMORY_DIR" ]; then
  printf 'memory-project: %s does not exist\n' "$MEMORY_DIR" >&2
  exit 1
fi

# strip_quotes <value> — removes one matching pair of surrounding "..." or '...'.
strip_quotes() {
  local v="$1"
  case "$v" in
    \"*\") v="${v#\"}"; v="${v%\"}" ;;
    \'*\') v="${v#\'}"; v="${v%\'}" ;;
  esac
  printf '%s' "$v"
}

tmp="$(mktemp 2>/dev/null || mktemp -t memory-project)"
trap 'rm -f "$tmp"' EXIT

for file in "$MEMORY_DIR"/*.md; do
  [ -e "$file" ] || continue
  base="$(basename "$file")"
  [ "$base" = "MEMORY.md" ] && continue

  slug="${base%.md}"

  # Frontmatter body: lines between first '---' (line 1) and the next '---'.
  fm="$(awk 'NR==1 && /^---$/ {in_fm=1; next} in_fm && /^---$/ {exit} in_fm' "$file" 2>/dev/null || true)"
  [ -z "$fm" ] && continue

  name="$(printf '%s\n' "$fm" | awk '/^name:/{sub(/^name:[[:space:]]*/, ""); print; exit}')"
  description="$(printf '%s\n' "$fm" | awk '/^description:/{sub(/^description:[[:space:]]*/, ""); print; exit}')"

  name="$(strip_quotes "$name")"
  description="$(strip_quotes "$description")"

  [ -z "$name" ] && name="$slug"
  [ -z "$description" ] && continue

  # Sort-key first column (slug), tab-separated. cut -f2- strips it after sort.
  printf '%s\t- [%s](%s.md) — %s\n' "$slug" "$name" "$slug" "$description" >> "$tmp"
done

sort -t "$(printf '\t')" -k1,1 "$tmp" | cut -f2- > "$INDEX_PATH"

count="$(wc -l < "$INDEX_PATH" | tr -d ' ')"
printf 'memory-project: regenerated %s with %s entries\n' "$INDEX_PATH" "$count" >&2
