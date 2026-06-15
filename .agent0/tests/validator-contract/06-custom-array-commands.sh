#!/usr/bin/env bash
# .agent0/tests/validator-contract/06-custom-array-commands.sh
# Scenario: ordered array commands support consumer-specific validator names.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
VALIDATOR="$AGENT0_ROOT/.agent0/validators/run.sh"

TMPDIR="$(mktemp -d -t validator-contract-06-XXXXXX)"
stderr_file="$(mktemp)"
trap 'rm -rf "$TMPDIR" "$stderr_file"' EXIT

mkdir -p "$TMPDIR/.agent0"
cat > "$TMPDIR/.agent0/validator.json" <<'EOF'
{
  "commands": [
    { "name": "test:unit", "run": "printf unit" },
    { "name": "db:rls", "run": "printf rls" },
    { "name": "ui:projects", "run": "printf ui" }
  ]
}
EOF

( cd "$TMPDIR" && bash "$VALIDATOR" >"$TMPDIR/out.json" 2>"$stderr_file" )

cmd="$(jq -r '.command' "$TMPDIR/out.json")"
ok="$(jq -r '.ok' "$TMPDIR/out.json")"
stdout="$(jq -r '.stdout' "$TMPDIR/out.json")"

expected="printf unit && printf rls && printf ui"
if [ "$cmd" != "$expected" ]; then
  printf 'FAIL: command mismatch.\nexpected: %s\ngot:      %s\n' "$expected" "$cmd"
  exit 1
fi

if [ "$ok" != "true" ]; then
  printf 'FAIL: ok should be true, got: %s\n' "$ok"
  exit 1
fi

if [ "$stdout" != "unitrlsui" ]; then
  printf 'FAIL: stdout should preserve array order, got: %s\n' "$stdout"
  exit 1
fi

printf 'PASS\n'
exit 0
