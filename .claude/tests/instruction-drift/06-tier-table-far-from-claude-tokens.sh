#!/usr/bin/env bash
# Scenario: file-level tier contract covers Claude-only tokens far from the tier table.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
TOOL="$AGENT0_ROOT/.claude/tools/check-instruction-drift.sh"

TMPDIR="$(mktemp -d -t instruction-drift-06-XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

cat > "$TMPDIR/CLAUDE.md" <<'EOF'
# Claude

<!-- AGENT0:BEGIN -->
shared
<!-- AGENT0:END -->
EOF

cat > "$TMPDIR/AGENTS.md" <<'EOF'
# Agents

| Tier | Meaning |
| --- | --- |
| native-now | native |
| manual/read-only-now | reference |
| Claude-only-until-follow-up | future |

<!-- AGENT0:BEGIN -->
shared
<!-- AGENT0:END -->

## Later Section

Line 01.
Line 02.
Line 03.
Line 04.
Line 05.
Line 06.
Line 07.
Line 08.
Line 09.
Line 10.
Line 11.
Line 12.

Run /sdd for spec-driven work.
EOF

out="$(bash "$TOOL" --root "$TMPDIR" --skip-sync-check 2>&1)"

if ! printf '%s\n' "$out" | grep -q 'AGENTS.md Claude-only claims are covered by file-level tier caveats'; then
  printf 'FAIL: expected file-level tier caveat diagnostic\n%s\n' "$out"
  exit 1
fi

echo "PASS: 06-tier-table-far-from-claude-tokens"
