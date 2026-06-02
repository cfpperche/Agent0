# 141 — od-sync-apply-completeness — tasks

_Generated from `plan.md` on 2026-06-02. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

**Design discipline (from the existing test file):** the engine's philosophy is *pure exported cores + thin FS/network wrappers*. `computeTreeChecksum` / `validateDesignMd` / `resolveChangedVendoredScope` / `verifyManifest` are all pure + unit-tested; the network-bound `--apply`/`--check` are not. Every fix below extracts a **pure, exported** decision/transform function (unit-tested TDD red→green) and keeps the FS/network in the command wrapper. Runner: `bun test scripts/sync-open-design.test.ts` from `.claude/skills/product/`.

## Implementation

- [x] 1. **Baseline** — run `bun test scripts/sync-open-design.test.ts`; confirm the current suite is green before any edit (regression anchor).
- [x] 2. **Fix 2 — catalogue regen (acceptance 4).** Extract pure exported `buildCatalogVendors(dsSystems, existingByName, categoryOf)` → sorted `vendors[]`. TDD: write failing tests — (a) a curated entry is preserved verbatim (category/mood/palette_primary unchanged, `vendor_path` refreshed); (b) a new system is added mechanically (`category` from `categoryOf`, `mood` + first `palette_summary` hex from the ds entry); (c) missing category → `"Uncategorized"`; (d) output sorted by `name`. Implement until green.
- [x] 3. **Fix 2 wiring.** Add `generateCatalogIndex(pinnedSha)` (FS wrapper: read `.cache/ds-index.json` + existing `od-catalog-index.json`, call `buildCatalogVendors`, write `{version, snapshot_date, source, vendors}` with trailing newline). Call it in `cmdApply` immediately after `generateDsIndex(sha)`. Add the `--gen-catalog` CLI branch in `main` (mirrors `--gen-ds-index`).
- [x] 4. **Fix 1 — content-true idempotence (acceptance 1/2/3).** Extract pure exported `pinnedContentAlreadyApplied(verifyResults, history, pinnedSha)` → boolean (fast-path: all verify ok AND latest `apply` history sha === pinnedSha). TDD failing tests: passes only when both hold; false when pinned_sha moved past last apply (the `--bump` case); false on any verify drift. Implement until green.
- [x] 5. **Fix 1 wiring.** Rewrite the `cmdApply` idempotence gate: (a) delete `if (vp.recursive) continue` + the manifest-checksum compare loop; (b) early fast-path — if `pinnedContentAlreadyApplied(verifyManifest(...), history, pinned_sha)` → `no-op (already in sync)`, return (no download); (c) slow-path — after Phase A staging, derive `alreadyInSync` by comparing each staged checksum (tree-aware) against the on-disk checksum; if all match → no-op, tear down staging, skip Phase B; else proceed to Phase B as today.
- [x] 6. **Fix 3 — stale-count advisory (acceptance 5).** Extract pure exported `scanStaleCounts(files, currentCount)` (files = `{path, text}[]`) → `{path, line, text}[]` for lines matching `\b(\d+)\s+(?:design\s+)?systems?\b` / `(\d+)\s+DESIGN\.md` whose number ≠ currentCount. TDD failing tests: flags a stale "73 systems" line, ignores a matching "150 systems" line, ignores non-count noise. Implement until green.
- [x] 7. **Fix 3 wiring.** In `cmdApply`, read the fixed allowlist of OD docs (`SKILL.md`, `02-prototype/{prompt.md,references/od-bridge.md}`, `14-design-system/prompt.md`), run `scanStaleCounts` against the current catalogue count, append a `## Stale count advisory` section to the apply report (non-blocking; empty section omitted or "none").
- [x] 8. **Doc cleanup.** De-hardcode the live stale string `02-prototype/prompt.md:104` ("73 `DESIGN.md` directories" → count-free phrasing) and any other line the advisory flags where phrasing allows.
- [x] 9. **Remove scratch** — delete `/tmp/gen-catalog.py` (logic now lives in `buildCatalogVendors`).

## Verification

_Acceptance checks tied to `spec.md`._

- [x] V1. `bun test scripts/sync-open-design.test.ts` — full suite green (new + existing). Covers acceptance 2/3 (idempotence content-compare incl. recursive trees via `pinnedContentAlreadyApplied` tests), acceptance 4 (`buildCatalogVendors` tests), acceptance 5 (`scanStaleCounts` tests).
- [x] V2. **Dogfood regen (acceptance 4):** run `bun scripts/sync-open-design.ts --gen-catalog`; `git diff` on `references/od-catalog-index.json` shows no semantic change at the current pin (regen reproduces the committed curated state) — proves preserve-curated correctness.
- [~] V3. **Dogfood idempotence fast-path (acceptance 1/2):** PARTIAL. The live fast-path no-op could NOT be observed on this repo — a pre-existing `vendor/open-design/skills/` tree drift (orphan files; see notes.md § Tradeoffs/Open questions) makes `--verify` fail, which correctly disqualifies the fast-path. Instead `--apply` fell to the slow-path full reconcile and produced **byte-identical** vendored content (zero git diff on `design-systems/`/`skills/`) — proving AC1 (reconcile without a workaround). The no-op fast-path itself is validated by the `pinnedContentAlreadyApplied` unit tests; it will engage on any repo with clean verify.
- [x] V4. **Stale-count advisory (acceptance 5):** confirm the advisory flags `02-prototype/prompt.md:104` BEFORE task 8's doc fix, and is clean AFTER.

## Notes

_Populated during execution → folds into the work report at the end._
