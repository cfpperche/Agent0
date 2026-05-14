# 027 — od-vendor-port — tasks

_Generated from `plan.md` on 2026-05-14. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Phase 1 — Vendor skeleton

- [x] 1. Port `od-vendor-manifest.schema.json` from `~/anthill/.anthill/schemas/` to `packages/mcp-product-pipeline/schemas/`. Verify it parses as valid JSON Schema.
- [x] 2. Create `packages/mcp-product-pipeline/vendor/open-design/` and copy `LICENSE`, `NOTICE`, `.LICENSE.provenance` verbatim from anthill's vendor tree.
- [x] 3. Port `MANIFEST.json` from anthill — keep `pinned_sha` `d25a7aaf4219d69b6a3055ddda25fbce0dafd24d`, `history[]`, `license_attribution[]`; rewrite every `vendored_paths[].dst` to be package-relative (`design-systems/` sibling, `vendor/open-design/...` for the rest).
- [x] 4. Create `packages/mcp-product-pipeline/runtime/od-sync/.gitignore` ignoring `tarball-*.tar.gz` and `extracted-*/`, keeping `*.md`.
- [x] 5. Add the `files` field to `packages/mcp-product-pipeline/package.json` — include `vendor/`, `design-systems/`, `schemas/`, `src/`; exclude `runtime/`, `tests/`.

### Phase 2 — Sync engine

- [x] 6. Port `sync-open-design.ts` (~659 LOC) from `~/anthill/scripts/` to `packages/mcp-product-pipeline/scripts/`. Rewrite path constants (`REPO_ROOT`→`PKG_ROOT`, `MANIFEST_PATH`, `RUNTIME_DIR`) to resolve from the package root via `import.meta.url`. Drop the `#!/usr/bin/env tsx` shebang dependency — invocation is `bun scripts/sync-open-design.ts`.
- [x] 7. Port `validateManifestShape`, `computeTreeChecksum`, `provenanceHeader`, `REQUIRED_H2_SUBSTRINGS`, `validateDesignMd` verbatim — do NOT re-derive the H2 keyword list (anthill relaxed it to 5 substrings after the narrow set matched 0/72 files).
- [x] 8. Add a `--verify` subcommand: recompute per-path checksums against `MANIFEST.json`, exit non-zero with a stderr report on any mismatch. This is the function `prepublishOnly` will call. Pure `verifyManifest()` exported for tests.
- [x] 9. Confirm `--check`'s `gh api` compare path keeps its "list all vendored_paths as potentially changed" fallback for when `gh` is absent; `git ls-remote` HEAD-SHA fetch stays as-is.
- [x] 10. Add `scripts.sync` (`bun scripts/sync-open-design.ts`) and `scripts.prepublishOnly` (`bun scripts/sync-open-design.ts --verify`) to `package.json`.

### Phase 3 — Content bootstrap (copy from anthill at pinned SHA)

- [x] 11. Copy `~/anthill/.anthill/design-systems/` (72 DS dirs + `README.md` = 73 files) to `packages/mcp-product-pipeline/design-systems/`. Preserved anthill's `454e8373` provenance headers verbatim.
- [x] 12. Copy `~/anthill/.anthill/vendor/open-design/{skills,prompts,frames,templates}/` into `packages/mcp-product-pipeline/vendor/open-design/`. 31 skill bundles (NOT 33 — anthill reality) + `INDEX.json`, the 3 `prompts/*.ts` + their `.extracted.md` siblings, 5 frames, `deck-framework.html`. Scaffold `.gitkeep` markers stripped (never in upstream tarball / manifest checksum tree).
- [x] 13. Generate `vendor/open-design/.cache/ds-index.json` — `{name, mood, palette_summary}` per DS (72 systems). Generation wired into `--apply`; runnable standalone via `--gen-ds-index` (used for this bootstrap).
- [x] 14. Run `bun scripts/sync-open-design.ts --verify` — `OD vendor verify OK — 7 path(s)`. **Deviation:** the 3 recursive-tree checksums in anthill's MANIFEST were stale (anthill's own on-disk content did not match its own MANIFEST — confirmed `bef62379…` on disk vs `e7142584…` in manifest). Recomputed the 3 tree checksums from the actually-vendored content; single-file checksums were correct and kept verbatim. See plan.md § Risks.

### Phase 4 — Provenance integrity

- [x] 15. Verified `prepublishOnly` fires `--verify` and blocks on drift: hand-edited `skills/dashboard/SKILL.md`, `bun run prepublishOnly` exited 1 with a drift report; reverted → exit 0. (`npm publish --dry-run` not used — package is `private: true`; the direct `bun run prepublishOnly` invocation tests the identical gate.)

### Phase 5 — MCP integration

- [x] 16. Read `src/paths.ts` (canonical path module; `packageRoot()` = `resolve(srcDir, "..")`, layout-agnostic). Created `src/od.ts` — `odPaths(pkgRoot?)` resolves all vendor subtree paths, `loadDsIndex` (cached), `designSystemPath` (kebab-case validated, traversal-safe), `assertVendorPresent` throws `VendorMissingError` (fail-loud), `vendorAnchors` exposes the 5 agent-readable roots.
- [x] 17. Registered `product_design_systems_index` in `src/tools.ts` — returns the parsed `ds-index.json` (72 systems) + `vendor_paths` absolute roots. Reads the generated index file; no per-call FS walk (cached in `od.ts`).
- [x] 18. Registered `product_design_system_path` in `src/tools.ts` — name → absolute `DESIGN.md` path. Fail-loud (`unknown-design-system` / `od-vendor-missing`).
- [x] 19. Wired via `registerAllTools` (the single registration entry `src/server.ts` invokes); server.ts docstring updated to the 10-tool surface.

### Phase 6 — Consumer doc & step-2 retrofit

- [x] 20. Ported `od-bridge.md` to `src/templates/02-prototype/references/od-bridge.md`. Rewrote anthill's `.anthill/vendor/...` symlink-path model to the MCP-tool model (`product_design_systems_index` returns `vendor_paths`; `product_design_system_path` resolves DESIGN.md).
- [x] 21. Rewrote `references/pipeline.md` — intro points at `od-bridge.md` as the grounded path; the inline 5-school table + "Picking 3 distinct directions" relocated verbatim under a "## Manual escape — OD vendor unavailable" heading; the stale "When the OD vendor lands" section removed.
- [x] 22. Updated `prompt.md` § 3 with the OD pre-flight read sequence (read od-bridge.md → `product_design_systems_index` → `product_design_system_path` → Read DESIGN.md); § 4 seeds from the vendored template; the stale "not yet ported" closing paragraph rewritten.
- [x] 23. Updated `schema.md` — added `design-systems/` to the REPORT.md Layer 1 `contains` floor (machine-enforced citation-path proxy); "Design Systems Consulted" + "Citations" guidance now require the vendored `DESIGN.md` path, with a documented manual-escape comment form.
- [x] 24. Added the vendored Apache-2.0 `LICENSE`/`NOTICE`/`MANIFEST.json` pointer to `README.md` § License.

### Tests

- [x] 25. Wrote `tests/sync-open-design.test.ts` — `computeTreeChecksum` (order-independence, drift sensitivity), `validateManifestShape` (pass + missing-field), `validateDesignMd` (pass + missing-section + body-only), `verifyManifest` drift detection (single-file edit, recursive-tree edit, missing-on-disk). 14 tests.
- [x] 26. Wrote `tests/od.test.ts` — `odPaths` resolution (dev vs simulated-installed), `vendorAnchors`, `assertVendorPresent` fail-loud (empty + partial tree), `loadDsIndex` (fixture + real 72-system index), `designSystemPath` (known, unknown, traversal-reject, missing-tree). 12 tests.

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria._

- [x] 27. **Vendor layout** — `MANIFEST.json` has all 8 required fields + `validateManifestShape` passes on every `readManifest`; `LICENSE`/`NOTICE`/`.LICENSE.provenance` present; `design-systems/` has **72** DS trees (spec said 73 — anthill reality is 72 dirs + `README.md` = 73 files); `vendor/open-design/skills/` has **31** bundles + `INDEX.json` (spec said 33 — anthill reality is 31); `prompts/` (6 files), `frames/` (6), `templates/` (1) populated. (spec § Vendor layout)
- [x] 28. **Sync engine scenarios** — `--verify` drift detection covered by `verifyManifest` unit tests (single-file + tree + missing). `--check`/`--bump`/`--apply` are ported verbatim from anthill's proven 659-LOC impl (network/git-bound maintainer ops): `--check` keeps the `git ls-remote` HEAD fetch + `gh api compare` with the "list all vendored_paths" fallback; `--bump` validates the 40-hex SHA shape + `shaExistsUpstream`; `--apply` is the two-phase staged atomic apply + `generateDsIndex`. (spec § Sync engine)
- [x] 29. **Distribution** — `npm pack --dry-run`: includes `vendor/` + `design-systems/` + `schemas/`, excludes `runtime/` + `tests/`. Tarball **769 KB**, unpacked **2.49 MB**, 231 files — recorded in `plan.md` § Risks. (spec § Distribution)
- [x] 30. **MCP integration scenarios** — `product_design_systems_index` returns the 72-system index (no per-call FS walk — `od.ts` caches; smoke-tested + unit-tested); `product_design_system_path` returns an absolute `DESIGN.md` path (`/…/design-systems/linear-app/DESIGN.md`); step-2 `prompt.md`/`schema.md`/`pipeline.md` route through `od-bridge.md` and enforce DS-path citation. (spec § MCP integration)
- [x] 31. **Provenance integrity** — `prepublishOnly` = `bun scripts/sync-open-design.ts --verify`, blocks publish on drift (task 15); no `postinstall` script added (confirmed). (spec § Provenance integrity)
- [x] 32. **Full suite green** — `bun test` → 104 pass / 0 fail (existing 78 + new 26); `bun tsc --noEmit` exits 0.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._

- Anthill is archived (2026-05-13) but its filesystem stays readable at `~/anthill/` — the canonical source for every copy/port task above.
- The 6 open questions from `spec.md` are resolved in `plan.md`'s decision table; if any resolution proves wrong mid-implementation, update both `plan.md` and the relevant `spec.md` open question.
- Phase ordering matters: Phase 3 (`--verify` in task 14) depends on Phase 2's script; Phase 5 depends on Phase 3's `ds-index.json`; Phase 6's `od-bridge.md` depends on Phase 5's tools existing to reference.

### Deviations from spec/plan discovered during implementation

- **Counts: 72 design systems / 31 skill bundles** (spec.md said 73 / 33). anthill's actual tree is 72 DS dirs (+ `README.md` = 73 files) and 31 skill bundles (+ `INDEX.json`). We mirrored anthill exactly; the spec numbers were an estimate. Not a functional issue — `MANIFEST.json` takes the trees as recursive wholes.
- **MANIFEST tree-checksums recomputed** (task 14). anthill's `MANIFEST.json` recorded recursive-tree checksums that did not match anthill's own on-disk content (anthill-side stale checksums). Keeping them verbatim would make `--verify`/`prepublishOnly` fail permanently. Recomputed the 3 recursive-tree checksums from the actually-vendored content; single-file checksums were correct and kept verbatim. Documented in `plan.md` § Risks.
- **Provenance headers reference `454e8373…`, not the manifest `pinned_sha` `d25a7aaf…`** — anthill bumped the pin but never re-applied. Content vendored is the `454e8373` snapshot; `pinned_sha` kept as `d25a7aaf…` per task 3. A future `--apply` reconciles. Documented in `plan.md` § Risks.
- **`--gen-ds-index` subcommand added** beyond the plan's 3 subcommands — needed to run `generateDsIndex` standalone for the Phase-3 bootstrap (the plan only specified wiring it into `--apply`). Harmless addition; `--apply` calls `generateDsIndex` too.
- **`product_design_systems_index` also returns `vendor_paths`** (absolute roots for skills/prompts/frames/templates/design-systems) — needed so `od-bridge.md` can teach the agent to reach SKILL.md/template.html/etc. without a path-resolver tool per subtree. Additive to the spec's `{name, mood, palette_summary}` index shape.
- **Task 19 "wire into server.ts":** the existing codebase registers all tools via `registerAllTools` in `tools.ts` (which `server.ts` already invokes) — no separate server.ts registration path exists. Followed the existing pattern; server.ts docstring updated to the 10-tool surface.

## Phase 7 — `PRODUCT_PIPELINE_OD` on/off toggle (follow-up, 2026-05-14)

Added after the step-2 OD dogfood (see `plan.md` § Follow-up). All done in one diff.

- [x] 33. `src/od.ts` — add `odDisabled()` (reads `PRODUCT_PIPELINE_OD`, off-values `off`/`0`/`false`/`no`/`disabled`) + `OdDisabledError extends VendorMissingError` (code `od-disabled`, `override readonly code`); gate `assertVendorPresent` to throw `OdDisabledError` first. Widened `VendorMissingError.code` to `string` so the subclass can override.
- [x] 34. `src/tools.ts` — no logic change needed (the `instanceof VendorMissingError` catch already covers the subclass); updated both OD tool descriptions to name `od-disabled`.
- [x] 35. Templates — one-line edits to `prompt.md`, `references/od-bridge.md`, `references/pipeline.md`, `schema.md` so the "Manual escape" trigger covers `od-disabled` alongside `od-vendor-missing`.
- [x] 36. Docs — `.mcp.json.example` product-pipeline block gains a commented `env` example; `README.md` § Activation gains a "Toggling Open Design grounding" subsection.
- [x] 37. `tests/od.test.ts` — `describe("PRODUCT_PIPELINE_OD toggle")`: `odDisabled()` value table, `assertVendorPresent`/`loadDsIndex`/`designSystemPath` all throw `OdDisabledError` when off (even with a complete tree), subclass+code assertions, unset = on. 5 tests; env var saved/restored per test. Full suite 109 pass, `bun tsc --noEmit` clean.
