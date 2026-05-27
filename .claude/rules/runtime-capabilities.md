---
paths:
  - ".claude/rules/runtime-capabilities.md"
  - "AGENTS.md"
  - "CLAUDE.md"
  - ".claude/tools/check-instruction-drift.sh"
---

# Runtime capabilities

This registry is the canonical map of Agent0 first-party capabilities across supported tool-calling runtimes. It answers what each runtime can use natively, what requires opt-in activation, what is convention-only, and what is only planned or unsupported. The file is provider-neutral in content, even though it lives under `.claude/rules/` because that is the current Agent0-managed sync surface.

## Status vocabulary

Use exactly these states in runtime cells:

- `native` — works on clone; the runtime has a primitive that consumes the capability.
- `native-opt-in` — the runtime has the primitive, but the user must enable it through an env var, config copy, credential, or explicit script invocation.
- `convention` — no runtime primitive; the entrypoint instructs the agent to perform the capability manually following a documented rule.
- `read-only` — the agent can read artifacts the capability produces but cannot invoke or extend the capability.
- `planned` — explicitly scoped for a future spec; write `planned: <spec-slug>` where known, otherwise `planned: untracked`.
- `unsupported` — no path forward is declared.

Runtime-specific labels such as `Claude-only-until-follow-up` are legacy wording. Do not use them in new capability cells.

## Capability matrix

| Capability | Claude Code | Codex CLI | Owner files | Notes |
| --- | --- | --- | --- | --- |
| instruction entrypoints | `native` | `native` | `CLAUDE.md`; `AGENTS.md`; `docs/specs/090-multi-runtime-entrypoints/` | Each runtime has a native first-contact file. |
| session handoff | `native` | `convention` | `.agent0/HANDOFF.md`; `.claude/rules/session-handoff.md`; `.claude/hooks/session-start.sh`; `.claude/hooks/session-stop.sh`; `docs/specs/092-multi-runtime-handoff/` | Claude injects/enforces by hooks; Codex reads and updates by entrypoint convention. |
| SDD | `native` | `convention` | `.claude/skills/sdd/SKILL.md`; `.claude/rules/spec-driven.md`; `docs/specs/` | Codex can follow the artifacts manually, but slash-command execution is not Codex-native. |
| debate | `native` | `planned: 091-sdd-debate-runner` | `.claude/skills/sdd/SKILL.md`; `.claude/skills/sdd/templates/debate.md.tmpl`; `docs/specs/089-sdd-debate-artifact/`; `docs/specs/091-sdd-debate-runner/` | Human-brokered direct-file debate works; automated runner stays paused. |
| lifecycle hooks | `native` | `unsupported` | `.claude/settings.json`; `.claude/hooks/*.sh`; `.claude/rules/runtime-introspect.md`; `.claude/rules/session-handoff.md` | Codex lifecycle hook parity is not declared in v1. |
| runtime introspect | `native` | `read-only` | `.claude/hooks/runtime-pre-mark.sh`; `.claude/hooks/runtime-capture.sh`; `.claude/tools/probe.sh`; `.claude/rules/runtime-introspect.md`; `.claude/.runtime-state/README.md` | Codex can inspect existing snapshots with shell reads, but Claude hooks produce the snapshots. |
| delegation/subagents | `native` | `unsupported` | `.claude/hooks/delegation-gate.sh`; `.claude/hooks/delegation-stop.sh`; `.claude/hooks/post-edit-validate.sh`; `.claude/rules/delegation.md`; `.claude/delegation-audit.jsonl` | Claude's `Agent` tool and hook gate are the current implementation. |
| MCP recipes | `native-opt-in` | `native-opt-in` | `.claude/rules/mcp-recipes.md`; `.mcp.json.example`; `.codex/config.toml.example`; `.claude/hooks/mcp-recipes-hint.sh`; `docs/specs/098-codex-mcp-recipes-parity/` | Claude activates via `.mcp.json`; Codex activates via trusted-project `.codex/config.toml` copied from the MCP-only template. Both remain explicit opt-in and credential-gated where applicable. |
| image generation | `native-opt-in` | `convention` | `.claude/skills/image/SKILL.md`; `.claude/rules/image-gen.md`; `.claude/rules/mcp-recipes.md`; `.mcp.json.example`; `assets/generated/` | Requires fal.ai MCP activation and `FAL_KEY`; Codex can only reproduce manually unless a future native path is scoped. |
| memory | `native` | `convention` | `.claude/memory/MEMORY.md`; `.claude/memory/*.md`; `.claude/rules/memory-placement.md`; `.claude/tools/memory-*.sh` | Claude discovers memory through its instruction surface; Codex reads the files manually when relevant. |
| harness sync | `native-opt-in` | `native-opt-in` | `.claude/tools/sync-harness.sh`; `.claude/rules/harness-sync.md`; `.claude/tests/harness-sync/` | Both runtimes can run the shell tool explicitly; it is never automatic. |
| customization/sync surfaces | `native` | `convention` | `.claude/tools/sync-harness.sh`; `.claude/rules/harness-sync.md`; `AGENTS.override.md`; nested `AGENTS.md`; `docs/specs/090-multi-runtime-entrypoints/` | Claude-side customization is harness-managed; Codex customization layers through its native instruction-chain convention. |

## Future runtimes

Potential future columns include `Cursor`, `Aider`, and `Hermes Agent`. They are placeholders only. Do not add support claims for a runtime until a spec dogfoods or verifies that runtime's actual behavior.

## Maintenance

Maintainer discipline (update rule, drift-check anchors, skill-portability relationship) lives in `.claude/memory/runtime-capabilities-maintenance.md`.
