# 143 — od-vendor-skills-remap — tasks

_Generated from `plan.md` on 2026-06-02. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. **Baseline snapshot** — record pre-state for the diff: current dst `skills/` bundle list, current `web-prototype/assets/template.html` provenance header (reads `:skills/…` today), and that `--verify` currently fails only on `skills/`.
- [x] 2. **Re-point the manifest** — in `.claude/skills/product/vendor/open-design/MANIFEST.json`, change the skill-bundle vendored-path `"src": "skills/"` → `"src": "design-templates/"`. Leave `dst`/`kind`/`recursive` unchanged.
- [x] 3. **Re-apply** — `bun scripts/sync-open-design.ts --apply` from `.claude/skills/product/`. Confirm it stages `design-templates/` into `vendor/open-design/skills/` (apply report: files added/updated; tarball reused from cache, no re-download).

## Verification

_Acceptance checks tied to `spec.md`._

- [x] V1. **31 bundles resolve (AC2).** Every pipeline-referenced bundle exists at `vendor/open-design/skills/<bundle>/`; spot-check `web-prototype/assets/template.html` and `saas-landing/SKILL.md` exist and their provenance header now reads `open-design@c128ffd5:design-templates/<bundle>/…`.
- [x] V2. **Zero pipeline-template edits (AC3).** `git status` shows no change under `templates/pipeline/**` — the dst-stable mapping kept all `vendor/open-design/skills/<bundle>` references resolving.
- [x] V3. **design-systems/ untouched (risk check).** The same `--apply` re-stages `design-systems/` byte-identically → `git status` shows no diff under `vendor/open-design/design-systems/` (or `design-systems/`).
- [x] V4. **`--verify` red only on skills/, expected (AC5 hand-off).** `--verify` fails on `vendor/open-design/skills/` (the now-orphaned creative set) and passes on all other paths — confirming 143 sourced the bundles correctly and the remaining drift is exactly 142's prune scope. NOT a 143 failure.

## Notes

_Populated during execution → folds into the work report._
