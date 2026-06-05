# 156 — sync-exclude-od-regenerated-state

_Created 2026-06-05._

**Status:** shipped

**UI impact:** none

## Intent

Three Open-Design (`/product` OD-engine) files ship in the harness-sync manifest yet are **regenerated locally** by `.claude/skills/product/scripts/sync-open-design.ts` whenever a consumer runs `/product`. Because they are git-tracked under `.claude/skills/product/` (swept by `COPY_CHECK_RECURSIVE`) but mutate at runtime, every consumer that has ever run the OD-sync drifts to `!! customized` on them **forever** — a false "customization" that can never be reconciled (the consumer's copy is newer machine-generated state, not a hand edit) and that pollutes every `--check`/`--apply`. Surfaced by the 2026-06-05 `cognixse` sync: `od-catalog-index.json` (newer `snapshot_date`), `vendor/open-design/.cache/ds-index.json` (a literal cache, newer `generated_at`), and `vendor/open-design/MANIFEST.json` (an append-only `history[]` audit log with an extra `auto-apply` row). This is the same class spec 144 already fixed for the OD extraction cache (`*/runtime/od-sync/extracted-*`, statically excluded from the walk) — this spec extends that exclusion to the OD-sync-regenerated index/cache/manifest so a consumer's sync stays honest.

## Acceptance criteria

- [x] **Scenario: a consumer that ran `/product` syncs clean**
  - **Given** a consumer project whose OD-engine regenerated `od-catalog-index.json` / `ds-index.json` / `MANIFEST.json` (newer timestamps/history than the Agent0 baseline)
  - **When** `sync-harness.sh --check` (and `--apply`) runs against current Agent0
  - **Then** none of those three regenerated OD files appear as `!! customized` (no false customization, no spurious drift), and the run reports clean for them

- [x] **Scenario: the `/product` skill still works in a fresh consumer**
  - **Given** a brand-new consumer with no prior OD-sync
  - **When** `sync-harness.sh --apply` lays down the harness and the consumer later runs `/product`
  - **Then** the skill has (or regenerates) the OD state it needs — excluding these files from the shipped surface does not break `/product` (the engine regenerates what it owns; any genuinely-needed seed is still available)

- [x] **Scenario: an already-drifted consumer self-heals on the next sync**
  - **Given** a consumer (e.g. `cognixse`) currently carrying these three as `!! customized` with baseline entries
  - **When** the new exclusion lands and `--apply` runs
  - **Then** the stale baseline entries for the excluded paths are reconciled (removed from the baseline / no longer compared) so they stop being reported — without deleting the consumer's regenerated copies

- [x] The mechanism reuses the **spec-144 matcher shape** (a `case`-glob `COPY_CHECK_SEED` array + `is_seed()`, sibling to `COPY_CHECK_EXCLUDE`/`matches_exclude`) — a focused, named disposition, not a bespoke per-file hack. It is *seed* (copy-if-absent, never-reconcile), NOT *exclude* (drop entirely), because `od-catalog-index.json` is read at runtime and must reach a cold consumer (see `plan.md` D2).
- [x] `.cache/` OD state no longer produces consumer drift (it is a seed). Fully *untracking* the cache at the Agent0 source (`git rm --cached` + a source `.gitignore`) is a deliberate **non-goal** — the seed mechanism already removes the drift, which is the reported problem (see `plan.md` D1 + § Non-goals).

## Non-goals

- **Changing `sync-open-design.ts` / OD-engine behavior.** This spec is about the *shipped surface* (what the sync manifest propagates and compares), not how the OD-engine regenerates its state.
- **Excluding genuinely-static `/product` skill content.** Only the runtime-regenerated OD files are in scope; SKILL.md, references that are NOT regenerated, templates, etc. stay shipped.
- **A general "regenerated-file" framework.** Scope is the three identified OD paths (+ the `.cache/` dir), mirroring spec 144's targeted shape — not a generic predicate engine.
- **Auto-migrating consumer OD state.** The harness never mutates consumer-owned/regenerated content; the consumer's newer copies stay as-is.
- **Untracking the `ds-index.json` cache at the Agent0 source** (`git rm --cached` + a source `.gitignore`). The seed mechanism already removes its consumer drift; untracking is a separate cleanliness change with its own orphan-handling, not needed to fix the reported problem (`plan.md` D1).
- **Splitting `MANIFEST.json`** into a shipped stable file + a consumer-local history file (`plan.md` D4).

## Open questions

_All resolved at plan time (decisions + rationale in `plan.md` § Decisions); this spec ships with no deferred follow-ups._

- [x] **Per-file disposition.** RESOLVED → `plan.md` D1: all three are **seeds** (ship-once, never-reconcile). The runtime read-contract recon confirmed `od-catalog-index.json` is read at `/product` runtime (steps 02/14) so it must reach a cold consumer; `ds-index.json`/`MANIFEST.json` are not read at runtime but fold into the same one mechanism.
- [x] **Mechanism.** RESOLVED → `plan.md` D2: a new `COPY_CHECK_SEED` array + `is_seed()` + `process_seed()` (seed = copy-if-absent, never-reconcile), reusing the spec-144 *matcher shape* but NOT its full-exclude (which would break cold-start). Source-side gitignore/untracking of the cache was rejected as a non-goal.
- [x] **Baseline reconciliation.** RESOLVED → `plan.md` D3: seeds are not recorded in the manifest, so `write_baseline` drops a stale entry by omission and `reconcile_deletions` skips them — a drifted consumer self-heals in one `--apply`. Verified live against `cognixse` (now `= seed`, not `!! customized`).
- [x] **MANIFEST history split.** RESOLVED → `plan.md` D4: NO — seed semantics handle the whole-file drift; splitting is over-engineering (non-goal).

## Context / references

- **Motivating incident:** 2026-06-05 `cognixse` harness sync — three OD files flagged `!! customized` despite zero hand edits; root-caused to OD-engine regeneration (newer `snapshot_date`/`generated_at`/`history[]`). The other "customized" file (`.codex/hooks.json`) was a separate whitespace-only false-positive, already resolved.
- `docs/specs/144-sync-harness-gitignore-aware-walk/` — the precedent: git-aware walk + static exclude of `*/runtime/od-sync/extracted-*` (OD extraction cache). This spec extends that exclusion class.
- `docs/specs/141-od-sync-apply-completeness/` — OD-sync apply semantics (the engine that regenerates these files).
- `.claude/skills/product/scripts/sync-open-design.ts` — the OD-engine that writes `od-catalog-index.json`, `vendor/open-design/.cache/ds-index.json`, `vendor/open-design/MANIFEST.json`.
- `.agent0/tools/sync-harness.sh` — `COPY_CHECK_RECURSIVE` (`.claude/skills/` sweep, lines ~228), the spec-144 static exclude (`*/runtime/od-sync/extracted-*`, ~244/317), and the runtime-cache-orphan deletion pass (~747/800) the fix should mirror.
- `.agent0/context/rules/harness-sync.md` § Manifest scope (git-aware walk = tracked-only) + § Gotchas (whitespace false-positive, the sibling class).
