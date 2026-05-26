#!/usr/bin/env bash
# Scenario: sync-harness sees root AGENTS.md on the baseline-tracked path.

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
TOOL="$AGENT0_ROOT/.claude/tools/check-instruction-drift.sh"

TMPDIR="$(mktemp -d -t instruction-drift-05-XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

SRC="$TMPDIR/agent0"
FORK="$TMPDIR/fork"
mkdir -p "$SRC/.claude/tools/lib" "$FORK/.claude/tools/lib"

cp "$AGENT0_ROOT/.claude/tools/sync-harness.sh" "$SRC/.claude/tools/sync-harness.sh"
cp "$AGENT0_ROOT/.claude/tools/sync-harness.sh" "$FORK/.claude/tools/sync-harness.sh"
cp "$AGENT0_ROOT/.claude/tools/lib/managed-block.sh" "$SRC/.claude/tools/lib/managed-block.sh"
cp "$AGENT0_ROOT/.claude/tools/lib/managed-block.sh" "$FORK/.claude/tools/lib/managed-block.sh"

cat > "$SRC/CLAUDE.md" <<'EOF'
# Claude

<!-- AGENT0:BEGIN -->
shared
<!-- AGENT0:END -->
EOF
cp "$SRC/CLAUDE.md" "$FORK/CLAUDE.md"

cat > "$SRC/AGENTS.md" <<'EOF'
# Agents

native-now
manual/read-only-now
Claude-only-until-follow-up

<!-- AGENT0:BEGIN -->
shared
<!-- AGENT0:END -->
EOF

cat > "$FORK/AGENTS.md" <<'EOF'
# Agents

native-now
manual/read-only-now
Claude-only-until-follow-up

<!-- AGENT0:BEGIN -->
fork-edited
<!-- AGENT0:END -->
EOF

actual_exit=0
out="$(bash "$TOOL" --root "$FORK" --agent0-path "$SRC" 2>&1)" || actual_exit=$?

if [ "$actual_exit" -eq 0 ]; then
  printf 'FAIL: AGENTS.md drift should fail\n%s\n' "$out"
  exit 1
fi

if ! printf '%s\n' "$out" | grep -q 'sync-harness reports AGENTS.md drift'; then
  printf 'FAIL: expected sync-harness AGENTS.md drift diagnostic\n%s\n' "$out"
  exit 1
fi

echo "PASS: 05-sync-harness-detects-agents-md-drift"
