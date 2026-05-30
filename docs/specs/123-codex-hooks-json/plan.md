# 123 — codex-hooks-json — plan

_Drafted 2026-05-30._

## Approach

Promote Codex hook registration to a tracked project file and leave TOML for local/MCP config:

1. Add `.codex/hooks.json` with consumer-safe Agent0 hook registrations.
2. Remove hook blocks from `.codex/config.toml.example`.
3. Remove duplicate inline hook blocks from the local gitignored `.codex/config.toml`.
4. Add `.codex/hooks.json` to the sync-harness managed manifest.
5. Update tests that previously parsed hook registrations out of TOML.
6. Update docs/spec notes/runtime capabilities to point at `.codex/hooks.json`.
7. Prepare a copy-paste dogfood prompt for a founder-opened fresh Codex TUI session.

## Files to Touch

- `.codex/hooks.json` — new tracked Codex project hook surface.
- `.codex/config.toml.example` — keep MCP recipes; remove lifecycle hook template blocks.
- `.codex/config.toml` — local cleanup only; remove duplicate inline Agent0 hook blocks.
- `.agent0/tools/sync-harness.sh` — add `.codex/hooks.json` to the propagation manifest.
- `.agent0/tests/context-injection/`, `.agent0/tests/session-handoff-multi-runtime/`,
  `.agent0/tests/harness-sync/`, `.agent0/tests/runtime-capabilities/` — update assertions.
- `AGENTS.md`, `CLAUDE.md`, `.agent0/context/rules/*.md`, `.agent0/HANDOFF.md`, spec 122 notes —
  replace opt-in TOML-hook language with tracked hooks JSON language.

## Risks

- **Duplicate hook runs.** Codex loads both `hooks.json` and inline TOML hooks. Local TOML cleanup is
  mandatory before dogfood.
- **Hook trust reset.** Moving the source path changes hook hashes; the first fresh Codex TUI run must
  review/trust the new hooks.
- **Maintainer-only hooks.** `propagation-advise.sh` is currently excluded from consumer propagation.
  The tracked consumer hook file must not register excluded scripts unless sync gains a filter.
- **Current-session inertia.** Existing Codex sessions keep loaded hooks until restarted.

## Validation

- `jq -e . .codex/hooks.json`
- `bash .agent0/tests/context-injection/run-all.sh`
- `bash .agent0/tests/session-handoff-multi-runtime/run-all.sh`
- `bash .agent0/tests/codex-mcp-recipes/run-all.sh`
- `bash .agent0/tests/runtime-capabilities/run-all.sh`
- `bash .agent0/tests/harness-sync/run-all.sh`
- Fresh Codex TUI dogfood opened by the founder.
