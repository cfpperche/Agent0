#!/usr/bin/env bash
# Spec 019 — Scenario: project memory does NOT propagate to forks.
# INVARIANT GUARD: protects sync-harness manifest from accidental inclusion
# of .claude/memory/. Should pass trivially before AND after impl.
# Asserts:
#   (a) Agent0 mock with .claude/memory/foo.md populated → after sync, fork has NO .claude/memory/foo.md

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
TOOL="$AGENT0_ROOT/.claude/tools/sync-harness.sh"

TMPDIR="$(mktemp -d -t spec-019-02-XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

SRC="$TMPDIR/agent0"
FORK="$TMPDIR/fork"
mkdir -p "$SRC/.claude/memory" "$SRC/.claude/hooks" "$FORK/.claude"

# Mock Agent0 source — minimal but with memory files populated
printf '#!/usr/bin/env bash\necho test\n' > "$SRC/.claude/hooks/test-hook.sh"
chmod +x "$SRC/.claude/hooks/test-hook.sh"
printf '{"hooks":{}}\n' > "$SRC/.claude/settings.json"
printf '# CLAUDE\n\n## Compact Instructions\n' > "$SRC/CLAUDE.md"

cat > "$SRC/.claude/memory/foo.md" <<'EOF'
---
name: foo
description: Agent0-only memory that should NEVER ship to forks
metadata:
  type: project
---
foo body
EOF
cat > "$SRC/.claude/memory/MEMORY.md" <<'EOF'
- [Foo](foo.md) — should not appear in fork
EOF

# Empty fork target
printf '{"hooks":{}}\n' > "$FORK/.claude/settings.json"
printf '# Fork CLAUDE\n\n## Compact Instructions\n' > "$FORK/CLAUDE.md"

bash "$TOOL" --apply --agent0-path="$SRC" "$FORK" >/dev/null 2>&1 || true

if [ -d "$FORK/.claude/memory" ] && [ -n "$(ls -A "$FORK/.claude/memory" 2>/dev/null)" ]; then
  printf 'FAIL: fork received .claude/memory/ content from sync\n'
  ls -la "$FORK/.claude/memory" 2>&1
  exit 1
fi

if [ -f "$FORK/.claude/memory/foo.md" ] || [ -f "$FORK/.claude/memory/MEMORY.md" ]; then
  printf 'FAIL: specific memory files leaked to fork\n'
  exit 1
fi

echo "PASS: 02-no-fork-propagation"
