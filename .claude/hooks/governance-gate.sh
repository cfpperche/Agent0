#!/usr/bin/env bash
# .claude/hooks/governance-gate.sh
# PreToolUse(Bash) hook enforcing a project-wide safety floor.
#
# Blocks three pattern families:
#   1. Destructive ops    — rm -rf (combined-flag variants), git push --force / -f, git reset --hard
#   2. Hook bypass        — git commit --no-verify, git push --no-verify
#   3. Blanket staging    — git add -A/--all/./*, git commit -a/-am/-ma/--all
#
# Override: append `# OVERRIDE: <reason>` to the command, where the reason
# (whitespace-trimmed) is >= 10 characters. Case-sensitive marker.
#
# Exit codes: 0 = allow, 2 = block (Claude Code re-prompts the agent with stderr).
# jq is a hard dependency; if missing, the hook fails closed (exit 2).
#
# bash 3.2-compatible: no associative arrays, no mapfile.

set -uo pipefail

INPUT="$(cat 2>/dev/null || true)"
[ -z "$INPUT" ] && exit 0

# --- Pre-jq fast-path probe (see .claude/memory/hook-chain-latency.md) ---
# 99% of Bash commands carry none of this gate's trigger keywords. Checking the
# raw JSON for any of the trigger fragments before paying for `jq` short-circuits
# the no-op path. The probe is SUFFICIENT-BUT-NOT-NECESSARY: a probe-miss falls
# through to the existing jq + full-regex path (false negative is safe), a
# probe-hit pays for full parse (false positive is harmless — just slower).
# Patterns mirror Family 1-3 below at the keyword level only.
# Required tokens: `rm -[rf]`, `--force`/`-f` (push), `--no-verify`, `--hard`,
# `-A`/`--all`/'\./'\*` (add), `-a`/`--all` (commit). `OVERRIDE` is included so
# the marker check still runs even if the actual destructive pattern isn't in
# this raw string (defense-in-depth — the override is only meaningful when a
# pattern DOES match, but its presence is a signal worth honoring).
if ! printf '%s' "$INPUT" \
    | grep -qE 'rm[[:space:]]+-|--force|--no-verify|--hard|add[[:space:]]+(-A|--all|\\\.|\\\*|\.|\*)|commit[[:space:]]+-[a-zA-Z]*a|commit[[:space:]]+--all|push[[:space:]]+[^"|]*-[a-zA-Z]*f|OVERRIDE'; then
  exit 0
fi

if ! CMD="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""')"; then
  cat >&2 <<'EOF'
governance-gate: failed to parse PreToolUse JSON (jq missing or malformed input).
Failing closed (exit 2) — install jq to restore Bash tool usage.
EOF
  exit 2
fi

[ -z "$CMD" ] && exit 0

# --- Override check: literal `# OVERRIDE: <reason ≥10 chars after trim>` ---
override_line="$(printf '%s' "$CMD" | grep -oE '# OVERRIDE: .*' | head -1 || true)"
if [ -n "$override_line" ]; then
  reason="${override_line#'# OVERRIDE: '}"
  reason="$(printf '%s' "$reason" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  if [ ${#reason} -ge 10 ]; then
    exit 0
  fi
fi

# --- Pattern families (first match wins) ---
family=""
trigger=""

# Family 1: Destructive ops
if printf '%s' "$CMD" | grep -qE '\brm[[:space:]]+-([a-zA-Z]*[rR][a-zA-Z]*[fF]|[a-zA-Z]*[fF][a-zA-Z]*[rR])[a-zA-Z]*([[:space:]]|$)'; then
  family="destructive"
  trigger="rm with combined -r/-R and -f/-F flags"
elif printf '%s' "$CMD" | grep -qE '\bgit[[:space:]]+([^[:space:];|&]+[[:space:]]+)*push\b[^|;&]*--force([[:space:]]|$)'; then
  family="destructive"
  trigger="git push --force"
elif printf '%s' "$CMD" | grep -qE '\bgit[[:space:]]+([^[:space:];|&]+[[:space:]]+)*push\b[^|;&]*[[:space:]]-[a-zA-Z]*f[a-zA-Z]*([[:space:]]|$)'; then
  family="destructive"
  trigger="git push -f"
elif printf '%s' "$CMD" | grep -qE '\bgit[[:space:]]+([^[:space:];|&]+[[:space:]]+)*reset[[:space:]]+--hard([[:space:]]|$)'; then
  family="destructive"
  trigger="git reset --hard"

# Family 2: Hook bypass (meta-defense)
elif printf '%s' "$CMD" | grep -qE '\bgit[[:space:]]+([^[:space:];|&]+[[:space:]]+)*commit\b[^|;&]*--no-verify([[:space:]]|$)'; then
  family="no-verify"
  trigger="git commit --no-verify"
elif printf '%s' "$CMD" | grep -qE '\bgit[[:space:]]+([^[:space:];|&]+[[:space:]]+)*push\b[^|;&]*--no-verify([[:space:]]|$)'; then
  family="no-verify"
  trigger="git push --no-verify"

# Family 3: Blanket staging
elif printf '%s' "$CMD" | grep -qE '\bgit[[:space:]]+([^[:space:];|&]+[[:space:]]+)*add[[:space:]]+(-A|--all|\.|\*)([[:space:]]|$)'; then
  family="blanket-staging"
  trigger="git add -A / --all / . / *"
elif printf '%s' "$CMD" | grep -qE '\bgit[[:space:]]+([^[:space:];|&]+[[:space:]]+)*commit[[:space:]]+(-[a-zA-Z]*a[a-zA-Z]*|--all)([[:space:]]|$)'; then
  family="blanket-staging"
  trigger="git commit -a / -am / -ma / --all"
fi

[ -z "$family" ] && exit 0

cat >&2 <<EOF
governance-gate: blocked [$family]

Triggered: $trigger
Command:   $CMD

This project enforces a safety floor against destructive operations, hook
bypass, and blanket staging. If you have a real reason to run this command,
append an inline override marker (>= 10 chars of reason after 'OVERRIDE:'):

  <your command>  # OVERRIDE: <why, >= 10 chars>

Marker is case-sensitive: '# OVERRIDE: ' (uppercase, colon, space).
EOF

exit 2
