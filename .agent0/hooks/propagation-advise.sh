#!/usr/bin/env bash
# .agent0/hooks/propagation-advise.sh
# PostToolUse hook — emits `propagation-advisory:` lines when an edit to a
# shipped file introduces an upstream-internal pointer (spec-NNN refs,
# docs/specs/NNN paths, anthill mentions, personal /home/<user>/ paths,
# .agent0/memory/<file>.md pointers).
#
# Runtime-neutral (spec 113): fires on Claude `Edit|Write|MultiEdit` AND on
# Codex `apply_patch`. Maintainer-only — excluded from consumer shipping via
# sync-harness `COPY_CHECK_EXCLUDE` (the file) + the `merge_settings_json`
# companion filter (the Claude registration). The Codex registration is NOT
# shipped in `.codex/config.toml.example`; the maintainer adds it to their own
# gitignored `.codex/config.toml` (see propagation-advisory-maintenance.md).
#
# Mirrors the tdd-advisory: / lint-advisory: family — always exits 0, never
# blocks. Fires for both parent AND sub-agent edits (the maintainer writing new
# rules is the most common author of fresh leaks).
#
# Discipline: .agent0/memory/propagation-hygiene.md
# Rule:       .agent0/context/rules/propagation-advisory.md
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_memory-hook-lib.sh
. "$SCRIPT_DIR/_memory-hook-lib.sh"

PROJECT_DIR="$(memory_project_dir "$INPUT")"
TOOL_NAME="$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || true)"
RUNTIME="$(memory_runtime "$INPUT")"

# Maintainer diagnostic (off by default): dump the raw hook payload so the real
# Codex apply_patch shape can be inspected when the advisory unexpectedly stays
# silent. Set AGENT0_PROPAGATION_DEBUG=1 in the runtime env to capture.
if [ -n "${AGENT0_PROPAGATION_DEBUG:-}" ]; then
  printf '%s' "$INPUT" > "$PROJECT_DIR/.agent0/.propagation-debug.json" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Shipped-surface predicate (per propagation-hygiene.md § The shipped file
# class). Returns 0 when REL is a shipped path AND not a within-surface
# exclusion; 1 otherwise.
# ---------------------------------------------------------------------------
in_shipped_surface() {
  rel="$1"
  in_shipped=0
  case "$rel" in
    CLAUDE.md|.mcp.json.example|.gitleaks.toml|.gitignore) in_shipped=1 ;;
    .claude/hooks/*|.agent0/context/rules/*|.agent0/validators/*|.claude/agents/*) in_shipped=1 ;;
    .agent0/hooks/*|.agent0/tools/*) in_shipped=1 ;;
    .claude/skills/*|.agent0/tests/*|.githooks/*) in_shipped=1 ;;
  esac
  [ "$in_shipped" = "0" ] && return 1
  # Within-surface exclusions — these paths legitimately carry refs.
  case "$rel" in
    .claude/skills/*/vendor/*|.claude/skills/*/design-systems/*) return 1 ;;
    .agent0/hooks/propagation-advise.sh) return 1 ;;
    .agent0/context/rules/propagation-advisory.md) return 1 ;;
    .agent0/tests/propagation-advisory/*) return 1 ;;
  esac
  return 0
}

# ---------------------------------------------------------------------------
# Emit + scan helpers — operate on globals REL (advisory label path),
# CONTENT_FILE (file holding the just-added content to scan), and
# ADVISORY_FILE (Codex-only JSON context accumulator).
# ---------------------------------------------------------------------------
emit_one() {
  # $1 = pattern label, $2 = grep output line in "lineno:text" form
  local label="$1" raw="$2" lineno text
  lineno="${raw%%:*}"
  text="${raw#*:}"
  text="$(printf '%s' "$text" | cut -c1-80)"
  # Channel by runtime: Claude surfaces exit-0 PostToolUse stderr. Codex ignores
  # plain stdout/stderr for PostToolUse; JSON stdout with
  # hookSpecificOutput.additionalContext is the documented developer-context
  # path. Always exit 0 (advisory).
  if [ "$RUNTIME" = "codex-cli" ]; then
    printf 'propagation-advisory: %s in %s:%s — %s\n' "$label" "$REL" "$lineno" "$text" >> "$ADVISORY_FILE"
  else
    printf 'propagation-advisory: %s in %s:%s — %s\n' "$label" "$REL" "$lineno" "$text" >&2
  fi
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

# Scan one (relpath, content-file) pair. Honours the override marker, then runs
# the 5 leak-pattern scans. Caller guarantees REL is in the shipped surface.
scan_one() {
  REL="$1"
  CONTENT_FILE="$2"
  [ -s "$CONTENT_FILE" ] || return 0

  # Override marker — same grammar as the project's other gates.
  if grep -qE '^[[:space:]]*#[[:space:]]*OVERRIDE:[[:space:]]*propagation-exempt:[[:space:]]*.{10,}' "$CONTENT_FILE"; then
    return 0
  fi

  # 5 patterns from propagation-hygiene.md § The mandate. Each uses `head -5`
  # to cap noise — the first 5 are signal enough for the maintainer to react.

  # 1. Concrete spec-NNN refs: "spec 080". 2+-digit floor avoids "spec 5".
  scan_pattern "spec-NNN" '\b[Ss]pec [0-9][0-9]+\b' ''
  # 2. Concrete docs/specs/ paths. Excludes placeholder + /product output paths.
  scan_pattern "docs/specs/NNN" 'docs/specs/[0-9]+-' \
    '001-\{\{SLUG\}\}|001-<slug>|002-foundation|003-\*|NNN-<slug>|NNN-\{\{SLUG\}\}'
  # 3. Anthill mentions — case-insensitive. Archived upstream design lineage.
  scan_pattern "anthill" '\banthill\b' ''
  # 4. Personal /home/<user>/ paths.
  scan_pattern "personal-path" '/home/[a-z][a-z0-9_-]+/' ''
  # 5. Memory-file path pointers. Excludes the index + placeholder forms.
  scan_pattern "memory-pointer" '\.agent0/memory/[a-z][a-z0-9_-]+\.md' \
    'MEMORY\.md|<topic>|<slug>|<file>|<name>|\.gitkeep'
}

# ---------------------------------------------------------------------------
# Build (relpath, content) pairs per runtime, feed each to scan_one.
# ---------------------------------------------------------------------------
TMP_CONTENT="$(mktemp 2>/dev/null || true)"
[ -z "$TMP_CONTENT" ] && exit 0
TMP_STREAM="$(mktemp 2>/dev/null || true)"
[ -z "$TMP_STREAM" ] && { rm -f "$TMP_CONTENT" 2>/dev/null || true; exit 0; }
ADVISORY_FILE="$(mktemp 2>/dev/null || true)"
[ -z "$ADVISORY_FILE" ] && { rm -f "$TMP_CONTENT" "$TMP_STREAM" 2>/dev/null || true; exit 0; }
trap 'rm -f "$TMP_CONTENT" "$TMP_STREAM" "$ADVISORY_FILE" 2>/dev/null || true' EXIT

case "$TOOL_NAME" in
  Edit|Write|MultiEdit)
    # --- Claude path: one (file_path, new-content) pair. ---
    FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
    [ -z "$FILE_PATH" ] && exit 0
    REL_PATH="$(memory_relpath "$PROJECT_DIR" "$FILE_PATH")"
    in_shipped_surface "$REL_PATH" || exit 0

    : > "$TMP_CONTENT"
    case "$TOOL_NAME" in
      Edit)
        printf '%s' "$INPUT" | jq -r '.tool_input.new_string // empty' > "$TMP_CONTENT" 2>/dev/null || exit 0
        ;;
      Write)
        printf '%s' "$INPUT" | jq -r '.tool_input.content // empty' > "$TMP_CONTENT" 2>/dev/null || exit 0
        ;;
      MultiEdit)
        N="$(printf '%s' "$INPUT" | jq -r '.tool_input.edits // [] | length' 2>/dev/null || echo 0)"
        [ -z "$N" ] && N=0
        [ "$N" -eq 0 ] && exit 0
        i=0
        while [ "$i" -lt "$N" ]; do
          printf '%s' "$INPUT" | jq -r ".tool_input.edits[$i].new_string // empty" >> "$TMP_CONTENT" 2>/dev/null || true
          printf '\n' >> "$TMP_CONTENT"
          i=$((i + 1))
        done
        ;;
    esac
    scan_one "$REL_PATH" "$TMP_CONTENT"
    ;;

  apply_patch)
    # --- Codex path: per-file added content from the patch body. ---
    # The patch body is split into per-file sections by `*** (Add|Update|
    # Delete|Move) File:` / `*** Move to:` headers. Add File scans raw new-file
    # content; Update File scans only `+` hunk additions.
    BODY="$(memory_patch_body "$INPUT")"
    [ -z "$BODY" ] && exit 0

    # Emit a tab-separated stream: "P\t<path>" on each file header, "A\t<line>"
    # for each added line. Begin/End/@@ and removed/context lines are ignored.
    # `*** Add File:` content is raw lines (a new file) — possibly +-prefixed
    # depending on the apply_patch variant; treat every non-marker line as added.
    # `*** Update File:` hunks are unified-diff style — only `^+` lines are
    # additions (context/removed lines must be skipped). Begin/End/@@ ignored.
    printf '%s\n' "$BODY" | awk '
      /^\*\*\* Add File: / {
        mode="add"; p=$0; sub(/^\*\*\* Add File: /, "", p)
        print "P\t" p; next
      }
      /^\*\*\* (Update|Delete) File: / {
        mode="hunk"; p=$0; sub(/^\*\*\* (Update|Delete) File: /, "", p)
        print "P\t" p; next
      }
      /^\*\*\* Move to: / {
        p=$0; sub(/^\*\*\* Move to: /, "", p)
        print "P\t" p; next
      }
      /^\*\*\* (Begin|End) Patch/ { next }
      /^@@/ { next }
      {
        if (mode == "add") {
          line=$0; sub(/^\+/, "", line)
          print "A\t" line; next
        }
        if (mode == "hunk" && $0 ~ /^\+/) {
          print "A\t" substr($0, 2); next
        }
      }
    ' > "$TMP_STREAM" 2>/dev/null || exit 0

    cur=""
    : > "$TMP_CONTENT"
    flush_section() {
      [ -n "$cur" ] || return 0
      if in_shipped_surface "$cur" && [ -s "$TMP_CONTENT" ]; then
        scan_one "$cur" "$TMP_CONTENT"
      fi
      : > "$TMP_CONTENT"
    }
    while IFS="$(printf '\t')" read -r kind val; do
      case "$kind" in
        P)
          flush_section
          cur="$(memory_relpath "$PROJECT_DIR" "$val")"
          ;;
        A)
          printf '%s\n' "$val" >> "$TMP_CONTENT"
          ;;
      esac
    done < "$TMP_STREAM"
    flush_section
    ;;

  *)
    exit 0
    ;;
esac

if [ "$RUNTIME" = "codex-cli" ] && [ -s "$ADVISORY_FILE" ]; then
  jq -Rs '{
    hookSpecificOutput: {
      hookEventName: "PostToolUse",
      additionalContext: .
    }
  }' < "$ADVISORY_FILE" 2>/dev/null || true
fi

exit 0
