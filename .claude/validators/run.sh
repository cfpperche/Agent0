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
if [ -f "bun.lockb" ] || [ -f "bun.lock" ] || [ -f "bunfig.toml" ]; then
  stack="js"
  if [ -f "tsconfig.json" ]; then
    command_str='bun test && bun tsc --noEmit'
  else
    command_str='bun test && bun run typecheck'
  fi
elif [ -f "pnpm-lock.yaml" ]; then
  stack="js"
  if [ -f "tsconfig.json" ]; then
    command_str='pnpm test && pnpm tsc --noEmit'
  else
    command_str='pnpm test && pnpm typecheck'
  fi
elif [ -f "package-lock.json" ] || [ -f "package.json" ]; then
  stack="js"
  command_str='npm test --silent && npm run typecheck'
elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
  stack="python"
  command_str='python -m pytest -q && python -m mypy . || true'
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

stdout_file="$(mktemp 2>/dev/null || mktemp -t validator-stdout)"
stderr_file="$(mktemp 2>/dev/null || mktemp -t validator-stderr)"
trap 'rm -f "$stdout_file" "$stderr_file"' EXIT

# Portable millisecond clock: `date +%s%3N` is GNU-only; fall back to seconds*1000 on macOS.
now_ms() {
  if date +%s%3N 2>/dev/null | grep -qE '^[0-9]+$'; then
    date +%s%3N
  else
    echo $(( $(date +%s) * 1000 ))
  fi
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
