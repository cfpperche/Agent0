#!/usr/bin/env bash
# .claude/validators/run.sh
# Stack auto-detect validator. Emits one JSON object on stdout per the
# documented contract (docs/specs/002-delegation/plan.md § "Validator JSON contract"
# extended by docs/specs/005-tdd/plan.md § "Validator JSON contract — additive change").
#
# Detect order (first match wins): bun → pnpm → npm → python → go → rust.
# When no marker is found, emits the no-stack-detected fallback (ok=true) so
# the consuming hook fails open.
#
# bash 3.2-compatible: no associative arrays, no mapfile.

set -uo pipefail

emit_no_stack() {
  printf '{"ok":true,"command":"no-stack-detected","exit":0,"duration_ms":0,"stdout":"","stderr":""}\n'
  exit 0
}

if ! command -v jq >/dev/null 2>&1; then
  emit_no_stack
fi

command_str=""
stack=""
stack_subtype=""
typecheck_advisory_msg=""

# Manifest-as-intent typecheck dispatch (mirrors spec 013 lint-validator):
#   (a) tsconfig.json exists                 → use direct tsc invocation
#   (b) package.json `.scripts.typecheck`    → use `<runner> run typecheck`
#   (c) neither                              → omit typecheck step + advisory
# State (c) replaces the pre-fix hard-failure path where `<runner> run typecheck`
# always landed in the pipeline, breaking validators on early-stage forks
# without typecheck infrastructure (surfaced by shrnk-mono dogfood 2026-05-12).
has_typecheck_script() {
  [ -f "package.json" ] && jq -e '.scripts.typecheck // empty' package.json >/dev/null 2>&1
}

if [ -f "bun.lockb" ] || [ -f "bun.lock" ] || [ -f "bunfig.toml" ]; then
  stack="js"
  stack_subtype="bun"
  if [ -f "tsconfig.json" ]; then
    command_str='bun test && bun tsc --noEmit'
  elif has_typecheck_script; then
    command_str='bun test && bun run typecheck'
  else
    command_str='bun test'
    typecheck_advisory_msg="typecheck-advisory: no tsconfig.json or 'typecheck' script in package.json — typecheck step skipped (add a tsconfig.json or declare \`bun run typecheck\` to enable)"
  fi
elif [ -f "pnpm-lock.yaml" ]; then
  stack="js"
  stack_subtype="pnpm"
  if [ -f "tsconfig.json" ]; then
    command_str='pnpm test && pnpm tsc --noEmit'
  elif has_typecheck_script; then
    command_str='pnpm test && pnpm typecheck'
  else
    command_str='pnpm test'
    typecheck_advisory_msg="typecheck-advisory: no tsconfig.json or 'typecheck' script in package.json — typecheck step skipped (add a tsconfig.json or declare \`pnpm typecheck\` to enable)"
  fi
elif [ -f "package-lock.json" ] || [ -f "package.json" ]; then
  stack="js"
  stack_subtype="npm"
  # npm path is conservative: rely on declared `typecheck` script rather than
  # `npx tsc` (npx is a separate binary from npm and adds resolution surprises
  # when TypeScript isn't installed locally). Forks on npm declare typecheck
  # in scripts; bun/pnpm get the tsconfig fast-path because their runners
  # invoke local node_modules/.bin/tsc directly.
  if has_typecheck_script; then
    command_str='npm test --silent && npm run typecheck'
  else
    command_str='npm test --silent'
    typecheck_advisory_msg="typecheck-advisory: no 'typecheck' script in package.json — typecheck step skipped (declare \`npm run typecheck\` to enable)"
  fi
elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
  stack="python"
  # Detect venv-style project managers (first lockfile match wins). Falls back
  # to bare `python` when no wrapper is found, preserving system-Python behavior.
  py_prefix="python"
  if { [ -f "uv.lock" ] || [ -d ".venv" ]; } && command -v uv >/dev/null 2>&1; then
    py_prefix="uv run python"
  elif [ -f "poetry.lock" ] && command -v poetry >/dev/null 2>&1; then
    py_prefix="poetry run python"
  elif [ -f "pdm.lock" ] && command -v pdm >/dev/null 2>&1; then
    py_prefix="pdm run python"
  fi
  # Make mypy non-blocking (advisory only) while pytest stays a real gate.
  # Brace group localises `|| true` to the mypy step; the prior shape
  # (`pytest && mypy || true`) collapsed pytest failures into exit 0.
  command_str="$py_prefix -m pytest -q && { $py_prefix -m mypy . || true; }"
elif [ -f "go.mod" ]; then
  stack="go"
  command_str='go test ./... && go vet ./...'
elif [ -f "Cargo.toml" ]; then
  stack="rust"
  command_str='cargo test --quiet && cargo clippy -q -- -D warnings'
fi

if [ -z "$command_str" ]; then
  emit_no_stack
fi

# --- Lint extension (spec 013) ----------------------------------------------
# Manifest-as-intent: linter declared in the manifest is the canonical signal
# this fork wants lint enforcement. Filesystem (`node_modules/...`, `python -m
# ruff --version`) is the secondary "installed?" probe used only after
# declaration is confirmed. Three states per stack:
#   (a) declared + installed → append `<runner> <linter> check` to command_str
#   (b) declared + missing   → emit `lint-advisory:` to stderr, do NOT append
#   (c) not declared         → silent skip
# Opt-out: CLAUDE_VALIDATOR_SKIP_LINT=1 short-circuits before any detection.
lint_advisory_msg=""
if [ "${CLAUDE_VALIDATOR_SKIP_LINT:-0}" != "1" ]; then
  if [ "$stack" = "js" ]; then
    if [ -f "package.json" ] && jq -e '.devDependencies["@biomejs/biome"] // .dependencies["@biomejs/biome"] // empty' package.json >/dev/null 2>&1; then
      if [ -f "node_modules/@biomejs/biome/package.json" ]; then
        case "$stack_subtype" in
          bun)  command_str="$command_str && bunx biome check" ;;
          pnpm) command_str="$command_str && pnpm exec biome check" ;;
          npm)  command_str="$command_str && npx biome check" ;;
        esac
      else
        case "$stack_subtype" in
          bun)  install_cmd="bun install" ;;
          pnpm) install_cmd="pnpm install" ;;
          npm)  install_cmd="npm install" ;;
          *)    install_cmd="npm install" ;;
        esac
        lint_advisory_msg="lint-advisory: biome declared in package.json but not installed — run \`$install_cmd\`"
      fi
    fi
  elif [ "$stack" = "python" ]; then
    ruff_declared=0
    ruff_manifest=""
    for manifest in pyproject.toml requirements.txt; do
      [ -f "$manifest" ] || continue
      if grep -qiE '(^[[:space:]]*ruff([[:space:]=<>~!]|$)|"ruff"|"ruff[<>=~!])' "$manifest" 2>/dev/null; then
        ruff_declared=1
        ruff_manifest="$manifest"
        break
      fi
    done
    # Also scan requirements*.txt variants (dev-requirements.txt, etc.)
    if [ "$ruff_declared" -eq 0 ]; then
      for manifest in requirements*.txt; do
        [ -f "$manifest" ] || continue
        if grep -qiE '(^[[:space:]]*ruff([[:space:]=<>~!]|$)|"ruff"|"ruff[<>=~!])' "$manifest" 2>/dev/null; then
          ruff_declared=1
          ruff_manifest="$manifest"
          break
        fi
      done
    fi

    if [ "$ruff_declared" -eq 1 ]; then
      if $py_prefix -m ruff --version >/dev/null 2>&1; then
        command_str="$command_str && $py_prefix -m ruff check ."
      else
        py_install_cmd="pip install ruff"
        if [ -f "uv.lock" ] && command -v uv >/dev/null 2>&1; then
          py_install_cmd="uv sync"
        elif [ -f "poetry.lock" ] && command -v poetry >/dev/null 2>&1; then
          py_install_cmd="poetry install"
        elif [ -f "pdm.lock" ] && command -v pdm >/dev/null 2>&1; then
          py_install_cmd="pdm install"
        fi
        lint_advisory_msg="lint-advisory: ruff declared in $ruff_manifest but not installed — run \`$py_install_cmd\`"
      fi
    fi
  fi
fi

# Surface advisories on stderr BEFORE running the pipeline. Captured by the
# post-edit hook (which redirects validator stderr separately from stdout so
# JSON parsing stays clean) and ingested into the agent's next-turn context.
# Multiple advisories can fire in the same run (e.g. lint declared+missing
# AND no typecheck primitive); each emits its own line, agent reads all.
if [ -n "$lint_advisory_msg" ]; then
  printf '%s\n' "$lint_advisory_msg" >&2
fi
if [ -n "$typecheck_advisory_msg" ]; then
  printf '%s\n' "$typecheck_advisory_msg" >&2
fi

stdout_file="$(mktemp 2>/dev/null || mktemp -t validator-stdout)"
stderr_file="$(mktemp 2>/dev/null || mktemp -t validator-stderr)"
trap 'rm -f "$stdout_file" "$stderr_file"' EXIT

# Portable millisecond clock. Computes (seconds * 1000) + (nanoseconds / 1_000_000).
# Avoids `date +%s%3N` because the `%3N` precision specifier is silently dropped
# on some platforms (observed on WSL2 GNU coreutils 2026-05) leaving full 9-digit
# nanoseconds appended — the regex `^[0-9]+$` cannot distinguish the two shapes.
# Using `%s` + `%N` separately and reducing in shell arithmetic is unambiguous.
# On BSD/macOS `%N` returns the literal `%N`; the regex check falls back to ms=0.
now_ms() {
  local secs nanos ms
  secs=$(date +%s)
  nanos=$(date +%N 2>/dev/null)
  if [[ "$nanos" =~ ^[0-9]+$ ]]; then
    # `10#` forces base-10 to avoid octal-parse on leading-zero nanos (e.g. "045123456").
    ms=$((10#$nanos / 1000000))
  else
    ms=0
  fi
  echo $((secs * 1000 + ms))
}

start_ms="$(now_ms)"
bash -c "$command_str" >"$stdout_file" 2>"$stderr_file"
exit_code=$?
end_ms="$(now_ms)"
duration_ms=$(( end_ms - start_ms ))

# Truncate to last ~4096 bytes; tail -c is in POSIX coreutils on Linux and macOS.
stdout_tail="$(tail -c 4096 "$stdout_file" 2>/dev/null || true)"
stderr_tail="$(tail -c 4096 "$stderr_file" 2>/dev/null || true)"

ok_value="false"
[ "$exit_code" -eq 0 ] && ok_value="true"

# --- TDD warning detection (spec 005) ---------------------------------------
# Skip entirely when not in a git repo: git diff is the signal source, and
# emitting an empty/misleading warnings field outside a repo is worse than
# omitting it. Hook treats missing `warnings` as "no advisory".
warnings_json=""
if git rev-parse --git-dir >/dev/null 2>&1; then
  case "$stack" in
    js)       default_patterns='*.test.ts *.test.tsx *.test.js *.test.jsx *.spec.ts *.spec.tsx *.spec.js *.spec.jsx __tests__/* tests/* test/*' ;;
    python)   default_patterns='*_test.py test_*.py tests/* test/*' ;;
    go)       default_patterns='*_test.go' ;;
    rust)     default_patterns='tests/* *_test.rs *_tests.rs' ;;
    *)        default_patterns='' ;;
  esac

  if [ -n "${CLAUDE_TDD_TEST_PATTERNS:-}" ]; then
    patterns_str="$CLAUDE_TDD_TEST_PATTERNS"
  else
    patterns_str="$default_patterns"
  fi

  # Modified-tracked + untracked-not-ignored, deduped. A sub-agent that uses
  # the Write tool to create a new test file leaves it untracked, so plain
  # `git diff` would miss it and the warning would falsely fire. Including
  # `ls-files --others --exclude-standard` closes that gap.
  changed_files="$(
    ( git diff --name-only 2>/dev/null
      git ls-files --others --exclude-standard 2>/dev/null
    ) | sort -u || true
  )"

  prod_files=""
  test_count=0
  excluded_globs='*.md *.txt *.json *.yml *.yaml *.toml LICENSE *.gitignore .gitkeep'

  old_ifs="$IFS"
  IFS='
'
  for f in $changed_files; do
    [ -z "$f" ] && continue

    is_excluded=0
    IFS=' '
    for g in $excluded_globs; do
      case "$f" in
        $g) is_excluded=1; break ;;
      esac
    done
    IFS='
'
    [ "$is_excluded" -eq 1 ] && continue

    is_test=0
    IFS=' '
    for g in $patterns_str; do
      case "$f" in
        $g) is_test=1; break ;;
      esac
    done
    IFS='
'
    if [ "$is_test" -eq 1 ]; then
      test_count=$(( test_count + 1 ))
    else
      if [ -z "$prod_files" ]; then
        prod_files="$f"
      else
        prod_files="$prod_files
$f"
      fi
    fi
  done
  IFS="$old_ifs"

  if [ -n "$prod_files" ] && [ "$test_count" -eq 0 ]; then
    files_json="$(printf '%s\n' "$prod_files" | jq -R . | jq -s .)"
    msg='Production files changed without any test changes in this session diff. If the change is genuinely test-exempt (rename, comment, refactor without behavior change), no action needed; otherwise, consider adding a test. See .claude/rules/tdd.md.'
    warnings_json="$(jq -n --argjson files "$files_json" --arg msg "$msg" \
      '[{kind:"no_test_change_for_prod_edit",files:$files,message:$msg}]')"
  else
    warnings_json='[]'
  fi
fi

if [ -n "$warnings_json" ]; then
  jq -n \
    --argjson ok "$ok_value" \
    --arg command "$command_str" \
    --argjson exit "$exit_code" \
    --argjson duration_ms "$duration_ms" \
    --arg stdout "$stdout_tail" \
    --arg stderr "$stderr_tail" \
    --argjson warnings "$warnings_json" \
    '{ok:$ok,command:$command,exit:$exit,duration_ms:$duration_ms,stdout:$stdout,stderr:$stderr,warnings:$warnings}'
else
  jq -n \
    --argjson ok "$ok_value" \
    --arg command "$command_str" \
    --argjson exit "$exit_code" \
    --argjson duration_ms "$duration_ms" \
    --arg stdout "$stdout_tail" \
    --arg stderr "$stderr_tail" \
    '{ok:$ok,command:$command,exit:$exit,duration_ms:$duration_ms,stdout:$stdout,stderr:$stderr}'
fi

exit 0
