#!/usr/bin/env bash
# .agent0/tools/unused-code.sh
#
# unused-code — runtime-neutral, on-demand detector for UNUSED/dead code in a
# project (unused files, exports, dependencies, unreferenced members).
# Spec: docs/specs/208-unused-code-audit/. Engine: knip (JS/TS-only for v1).
#
# Philosophy (twin of /vuln-audit): do NOT run on the per-edit validator path,
# on install, or on commit. Detect unused code on demand, report + propose,
# NEVER delete. Human-in-loop. "candidate unused" — never "delete this".
#
# Usage:
#   unused-code.sh [path] [--json] [--exit-code]
#
#   path           directory to scan (default: .)
#   --json         emit a deterministic structured doc on stdout (shape-only
#                  convenience, NOT a versioned wire contract — field set may evolve)
#   --exit-code    map result status -> process exit code (consumer-owned CI opt-in):
#                  clean=0 findings=1 unconfigured=2 unavailable=3 failed=4. WITHOUT
#                  this flag the process ALWAYS exits 0 for any RESULT STATUS
#                  (advisory family — never a gate).
#
# Usage errors (unknown flag, non-directory path) exit 64 (EX_USAGE) regardless
# of --exit-code. They signal a wrong invocation, not a scan result, so they are
# deliberately exempt from the advisory exit model (same posture as vuln-audit).
#
# Result statuses (first-class, decoupled from exit code):
#   no-stack    no supported (JS/TS) stack detected — clean no-op, no claim of coverage
#   clean       engine ran, no unused code in its corpus
#   findings    engine ran, >=1 unused-code finding
#   unconfigured knip resolvable but the project ships no knip config (no entry/boundary
#               model) — hard-stop rather than run bare defaults that flag legit entry
#               points as unused (would manufacture false positives)
#   unavailable knip not resolvable (not installed locally) — advisory + install hint
#   failed      engine ran but errored / produced unparseable output
#
# Coverage caveat: v1 covers JS/TS via knip ONLY. A non-JS project reports
# `no-stack` and never claims stack-neutral coverage it does not have.

set -uo pipefail

# ---------------------------------------------------------------------------
# Args
# ---------------------------------------------------------------------------
SCAN_PATH="."
OUT_JSON=0
USE_EXIT_CODE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --json) OUT_JSON=1 ;;
    --exit-code) USE_EXIT_CODE=1 ;;
    -h|--help)
      sed -n '3,38p' "$0"
      exit 0
      ;;
    -*) echo "unused-code: unknown flag: $1" >&2; exit 64 ;;
    *) SCAN_PATH="$1" ;;
  esac
  shift
done

# jq is required to parse knip's JSON. Absent → fail open (advisory family).
if ! command -v jq >/dev/null 2>&1; then
  if [ "$OUT_JSON" -eq 1 ]; then
    printf '{"status":"unavailable","engine":"knip","reason":"jq not installed","findings":[]}\n'
  else
    printf 'unused-code: status=unavailable — jq not installed (required to parse engine output)\n'
  fi
  [ "$USE_EXIT_CODE" -eq 1 ] && exit 3
  exit 0
fi

if [ ! -d "$SCAN_PATH" ]; then
  echo "unused-code: not a directory: $SCAN_PATH" >&2
  exit 64
fi
cd "$SCAN_PATH" || { echo "unused-code: cannot cd to $SCAN_PATH" >&2; exit 64; }

# ---------------------------------------------------------------------------
# Status emit helpers
# ---------------------------------------------------------------------------
STATUS=""
REASON=""
HINT=""
FINDINGS_JSON="[]"

emit_and_exit() {
  # $1 status, $2 reason (human), $3 hint (optional), $4 exit-code-mapping
  local status="$1" reason="$2" hint="${3:-}" code="${4:-0}"
  if [ "$OUT_JSON" -eq 1 ]; then
    jq -n \
      --arg status "$status" \
      --arg engine "knip" \
      --arg reason "$reason" \
      --arg hint "$hint" \
      --argjson findings "$FINDINGS_JSON" \
      '{status:$status,engine:$engine,reason:$reason,hint:$hint,findings:$findings}
       | with_entries(select(.key == "findings" or .value != ""))'
  else
    printf 'unused-code: status=%s (engine: knip, JS/TS)\n' "$status"
    [ -n "$reason" ] && printf '  %s\n' "$reason"
    [ -n "$hint" ] && printf '  hint: %s\n' "$hint"
    if [ "$status" = "findings" ]; then
      printf '%s' "$FINDINGS_JSON" | jq -r '
        .[] | "  [\(.kind)] \(.file)\(if .name then " — " + .name else "" end) — candidate unused"
      '
      printf '\n  These are CANDIDATES. Verify before removing — exports may be intentional public API,\n  files may be loaded dynamically. unused-code never deletes anything.\n'
    fi
  fi
  [ "$USE_EXIT_CODE" -eq 1 ] && exit "$code"
  exit 0
}

# ---------------------------------------------------------------------------
# Stack detection — JS/TS only in v1. No markers → no-stack clean no-op.
# (No claim of stack-neutral coverage. Further stacks land one-per-stack
# behind demand, like the lint validator rolled out.)
# ---------------------------------------------------------------------------
if [ ! -f "package.json" ]; then
  emit_and_exit "no-stack" "no package.json — no supported (JS/TS) stack detected" "" 0
fi

# Install-hint flavor from the lockfile (used only in the `unavailable` message).
install_cmd="npm install -D knip"
if [ -f "bun.lockb" ] || [ -f "bun.lock" ] || [ -f "bunfig.toml" ]; then
  install_cmd="bun add -d knip"
elif [ -f "pnpm-lock.yaml" ]; then
  install_cmd="pnpm add -D knip"
fi

# ---------------------------------------------------------------------------
# Engine resolution — resolve a single NO-FETCH knip invocation. Prefer the
# local binary directly (covers npm/pnpm/bun installs, zero install risk); fall
# back to an `npx --no-install` probe for hoisted/workspace layouts. We do NOT
# probe via `pnpm exec` or bare `bunx` — both can trigger an install/sync, which
# would violate the never-install / modifies-no-file contract (codex review
# 2026-06-19). The SAME $KNIP_RUN string is used for the probe AND the real run,
# so the no-fetch guarantee cannot drift between resolution and execution.
# ---------------------------------------------------------------------------
KNIP_RUN=""
if [ -x "node_modules/.bin/knip" ]; then
  KNIP_RUN="node_modules/.bin/knip"
elif command -v npx >/dev/null 2>&1 && npx --no-install knip --version >/dev/null 2>&1; then
  KNIP_RUN="npx --no-install knip"
fi

if [ -z "$KNIP_RUN" ]; then
  emit_and_exit "unavailable" "knip is not installed in this project" "run \`$install_cmd\`, then re-run unused-code" 3
fi

# ---------------------------------------------------------------------------
# Config detection — knip needs an entry/boundary model to avoid flagging
# legitimate entry points. No config → hard-stop at `unconfigured` (maintainer
# ruling 2026-06-18) rather than run bare defaults that manufacture false
# positives. A `knip` key in package.json counts as configured.
# ---------------------------------------------------------------------------
has_knip_config() {
  for f in knip.json knip.jsonc knip.ts knip.js \
           .knip.json .knip.jsonc .knip.ts .knip.js \
           knip.config.ts knip.config.js; do
    [ -f "$f" ] && return 0
  done
  jq -e '.knip // empty' package.json >/dev/null 2>&1 && return 0
  return 1
}

if ! has_knip_config; then
  emit_and_exit "unconfigured" \
    "knip is installed but no knip config was found — its entry-point/boundary model is required to avoid flagging legitimate entry points as unused" \
    "add a knip.json (see https://knip.dev/overview/configuration) declaring your \`entry\` and \`project\` globs, then re-run" 2
fi

# ---------------------------------------------------------------------------
# Run knip. Exit code is 0 (clean) / 1 (findings); other codes or unparseable
# output → failed (with reason). NEVER crash.
# ---------------------------------------------------------------------------
err_file="$(mktemp 2>/dev/null || mktemp -t unused-code-err)"
trap 'rm -f "$err_file"' EXIT
raw_out="$($KNIP_RUN --reporter json 2>"$err_file")"
knip_exit=$?
knip_err="$(head -1 "$err_file" 2>/dev/null)"

# knip exits 0 (clean) or 1 (findings). ANY other code is an engine failure
# (config error, crash, ...) and must NOT be silently read as clean/findings,
# even if it happened to print valid-looking JSON (codex BLOCKER 1).
if [ "$knip_exit" -ne 0 ] && [ "$knip_exit" -ne 1 ]; then
  reason="knip exited $knip_exit"
  [ -n "$knip_err" ] && reason="$reason: $knip_err"
  emit_and_exit "failed" "$reason" "" 4
fi

# Defensive parse: require a top-level object with an `issues` array.
if ! printf '%s' "$raw_out" | jq -e 'type == "object" and (.issues | type == "array")' >/dev/null 2>&1; then
  reason="knip produced no parseable JSON (exit $knip_exit)"
  [ -n "$knip_err" ] && reason="$reason: $knip_err"
  emit_and_exit "failed" "$reason" "" 4
fi

# Flatten issues into a typed findings array. Depend only on documented keys;
# tolerate missing/extra keys. Maps knip issue-type arrays -> taxonomy kinds.
FINDINGS_JSON="$(printf '%s' "$raw_out" | jq -c '
  # Tolerate string-or-object array elements (knip documents objects, but the
  # parser must not crash if a future element is a bare string — codex BLOCKER 2).
  def norm: if type == "object" then . else {name:(.|tostring)} end;
  def emit($file; $kind; $arr): ($arr // []) | map(norm | {file:$file, kind:$kind, name:(.name // null)});
  # unused file: the element name duplicates the file path → carry name:null.
  def emitfile($file; $arr): ($arr // []) | map({file:$file, kind:"unused file", name:null});
  [ .issues[]
    | .file as $f
    | ( emitfile($f; .files)
      + emit($f; "unused export";      .exports)
      + emit($f; "unused export";      .types)
      + emit($f; "unused dependency";  .dependencies)
      + emit($f; "unused dependency";  .devDependencies)
      + emit($f; "unreferenced member"; .enumMembers)
      + emit($f; "unreferenced member"; .namespaceMembers)
      + emit($f; "other";              .unlisted)
      + emit($f; "other";              .unresolved)
      + emit($f; "other";              .duplicates)
      )
  ] | flatten
')"
jq_rc=$?

# A jq failure (or empty output) here must NOT collapse to `clean` — a real
# findings set could be swallowed (codex BLOCKER 2). Treat it as engine failure.
if [ "$jq_rc" -ne 0 ] || [ -z "$FINDINGS_JSON" ]; then
  emit_and_exit "failed" "knip JSON could not be reduced to a findings list (jq exit $jq_rc)" "" 4
fi

count="$(printf '%s' "$FINDINGS_JSON" | jq 'length' 2>/dev/null)"
case "$count" in
  ''|*[!0-9]*) emit_and_exit "failed" "could not count findings from engine output" "" 4 ;;
esac

if [ "$count" -gt 0 ]; then
  emit_and_exit "findings" "$count candidate unused item(s) found" "" 1
else
  emit_and_exit "clean" "no unused code found by knip" "" 0
fi
