#!/usr/bin/env bash
# .agent0/tools/unused-code.sh
#
# unused-code — runtime-neutral, on-demand detector for UNUSED/dead code in a
# project (unused files, exports, dependencies, unreferenced members,
# unreachable code). Specs: 208 (JS/TS via knip), 209 (Python via vulture,
# Go via deadcode).
#
# Philosophy (twin of /vuln-audit): do NOT run on the per-edit validator path,
# on install, or on commit. Detect unused code on demand, report + propose,
# NEVER delete. Human-in-loop. "candidate unused" — never "delete this".
#
# Usage:
#   unused-code.sh [path] [--json] [--exit-code] [--stack <js|python|go>]
#
#   path           directory to scan (default: .)
#   --json         emit a deterministic structured doc on stdout (shape-only
#                  convenience, NOT a versioned wire contract — field set may evolve)
#   --exit-code    map result status -> process exit code (consumer-owned CI opt-in):
#                  clean=0 findings=1 unconfigured=2 unavailable=3 failed=4. WITHOUT
#                  this flag the process ALWAYS exits 0 for any RESULT STATUS
#                  (advisory family — never a gate).
#   --stack S      force the stack to audit (js|python|go), overriding first-match
#                  detection. Useful in polyglot repos.
#
# Usage errors (unknown flag, non-directory path, bad --stack) exit 64 (EX_USAGE)
# regardless of --exit-code. They signal a wrong invocation, not a scan result,
# so they are deliberately exempt from the advisory exit model (like vuln-audit).
#
# Result statuses (first-class, decoupled from exit code):
#   no-stack    no supported stack (JS/TS, Python, Go) detected — clean no-op
#   clean       engine ran, no unused code in its corpus
#   findings    engine ran, >=1 unused-code finding
#   unconfigured engine resolvable but lacks the boundary/entry model it needs for
#               sound results (knip: no knip config; Go deadcode: no executable
#               main/test reachability root) — hard-stop rather than emit a
#               misleading `clean`
#   unavailable the stack's engine is not resolvable locally — advisory + install hint
#   failed      engine ran but errored / produced unparseable output
#
# Engines (single engine per stack): JS/TS → knip; Python → vulture; Go → deadcode.
# Coverage caveat: covers JS/TS, Python, Go. Rust/PHP are deferred (their tooling
# detects unused DEPENDENCIES, not dead code — a different capability). A repo
# with no supported stack reports `no-stack` and never claims coverage it lacks.

set -uo pipefail

# ---------------------------------------------------------------------------
# Args
# ---------------------------------------------------------------------------
SCAN_PATH="."
OUT_JSON=0
USE_EXIT_CODE=0
FORCE_STACK=""

while [ $# -gt 0 ]; do
  case "$1" in
    --json) OUT_JSON=1 ;;
    --exit-code) USE_EXIT_CODE=1 ;;
    --stack)
      shift
      if [ $# -eq 0 ] || case "${1:-}" in -*) true ;; *) false ;; esac; then
        echo "unused-code: --stack requires a value (js|python|go)" >&2; exit 64
      fi
      FORCE_STACK="$1"
      ;;
    --stack=*) FORCE_STACK="${1#*=}" ;;
    -h|--help)
      sed -n '3,46p' "$0"
      exit 0
      ;;
    -*) echo "unused-code: unknown flag: $1" >&2; exit 64 ;;
    *) SCAN_PATH="$1" ;;
  esac
  shift
done

case "$FORCE_STACK" in
  ""|js|python|go) ;;
  *) echo "unused-code: --stack must be one of: js python go" >&2; exit 64 ;;
esac

# jq is required to parse/emit JSON. Absent → fail open (advisory family).
if ! command -v jq >/dev/null 2>&1; then
  if [ "$OUT_JSON" -eq 1 ]; then
    printf '{"status":"unavailable","reason":"jq not installed","findings":[]}\n'
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
# Shared state + emit helper
# ---------------------------------------------------------------------------
ENGINE=""          # set per branch (knip|vulture|deadcode)
STACK_LABEL=""     # human stack label (JS/TS|Python|Go)
NOTE=""            # polyglot "other detected stacks" note (optional, human)
UNAUDITED_JSON="[]" # polyglot: structured list of detected-but-unaudited stacks
FINDINGS_JSON="[]" # array of {file, kind, name, confidence?}

emit_and_exit() {
  # $1 status, $2 reason (human), $3 hint (optional), $4 exit-code-mapping
  local status="$1" reason="$2" hint="${3:-}" code="${4:-0}"
  if [ "$OUT_JSON" -eq 1 ]; then
    jq -n \
      --arg status "$status" \
      --arg engine "$ENGINE" \
      --arg stack "$STACK_LABEL" \
      --arg reason "$reason" \
      --arg hint "$hint" \
      --arg note "$NOTE" \
      --argjson unaudited "$UNAUDITED_JSON" \
      --argjson findings "$FINDINGS_JSON" \
      '{status:$status,engine:$engine,stack:$stack,reason:$reason,hint:$hint,note:$note,unaudited_stacks:$unaudited,findings:$findings}
       | with_entries(select(.key == "findings" or (.value != "" and .value != [])))'
  else
    printf 'unused-code: status=%s (engine: %s%s)\n' "$status" "${ENGINE:-none}" "${STACK_LABEL:+, $STACK_LABEL}"
    [ -n "$reason" ] && printf '  %s\n' "$reason"
    [ -n "$hint" ] && printf '  hint: %s\n' "$hint"
    [ -n "$NOTE" ] && printf '  note: %s\n' "$NOTE"
    if [ "$status" = "findings" ]; then
      printf '%s' "$FINDINGS_JSON" | jq -r '
        .[] | "  [\(.kind)] \(.file)\(if .name then " — " + .name else "" end)\(if .confidence then " (" + (.confidence|tostring) + "% confidence)" else "" end) — candidate unused"
      '
      printf '\n  These are CANDIDATES. Verify before removing — exports may be intentional public API,\n  code may be reached dynamically/via reflection. unused-code never deletes anything.\n'
      [ "$ENGINE" = "vulture" ] && printf '  (vulture findings are heuristic; the confidence value is shown per line.)\n'
    fi
  fi
  [ "$USE_EXIT_CODE" -eq 1 ] && exit "$code"
  exit 0
}

# ---------------------------------------------------------------------------
# Stack detection — detect ALL supported stacks (drives the polyglot note),
# then pick one (the --stack override, else first-match in js→python→go order).
# ---------------------------------------------------------------------------
DETECTED=""
[ -f "package.json" ] && DETECTED="$DETECTED js"
if [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "setup.cfg" ] || ls requirements*.txt >/dev/null 2>&1; then
  DETECTED="$DETECTED python"
fi
[ -f "go.mod" ] && DETECTED="$DETECTED go"
DETECTED="$(echo "$DETECTED" | xargs 2>/dev/null)"  # trim

if [ -z "$DETECTED" ] && [ -z "$FORCE_STACK" ]; then
  emit_and_exit "no-stack" "no supported stack (JS/TS, Python, Go) detected" "" 0
fi

if [ -n "$FORCE_STACK" ]; then
  STACK="$FORCE_STACK"
else
  STACK="${DETECTED%% *}"  # first token
fi

# Polyglot honesty (for BOTH forced and auto runs): name the detected stacks
# that are NOT the one being audited, as a human note AND a structured
# `unaudited_stacks` array — so a consumer keying on status=clean can never
# silently miss partial coverage. Forcing --stack does not audit the others.
others=""
for s in $DETECTED; do
  [ "$s" = "$STACK" ] && continue
  others="${others:+$others, }$s"
done
if [ -n "$others" ]; then
  NOTE="other supported stacks detected but not audited: $others — re-run with --stack=<name>"
  UNAUDITED_JSON="$(printf '%s\n' "$DETECTED" | tr ' ' '\n' | grep -v "^$STACK\$" | grep -v '^$' | jq -R . | jq -s -c .)"
fi

# ===========================================================================
# Branch: JS/TS via knip (spec 208)
# ===========================================================================
run_js() {
  ENGINE="knip"; STACK_LABEL="JS/TS"

  local install_cmd="npm install -D knip"
  if [ -f "bun.lockb" ] || [ -f "bun.lock" ] || [ -f "bunfig.toml" ]; then
    install_cmd="bun add -d knip"
  elif [ -f "pnpm-lock.yaml" ]; then
    install_cmd="pnpm add -D knip"
  fi

  # Resolve a single NO-FETCH knip invocation: prefer the local binary; fall back
  # to `npx --no-install`. Never `pnpm exec`/bare `bunx` (can install/sync). Same
  # string used for probe AND run so the no-fetch guarantee can't drift.
  local KNIP_RUN=""
  if [ -x "node_modules/.bin/knip" ]; then
    KNIP_RUN="node_modules/.bin/knip"
  elif command -v npx >/dev/null 2>&1 && npx --no-install knip --version >/dev/null 2>&1; then
    KNIP_RUN="npx --no-install knip"
  fi
  if [ -z "$KNIP_RUN" ]; then
    emit_and_exit "unavailable" "knip is not installed in this project" "run \`$install_cmd\`, then re-run unused-code" 3
  fi

  # knip needs an entry/boundary model; no config → unconfigured (not bare defaults).
  local have_cfg=0 f
  for f in knip.json knip.jsonc knip.ts knip.js .knip.json .knip.jsonc .knip.ts .knip.js knip.config.ts knip.config.js; do
    [ -f "$f" ] && { have_cfg=1; break; }
  done
  [ "$have_cfg" -eq 0 ] && jq -e '.knip // empty' package.json >/dev/null 2>&1 && have_cfg=1
  if [ "$have_cfg" -eq 0 ]; then
    emit_and_exit "unconfigured" \
      "knip is installed but no knip config was found — its entry-point/boundary model is required to avoid flagging legitimate entry points as unused" \
      "add a knip.json (see https://knip.dev/overview/configuration) declaring your \`entry\` and \`project\` globs, then re-run" 2
  fi

  local err_file raw_out knip_exit knip_err
  err_file="$(mktemp 2>/dev/null || mktemp -t unused-code-err)"
  trap 'rm -f "$err_file"' EXIT
  raw_out="$($KNIP_RUN --reporter json 2>"$err_file")"
  knip_exit=$?
  knip_err="$(head -1 "$err_file" 2>/dev/null)"

  # knip exits 0 (clean) / 1 (findings); any other code is an engine failure
  # even if it printed valid-looking JSON.
  if [ "$knip_exit" -ne 0 ] && [ "$knip_exit" -ne 1 ]; then
    local r="knip exited $knip_exit"; [ -n "$knip_err" ] && r="$r: $knip_err"
    emit_and_exit "failed" "$r" "" 4
  fi
  if ! printf '%s' "$raw_out" | jq -e 'type == "object" and (.issues | type == "array")' >/dev/null 2>&1; then
    local r="knip produced no parseable JSON (exit $knip_exit)"; [ -n "$knip_err" ] && r="$r: $knip_err"
    emit_and_exit "failed" "$r" "" 4
  fi

  FINDINGS_JSON="$(printf '%s' "$raw_out" | jq -c '
    def norm: if type == "object" then . else {name:(.|tostring)} end;
    def emit($file; $kind; $arr): ($arr // []) | map(norm | {file:$file, kind:$kind, name:(.name // null)});
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
  local jq_rc=$?
  if [ "$jq_rc" -ne 0 ] || [ -z "$FINDINGS_JSON" ]; then
    emit_and_exit "failed" "knip JSON could not be reduced to a findings list (jq exit $jq_rc)" "" 4
  fi
  _emit_count_based "no unused code found by knip"
}

# ===========================================================================
# Branch: Python via vulture (spec 209)
# ===========================================================================
run_py() {
  ENGINE="vulture"; STACK_LABEL="Python"

  # Resolve vulture NO-FETCH: project venv binary, else PATH. Deliberately NOT
  # `uv run`/`poetry run` — those can sync/fetch (violates no-fetch).
  local VULTURE=""
  if [ -x ".venv/bin/vulture" ]; then
    VULTURE=".venv/bin/vulture"
  elif command -v vulture >/dev/null 2>&1; then
    VULTURE="vulture"
  fi
  if [ -z "$VULTURE" ]; then
    emit_and_exit "unavailable" "vulture is not installed in this project" "run \`pip install vulture\` (ideally into the project venv), then re-run unused-code" 3
  fi

  local err_file raw_out v_err
  err_file="$(mktemp 2>/dev/null || mktemp -t unused-code-err)"
  trap 'rm -f "$err_file"' EXIT
  # vulture's exit code is unreliable (0 on missing-path errors too); parse output.
  raw_out="$("$VULTURE" . --exclude '.venv,venv,node_modules,build,dist,.git,__pycache__' 2>"$err_file")"
  v_err="$(head -1 "$err_file" 2>/dev/null)"

  # Hard error (bad path, parse crash) → failed.
  if printf '%s\n%s' "$raw_out" "$v_err" | grep -qE 'could not be found|Error:|Traceback'; then
    local r="vulture errored"; [ -n "$v_err" ] && r="$r: $v_err"
    emit_and_exit "failed" "$r" "" 4
  fi

  # vulture's exit code is unreliable, so output shape is the contract. Any
  # per-location diagnostic line (`:N:`) that is NOT a recognized finding means
  # the format changed or vulture said something we don't understand → failed,
  # rather than risk a false `clean` that swallows real findings (codex MAJOR).
  local find_re=':[0-9]+: (unused [a-z]+|unreachable code) ?[^(]*\([0-9]+% confidence\)'
  local unrecognized
  unrecognized="$(printf '%s\n' "$raw_out" | grep -E ':[0-9]+:' | grep -vE "$find_re" || true)"
  if [ -n "$unrecognized" ]; then
    emit_and_exit "failed" "vulture produced unrecognized output: $(printf '%s' "$unrecognized" | head -1)" "" 4
  fi

  # Parse. select() and capture() use the SAME regex, so a selected line ALWAYS
  # captures — no silent drop (codex BLOCKER). The name is extracted via [^(]*
  # then stripped of quotes, so dotted names ('xml.etree', 'Foo.Bar') survive;
  # unreachable-code lines carry no symbol name → null (codex MAJOR).
  FINDINGS_JSON="$(printf '%s\n' "$raw_out" | jq -R -s -c '
    def kindof($w):
      if   ($w|test("function|class|method")) then "unused export"
      elif ($w|test("variable|attribute|property")) then "unreferenced member"
      elif ($w|test("unreachable")) then "unreachable code"
      else "other" end;
    def RE: "^(?<file>.+):(?<line>[0-9]+): (?<what>unused [a-z]+|unreachable code) ?(?<rest>[^(]*)\\((?<conf>[0-9]+)% confidence\\)";
    [ split("\n")[]
      | select(test(RE))
      | capture(RE)
      | { file: .file,
          kind: kindof(.what),
          name: ( if (.what|test("unreachable")) then null
                  else (.rest | gsub("\u0027";"") | gsub("\u0022";"") | gsub("^ +| +$";"")
                              | (if . == "" then null else . end)) end ),
          confidence: (.conf|tonumber) }
    ]
  ')"
  local jq_rc=$?
  if [ "$jq_rc" -ne 0 ] || [ -z "$FINDINGS_JSON" ]; then
    emit_and_exit "failed" "vulture output could not be parsed into findings (jq exit $jq_rc)" "" 4
  fi
  _emit_count_based "no unused code found by vulture"
}

# ===========================================================================
# Branch: Go via deadcode (spec 209)
# ===========================================================================
run_go() {
  ENGINE="deadcode"; STACK_LABEL="Go"

  # Resolve deadcode NO-FETCH: PATH only (never `go install`).
  if ! command -v deadcode >/dev/null 2>&1; then
    emit_and_exit "unavailable" "deadcode is not installed" "run \`go install golang.org/x/tools/cmd/deadcode@latest\`, then re-run unused-code" 3
  fi

  local err_file raw_out d_exit d_err
  err_file="$(mktemp 2>/dev/null || mktemp -t unused-code-err)"
  trap 'rm -f "$err_file"' EXIT
  raw_out="$(deadcode -test -json ./... 2>"$err_file")"
  d_exit=$?
  d_err="$(head -1 "$err_file" 2>/dev/null)"

  # No executable main / no reachability root → unconfigured (generalized): the
  # engine has no entry model to analyze, so `clean` would be misleading.
  if printf '%s' "$d_err" | grep -q 'no main packages'; then
    emit_and_exit "unconfigured" \
      "deadcode found no executable main package — it analyzes reachability from an executable entry point, which a library-only module lacks" \
      "run unused-code from a module with a \`main\` package (or add a test entry); library-only Go has no reachability root for dead-code analysis" 2
  fi
  # deadcode exits 0 even with findings; a non-zero exit that ISN'T the no-main
  # case is a real failure.
  if [ "$d_exit" -ne 0 ]; then
    local r="deadcode exited $d_exit"; [ -n "$d_err" ] && r="$r: $d_err"
    emit_and_exit "failed" "$r" "" 4
  fi
  # Clean prints `null`; findings print a JSON array. Defensive parse.
  if ! printf '%s' "$raw_out" | jq -e 'type == "array" or type == "null"' >/dev/null 2>&1; then
    local r="deadcode produced no parseable JSON"; [ -n "$d_err" ] && r="$r: $d_err"
    emit_and_exit "failed" "$r" "" 4
  fi
  FINDINGS_JSON="$(printf '%s' "$raw_out" | jq -c '
    [ (. // [])[] | (.Funcs // [])[]
      | {file:(.Position.File // null), kind:"unreachable code", name:(.Name // null)}
    ]
  ')"
  local jq_rc=$?
  if [ "$jq_rc" -ne 0 ] || [ -z "$FINDINGS_JSON" ]; then
    emit_and_exit "failed" "deadcode JSON could not be reduced to a findings list (jq exit $jq_rc)" "" 4
  fi
  _emit_count_based "no unreachable code found by deadcode"
}

# Shared tail: count FINDINGS_JSON → findings|clean (with the failed guard).
_emit_count_based() {
  local clean_reason="$1" count
  count="$(printf '%s' "$FINDINGS_JSON" | jq 'length' 2>/dev/null)"
  case "$count" in
    ''|*[!0-9]*) emit_and_exit "failed" "could not count findings from engine output" "" 4 ;;
  esac
  if [ "$count" -gt 0 ]; then
    emit_and_exit "findings" "$count candidate unused item(s) found" "" 1
  else
    emit_and_exit "clean" "$clean_reason" "" 0
  fi
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
case "$STACK" in
  js)     run_js ;;
  python) run_py ;;
  go)     run_go ;;
  *)      emit_and_exit "no-stack" "no supported stack to audit" "" 0 ;;
esac
