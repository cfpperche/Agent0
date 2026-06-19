#!/usr/bin/env bash
# docs/specs/210-validator-multistack-advisory/verify.sh
#
# Mechanical acceptance check for the multi-stack honesty advisory (spec 210).
# Builds throwaway fixtures (NOT committed), runs the validator in each, and
# asserts the multi-stack-advisory fires exactly when it should — and never
# touches the JSON ok/exit. SKIPs gracefully if git/jq absent.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
VALIDATOR="$ROOT/.agent0/validators/run.sh"
CACHE="${TMPDIR:-/tmp}/validator-multistack-fixtures"

pass=0; fail=0
say() { printf '%s\n' "$*"; }
ok()  { pass=$((pass+1)); say "  PASS: $1"; }
bad() { fail=$((fail+1)); say "  FAIL: $1"; }

[ -f "$VALIDATOR" ] || { say "verify: validator not found at $VALIDATOR"; exit 1; }
command -v jq >/dev/null 2>&1 || { say "verify: SKIP — jq not installed"; exit 0; }
command -v git >/dev/null 2>&1 || { say "verify: SKIP — git not installed"; exit 0; }

reset_dir() { rm -rf "$1" 2>/dev/null; mkdir -p "$1"; }  # OVERRIDE: throwaway fixture under TMPDIR
init_git() { ( cd "$1" && git init -q && git add -A && git -c user.email=v@v -c user.name=v commit -qm x >/dev/null 2>&1 ); }

# returns advisory line (or empty) on stdout; sets global LAST_STDERR/LAST_JSON
run_validator() {
  local dir="$1"; shift
  LAST_STDERR="$( cd "$dir" && env "$@" bash "$VALIDATOR" 2>/tmp/.ms-verify-err.$$ >/tmp/.ms-verify-out.$$; cat /tmp/.ms-verify-err.$$ )"
  LAST_JSON="$(cat /tmp/.ms-verify-out.$$)"
  rm -f /tmp/.ms-verify-err.$$ /tmp/.ms-verify-out.$$ 2>/dev/null
}

# --- (a) polyglot + subtree: advisory fires, names both sides, ok/exit intact -
D="$CACHE/poly"; reset_dir "$D"
printf '{"name":"web","version":"1.0.0"}\n' > "$D/package.json"
mkdir -p "$D/services/api"
printf '{"name":"acme/api"}\n' > "$D/services/api/composer.json"
init_git "$D"
run_validator "$D"
if printf '%s' "$LAST_STDERR" | grep -q 'multi-stack-advisory:'; then
  ok "polyglot+subtree emits multi-stack-advisory"
else
  bad "polyglot+subtree did NOT emit advisory (stderr: $LAST_STDERR)"
fi
printf '%s' "$LAST_STDERR" | grep -q "php" && ok "advisory names the subtree (php) stack" || bad "advisory missing subtree stack 'php'"
printf '%s' "$LAST_STDERR" | grep -qE "audited only '(js)'" && ok "advisory names audited stack (js)" || bad "advisory missing audited stack"
# ok/exit IDENTICAL between advisory-on and opt-out (proves non-blocking) —
# the advisory must not change the validation result, only add a stderr line.
on_ok="$(printf '%s' "$LAST_JSON" | jq -c '{ok,exit}')"
run_validator "$D" CLAUDE_VALIDATOR_SKIP_MULTISTACK=1
off_ok="$(printf '%s' "$LAST_JSON" | jq -c '{ok,exit}')"
[ -n "$on_ok" ] && [ "$on_ok" = "$off_ok" ] && ok "advisory non-blocking: ok/exit identical on-vs-opt-out ($on_ok)" || bad "advisory changed ok/exit (on=$on_ok off=$off_ok)"

# --- (b) declarative validator.json present → NO advisory --------------------
D="$CACHE/declarative"; reset_dir "$D"
printf '{"name":"web","version":"1.0.0"}\n' > "$D/package.json"
mkdir -p "$D/services/api"; printf '{"name":"acme/api"}\n' > "$D/services/api/composer.json"
mkdir -p "$D/.agent0"; printf '{"commands":{"test":"true"}}\n' > "$D/.agent0/validator.json"
init_git "$D"
run_validator "$D"
printf '%s' "$LAST_STDERR" | grep -q 'multi-stack-advisory:' && bad "declarative path wrongly emitted advisory" || ok "declarative validator.json → no advisory"

# --- (c) single-stack → NO advisory -----------------------------------------
D="$CACHE/single"; reset_dir "$D"
printf '{"name":"web","version":"1.0.0"}\n' > "$D/package.json"
init_git "$D"
run_validator "$D"
printf '%s' "$LAST_STDERR" | grep -q 'multi-stack-advisory:' && bad "single-stack wrongly emitted advisory" || ok "single-stack → no advisory"

# --- (d) git absent → graceful + root-degrade detection actually works -------
D="$CACHE/nogit"; reset_dir "$D"
printf '{"name":"web","version":"1.0.0"}\n' > "$D/package.json"
printf '{"name":"acme/api"}\n' > "$D/composer.json"   # both at root so root-degrade can see them
run_validator "$D"   # NOT git-init'd → in_git_repo=0 → root-marker degrade
printf '%s' "$LAST_JSON" | jq -e 'has("ok")' >/dev/null 2>&1 && ok "git-absent: validator still emits valid JSON (no crash)" || bad "git-absent broke the validator"
printf '%s' "$LAST_STDERR" | grep -q 'multi-stack-advisory:' && ok "git-absent: root-marker degrade still detects + advises" || bad "git-absent root-degrade did not advise (stderr: $LAST_STDERR)"

# --- (f) codex guard: stray non-fallback marker (tools/setup.py) → NO python --
# Detector mirrors the fallback EXACTLY; setup.py is not a fallback marker.
D="$CACHE/stray"; reset_dir "$D"
printf '{"name":"web","version":"1.0.0"}\n' > "$D/package.json"
mkdir -p "$D/tools"; printf 'print(1)\n' > "$D/tools/setup.py"
init_git "$D"
run_validator "$D"
printf '%s' "$LAST_STDERR" | grep -q 'multi-stack-advisory:' && bad "stray tools/setup.py wrongly tripped a stack" || ok "stray non-fallback marker (setup.py) does not trip advisory"

# --- (g) codex guard: vendored manifest is pruned → NO advisory --------------
D="$CACHE/vendored"; reset_dir "$D"
printf '{"name":"web","version":"1.0.0"}\n' > "$D/package.json"
mkdir -p "$D/vendor/foo"; printf '{"name":"vendored/pkg"}\n' > "$D/vendor/foo/composer.json"
init_git "$D"
run_validator "$D"
printf '%s' "$LAST_STDERR" | grep -q 'multi-stack-advisory:' && bad "vendored composer.json wrongly tripped php" || ok "vendored manifest pruned from detection"

# --- (e) opt-out env → NO advisory ------------------------------------------
D="$CACHE/optout"; reset_dir "$D"
printf '{"name":"web","version":"1.0.0"}\n' > "$D/package.json"
mkdir -p "$D/services/api"; printf '{"name":"acme/api"}\n' > "$D/services/api/composer.json"
init_git "$D"
run_validator "$D" CLAUDE_VALIDATOR_SKIP_MULTISTACK=1
printf '%s' "$LAST_STDERR" | grep -q 'multi-stack-advisory:' && bad "opt-out env did not suppress advisory" || ok "CLAUDE_VALIDATOR_SKIP_MULTISTACK=1 suppresses advisory"

say ""
say "verify: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
