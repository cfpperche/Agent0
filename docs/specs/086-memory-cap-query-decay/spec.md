# 086 — memory-cap-query-decay

_Created 2026-05-24._

**Status:** shipped

## Intent

Ship the scale-handling mechanisms for `.claude/memory/` — three coupled surfaces that turn the bucket from "small founder-curated set" into "viable at 100-500 entries". Combines MS-5 + MS-7 of umbrella [080](../080-memory-system-scale-ready/) into one spec because they share the same input shape (the frontmatter schema from 082) and the same output surface (the projection helper from 083, plus a SessionStart readout). Splitting them would duplicate scaffold overhead without buying review clarity.

Three layers:

1. **Cap on `MEMORY.md` index lines** — 250 chars per projected line. Today's MEMORY.md has 13 entries; 2 already exceed the cap (max 353 chars). The cap is enforced at projection time, not at write time — `memory-project.sh` advises on each overflow with a `memory-cap-advisory:` line naming the file; the founder rewrites the description shorter. No auto-truncation; the cap exists to keep the index scannable, and a truncated bullet hides exactly the half a reader would have needed.
2. **`memory-query.sh`** — search + filter helper for entry bodies and frontmatter. Subcommands `search <pattern>` (full-body grep), `list [--type=X|--stale=Nd]` (filter the index by frontmatter type or staleness), `confirm <name>` (bump `last_accessed` + `confirmed_count` when re-validating an entry). The mechanism that makes the bucket searchable at 100+ entries, where eyeballing MEMORY.md stops working.
3. **Decay engine** — reads `last_accessed` / `created_at` / `confirmed_count` frontmatter (per 082 schema) and computes a staleness score with a transparent default formula. Surfaces stale entries via SessionStart readout advisory (`memory-decay-advisory: N entries stale; run /memory-query list --stale=...`). Never auto-archives. Forks override the formula + numerics in `.claude/memory.config.json` (shipped as starter per umbrella OQ-4 tentative).

Includes a one-shot **schema backfill** for the 13 existing Agent0 entries (populate `created_at` from git-introduction, `last_accessed` from today, `confirmed_count: 0`) so the query + decay layers have data on day one. Manual one-shot per umbrella NG-4 spirit; no migration tooling for forks (the schema is optional, forks adopt opportunistically).

This is the last child of umbrella 080. Closure flips the umbrella's MS-5 + MS-7 rows to ✓ and ships the full 7-mechanism set.

## Acceptance criteria

- [x] **Scenario: cap advisory on overflow**
  - **Given** an entry whose `description` frontmatter projects to a `MEMORY.md` line > 250 chars
  - **When** `bash .claude/tools/memory-project.sh` regenerates the index
  - **Then** the projected line is still emitted (no truncation) but a `memory-cap-advisory:` line is appended to stderr naming the file + actual length, and the script's exit code stays 0 (advisory, not blocking)

- [x] **Scenario: query by pattern surfaces full-body matches**
  - **Given** memory entries containing the text "hooks" somewhere in their body or frontmatter
  - **When** `bash .claude/tools/memory-query.sh search hooks` runs
  - **Then** each matching entry's path + one-line context is printed to stdout; matches scan both `description:` frontmatter and free-prose body; the search is case-insensitive by default

- [x] **Scenario: list filters by type**
  - **Given** entries with mixed `metadata.type` values (e.g. `project` / `reference`)
  - **When** `bash .claude/tools/memory-query.sh list --type=reference` runs
  - **Then** only entries whose frontmatter `metadata.type` equals `reference` are listed, with their `name` + `description`; entries of other types are excluded

- [x] **Scenario: list filters by staleness**
  - **Given** entries with `last_accessed` timestamps spread across the past 90 days
  - **When** `bash .claude/tools/memory-query.sh list --stale=30d` runs
  - **Then** only entries whose `last_accessed` is older than `today − 30 days` are listed; entries without `last_accessed` are treated as stale (their non-presence implies never confirmed); the staleness threshold accepts the same `Nd|Nw|Nm` shorthand as `/remind snooze`

- [x] **Scenario: confirm bumps frontmatter audit fields**
  - **Given** an entry `agent0-purpose.md` with `confirmed_count: 0` and no `last_accessed`
  - **When** `bash .claude/tools/memory-query.sh confirm agent0-purpose` runs
  - **Then** the entry's `last_accessed` is set to today's ISO date and `confirmed_count` is incremented to 1; the change is captured by `git log` of the entry file (the memory-events-journal hook does NOT fire — `confirm` writes directly via Python, bypassing the tool-surface the journal hook listens on; documented in 086/notes.md as a known gap)

- [x] **Scenario: decay readout surfaces stale entries**
  - **Given** ≥1 entry whose staleness score (per the default formula) exceeds the threshold
  - **When** SessionStart fires the decay readout hook
  - **Then** a `=== MEMORY DECAY ===` framed block is emitted with one line per stale entry (`<name> — stale <N>d, confirmed <M>x`) plus a guidance line `run bash .claude/tools/memory-query.sh list --stale=<N>d` to inspect; empty case emits the frame with `(no stale entries)`

- [x] **Scenario: decay never auto-archives**
  - **Given** an entry well past any reasonable staleness threshold
  - **When** the decay engine evaluates it
  - **Then** the entry file is NOT moved, deleted, renamed, or mutated in any way; only the advisory line is emitted; the founder (or agent) decides whether to confirm / archive / delete via explicit action

- [x] **Scenario: config overrides default formula**
  - **Given** `.claude/memory.config.json` declares `decay.formula` and/or `decay.threshold_days` overrides
  - **When** the decay engine runs
  - **Then** the override values are used in place of the defaults; missing keys fall back to defaults; malformed JSON triggers a `memory-config-advisory:` warning and the defaults run

- [x] `.claude/tools/memory-query.sh` exists, is executable, supports `search` / `list` / `confirm` / `decay` subcommands (OQ-4 resolution: single script)
- [x] `.claude/tools/memory-project.sh` updated with the 250-char cap check (advisory, not blocking)
- [x] `.claude/hooks/memory-decay-readout.sh` exists, registered at SessionStart, emits the framed block
- [x] `.claude/memory.config.json` shipped as starter template at repo root with documented default values + comments
- [x] All 13 existing Agent0 memory entries have `metadata.created_at` + `metadata.last_accessed` + `metadata.confirmed_count` populated (backfill script run once during ship)
- [x] `.claude/rules/memory-placement.md` updated: new § *Cap / query / decay* documenting the 3 surfaces + override grammar
- [x] Umbrella 080 MS-5 + MS-7 rows flip to ✓ shipped; the `Scenario: 086 closure` checkbox ticks

## Non-goals

- **NG-1: No auto-archive / auto-delete on staleness.** Decay surfaces advisory; the human (or explicit `/memory-archive` command if later added) acts. Anthill ships `auto_archive: true` as a fork-toggle; Agent0 explicitly defaults `auto_archive: false` and the v1 helper doesn't even read the toggle. The mechanism is observation, not removal.

- **NG-2: No read-detection hook for `last_accessed`.** Anthill's read-detection (hook on file open / grep / search) was reported fragile in the deep-dive research. Agent0's `last_accessed` is bumped only via explicit `memory-query.sh confirm <name>`. The honest signal "I re-validated this entry and it's still useful" beats the noisy signal "this file was opened by a grep". Re-visit if 086 dogfood shows systemic under-confirmation.

- **NG-3: No frozen decay thresholds shipped.** The default formula + threshold values live in `.claude/tools/memory-query.sh` as documented constants (e.g. `default_threshold_days=60`), but `.claude/memory.config.json` overrides them. Forks at different scales pick different thresholds. Agent0 doesn't claim 60d is correct for any fork — it's a placeholder that's transparent + cheap to change.

- **NG-4: No graph / tag / link traversal in `memory-query.sh`.** Search is grep + frontmatter filter. Anthill's drawer + tier + dimension model is rejected by umbrella NG-3 (policy-leak). The query helper is a structural index, not a knowledge graph.

- **NG-5: No JSON Schema for `memory.config.json`.** Same posture as 082 (frontmatter schema in writer, not separate JSON Schema file) and 084 (reminders.yaml shape in helper). The config file's shape is documented in the script body + this spec; out-of-spec keys are ignored with an advisory.

- **NG-6: No migration tooling for forks.** The schema backfill is a one-shot script run by Agent0 to populate its own 13 entries. Forks adopting the capacity gradually populate the new frontmatter fields as entries get touched. No "migrate-all-forks" tooling ships.

## Open questions

- [x] **OQ-1** Default decay formula. **RESOLVED 2026-05-24:** simple linear. `score = (today − last_accessed_or_created_at).days − confirmed_count × 14`. Entries without `last_accessed` fall back to `created_at` (a brand-new entry isn't stale on day 1). Default threshold: 60 days. Each `confirm` action discounts ~2 weeks. Transparent, easy to reason about, easy for forks to tweak (single constant `14` for boost weight, single threshold `60`).

- [x] **OQ-2** Decay readout fire policy. **RESOLVED 2026-05-24 in plan:** always-fire. Empty case emits `(no stale entries)` inside the framed block (mirrors REMINDERS readout). Capacity discoverability > SessionStart noise; the empty frame is ~3 lines and signals "the decay engine is alive".

- [x] **OQ-3** Cap advisory destination. **RESOLVED 2026-05-24 in plan:** stderr only. Consistent with other advisories (`tdd-advisory:` / `lint-advisory:` etc per `.claude/rules/delegation.md`). No log file accumulates.

- [x] **OQ-4** Single script vs two. **RESOLVED 2026-05-24 in plan:** single `memory-query.sh` with 4 subcommands (`search` / `list` / `confirm` / `decay`). Idiomatic dispatcher pattern (git/kubectl style). Readout hook calls `memory-query.sh decay --readout`.

- [x] **OQ-5** Variadic `confirm`. **RESOLVED 2026-05-24 in plan:** yes. `memory-query.sh confirm a b c` mutates all 3 entries atomically. Cheap to implement (loop over args), common in real review sessions.

- [x] **OQ-6** Backfill `created_at` source. **RESOLVED 2026-05-24 in plan:** per-entry git-introduction time via `git log --follow --format=%aI -- <file> | tail -1`. True signal preserved (matches 084 T2 migration pattern). `last_accessed` defaults to today (no honest pre-spec read signal exists).

## Context / references

- `docs/specs/080-memory-system-scale-ready/spec.md` § MS-5 + MS-7 — umbrella row definitions + non-goals (NG-3 / NG-4) that this spec inherits
- `docs/specs/082-memory-frontmatter-schema/spec.md` — frontmatter schema this spec depends on; `metadata.created_at` / `metadata.last_accessed` / `metadata.confirmed_count` are optional fields declared there
- `docs/specs/083-memory-events-journal/spec.md` — projection helper (`memory-project.sh`) this spec extends with cap enforcement; event journal that catches the `confirm` mutations as `update` events
- `docs/specs/084-reminders-yaml-refactor/spec.md` — pattern reference for "script body holds the schema, no separate JSON Schema runtime"; also pattern for `Nd|Nw|Nm|YYYY-MM-DD` duration shorthand reused in `--stale=`
- `.claude/rules/memory-placement.md` — 3-bucket model; this spec adds the § *Cap / query / decay* subsection
- `.claude/memory/MEMORY.md` — current 13-entry projection (2 entries already over 250 chars: `consumer-contract-discipline` at 353, `anthill-port-workflow` at 345)
- `.claude/memory/anthill-archived.md` — Anthill is the quality reference; the decay-engine port carries Anthill's mechanism without policy (auto_archive=false, drawer-less)
- `/tmp/research/anthill.md` lines 258, 346, 377 — Anthill's `memory-decay.sh` + `memory-confirm.sh` + read-detection hook; informs NG-2 (read-detection rejected as fragile per research)
- `.claude/memory/feedback_speculative_observability.md` — rule-of-three demand test; relaxed here because the umbrella is shipping the mechanism set, but the *advisory* posture (no auto-action) honors the spirit
- `.claude/rules/delegation.md` § *Advisories* — `memory-cap-advisory:` / `memory-config-advisory:` / `memory-decay-advisory:` follow the project advisory grammar
