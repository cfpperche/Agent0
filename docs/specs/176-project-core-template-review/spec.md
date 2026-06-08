# 176 - project-core-template-review

_Created 2026-06-08._

**Status:** shipped
**UI impact:** none

## Intent

Consumer projects can already own `.agent0/project-core.md` while Agent0 ships `.agent0/project-core.md.example` as the current template. That is correct, but it leaves a configured consumer blind to template evolution: when Agent0 updates the example, sync copies the new template, preserves the consumer source, and no agent learns that the real configuration may need review.

This spec adds a lightweight template acknowledgement marker. The example carries a template id. Consumer sources copy/keep the marker after reviewing the template. When the example's id differs from the consumer source's id, Agent0 emits an advisory telling agents to review the new template and update `.agent0/project-core.md`. The advisory is idempotent: it disappears after the source acknowledges the current template id.

## Acceptance criteria

- [x] **Scenario: Configured consumer receives a new template and gets a review advisory**
  - **Given** a consumer has `.agent0/project-core.md`
  - **And** Agent0 ships `.agent0/project-core.md.example` with a template id missing from or newer than the consumer source
  - **When** `sync-harness.sh --apply` copies or updates the example
  - **Then** sync emits an advisory telling the agent to review the example, update the source, and run the local renderer.

- [x] **Scenario: Matching template id is quiet**
  - **Given** `.agent0/project-core.md` and `.agent0/project-core.md.example` carry the same template id
  - **When** startup/status/doctor/sync surfaces run
  - **Then** no template-review advisory appears.

- [x] **Scenario: Review advisory is visible in normal agent surfaces**
  - **Given** a configured consumer has a stale or missing project-core template id
  - **When** `startup-brief.sh`, `status.sh`, or `doctor.sh` runs
  - **Then** the output tells agents to review `.agent0/project-core.md.example` and update `.agent0/project-core.md`.

- [x] **Scenario: Missing source remains bootstrap, not template review**
  - **Given** `.agent0/project-core.md.example` exists but `.agent0/project-core.md` is absent
  - **When** advisory surfaces run
  - **Then** they emit the bootstrap advisory, not the configured-source review advisory.

- [x] No command auto-updates a consumer source marker during sync.

## Non-goals

- Auto-merging template content into `.agent0/project-core.md`.
- Requiring consumers to make their config identical to the example.
- Re-enabling prompt-time context injection.
- Syncing consumers other than the one explicitly requested.

## Open questions

- [x] None.

## Context / references

- `docs/specs/173-project-core-language-locale/` - source/example split.
- `docs/specs/174-bootstrap-advisories/` - bootstrap alerts.
- `docs/specs/175-project-core-local-renderer/` - local mirror renderer.
- `.agent0/project-core.md.example` - template surface.
- `.agent0/hooks/_brief-compose.sh`, `.agent0/tools/doctor.sh`, `.agent0/tools/sync-harness.sh` - advisory surfaces.
