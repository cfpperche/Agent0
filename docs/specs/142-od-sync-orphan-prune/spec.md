# 142 — od-sync-orphan-prune

_Created 2026-06-02._

**Status:** draft

## Intent

`sync-open-design.ts --apply` writes upstream content over the vendored dst via `rename`, but **never deletes dst files that upstream removed**. In a recursive vendored tree (`skills/`, `design-systems/`, `frames/`) every file removed upstream becomes a permanent orphan. Concretely (measured 2026-06-02 at pin `c128ffd5`): `vendor/open-design/skills/` carries **375** files vs the tarball's **284** — **91 orphan skill bundles** (`blog-post/`, `critique/`, `dashboard/`, `email-marketing/`, … + a stale `INDEX.json`) that upstream deleted but `--apply` left behind. Because `verifyManifest` walks the on-disk dst, those orphans poison the tree checksum and make `--verify` **fail permanently** — on Agent0 AND on the 3 consumers just re-synced from it (they inherited the same orphans). This also defeats spec 141's idempotence fast-path, which is gated on `--verify` passing: on any repo with an upstream removal the fast-path can never engage. This spec makes `--apply` prune orphans inside recursive vendored trees, **safely** (two-phase, scoped, with a guard against silently deleting a bundle the pipeline still references). It is the completion of the engine-correctness work 141 began; it does NOT touch idempotence/regen/counts (141 owns those) or restructure the vendor (the founder-gated OD-extraction, `r-2026-06-01`).

**Premise correction (debate.md, 2026-06-02 — Claude Code ↔ Codex CLI).** The cross-model debate established orphan-prune is correct ONLY after the vendor mapping is fixed. The c128ffd5 advance reorganized upstream: `skills/` is now a 154-bundle creative set, and the pipeline's bundles (`web-prototype`, `saas-landing`, +29 others — 31/31, identical structure) moved to `design-templates/`. The 91-file / 31-bundle "orphan" set is the pipeline's LIVE set, surviving only via this no-prune bug; pruning it before re-mapping would break the pipeline. Therefore **spec 143 `od-vendor-skills-remap` (re-point the `skills/` vendored-path src → `design-templates/`, dst unchanged) is a HARD PREDECESSOR** — 142 must not run until 143 lands, after which the now-stale upstream `skills/` creative set becomes the orphan set 142 safely prunes.

## Acceptance criteria

- [ ] **Scenario: `--apply` prunes dst files upstream removed within a recursive tree**
  - **Given** a recursive vendored path whose dst contains files absent from the tarball at `pinned_sha` (e.g. the 91 orphan skill bundles)
  - **When** `--apply` completes a real reconcile
  - **Then** the dst tree contains exactly the tarball's file set for that path (orphans deleted), and a subsequent `--verify` exits 0 for that path

- [ ] **Scenario: pruning is scoped — only recursive-vp dst roots, never beyond**
  - **Given** an `--apply` run
  - **When** orphan pruning executes
  - **Then** it deletes only files under a recursive `vendored_paths[].dst` root that are absent from that path's staged set; non-recursive entries, `.gitkeep` sentinels, and anything outside the vendored dst roots are never touched

- [ ] **Scenario: prune respects the two-phase safety invariant**
  - **Given** a `--apply` where Phase A validation fails (a DESIGN.md schema failure)
  - **When** the apply aborts
  - **Then** no orphan is deleted — pruning happens only after Phase A passes and as part of (or after) the Phase B commit, so a failed apply leaves the live vendor fully intact

- [ ] **Scenario: a pipeline-referenced orphan hard-blocks the apply (resolved — block, not report)**
  - **Given** an orphan path that a live non-vendor file (a pipeline template) still references
  - **When** pruning runs
  - **Then** `--apply` hard-fails naming the referenced path (does NOT delete it), so the repo is never left referencing a deleted bundle; unreferenced orphans prune normally. _(per debate.md OQ2: block-when-referenced + auto-prune-when-unreferenced; delete-and-report rejected as too weak for paths product templates read)_

- [ ] **Scenario: prune is atomic / recoverable (resolved per debate.md)**
  - **Given** a prune that fails partway (an `rm`, manifest, or report error after some orphans are gone)
  - **When** the failure occurs
  - **Then** recovery is a local restore, not a re-download: deletion moves orphans to a `runtime/od-sync/` trash journal (OUTSIDE the vendored root — a quarantine inside the root would itself be hashed by `verifyManifest`/`walkFiles`) and only finalizes after the manifest + report write succeed

- [ ] **Scenario: nested recursive roots don't cross-prune (resolved per debate.md)**
  - **Given** the manifest's recursive vendored roots (today `design-systems/`, `vendor/open-design/skills/`, `frames/` are disjoint)
  - **When** the prune set is computed for a root
  - **Then** a parent root never treats a child root's files as orphans — either overlapping recursive dst prefixes are rejected, or child roots are excluded from a parent's prune walk

- [ ] **Scenario (regression): `--verify` goes green after 143 + 142**
  - **Given** spec 143 has re-pointed `skills/` src → `design-templates/` and `--apply` ran
  - **When** 142's prune runs (the now-stale upstream `skills/` creative bundles are the orphan set)
  - **Then** those genuinely-removed files are pruned and `--verify` exits 0 across all 7 vendored paths — WITHOUT deleting the pipeline's `web-prototype`/`saas-landing`/etc. (now sourced from `design-templates/`)

- [ ] **Prune set source (resolved per debate.md OQ3):** the prune set is built from the Phase-A staged final dst-relative paths, captured as `dstRoot → Set<relpath>` during staging (not via mutable `VendoredPath` object identity, not a second tarball walk), compared against `walkFiles(dstFull)` preserving the `.gitkeep` exclusion.

- [ ] After 143 + 142 land and Agent0's `--verify` is green, re-running `sync-harness.sh --apply` to the 3 consumers (mei-saas/cognixse/tese) clears their inherited drift too. _(propagation follow-up, not engine scope)_

## Non-goals

- Changing the idempotence fast/slow-path, catalogue regen, or stale-count advisory — spec 141 owns those and they are correct.
- Restructuring or extracting the OD vendor out of `/product` — the founder-gated `r-2026-06-01` OD-vendor-extraction.
- Pruning anything outside the recursive `vendored_paths[].dst` roots, or deleting files for non-recursive vendored entries (a non-recursive entry that disappears upstream is already handled by `report.removed`).
- Re-curating or auditing the surviving skill bundles for quality — prune is set-membership only.
- **Fixing the vendor mapping itself — that is spec 143 `od-vendor-skills-remap`, the HARD PREDECESSOR.** 142 is the engine's prune capability; 143 corrects which upstream tree `skills/` vendors. 142 must not run until 143 has landed (else it deletes the pipeline's live bundles).

## Open questions

_All 4 resolved by the cross-model debate — see `debate.md` § Synthesis (2026-06-02, Claude Code ↔ Codex CLI). Resolutions folded into § Intent and § Acceptance above:_

- [x] **OQ1 auto vs `--prune` flag** → automatic, no flag, + guard-failure path (Acceptance).
- [x] **OQ2 block vs report** → block-when-referenced + auto-prune-unreferenced (Acceptance).
- [x] **OQ3 prune set source** → reuse Phase-A staged set as `dstRoot → Set<relpath>` (Acceptance).
- [x] **OQ4 is pruning correct** → only after the spec-143 remap; the 31 "orphans" are the pipeline's live set (moved to `design-templates/` upstream), not deletable junk (Intent § Premise correction).

## Context / references

- `docs/specs/141-od-sync-apply-completeness/` — parent engine spec; its `notes.md` § Open questions filed this as the discovered 3rd gap, and its fast-path is the coupled victim of the orphan bug.
- `.claude/skills/product/scripts/sync-open-design.ts` §§ `cmdApply` Phase B (the `rename` loop that never deletes), `verifyManifest` (walks dst → sees orphans), `walkFiles` (the dst walk, already `.gitkeep`-aware — reuse for the prune set).
- Evidence (2026-06-02): dst `skills/` 375 files vs tarball 284 → 91 orphans (whole bundles + `INDEX.json`); only `skills/` fails `--verify` (the 73→150 `design-systems/` advance was purely additive, no orphans).
- `r-2026-06-01` — OD-vendor-extraction (distinct, founder-gated).
- Affected repos right now: Agent0 + the 3 consumers (mei-saas/cognixse/tese) all fail `vendor/open-design/skills/` `--verify` until this lands + re-sync.
