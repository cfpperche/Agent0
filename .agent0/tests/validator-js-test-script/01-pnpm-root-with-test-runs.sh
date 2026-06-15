#!/usr/bin/env bash
# .agent0/tests/validator-js-test-script/01-pnpm-root-with-test-runs.sh
# Scenario: pnpm root declares scripts.test -> validator keeps running pnpm test.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
VALIDATOR="$AGENT0_ROOT/.agent0/validators/run.sh"

TMPDIR="$(mktemp -d -t validator-js-test-01-XXXXXX)"
stderr_file="$(mktemp)"
trap 'rm -rf "$TMPDIR" "$stderr_file"' EXIT

mkdir -p "$TMPDIR/bin"
cat > "$TMPDIR/bin/pnpm" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$TMPDIR/bin/pnpm"

touch "$TMPDIR/pnpm-lock.yaml"
cat > "$TMPDIR/package.json" <<'EOF'
{"name":"root-with-test","scripts":{"test":"true"}}
EOF

( cd "$TMPDIR" && PATH="$TMPDIR/bin:$PATH" bash "$VALIDATOR" >"$TMPDIR/out.json" 2>"$stderr_file" )

cmd="$(jq -r '.command' "$TMPDIR/out.json")"
ok="$(jq -r '.ok' "$TMPDIR/out.json")"

if [ "$cmd" != "pnpm test" ]; then
  printf 'FAIL: command should keep `pnpm test`, got: %s\n' "$cmd"
  exit 1
fi

if [ "$ok" != "true" ]; then
  printf 'FAIL: ok should be true, got: %s\n' "$ok"
  exit 1
fi

if grep -q 'test-advisory:' "$stderr_file"; then
  printf 'FAIL: stderr should not contain test-advisory when root has scripts.test. Got: %s\n' "$(cat "$stderr_file")"
  exit 1
fi

printf 'PASS\n'
exit 0
