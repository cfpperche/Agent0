# 084 — reminders-yaml-refactor

_Created 2026-05-24._

**Status:** shipped

## Intent

Refactor Agent0's reminders capacity (`.claude/REMINDERS.md` plain-bullet markdown → `.claude/reminders.yaml` structured YAML) and add two new fields ported from Anthill's `reminders.yaml` exemplar: `check_command` (a bash probe the agent can run to inform whether the reminder still applies) and `snooze` (push a reminder out of the readout window until a future date). Soft-delete via `status: done + completed_ts` replaces the current "deletion IS dismissal" discipline so the YAML carries audit history in-band rather than only via `git log`.

This is MS-4 of umbrella spec [080](../080-memory-system-scale-ready/spec.md) — porting the *mechanism* of structured reminders from Anthill without porting its *policy* (JSON Schema corpus, links-graph traversal, autonomous check execution). Anthill's exemplar shape (per `/tmp/research/anthill.md` line 110) is the reference; Agent0 picks the subset that earns its complexity at solo-founder + fork-at-scale. Current state: 12 plain bullets in `.claude/REMINDERS.md`, no programmable checks, no snooze, dismiss-as-delete. Target state: same surface (add/list/dismiss equivalent) plus `snooze`, `check`, soft-delete, stable IDs.

## Acceptance criteria

- [x] **Scenario: structured add**
  - **Given** `.claude/reminders.yaml` exists with the canonical top-level `reminders:` list (possibly empty)
  - **When** `/remind add "<text>" [--due <DATE>] [--check '<cmd>'] [--links <a,b,c>]` runs
  - **Then** a new entry appends to `reminders:` with fields `id` (stable, format `r-YYYY-MM-DD-<short-slug>`), `created` (today's ISO date), `context` (the `<text>`), `status: pending`, plus the optional `due` / `check_command` / `links` when supplied; no other side effect

- [x] **Scenario: readout filters out done and not-yet-due snoozed**
  - **Given** `reminders.yaml` contains a mix of `status: pending`, `status: done`, and `status: snoozed` entries (some with `snoozed_until` in the past, some in the future)
  - **When** SessionStart fires `reminders-readout.sh`
  - **Then** the `=== REMINDERS ===` block surfaces only entries with `status: pending` OR `status: snoozed` with `snoozed_until ≤ today`; `done` entries and future-snoozed entries are excluded

- [x] **Scenario: snooze sets status + snoozed_until**
  - **Given** a pending entry with `id: r-2026-05-24-foo`
  - **When** `/remind snooze r-2026-05-24-foo 7d` runs
  - **Then** the entry's `status` flips to `snoozed` and `snoozed_until` is set to `today + 7 days` (ISO date)

- [x] **Scenario: done is soft-delete with audit timestamp**
  - **Given** a pending entry with `id: r-2026-05-24-foo`
  - **When** `/remind done r-2026-05-24-foo` runs
  - **Then** the entry's `status` flips to `done`, `completed_ts` is set to the current UTC ISO-8601 timestamp, the entry stays in `reminders.yaml` (not removed)

- [x] **Scenario: check runs the probe and surfaces output**
  - **Given** a pending entry whose `check_command` is `echo "still applicable"`
  - **When** `/remind check r-2026-05-24-foo` runs
  - **Then** the command is executed in the repo's working directory and its stdout/stderr/exit-code are reported to the agent verbatim; the YAML is NOT mutated regardless of exit code (human-in-loop decides next action)

- [x] **Scenario: snooze accepts duration shorthand + ISO date**
  - **Given** a pending entry
  - **When** `/remind snooze <id> <duration>` runs with `<duration>` matching one of `^[0-9]+(d|w|m)$` (days/weeks/months) OR `^[0-9]{4}-[0-9]{2}-[0-9]{2}$` (ISO date)
  - **Then** both shapes are accepted; any other shape is refused with `snooze: duration must be Nd|Nw|Nm or YYYY-MM-DD (got: <value>)` and the YAML is unchanged

- [x] **Scenario: dismiss-by-position still works for UX continuity**
  - **Given** `/remind list` shows entries numbered 1..N (1-indexed against the surfaced filtered list)
  - **When** `/remind done <N>` or `/remind snooze <N> <duration>` runs with `N` as a positive integer
  - **Then** the Nth listed entry is operated on by its stable `id` — positions resolve to IDs at command time, IDs remain canonical in storage

- [x] `.claude/reminders.yaml` exists, parses as valid YAML, top-level key is `reminders:` (a list)
- [x] `.claude/skills/remind/SKILL.md` argument-hint reflects the new subcommands (`add`/`list`/`dismiss`-alias-for-done/`done`/`snooze`/`check`)
- [x] `.claude/hooks/reminders-readout.sh` reads YAML (via `yq` with a fallback message if absent) and emits the same framed `=== REMINDERS ===` block
- [x] `.claude/rules/reminders.md` rewritten for the new shape (storage, subcommands, soft-delete discipline, override grammar carryover)
- [x] `.claude/REMINDERS.md` deleted from the working tree (git history preserves it); existing 12 bullets migrated manually into `reminders.yaml` in a single pre-commit (no script)
- [x] Umbrella 080 MS-4 row flips to ✓ shipped; the closure scenario in umbrella `spec.md` ticks

## Non-goals

- **NG-1: No JSON Schema validator.** Anthill ships `reminders.schema.json` (74 lines) validated via `schema-validate.sh`. Agent0 keeps schema enforcement in the skill body (validate at write time) — the YAML shape itself is the contract. Adding a JSON Schema runtime + python3+jsonschema dep is policy-leak (umbrella NG-3 spirit).

- **NG-2: No autonomous `check_command` execution at SessionStart.** The readout surfaces context + check_command (text); the agent runs the probe explicitly via `/remind check <id>` when relevant. Auto-running every check on every session boot inflates latency (a check that spawns `gh issue view` is ~500ms-2s) and breaks the contract-not-promise discipline (see `.claude/rules/delegation.md` § Why DONE_WHEN exists).

- **NG-3: No links-graph traversal.** Anthill's `links: [...]` array supports cross-reference walks. Agent0 keeps `links` as a flat hint field for human grep — no resolver, no graph queries, no link-validity checks.

- **NG-4: No migration script.** Umbrella decision (MS-4 row notes column). 12 entries fit a one-shot manual translation; investing in conversion tooling for a single-time cutover is over-engineering.

- **NG-5: No `close_note` field.** Anthill carries a free-prose `close_note` on `status: done` entries. Agent0 defers this — `completed_ts` is the audit signal; richer post-mortem belongs in `.claude/memory/` or `git log`, not in the reminders bucket. Add later if dogfood surfaces the need.

## Open questions

- [x] **OQ-1** Soft-delete default vs hard-delete default. **RESOLVED 2026-05-24:** soft-delete default. `/remind done <id>` flips `status: done` + sets `completed_ts`; entry stays in `reminders.yaml`. Audit in-band + via `git log`. Monotonic file growth mitigated by deferred `/remind prune` (rule-of-three: scaffold only if real friction surfaces). Casa com 082/083 pattern (state grows; cap/decay are separate questions).

- [x] **OQ-2** `dismiss` subcommand fate. **RESOLVED 2026-05-24 in plan:** keep as silent alias for `done`. Argument-hint surfaces `done` as primary; `dismiss <N|id>` works without warning so prior muscle memory + any cross-references in conversation history don't break. Soft-deprecation is over-engineering for a name change.

- [x] **OQ-3** `yq` dependency. **RESOLVED 2026-05-24:** advise + Python fallback. Hook tries `yq` first; if absent, falls back to `python3 -c "import yaml; ..."` (PyYAML is pip-installable and broadly present). If neither is available, emits raw YAML inside the framed block with a one-line `(yq/python3+yaml absent — install yq or pip install pyyaml for filtered readout)` advisory. Never blocks SessionStart. Degrades visibly, not silently.

- [x] **OQ-4** Stable ID format. **RESOLVED 2026-05-24 in plan:** `r-YYYY-MM-DD-<short-slug>` (Anthill convention). Sortable + human-grokkable. Slug derived from first 3-5 meaningful words of context, lowercased + kebab-cased, max ~30 chars.

- [x] **OQ-5** Readout: inline `check_command` text vs hint-only. **RESOLVED 2026-05-24 in plan:** inline. The user opted into a check by adding it; hiding the command behind a "use /remind check <id> to see" detour adds friction without containment value. Inline preserves "agent reads, agent decides".

- [x] **OQ-6** Sync-harness propagation. **RESOLVED 2026-05-24 in plan:** capacity propagates (skill + hook + rule + Python helper); content does not. Skill creates `.claude/reminders.yaml` on first `add`. No `.example` template, no `.gitkeep` for the state file. Mirrors `.claude/memory/` pattern (sync ships the scaffold dir, not the entries).

## Context / references

- `.claude/rules/reminders.md` — current capacity spec; this spec rewrites it
- `.claude/REMINDERS.md` — current state, 12 plain bullets (to migrate)
- `.claude/skills/remind/SKILL.md` — current skill implementation
- `.claude/hooks/reminders-readout.sh` — current SessionStart readout hook
- `docs/specs/080-memory-system-scale-ready/spec.md` § MS-4 — umbrella row + non-goals (NG-3 drawer-taxonomy policy-leak)
- `/tmp/research/anthill.md` lines 110, 319, 346 — Anthill `reminders.yaml` schema reference
- `/home/goat/anthill/.anthill/memory/reminders.yaml` — Anthill exemplar (id/created/due/context/check_command/links/status/snoozed_until/completed_ts/close_note shape)
- `.claude/rules/memory-placement.md` — 3-bucket model (reminders is project-shared via clone, NOT shipped to forks; only the capacity propagates)
- `.claude/rules/delegation.md` § Why DONE_WHEN exists — informs NG-2 (no autonomous check)
- `docs/specs/082-memory-frontmatter-schema/spec.md` + `docs/specs/083-memory-events-journal/spec.md` — sibling MS-1/MS-2 specs whose patterns (schema in skill body, soft state via status field) this spec mirrors
