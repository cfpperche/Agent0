#!/usr/bin/env bash
# .claude/tools/bench-hooks.sh
# Benchmark + regression check for PreToolUse(Bash) hook chain latency.
#
# Modes:
#   --baseline   write results to .claude/.perf-baseline.json (commits new baseline)
#   --check      read baseline, re-run, exit 2 if any tracked p95 exceeds
#                baseline × (1 + tolerance); default tolerance = 25%
#   (none)       run + print, no file IO; useful between optimizations
#
# Options:
#   --reps N           rep count per (hook × command) cell (default 100)
#   --commands LIST    comma-separated label:cmd list (default: built-in fast+slow set)
#   --tolerance PCT    --check tolerance percent (default 25; env CLAUDE_HOOK_CHAIN_TOLERANCE_PCT also honored)
#   --quiet            suppress human-readable table on stdout
#
# Timing: bash 5+ $EPOCHREALTIME (microsecond precision) — no external timing tool.
# Side-effects: redirects CLAUDE_PROJECT_DIR to a per-run tmpdir so the hooks' own
# audit logs (.claude/secrets-audit.jsonl, .claude/supply-chain-audit.jsonl) and
# in-flight runtime-mark files land in tmp, never in the real project tree.
# Tmpdir is cleaned at exit.
#
# Why this exists: see .agent0/memory/hook-chain-latency.md.

set -uo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
HOOKS_DIR="$PROJECT_DIR/.claude/hooks"
BASELINE_PATH="$PROJECT_DIR/.claude/.perf-baseline.json"

MODE="run"                # run | baseline | check
REPS=100
TOLERANCE_PCT="${CLAUDE_HOOK_CHAIN_TOLERANCE_PCT:-25}"
QUIET=0
COMMANDS_ARG=""

while [ $# -gt 0 ]; do
  case "$1" in
    --baseline) MODE="baseline"; shift ;;
    --check)    MODE="check"; shift ;;
    --reps)     REPS="$2"; shift 2 ;;
    --commands) COMMANDS_ARG="$2"; shift 2 ;;
    --tolerance) TOLERANCE_PCT="$2"; shift 2 ;;
    --quiet)    QUIET=1; shift ;;
    -h|--help)
      sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *)
      printf 'bench-hooks: unknown arg "%s"\n' "$1" >&2
      exit 2 ;;
  esac
done

if [ -z "${EPOCHREALTIME:-}" ]; then
  echo "bench-hooks: bash $BASH_VERSION lacks EPOCHREALTIME (need bash 5+); aborting" >&2
  exit 2
fi
command -v jq >/dev/null 2>&1 || { echo "bench-hooks: jq missing; aborting" >&2; exit 2; }

# --- Tmpdir + isolation ---
BENCH_TMPDIR="$(mktemp -d -t agent0-bench.XXXXXX)"
trap 'rm -rf "$BENCH_TMPDIR"' EXIT
mkdir -p "$BENCH_TMPDIR/.claude"
# Initialize the redirected project tree just enough for hook side-writes.
mkdir -p "$BENCH_TMPDIR/.agent0/.runtime-state/in-flight"
ORIGINAL_PROJECT_DIR="$PROJECT_DIR"
export CLAUDE_PROJECT_DIR="$BENCH_TMPDIR"

# --- Hooks under test (filenames in .claude/hooks/) ---
# Order matches settings.json PreToolUse(Bash) registration.
HOOK_NAMES=( "governance-gate.sh" "secrets-scan.sh" "supply-chain-scan.sh" "runtime-pre-mark.sh" )

# --- Command set ---
# label::: command-string  (the ':::' separator is intentional — unlikely in any real cmd)
DEFAULT_COMMANDS=(
  "noop::: :"
  "ls:::ls"
  "cat:::cat /dev/null"
  "echo:::echo hello"
  "git-status:::git status"
  "git-log:::git log -1"
  "grep:::grep -r foo ."
  "git-commit:::git commit -m 'test'"
  "npm-install:::npm install lodash"
  "cat-file:::cat CLAUDE.md"
)
if [ -n "$COMMANDS_ARG" ]; then
  IFS=',' read -r -a COMMANDS_LIST <<< "$COMMANDS_ARG"
else
  COMMANDS_LIST=( "${DEFAULT_COMMANDS[@]}" )
fi

# --- Payload builder ---
# Builds the JSON stdin payload mirroring Claude Code's PreToolUse(Bash) shape.
build_payload() {
  local cmd="$1"
  jq -c -n \
    --arg cmd "$cmd" \
    '{session_id:"bench", agent_id:null, tool_use_id:"toolu_bench", tool_input:{command:$cmd}}'
}

# --- Runner: time N reps of one hook against one payload, output microsec deltas ---
# Warm-up: 5 reps discarded before measurement begins (filesystem cache, jit, etc.)
run_cell() {
  local hook_path="$1"
  local payload="$2"
  local n="$3"
  local warmup=5
  local t0 t1 us0 us1 i
  # warm-up
  i=0
  while [ "$i" -lt "$warmup" ]; do
    printf '%s' "$payload" | bash "$hook_path" >/dev/null 2>&1 || true
    i=$((i + 1))
  done
  # measured
  i=0
  while [ "$i" -lt "$n" ]; do
    t0="$EPOCHREALTIME"
    printf '%s' "$payload" | bash "$hook_path" >/dev/null 2>&1 || true
    t1="$EPOCHREALTIME"
    us0="${t0/./}"
    us1="${t1/./}"
    printf '%d\n' "$((us1 - us0))"
    i=$((i + 1))
  done
}

# --- Percentile from a stream of integer microseconds → milliseconds (float w/ 2 decimals) ---
percentile_ms() {
  local pct="$1"
  awk -v pct="$pct" '
    { a[NR] = $1 }
    END {
      n = NR
      if (n == 0) { print "null"; exit }
      # sort ascending
      for (i = 1; i <= n; i++)
        for (j = i + 1; j <= n; j++)
          if (a[i] > a[j]) { t = a[i]; a[i] = a[j]; a[j] = t }
      idx = int(pct/100 * n + 0.5)
      if (idx < 1) idx = 1
      if (idx > n) idx = n
      printf("%.2f", a[idx] / 1000.0)
    }'
}

# --- Build "noop" hook for harness-IPC characterization ---
NOOP_HOOK="$BENCH_TMPDIR/noop-hook.sh"
cat > "$NOOP_HOOK" <<'NOOP'
#!/usr/bin/env bash
# Discards stdin, exits 0. Characterizes bash subprocess spawn + stdin pipe cost
# (the cost floor every real hook pays before any of its own logic runs).
cat >/dev/null 2>&1 || true
exit 0
NOOP
chmod +x "$NOOP_HOOK"

# Hook-row ordering: [noop, four real hooks].
HOOK_ROWS=( "noop" "${HOOK_NAMES[@]}" )

# --- Run all cells, collect results into associative-ish arrays via composite keys ---
declare -A P50 P95 NDATA

if [ "$QUIET" -eq 0 ]; then
  printf 'bench-hooks: reps=%d cells=%d hooks=%d cmds=%d project_dir(redirected)=%s\n' \
    "$REPS" "$((${#HOOK_ROWS[@]} * ${#COMMANDS_LIST[@]}))" \
    "${#HOOK_ROWS[@]}" "${#COMMANDS_LIST[@]}" "$BENCH_TMPDIR" >&2
fi

for cmd_pair in "${COMMANDS_LIST[@]}"; do
  cmd_label="${cmd_pair%%:::*}"
  cmd_str="${cmd_pair#*:::}"
  payload="$(build_payload "$cmd_str")"

  for hook in "${HOOK_ROWS[@]}"; do
    if [ "$hook" = "noop" ]; then
      hook_path="$NOOP_HOOK"
    else
      hook_path="$HOOKS_DIR/$hook"
      if [ ! -f "$hook_path" ]; then
        P50["$hook|$cmd_label"]="null"
        P95["$hook|$cmd_label"]="null"
        NDATA["$hook|$cmd_label"]="0"
        continue
      fi
    fi

    samples="$(run_cell "$hook_path" "$payload" "$REPS")"
    p50="$(printf '%s\n' "$samples" | percentile_ms 50)"
    p95="$(printf '%s\n' "$samples" | percentile_ms 95)"
    P50["$hook|$cmd_label"]="$p50"
    P95["$hook|$cmd_label"]="$p95"
    NDATA["$hook|$cmd_label"]="$REPS"
  done
done

# --- Human-readable output (stdout) ---
if [ "$QUIET" -eq 0 ]; then
  printf '\n%s\n' "## bench-hooks results (p95 ms, n=$REPS per cell)"
  # Header
  printf '%-26s' "hook \\ cmd"
  for cmd_pair in "${COMMANDS_LIST[@]}"; do
    cmd_label="${cmd_pair%%:::*}"
    printf '%-13s' "$cmd_label"
  done
  printf '\n'
  for hook in "${HOOK_ROWS[@]}"; do
    printf '%-26s' "$hook"
    for cmd_pair in "${COMMANDS_LIST[@]}"; do
      cmd_label="${cmd_pair%%:::*}"
      printf '%-13s' "${P95["$hook|$cmd_label"]}"
    done
    printf '\n'
  done
  # Also show p50 in a second block
  printf '\n%s\n' "## bench-hooks results (p50 ms)"
  printf '%-26s' "hook \\ cmd"
  for cmd_pair in "${COMMANDS_LIST[@]}"; do
    cmd_label="${cmd_pair%%:::*}"
    printf '%-13s' "$cmd_label"
  done
  printf '\n'
  for hook in "${HOOK_ROWS[@]}"; do
    printf '%-26s' "$hook"
    for cmd_pair in "${COMMANDS_LIST[@]}"; do
      cmd_label="${cmd_pair%%:::*}"
      printf '%-13s' "${P50["$hook|$cmd_label"]}"
    done
    printf '\n'
  done
fi

# --- Build JSON output ---
cells_json="{}"
for hook in "${HOOK_ROWS[@]}"; do
  per_hook="{}"
  for cmd_pair in "${COMMANDS_LIST[@]}"; do
    cmd_label="${cmd_pair%%:::*}"
    p50="${P50["$hook|$cmd_label"]}"
    p95="${P95["$hook|$cmd_label"]}"
    n="${NDATA["$hook|$cmd_label"]}"
    per_hook="$(jq -c --arg key "$cmd_label" \
      --argjson p50 "${p50:-null}" \
      --argjson p95 "${p95:-null}" \
      --argjson n "${n:-0}" \
      '. + {($key): {p50_ms:$p50, p95_ms:$p95, n:$n}}' <<<"$per_hook")"
  done
  cells_json="$(jq -c --arg hook "$hook" --argjson v "$per_hook" \
    '. + {($hook): $v}' <<<"$cells_json")"
done

git_sha="$(git -C "$ORIGINAL_PROJECT_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")"
harness_version="${CLAUDECODE_VERSION:-unknown}"
os_string="$(uname -s -r 2>/dev/null || echo unknown)"
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"

result_json="$(jq -c -n \
  --arg git_sha "$git_sha" \
  --arg harness_version "$harness_version" \
  --arg os "$os_string" \
  --arg ts "$ts" \
  --argjson reps "$REPS" \
  --argjson cells "$cells_json" \
  '{git_sha:$git_sha, harness_version:$harness_version, os:$os, ts:$ts, reps:$reps, cells:$cells}')"

# --- Mode dispatch ---
case "$MODE" in
  run)
    if [ "$QUIET" -eq 0 ]; then printf '\n'; fi
    printf '%s\n' "$result_json" | jq .
    ;;

  baseline)
    printf '%s\n' "$result_json" | jq . > "$BASELINE_PATH"
    if [ "$QUIET" -eq 0 ]; then
      printf '\nbench-hooks: wrote baseline → %s\n' "$BASELINE_PATH" >&2
    fi
    ;;

  check)
    if [ ! -f "$BASELINE_PATH" ]; then
      echo "bench-hooks: baseline missing at $BASELINE_PATH; run --baseline first" >&2
      exit 2
    fi
    baseline_cells="$(jq -c '.cells' "$BASELINE_PATH")"
    fail=0
    # tolerance factor (e.g. 25% → 1.25)
    tol_factor="$(awk -v p="$TOLERANCE_PCT" 'BEGIN { printf "%.4f", 1 + p/100 }')"
    for hook in "${HOOK_ROWS[@]}"; do
      for cmd_pair in "${COMMANDS_LIST[@]}"; do
        cmd_label="${cmd_pair%%:::*}"
        current_p95="${P95["$hook|$cmd_label"]}"
        baseline_p95="$(jq -r --arg h "$hook" --arg c "$cmd_label" \
          '.[$h][$c].p95_ms // empty' <<<"$baseline_cells")"
        [ -z "$baseline_p95" ] || [ "$baseline_p95" = "null" ] && continue
        [ "$current_p95" = "null" ] && continue
        # Compute baseline × tolerance
        limit="$(awk -v b="$baseline_p95" -v t="$tol_factor" 'BEGIN { printf "%.4f", b*t }')"
        worse="$(awk -v c="$current_p95" -v l="$limit" 'BEGIN { print (c+0 > l+0) ? 1 : 0 }')"
        if [ "$worse" = "1" ]; then
          printf 'bench-hooks: REGRESSION %s × %s — current %s ms exceeds baseline %s ms × %s%% = %s ms\n' \
            "$hook" "$cmd_label" "$current_p95" "$baseline_p95" "$TOLERANCE_PCT" "$limit" >&2
          fail=1
        fi
      done
    done
    if [ "$fail" -eq 1 ]; then
      echo "bench-hooks: at least one p95 regressed beyond tolerance" >&2
      exit 2
    fi
    if [ "$QUIET" -eq 0 ]; then
      printf '\nbench-hooks: all tracked p95 within tolerance (+%s%%) of baseline\n' "$TOLERANCE_PCT" >&2
    fi
    ;;
esac
