---
paths:
  - ".claude/rules/runtime-capabilities.md"
  - "AGENTS.md"
  - "CLAUDE.md"
  - ".agent0/tools/check-instruction-drift.sh"
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
| instruction entrypoints | `native` | `native` | `CLAUDE.md`; `AGENTS.md` | Each runtime has a native first-contact file. |
| session handoff | `native` | `native-opt-in` | `.agent0/HANDOFF.md`; `.claude/rules/session-handoff.md`; `.agent0/hooks/session-start.sh`; `.agent0/hooks/session-stop.sh`; `.agent0/hooks/session-track-edits.sh`; `.codex/config.toml.example` | Claude injects/nags by hooks; Codex receives SessionStart/Stop/apply_patch attribution after uncommenting the project hook blocks. Codex Stop uses continue-with-corrective-prompt nag-once parity, not byte-for-byte termination blocking. |
| SDD | `native` | `convention` | `.claude/skills/sdd/SKILL.md`; `.claude/rules/spec-driven.md`; `docs/specs/` | Codex can follow the artifacts manually, but slash-command execution is not Codex-native. |
| debate | `native` | `planned: 091-sdd-debate-runner` | `.claude/skills/sdd/SKILL.md`; `.claude/skills/sdd/templates/debate.md.tmpl` | Human-brokered direct-file debate works; automated runner stays paused. |
| lifecycle hooks | `native` | `native` | `.claude/settings.json`; `.claude/hooks/*.sh`; `.agent0/hooks/*.sh`; `.codex/config.toml` (`[hooks]`); `.codex/hooks.json`; `.claude/rules/session-handoff.md` | Both runtimes expose `PreToolUse` / `PostToolUse` / `SessionStart` / `Stop` / `SubagentStart` / `SubagentStop` / `UserPromptSubmit` / `PreCompact` / `PostCompact` / `PermissionRequest`; payload shape is nearly identical. Claude additionally exposes `PostToolUseFailure` and a richer total surface (~29 events). Codex tool-name catalog differs — first-party edits arrive as `apply_patch` / `Bash`, not `Edit` / `Write` / `MultiEdit`. First-party Agent0 hook ports are tracked per-capacity; see re-audit note below. |
| reminders | `native` | `native-opt-in` | `.claude/rules/reminders.md`; `.agent0/hooks/reminders-readout.sh`; `.claude/settings.json`; `.codex/config.toml.example`; `.agent0/reminders.yaml` | Claude emits the SessionStart readout from project settings; Codex receives the same framed readout after project hook activation. |
| routines | `native` | `native-opt-in` | `.claude/rules/routines.md`; `.agent0/hooks/routines-readout.sh`; `.claude/settings.json`; `.codex/config.toml.example`; `.agent0/routines/`; `.agent0/.routines-state/` | Claude emits pending routine queue readouts from project settings; Codex receives the same queue readout after project hook activation. |
| delegation/subagents | `native` | `native-opt-in` | `.agent0/hooks/delegation-gate.sh`; `.agent0/hooks/delegation-start-audit.sh`; `.agent0/hooks/delegation-stop.sh`; `.agent0/hooks/delegation-verify.sh`; `.claude/rules/delegation.md`; `.agent0/delegation-audit.jsonl`; `.codex/config.toml.example` | Claude's `Agent` tool blocks under-specified dispatch (`delegation-gate.sh`, exit 2). Codex has native subagents (`/agent`, `agents.max_depth`) + opt-in `SubagentStart`/`SubagentStop` observability hooks writing the single canonical `.agent0/delegation-audit.jsonl` + a runtime-neutral `SubagentStop` verifier (`delegation-verify.sh`, spec 111), but NO pre-dispatch blocking gate — no Codex hook can stop a spawn (spec 106), so the 5-field discipline is convention-only on Codex (orchestrator self-applies it; see `delegation.md` § Codex: convention-only). |
| MCP recipes | `native-opt-in` | `native-opt-in` | `.mcp.json.example`; `.codex/config.toml.example` | Templates only — copy/uncomment per upstream MCP README. No curated reference rule, no SessionStart stack hint; each block is `enabled = false` / commented by default with env-var indirection for secrets. |
| browser auth | `native-opt-in` | `native-opt-in` | `.claude/rules/browser-auth.md`; `.agent0/.browser-state/`; `.mcp.json.example`; `.codex/config.toml.example` | Playwright MCP headed-login → save → headless-reuse flow; `BROWSER_AUTH_REQUIRED: <host>` signaling convention; per-host state under `.agent0/.browser-state/<host>.json` (gitignored, credential-class). |
| image generation | `native-opt-in` | `convention` | `.claude/skills/image/SKILL.md`; `.claude/rules/image-gen.md`; `.mcp.json.example`; `assets/generated/` | Requires fal.ai MCP activation and `FAL_KEY`; Codex can only reproduce manually unless a future native path is scoped. |
| memory | `native` | `native-opt-in` | `.agent0/memory/MEMORY.md`; `.agent0/memory/*.md`; `.claude/rules/memory-placement.md`; `.agent0/hooks/memory-*.sh`; `.agent0/tools/memory-*.sh`; `.codex/config.toml.example` | Codex hooks port the four memory implementations via `.codex/config.toml.example`; `apply_patch` is the v1 hook-coverage surface; `Bash` writes are out of strict parity and caught by `.githooks/pre-commit` backstop; finalizer fallback for hook-disabled sessions. |
| harness sync | `native-opt-in` | `native-opt-in` | `.agent0/tools/sync-harness.sh`; `.claude/rules/harness-sync.md`; `.agent0/tests/harness-sync/` | Both runtimes can run the shell tool explicitly; it is never automatic. |
| vuln audit | `native` | `native-opt-in` | `.agent0/tools/vuln-audit.sh`; `.claude/skills/vuln-audit/SKILL.md`; `.claude/rules/vuln-audit.md`; `.agent0/tests/vuln-audit/` | On-demand detector for known-vulnerable installed deps (engine: osv-scanner; requires the binary + `jq`). Claude has the `/vuln-audit` slash skill; Codex runs the runtime-neutral tool directly. Never gates install/commit; reports + proposes, never auto-fixes. Engine-absent fails open (advisory, exit 0). |
| customization/sync surfaces | `native` | `convention` | `.agent0/tools/sync-harness.sh`; `.claude/rules/harness-sync.md`; `AGENTS.override.md`; nested `AGENTS.md` | Claude-side customization is harness-managed; Codex customization layers through its native instruction-chain convention. |

_Re-audit pending: the `lifecycle hooks` promotion from `unsupported` to `native` for Codex CLI implies adjacent rows still framed around "Codex CLI cannot intercept" may need similar promotion. `delegation/subagents` was resolved (spec 106 — promoted to `native-opt-in`, observability hooks only). Track via the next firing of the competitive-harness re-audit routine, or earlier if a downstream spec needs the answer._

## Future runtimes

Potential future columns include `Cursor`, `Aider`, and `Hermes Agent`. They are placeholders only. Do not add support claims for a runtime until a spec dogfoods or verifies that runtime's actual behavior.

## Maintenance

Maintainer discipline (update rule, drift-check anchors, skill-portability relationship) lives in `.agent0/memory/runtime-capabilities-maintenance.md`.
