#!/usr/bin/env bash
# Spec 163: a tool whose kit lib is absent fails CLEARLY (exit 70), not cryptically.
set -uo pipefail
AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
TMP="$(mktemp -d -t cap-missingkit-XXXXXX)"; trap 'rm -rf "$TMP"' EXIT
cp "$AGENT0_ROOT/.agent0/tools/diagram.sh" "$TMP/diagram.sh"   # copy tool WITHOUT lib/
PASS=0; FAIL=0
out="$(bash "$TMP/diagram.sh" caps 2>&1)"; rc=$?
if [ "$rc" = 70 ] && printf '%s' "$out" | grep -q "missing kit library"; then
  PASS=$((PASS+1)); echo "  ✓ missing kit → exit 70 + clear message"
else
  FAIL=$((FAIL+1)); echo "  ✗ missing kit guard (rc=$rc: $out)"
fi
echo "  -- $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && echo "=== missing-kit-guard: PASS ===" || { echo "=== missing-kit-guard: FAIL ==="; exit 1; }
