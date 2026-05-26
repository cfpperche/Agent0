#!/usr/bin/env bash
# Scenario: non-minimum extra rows are allowed.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
TOOL="$AGENT0_ROOT/.claude/tools/check-instruction-drift.sh"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=fixtures.sh
. "$SCRIPT_DIR/fixtures.sh"

TMPDIR="$(mktemp -d -t runtime-capabilities-08-XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

runtime_caps_write_valid_fixture "$TMPDIR"
cat >> "$TMPDIR/.claude/rules/runtime-capabilities.md" <<'EOF'
| routines | `native` | `convention` | `.claude/rules/routines.md` | extra row |
EOF

out="$(bash "$TOOL" --root "$TMPDIR" --skip-sync-check 2>&1)"

if ! printf '%s\n' "$out" | grep -q 'runtime capability registry anchor checks passed'; then
  printf 'FAIL: expected extra row to remain allowed\n%s\n' "$out"
  exit 1
fi

echo "PASS: 08-extra-row-allowed"
