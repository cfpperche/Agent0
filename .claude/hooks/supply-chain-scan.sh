#!/usr/bin/env bash
# .claude/hooks/supply-chain-scan.sh
# PreToolUse(Bash) hook — supply-chain dep-install advisory + audit (spec 008).
#
# Detects dep-mutating Bash commands across 10 package managers (npm, pnpm,
# yarn, bun, pip, uv, poetry, pdm, cargo, go), audits them, and emits a soft
# stderr advisory line. Honors the `# OVERRIDE: <reason ≥10 chars>` marker
# (start-of-line anchored, same shape as .claude/hooks/secrets-scan.sh) to
# record intent. ADVISORY-ONLY — never blocks (no exit 2). Future blocking
# behaviour would be a separate spec.
#
# Decision values:
#   "skip-not-install"  — command is not a recognised dep-install shape; audited
#                         for forensic completeness (mirrors secrets-scan's
#                         skip-not-commit row-per-bash discipline)
#   "advisory"          — dep-install detected, no valid override; one stderr
#                         line `supply-chain-advisory: <manager> <action> — <pkgs>`
#   "advisory-override" — dep-install detected + valid override marker;
#                         no stderr, override_reason populated in audit row
#
# Override grammar: line matching `^[[:space:]]*# OVERRIDE: <reason>` in the
# raw command string, reason ≥10 chars after trim. Start-of-line anchored;
# inline trailing markers are NOT accepted (matches secrets-scan precedent;
# see .claude/rules/secrets-scan.md § Override grammar for the regression that
# the anchor closes). Short reasons silently degrade to plain advisory.
#
# Escape hatch: CLAUDE_SKIP_SUPPLY_CHAIN_SCAN=1 exits 0 silently — no audit.
#
# Reference:
#   .claude/rules/supply-chain.md      — full discipline
#   .claude/hooks/secrets-scan.sh      — sibling preflight (primitives reused)
#   docs/specs/008-supply-chain-scan/  — design memory
#
# Exit codes: 0 always. Hook never blocks (advisory-only).
# jq is a hard dependency; if missing the hook fails open (exit 0).
# bash 3.2-compatible: no associative arrays, no mapfile, no `[[ =~ ]]`.
# set -uo pipefail (NOT set -euo pipefail): `-e` would abort on intentional
# non-zero returns from grep (no match → exit 1).

set -uo pipefail

# ---------------------------------------------------------------------------
# Phase 1: User-facing escape hatch
# ---------------------------------------------------------------------------
if [ "${CLAUDE_SKIP_SUPPLY_CHAIN_SCAN:-0}" = "1" ]; then
  exit 0
fi

# ---------------------------------------------------------------------------
# Stdin capture + jq availability
# ---------------------------------------------------------------------------
INPUT="$(cat 2>/dev/null || true)"
[ -z "$INPUT" ] && exit 0

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

COMMAND="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || true)"
SESSION_ID="$(printf '%s' "$INPUT" | jq -r '.session_id // ""' 2>/dev/null || true)"
AGENT_ID="$(printf '%s' "$INPUT" | jq -r '.agent_id // ""' 2>/dev/null || true)"

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
AUDIT_LOG="$PROJECT_DIR/.claude/supply-chain-audit.jsonl"

mkdir -p "$(dirname "$AUDIT_LOG")" 2>/dev/null || exit 0
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Empty command → no audit, exit 0
[ -z "$COMMAND" ] && exit 0

# ---------------------------------------------------------------------------
# Audit helper
# ---------------------------------------------------------------------------
# append_audit decision [manager] [action] [packages_json] [override_reason]
# packages_json must be a pre-encoded JSON value (array string or the literal
# "null"). manager/action/override_reason are bare strings (encoded inline).
append_audit() {
  local decision="$1"
  local manager="${2:-}"
  local action="${3:-}"
  local packages_json="${4:-null}"
  local override_reason="${5:-}"

  local session_id_json agent_id_json manager_json action_json override_reason_json

  if [ -n "$SESSION_ID" ]; then
    session_id_json="$(printf '%s' "$SESSION_ID" | jq -R -s -c 'rtrimstr("\n")')"
  else
    session_id_json="null"
  fi

  if [ -n "$AGENT_ID" ]; then
    agent_id_json="$(printf '%s' "$AGENT_ID" | jq -R -s -c 'rtrimstr("\n")')"
  else
    agent_id_json="null"
  fi

  if [ -n "$manager" ]; then
    manager_json="$(printf '%s' "$manager" | jq -R -s -c 'rtrimstr("\n")')"
  else
    manager_json="null"
  fi

  if [ -n "$action" ]; then
    action_json="$(printf '%s' "$action" | jq -R -s -c 'rtrimstr("\n")')"
  else
    action_json="null"
  fi

  if [ -n "$override_reason" ]; then
    override_reason_json="$(printf '%s' "$override_reason" | jq -R -s -c 'rtrimstr("\n")')"
  else
    override_reason_json="null"
  fi

  local line
  line="$(jq -c -n \
    --arg ts "$ts" \
    --argjson session_id "$session_id_json" \
    --argjson agent_id "$agent_id_json" \
    --arg decision "$decision" \
    --arg scope "bash" \
    --argjson manager "$manager_json" \
    --argjson action "$action_json" \
    --argjson packages "$packages_json" \
    --argjson override_reason "$override_reason_json" \
    '{ts:$ts, session_id:$session_id, agent_id:$agent_id, decision:$decision, scope:$scope, manager:$manager, action:$action, packages:$packages, override_reason:$override_reason}')"

  # Atomic append via flock; probe writability in a subshell first to avoid
  # the sticky `exec 9>file 2>/dev/null` trap (silences all stderr).
  # See .claude/rules/delegation.md § Gotchas.
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

# ---------------------------------------------------------------------------
# Phase 3: Override marker parsing
# ---------------------------------------------------------------------------
# Same regex as secrets-scan.sh: `^[[:space:]]*# OVERRIDE: <reason>` anchored
# at start-of-line. Reason must be ≥10 chars after trim. Short reasons are
# silently dropped (no stderr — supply-chain is advisory-only, not blocking,
# so the "corrective template" pattern from secrets-scan doesn't apply here).
override_reason=""
override_valid=0

override_line="$(printf '%s' "$COMMAND" | grep -E '^[[:space:]]*# OVERRIDE: ' | head -1 | sed -e 's/^[[:space:]]*//' 2>/dev/null || true)"

if [ -n "$override_line" ]; then
  reason="${override_line#'# OVERRIDE: '}"
  reason="$(printf '%s' "$reason" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  if [ "${#reason}" -ge 10 ]; then
    override_reason="$reason"
    override_valid=1
  fi
  # Otherwise: marker silently dropped; advisory path fires below.
fi

# ---------------------------------------------------------------------------
# Phase 4: Tokenize the command and detect manager+verb+packages
# ---------------------------------------------------------------------------
# We tokenize via default word splitting (whitespace + newlines). This means
# tokens from a multi-line command (with override marker on line 2) all flow
# into one stream — the `#` token starting line 2 acts as a terminator in
# the package-collection loop below.
#
# Manager set + verb whitelist per manager:
#   npm    install i add update upgrade
#   pnpm   install i add update up
#   yarn   add                                 (yarn install is no-arg resolve)
#   bun    install i add update
#   pip    install
#   uv     add
#   poetry add
#   pdm    add
#   cargo  add update
#   go     get
#
# Loop walks tokens, looks for (manager, verb) pair, then collects subsequent
# non-flag-non-separator tokens as packages.

detected_manager=""
detected_action=""
detected_packages=""

# shellcheck disable=SC2206  # intentional word-splitting on COMMAND
tokens=( $COMMAND )
n=${#tokens[@]}

i=0
while [ "$i" -lt "$((n - 1))" ]; do
  current="${tokens[$i]}"
  next="${tokens[$((i + 1))]}"

  verbs=""
  case "$current" in
    npm)    verbs="install i add update upgrade" ;;
    pnpm)   verbs="install i add update up" ;;
    yarn)   verbs="add" ;;
    bun)    verbs="install i add update" ;;
    pip)    verbs="install" ;;
    uv)     verbs="add" ;;
    poetry) verbs="add" ;;
    pdm)    verbs="add" ;;
    cargo)  verbs="add update" ;;
    go)     verbs="get" ;;
    *)      i=$((i + 1)); continue ;;
  esac

  # Is `next` one of this manager's verbs?
  verb_match=""
  for v in $verbs; do
    if [ "$next" = "$v" ]; then
      verb_match="$v"
      break
    fi
  done

  if [ -z "$verb_match" ]; then
    i=$((i + 1))
    continue
  fi

  # Found a manager+verb pair. Collect packages from tokens[i+2..].
  # Stop at any shell separator (chain / pipe / redirect / background) or
  # comment start. Skip BOTH a known value-taking flag and its value (so
  # `--directory /path` doesn't leak the path into packages). `-r` and
  # `--package` are deliberately NOT on the value-taking list — their values
  # carry the supply-chain signal (requirements file, package name).
  j=$((i + 2))
  pkgs=""
  while [ "$j" -lt "$n" ]; do
    tok="${tokens[$j]}"
    case "$tok" in
      '&&'|'||'|';'|'|'|'>'|'>>'|'<'|'&'|'2>&1'|'2>'|'&>')
                      break ;;
      '#'*)           break ;;
      --directory|--dir|--target|--target-dir|--prefix|--manifest-path|--project|--cwd|--workspace|--config|-c|--filter|--registry|--index|--index-url)
                      j=$((j + 2)); continue ;;
      -*)             j=$((j + 1)); continue ;;
      *)              pkgs="$pkgs $tok"; j=$((j + 1)) ;;
    esac
  done
  pkgs="${pkgs# }"  # trim leading space

  if [ -n "$pkgs" ]; then
    detected_manager="$current"
    detected_action="$verb_match"
    detected_packages="$pkgs"
    break
  fi

  # Manager+verb matched but no packages collected (e.g. `npm install` alone,
  # or `pip install --help`). Treat as not-a-mutation and keep scanning in
  # case the command chains another install later.
  i=$((i + 1))
done

# ---------------------------------------------------------------------------
# Phase 5: Decision
# ---------------------------------------------------------------------------
if [ -z "$detected_manager" ]; then
  # No install pattern matched → skip-not-install audit + silent exit.
  append_audit "skip-not-install"
  exit 0
fi

# Build packages JSON array from space-separated string.
# shellcheck disable=SC2086  # intentional word splitting
packages_json="$(printf '%s\n' $detected_packages | jq -R . | jq -s -c .)"

if [ "$override_valid" -eq 1 ]; then
  # Valid override marker — record reason, no stderr.
  append_audit "advisory-override" "$detected_manager" "$detected_action" "$packages_json" "$override_reason"
  exit 0
fi

# No valid override — emit stderr advisory and audit `advisory`.
packages_display="$(printf '%s' "$packages_json" | jq -r 'join(", ")')"
printf 'supply-chain-advisory: %s %s — %s\n' "$detected_manager" "$detected_action" "$packages_display" >&2
append_audit "advisory" "$detected_manager" "$detected_action" "$packages_json" ""
exit 0
