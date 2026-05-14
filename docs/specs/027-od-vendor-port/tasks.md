# 027 — od-vendor-port — tasks

_Generated from `plan.md` on 2026-05-14. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Phase 1 — Vendor skeleton

- [ ] 1. Port `od-vendor-manifest.schema.json` from `~/anthill/.anthill/schemas/` to `packages/mcp-product-pipeline/schemas/`. Verify it parses as valid JSON Schema.
- [ ] 2. Create `packages/mcp-product-pipeline/vendor/open-design/` and copy `LICENSE`, `NOTICE`, `.LICENSE.provenance` verbatim from anthill's vendor tree.
- [ ] 3. Port `MANIFEST.json` from anthill — keep `pinned_sha` `d25a7aaf4219d69b6a3055ddda25fbce0dafd24d`, `history[]`, `license_attribution[]`; rewrite every `vendored_paths[].dst` to be package-relative (`design-systems/` sibling, `vendor/open-design/...` for the rest).
- [ ] 4. Create `packages/mcp-product-pipeline/runtime/od-sync/.gitignore` ignoring `tarball-*.tar.gz` and `extracted-*/`, keeping `*.md`.
- [ ] 5. Add the `files` field to `packages/mcp-product-pipeline/package.json` — include `vendor/`, `design-systems/`, `schemas/`, `src/`; exclude `runtime/`, `tests/`.

### Phase 2 — Sync engine

- [ ] 6. Port `sync-open-design.ts` (~659 LOC) from `~/anthill/scripts/` to `packages/mcp-product-pipeline/scripts/`. Rewrite path constants (`REPO_ROOT`, `MANIFEST_PATH`, `RUNTIME_DIR`) to resolve from the package root via `import.meta.url`. Drop the `#!/usr/bin/env tsx` shebang dependency — invocation is `bun scripts/sync-open-design.ts`.
- [ ] 7. Port `validateManifestShape`, `computeTreeChecksum`, `provenanceHeader`, `REQUIRED_H2_SUBSTRINGS`, `validateDesignMd` verbatim — do NOT re-derive the H2 keyword list (anthill relaxed it to 5 substrings after the narrow set matched 0/72 files).
- [ ] 8. Add a `--verify` subcommand: recompute per-path checksums against `MANIFEST.json`, exit non-zero with a stderr report on any mismatch. This is the function `prepublishOnly` will call.
- [ ] 9. Confirm `--check`'s `gh api` compare path keeps its "list all vendored_paths as potentially changed" fallback for when `gh` is absent; `git ls-remote` HEAD-SHA fetch stays as-is.
- [ ] 10. Add `scripts.sync` (`bun scripts/sync-open-design.ts`) and `scripts.prepublishOnly` (`bun scripts/sync-open-design.ts --verify`) to `package.json`.

### Phase 3 — Content bootstrap (copy from anthill at pinned SHA)

- [ ] 11. Copy `~/anthill/.anthill/design-systems/` (73 `DESIGN.md` trees) to `packages/mcp-product-pipeline/design-systems/`. Preserve anthill's provenance headers (SHA-stable, identical pin).
- [ ] 12. Copy `~/anthill/.anthill/vendor/open-design/{skills,prompts,frames,templates}/` into `packages/mcp-product-pipeline/vendor/open-design/`. Includes all 33 skill bundles + `INDEX.json`, the 3 `prompts/*.ts` + their `.extracted.md` siblings, 3 frames, `deck-framework.html`.
- [ ] 13. Generate `vendor/open-design/.cache/ds-index.json` — `{name, mood, palette_summary}` per DS. Add the generation step to `sync-open-design.ts`'s `--apply` so future bumps regenerate it; run it once now for the bootstrap.
- [ ] 14. Run `bun scripts/sync-open-design.ts --verify` — confirm every copied path's checksum matches the ported `MANIFEST.json`. Fix any path-rewrite or copy mismatch until `--verify` exits 0.

### Phase 4 — Provenance integrity

- [ ] 15. Verify `prepublishOnly` fires `--verify` and blocks publish on drift: hand-edit a vendored file, run `npm publish --dry-run` (or `bun pm` equivalent), confirm non-zero exit; revert the edit.

### Phase 5 — MCP integration

- [ ] 16. Read `src/paths.ts` to confirm its role; create `src/od.ts` with: absolute vendor-path resolution from `import.meta.url` (works in both dev layout and installed `node_modules/` layout), `ds-index.json` loader, and fail-loud detection that returns an actionable error when the vendor tree is missing/partial.
- [ ] 17. Register `product_design_systems_index` in `src/tools.ts` — returns the parsed `ds-index.json` (all 73 systems, one-line each). Does not walk the filesystem per call.
- [ ] 18. Register `product_design_system_path` (DESIGN.md path resolver) in `src/tools.ts` — takes a system name, returns the absolute resolved path for the agent's `Read` tool. Fail-loud on unknown name or missing tree.
- [ ] 19. Wire both tools into `src/server.ts`.

### Phase 6 — Consumer doc & step-2 retrofit

- [ ] 20. Port `od-bridge.md` from `~/anthill/.claude/skills/anthill-prototype/references/` to `packages/mcp-product-pipeline/src/templates/02-prototype/references/`. Rewrite paths to package-relative; replace anthill's symlink-path model with the MCP-tool-returns-absolute-path model.
- [ ] 21. Simplify the OD-pipeline section in `src/templates/02-prototype/references/pipeline.md` to point at `od-bridge.md`; relocate (do NOT delete) the inline 5-school description under a clearly-marked "Manual escape — OD vendor unavailable" heading.
- [ ] 22. Update `src/templates/02-prototype/prompt.md` to direct the agent through the `od-bridge.md` pre-flight read sequence.
- [ ] 23. Update `src/templates/02-prototype/schema.md` to make DS-by-name citation in the REPORT mandatory.
- [ ] 24. Add a one-line pointer to the vendored Apache-2.0 `LICENSE`/`NOTICE` in `packages/mcp-product-pipeline/README.md`.

### Tests

- [ ] 25. Write `tests/sync-open-design.test.ts` — covers `computeTreeChecksum`, `validateManifestShape`, `validateDesignMd` (pass + missing-section cases), `--verify` drift detection.
- [ ] 26. Write `tests/od.test.ts` — vendor-path resolution in dev + simulated-installed layouts, `ds-index.json` load, fail-loud on missing tree.

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria._

- [ ] 27. **Vendor layout** — `MANIFEST.json` schema-validates; `LICENSE`/`NOTICE`/`.LICENSE.provenance` present; `design-systems/` has 73 trees; `vendor/open-design/skills/` has 33 bundles; `prompts/`, `frames/`, `templates/` populated. (spec § Vendor layout)
- [ ] 28. **Sync engine scenarios** — `--check` is read-only and writes a dated report; `--bump` updates manifest only and rejects non-existent SHAs; `--apply` extracts + checksums + validates + appends history; hand-edit is caught by `--verify`. (spec § Sync engine, 4 scenarios)
- [ ] 29. **Distribution** — `npm pack --dry-run` includes `vendor/` + `design-systems/` + `schemas/`, excludes `runtime/`; record the final tarball size in `plan.md`. (spec § Distribution)
- [ ] 30. **MCP integration scenarios** — `product_design_systems_index` returns all 73 without per-call FS walk; the path resolver returns an absolute path the agent can `Read`; step-2 templates require DS citation via the ported `od-bridge.md`. (spec § MCP integration, 3 scenarios)
- [ ] 31. **Provenance integrity** — `prepublishOnly` runs `--verify` and blocks publish on drift; no `postinstall` script was added. (spec § Provenance integrity)
- [ ] 32. **Full suite green** — `bun test` passes (existing 78 + new), `bun tsc --noEmit` clean.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._

- Anthill is archived (2026-05-13) but its filesystem stays readable at `~/anthill/` — the canonical source for every copy/port task above.
- The 6 open questions from `spec.md` are resolved in `plan.md`'s decision table; if any resolution proves wrong mid-implementation, update both `plan.md` and the relevant `spec.md` open question.
- Phase ordering matters: Phase 3 (`--verify` in task 14) depends on Phase 2's script; Phase 5 depends on Phase 3's `ds-index.json`; Phase 6's `od-bridge.md` depends on Phase 5's tools existing to reference.
