# 081 — compact-history-runtime-readme

_Created 2026-05-23. Shipped 2026-05-23._

**Status:** shipped
**Parent:** [080-memory-system-scale-ready](../080-memory-system-scale-ready/) (covers MS-3 + MS-6 of the umbrella gap matrix)

## Intent

Two quick-win mechanisms from the 080 umbrella that ship orthogonally — neither depends on the other or on the umbrella's schema/event-sourcing children (082/083). Both correct already-felt or already-documented friction with zero new primitives:

- **MS-3 — Per-compaction snapshot history.** Replace `.claude/COMPACT_NOTES.md` (overwritten per compaction) with append-only `.claude/.compact-history/<ISO>.md` (one file per compaction event). Fixes the documented gotcha in `.claude/rules/compaction-continuity.md` § *Gotchas*: *"The snapshot file is overwritten each compaction, not appended. Multiple compactions in one session lose the earliest snapshot."*

- **MS-6 — Runtime-state subsystem README.** Ship `.claude/.runtime-state/README.md` enumerating the state subsystems already present in Agent0 (`.runtime-state/`, `.browser-state/`, `.delegation-state/`, `.routines-state/`, `.rule-load-debug.jsonl`). Pattern borrowed from Anthill's `.anthill/runtime/README.md` — pure documentation, no new primitives. README is git-tracked via gitignore exception even though the state contents inside the dir are not.

Together: ~210 LOC, zero schema dependencies, can ship in one session of focused work.

## Acceptance criteria

### MS-3 — Per-compaction snapshot history

- [x] **Scenario: First compaction creates a new file** — **Given** a session with no prior compactions and an empty `.claude/.compact-history/`; **When** the user triggers `/compact` and the `PreCompact` hook fires; **Then** a file matching `.claude/.compact-history/YYYY-MM-DDTHH-MM-SS*.md` is created with the same snapshot shape `pre-compact.sh` writes today.

- [x] **Scenario: Second compaction preserves the first** — **Given** a session that has already compacted once (one file in `.claude/.compact-history/`); **When** `/compact` runs again; **Then** two distinct `.md` files exist under `.claude/.compact-history/`, with strictly increasing ISO-timestamp prefixes, and neither has been overwritten.

- [x] **Scenario: SessionStart on `source=compact` injects the latest snapshot** — **Given** multiple `.claude/.compact-history/*.md` files exist (some from prior compactions of this or earlier sessions); **When** SessionStart fires with `source="compact"`; **Then** `session-start.sh` reads the file with the lexicographically-largest filename (which equals chronologically-latest given ISO-timestamp naming) and injects its contents as `additionalContext` — semantically identical to today's behavior on `COMPACT_NOTES.md`.

- [x] **Scenario: Retention cap honored** — **Given** `.claude/settings.json` carries `compactHistory.keepLast: 5` AND `.claude/.compact-history/` contains 6 files; **When** the PreCompact hook runs again and creates the 7th file; **Then** exactly the 5 most-recent files remain on disk; older files are deleted; the cap is configurable (default `keepLast: 20` if no setting present).

- [x] `.claude/.compact-history/` is gitignored — the directory exists per-machine, contents are ephemeral.

- [x] `.gitignore` is updated to ignore the new path (`.claude/.compact-history/`) and `.claude/COMPACT_NOTES.md` is removed from any ignore entry that previously referenced it (it should no longer be written).

- [x] `.claude/rules/compaction-continuity.md` is updated:
  - § *Flow* references the new per-event path instead of the overwritten file
  - § *Files* lists `.claude/.compact-history/<ISO>.md` as the snapshot location
  - § *Gotchas* has the "multiple compactions lose the earliest snapshot" line **removed** (resolved by this spec), with a brief note that the prior single-file model was retired by 081
  - The rule explicitly notes the rule's CLAUDE.md anchor (or the inverse — CLAUDE.md updated if the rule's filename references appear there)

- [x] `.claude/hooks/pre-compact.sh` writes to `.claude/.compact-history/<ISO>.md` (new filename per call) instead of overwriting `.claude/COMPACT_NOTES.md`.

- [x] `.claude/hooks/session-start.sh` on `source="compact"` reads the lex-greatest `.claude/.compact-history/*.md` and injects it; falls back gracefully (no inject, no error) if the directory is missing or empty.

- [x] `.claude/COMPACT_NOTES.md` is removed from the repo if it was tracked, and from any read paths in `session-start.sh`. (If it was always gitignored, no source change needed; just remove the file-path references.)

### MS-6 — Runtime-state subsystem README

- [x] **Scenario: README exists at the canonical path** — **Given** Agent0 freshly cloned; **When** the user lists `.claude/.runtime-state/`; **Then** `README.md` is present (git-tracked via gitignore exception) and the directory's other contents are gitignored as before.

- [x] **Scenario: README enumerates all current subsystems** — **Given** `.claude/.runtime-state/README.md`; **When** read; **Then** the following are listed with 1-2 sentence ownership/purpose statements: `.claude/.runtime-state/` (verifier last-run snapshot — owned by `runtime-introspect`), `.claude/.browser-state/` (Playwright auth state — owned by `mcp-recipes`), `.claude/.delegation-state/` (per-agent loop-budget counters — owned by `delegation`), `.claude/.routines-state/` (queued + completed routine renders — owned by `routines`), `.claude/.rule-load-debug.jsonl` (opt-in instruction-load instrumentation — owned by `rule-load-debug`), `.claude/.compact-history/` (per-compaction snapshots — owned by `compaction-continuity`, added by this spec).

- [x] **Scenario: Each enumerated subsystem cross-references its rule** — **Given** the README enumerates a subsystem; **When** a reader follows the entry; **Then** the entry includes a path to the relevant rule under `.claude/rules/` so the reader can deepen on demand without re-grepping.

- [x] **Scenario: README propagates to forks** — **Given** Agent0 ships the README via `.claude/tools/sync-harness.sh` manifest; **When** a fork runs the sync; **Then** `.claude/.runtime-state/README.md` is included in the synced fileset (verified by inspecting the harness-sync-baseline manifest and the post-sync state).

- [x] `.gitignore` exception correctly tracks the README while ignoring sibling state files. Two lines under the `.claude/.runtime-state/` block: ignore the dir contents, then `!.claude/.runtime-state/README.md`.

- [x] `.claude/harness-sync-baseline.json` (or whatever the sync manifest is canonically called) includes the README path.

- [x] The README states it does NOT enumerate `.claude/.skill-state/` or any future state subsystem unless it's actually present; future additions update the README in the same commit that ships the subsystem (documented as a discipline at the bottom of the README).

## Non-goals

- **NG-A — No new state subsystems.** MS-6 documents what's already there. Adding a 7th subsystem is a future spec's call.
- **NG-B — No introspection or query tool over `.compact-history/<ISO>.md`.** The files are read by `SessionStart` only; humans grep if they want history. Building a `claude-compact-history list` or similar tool is out of scope.
- **NG-C — No semantic compression or diff between compaction events.** Each file is a verbatim snapshot per the existing `pre-compact.sh` logic. We are not deduping or compressing.
- **NG-D — No relocation of the README to a different path** (e.g. `.claude/STATE-LAYOUT.md` at the top of `.claude/`). The README lives inside `.claude/.runtime-state/` per the Anthill pattern, with a gitignore exception, because the discovery angle is "I'm looking at `.claude/.*-state/` and want to understand what's here". Top-level placement was considered and rejected in design (see 080 OQ-discussion).
- **NG-E — This spec does NOT introduce, depend on, or co-ship the umbrella's other mechanisms** (MS-1 schema, MS-2 event-sourcing, MS-4 reminders.yaml, MS-5 cap+query, MS-7 decay). 081 is the pure quick-win; sibling specs cover the rest.
- **NG-F — Respects parent NG-1.** Nothing in 081 reads from or writes to `~/.claude/projects/<path>/memory/` (CC auto-memory). Both subsystems touched by 081 are project-state, not user-state.

## Open questions

- [x] **OQ-1** Should `.claude/.compact-history/` be created on-demand by `pre-compact.sh` or pre-exist via a `.gitkeep` (with the README inside it)? Lean: pre-exist with README + `.gitkeep` so a fresh fork has the directory immediately discoverable post-clone. Locked at plan time.
- [x] **OQ-2** Filename for `.compact-history/<ISO>.md` — strict ISO-8601 `YYYY-MM-DDTHH-MM-SSZ.md`, or include a short suffix for tie-breaking (multiple compactions within one second)? Lean: ISO with nanosecond fallback (`YYYY-MM-DDTHH-MM-SS-NNNNNNNNN.md`) so lex order = chrono order even under contention. Locked at plan time.
- [x] **OQ-3** Should the `keepLast` retention cap be hard-coded (e.g. 20) or settings-driven from the start? Decision: settings-driven with default 20. Cheap to add; avoids a future migration. The setting key is `compactHistory.keepLast` in `.claude/settings.json`.
- [x] **OQ-4** Does MS-6's README enumerate any state subsystems that don't yet exist (e.g. `.claude/.memory-events/` from MS-2 in spec 083)? Decision: NO — the README enumerates only what's present at 081-ship time. Future specs that add state subsystems update the README in their own commit (documented as discipline).

## Context / references

- Parent umbrella: [080-memory-system-scale-ready](../080-memory-system-scale-ready/)
- `.claude/rules/compaction-continuity.md` — current behavior; this spec supersedes the overwrite section
- `.claude/rules/runtime-introspect.md` — owner of `.claude/.runtime-state/`, the canonical sibling subsystem
- `.claude/rules/mcp-recipes.md` § *Authenticated workflow* — owner of `.claude/.browser-state/`
- `.claude/rules/delegation.md` — owner of `.claude/.delegation-state/`
- `.claude/rules/routines.md` — owner of `.claude/.routines-state/`
- `.claude/rules/rule-load-debug.md` — owner of `.claude/.rule-load-debug.jsonl`
- `.claude/hooks/pre-compact.sh` — file to modify for MS-3
- `.claude/hooks/session-start.sh` — file to modify for MS-3 (the `source="compact"` branch)
- `.claude/tools/sync-harness.sh` + the harness-sync manifest — confirm README propagation
- Anthill source pattern: `/home/goat/anthill/.anthill/runtime/README.md` (template for our README's shape; pattern only, no content port)
