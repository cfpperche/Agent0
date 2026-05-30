#!/usr/bin/env bash
# Scenario: a Codex `apply_patch` *** Update File: hunk on a shipped path fires
# ONLY on the `+`-added line's leak — context (` `) and removed (`-`) lines that
# also contain leak patterns must NOT trigger (parity with Claude's new-content
# scan). Guards the unified-diff branch of the apply_patch parser — spec 113.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
HOOK="$AGENT0_ROOT/.agent0/hooks/propagation-advise.sh"

TMPDIR_T="$(mktemp -d -t pa-14-XXXXXX)"
trap 'rm -rf "$TMPDIR_T"' EXIT
export CLAUDE_PROJECT_DIR="$TMPDIR_T"

# Context line refs spec 011, removed line refs spec 022, added line refs spec 080.
# Only spec 080 (the added content) should surface.
patch='*** Begin Patch
*** Update File: .agent0/context/rules/foo.md
@@
 context line refs spec 011 here
-removed line refs spec 022 here
+added line refs spec 080 here
*** End Patch'

payload="$(jq -n --arg p "$patch" \
  '{tool_name: "apply_patch", tool_input: {command: $p}}')"

# Codex surfacing channel is JSON STDOUT additionalContext.
out_capture="$(mktemp)"
exit_code=0
printf '%s' "$payload" | bash "$HOOK" >"$out_capture" 2>/dev/null || exit_code=$?

if [ "$exit_code" -ne 0 ]; then
  printf 'FAIL: hook exited %d (expected 0)\n' "$exit_code"
  cat "$out_capture"; rm -f "$out_capture"; exit 1
fi

if ! jq -e '
  .hookSpecificOutput.hookEventName == "PostToolUse"
  and (.hookSpecificOutput.additionalContext | contains("spec 080"))
' "$out_capture" >/dev/null 2>&1; then
  printf 'FAIL: added-line leak (spec 080) not surfaced in JSON additionalContext\n'
  cat "$out_capture"; rm -f "$out_capture"; exit 1
fi

if jq -r '.hookSpecificOutput.additionalContext // empty' "$out_capture" | grep -qE "spec 011|spec 022"; then
  printf 'FAIL: context/removed line leak surfaced (should scan added lines only)\n'
  cat "$out_capture"; rm -f "$out_capture"; exit 1
fi

rm -f "$out_capture"
echo "PASS: 14-codex-update-hunk-added-only"
