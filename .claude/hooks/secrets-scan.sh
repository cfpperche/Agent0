#!/usr/bin/env bash
# .claude/hooks/secrets-scan.sh
# PreToolUse(Bash) hook — secrets-scan capacity (spec 006).
#
# Phases (fixed order):
#   1. Early-exit on CLAUDE_SKIP_SECRETS_SCAN=1 (silent, no audit).
#   2. Parse stdin JSON; short-circuit (exit 0, NO audit) unless the command
#      is a real `git commit` invocation.
#   3. Override marker — `^[[:space:]]*# OVERRIDE: <reason ≥10 chars>` on the
#      command string. Start-of-line anchored so prose that documents the
#      marker (mid-sentence "use # OVERRIDE: ...") is not treated as bypass.
#      Reason <10 chars after trim → block with explicit stderr.
#   4. Gitleaks invocation — `protect --staged --no-banner` at the repo root.
#      Binary missing → audit "skip-no-engine", warn once, exit 0 (fail open).
#   5. Decision + audit JSONL append (with flock atomicity).
#
# Decision values:
#   "block"           — findings present, no valid override → exit 2
#   "allow"           — no findings (or all allowlisted by gitleaks) → exit 0
#   "override"        — findings present + valid override marker → exit 0
#   "skip-no-engine"  — gitleaks not on PATH → exit 0 (fail open)
#
# Non-commit Bash events: silent short-circuit, NO audit line. The matcher in
# settings.json fires broadly (any command containing "git"); the precise
# filter lives here per plan § Risks (matcher granularity).
#
# Exit codes: 0 = allow, 2 = block.
# jq is a hard dependency; if missing, the hook fails open (exit 0) so a
# missing dependency cannot lock the agent out of the Bash tool.
#
# bash 3.2-compatible: no associative arrays, no mapfile, no `[[ =~ ]]`.

set -euo pipefail

# --- Phase 1: User-facing escape hatch ---
# Honoured as the very first non-comment line per spec 006 acceptance: a
# user who exports this var expects total silence, including no audit row.
if [ "${CLAUDE_SKIP_SECRETS_SCAN:-0}" = "1" ]; then
  exit 0
fi

INPUT="$(cat 2>/dev/null || true)"
[ -z "$INPUT" ] && exit 0

if ! command -v jq >/dev/null 2>&1; then
  # Fail open when jq is missing — same posture as the stub.
  exit 0
fi

COMMAND="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || true)"
SESSION_ID="$(printf '%s' "$INPUT" | jq -r '.session_id // ""' 2>/dev/null || true)"

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
AUDIT_LOG="$PROJECT_DIR/.claude/secrets-audit.jsonl"

# --- Phase 2: Command parsing (short-circuit for non-commit invocations) ---
#
# is_git_commit: returns 0 if the command string is a `git commit` shape.
# Cases handled by one regex:
#   - `git commit`                  (canonical)
#   - `git  commit`                 (double-space / extra whitespace)
#   - `git -C /path commit`         (working-dir override)
#   - `git --git-dir=... commit`    (other top-level options before subcommand)
#   - `git commit --amend`          (any trailing flags / args)
#   - `&& git commit`, `; git commit`, leading whitespace etc.
# NOT matched (intentional): `git-commit` (alias binary), `gitcommit`,
# strings that mention "git commit" inside quoted prose elsewhere in a
# pipeline — false-negative cost is one unscanned commit per pathological
# command shape; the more common false-positive cost is bounded to one
# extra gitleaks call (cheap). See plan § Risks: matcher granularity.
is_git_commit() {
  printf '%s' "$1" | grep -qE '(^|[^A-Za-z0-9_-])git([[:space:]]+-[^[:space:]]+([[:space:]]+[^[:space:]]+)?)*[[:space:]]+commit([[:space:]]|$)'
}

if [ -z "$COMMAND" ] || ! is_git_commit "$COMMAND"; then
  exit 0
fi

# From here on, we have a real `git commit` — every exit path appends one
# audit line.

mkdir -p "$(dirname "$AUDIT_LOG")" 2>/dev/null || exit 0

ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# --- Phase 3: Override marker ---
# Start-of-line anchor (with optional leading whitespace) so prose that
# *documents* the marker is not treated as a bypass. This mirrors the 002
# delegation-gate fix; do NOT use the unanchored shape from governance-gate.
override_reason=""
override_present=0
override_too_short=0

override_line="$(printf '%s' "$COMMAND" | grep -E '^[[:space:]]*# OVERRIDE: ' | head -1 | sed -e 's/^[[:space:]]*//' || true)"
if [ -n "$override_line" ]; then
  override_present=1
  reason="${override_line#'# OVERRIDE: '}"
  reason="$(printf '%s' "$reason" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  if [ ${#reason} -ge 10 ]; then
    override_reason="$reason"
  else
    override_too_short=1
    short_reason_seen="$reason"
  fi
fi

# Helper: append one JSONL audit line atomically (flock-guarded when available).
# Args: $1=decision, $2=finding_count, $3=override_reason_or_empty.
append_audit() {
  local decision="$1"
  local finding_count="$2"
  local reason="$3"

  local reason_json
  if [ -n "$reason" ]; then
    reason_json="$(printf '%s' "$reason" | jq -R -s -c 'rtrimstr("\n")')"
  else
    reason_json="null"
  fi

  local line
  line="$(jq -c -n \
    --arg ts "$ts" \
    --arg session_id "$SESSION_ID" \
    --arg decision "$decision" \
    --argjson finding_count "$finding_count" \
    --argjson override_reason "$reason_json" \
    '{ts:$ts, session_id:$session_id, decision:$decision, finding_count:$finding_count, override_reason:$override_reason}')"

  # Atomic append via flock when available; fall back to plain append otherwise.
  # Probe writability in a subshell before the bare `exec 9>...` redirect —
  # `exec 9>file 2>/dev/null` would permanently silence FD 2 for the rest of
  # the script (see .claude/rules/delegation.md § Gotchas).
  if command -v flock >/dev/null 2>&1; then
    local lock_path="$AUDIT_LOG.lock"
    ( : >>"$lock_path" ) 2>/dev/null || {
      printf '%s\n' "$line" >> "$AUDIT_LOG" 2>/dev/null || true
      return 0
    }
    exec 9>"$lock_path"
    flock 9
    printf '%s\n' "$line" >> "$AUDIT_LOG"
    flock -u 9
    exec 9>&-
  else
    printf '%s\n' "$line" >> "$AUDIT_LOG" 2>/dev/null || true
  fi
}

# Short-reason override path: block with explicit stderr (override marker is
# present but unusable). Audit as "block" with finding_count 0 — we have not
# yet run the scan, but the user's intent was to override, and the marker
# failed validation. finding_count 0 reflects "not scanned"; the
# override_reason field captures the rejected string for audit transparency.
if [ "$override_too_short" -eq 1 ]; then
  cat >&2 <<EOF
secrets-scan: override reason must be ≥10 characters, got "$short_reason_seen"
Spec: docs/specs/006-secrets-scan/spec.md (Scenario 3)
EOF
  append_audit "block" 0 "$short_reason_seen"
  exit 2
fi

# --- Phase 4: Gitleaks invocation ---
if ! command -v gitleaks >/dev/null 2>&1; then
  printf '%s\n' "secrets-scan: gitleaks not found, scan skipped" >&2
  append_audit "skip-no-engine" 0 ""
  exit 0
fi

# Resolve repo root for the gitleaks invocation. If we are not inside a git
# tree at all, there is nothing to scan — fall through as "allow".
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$REPO_ROOT" ]; then
  append_audit "allow" 0 ""
  exit 0
fi

GITLEAKS_REPORT="$(mktemp -t gitleaks-XXXXXX.json 2>/dev/null || mktemp)"
# Capture stdout+stderr for surfacing to the agent on parse failure.
GITLEAKS_OUT="$(mktemp -t gitleaks-out-XXXXXX 2>/dev/null || mktemp)"

# Run gitleaks; do NOT exit on non-zero (gitleaks returns 1 when findings are
# present, which is our success path).
set +e
( cd "$REPO_ROOT" && gitleaks protect --staged --no-banner \
    --report-format=json --report-path="$GITLEAKS_REPORT" ) >"$GITLEAKS_OUT" 2>&1
gitleaks_exit=$?
set -e

# Defensive JSON parse. gitleaks v8 writes an array (possibly empty) on
# success/finding; parse defensively per plan § Risks (JSON output stability).
finding_count=0
if [ -s "$GITLEAKS_REPORT" ]; then
  # Use the type-checked accessor so an unexpected shape does not silently
  # become 0 — distinguishes "valid empty array" from "broken parser".
  finding_count="$(jq 'if type == "array" then length else -1 end' "$GITLEAKS_REPORT" 2>/dev/null || printf '%s' '-1')"
fi

if [ "$finding_count" = "-1" ] || ! printf '%s' "$finding_count" | grep -qE '^[0-9]+$'; then
  # Surface raw gitleaks output to the agent so they see what happened,
  # then audit as allow + exit 0 (fail open on unparseable report — same
  # posture as the missing-binary path).
  cat >&2 <<EOF
secrets-scan: failed to parse gitleaks JSON output (exit=$gitleaks_exit).
Raw gitleaks output:
$(cat "$GITLEAKS_OUT" 2>/dev/null || true)
EOF
  rm -f "$GITLEAKS_REPORT" "$GITLEAKS_OUT" 2>/dev/null || true
  append_audit "allow" 0 ""
  exit 0
fi

# --- Phase 5: Decision ---
if [ "$finding_count" -eq 0 ]; then
  rm -f "$GITLEAKS_REPORT" "$GITLEAKS_OUT" 2>/dev/null || true
  append_audit "allow" 0 ""
  exit 0
fi

# Findings present.
if [ -n "$override_reason" ]; then
  # Override path: scan + audit still run, but block is suppressed.
  # Stderr stays quiet on the allow path; the audit log captures the reason.
  rm -f "$GITLEAKS_REPORT" "$GITLEAKS_OUT" 2>/dev/null || true
  append_audit "override" "$finding_count" "$override_reason"
  exit 0
fi

# Block path: list each finding's Description + File:StartLine on stderr.
findings_summary="$(jq -r '.[] | "  - \(.Description // .RuleID // "secret") at \(.File // "<unknown>"):\(.StartLine // 0)"' "$GITLEAKS_REPORT" 2>/dev/null || true)"

cat >&2 <<EOF
secrets-scan: blocked — $finding_count finding(s) detected in staged diff.

$findings_summary

To bypass for a legitimate fixture or test, append a comment to the commit
command (note: shell strips comments before git sees them, but the hook
parses the raw tool_input.command string):

  git commit -m "..." # OVERRIDE: <reason ≥10 chars explaining why>

Or, for path/regex/commit-scoped exemptions, edit .gitleaks.toml. Inline
suppression: append a "# gitleaks:allow" comment on the same line as the
match. See .claude/rules/secrets-scan.md (when present) and
docs/specs/006-secrets-scan/spec.md for the full discipline.
EOF

rm -f "$GITLEAKS_REPORT" "$GITLEAKS_OUT" 2>/dev/null || true
append_audit "block" "$finding_count" ""
exit 2
