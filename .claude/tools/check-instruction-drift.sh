#!/usr/bin/env bash
# Static drift checks for the multi-runtime instruction entrypoints.

set -euo pipefail

ROOT="$(pwd)"
AGENT0_PATH=""
SKIP_SYNC_CHECK=0

usage() {
  cat <<'EOF'
check-instruction-drift.sh — verify CLAUDE.md / AGENTS.md entrypoint invariants

Usage:
  check-instruction-drift.sh [--root PATH] [--agent0-path PATH] [--skip-sync-check]

Exit codes:
  0  all checks passed
  1  drift or invalid entrypoint state detected
  2  usage error
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --root=*) ROOT="${1#--root=}" ;;
    --root)
      shift
      ROOT="${1:-}"
      ;;
    --agent0-path=*) AGENT0_PATH="${1#--agent0-path=}" ;;
    --agent0-path)
      shift
      AGENT0_PATH="${1:-}"
      ;;
    --skip-sync-check) SKIP_SYNC_CHECK=1 ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'check-instruction-drift: unknown arg: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

ROOT="$(cd "$ROOT" && pwd)"
[ -n "$AGENT0_PATH" ] || AGENT0_PATH="$ROOT"
AGENT0_PATH="$(cd "$AGENT0_PATH" && pwd)"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="$ROOT/.claude/tools/lib/managed-block.sh"
if [ ! -f "$LIB" ]; then
  LIB="$SCRIPT_DIR/lib/managed-block.sh"
fi
if [ ! -f "$LIB" ]; then
  printf 'check-instruction-drift: missing managed-block helper library\n' >&2
  exit 2
fi
# shellcheck source=/dev/null
. "$LIB"

failures=0

ok() {
  printf 'ok: %s\n' "$1"
}

fail() {
  printf 'drift: %s\n' "$1" >&2
  failures=$((failures + 1))
}

claude="$ROOT/CLAUDE.md"
agents="$ROOT/AGENTS.md"

if [ -f "$claude" ] && [ -f "$agents" ]; then
  ok "both root entrypoints exist"
else
  [ -f "$claude" ] || fail "missing CLAUDE.md"
  [ -f "$agents" ] || fail "missing AGENTS.md"
fi

if [ -f "$claude" ]; then
  claude_state="$(detect_marker_state "$claude")"
  [ "$claude_state" = "paired" ] && ok "CLAUDE.md markers paired and ordered" || fail "CLAUDE.md marker state is $claude_state"
fi
if [ -f "$agents" ]; then
  agents_state="$(detect_marker_state "$agents")"
  [ "$agents_state" = "paired" ] && ok "AGENTS.md markers paired and ordered" || fail "AGENTS.md marker state is $agents_state"
fi

if [ -f "$claude" ] && [ -f "$agents" ] &&
   [ "$(detect_marker_state "$claude")" = "paired" ] &&
   [ "$(detect_marker_state "$agents")" = "paired" ]; then
  claude_sha="$(_region_sha "$(_extract_region "$claude")")"
  agents_sha="$(_region_sha "$(_extract_region "$agents")")"
  if [ "$claude_sha" = "$agents_sha" ]; then
    ok "managed blocks are byte-identical"
  else
    fail "managed blocks differ"
  fi
fi

check_claim_caveats() {
  local file="$1"
  local tier

  for tier in 'native-now' 'manual/read-only-now' 'Claude-only-until-follow-up'; do
    if ! grep -qF "$tier" "$file"; then
      fail "AGENTS.md missing tier qualifier: $tier"
    fi
  done
}

if [ -f "$agents" ] && [ "$(detect_marker_state "$agents")" = "paired" ]; then
  before_failures="$failures"
  check_claim_caveats "$agents"
  if [ "$failures" -eq "$before_failures" ]; then
    ok "AGENTS.md Claude-only claims are covered by file-level tier caveats"
  fi
fi

if [ "$SKIP_SYNC_CHECK" -eq 1 ]; then
  ok "sync-harness AGENTS.md baseline check skipped by flag"
else
  sync_tool="$ROOT/.claude/tools/sync-harness.sh"
  if [ ! -f "$sync_tool" ]; then
    fail "missing sync-harness.sh for AGENTS.md baseline check"
  else
    sync_exit=0
    sync_out="$(bash "$sync_tool" --check --agent0-path="$AGENT0_PATH" "$ROOT" 2>&1)" || sync_exit=$?
    if ! printf '%s\n' "$sync_out" | grep -q 'AGENTS.md'; then
      fail "sync-harness --check did not inspect AGENTS.md"
    elif printf '%s\n' "$sync_out" | grep -qE '(^!!|^~|would copy|would remove).*AGENTS\.md|AGENTS\.md.*(customized|stale)'; then
      fail "sync-harness reports AGENTS.md drift"
    else
      ok "sync-harness checks AGENTS.md on the baseline-tracked path"
    fi
    if [ "$sync_exit" -ne 0 ] && ! printf '%s\n' "$sync_out" | grep -q 'AGENTS.md'; then
      fail "sync-harness --check exited $sync_exit before AGENTS.md could be verified"
    fi
  fi
fi

if [ "$failures" -eq 0 ]; then
  exit 0
fi
exit 1
