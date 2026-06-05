# 156 — sync-exclude-od-regenerated-state

_Created 2026-06-05._

**Status:** draft

**UI impact:** none

## Intent

Three Open-Design (`/product` OD-engine) files ship in the harness-sync manifest yet are **regenerated locally** by `.claude/skills/product/scripts/sync-open-design.ts` whenever a consumer runs `/product`. Because they are git-tracked under `.claude/skills/product/` (swept by `COPY_CHECK_RECURSIVE`) but mutate at runtime, every consumer that has ever run the OD-sync drifts to `!! customized` on them **forever** — a false "customization" that can never be reconciled (the consumer's copy is newer machine-generated state, not a hand edit) and that pollutes every `--check`/`--apply`. Surfaced by the 2026-06-05 `cognixse` sync: `od-catalog-index.json` (newer `snapshot_date`), `vendor/open-design/.cache/ds-index.json` (a literal cache, newer `generated_at`), and `vendor/open-design/MANIFEST.json` (an append-only `history[]` audit log with an extra `auto-apply` row). This is the same class spec 144 already fixed for the OD extraction cache (`*/runtime/od-sync/extracted-*`, statically excluded from the walk) — this spec extends that exclusion to the OD-sync-regenerated index/cache/manifest so a consumer's sync stays honest.

## Acceptance criteria

- [ ] **Scenario: a consumer that ran `/product` syncs clean**
  - **Given** a consumer project whose OD-engine regenerated `od-catalog-index.json` / `ds-index.json` / `MANIFEST.json` (newer timestamps/history than the Agent0 baseline)
  - **When** `sync-harness.sh --check` (and `--apply`) runs against current Agent0
  - **Then** none of those three regenerated OD files appear as `!! customized` (no false customization, no spurious drift), and the run reports clean for them

- [ ] **Scenario: the `/product` skill still works in a fresh consumer**
  - **Given** a brand-new consumer with no prior OD-sync
  - **When** `sync-harness.sh --apply` lays down the harness and the consumer later runs `/product`
  - **Then** the skill has (or regenerates) the OD state it needs — excluding these files from the shipped surface does not break `/product` (the engine regenerates what it owns; any genuinely-needed seed is still available)

- [ ] **Scenario: an already-drifted consumer self-heals on the next sync**
  - **Given** a consumer (e.g. `cognixse`) currently carrying these three as `!! customized` with baseline entries
  - **When** the new exclusion lands and `--apply` runs
  - **Then** the stale baseline entries for the excluded paths are reconciled (removed from the baseline / no longer compared) so they stop being reported — without deleting the consumer's regenerated copies

- [ ] The exclusion follows the **spec-144 precedent** (static walk exclude + git-aware skip), not a new bespoke mechanism
- [ ] `.cache/` OD state is treated as a cache (gitignored at the Agent0 source and/or excluded from the manifest) — a cache must not be a tracked, shipped, drift-producing file

## Non-goals

- **Changing `sync-open-design.ts` / OD-engine behavior.** This spec is about the *shipped surface* (what the sync manifest propagates and compares), not how the OD-engine regenerates its state.
- **Excluding genuinely-static `/product` skill content.** Only the runtime-regenerated OD files are in scope; SKILL.md, references that are NOT regenerated, templates, etc. stay shipped.
- **A general "regenerated-file" framework.** Scope is the three identified OD paths (+ the `.cache/` dir), mirroring spec 144's targeted shape — not a generic predicate engine.
- **Auto-migrating consumer OD state.** The harness never mutates consumer-owned/regenerated content; the consumer's newer copies stay as-is.

## Open questions

- [ ] **Per-file disposition.** For each of the three: is it (a) pure cache → gitignore at source + drop from manifest (`ds-index.json` almost certainly this); (b) regenerated-per-consumer index → exclude from the comparison/manifest but keep a seed if `/product` needs one cold (`od-catalog-index.json`?); (c) append-only audit that should never ship (`MANIFEST.json` history)? Owner: plan-time, confirmed against `sync-open-design.ts`'s read/write contract.
- [ ] **Mechanism: static walk-exclude vs gitignore-at-source vs both.** Spec 144 used a static exclude pattern in `sync-harness.sh` (`*/runtime/od-sync/extracted-*`) PLUS a source-side `.gitignore`. Which combination here? A source-side gitignore also stops the file being tracked in Agent0 (correct for a cache; maybe wrong for a seed the skill ships). Owner: plan-time.
- [ ] **Baseline reconciliation for already-drifted consumers.** How do the now-excluded paths leave the recorded baseline cleanly (so `cognixse` stops reporting them) without a `!! customized (upstream-removed)` refusal storm? Likely the deletion/exclusion pass treats them like spec-144 runtime-cache orphans. Owner: plan-time.
- [ ] **Should `MANIFEST.json`'s history be split** (shippable pin vs runtime history), or is the whole file consumer-regenerated? Owner: plan-time, against the OD-engine.

## Context / references

- **Motivating incident:** 2026-06-05 `cognixse` harness sync — three OD files flagged `!! customized` despite zero hand edits; root-caused to OD-engine regeneration (newer `snapshot_date`/`generated_at`/`history[]`). The other "customized" file (`.codex/hooks.json`) was a separate whitespace-only false-positive, already resolved.
- `docs/specs/144-sync-harness-gitignore-aware-walk/` — the precedent: git-aware walk + static exclude of `*/runtime/od-sync/extracted-*` (OD extraction cache). This spec extends that exclusion class.
- `docs/specs/141-od-sync-apply-completeness/` — OD-sync apply semantics (the engine that regenerates these files).
- `.claude/skills/product/scripts/sync-open-design.ts` — the OD-engine that writes `od-catalog-index.json`, `vendor/open-design/.cache/ds-index.json`, `vendor/open-design/MANIFEST.json`.
- `.agent0/tools/sync-harness.sh` — `COPY_CHECK_RECURSIVE` (`.claude/skills/` sweep, lines ~228), the spec-144 static exclude (`*/runtime/od-sync/extracted-*`, ~244/317), and the runtime-cache-orphan deletion pass (~747/800) the fix should mirror.
- `.agent0/context/rules/harness-sync.md` § Manifest scope (git-aware walk = tracked-only) + § Gotchas (whitespace false-positive, the sibling class).
