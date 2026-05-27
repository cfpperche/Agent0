#!/usr/bin/env bash
# .claude/hooks/propagation-advise.sh
# PostToolUse(Edit|Write|MultiEdit) hook — emits `propagation-advisory:`
# lines when an edit to a shipped file introduces an upstream-internal
# pointer (spec-NNN refs, docs/specs/NNN paths, anthill mentions, personal
# /home/<user>/ paths, .agent0/memory/<file>.md pointers).
#
# Mirrors the tdd-advisory: / lint-advisory: / secrets-advisory: family —
# always exits 0, never blocks. Fires for both parent AND sub-agent edits
# (the maintainer writing new rules is the most common author).
#
# Discipline: .agent0/memory/propagation-hygiene.md
# Rule:       .claude/rules/propagation-advisory.md
#
# Opt-out:    CLAUDE_SKIP_PROPAGATION_ADVISE=1
# Override:   `# OVERRIDE: propagation-exempt: <reason ≥10 chars>` in edit content
#
# bash 3.2-compatible: no associative arrays, no mapfile, no `[[ =~ ]]`,
# no `<<<` herestring.

set -uo pipefail

# Opt-out gate.
[ "${CLAUDE_SKIP_PROPAGATION_ADVISE:-0}" = "1" ] && exit 0

INPUT="$(cat 2>/dev/null || true)"
[ -z "$INPUT" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

TOOL_NAME="$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || true)"
FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
[ -z "$FILE_PATH" ] && exit 0

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
REL="${FILE_PATH#$PROJECT_DIR/}"

# ---------------------------------------------------------------------------
# Path scoping — only fire on shipped surface (per propagation-hygiene.md
# § The shipped file class).
# ---------------------------------------------------------------------------
in_shipped=0
case "$REL" in
  CLAUDE.md|.mcp.json.example|.gitleaks.toml|.gitignore) in_shipped=1 ;;
  .claude/hooks/*|.claude/rules/*|.claude/tools/*|.claude/validators/*|.claude/agents/*) in_shipped=1 ;;
  .agent0/hooks/*|.agent0/tools/*) in_shipped=1 ;;
  .claude/skills/*|.claude/tests/*|.githooks/*) in_shipped=1 ;;
esac
[ "$in_shipped" = "0" ] && exit 0

# Within-surface exclusions — these paths legitimately carry refs.
case "$REL" in
  # Vendor content (open-design, design-systems) has its own provenance.
  .claude/skills/*/vendor/*|.claude/skills/*/design-systems/*) exit 0 ;;
  # Self-exclusions: the hook, rule, and tests document the patterns inline.
  .claude/hooks/propagation-advise.sh) exit 0 ;;
  .claude/rules/propagation-advisory.md) exit 0 ;;
  .claude/tests/propagation-advisory/*) exit 0 ;;
esac

# ---------------------------------------------------------------------------
# Extract edit content per tool variant.
# ---------------------------------------------------------------------------
CONTENT_FILE="$(mktemp 2>/dev/null || true)"
[ -z "$CONTENT_FILE" ] && exit 0
trap 'rm -f "$CONTENT_FILE" 2>/dev/null || true' EXIT

case "$TOOL_NAME" in
  Edit)
    printf '%s' "$INPUT" | jq -r '.tool_input.new_string // empty' > "$CONTENT_FILE" 2>/dev/null || exit 0
    ;;
  Write)
    printf '%s' "$INPUT" | jq -r '.tool_input.content // empty' > "$CONTENT_FILE" 2>/dev/null || exit 0
    ;;
  MultiEdit)
    N="$(printf '%s' "$INPUT" | jq -r '.tool_input.edits // [] | length' 2>/dev/null || echo 0)"
    [ -z "$N" ] && N=0
    [ "$N" -eq 0 ] && exit 0
    i=0
    while [ "$i" -lt "$N" ]; do
      printf '%s' "$INPUT" | jq -r ".tool_input.edits[$i].new_string // empty" >> "$CONTENT_FILE" 2>/dev/null || true
      printf '\n' >> "$CONTENT_FILE"
      i=$((i + 1))
    done
    ;;
  *) exit 0 ;;
esac

[ -s "$CONTENT_FILE" ] || exit 0

# ---------------------------------------------------------------------------
# Override marker — same grammar as the project's other gates.
# ---------------------------------------------------------------------------
if grep -qE '^[[:space:]]*#[[:space:]]*OVERRIDE:[[:space:]]*propagation-exempt:[[:space:]]*.{10,}' "$CONTENT_FILE"; then
  exit 0
fi

# ---------------------------------------------------------------------------
# Emit helper.
# ---------------------------------------------------------------------------
emit_one() {
  # $1 = pattern label
  # $2 = grep output line in "lineno:text" form
  local label="$1" raw="$2" lineno text
  lineno="${raw%%:*}"
  text="${raw#*:}"
  text="$(printf '%s' "$text" | cut -c1-80)"
  printf 'propagation-advisory: %s in %s:%s — %s\n' "$label" "$REL" "$lineno" "$text" >&2
}

scan_pattern() {
  # $1 = label, $2 = grep ERE pattern, $3 = optional grep -v ERE filter
  local label="$1" pattern="$2" exclude="${3:-}"
  local tmp_hits
  tmp_hits="$(mktemp 2>/dev/null || true)"
  [ -z "$tmp_hits" ] && return 0
  if [ -n "$exclude" ]; then
    grep -nE "$pattern" "$CONTENT_FILE" 2>/dev/null | grep -vE "$exclude" | head -5 > "$tmp_hits" 2>/dev/null || true
  else
    grep -nE "$pattern" "$CONTENT_FILE" 2>/dev/null | head -5 > "$tmp_hits" 2>/dev/null || true
  fi
  if [ -s "$tmp_hits" ]; then
    while IFS= read -r m; do
      [ -n "$m" ] && emit_one "$label" "$m"
    done < "$tmp_hits"
  fi
  rm -f "$tmp_hits" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# 5 patterns from propagation-hygiene.md § The mandate.
# Each pattern uses `head -5` to cap noise — if an edit introduces dozens
# of leaks, the first 5 are signal enough for the maintainer to react.
# ---------------------------------------------------------------------------

# 1. Concrete spec-NNN refs: "spec 080", "Spec 12", "spec 1234".
#    The 2+-digit floor avoids matching "spec 5" / "spec 1" false positives
#    (those are too short to be Agent0 spec numbers — Agent0 specs are
#    3-digit zero-padded per the NNN-<slug>/ convention).
scan_pattern "spec-NNN" '\b[Ss]pec [0-9][0-9]+\b' ''

# 2. Concrete docs/specs/ paths. Excludes the placeholder NNN form and the
#    three consumer-output paths that /product writes (001-<slug>, 002-foundation,
#    003-* infra-children).
scan_pattern "docs/specs/NNN" 'docs/specs/[0-9]+-' \
  '001-\{\{SLUG\}\}|001-<slug>|002-foundation|003-\*|NNN-<slug>|NNN-\{\{SLUG\}\}'

# 3. Anthill mentions — case-insensitive. Anthill is the archived upstream
#    design lineage; consumer projects have zero context for it.
scan_pattern "anthill" '\banthill\b' ''

# 4. Personal /home/<user>/ paths. The pattern matches /home/<segment>/
#    where <segment> is lowercase letters/digits/underscores/hyphens.
#    The trailing slash requirement avoids matching prose like "in /home".
scan_pattern "personal-path" '/home/[a-z][a-z0-9_-]+/' ''

# 5. Memory-file path pointers. Excludes the MEMORY.md index and the
#    placeholder forms a rule may legitimately reference.
scan_pattern "memory-pointer" '\.agent0/memory/[a-z][a-z0-9_-]+\.md' \
  'MEMORY\.md|<topic>|<slug>|<file>|<name>|\.gitkeep'

exit 0
