# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects and enforces this file through hooks; Codex reads and updates it by convention through `AGENTS.md`.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Spec 100 (`multi-runtime-session-readouts`) is implemented and validated.** The three SessionStart readout hooks moved from `.claude/hooks/` to `.agent0/hooks/`: `reminders-readout.sh`, `routines-readout.sh`, and `mcp-recipes-hint.sh`. Claude settings now point at the shared paths; `.codex/config.toml.example` contains opt-in commented SessionStart blocks for all three.

Docs and entrypoints were updated so the MCP stack hint is no longer described as Claude-only. Runtime capabilities now has explicit `reminders` and `routines` rows with Codex `native-opt-in`; MCP recipes points at the shared hook. Existing mcp/monorepo tests were repointed to `.agent0/hooks/mcp-recipes-hint.sh`.

Validation passed: new `multi-runtime-readouts` fixtures (including subdir launch and no-PyYAML/yq degraded reminder fallback), `mcp-recipes`, `mcp-recipes-laravel`, `monorepo-stack-detect`, `runtime-capabilities`, `instruction-drift`, `codex-mcp-recipes`, `memory-multi-runtime`, selected harness-sync scenarios `01/02/05/07/35`, `sync-harness --apply --dry-run` fixture propagation, `skill validate/check-rubric` for `remind`, and `git diff --check`.

Pre-existing/paused: `docs/specs/091-sdd-debate-runner/` remains untracked and out of scope. `.codex/config.toml` + `.codex/.env.local` remain machine-local.

## Active Work

_None active._

## Next Actions

1. Review/commit the spec 100 diff.
2. Push the existing local commits plus this spec 100 work when ready.
3. Leave spec 091 paused unless explicitly resumed.

## Decisions & Gotchas

- `codex exec --json --ephemeral --dangerously-bypass-hook-trust` did not surface SessionStart hook output, even for existing `MEMORY DECAY`; notes record this as a non-faithful interactive preamble probe. Synthetic SessionStart fixtures are the acceptance evidence.
- `_memory-hook-lib.sh` now resolves stdin `.cwd` through `git rev-parse --show-toplevel` when possible, so Codex launches from subdirectories read root harness state.
- `memory_runtime` now classifies SessionStart payloads without `CLAUDE_PROJECT_DIR` as Codex, with `apply_patch` still the primary Codex edit-surface signal.
- The shipped MCP rule intentionally does not link to concrete Agent0 spec paths; lineage stays in spec 100 notes to preserve propagation hygiene.
