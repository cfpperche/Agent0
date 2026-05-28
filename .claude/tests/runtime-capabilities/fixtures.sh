#!/usr/bin/env bash
# Shared fixtures for runtime-capabilities drift tests.

set -euo pipefail

runtime_caps_write_valid_fixture() {
  local root="$1"
  local managed='## Runtime capabilities

See `.claude/rules/runtime-capabilities.md`.
'

  mkdir -p "$root/.claude/rules"

  cat > "$root/CLAUDE.md" <<EOF
# Claude

<!-- AGENT0:BEGIN -->
$managed<!-- AGENT0:END -->
EOF

  cat > "$root/AGENTS.md" <<EOF
# Agents

<!-- AGENT0:BEGIN -->
$managed<!-- AGENT0:END -->
EOF

  cat > "$root/.claude/rules/runtime-capabilities.md" <<'EOF'
# Runtime capabilities

## Status vocabulary

- `native`
- `native-opt-in`
- `convention`
- `read-only`
- `planned`
- `unsupported`

## Capability matrix

| Capability | Claude Code | Codex CLI | Owner files | Notes |
| --- | --- | --- | --- | --- |
| instruction entrypoints | `native` | `native` | `CLAUDE.md`; `AGENTS.md` | ok |
| session handoff | `native` | `convention` | `.agent0/HANDOFF.md` | ok |
| SDD | `native` | `convention` | `.claude/skills/sdd/SKILL.md` | ok |
| debate | `native` | `planned: 091-sdd-debate-runner` | `.claude/skills/sdd/templates/debate.md.tmpl` | ok |
| lifecycle hooks | `native` | `unsupported` | `.claude/hooks/*.sh` | ok |
| runtime introspect | `native` | `read-only` | `.claude/tools/probe.sh` | ok |
| delegation/subagents | `native` | `unsupported` | `.claude/rules/delegation.md` | ok |
| MCP recipes | `native-opt-in` | `native-opt-in` | `.claude/rules/mcp-recipes.md`; `.mcp.json.example`; `.agent0/hooks/mcp-recipes-hint.sh` | ok |
| image generation | `native-opt-in` | `convention` | `.claude/rules/image-gen.md` | ok |
| memory | `native` | `native-opt-in` | `.agent0/memory/MEMORY.md` | ok |
| harness sync | `native-opt-in` | `native-opt-in` | `.claude/tools/sync-harness.sh` | ok |
| customization/sync surfaces | `native` | `convention` | `AGENTS.override.md` | ok |
EOF
}
