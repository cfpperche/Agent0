#!/usr/bin/env bash
# .agent0/tests/validator-contract/04-empty-config-fails.sh
# Scenario: existing .agent0/validator.json with no runnable commands fails.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
VALIDATOR="$AGENT0_ROOT/.agent0/validators/run.sh"

TMPDIR="$(mktemp -d -t validator-contract-04-XXXXXX)"
stderr_file="$(mktemp)"
trap 'rm -rf "$TMPDIR" "$stderr_file"' EXIT

mkdir -p "$TMPDIR/.agent0"
cat > "$TMPDIR/.agent0/validator.json" <<'EOF'
{"commands":{}}
EOF

( cd "$TMPDIR" && bash "$VALIDATOR" >"$TMPDIR/out.json" 2>"$stderr_file" )

ok="$(jq -r '.ok' "$TMPDIR/out.json")"

if [ "$ok" != "false" ]; then
  printf 'FAIL: empty config should return ok=false, got: %s\n' "$ok"
  exit 1
fi

if ! grep -qF 'declares no runnable commands' "$stderr_file"; then
  printf 'FAIL: stderr should explain no runnable commands. Got: %s\n' "$(cat "$stderr_file")"
  exit 1
fi

printf 'PASS\n'
exit 0
