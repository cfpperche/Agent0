#!/usr/bin/env bash
# .claude/hooks/runtime-capture.sh
# PostToolUse(Bash) hook — capture last test/build/typecheck run (spec 011).
#
# Tokenises tool_input.command, matches against the v1 detector pair list
# plus CLAUDE_RUNTIME_INTROSPECT_EXTRA_DETECT globs, and on a match writes
# .claude/.runtime-state/last-run.json atomically (mktemp + mv). Non-matches
# exit silently with no state write. Always exits 0 — capture failure is
# invisible to the underlying Bash; one diagnostic line goes to stderr only
# when CLAUDE_RUNTIME_INTROSPECT_DEBUG=1.
#
# Tokeniser TWIN: shares pattern with .claude/hooks/supply-chain-scan.sh's
# package-collection loop — same chain/pipe/redirect terminators and
# value-taking flag skip. See .claude/rules/runtime-introspect.md § Gotchas
# ("Tokeniser drift with supply-chain-scan").
#
# Detector pair list (v1):
#   bun test                        → bun-test
#   bun tsc                         → bun-tsc
#   bun run <script-with-keyword>   → bun-run        (test|build|typecheck|lint substring)
#   npm test                        → npm-test
#   npm run <script-with-keyword>   → npm-run
#   pnpm test                       → pnpm-test
#   pnpm run <script-with-keyword>  → pnpm-run
#   yarn test|build|typecheck|lint  → yarn-<verb>
#   pytest                          → pytest
#   python|python3 -m pytest        → python-pytest
#   python|python3 -m unittest      → python-unittest
#
# Extension: CLAUDE_RUNTIME_INTROSPECT_EXTRA_DETECT="<space-separated keys>"
#   where each key has the hyphen-joined `<tool>-<verb>` shape (e.g. make-test,
#   just-check). The resulting detector field is prefixed `extra:<key>` so
#   forensic queries can distinguish core vs extension matches.
#
# Reference:
#   .claude/rules/runtime-introspect.md       — full discipline
#   .claude/hooks/supply-chain-scan.sh        — tokeniser-twin (keep in sync)
#   .claude/hooks/secrets-scan.sh             — fail-open patterns
#   docs/specs/011-runtime-introspect/        — spec

set -uo pipefail

debug() {
  if [ "${CLAUDE_RUNTIME_INTROSPECT_DEBUG:-0}" = "1" ]; then
    printf 'runtime-introspect: %s\n' "$*" >&2
  fi
}

# ---------------------------------------------------------------------------
# Phase 1: User-facing escape hatch
# ---------------------------------------------------------------------------
if [ "${CLAUDE_SKIP_RUNTIME_INTROSPECT:-0}" = "1" ]; then
  exit 0
fi

# ---------------------------------------------------------------------------
# Stdin capture + jq availability
# ---------------------------------------------------------------------------
INPUT="$(cat 2>/dev/null || true)"
[ -z "$INPUT" ] && exit 0

if ! command -v jq >/dev/null 2>&1; then
  debug "jq not found — capture skipped"
  exit 0
fi

COMMAND="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || true)"
[ -z "$COMMAND" ] && exit 0

SESSION_ID="$(printf '%s' "$INPUT" | jq -r '.session_id // ""' 2>/dev/null || true)"
AGENT_ID="$(printf '%s' "$INPUT" | jq -r '.agent_id // ""' 2>/dev/null || true)"
TOOL_USE_ID="$(printf '%s' "$INPUT" | jq -r '.tool_use_id // ""' 2>/dev/null || true)"

# tool_response shape: {stdout, stderr, exit_code} for Bash. All optional.
EXIT_CODE="$(printf '%s' "$INPUT" | jq -r '.tool_response.exit_code // empty' 2>/dev/null || true)"

# Use jq -j (no separator newline) + printf-x sentinel to preserve trailing
# newlines in stdout/stderr. $(jq -r) strips ONE trailing \n; without this
# trick, "foo\n" round-trips to "foo".
STDOUT_RAW="$(printf '%s' "$INPUT" | jq -j '.tool_response.stdout // ""' 2>/dev/null; printf x)"
STDOUT_RAW="${STDOUT_RAW%x}"
STDERR_RAW="$(printf '%s' "$INPUT" | jq -j '.tool_response.stderr // ""' 2>/dev/null; printf x)"
STDERR_RAW="${STDERR_RAW%x}"

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
STATE_DIR="$PROJECT_DIR/.claude/.runtime-state"
IN_FLIGHT_DIR="$STATE_DIR/in-flight"

# ---------------------------------------------------------------------------
# Phase 2: Tokenise and detect
# ---------------------------------------------------------------------------
# shellcheck disable=SC2206  # intentional word-splitting on COMMAND
tokens=( $COMMAND )
n=${#tokens[@]}

detector=""

# Helper: does token contain one of the verifier keywords?
script_has_keyword() {
  case "$1" in
    *test*|*build*|*typecheck*|*lint*) return 0 ;;
    *) return 1 ;;
  esac
}

# Parse EXTRA_DETECT into a space-separated list of `<tool>-<verb>` keys.
extra_detect="${CLAUDE_RUNTIME_INTROSPECT_EXTRA_DETECT:-}"

i=0
while [ "$i" -lt "$n" ]; do
  current="${tokens[$i]}"
  next=""
  next2=""
  [ "$((i + 1))" -lt "$n" ] && next="${tokens[$((i + 1))]}"
  [ "$((i + 2))" -lt "$n" ] && next2="${tokens[$((i + 2))]}"

  # Single-token verifiers
  case "$current" in
    pytest)
      detector="pytest"
      break
      ;;
  esac

  # python|python3 -m pytest|unittest
  case "$current" in
    python|python3)
      if [ "$next" = "-m" ]; then
        case "$next2" in
          pytest)    detector="python-pytest"; break ;;
          unittest)  detector="python-unittest"; break ;;
        esac
      fi
      ;;
  esac

  # Pair-token verifiers
  case "$current $next" in
    "bun test")    detector="bun-test"; break ;;
    "bun tsc")     detector="bun-tsc"; break ;;
    "npm test")    detector="npm-test"; break ;;
    "pnpm test")   detector="pnpm-test"; break ;;
    "yarn test")   detector="yarn-test"; break ;;
    "yarn build")  detector="yarn-build"; break ;;
    "yarn typecheck") detector="yarn-typecheck"; break ;;
    "yarn lint")   detector="yarn-lint"; break ;;
  esac

  # run-script verifiers: bun run / npm run / pnpm run + script with keyword
  case "$current $next" in
    "bun run"|"npm run"|"pnpm run"|"yarn run")
      if [ -n "$next2" ] && script_has_keyword "$next2"; then
        case "$current" in
          bun)   detector="bun-run"; break ;;
          npm)   detector="npm-run"; break ;;
          pnpm)  detector="pnpm-run"; break ;;
          yarn)  detector="yarn-run"; break ;;
        esac
      fi
      ;;
  esac

  i=$((i + 1))
done

# ---------------------------------------------------------------------------
# Phase 3: EXTRA_DETECT extension (only when core detection missed)
# ---------------------------------------------------------------------------
if [ -z "$detector" ] && [ -n "$extra_detect" ]; then
  i=0
  while [ "$i" -lt "$((n - 1))" ]; do
    current="${tokens[$i]}"
    next="${tokens[$((i + 1))]}"
    candidate="$current-$next"
    for key in $extra_detect; do
      if [ "$candidate" = "$key" ]; then
        detector="extra:$key"
        break 2
      fi
    done
    i=$((i + 1))
  done
fi

# No detector matched → silent skip.
[ -z "$detector" ] && exit 0

debug "detector matched: $detector ($COMMAND)"

# ---------------------------------------------------------------------------
# Phase 4: Compute started_at / ended_at / duration_ms
# ---------------------------------------------------------------------------
ended_at="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || true)"
[ -z "$ended_at" ] && exit 0

started_at="$ended_at"
duration_ms="null"

if [ -n "$TOOL_USE_ID" ] && [ -f "$IN_FLIGHT_DIR/${TOOL_USE_ID}.t" ]; then
  mark="$(cat "$IN_FLIGHT_DIR/${TOOL_USE_ID}.t" 2>/dev/null || true)"
  if [ -n "$mark" ]; then
    started_at="$mark"
    if command -v date >/dev/null 2>&1; then
      start_epoch="$(date -u -d "$started_at" +%s 2>/dev/null || date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$started_at" +%s 2>/dev/null || true)"
      end_epoch="$(date -u -d "$ended_at" +%s 2>/dev/null || date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$ended_at" +%s 2>/dev/null || true)"
      if [ -n "$start_epoch" ] && [ -n "$end_epoch" ]; then
        duration_ms=$(( (end_epoch - start_epoch) * 1000 ))
      fi
    fi
  fi
  rm -f "$IN_FLIGHT_DIR/${TOOL_USE_ID}.t" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Phase 5: Clamp stdout / stderr to 4 KB head + 4 KB tail
# ---------------------------------------------------------------------------
clamp_stream() {
  local raw="$1"
  local len=${#raw}
  if [ "$len" -le 8192 ]; then
    printf '%s' "$raw"
    printf '\0'
    printf ''
    printf '\0'
    printf 'false'
    return
  fi
  # head: first 4096 chars, tail: last 4096 chars
  local head_part="${raw:0:4096}"
  local tail_part="${raw: -4096}"
  printf '%s' "$head_part"
  printf '\0'
  printf '%s' "$tail_part"
  printf '\0'
  printf 'true'
}

# Use jq directly with --rawfile-equivalent via --arg for the clamping.
stdout_len=${#STDOUT_RAW}
stderr_len=${#STDERR_RAW}

if [ "$stdout_len" -le 8192 ]; then
  stdout_head="$STDOUT_RAW"
  stdout_tail=""
  stdout_truncated="false"
else
  stdout_head="${STDOUT_RAW:0:4096}"
  stdout_tail="${STDOUT_RAW: -4096}"
  stdout_truncated="true"
fi

if [ "$stderr_len" -le 8192 ]; then
  stderr_head="$STDERR_RAW"
  stderr_tail=""
  stderr_truncated="false"
else
  stderr_head="${STDERR_RAW:0:4096}"
  stderr_tail="${STDERR_RAW: -4096}"
  stderr_truncated="true"
fi

# ---------------------------------------------------------------------------
# Phase 6: Write last-run.json atomically
# ---------------------------------------------------------------------------
mkdir -p "$STATE_DIR" 2>/dev/null || { debug "could not create state dir"; exit 0; }

# Probe writability before invoking mktemp.
if ! ( : >>"$STATE_DIR/.writetest" ) 2>/dev/null; then
  debug "state dir not writeable — capture skipped"
  exit 0
fi
rm -f "$STATE_DIR/.writetest" 2>/dev/null || true

# Build JSON payload with jq for safe escaping.
session_id_json="null"
[ -n "$SESSION_ID" ] && session_id_json="$(printf '%s' "$SESSION_ID" | jq -R -s -c 'rtrimstr("\n")')"

agent_id_json="null"
[ -n "$AGENT_ID" ] && agent_id_json="$(printf '%s' "$AGENT_ID" | jq -R -s -c 'rtrimstr("\n")')"

exit_json="null"
case "$EXIT_CODE" in
  ''|*[!0-9-]*) exit_json="null" ;;
  *)            exit_json="$EXIT_CODE" ;;
esac

payload="$(jq -n \
  --arg command "$COMMAND" \
  --arg detector "$detector" \
  --argjson exit "$exit_json" \
  --arg started_at "$started_at" \
  --arg ended_at "$ended_at" \
  --argjson duration_ms "$duration_ms" \
  --argjson session_id "$session_id_json" \
  --argjson agent_id "$agent_id_json" \
  --arg stdout_head "$stdout_head" \
  --arg stdout_tail "$stdout_tail" \
  --argjson stdout_truncated "$stdout_truncated" \
  --arg stderr_head "$stderr_head" \
  --arg stderr_tail "$stderr_tail" \
  --argjson stderr_truncated "$stderr_truncated" \
  '{
    command: $command,
    detector: $detector,
    exit: $exit,
    started_at: $started_at,
    ended_at: $ended_at,
    duration_ms: $duration_ms,
    session_id: $session_id,
    agent_id: $agent_id,
    stdout_head: $stdout_head,
    stdout_tail: $stdout_tail,
    stdout_truncated: $stdout_truncated,
    stderr_head: $stderr_head,
    stderr_tail: $stderr_tail,
    stderr_truncated: $stderr_truncated
  }' 2>/dev/null || true)"

[ -z "$payload" ] && { debug "jq payload build failed"; exit 0; }

tmpfile="$(mktemp "$STATE_DIR/last-run.XXXXXX.json" 2>/dev/null || true)"
if [ -z "$tmpfile" ]; then
  debug "mktemp failed in state dir"
  exit 0
fi

printf '%s\n' "$payload" > "$tmpfile" 2>/dev/null || {
  rm -f "$tmpfile" 2>/dev/null || true
  debug "write to tmpfile failed"
  exit 0
}

mv -f "$tmpfile" "$STATE_DIR/last-run.json" 2>/dev/null || {
  rm -f "$tmpfile" 2>/dev/null || true
  debug "atomic rename failed"
  exit 0
}

debug "wrote snapshot: $detector exit=$exit_json"
exit 0
