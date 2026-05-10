#!/usr/bin/env bash
# .claude/validators/run.sh
# Stack auto-detect validator. Emits one JSON object on stdout per the
# documented contract (docs/specs/002-delegation/plan.md § "Validator JSON contract").
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
if [ -f "bun.lockb" ] || [ -f "bunfig.toml" ]; then
  if [ -f "tsconfig.json" ]; then
    command_str='bun test && bun tsc --noEmit'
  else
    command_str='bun test && bun run typecheck'
  fi
elif [ -f "pnpm-lock.yaml" ]; then
  if [ -f "tsconfig.json" ]; then
    command_str='pnpm test && pnpm tsc --noEmit'
  else
    command_str='pnpm test && pnpm typecheck'
  fi
elif [ -f "package-lock.json" ] || [ -f "package.json" ]; then
  command_str='npm test --silent && npm run typecheck'
elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
  command_str='python -m pytest -q && python -m mypy . || true'
elif [ -f "go.mod" ]; then
  command_str='go test ./... && go vet ./...'
elif [ -f "Cargo.toml" ]; then
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

jq -n \
  --argjson ok "$ok_value" \
  --arg command "$command_str" \
  --argjson exit "$exit_code" \
  --argjson duration_ms "$duration_ms" \
  --arg stdout "$stdout_tail" \
  --arg stderr "$stderr_tail" \
  '{ok:$ok,command:$command,exit:$exit,duration_ms:$duration_ms,stdout:$stdout,stderr:$stderr}'

exit 0
