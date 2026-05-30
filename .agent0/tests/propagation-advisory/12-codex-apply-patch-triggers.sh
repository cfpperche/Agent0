#!/usr/bin/env bash
# Scenario: a Codex `apply_patch` that adds a spec-NNN ref to a shipped path
# fires the propagation-advisory: spec-NNN line. Hook exits 0 regardless.
# Runtime-neutral parity with 01 (the Claude Edit equivalent) — spec 113.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
HOOK="$AGENT0_ROOT/.agent0/hooks/propagation-advise.sh"

TMPDIR_T="$(mktemp -d -t pa-12-XXXXXX)"
trap 'rm -rf "$TMPDIR_T"' EXIT
export CLAUDE_PROJECT_DIR="$TMPDIR_T"

# apply_patch body: `*** Add File:` (NEW file) on a shipped rule. Codex sends
# the patch body under `tool_input.command`; keep RAW new-file content here to
# guard the parser branch that tolerates no `+` prefix.
patch='*** Begin Patch
*** Add File: .claude/rules/foo.md
This refs spec 080 in newly added content.
*** End Patch'

payload="$(jq -n --arg p "$patch" \
  '{tool_name: "apply_patch", tool_input: {command: $p}}')"

# Codex ignores plain PostToolUse stdout; developer context must be JSON stdout
# with hookSpecificOutput.additionalContext.
out_capture="$(mktemp)"; err_capture="$(mktemp)"
exit_code=0
printf '%s' "$payload" | bash "$HOOK" >"$out_capture" 2>"$err_capture" || exit_code=$?

if [ "$exit_code" -ne 0 ]; then
  printf 'FAIL: hook exited %d (expected 0)\n' "$exit_code"
  cat "$err_capture"; rm -f "$out_capture" "$err_capture"; exit 1
fi

if ! jq -e '
  .hookSpecificOutput.hookEventName == "PostToolUse"
  and (.hookSpecificOutput.additionalContext | contains("propagation-advisory: spec-NNN"))
  and (.hookSpecificOutput.additionalContext | contains(".claude/rules/foo.md:1"))
' "$out_capture" >/dev/null 2>&1; then
  printf 'FAIL: missing propagation-advisory JSON additionalContext on Codex path\n'
  printf 'stdout was:\n'; cat "$out_capture"; printf 'stderr was:\n'; cat "$err_capture"
  rm -f "$out_capture" "$err_capture"; exit 1
fi

if [ -s "$err_capture" ]; then
  printf 'FAIL: Codex path wrote stderr (should use JSON stdout only)\n'
  cat "$err_capture"; rm -f "$out_capture" "$err_capture"; exit 1
fi

rm -f "$out_capture" "$err_capture"
echo "PASS: 12-codex-apply-patch-triggers"
