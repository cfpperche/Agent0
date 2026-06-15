#!/usr/bin/env bash
# .agent0/tests/validator-contract/05-legacy-fallback-without-config.sh
# Scenario: no .agent0/validator.json preserves stack fallback behavior.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
VALIDATOR="$AGENT0_ROOT/.agent0/validators/run.sh"

TMPDIR="$(mktemp -d -t validator-contract-05-XXXXXX)"
stderr_file="$(mktemp)"
trap 'rm -rf "$TMPDIR" "$stderr_file"' EXIT

mkdir -p "$TMPDIR/bin"
touch "$TMPDIR/pnpm-lock.yaml"
cat > "$TMPDIR/package.json" <<'EOF'
{"name":"legacy-root","scripts":{"test":"true"}}
EOF
cat > "$TMPDIR/bin/pnpm" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$TMPDIR/bin/pnpm"

( cd "$TMPDIR" && PATH="$TMPDIR/bin:$PATH" bash "$VALIDATOR" >"$TMPDIR/out.json" 2>"$stderr_file" )

cmd="$(jq -r '.command' "$TMPDIR/out.json")"
ok="$(jq -r '.ok' "$TMPDIR/out.json")"

if [ "$cmd" != "pnpm test" ]; then
  printf 'FAIL: legacy fallback should still run pnpm test, got: %s\n' "$cmd"
  exit 1
fi

if [ "$ok" != "true" ]; then
  printf 'FAIL: ok should be true, got: %s\n' "$ok"
  exit 1
fi

printf 'PASS\n'
exit 0
