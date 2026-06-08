# 175 - project-core-local-renderer

_Created 2026-06-08._

**Status:** shipped
**UI impact:** none

## Intent

Specs 173/174 made `.agent0/project-core.md` the consumer-owned source for language/locale and project framing, mirrored into `CLAUDE.md` and `AGENTS.md`. The mirror worked, but the only writer lived inside `sync-harness.sh`, which requires an Agent0 source path. That is the wrong coupling: changing a consumer-owned source should not require an upstream Agent0 sync just to refresh derived regions in the same consumer.

This spec makes project-core rendering a local consumer capability. A local tool regenerates the two `AGENT0:PROJECT` regions from `.agent0/project-core.md` without `--agent0-path`; post-edit hooks run it after agent edits; `sync-harness.sh` calls the same local renderer only as part of upstream sync. The source remains authoritative, the regions remain derived, and bootstrap alerts still disappear once the source exists.

## Acceptance criteria

- [x] **Scenario: Local renderer creates missing mirrors without Agent0 path**
  - **Given** a consumer has `.agent0/project-core.md` and entrypoints without `AGENT0:PROJECT`
  - **When** `.agent0/tools/project-core-sync.sh --apply` runs in that consumer
  - **Then** it creates matching `AGENT0:PROJECT` regions in both `CLAUDE.md` and `AGENTS.md` without requiring `--agent0-path` or `AGENT0_HARNESS_PATH`.

- [x] **Scenario: Local renderer updates stale mirrors after source edits**
  - **Given** both entrypoints have `AGENT0:PROJECT` regions rendered from an older `.agent0/project-core.md`
  - **When** `.agent0/project-core.md` changes and the local renderer runs
  - **Then** both mirrors are re-rendered from the source automatically.

- [x] **Scenario: Derived-region edits lose to the source**
  - **Given** a user or agent edits only the `AGENT0:PROJECT` region in an entrypoint
  - **When** the local renderer runs
  - **Then** it restores the region from `.agent0/project-core.md`, because the entrypoint region is derived, not authoritative.

- [x] **Scenario: Agent edit hooks keep mirrors current**
  - **Given** a runtime edits files through its normal edit tool
  - **When** the edit completes
  - **Then** the PostToolUse hook runs the local renderer in the current consumer checkout and quietly no-ops when mirrors are already current.

- [x] **Scenario: Upstream sync reuses the local renderer**
  - **Given** `sync-harness.sh --apply` runs during an Agent0-to-consumer sync
  - **When** the consumer has `.agent0/project-core.md`
  - **Then** sync invokes the local renderer instead of owning a separate project-core merge implementation.

- [x] **Scenario: Bootstrap advisory text points to the local renderer**
  - **Given** a consumer has `.agent0/project-core.md.example` but no `.agent0/project-core.md`
  - **When** startup/status/doctor/sync surfaces explain the pending bootstrap
  - **Then** they tell the operator to configure the source and run the local renderer, not to perform an upstream harness sync solely for mirror refresh.

## Non-goals

- Re-enabling prompt-time context injection.
- Auto-creating `.agent0/project-core.md` from the example.
- Making `sync-harness.sh` infer the Agent0 source path.
- Adding a watcher/daemon.
- Reloading runtime entrypoint instructions mid-session after a mirror rewrite.

## Open questions

- [x] None.

## Context / references

- `docs/specs/173-project-core-language-locale/` - introduced project-core source/example split.
- `docs/specs/174-bootstrap-advisories/` - introduced pending bootstrap alerts.
- `.agent0/tools/sync-harness.sh` - previous mirror writer and upstream sync surface.
- `.agent0/tools/check-instruction-drift.sh` - verifies mirror drift.
- `.claude/settings.json` and `.codex/hooks.json` - post-edit hook surfaces.
