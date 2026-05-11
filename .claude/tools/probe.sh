#!/usr/bin/env bash
# .claude/tools/probe.sh
# Shell tool for the runtime-introspect capacity (spec 011). Lets the agent
# query the latest captured test/build/typecheck run via a structured
# plain-text summary.
#
# Subcommands (v1):
#   last-run  — read .claude/.runtime-state/last-run.json and emit a
#               PASS/FAIL/UNKNOWN status header, age in seconds, stale
#               flag (vs session-start), and stdout/stderr tails.
#
# Exit codes:
#   0  — normal: snapshot found (any status), or no-snapshot empty state
#   2  — unknown subcommand (with usage hint on stderr)
#
# Reference:
#   .claude/rules/runtime-introspect.md  — full discipline
#   docs/specs/011-runtime-introspect/   — spec

set -uo pipefail

usage() {
  cat <<'EOF' >&2
Usage: bash .claude/tools/probe.sh <subcommand>

Subcommands:
  last-run    Show the latest captured test/build/typecheck run.

Examples:
  bash .claude/tools/probe.sh last-run
EOF
}

SUBCMD="${1:-}"

if [ -z "$SUBCMD" ]; then
  usage
  exit 2
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
STATE_FILE="$PROJECT_DIR/.claude/.runtime-state/last-run.json"
SESSION_MARK="$PROJECT_DIR/.claude/.session-state/started-at"

case "$SUBCMD" in
  last-run)
    if ! command -v jq >/dev/null 2>&1; then
      printf 'probe: jq not found — runtime-introspect probe disabled\n'
      exit 0
    fi

    if [ ! -f "$STATE_FILE" ]; then
      cat <<'EOF'
status: no-snapshot
hint: run a recognised verifier (e.g. `bun test`, `pytest`) then re-query with `bash .claude/tools/probe.sh last-run`.
EOF
      exit 0
    fi

    if ! jq -e . "$STATE_FILE" >/dev/null 2>&1; then
      printf 'status: parse-error\nhint: %s is not valid JSON — capacity may be wedged.\n' "$STATE_FILE"
      exit 0
    fi

    command="$(jq -r '.command // ""' "$STATE_FILE")"
    detector="$(jq -r '.detector // ""' "$STATE_FILE")"
    exit_val="$(jq -r '.exit // "null"' "$STATE_FILE")"
    started_at="$(jq -r '.started_at // ""' "$STATE_FILE")"
    duration_ms="$(jq -r '.duration_ms // "null"' "$STATE_FILE")"
    stdout_head="$(jq -r '.stdout_head // ""' "$STATE_FILE")"
    stdout_tail="$(jq -r '.stdout_tail // ""' "$STATE_FILE")"
    stdout_truncated="$(jq -r '.stdout_truncated // false' "$STATE_FILE")"
    stderr_head="$(jq -r '.stderr_head // ""' "$STATE_FILE")"
    stderr_tail="$(jq -r '.stderr_tail // ""' "$STATE_FILE")"
    stderr_truncated="$(jq -r '.stderr_truncated // false' "$STATE_FILE")"

    # Status mapping
    case "$exit_val" in
      0)      status="PASS" ;;
      null|'') status="UNKNOWN" ;;
      *)      status="FAIL" ;;
    esac

    # Age computation
    age="?"
    if [ -n "$started_at" ]; then
      start_epoch="$(date -u -d "$started_at" +%s 2>/dev/null || date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$started_at" +%s 2>/dev/null || true)"
      now_epoch="$(date -u +%s 2>/dev/null || true)"
      if [ -n "$start_epoch" ] && [ -n "$now_epoch" ]; then
        age="$((now_epoch - start_epoch))s"
      fi
    fi

    # Stale comparison
    stale="false"
    if [ -f "$SESSION_MARK" ]; then
      # session-mark mtime vs snapshot started_at
      session_epoch="$(date -u -r "$SESSION_MARK" +%s 2>/dev/null || stat -c '%Y' "$SESSION_MARK" 2>/dev/null || true)"
      if [ -n "$session_epoch" ] && [ -n "${start_epoch:-}" ]; then
        if [ "$start_epoch" -lt "$session_epoch" ]; then
          stale="true"
        fi
      fi
    fi

    # Emit header
    printf 'status: %s\n' "$status"
    printf 'command: %s\n' "$command"
    printf 'detector: %s\n' "$detector"
    printf 'exit: %s\n' "$exit_val"
    printf 'age: %s\n' "$age"
    if [ "$duration_ms" != "null" ]; then
      printf 'duration_ms: %s\n' "$duration_ms"
    fi
    printf 'stale: %s\n' "$stale"
    printf '\n'

    # stdout block
    printf -- '--- stdout (head) ---\n'
    if [ -z "$stdout_head" ]; then
      printf '(empty)\n'
    else
      printf '%s\n' "$stdout_head"
    fi
    if [ "$stdout_truncated" = "true" ]; then
      printf -- '--- stdout (tail) ---\n'
      printf '%s\n' "$stdout_tail"
    fi

    # stderr block
    printf '\n--- stderr ---\n'
    if [ -z "$stderr_head" ] && [ -z "$stderr_tail" ]; then
      printf '(empty)\n'
    else
      printf '%s\n' "$stderr_head"
      if [ "$stderr_truncated" = "true" ]; then
        printf -- '--- stderr (tail) ---\n'
        printf '%s\n' "$stderr_tail"
      fi
    fi

    exit 0
    ;;

  *)
    printf 'probe: unknown subcommand "%s"\n\n' "$SUBCMD" >&2
    usage
    exit 2
    ;;
esac
