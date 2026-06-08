# 174 - bootstrap-advisories

_Created 2026-06-08._

**Status:** shipped
**UI impact:** none

## Intent

Spec 173 introduced `.agent0/project-core.md.example` as an Agent0-shipped opinion for consumer language/locale bootstrap, while keeping each consumer's real `.agent0/project-core.md` consumer-owned. That split is correct, but it creates an incomplete-harness state: agents can run in a synced consumer where the example exists, the real project core is still absent, and no one is warned that the always-on project framing has not been configured. This spec adds advisory-only bootstrap alerts for that state, and requires those alerts to disappear immediately after the consumer creates `.agent0/project-core.md` and reruns sync.

## Acceptance criteria

- [x] **Scenario: Sync warns when project-core bootstrap is pending**
  - **Given** a consumer has `.agent0/project-core.md.example` but no `.agent0/project-core.md`
  - **When** `sync-harness.sh --apply` or `--check` completes
  - **Then** it emits a `bootstrap-advisory:` line explaining how to copy/customize the source and rerun sync.

- [x] **Scenario: Startup and status warn agents when project-core bootstrap is pending**
  - **Given** a consumer has `.agent0/project-core.md.example` but no `.agent0/project-core.md`
  - **When** `startup-brief.sh` or `status.sh` composes live harness state
  - **Then** the output includes a short `=== bootstrap ===` block that names the missing source and the rerun command.

- [x] **Scenario: Doctor reports pending bootstrap as advisory, not broken**
  - **Given** a consumer has `.agent0/project-core.md.example` but no `.agent0/project-core.md`
  - **When** `doctor.sh` runs
  - **Then** it reports project-core bootstrap as `advisory` and exits successfully if no other broken checks exist.

- [x] **Scenario: Bootstrap alerts disappear after configuration**
  - **Given** a consumer creates `.agent0/project-core.md` from the example and reruns sync
  - **When** `sync-harness.sh`, `startup-brief.sh`, `status.sh`, or `doctor.sh` runs afterward
  - **Then** no pending-bootstrap warning appears for project-core.

- [x] **Scenario: No example means no project-core bootstrap warning**
  - **Given** an older or partial harness has neither `.agent0/project-core.md.example` nor `.agent0/project-core.md`
  - **When** the advisory surfaces run
  - **Then** they do not emit a project-core bootstrap warning, because there is no shipped bootstrap opinion to act on.

- [x] No command creates `.agent0/project-core.md` automatically.

## Non-goals

- Auto-configuring project-core content for any consumer.
- Creating a generic bootstrap registry before at least two more bootstrap-required surfaces exist.
- Treating pending project-core bootstrap as a hard failure.
- Re-enabling prompt-time context injection.
- Syncing consumer repositories as part of Agent0 implementation validation unless explicitly requested after the spec is validated.

## Open questions

- [x] None.

## Context / references

- `docs/specs/173-project-core-language-locale/` - introduced project-core source/example split.
- `.agent0/context/rules/harness-sync.md` - project-core mirror contract.
- `.agent0/tools/sync-harness.sh` - sync surface that copies the example and mirrors source when present.
- `.agent0/hooks/_brief-compose.sh` - shared startup/status composition library.
- `.agent0/tools/doctor.sh` - harness health checks.
