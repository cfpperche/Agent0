# 142 — od-sync-orphan-prune — plan

_Drafted from `spec.md` on 2026-06-02. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Extend `cmdApply` to prune orphan files inside recursive vendored trees, reusing the engine's "pure exported core + thin FS wrapper" shape (same as spec 141). The OQs are pre-resolved by `debate.md` § Synthesis; this plan turns them into placement + functions.

**Placement in `cmdApply` (post-141 line numbers):** after Phase A staging + the schema-failure check + the slow-path no-op short-circuit (~line 575), and BEFORE Phase B's rename loop (577):
1. **Compute orphans** per recursive vp: `walkFiles(dstFull)` dst-relative paths (already `.gitkeep`-aware) minus that vp's staged dst-relative set → `computeOrphans()`.
2. **Nested-root guard** (`assertDisjointRoots`) over the recursive vp dst roots — throw if any root is a path-prefix of another (so a parent never prunes a child root's files). Today they're disjoint (`design-systems/`, `vendor/open-design/skills/`, `vendor/open-design/frames/`); the guard makes that an invariant, not an assumption.
3. **Referenced-bundle guard** — scan tracked non-vendor files (the pipeline templates + SKILL.md) for references to any orphan's top-level bundle dir; `findReferencedOrphans()` returns the intersection. If non-empty → **throw before Phase B** (no mutation yet → live vendor fully intact), naming the referenced path(s). After 143's remap the orphan set is the upstream creative `skills/` bundles, none referenced → guard passes; the guard is the safety net for the general case.

Then Phase B writes staged as today; the prune executes as part of finalization:
4. **Prune with a rollback journal:** move each orphan (and emptied dirs) to `runtime/od-sync/pruned-<sha>/<relpath>` (OUTSIDE the vendored root — a quarantine inside it would be re-hashed by `verifyManifest`/`walkFiles`). The existing tree-checksum computation (Phase B, ~598) is already staged-only, so the manifest tree digest matches the post-prune dst.
5. **Finalize:** after `writeManifest` + indices + report all succeed, `rm -rf` the trash journal. A mid-prune/mid-write crash leaves the journal for a local restore (the failure mode Codex named: avoid "re-download + re-apply" recovery).
6. **Report:** add a `## Pruned (N)` section to the apply report listing removed paths; `console.log` the count.

**Pure exported cores (TDD red→green, unit-tested like 141's):**
- `computeOrphans(onDiskRel: string[], stagedRel: string[]): string[]` — set difference (on-disk minus staged).
- `topLevelBundles(relPaths: string[]): string[]` — unique first path segments (bundle dir names) for the guard.
- `findReferencedOrphans(orphanBundles: string[], referencedNames: Set<string>): string[]` — intersection; the FS grep produces `referencedNames`.
- `assertDisjointRoots(recursiveDsts: string[]): void` — throw on overlapping dst prefixes.

The FS wrappers (`walkFiles` reuse, the template grep, the move-to-trash, the rm-on-success) stay untested glue, validated by the real `--apply` regression.

## Files to touch

**Modify:**
- `.claude/skills/product/scripts/sync-open-design.ts` — add the 4 pure functions; wire compute-orphans + the two guards (pre-Phase-B) + the move-to-trash prune + rm-on-success + the `## Pruned` report section into `cmdApply`.
- `.claude/skills/product/scripts/sync-open-design.test.ts` — unit tests for the 4 pure functions (red→green).
- `.claude/skills/product/.gitignore` (create or append) — ignore `vendor/open-design/runtime/od-sync/pruned-*/` (belt-and-suspenders: the journal is rm'd on success, but a crashed run shouldn't leave committable artifacts). _Confirm the exact runtime path at impl time._

**No deletes by hand** — the engine prunes the orphaned creative `skills/` bundles at `--apply` time (that IS the deliverable's effect); the deletion lands as part of running the validated apply.

## Alternatives considered

### Prune = `rm` directly (no trash journal)
Rejected per debate — `--apply` deletion has no rollback; a mid-prune failure would force "re-download + re-apply" recovery. Move-to-trash-then-rm-on-success makes a crash a local restore, for a few lines more.

### Referenced-guard = delete-and-report (not block)
Rejected per debate — delete-and-report assumes someone reads the report; for paths a live template reads, silently deleting then reporting leaves a broken repo. Block-when-referenced fails loud before mutation.

### Quarantine orphans inside the vendored root (`skills/.removed/`)
Rejected per debate — `verifyManifest`/`walkFiles` walk the live dst and would hash the quarantine, re-introducing drift. The journal must live outside the vendored root.

### Opt-in `--prune` flag
Rejected per debate (OQ1) — a flag recreates the "forgot the second command" failure that is the whole bug. Automatic, with the referenced-guard as the only hard-fail.

## Risks and unknowns

- **Referenced-detection precision.** The grep must catch real references (`skills/<bundle>`, `<bundle>/`) without false-positives that wrongly block a legit prune. Scope the scan to pipeline templates + SKILL.md; the pure intersection is exact. After 143 the creative orphans aren't referenced, so the live run exercises the pass path; add a unit test for the block path with a synthetic referenced orphan.
- **Empty-dir cleanup.** Moving orphan files leaves empty bundle dirs; the prune must remove now-empty dirs too (or the dst tree keeps empty shells). Handle in the move step.
- **Trash path under a tracked dir.** `runtime/od-sync/` is git-tracked (apply reports live there). The journal subdir must be gitignored; confirm the gitignore lands and the rm-on-success keeps it absent in the happy path.
- **Regression scope.** The live validating `--apply` will actually delete ~150 creative `skills/` bundles (the post-143 orphans) — a large deletion in the commit. Expected: that is exactly what makes `--verify` green; `web-prototype` et al. survive (sourced from `design-templates/` by 143, hence staged, hence not orphans).

## Research / citations

- `docs/specs/142-od-sync-orphan-prune/debate.md` § Synthesis — the 4 OQ resolutions this plan implements.
- `sync-open-design.ts` — `cmdApply` Phase A/B (489-657), the staged-only tree-checksum (595-599), `walkFiles` (`.gitkeep`-aware, ~271), `verifyManifest` (recursive walk), the 141 pure-core pattern (`pinnedContentAlreadyApplied`/`scanStaleCounts`).
- Engine test file — `bun:test`, pure-function + fixture-tree style (mirror for the 4 new cores).
- Spec 143 (`origin/main`) — the predecessor that re-sourced the pipeline bundles to `design-templates/`, making the creative `skills/` set the now-prunable orphan set.
