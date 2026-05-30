# 123 — codex-hooks-json

_Created 2026-05-30._

**Status:** shipped

## Intent

Move Agent0's Codex hook registration architecture out of optional inline TOML blocks and into a
tracked project hook file:

```
.codex/hooks.json                  Codex project hook registration, tracked and synced
.codex/config.toml.example         MCP recipes template only, no Agent0 hook blocks
.codex/config.toml                 local operator config, gitignored, no consumer-owned hooks
```

The founder decision is parity with Claude Code: Agent0 ships `.claude/settings.json` as the project
hook surface, so Codex should receive the same first-party harness hooks from a tracked project file.
Consumers still need to trust project hooks on first run, but they should not have to copy and
uncomment lifecycle hook blocks to get the harness behavior Agent0 owns.

## Acceptance Criteria

- [x] **Scenario: Codex hooks are tracked**
  - **Given** a fresh Agent0 checkout
  - **When** Codex starts in the repo
  - **Then** project hook registrations live in `.codex/hooks.json`, and the file is git-trackable.

- [x] **Scenario: TOML is no longer the Codex hook carrier**
  - **Given** `.codex/config.toml.example`
  - **When** a consumer copies it for MCP/local settings
  - **Then** it contains no `[[hooks.*]]` blocks and no `context-inject.sh` hook registration.

- [x] **Scenario: sync-harness propagates Codex hooks**
  - **Given** a consumer project runs `.agent0/tools/sync-harness.sh --apply`
  - **When** the harness is installed or updated
  - **Then** `.codex/hooks.json` is copied as a managed harness file while `.codex/config.toml`
    remains untouched.

- [x] **Scenario: no duplicate Codex hook execution**
  - **Given** the local Agent0 dogfood checkout
  - **When** `.codex/hooks.json` exists
  - **Then** the same Agent0 hook registrations are not also present inline in `.codex/config.toml`.

- [x] **Scenario: docs and runtime registry point at the new surface**
  - **Given** entrypoints, runtime capabilities, session-handoff/memory-placement/harness-sync docs,
    tests, and spec 122 follow-up notes
  - **When** this spec lands
  - **Then** Codex hook activation is described as tracked `.codex/hooks.json` plus hook trust, not as
    copying/uncommenting hook blocks in `.codex/config.toml.example`.

- [x] **Scenario: fresh Codex dogfood proves model-visible hydration**
  - **Given** the founder opens a fresh Codex TUI session after this migration
  - **When** the session trusts project hooks and receives a prompt mentioning Agent0 context
  - **Then** the model-visible context includes `AGENT0_CONTEXT_INJECTION` from `.codex/hooks.json`
    sourced hooks for both `SessionStart` and `UserPromptSubmit`.

## Non-goals

- **Moving MCP recipes out of TOML.** `.codex/config.toml.example` remains the safe template for MCP
  server recipes only, not a complete Codex config default.
- **Tracking `.codex/config.toml`.** The real TOML config can contain provider/model/MCP choices and
  credentials, so it stays gitignored.
- **Changing Codex hook trust semantics.** Codex must still review changed project hooks before
  running them.
- **Shipping maintainer-only hooks that are excluded from consumer propagation.** If a hook script is
  excluded from `sync-harness`, its Codex registration cannot be in consumer-shipped `.codex/hooks.json`
  unless a structured consumer filter is added.

## Open Questions

- [x] Does `hooks.json` lose hook features relative to inline TOML?
  - No. Official Codex docs describe `hooks.json` and inline `[hooks]` as equivalent hook sources
    using the same event/matcher/handler schema.
- [x] Should maintainer-only Codex hooks remain in gitignored `.codex/config.toml`, or should
  `sync-harness` gain a structured `.codex/hooks.json` filter like `.claude/settings.json`?
  - For this migration, keep `.codex/hooks.json` consumer-safe and avoid dangling consumer hooks.
- [x] Fresh-Codex dogfood evidence from founder-opened session.
  - Founder-provided fresh Codex TUI proof reported `PASS`, injected block present, events
    `SessionStart, UserPromptSubmit`, modes `index, prompt-selected`, and
    `source_dir: .agent0/context/rules`.

## Context / References

- Spec 122 moved behavioral context to `.agent0/context/rules/` and added `context-inject.sh`.
- Official Codex hook docs: Codex discovers hooks in `hooks.json` or inline `[hooks]`; if both exist
  in one layer, Codex merges them and warns. Project-local hooks require project trust and hook trust.
