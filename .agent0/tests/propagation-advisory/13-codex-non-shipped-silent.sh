#!/usr/bin/env bash
# Scenario: a Codex `apply_patch` that adds a spec-NNN ref to a NON-shipped path
# (e.g. docs/specs/, which never ships to consumers) stays silent. Hook exits 0.
# Runtime-neutral parity with 06 (the Claude non-shipped equivalent) — spec 113.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
HOOK="$AGENT0_ROOT/.agent0/hooks/propagation-advise.sh"

TMPDIR_T="$(mktemp -d -t pa-13-XXXXXX)"
trap 'rm -rf "$TMPDIR_T"' EXIT
export CLAUDE_PROJECT_DIR="$TMPDIR_T"

# Leak in a non-shipped path — docs/specs/ carries refs legitimately and must
# NOT trigger the advisory.
patch='*** Begin Patch
*** Update File: docs/specs/099-some-spec/spec.md
@@
+This refs spec 080 and /home/someone/secret here.
*** End Patch'

payload="$(jq -n --arg p "$patch" \
  '{tool_name: "apply_patch", tool_input: {command: $p}}')"

# Must be silent on BOTH channels (JSON/plain stdout = Codex, stderr = Claude).
both_capture="$(mktemp)"
exit_code=0
printf '%s' "$payload" | bash "$HOOK" >"$both_capture" 2>&1 || exit_code=$?

if [ "$exit_code" -ne 0 ]; then
  printf 'FAIL: hook exited %d (expected 0)\n' "$exit_code"
  cat "$both_capture"; rm -f "$both_capture"; exit 1
fi

if grep -q "propagation-advisory:" "$both_capture"; then
  printf 'FAIL: advisory fired on a non-shipped path (should be silent)\n'
  printf 'output was:\n'; cat "$both_capture"; rm -f "$both_capture"; exit 1
fi

rm -f "$both_capture"
echo "PASS: 13-codex-non-shipped-silent"
