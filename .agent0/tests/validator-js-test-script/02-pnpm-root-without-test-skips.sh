#!/usr/bin/env bash
# .agent0/tests/validator-js-test-script/02-pnpm-root-without-test-skips.sh
# Scenario: pnpm root lacks scripts.test -> validator omits pnpm test and advises.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
VALIDATOR="$AGENT0_ROOT/.agent0/validators/run.sh"

TMPDIR="$(mktemp -d -t validator-js-test-02-XXXXXX)"
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
{"name":"root-without-test","scripts":{"typecheck":"true"}}
EOF

( cd "$TMPDIR" && PATH="$TMPDIR/bin:$PATH" bash "$VALIDATOR" >"$TMPDIR/out.json" 2>"$stderr_file" )

cmd="$(jq -r '.command' "$TMPDIR/out.json")"
ok="$(jq -r '.ok' "$TMPDIR/out.json")"

if [ "$cmd" != "pnpm typecheck" ]; then
  printf 'FAIL: command should omit `pnpm test` and run typecheck only, got: %s\n' "$cmd"
  exit 1
fi

if [ "$ok" != "true" ]; then
  printf 'FAIL: ok should be true, got: %s\n' "$ok"
  exit 1
fi

if ! grep -qF "test-advisory: no 'test' script in root package.json" "$stderr_file"; then
  printf 'FAIL: stderr should contain test-advisory. Got: %s\n' "$(cat "$stderr_file")"
  exit 1
fi

printf 'PASS\n'
exit 0
