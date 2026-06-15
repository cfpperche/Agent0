#!/usr/bin/env bash
# .agent0/tests/validator-contract/01-declarative-precedence.sh
# Scenario: .agent0/validator.json takes precedence over stack fallback.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
VALIDATOR="$AGENT0_ROOT/.agent0/validators/run.sh"

TMPDIR="$(mktemp -d -t validator-contract-01-XXXXXX)"
stderr_file="$(mktemp)"
trap 'rm -rf "$TMPDIR" "$stderr_file"' EXIT

mkdir -p "$TMPDIR/.agent0" "$TMPDIR/bin"
touch "$TMPDIR/pnpm-lock.yaml"
cat > "$TMPDIR/bin/pnpm" <<'EOF'
#!/usr/bin/env bash
printf 'implicit pnpm fallback should not run\n' >&2
exit 9
EOF
chmod +x "$TMPDIR/bin/pnpm"

cat > "$TMPDIR/.agent0/validator.json" <<'EOF'
{
  "commands": {
    "test": "printf declared-test",
    "typecheck": "printf declared-typecheck"
  }
}
EOF

( cd "$TMPDIR" && PATH="$TMPDIR/bin:$PATH" bash "$VALIDATOR" >"$TMPDIR/out.json" 2>"$stderr_file" )

cmd="$(jq -r '.command' "$TMPDIR/out.json")"
ok="$(jq -r '.ok' "$TMPDIR/out.json")"
stdout="$(jq -r '.stdout' "$TMPDIR/out.json")"

if [ "$cmd" != "printf declared-test && printf declared-typecheck" ]; then
  printf 'FAIL: command should use declared pipeline, got: %s\n' "$cmd"
  exit 1
fi

if [ "$ok" != "true" ]; then
  printf 'FAIL: ok should be true, got: %s\n' "$ok"
  exit 1
fi

if ! printf '%s' "$stdout" | grep -q 'declared-testdeclared-typecheck'; then
  printf 'FAIL: stdout should show declared commands ran, got: %s\n' "$stdout"
  exit 1
fi

if grep -q 'implicit pnpm fallback should not run' "$stderr_file" "$TMPDIR/out.json"; then
  printf 'FAIL: stack fallback ran despite .agent0/validator.json\n'
  exit 1
fi

printf 'PASS\n'
exit 0
