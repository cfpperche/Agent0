#!/usr/bin/env bash
# .agent0/tests/validator-contract/03-invalid-config-fails.sh
# Scenario: malformed declarative contract fails clearly and never falls back.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
VALIDATOR="$AGENT0_ROOT/.agent0/validators/run.sh"

TMPDIR="$(mktemp -d -t validator-contract-03-XXXXXX)"
stderr_file="$(mktemp)"
trap 'rm -rf "$TMPDIR" "$stderr_file"' EXIT

mkdir -p "$TMPDIR/.agent0" "$TMPDIR/bin"
touch "$TMPDIR/pnpm-lock.yaml"
cat > "$TMPDIR/bin/pnpm" <<'EOF'
#!/usr/bin/env bash
printf 'fallback should not run\n' >&2
exit 0
EOF
chmod +x "$TMPDIR/bin/pnpm"
cat > "$TMPDIR/.agent0/validator.json" <<'EOF'
{
  "commands": {
    "test": true
  }
}
EOF

( cd "$TMPDIR" && PATH="$TMPDIR/bin:$PATH" bash "$VALIDATOR" >"$TMPDIR/out.json" 2>"$stderr_file" )

ok="$(jq -r '.ok' "$TMPDIR/out.json")"
cmd="$(jq -r '.command' "$TMPDIR/out.json")"

if [ "$ok" != "false" ]; then
  printf 'FAIL: invalid config should return ok=false, got: %s\n' "$ok"
  exit 1
fi

if [ "$cmd" != ".agent0/validator.json" ]; then
  printf 'FAIL: command should identify validator config, got: %s\n' "$cmd"
  exit 1
fi

if ! grep -qF 'validator-config-advisory:' "$stderr_file"; then
  printf 'FAIL: stderr should contain validator-config-advisory. Got: %s\n' "$(cat "$stderr_file")"
  exit 1
fi

if grep -qF 'fallback should not run' "$stderr_file" "$TMPDIR/out.json"; then
  printf 'FAIL: fallback ran despite invalid declarative config\n'
  exit 1
fi

printf 'PASS\n'
exit 0
