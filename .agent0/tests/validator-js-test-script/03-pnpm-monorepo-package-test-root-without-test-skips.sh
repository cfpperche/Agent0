#!/usr/bin/env bash
# .agent0/tests/validator-js-test-script/03-pnpm-monorepo-package-test-root-without-test-skips.sh
# Scenario: pnpm monorepo package has tests, root lacks scripts.test -> root
# validator still does not infer an implicit pnpm test.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
VALIDATOR="$AGENT0_ROOT/.agent0/validators/run.sh"

TMPDIR="$(mktemp -d -t validator-js-test-03-XXXXXX)"
stderr_file="$(mktemp)"
trap 'rm -rf "$TMPDIR" "$stderr_file"' EXIT

mkdir -p "$TMPDIR/bin" "$TMPDIR/apps/web"
cat > "$TMPDIR/bin/pnpm" <<'EOF'
#!/usr/bin/env bash
printf 'pnpm should not have been called\n' >&2
exit 1
EOF
chmod +x "$TMPDIR/bin/pnpm"

touch "$TMPDIR/pnpm-lock.yaml"
cat > "$TMPDIR/package.json" <<'EOF'
{"name":"monorepo-root","private":true,"workspaces":["apps/*"],"scripts":{"build":"turbo run build"}}
EOF
cat > "$TMPDIR/apps/web/package.json" <<'EOF'
{"name":"@example/web","scripts":{"test":"node --test \"lib/**/*.test.ts\"","test:unit":"node --test \"lib/**/*.test.ts\""}}
EOF

( cd "$TMPDIR" && PATH="$TMPDIR/bin:$PATH" bash "$VALIDATOR" >"$TMPDIR/out.json" 2>"$stderr_file" )

cmd="$(jq -r '.command' "$TMPDIR/out.json")"
ok="$(jq -r '.ok' "$TMPDIR/out.json")"

if [ "$cmd" != "true" ]; then
  printf 'FAIL: command should be no-op true when no root validation stages are declared, got: %s\n' "$cmd"
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

if grep -qF 'pnpm should not have been called' "$TMPDIR/out.json" "$stderr_file"; then
  printf 'FAIL: pnpm shim was called even though root has no scripts.test. stderr: %s\n' "$(cat "$stderr_file")"
  exit 1
fi

printf 'PASS\n'
exit 0
