# 142 — od-sync-orphan-prune — tasks

_Generated from `plan.md` on 2026-06-02. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

**Discipline:** pure exported cores (TDD red→green) + thin FS wrappers, same as spec 141. Runner: `bun test scripts/sync-open-design.test.ts` from `.claude/skills/product/`. Predecessor spec 143 is already on `origin/main` (skills/ re-sourced from design-templates/), so the live orphan set is the upstream creative `skills/` bundles.

## Implementation

- [x] 1. **Baseline** — `bun test scripts/sync-open-design.test.ts` green; confirm `--verify` currently red only on `skills/` (the prune target).
- [x] 2. **TDD pure cores (red→green).** Add failing tests then implement 4 exported functions in `sync-open-design.ts`:
  - `computeOrphans(onDiskRel, stagedRel)` → on-disk minus staged (set difference).
  - `topLevelBundles(relPaths)` → unique first path segments.
  - `findReferencedOrphans(orphanBundles, referencedNames: Set)` → intersection.
  - `assertDisjointRoots(recursiveDsts)` → throws when one dst is a path-prefix of another.
- [x] 3. **Wire compute + guards into `cmdApply`** (after the slow-path no-op, before Phase B rename): build per-recursive-vp staged dst-relative sets; `assertDisjointRoots` over recursive dst roots; `computeOrphans` per root; `findReferencedOrphans` against a grep of pipeline templates + `SKILL.md`; **throw before Phase B** if any referenced (no mutation yet).
- [x] 4. **Wire prune execution** (finalization): after Phase B writes staged, move orphans (+ now-empty dirs) to `runtime/od-sync/pruned-<sha>/`; after `writeManifest` + indices + report succeed, `rm -rf` the journal. Add a `## Pruned (N)` section to the apply report + a `console.log` count.
- [x] 5. **Gitignore the journal** — ensure `…/runtime/od-sync/pruned-*/` is ignored (create/append `.claude/skills/product/.gitignore`); confirm exact path.

## Verification

_Acceptance checks tied to `spec.md`._

- [x] V1. **Unit suite green** — `bun test` passes (new pure-core tests + existing). Covers compute/guard/referenced/disjoint logic (Acceptance OQ1-3 + nested-root).
- [x] V2. **Referenced-block (unit)** — a synthetic orphan whose bundle name is in `referencedNames` makes `findReferencedOrphans` return it (→ the wrapper would throw). Proves the block path without needing a real referenced orphan.
- [x] V3. **Live regression (the headline):** run `bun scripts/sync-open-design.ts --apply` → the orphaned creative `skills/` bundles are pruned, **`--verify` exits 0 across all 7 paths**, and `web-prototype`/`saas-landing`/the 31 pipeline bundles **survive** (sourced from `design-templates/` by 143). Apply report shows a non-empty `## Pruned`.
- [x] V4. **No collateral** — `git status` shows the prune deleted only `vendor/open-design/skills/` orphans; `design-systems/`, `frames/`, prompts untouched; the trash journal absent (rm'd on success) and gitignored.

## Notes

_Populated during execution → folds into the work report._
