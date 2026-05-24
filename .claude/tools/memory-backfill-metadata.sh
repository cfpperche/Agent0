#!/usr/bin/env bash
# memory-backfill-metadata.sh — one-shot populate created_at / last_accessed /
# confirmed_count on the existing .claude/memory/*.md entries.
#
# Idempotent: the helper no-ops when all 3 fields are already present.
# Run once during spec 086 ship; not part of the running capacity.
# Forks adopting the schema populate organically as entries get touched.

set -uo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
HELPER="$PROJECT_DIR/.claude/tools/memory-query-helper.py"
MEM_DIR="$PROJECT_DIR/.claude/memory"

if [[ ! -x "$HELPER" ]]; then
  printf 'memory-backfill: helper not executable: %s\n' "$HELPER" >&2
  exit 3
fi
if [[ ! -d "$MEM_DIR" ]]; then
  printf 'memory-backfill: %s missing\n' "$MEM_DIR" >&2
  exit 3
fi

processed=0
skipped=0
for f in "$MEM_DIR"/*.md; do
  base="$(basename "$f")"
  [[ "$base" == "MEMORY.md" ]] && continue
  out=$(CLAUDE_PROJECT_DIR="$PROJECT_DIR" python3 "$HELPER" backfill-metadata "$f" 2>&1)
  if [[ -n "$out" ]]; then
    printf '%s\n' "$out"
    processed=$((processed + 1))
  else
    skipped=$((skipped + 1))
  fi
done

printf '\nmemory-backfill: %d backfilled, %d already populated (skipped)\n' "$processed" "$skipped"
