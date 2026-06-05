# 156 — sync-exclude-od-regenerated-state — plan

_Drafted from `spec.md` on 2026-06-05. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Add a new **seed-file** category to `sync-harness.sh` — `COPY_CHECK_SEED` — with *ship-once, never-reconcile* semantics: a seed file is **copied only if absent** in the consumer, and once present is **never compared, flagged `!! customized`, overwritten, or deleted**. Seeds are **not recorded in the manifest** (so they get no baseline entry and the deletion pass leaves them alone), which means an already-drifted consumer (e.g. `cognixse`, whose baseline still carries the three) **self-heals in a single `--apply`**: the new baseline simply omits them. The three OD-engine-regenerated files become seeds. This solves the reported drift uniformly for all three while preserving cold-start for the one file the pipeline reads at runtime.

Why seed and not the spec-144 full exclude: `od-catalog-index.json` is **read at `/product` runtime** (steps 02-prototype + 14-design-system) so it **must exist** for a cold consumer — a plain `COPY_CHECK_EXCLUDE` (which drops it from the walk entirely) would break a fresh consumer. Seed = "copy if absent" keeps cold-start working; "never reconcile" kills the drift. The other two (`ds-index.json` cache, `MANIFEST.json` provenance) are not read at runtime, but folding them into the same one mechanism is simpler than two behaviors and equally correct (shipping a 44 KB seed cache once is harmless; the drift is what mattered).

## Decisions (resolves every spec § Open question)

- **D1 — per-file disposition (OQ1).** All three are **seeds** (ship-once, never-reconcile):
  - `(A) references/od-catalog-index.json` — read at runtime ⇒ MUST ship as a seed (cold-start). Stays git-tracked in Agent0.
  - `(B) vendor/open-design/.cache/ds-index.json` — pure cache, never read by the skill. Seed (harmless one-time ship; drift gone). Stays tracked in Agent0 — **fully untracking the cache is a deliberate non-goal** (the seed mechanism already removes its consumer drift; `git rm --cached` + a source `.gitignore` is a separate cleanliness change with its own orphan-handling, not needed to fix the reported problem).
  - `(C) vendor/open-design/MANIFEST.json` — provenance/pin, not read at runtime; only `history[]` drifts. Seed (ship the pin once; tolerate local history growth).
- **D2 — mechanism (OQ2): one new `COPY_CHECK_SEED` array + `is_seed()` + `process_seed()`.** Reuses the existing `case`-glob matcher shape (`matches_exclude`) and the `process_file` copy-if-absent branch. NOT the spec-144 `COPY_CHECK_EXCLUDE` (that drops a file entirely → would break cold-start for A). The seed pass slots into `walk_copy_check` *before* `record_manifest`, so seeds never enter the manifest/baseline.
- **D3 — baseline reconciliation for already-drifted consumers (OQ3).** Because seeds are never recorded in the manifest, `write_baseline` (which serialises `MANIFEST_TSV`) omits them → a single `--apply` drops the stale baseline entries. `reconcile_deletions` gets an early `is_seed && continue` so a seed with a lingering baseline entry is **not** treated as a deletable/refusable orphan during the one-apply transition. Net: `cognixse`'s next `--apply` stops reporting the three, keeps the consumer's regenerated copies, and writes a clean baseline — no `--force`, no manual step.
- **D4 — MANIFEST history split (OQ4): NO.** Splitting `MANIFEST.json` into a shipped `stable` + consumer-local `history` is over-engineering; seed semantics handle the whole file's drift without touching the OD-engine's format. Recorded as a non-goal.

## Files to touch

**Modify:**
- `.agent0/tools/sync-harness.sh`:
  - Add `COPY_CHECK_SEED=( … 3 relpaths … )` next to `COPY_CHECK_EXCLUDE` (with a comment explaining ship-once-never-reconcile + why not `EXCLUDE`).
  - Add `is_seed()` (mirrors `matches_exclude`).
  - Add `process_seed()` — copy-if-absent (counts `SEEDED`); else `= seed <rel> (consumer-owned, not reconciled)` (counts `SEED_KEPT`); never compare/flag/overwrite. Honors `--check` (absent ⇒ `+ would seed` + DRIFT; present ⇒ no drift) and `--dry-run`. Respects `_skip_tracked_local_only`.
  - In `walk_copy_check`: in the recursive loop (and, defensively, the glob + literal loops), `if is_seed "$relfile"; then process_seed "$relfile"; continue; fi` placed **before** `record_manifest`.
  - In `reconcile_deletions`: `is_seed "$rel" && continue` early in the per-baseline-row loop.
  - Add `SEEDED` / `SEED_KEPT` counters + surface them in the summary line.
- `.agent0/context/rules/harness-sync.md` — document the seed category (a short `## Seed files (ship-once, never-reconcile)` section near § Manifest scope; cross-reference spec 156 + why it differs from `COPY_CHECK_EXCLUDE`).

**Create:**
- `.agent0/tests/harness-sync/NN-seed-*.sh` (glob-discovered by the existing runner) — cover: cold consumer gets the seed (copied when absent); a present+drifted seed is NOT flagged `!! customized` and is left byte-untouched; a seed is not recorded in the new baseline; an already-baselined drifted seed self-heals on `--apply` (no orphan refusal, baseline entry dropped); `--force` does not overwrite a present seed.

**Delete:** none (ds-index untracking is a non-goal — see D1).

## Alternatives considered

### Plain `COPY_CHECK_EXCLUDE` (spec-144 style) for all three

Rejected: `EXCLUDE` drops the file from the walk entirely, so a **cold consumer never receives `od-catalog-index.json`** and `/product` steps 02/14 fail to read the catalogue. Verified read-at-runtime via `templates/pipeline/02-prototype/prompt.md` + `14-design-system/prompt.md`. Exclude is correct only for files never needed cold (the spec-144 `extracted-*` cache); it is wrong for a runtime-read seed.

### Make `sync-open-design.ts` write deterministic (no timestamps/history)

Rejected: changing the OD-engine's output format is a non-goal (spec § Non-goals), fragile (the `generated_at`/`snapshot_date`/`history[]` fields are legitimately informative), and wouldn't fix `MANIFEST.json`'s append-only history. The drift is a *shipped-surface* problem; fix it on the sync side.

### Split `MANIFEST.json` into stable + history files

Rejected (D4): more moving parts, an OD-engine format change, and unnecessary — seed semantics already neutralise the history drift.

## Risks and unknowns

- **R1 — must not regress the 40+ harness-sync tests.** The seed pass is additive (a `continue` branch before the normal path); the three seed paths are specific. Mitigation: run the full `.agent0/tests/harness-sync/` suite; the seed paths don't intersect any existing fixture.
- **R2 — `is_seed` in all three walk loops.** The three files live under `COPY_CHECK_RECURSIVE` (`.claude/skills/`), so only the recursive loop strictly needs the branch; adding it to the glob + literal loops too is defensive (no path there matches, so it's inert) and keeps the three loops symmetric.
- **R3 — seed not recorded ⇒ never in baseline.** Confirmed `write_baseline` serialises only `MANIFEST_TSV`; a seed that is never `record_manifest`'d is absent from the new baseline by construction. The transition is the one place a *stale* baseline entry exists — handled by the `reconcile_deletions` skip (D3).
- **R4 — cold consumer still ships the 44 KB `ds-index` cache as a seed.** Accepted: harmless, and untracking it is a scoped non-goal. Noted in D1.

## Research / citations

- Spec-156 OD-file lifecycle recon (this session): `sync-open-design.ts` writes `MANIFEST_PATH`/`DS_INDEX_PATH`/`CATALOG_INDEX_PATH` (`:32/34/35`), `history.push({event:'apply'…})` at `:656` (apply) vs `:396` (bump), `generateCatalogIndex`/`generateDsIndex` at apply (`:669/670`), `snapshot_date: todayDateStr()` (`:1133`), `generated_at: nowISO()` (`:1036`). Runtime reads of `od-catalog-index.json`: `templates/pipeline/02-prototype/prompt.md`, `14-design-system/prompt.md`. No runtime read of `ds-index.json`/`MANIFEST.json` (provenance only).
- `sync-harness.sh` integration points: `COPY_CHECK_EXCLUDE` + `matches_exclude` (`:235/302`), `is_runtime_cache` (`:315`), `process_file` copy-if-absent branch (`:477`), `walk_copy_check` loops (`:658/669/682`), `reconcile_deletions` (`:717`), `write_baseline` (`:834`, serialises `MANIFEST_TSV`).
- `docs/specs/144-sync-harness-gitignore-aware-walk/` — the exclusion precedent (`extracted-*`) and why seed ≠ exclude here.
