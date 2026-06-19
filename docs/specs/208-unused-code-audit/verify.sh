#!/usr/bin/env bash
# docs/specs/208-unused-code-audit/verify.sh
#
# Mechanical acceptance check for the unused-code capacity (spec 208).
# Builds throwaway JS/TS fixtures (NOT committed — under a temp cache dir),
# installs knip once (reused on re-runs), and asserts that the engine
# .agent0/tools/unused-code.sh reports the spec'd status for each scenario:
#   findings | clean | unconfigured | unavailable | no-stack | failed
#
# Opt-in spec-verify target (tasks.md **Verify:** line). Runs from repo root.
# SKIPs gracefully (exit 0) when node/npm is absent so the check never
# false-fails on a host without the JS toolchain.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
ENGINE="$ROOT/.agent0/tools/unused-code.sh"
CACHE="${TMPDIR:-/tmp}/unused-code-verify-fixtures"

pass=0; fail=0
say() { printf '%s\n' "$*"; }
ok()  { pass=$((pass+1)); say "  PASS: $1"; }
bad() { fail=$((fail+1)); say "  FAIL: $1"; }

[ -f "$ENGINE" ] || { say "verify: engine not found at $ENGINE"; exit 1; }

if ! command -v jq >/dev/null 2>&1; then say "verify: SKIP — jq not installed"; exit 0; fi
if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
  say "verify: SKIP — node/npm not installed (JS toolchain required for knip fixtures)"; exit 0
fi

# --- status assertion helper ------------------------------------------------
# $1 = fixture dir, $2 = expected status
expect_status() {
  local dir="$1" want="$2" got
  got="$(bash "$ENGINE" "$dir" --json 2>/dev/null | jq -r '.status')"
  if [ "$got" = "$want" ]; then ok "$want ($dir)"; else bad "expected $want, got '$got' ($dir)"; fi
}

# --- build fixtures (idempotent; install knip once) -------------------------
mkdir -p "$CACHE"
if [ ! -d "$CACHE/_engine/node_modules/knip" ]; then
  say "verify: installing knip into fixture cache (first run, ~60s)..."
  mkdir -p "$CACHE/_engine"
  ( cd "$CACHE/_engine"
    printf '{"name":"uc-engine","version":"1.0.0","type":"module","devDependencies":{"knip":"^6"}}\n' > package.json
    npm install --silent --no-audit --no-fund >/dev/null 2>&1 )
fi
if [ ! -d "$CACHE/_engine/node_modules/knip" ]; then
  say "verify: SKIP — knip could not be installed (offline?)"; exit 0
fi
KNIP_NM="$CACHE/_engine/node_modules"

# findings: unused file + unused export + unused dependency
mkdir -p "$CACHE/findings"
printf '{"name":"f","version":"1.0.0","type":"module","dependencies":{"lodash":"^4.17.21"},"devDependencies":{"knip":"^6"}}\n' > "$CACHE/findings/package.json"
printf '{ "entry": ["index.js"], "project": ["**/*.js"] }\n' > "$CACHE/findings/knip.json"
printf "import { used } from './helper.js';\nexport function main() { return used(); }\n" > "$CACHE/findings/index.js"
printf 'export function used() { return 1; }\nexport function unusedHelper() { return 2; }\n' > "$CACHE/findings/helper.js"
printf 'export const x = 1;\n' > "$CACHE/findings/orphan.js"
ln -sfn "$KNIP_NM" "$CACHE/findings/node_modules"

# clean: config + everything used, no unused dep
mkdir -p "$CACHE/clean"
printf '{"name":"c","version":"1.0.0","type":"module","devDependencies":{"knip":"^6"}}\n' > "$CACHE/clean/package.json"
printf '{ "entry": ["index.js"], "project": ["**/*.js"] }\n' > "$CACHE/clean/knip.json"
printf "import { used } from './helper.js';\nexport function main() { return used(); }\n" > "$CACHE/clean/index.js"
printf 'export function used() { return 1; }\n' > "$CACHE/clean/helper.js"
ln -sfn "$KNIP_NM" "$CACHE/clean/node_modules"

# unconfigured: knip present, NO knip config, no package.json#knip key
mkdir -p "$CACHE/unconfigured"
printf '{"name":"u","version":"1.0.0","type":"module","devDependencies":{"knip":"^6"}}\n' > "$CACHE/unconfigured/package.json"
printf 'export const x = 1;\n' > "$CACHE/unconfigured/index.js"
ln -sfn "$KNIP_NM" "$CACHE/unconfigured/node_modules"

# unavailable: JS project, no knip resolvable
mkdir -p "$CACHE/unavailable"
printf '{"name":"un","version":"1.0.0","type":"module"}\n' > "$CACHE/unavailable/package.json"

# no-stack: no package.json
mkdir -p "$CACHE/nostack"
rm -f "$CACHE/nostack/package.json" 2>/dev/null

# failed: stub a knip on PATH that emits non-JSON, in a configured JS project
mkdir -p "$CACHE/failed/bin"
printf '{"name":"x","version":"1.0.0","type":"module","devDependencies":{"knip":"^6"}}\n' > "$CACHE/failed/package.json"
printf '{ "entry": ["index.js"], "project": ["**/*.js"] }\n' > "$CACHE/failed/knip.json"
printf 'export const x = 1;\n' > "$CACHE/failed/index.js"
mkdir -p "$CACHE/failed/node_modules/.bin"
printf '#!/usr/bin/env bash\necho "boom not json" >&2\nexit 2\n' > "$CACHE/failed/node_modules/.bin/knip"
chmod +x "$CACHE/failed/node_modules/.bin/knip"

# failed2 (codex BLOCKER 1 regression guard): knip exits 2 but prints VALID
# empty JSON. Must be `failed`, NOT `clean` — exit code is authoritative for
# engine failure even when the JSON parses.
mkdir -p "$CACHE/failed2/node_modules/.bin"
printf '{"name":"x2","version":"1.0.0","type":"module","devDependencies":{"knip":"^6"}}\n' > "$CACHE/failed2/package.json"
printf '{ "entry": ["index.js"], "project": ["**/*.js"] }\n' > "$CACHE/failed2/knip.json"
printf 'export const x = 1;\n' > "$CACHE/failed2/index.js"
printf '#!/usr/bin/env bash\necho "{\\"issues\\":[]}"\nexit 2\n' > "$CACHE/failed2/node_modules/.bin/knip"
chmod +x "$CACHE/failed2/node_modules/.bin/knip"

# --- assertions -------------------------------------------------------------
say "verify: asserting status per scenario..."
expect_status "$CACHE/findings"     "findings"
expect_status "$CACHE/clean"        "clean"
expect_status "$CACHE/unconfigured" "unconfigured"
expect_status "$CACHE/unavailable"  "unavailable"
expect_status "$CACHE/nostack"      "no-stack"
expect_status "$CACHE/failed"       "failed"
expect_status "$CACHE/failed2"      "failed"

# default exit is 0 for EVERY result status (advisory family)
for d in findings clean unconfigured unavailable nostack failed; do
  bash "$ENGINE" "$CACHE/$d" >/dev/null 2>&1
  [ $? -eq 0 ] && ok "default exit 0 ($d)" || bad "default exit non-zero ($d)"
done

# --exit-code maps each status to its documented code
check_code() { # dir, expected-code, label
  bash "$ENGINE" "$1" --exit-code >/dev/null 2>&1
  local got=$?
  [ "$got" -eq "$2" ] && ok "--exit-code $3=$2" || bad "--exit-code $3 expected $2 got $got"
}
check_code "$CACHE/clean"        0 clean
check_code "$CACHE/findings"     1 findings
check_code "$CACHE/unconfigured" 2 unconfigured
check_code "$CACHE/unavailable"  3 unavailable
check_code "$CACHE/failed"       4 failed

# scenario-2 proof: per-kind records + "candidate unused" wording + no mutation.
fout="$(bash "$ENGINE" "$CACHE/findings")"
printf '%s' "$fout" | grep -q 'candidate unused' && ok "findings wording says 'candidate unused'" || bad "missing 'candidate unused' wording"
printf '%s' "$fout" | grep -qi 'never deletes' && ok "findings output states it never deletes" || bad "missing never-deletes disclaimer"
kinds="$(bash "$ENGINE" "$CACHE/findings" --json | jq -r '[.findings[].kind]|unique|join(",")')"
case "$kinds" in
  *"unused dependency"*) : ;; *) bad "expected 'unused dependency' kind, got: $kinds" ;;
esac
case "$kinds" in
  *"unused export"*) : ;; *) bad "expected 'unused export' kind, got: $kinds" ;;
esac
case "$kinds" in
  *"unused file"*) ok "per-kind records present ($kinds)" ;; *) bad "expected 'unused file' kind, got: $kinds" ;;
esac

# no-mutation: snapshot the findings fixture before/after a run (excluding the
# symlinked node_modules), assert nothing changed.
snap_before="$(cd "$CACHE/findings" && find . -path ./node_modules -prune -o -type f -print | sort | xargs -I{} sh -c 'printf "%s " "{}"; cat "{}" | cksum' 2>/dev/null | sort)"
bash "$ENGINE" "$CACHE/findings" >/dev/null 2>&1
bash "$ENGINE" "$CACHE/findings" --json >/dev/null 2>&1
snap_after="$(cd "$CACHE/findings" && find . -path ./node_modules -prune -o -type f -print | sort | xargs -I{} sh -c 'printf "%s " "{}"; cat "{}" | cksum' 2>/dev/null | sort)"
[ "$snap_before" = "$snap_after" ] && ok "no source/manifest/config mutation across runs" || bad "fixture files changed across runs"

say ""
say "verify: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
