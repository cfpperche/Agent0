# 177 — spec-verify-advisory

_Created 2026-06-08._

**Status:** shipped

**UI impact:** none

## Intent

Agent0 specs declare intent (`spec.md`), plan (`plan.md`), and tasks (`tasks.md`), and the `/sdd tasks` flow ends with acceptance checks written as prose. But there is no first-class, **rerunnable** proof attached to a spec: nothing answers "run this spec's proof again and tell me if it still holds." The `/squad` done-gate (`squad.json:gate[]`) has this shape but only inside the heavyweight two-runtime build loop; the ordinary main-agent `/sdd` flow has no equivalent. This spec ports the *pattern* (not the substrate) from the studied `repository-harness` project, whose `story verify <id>` runs a stored command from repo root and persists pass/fail — adapted to Agent0's markdown+shell+advisory idiom: an opt-in `**Verify:**` declaration in a spec's `tasks.md`, a runtime-neutral `spec-verify.sh` tool that runs it and records the result to `notes.md`, and a non-blocking `spec-verify-advisory:` from the post-edit validator when a *shipped* spec that *declares* a verify command has no passing record. It serves any agent (Claude Code, Codex CLI) and any human re-checking whether a delivered spec's proof still passes.

## Acceptance criteria

- [x] **Scenario: declared command passes**
  - **Given** a spec dir whose `tasks.md` contains one or more `**Verify:** \`<command>\`` lines whose commands exit 0
  - **When** `bash .agent0/tools/spec-verify.sh docs/specs/NNN-<slug>` runs
  - **Then** each command runs from the repo root, the tool exits 0, and a timestamped result block recording each command + `pass` is appended to that spec's `notes.md` under a `## Verification log` section

- [x] **Scenario: declared command fails**
  - **Given** a spec dir whose `tasks.md` declares a `**Verify:**` command that exits non-zero
  - **When** `spec-verify.sh` runs on it
  - **Then** the tool exits 1, the failing command is reported, and the `notes.md` log records that command as `fail` (remaining commands still run and are recorded)

- [x] **Scenario: no command declared**
  - **Given** a spec dir whose `tasks.md` declares no `**Verify:**` line
  - **When** `spec-verify.sh` runs on it
  - **Then** the tool exits 2, prints a one-line "no verify command declared" notice, and does NOT modify `notes.md`

- [x] **Scenario: machine-readable output**
  - **Given** any spec dir
  - **When** `spec-verify.sh <dir> --json` runs
  - **Then** stdout is a single JSON object `{status, spec, commands:[{command,result}], passed, failed, declared}` and (with `jq` absent) the tool still exits with the correct code

- [x] **Scenario: advisory fires for an unverified shipped spec**
  - **Given** a `spec.md` with `**Status:** shipped` whose `tasks.md` declares a `**Verify:**` command, and whose `notes.md` has no passing verification record (or the latest record is `fail`)
  - **When** the post-edit validator (`.agent0/validators/run.sh`) runs
  - **Then** it emits exactly one `spec-verify-advisory: <spec> declares a verify command with no passing record — run bash .agent0/tools/spec-verify.sh <dir>` line and the validator's `ok` field is unchanged (non-blocking)

- [x] **Scenario: advisory stays silent without opt-in**
  - **Given** a shipped spec whose `tasks.md` declares NO `**Verify:**` command
  - **When** the validator runs
  - **Then** no `spec-verify-advisory:` is emitted for that spec (the mechanism is opt-in; absence of a declaration is never nagged)

- [x] The tool, rule doc, and tests propagate to consumers via existing sync globs (`.agent0/tools|*.sh`, `.agent0/context` recursive, `.agent0/tests` recursive); no change to `sync-harness.sh` glob lists is required.
- [x] A rule doc `.agent0/context/rules/spec-verify.md` documents the declaration syntax, tool, advisory, and override, matching the existing advisory-rule shape (frontmatter `paths:`, H2 sections, Gotchas).
- [x] This spec dogfoods itself: its own `tasks.md` declares a `**Verify:**` command and its `squad.json:gate[]` invokes `spec-verify.sh` on this spec dir.

## Non-goals

- No SQLite / database / compiled CLI — the studied project's substrate is explicitly rejected (markdown + shell only).
- No blocking gate — the advisory never flips the validator's `ok` field and never blocks a commit or a stop.
- No risk-lane / intake classification, no trace ledger, no backlog primitive (separate ideas from the same study; out of scope here).
- No auto-run of verify commands by the validator — running is explicit (`spec-verify.sh`) or via the squad gate; the validator only *advises*, it does not execute arbitrary spec commands.
- No nagging of specs that don't opt in (no `**Verify:**` declared → silent).
- Not a replacement for the visual-contract gate or the lint/typecheck/tdd advisories; it is a sibling in the same advisory family.

## Open questions

- [x] Canonical home for the `**Verify:**` declaration → resolved: `tasks.md` (the executable "do" file; keeps `spec.md` intent-pure). The tool also scans `spec.md` as a fallback for robustness.
- [x] Should a shipped spec with NO verify declared be nagged? → resolved: no (opt-in, anti-ceremony).
- [x] Where is the result persisted? → resolved: appended to the spec's `notes.md` under `## Verification log` (markdown, git-tracked, no new file).

## Context / references

- Studied project `repository-harness` (`/tmp/rh-study`): `docs/HARNESS.md` § Story Verification, `scripts/schema/002-story-verify.sql` (`verify_command`/`last_verified_at`/`last_verified_result`), `crates/harness-cli/src/infrastructure.rs` story-verify execution.
- Codex adoption analysis: `.agent0/.runtime-state/codex-exec/20260608T203313Z-rh-adopt/last-message.md` (ranked this #1 FILL-GAP).
- Sibling advisories: `.agent0/context/rules/tdd.md`, `lint-validator.md`, `typecheck-advisory.md`, `visual-contract.md`.
- Validator: `.agent0/validators/run.sh`; advisory emission idiom: `.agent0/hooks/propagation-advise.sh`.
- Adjacent done-gate: `.agent0/context/rules/squad.md`, `docs/specs/163-capacity-kit/squad.json`.
