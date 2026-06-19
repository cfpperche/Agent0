#!/usr/bin/env bash
# docs/specs/209-unused-code-python-go/verify.sh
#
# Mechanical acceptance check for the Python (vulture) + Go (deadcode) extension
# of the unused-code engine (spec 209). Builds throwaway fixtures (NOT committed),
# installs vulture (into a cached venv) and deadcode (into a cached GOBIN) once,
# and asserts the engine reports the spec'd status/shape per scenario. Also
# re-runs the spec-208 suite to prove JS parity (no regression).
#
# Opt-in spec-verify target. SKIPs gracefully (exit 0) when a toolchain is
# absent so it never false-fails on a host without python3/go.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
ENGINE="$ROOT/.agent0/tools/unused-code.sh"
CACHE="${TMPDIR:-/tmp}/unused-code-209-fixtures"

pass=0; fail=0
say() { printf '%s\n' "$*"; }
ok()  { pass=$((pass+1)); say "  PASS: $1"; }
bad() { fail=$((fail+1)); say "  FAIL: $1"; }

[ -f "$ENGINE" ] || { say "verify: engine not found at $ENGINE"; exit 1; }
command -v jq >/dev/null 2>&1 || { say "verify: SKIP — jq not installed"; exit 0; }

st() { bash "$ENGINE" "$1" --json 2>/dev/null | jq -r '.status'; }
expect() { local got; got="$(st "$1")"; [ "$got" = "$2" ] && ok "$2 ($3)" || bad "expected $2, got '$got' ($3)"; }

mkdir -p "$CACHE"

# ---------------- JS parity (delegate to spec-208 verify) -------------------
if [ -f "$ROOT/docs/specs/208-unused-code-audit/verify.sh" ]; then
  if bash "$ROOT/docs/specs/208-unused-code-audit/verify.sh" >/dev/null 2>&1; then
    ok "JS parity — spec-208 verify still green"
  else
    bad "JS parity — spec-208 verify regressed"
  fi
fi

# ---------------- Python (vulture) -----------------------------------------
if command -v python3 >/dev/null 2>&1; then
  if [ ! -x "$CACHE/_venv/bin/vulture" ]; then
    say "verify: installing vulture into fixture venv (first run)..."
    python3 -m venv "$CACHE/_venv" >/dev/null 2>&1
    "$CACHE/_venv/bin/pip" install --quiet vulture >/dev/null 2>&1 || true
  fi
  if [ -x "$CACHE/_venv/bin/vulture" ]; then
    # findings fixture
    mkdir -p "$CACHE/py-find"
    printf '[project]\nname="f"\nversion="0"\n' > "$CACHE/py-find/pyproject.toml"
    printf 'import os\ndef used():\n    return 1\ndef dead():\n    return 2\nprint(used())\n' > "$CACHE/py-find/app.py"
    ln -sfn "$CACHE/_venv" "$CACHE/py-find/.venv"
    expect "$CACHE/py-find" "findings" "python findings"
    # confidence present + heuristic wording
    conf="$(bash "$ENGINE" "$CACHE/py-find" --json | jq -r '[.findings[].confidence]|map(select(.!=null))|length')"
    [ "${conf:-0}" -gt 0 ] && ok "python findings carry confidence" || bad "python confidence missing"
    bash "$ENGINE" "$CACHE/py-find" | grep -qi 'heuristic' && ok "python output flags heuristic" || bad "python heuristic note missing"
    # regression guard (codex BLOCKER/MAJOR): a file with multiple findings incl.
    # unreachable code — none dropped, unreachable carries name:null.
    mkdir -p "$CACHE/py-unr"
    printf '[project]\nname="r"\nversion="0"\n' > "$CACHE/py-unr/pyproject.toml"
    printf 'def f():\n    return 1\n    dead_var = 2\nprint(f())\n' > "$CACHE/py-unr/app.py"
    ln -sfn "$CACHE/_venv" "$CACHE/py-unr/.venv"
    unrj="$(bash "$ENGINE" "$CACHE/py-unr" --json)"
    nfind="$(printf '%s' "$unrj" | jq '.findings|length')"
    [ "${nfind:-0}" -ge 2 ] && ok "python multi-finding not undercounted ($nfind)" || bad "python undercounted findings ($nfind)"
    unrname="$(printf '%s' "$unrj" | jq -r '[.findings[]|select(.kind=="unreachable code")][0].name')"
    [ "$unrname" = "null" ] && ok "python unreachable-code name is null" || bad "python unreachable name not null ($unrname)"
    # clean fixture
    mkdir -p "$CACHE/py-clean"
    printf '[project]\nname="c"\nversion="0"\n' > "$CACHE/py-clean/pyproject.toml"
    printf 'def used():\n    return 1\nprint(used())\n' > "$CACHE/py-clean/app.py"
    ln -sfn "$CACHE/_venv" "$CACHE/py-clean/.venv"
    expect "$CACHE/py-clean" "clean" "python clean"
  else
    say "verify: SKIP python scenarios — vulture could not be installed (offline?)"
  fi
  # unavailable: python project, no vulture resolvable
  mkdir -p "$CACHE/py-unavail"
  printf '[project]\nname="u"\nversion="0"\n' > "$CACHE/py-unavail/pyproject.toml"
  printf 'x = 1\n' > "$CACHE/py-unavail/app.py"
  expect "$CACHE/py-unavail" "unavailable" "python unavailable (no vulture)"
else
  say "verify: SKIP python scenarios — python3 not installed"
fi

# ---------------- Go (deadcode) --------------------------------------------
if command -v go >/dev/null 2>&1; then
  GOBIN_DIR="$CACHE/_gobin"
  if [ ! -x "$GOBIN_DIR/deadcode" ]; then
    say "verify: installing deadcode into fixture GOBIN (first run)..."
    mkdir -p "$GOBIN_DIR"
    GOBIN="$GOBIN_DIR" go install golang.org/x/tools/cmd/deadcode@latest >/dev/null 2>&1 || true
  fi
  if [ -x "$GOBIN_DIR/deadcode" ]; then
    export PATH="$GOBIN_DIR:$PATH"
    # findings
    mkdir -p "$CACHE/go-find"
    printf 'module gofind\n\ngo 1.21\n' > "$CACHE/go-find/go.mod"
    printf 'package main\nimport "fmt"\nfunc used() int { return 1 }\nfunc dead() int { return 2 }\nfunc main(){ fmt.Println(used()) }\n' > "$CACHE/go-find/main.go"
    expect "$CACHE/go-find" "findings" "go findings"
    kind="$(bash "$ENGINE" "$CACHE/go-find" --json | jq -r '.findings[0].kind')"
    [ "$kind" = "unreachable code" ] && ok "go finding kind = unreachable code" || bad "go kind expected 'unreachable code', got '$kind'"
    # clean
    mkdir -p "$CACHE/go-clean"
    printf 'module goclean\n\ngo 1.21\n' > "$CACHE/go-clean/go.mod"
    printf 'package main\nimport "fmt"\nfunc main(){ fmt.Println(1) }\n' > "$CACHE/go-clean/main.go"
    expect "$CACHE/go-clean" "clean" "go clean"
    # library-only → unconfigured (NOT clean)
    mkdir -p "$CACHE/go-lib"
    printf 'module golib\n\ngo 1.21\n' > "$CACHE/go-lib/go.mod"
    printf 'package mylib\nfunc Exported() int { return 1 }\n' > "$CACHE/go-lib/lib.go"
    expect "$CACHE/go-lib" "unconfigured" "go library-only → unconfigured"
  else
    say "verify: SKIP go scenarios — deadcode could not be installed (offline?)"
  fi
  # unavailable: go module, deadcode not on PATH
  mkdir -p "$CACHE/go-unavail"
  printf 'module gounavail\n\ngo 1.21\n' > "$CACHE/go-unavail/go.mod"
  printf 'package main\nfunc main(){}\n' > "$CACHE/go-unavail/main.go"
  ( PATH="$(command -v jq >/dev/null && dirname "$(command -v jq)"):/usr/bin:/bin"; export PATH
    g="$(bash "$ENGINE" "$CACHE/go-unavail" --json 2>/dev/null | jq -r '.status')"
    [ "$g" = "unavailable" ] && exit 0 || exit 1 ) && ok "go unavailable (no deadcode)" || bad "go unavailable not detected"
else
  say "verify: SKIP go scenarios — go not installed"
fi

# ---------------- polyglot note + --stack ----------------------------------
mkdir -p "$CACHE/poly"
printf '[project]\nname="p"\nversion="0"\n' > "$CACHE/poly/pyproject.toml"
printf 'module poly\n\ngo 1.21\n' > "$CACHE/poly/go.mod"
printf 'package main\nfunc main(){}\n' > "$CACHE/poly/main.go"
polyj="$(bash "$ENGINE" "$CACHE/poly" --json 2>/dev/null)"
printf '%s' "$polyj" | jq -e '.note | test("not audited")' >/dev/null 2>&1 && ok "polyglot note surfaces unaudited stacks" || bad "polyglot note missing"
# default audits python (first-match, no js); go must be in unaudited_stacks
printf '%s' "$polyj" | jq -e '.unaudited_stacks | index("go")' >/dev/null 2>&1 && ok "default run: unaudited_stacks includes go" || bad "unaudited_stacks missing go ($(printf '%s' "$polyj" | jq -c '.unaudited_stacks'))"
# forced --stack must STILL surface the others as unaudited (codex finding 1)
fpoly="$(bash "$ENGINE" "$CACHE/poly" --stack go --json 2>/dev/null)"
fstack="$(printf '%s' "$fpoly" | jq -r '.stack')"
[ "$fstack" = "Go" ] && ok "--stack override selects Go" || bad "--stack override failed (got '$fstack')"
printf '%s' "$fpoly" | jq -e '.unaudited_stacks | index("python")' >/dev/null 2>&1 && ok "forced --stack still surfaces unaudited (python)" || bad "forced --stack dropped unaudited_stacks ($(printf '%s' "$fpoly" | jq -c '.unaudited_stacks'))"
# bad --stack is a usage error (exit 64)
bash "$ENGINE" "$CACHE/poly" --stack ruby >/dev/null 2>&1; [ $? -eq 64 ] && ok "bad --stack exits 64" || bad "bad --stack did not exit 64"

# ---------------- no-stack + default-exit-0 --------------------------------
mkdir -p "$CACHE/empty"
expect "$CACHE/empty" "no-stack" "no-stack (empty dir)"
bash "$ENGINE" "$CACHE/empty" >/dev/null 2>&1; [ $? -eq 0 ] && ok "default exit 0 (no-stack)" || bad "default exit non-zero (no-stack)"

say ""
say "verify: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
