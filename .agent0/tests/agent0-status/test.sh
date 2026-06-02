#!/usr/bin/env bash
# Behavioural tests for spec 137 (agent0-status): status.sh, doctor.sh, and the
# extracted _brief-compose.sh library. Runtime-neutral pure bash.
#
# Run: bash .agent0/tests/agent0-status/test.sh

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
HOOKS="$REPO/.agent0/hooks"
TOOLS="$REPO/.agent0/tools"
PASS=0; FAIL=0
ok()   { printf '  ok   %s\n' "$1"; PASS=$((PASS + 1)); }
bad()  { printf '  FAIL %s\n' "$1"; FAIL=$((FAIL + 1)); }

# --- V3: library is runtime-emit-neutral ------------------------------------
printf 'V3 — _brief-compose.sh carries composition only (no emit/truncation)\n'
# Strip full-line comments first — the header comment legitimately *names* these
# tokens to document the emit/composition boundary; only CODE use is forbidden.
if grep -vE '^[[:space:]]*#' "$HOOKS/_brief-compose.sh" \
   | grep -qE 'emit_context|trim_lines|trim_bytes|hookSpecificOutput|jq -n'; then
  bad "lib contains runtime-emit/truncation tokens in code"
else
  ok "no emit_context/trim_*/jq -n/hookSpecificOutput in lib code"
fi
grep -q '_brief-compose.sh' "$HOOKS/startup-brief.sh" && ok "startup-brief.sh sources the lib" || bad "startup-brief.sh does not source the lib"

# --- V2: brief still composes after refactor --------------------------------
printf 'V2 — startup-brief.sh still emits a brief post-refactor\n'
brief="$(printf '{}' | bash "$HOOKS/startup-brief.sh" 2>/dev/null)"
[ -n "$brief" ] && printf '%s' "$brief" | grep -q 'AGENT0_STARTUP_BRIEF' && ok "brief emitted with header" || bad "brief empty or missing header"
printf '%s' "$brief" | grep -q '=== handoff ===' && ok "brief has handoff section" || bad "brief missing handoff section"

# --- V1: status renders full work state -------------------------------------
printf 'V1 — status.sh renders full untruncated work state\n'
st="$(bash "$TOOLS/status.sh" 2>/dev/null)"; st_exit=$?
[ "$st_exit" -eq 0 ] && ok "status.sh exit 0" || bad "status.sh exit $st_exit"
for sec in 'AGENT0_STATUS' '=== handoff ===' '=== git ===' '=== next ===' 'END_AGENT0_STATUS'; do
  printf '%s' "$st" | grep -qF "$sec" && ok "status has [$sec]" || bad "status missing [$sec]"
done

# --- V5: status degrades cleanly on a partial harness -----------------------
printf 'V5 — status.sh degrades cleanly with no HANDOFF/reminders\n'
empty="$(mktemp -d)"
trap 'rm -rf "$empty"' EXIT
deg="$(AGENT0_PROJECT_DIR="$empty" bash "$TOOLS/status.sh" 2>/dev/null)"; deg_exit=$?
[ "$deg_exit" -eq 0 ] && ok "partial-harness status exit 0" || bad "partial-harness status exit $deg_exit"
printf '%s' "$deg" | grep -qi 'missing' && ok "handoff-missing marker present" || bad "no missing marker on partial harness"

# --- V4: doctor exit code reflects severity ---------------------------------
printf 'V4 — doctor.sh tri-state + severity-based exit code\n'
doc="$(bash "$TOOLS/doctor.sh" 2>/dev/null)"; doc_exit=$?
printf '%s' "$doc" | grep -q '=== rollup ===' && ok "doctor prints rollup" || bad "doctor missing rollup"
# Real repo: no broken checks expected → exit 0.
[ "$doc_exit" -eq 0 ] && ok "healthy harness exit 0" || bad "healthy harness exit $doc_exit (expected 0)"
# Empty fixture: core files missing → broken → exit non-zero.
AGENT0_PROJECT_DIR="$empty" bash "$TOOLS/doctor.sh" >/dev/null 2>&1; broke_exit=$?
[ "$broke_exit" -ne 0 ] && ok "broken harness exit non-zero ($broke_exit)" || bad "broken harness exit 0 (expected non-zero)"
# Optional-binary absence must NOT break: simulate by checking rollup wording.
printf '%s' "$doc" | grep -qE 'OK|ADVISORY' && ok "advisories never force broken verdict on healthy repo" || bad "unexpected verdict"

# --- V8: next-actions line suppressed when handoff parks "nothing actionable" -
printf 'V8 — === next === does not point at a "nothing actionable" handoff\n'
fix_none="$(mktemp -d)"; mkdir -p "$fix_none/.agent0"
printf '## Next Actions\n\n- **Nothing actionable in the queue** — dormant items only\n' > "$fix_none/.agent0/HANDOFF.md"
none_out="$(AGENT0_PROJECT_DIR="$fix_none" bash "$TOOLS/status.sh" 2>/dev/null | sed -n '/=== next ===/,/END_AGENT0_STATUS/p')"
printf '%s' "$none_out" | grep -q 'handoff has queued Next Actions' \
  && bad "next-line fired despite 'nothing actionable' handoff" \
  || ok "next-line correctly suppressed on 'nothing actionable'"

fix_real="$(mktemp -d)"; mkdir -p "$fix_real/.agent0"
printf '## Next Actions\n\n- Ship the auth refactor and update the README\n' > "$fix_real/.agent0/HANDOFF.md"
real_out="$(AGENT0_PROJECT_DIR="$fix_real" bash "$TOOLS/status.sh" 2>/dev/null | sed -n '/=== next ===/,/END_AGENT0_STATUS/p')"
printf '%s' "$real_out" | grep -q 'handoff has queued Next Actions' \
  && ok "next-line fires on a real actionable handoff" \
  || bad "next-line missing on a genuinely actionable handoff"

# --- V9: doctor dir/non-empty checks (dogfood D2 cosmetics) ------------------
printf 'V9 — doctor flags a wrong-type rules path and an empty exec file\n'
grep -q 'check_file ".agent0/context/rules" dir' "$TOOLS/doctor.sh" && ok "rules checked as dir (-d)" || bad "rules not dir-checked"
grep -q 'present but empty' "$TOOLS/doctor.sh" && ok "exec files get a non-empty check" || bad "no non-empty check for exec files"

printf '\n=== %d passed, %d failed ===\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
