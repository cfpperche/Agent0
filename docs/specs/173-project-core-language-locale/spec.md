# 173 - project-core-language-locale

_Created 2026-06-08._

**Status:** shipped
**UI impact:** none

## Intent

Agent0 paused prompt-time context injection while spec 171 redesigns event-scoped routing. That removed a noisy dynamic channel, but it also exposed that some always-needed project framing, especially language and locale guidance, should not depend on prompt hydration at all. This spec makes language/locale a first-class project-core convention: Agent0 gets its own `.agent0/project-core.md`, the existing `AGENT0:PROJECT` mirror makes Claude and Codex see the same guidance, and consumers receive a configurable example without Agent0 overwriting each consumer's real project-core source.

## Acceptance criteria

- [x] **Scenario: Agent0 language guidance is always-on**
  - **Given** Agent0 has a `.agent0/project-core.md`
  - **When** `CLAUDE.md` and `AGENTS.md` are inspected by their respective runtimes
  - **Then** both entrypoints include the same `AGENT0:PROJECT` region with Agent0's language, locale, voice, and scope guidance.

- [x] **Scenario: Consumers get a configurable placeholder, not Agent0's own values**
  - **Given** a consumer sync receives Agent0 harness files
  - **When** the consumer has not authored `.agent0/project-core.md`
  - **Then** sync may copy `.agent0/project-core.md.example`, but it must not create or overwrite the consumer's real `.agent0/project-core.md`.

- [x] **Scenario: Existing consumer-owned project-core behavior is preserved**
  - **Given** a consumer has authored `.agent0/project-core.md`
  - **When** `sync-harness.sh --apply` runs
  - **Then** the consumer's source remains the authority and is mirrored into both entrypoints exactly as spec 131 defined.

- [x] **Scenario: Language fallback rule points to the project core**
  - **Given** an agent reads `.agent0/context/rules/language.md`
  - **When** `.agent0/project-core.md` exists
  - **Then** the rule directs the agent to treat the project core as the durable language/locale source before applying fallback defaults.

- [x] No consumer repository is synced as part of this spec.

- [x] Validation covers instruction drift, project-core mirror behavior, and the new consumer example shipping contract.

## Non-goals

- Re-enabling `UserPromptSubmit` context injection.
- Solving dynamic prompt/tool routing; spec 171 owns that.
- Choosing language settings for `mei-saas`, `acmeyard`, `cognixse`, or any other consumer project.
- Making `.agent0/project-core.md` an Agent0-owned sync-manifest file.
- Adding a parser or schema for project-core content.

## Open questions

- [x] None.

## Context / references

- `docs/specs/131-harness-entrypoint-sync/` - shipped the consumer-owned `.agent0/project-core.md` mirror into both entrypoints.
- `docs/specs/171-context-injection-reformulation/` - paused/reformulates dynamic prompt context.
- `.agent0/context/rules/harness-sync.md` - documents project-core ownership and mirror semantics.
- `.agent0/tools/sync-harness.sh` - implements the project-core mirror and sync manifest.
- `.agent0/tools/check-instruction-drift.sh` - validates entrypoint/project-core drift.
- `.agent0/context/rules/language.md` - current fallback language rule.
