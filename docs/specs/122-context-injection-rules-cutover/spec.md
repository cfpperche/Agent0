# 122 — context-injection-rules-cutover

_Created 2026-05-30._

**Status:** shipped

## Intent

Replace Agent0's Claude-native `.claude/rules/` harness surface with an Agent0-owned context
injection layer used by both Claude Code and Codex CLI.

The founder decision is explicit: if Agent0 owns a cross-runtime context hydrator, keeping
Claude Code's native rules as a second behavioral channel is unnecessary confusion. The harness
should have **one source of authoring** and **one runtime-neutral delivery primitive**:

```
.agent0/context/rules/<slug>.md        canonical context fragments
.agent0/hooks/context-inject.sh        runtime-neutral hydrator
.claude/settings.json                  Claude registration only
.codex/config.toml.example             Codex opt-in registration only
```

`.claude/rules/*.md` stops being a shipped or native-loaded harness feature. Claude-specific files
remain only where the file format itself is runtime-specific (`.claude/settings.json`,
`.claude/skills/` for `cc-native` skills, etc.). Rule bodies become neutral context fragments under
`.agent0/context/rules/`.

This is the same principle spec 121 applied to portable skills, but without per-runtime discovery
symlinks: rules are not a standard cross-agent format, and using Claude's native rule loader for one
runtime would recreate the asymmetry this spec removes. Hooks are the common primitive both runtimes
already support.

## Acceptance criteria

- [x] **Scenario: no Claude-native rules are shipped**
  - **Given** a fresh Agent0 checkout
  - **When** Claude Code starts in the repo
  - **Then** there are no harness-managed `.claude/rules/*.md` files for Claude to auto-load, and
    all former rule bodies live under `.agent0/context/rules/`.

- [x] **Scenario: context hydrator is registered for both runtimes**
  - **Given** the shared hydrator `.agent0/hooks/context-inject.sh`
  - **When** Claude Code starts or receives a prompt
  - **Then** `.claude/settings.json` invokes the hydrator via `SessionStart` and `UserPromptSubmit`.
  - **And when** Codex users opt into Agent0 hooks
  - **Then** `.codex/config.toml.example` contains matching commented registrations.

- [x] **Scenario: prompt-scoped context is deterministic and provenance-labeled**
  - **Given** a user prompt mentioning a known capacity, file path, or keyword
  - **When** the hydrator runs
  - **Then** it emits a bounded `AGENT0_CONTEXT_INJECTION` block naming each selected source file and
    reason, with instructions/fragments only from trusted repo-controlled files.

- [x] **Scenario: startup context stays small**
  - **Given** a new session
  - **When** `SessionStart` fires
  - **Then** the hydrator emits an index/readout, not the entire context corpus, so startup does not
    blindly load hundreds of kilobytes of historical rules.

- [x] **Scenario: sync-harness propagates context injection, not Claude rules**
  - **Given** a consumer project runs `.agent0/tools/sync-harness.sh --apply`
  - **When** the harness is installed or updated
  - **Then** `.agent0/context/rules/` and `.agent0/hooks/context-inject.sh` are propagated, while
    `.claude/rules/*.md` is absent from the sync manifest and stale consumer rule files are removed
    when they match the recorded baseline.

- [x] **Scenario: durable docs point at the new surface**
  - **Given** entrypoints, runtime capabilities, memory placement, harness sync docs, README/site
  - **When** this spec lands
  - **Then** first-contact documentation names `.agent0/context/rules/` + context injection as the
    behavioral context surface, not `.claude/rules/`.

## Non-goals

- **Perfect behavioral parity with Claude's path-scoped rule loader in v1.** The cutover removes the
  native loader. The v1 hydrator may use prompt/path/keyword selection and can improve over time.
- **Removing Claude Code itself.** `CLAUDE.md`, `.claude/settings.json`, and `cc-native` skills remain.
- **Converting skills or hooks into context files.** This spec only moves behavioral documentation /
  rule bodies.
- **Using the phrase "prompt injection" in the shipped interface.** The capacity is named context
  injection / context hydration. Untrusted external content must never be mixed into instruction
  fragments.

## Open questions

- [x] Selection policy: which fragments are startup-index only, which are prompt-selected, and which
  should always hydrate for Agent0-maintainer work?
- [x] Stale consumer removal: does the existing sync-harness baseline machinery remove formerly
  shipped `.claude/rules/*.md` cleanly after the manifest drops them, or does it need an explicit
  relocation/deletion pass?
- [x] Live proof — Claude Code: fresh session confirmed `.claude/rules/` is absent, `.agent0/context/rules/`
  has 21 fragments, `.claude/settings.json` registers `context-inject.sh`, the context-injection suite passes,
  and live `SessionStart` + `UserPromptSubmit` blocks arrive from `.agent0/context/rules`.
- [x] Live proof — Codex CLI: after adding the local opt-in hooks to `.codex/config.toml` and starting a
  fresh Codex TUI session, live hook context showed `AGENT0_CONTEXT_INJECTION` for `SessionStart`
  (`mode: index`) and `UserPromptSubmit` (`mode: prompt-selected`), both from `.agent0/context/rules`.
  The dogfood reply reported `PASS`, `event value(s): SessionStart, UserPromptSubmit`, `source_dir:
  .agent0/context/rules`, and selected `language user-prompt-framing spec-driven session-handoff
  runtime-capabilities harness-sync memory-placement`. A follow-up normal TUI launch prompted Codex hook
  review, `Trust all and continue` was accepted, and the model replied `TRUSTED_CONTEXT_SEEN`.
  Gotcha: `codex exec` did not expose the same context to the model in this test; the live proof is from
  Codex TUI.

## Context / references

- Claude rules are context, not enforcement; hooks can add context via `additionalContext`.
- Codex has `AGENTS.md` and hooks, but no native `.claude/rules` equivalent.
- Spec 121 established the location-neutral / registration-per-runtime pattern for skills; this spec
  applies the same architectural stance to behavioral context, using hooks instead of symlinks.
