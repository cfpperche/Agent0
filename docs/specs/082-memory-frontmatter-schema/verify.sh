#!/usr/bin/env bash
# Spec 082 verify.sh — exercises the 9 behavior scenarios in spec.md against
# .claude/hooks/memory-frontmatter-validate.sh. Run from anywhere; resolves
# paths relative to this script's location.
#
# Exit 0 if all scenarios pass; non-zero if any fail.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
HOOK="$REPO_ROOT/.claude/hooks/memory-frontmatter-validate.sh"

if [ ! -x "$HOOK" ]; then
  echo "RED: hook not found or not executable at $HOOK"
  echo "     (this is expected during TDD red phase before task 3 lands)"
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "FAIL: jq required" >&2
  exit 2
fi

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

# Mirror .claude/memory/ under TMPDIR so the hook's path scoping (rooted at
# CLAUDE_PROJECT_DIR) treats fixtures as in-scope.
MEMDIR="$TMPDIR/.claude/memory"
mkdir -p "$MEMDIR" "$TMPDIR/.claude/rules"

PASS=0
FAIL=0
ALL_STDERR=""

run_scenario() {
  local name="$1"
  local fixture_file="$2"
  local expected_stderr_pattern="$3"   # regex, or "EMPTY"
  local expected_exit="$4"
  local cpd="${5:-$TMPDIR}"

  local payload
  payload=$(jq -n --arg fp "$fixture_file" '{tool_input:{file_path:$fp}}')
  local stderr_file
  stderr_file="$(mktemp)"
  local actual_exit=0
  CLAUDE_PROJECT_DIR="$cpd" bash "$HOOK" <<<"$payload" 2>"$stderr_file" || actual_exit=$?
  local actual_stderr
  actual_stderr="$(cat "$stderr_file")"
  rm -f "$stderr_file"

  ALL_STDERR="$ALL_STDERR
$actual_stderr"

  local ok=1
  if [ "$actual_exit" != "$expected_exit" ]; then
    ok=0
    echo "FAIL [$name]: expected exit $expected_exit, got $actual_exit"
  fi
  if [ "$expected_stderr_pattern" = "EMPTY" ]; then
    if [ -n "$actual_stderr" ]; then
      ok=0
      echo "FAIL [$name]: expected empty stderr, got:"
      printf '  %s\n' "$actual_stderr"
    fi
  else
    if ! grep -qE "$expected_stderr_pattern" <<<"$actual_stderr"; then
      ok=0
      echo "FAIL [$name]: expected stderr matching /$expected_stderr_pattern/, got:"
      printf '  %s\n' "$actual_stderr"
    fi
  fi
  if [ "$ok" = "1" ]; then
    echo "PASS [$name]"
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
  fi
}

# ---------- Scenario S3: conforming entry passes silently ----------
cat >"$MEMDIR/conforming.md" <<'EOF'
---
name: conforming
description: a fully conforming entry for the happy path test
metadata:
  type: project
---
# Body
EOF
run_scenario "S3 conforming silent" "$MEMDIR/conforming.md" "EMPTY" "0"

# ---------- Scenario S3b: conforming entry with all 3 optional fields ----------
cat >"$MEMDIR/conforming-all-fields.md" <<'EOF'
---
name: conforming-all-fields
description: optional fields populated; should still pass silently
metadata:
  type: project
  created_at: 2026-05-24T00:00:00Z
  last_accessed: 2026-05-24T12:00:00Z
  confirmed_count: 3
---
EOF
run_scenario "S3b conforming with optional" "$MEMDIR/conforming-all-fields.md" "EMPTY" "0"

# ---------- Scenario S4: missing required field 'description' ----------
cat >"$MEMDIR/missing-desc.md" <<'EOF'
---
name: missing-desc
metadata:
  type: project
---
EOF
run_scenario "S4 missing required (description)" "$MEMDIR/missing-desc.md" "memory-frontmatter-advisory:.*missing required field 'description'" "0"

# ---------- Scenario S4b: missing required field 'metadata.type' ----------
cat >"$MEMDIR/missing-type.md" <<'EOF'
---
name: missing-type
description: top-level fields fine but metadata.type absent
metadata:
  created_at: 2026-05-24T00:00:00Z
---
EOF
run_scenario "S4b missing required (metadata.type)" "$MEMDIR/missing-type.md" "memory-frontmatter-advisory:.*missing required field 'metadata\.type'" "0"

# ---------- Scenario S5: unknown field typo guard (top-level) ----------
cat >"$MEMDIR/unknown-top.md" <<'EOF'
---
name: unknown-top
description: has top-level typo
metdata:
  type: project
---
EOF
run_scenario "S5 unknown field (top-level typo)" "$MEMDIR/unknown-top.md" "memory-frontmatter-advisory:.*unknown field 'metdata'" "0"

# ---------- Scenario S5b: unknown field typo guard (nested) ----------
cat >"$MEMDIR/unknown-nested.md" <<'EOF'
---
name: unknown-nested
description: nested typo
metadata:
  type: project
  created_on: 2026-05-24
---
EOF
run_scenario "S5b unknown field (metadata.* typo)" "$MEMDIR/unknown-nested.md" "memory-frontmatter-advisory:.*unknown field 'metadata\.created_on'" "0"

# ---------- Scenario S6: malformed YAML (no closing ---) ----------
cat >"$MEMDIR/no-close.md" <<'EOF'
---
name: no-close
description: missing close
metadata:
  type: project
this body never closes the frontmatter
EOF
run_scenario "S6 malformed (no closing fence)" "$MEMDIR/no-close.md" "memory-frontmatter-advisory:.*frontmatter unparseable" "0"

# ---------- Scenario S7: no frontmatter block at all ----------
cat >"$MEMDIR/no-fm.md" <<'EOF'
# No frontmatter here

just a body.
EOF
run_scenario "S7 no frontmatter block" "$MEMDIR/no-fm.md" "memory-frontmatter-advisory:.*no frontmatter block" "0"

# ---------- Scenario S8: edit outside .claude/memory/ ignored ----------
cat >"$TMPDIR/.claude/rules/foo.md" <<'EOF'
# foo
EOF
run_scenario "S8 outside scope ignored (.claude/rules/)" "$TMPDIR/.claude/rules/foo.md" "EMPTY" "0"

cat >"$TMPDIR/random.md" <<'EOF'
# unrelated
EOF
run_scenario "S8b outside scope ignored (unrelated path)" "$TMPDIR/random.md" "EMPTY" "0"

# ---------- Scenario S9: MEMORY.md is skipped ----------
cat >"$MEMDIR/MEMORY.md" <<'EOF'
- some index entry
- another index entry
EOF
run_scenario "S9 MEMORY.md skipped" "$MEMDIR/MEMORY.md" "EMPTY" "0"

# ---------- Scenario S10: all 13 actual entries pass ----------
for f in "$REPO_ROOT"/.claude/memory/*.md; do
  bn="$(basename "$f")"
  [ "$bn" = "MEMORY.md" ] && continue
  run_scenario "S10 live entry: $bn" "$f" "EMPTY" "0" "$REPO_ROOT"
done

# ---------- Meta-assertion: every emitted advisory cites the schema authority (spec criterion #12) ----------
ADVISORY_LINES="$(printf '%s' "$ALL_STDERR" | grep '^memory-frontmatter-advisory:' || true)"
ADVISORY_COUNT="$(printf '%s\n' "$ADVISORY_LINES" | grep -c '^memory-frontmatter-advisory:' || true)"
CITATION_COUNT="$(printf '%s\n' "$ADVISORY_LINES" | grep -c 'memory-placement\.md.*Frontmatter schema' || true)"
echo
if [ "$ADVISORY_COUNT" -eq 0 ]; then
  echo "WARN [S12 citation]: no advisories were emitted across the suite — cannot verify citation"
elif [ "$ADVISORY_COUNT" = "$CITATION_COUNT" ]; then
  echo "PASS [S12 citation]: all $ADVISORY_COUNT advisories cite the schema section"
  PASS=$((PASS + 1))
else
  echo "FAIL [S12 citation]: $CITATION_COUNT of $ADVISORY_COUNT advisories cite the schema section"
  FAIL=$((FAIL + 1))
fi

echo
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
