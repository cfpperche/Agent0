#!/usr/bin/env bash
# Scenario: Claude-only command claims in AGENTS.md need the complete tier contract.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
TOOL="$AGENT0_ROOT/.claude/tools/check-instruction-drift.sh"

TMPDIR="$(mktemp -d -t instruction-drift-04-XXXXXX)"
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

<!-- AGENT0:BEGIN -->
shared
<!-- AGENT0:END -->

## Bad Claim

Run /sdd directly for every non-trivial change.
EOF

actual_exit=0
out="$(bash "$TOOL" --root "$TMPDIR" --skip-sync-check 2>&1)" || actual_exit=$?

if [ "$actual_exit" -eq 0 ]; then
  printf 'FAIL: incomplete tier contract should fail\n%s\n' "$out"
  exit 1
fi

if ! printf '%s\n' "$out" | grep -q 'AGENTS.md missing tier qualifier: Claude-only-until-follow-up'; then
  printf 'FAIL: expected missing tier qualifier diagnostic\n%s\n' "$out"
  exit 1
fi

echo "PASS: 04-no-claude-only-claims-without-tier-caveat"
