#!/usr/bin/env bash
# Scenario: .codex/config.toml.example synced; .codex/config.toml never touched.
# Asserts:
#   (a) .codex/config.toml.example copied from Agent0 to consumer project
#   (b) consumer project's .codex/config.toml remains byte-identical

set -euo pipefail

AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
TOOL="$AGENT0_ROOT/.agent0/tools/sync-harness.sh"

TMPDIR="$(mktemp -d -t spec-098-35-XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

SRC="$TMPDIR/agent0"
CONSUMER="$TMPDIR/consumer"
mkdir -p "$SRC/.claude" "$SRC/.codex" "$CONSUMER/.claude" "$CONSUMER/.codex"

cat > "$SRC/.codex/config.toml.example" <<'EOF'
# Agent0 - Codex MCP recipes
[mcp_servers.playwright]
enabled = false
command = "npx"
args = ["-y", "@playwright/mcp@latest"]
EOF
printf '{"hooks":{}}\n' > "$SRC/.claude/settings.json"
printf '# CLAUDE\n\n## Compact Instructions\n' > "$SRC/CLAUDE.md"

cat > "$CONSUMER/.codex/config.toml" <<'EOF'
model = "consumer-local-model"
approval_policy = "never"

[mcp_servers.consumer-private]
command = "private-command"
args = ["--token", "CONSUMER-SECRET-MARKER"]
EOF
printf '{"hooks":{}}\n' > "$CONSUMER/.claude/settings.json"
printf '# CLAUDE consumer project\n\n## Compact Instructions\n' > "$CONSUMER/CLAUDE.md"

config_sha_before="$(sha256sum "$CONSUMER/.codex/config.toml" | awk '{print $1}')"

actual_exit=0
out="$(bash "$TOOL" --apply --agent0-path="$SRC" "$CONSUMER" 2>&1)" || actual_exit=$?

if [ "$actual_exit" -ne 0 ]; then
  printf 'FAIL: --apply expected exit 0, got %d\n%s\n' "$actual_exit" "$out"
  exit 1
fi

if [ ! -f "$CONSUMER/.codex/config.toml.example" ]; then
  printf 'FAIL: .codex/config.toml.example not copied\n%s\n' "$out"
  exit 1
fi

config_sha_after="$(sha256sum "$CONSUMER/.codex/config.toml" | awk '{print $1}')"
if [ "$config_sha_before" != "$config_sha_after" ]; then
  printf 'FAIL: .codex/config.toml was modified by sync\n'
  exit 1
fi

if ! grep -q 'CONSUMER-SECRET-MARKER' "$CONSUMER/.codex/config.toml"; then
  printf 'FAIL: .codex/config.toml content corrupted\n'
  exit 1
fi

echo "PASS: 35-codex-config-example-untouched"
