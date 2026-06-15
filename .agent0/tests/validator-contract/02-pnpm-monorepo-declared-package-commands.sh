#!/usr/bin/env bash
# .agent0/tests/validator-contract/02-pnpm-monorepo-declared-package-commands.sh
# Scenario: pnpm monorepo owns package-scoped validator commands.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
VALIDATOR="$AGENT0_ROOT/.agent0/validators/run.sh"

TMPDIR="$(mktemp -d -t validator-contract-02-XXXXXX)"
stderr_file="$(mktemp)"
trap 'rm -rf "$TMPDIR" "$stderr_file"' EXIT

mkdir -p "$TMPDIR/.agent0" "$TMPDIR/apps/web" "$TMPDIR/bin"
touch "$TMPDIR/pnpm-lock.yaml"
cat > "$TMPDIR/package.json" <<'EOF'
{"name":"monorepo-root","private":true,"scripts":{"typecheck":"turbo run typecheck"}}
EOF
cat > "$TMPDIR/apps/web/package.json" <<'EOF'
{"name":"@example/web","scripts":{"test:unit":"node --test \"lib/**/*.test.ts\""}}
EOF
cat > "$TMPDIR/bin/pnpm" <<'EOF'
#!/usr/bin/env bash
printf 'pnpm %s\n' "$*"
exit 0
EOF
chmod +x "$TMPDIR/bin/pnpm"
cat > "$TMPDIR/.agent0/validator.json" <<'EOF'
{
  "commands": {
    "test": "pnpm --filter @example/web test:unit",
    "typecheck": "pnpm --filter @example/web typecheck",
    "lint": "pnpm --filter @example/web lint"
  }
}
EOF

( cd "$TMPDIR" && PATH="$TMPDIR/bin:$PATH" bash "$VALIDATOR" >"$TMPDIR/out.json" 2>"$stderr_file" )

cmd="$(jq -r '.command' "$TMPDIR/out.json")"
ok="$(jq -r '.ok' "$TMPDIR/out.json")"

expected="pnpm --filter @example/web test:unit && pnpm --filter @example/web typecheck && pnpm --filter @example/web lint"
if [ "$cmd" != "$expected" ]; then
  printf 'FAIL: command mismatch.\nexpected: %s\ngot:      %s\n' "$expected" "$cmd"
  exit 1
fi

if [ "$ok" != "true" ]; then
  printf 'FAIL: ok should be true, got: %s\n' "$ok"
  exit 1
fi

if grep -qF 'test-advisory:' "$stderr_file"; then
  printf 'FAIL: declarative contract should not emit root-test fallback advisory. stderr: %s\n' "$(cat "$stderr_file")"
  exit 1
fi

printf 'PASS\n'
exit 0
