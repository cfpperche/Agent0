#!/usr/bin/env bash
# run: emits a per-command audit line; denies sensitive without confirm.
source "$(dirname "$0")/_lib.sh"
echo "04-audit"

FAKE="$(fake_bin)"
export AGENT0_BROWSER_BIN="$FAKE" AB_CALLS_LOG="$WORK/ab-calls.log"

# allowed read-only ⇒ audited + passthrough executed
bash "$TOOL" run -- snapshot >/dev/null 2>&1; RC=$?
assert_rc "$RC" 0 "allowed read-only run rc 0"
AUDIT="$(bash "$TOOL" audit-tail 50)"
assert_contains "$AUDIT" '"action":"snapshot"' "snapshot audited"
assert_contains "$AUDIT" '"decision":"allow"' "allow decision recorded"
assert_contains "$(cat "$AB_CALLS_LOG" 2>/dev/null)" "snapshot" "passthrough reached the binary"

# denied sensitive ⇒ audited as deny, NOT executed, rc 2
: > "$AB_CALLS_LOG"
bash "$TOOL" run -- eval "alert(1)" >/dev/null 2>&1; RC=$?
assert_rc "$RC" 2 "denied sensitive run rc 2"
AUDIT="$(bash "$TOOL" audit-tail 50)"
assert_contains "$AUDIT" '"action":"eval"' "eval attempt audited"
assert_contains "$AUDIT" '"decision":"deny"' "deny decision recorded"
assert_eq "$(grep -c eval "$AB_CALLS_LOG" 2>/dev/null)" "0" "denied action NOT passed to the binary"

# fallback route ⇒ run refuses with rc 4 (points at MCP)
OUT="$(AGENT0_BROWSER_BIN=/nonexistent/agent-browser bash "$TOOL" run -- snapshot 2>&1)"; RC=$?
assert_rc "$RC" 4 "no-binary run rc 4 (fallback)"
assert_contains "$OUT" "fallback" "refusal names the fallback path"

finish
