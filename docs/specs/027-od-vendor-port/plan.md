# 027 — od-vendor-port — plan

_Drafted from `spec.md` on 2026-05-14. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Port anthill's commit-pinned-tarball vendor architecture into `packages/mcp-product-pipeline/`, adapted on three axes: (1) everything lives inside the package — no Agent0 `.claude/` surface; (2) distribution is the npm tarball, not anthill's symlink injection; (3) the protection layer is a `prepublishOnly` checksum verifier, not a CC hook. The architecture itself (MANIFEST.json + LICENSE/NOTICE provenance + `sync-open-design.ts` with `--check`/`--bump`/`--apply`) is mirrored faithfully — anthill's ADR already litigated submodule vs fork vs daemon-fetch, and we adopt its conclusion rather than re-deciding.

Build order is six phases, each independently verifiable. **Phase 1** scaffolds the vendor skeleton (schema, manifest, license files, dir structure, `package.json` `files` field). **Phase 2** ports the sync engine. **Phase 3** populates content — and here the plan makes a deliberate bootstrap choice: rather than re-run `--apply` from upstream (network dependency, non-deterministic against a moving upstream), we **copy anthill's already-extracted vendor tree** at its pinned SHA `d25a7aaf…`, then run `--verify` to confirm checksums match. The result is byte-identical to what anthill benchmarked on 2026-04-30; the sync script's `--apply` exists for *future* bumps, not the initial port. **Phase 4** wires `prepublishOnly`. **Phase 5** adds the two MCP tools (DS index + DESIGN.md path resolver) returning absolute resolved paths. **Phase 6** ports `od-bridge.md` into the step-2 templates and simplifies `pipeline.md` while retaining the inline 5-school content as a documented manual escape (per open question 6).

### Open questions — resolutions baked into this plan

| # | Question | Resolution |
|---|----------|------------|
| 1 | `design-systems/` placement | **Sibling** of `vendor/` — `packages/mcp-product-pipeline/design-systems/`. Mirrors anthill; keeps `vendor/` semantically "Apache-attributed upstream bundle". |
| 2 | DS index shape | **Generate** `vendor/open-design/.cache/ds-index.json` during `--apply` (and during the Phase-3 bootstrap), `{name, mood, palette_summary}` per DS. Part of the manifest checksum tree. |
| 3 | `prompts/*.ts` transform | **Both forms.** Vendor the `.ts` (source of truth, importable by `server.ts`) AND generate `.extracted.md` during `--apply` for agent-facing `Read`. `od-bridge.md` points the agent at the `.extracted.md`. |
| 4 | `runtime/od-sync/` git status | **Commit** the daily `.md` reports (audit trail, mirrors anthill). **Gitignore + npmignore** the tarball cache and extracted dirs (`tarball-*.tar.gz`, `extracted-*/`). |
| 5 | npm license attribution | `package.json` `license` stays the package's own license. The vendored Apache-2.0 content carries `LICENSE` + `NOTICE` + `.LICENSE.provenance` inside its own subtree (standard vendored-dep pattern). Add a one-line pointer in the package `README.md`. No `license: "Apache-2.0 AND …"` SPDX compound — npm has no per-path license concept and the compound would misrepresent the package code's license. |
| 6 | Fail-loud vs degrade | **Fail loud.** The path-resolver MCP tool detects a missing/partial vendor tree and returns an actionable error. No automatic fallback. The inline 5-school description is **retained in `pipeline.md`** as documentation / manual escape — not deleted, not auto-wired. |

## Files to touch

**Create — vendor skeleton & tooling:**
- `packages/mcp-product-pipeline/schemas/od-vendor-manifest.schema.json` — JSON Schema for `MANIFEST.json`; port from `~/anthill/.anthill/schemas/od-vendor-manifest.schema.json`.
- `packages/mcp-product-pipeline/vendor/open-design/MANIFEST.json` — `pinned_sha`/`history`/`vendored_paths[]`/`license_attribution[]`; port anthill's, rewrite `dst` paths to package-relative.
- `packages/mcp-product-pipeline/vendor/open-design/LICENSE` — Apache-2.0 verbatim (copy from anthill).
- `packages/mcp-product-pipeline/vendor/open-design/NOTICE` — per-subtree attribution (copy from anthill).
- `packages/mcp-product-pipeline/vendor/open-design/.LICENSE.provenance` — extraction SHA + date.
- `packages/mcp-product-pipeline/scripts/sync-open-design.ts` — the sync engine; port ~659 LOC from anthill, adapt paths + invocation (bun-native, drop the `#!/usr/bin/env tsx` shebang dependency), add `--verify` subcommand.
- `packages/mcp-product-pipeline/runtime/od-sync/.gitignore` — ignore `tarball-*.tar.gz` + `extracted-*/`, keep `*.md`.

**Create — vendored content (Phase 3 bootstrap, copied from anthill at pinned SHA):**
- `packages/mcp-product-pipeline/design-systems/**` — 73 `DESIGN.md` trees.
- `packages/mcp-product-pipeline/vendor/open-design/skills/**` — 33 skill bundles + `INDEX.json`.
- `packages/mcp-product-pipeline/vendor/open-design/prompts/{system,discovery,directions}.ts` + `.extracted.md` siblings.
- `packages/mcp-product-pipeline/vendor/open-design/frames/{iphone-15-pro,macbook,browser-chrome}.html`.
- `packages/mcp-product-pipeline/vendor/open-design/templates/deck-framework.html`.
- `packages/mcp-product-pipeline/vendor/open-design/.cache/ds-index.json` — generated DS index.

**Create — MCP integration & consumer doc:**
- `packages/mcp-product-pipeline/src/od.ts` — vendor path resolution (absolute, from `import.meta.url`) + `ds-index.json` loader; the missing-tree fail-loud detection lives here.
- `packages/mcp-product-pipeline/src/templates/02-prototype/references/od-bridge.md` — consumer doc; port from `~/anthill/.claude/skills/anthill-prototype/references/od-bridge.md`, rewrite paths to package-relative + the MCP-tool-returns-absolute-path model.
- `packages/mcp-product-pipeline/tests/sync-open-design.test.ts` — checksum, manifest-shape, `validateDesignMd`, `--verify` drift detection.
- `packages/mcp-product-pipeline/tests/od.test.ts` — path resolution, index load, fail-loud on missing tree.

**Modify:**
- `packages/mcp-product-pipeline/package.json` — add `files` (include `vendor/`, `design-systems/`, `schemas/`; exclude `runtime/`), `scripts.sync`, `scripts.prepublishOnly` (`bun scripts/sync-open-design.ts --verify`).
- `packages/mcp-product-pipeline/src/tools.ts` — register `product_design_systems_index` + `product_design_system_path` (or equivalent resolver).
- `packages/mcp-product-pipeline/src/server.ts` — wire the two new tools.
- `packages/mcp-product-pipeline/src/paths.ts` — re-export / integrate the `od.ts` resolution helpers if `paths.ts` is the canonical path module.
- `packages/mcp-product-pipeline/src/templates/02-prototype/references/pipeline.md` — simplify the OD-pipeline section to point at `od-bridge.md`; **retain** the inline 5-school description under a clearly-marked "Manual escape (OD vendor unavailable)" heading.
- `packages/mcp-product-pipeline/src/templates/02-prototype/prompt.md` — point the agent at the `od-bridge.md` pre-flight read sequence.
- `packages/mcp-product-pipeline/src/templates/02-prototype/schema.md` — make DS-by-name citation in the REPORT mandatory.
- `packages/mcp-product-pipeline/README.md` — one-line pointer to the vendored Apache-2.0 LICENSE/NOTICE.
- `.gitignore` (repo root or package) — ensure `runtime/od-sync/` tarball cache is ignored.

**Delete:** none. The inline 5-school content is relocated within `pipeline.md`, not removed.

## Alternatives considered

### Re-run `--apply` from upstream for the initial port

Rejected as the *bootstrap* method. Running `--apply` against `github.com/nexu-io/open-design` at port time introduces a network dependency into the implementation, and risks subtle drift if upstream's tarball at the pinned SHA resolves differently than anthill's extraction did (line endings, file mode, ordering). Copying anthill's already-extracted, already-benchmarked tree at SHA `d25a7aaf…` is deterministic and offline. `--apply` is still built and tested — it is the mechanism for *future* bumps — but the initial content lands by copy + `--verify`, not by fresh extraction.

### Port the sync script to repo root (`scripts/sync-open-design.ts`)

Rejected. Anthill puts it at repo root because anthill *is* the project. Our MCP is a package within Agent0; per the self-contained-package rule ([[feedback_mcp_package_self_contained]]), the script, its runtime artifacts, and its schema all live under `packages/mcp-product-pipeline/`. A repo-root script would couple Agent0's tooling surface to a package concern.

### Expose vendored content via MCP tools that stream file contents

Rejected. Anthill's consumption pattern (traced in spec.md § Findings) is "agent reads files directly with its `Read` tool, using paths it learned from `od-bridge.md`". Streaming content through MCP tools would duplicate the `Read` capability, bloat MCP responses, and break the progressive-disclosure model where the agent reads only the DESIGN.md / SKILL.md it actually selected. The MCP tools resolve *paths*; the agent's `Read` does the rest.

### Graceful silent fallback to inline-5-schools when the vendor is missing

Rejected (open question 6). A silent fallback produces measurably worse output — no DESIGN.md grounding, no citation chain — without signalling *why* quality dropped. Fail-loud with a documented manual escape keeps degradation explicit and operator-chosen.

## Risks and unknowns

- **bun vs tsx runtime.** Anthill's script has `#!/usr/bin/env tsx`. The MCP package runs on bun, which executes TS natively — invocation becomes `bun scripts/sync-open-design.ts`. Need to audit the script for tsx-specific assumptions (there should be none; it uses `node:` builtins) and rewrite the shebang / `package.json` script entry.
- **`gh api` dependency in `--check`.** Anthill's `--check` uses `gh api …/compare` for the file-level diff, falling back to "list all vendored_paths as potentially changed" when `gh` is absent. The fallback must be preserved — consumers running `--check` won't reliably have `gh`. `git ls-remote` for the HEAD SHA has no auth/dependency and stays as-is.
- **npm package size.** ~3.1 MB vendored. Must verify the `files` field includes `vendor/` + `design-systems/` + `schemas/` and *excludes* `runtime/`. `npm pack --dry-run` is the verification — list it as an acceptance task. Document the final tarball size in this plan once measured.
  - **MEASURED (task 29):** tarball **769 KB** (gzipped), unpacked **2.49 MB**, 231 files. `files` field is `["src/","vendor/","design-systems/","schemas/","scripts/","README.md"]` — `runtime/` and `tests/` confirmed excluded; `vendor/open-design/.cache/ds-index.json`, `MANIFEST.json`, `LICENSE`/`NOTICE`/`.LICENSE.provenance`, `skills/INDEX.json` all confirmed shipping. (`scripts/` is included so consumers can run `--check`/`--verify`; harmless, ~25 KB.)
- **Absolute path resolution post-publish.** `src/od.ts` resolves vendor paths from `import.meta.url`. When published, the package root is `node_modules/agent0-mcp-product-pipeline/` — resolution must walk up from `src/` to package root reliably. Test both the dev layout (`packages/mcp-product-pipeline/`) and a simulated installed layout.
- **DESIGN.md H2 validation keywords.** Anthill's `validateDesignMd` checks 5 substrings (`color palette`, `typography`, `component`, `layout`, `visual theme`) — relaxed from a narrower set that matched 0/72 files. Port the *relaxed* version verbatim; do not re-derive.
- **`provenanceHeader` only stamps `.md`/`.html`/`.ts`/`.tsx`.** `.json` and binaries are checksum-only. The bootstrap-by-copy path must ensure copied files either already carry anthill's provenance headers or get them re-stamped — decide in tasks whether the copy preserves anthill's headers (they reference `open-design@<sha>`, which is correct and SHA-stable) or `--apply` re-stamps. Leaning: preserve anthill's headers since the SHA is identical.
  - **RESOLVED during impl (task 11/12):** copy preserves anthill's headers verbatim. Note: anthill's headers reference `open-design@454e8373…`, NOT the manifest's `pinned_sha` `d25a7aaf…` — anthill bumped the pin but never re-applied (last `apply` history event is at `454e8373`). The content we vendored is therefore the `454e8373` snapshot; `pinned_sha` stays `d25a7aaf…` per spec/task-3 instruction. A future `--apply` from the pin reconciles this; not a port-time blocker (bootstrap is by copy, not extraction).

- **MANIFEST tree-checksum deviation (discovered task 14).** anthill's `MANIFEST.json` records recursive-tree checksums (`design-systems/`, `skills/`, `frames/`) that do NOT match anthill's own on-disk content — verified by recomputing with the ported `computeTreeChecksum` against anthill's tree (`bef62379…` on disk vs `e7142584…` in anthill's manifest). The single-file checksums (3 `prompts/*.ts` + `deck-framework.html`) are correct. Root cause is anthill-side stale checksums (likely an `--apply` round whose tree-checksum write lagged a later file-set change). Keeping the stale values verbatim would make `--verify` — and thus `prepublishOnly` — fail permanently, defeating the provenance-integrity capability. **Resolution:** recompute the 3 recursive-tree checksums from the content we actually vendored; keep everything else (`pinned_sha`, `history`, `license_attribution`, single-file checksums) verbatim from anthill. Our MANIFEST is the byte-accurate baseline for our vendored tree; `--verify` exits 0.
- **Unknown: does upstream still resolve at the pinned SHA?** Irrelevant for the bootstrap (copy from anthill, not upstream) but relevant for the first future `--bump`. Not a port-time blocker.
- **`paths.ts` integration shape.** Haven't yet read `src/paths.ts` — the plan assumes it's the canonical path module and `od.ts` either lives beside it or is re-exported through it. Confirm during Phase 5; adjust if `paths.ts` has a different role.

## Research / citations

- Anthill ADR — `~/anthill/.anthill/memory/architecture/adr-vendor-open-design.md` — architecture decision + rejected alternatives (submodule, fork, daemon-fetch).
- Anthill sync script — `~/anthill/scripts/sync-open-design.ts` (659 LOC) — the implementation being ported; `provenanceHeader` (L159), `REQUIRED_H2_SUBSTRINGS` (L185), `validateDesignMd` (L194), subcommands `--check`/`--bump`/`--apply`.
- Anthill manifest — `~/anthill/.anthill/vendor/open-design/MANIFEST.json` — pinned SHA `d25a7aaf4219d69b6a3055ddda25fbce0dafd24d`, `vendored_paths[]` shape, `history[]` events.
- Anthill consumer doc — `~/anthill/.claude/skills/anthill-prototype/references/od-bridge.md` (187 LOC) — the consumption pattern + pre-flight read sequence being ported.
- Anthill injection — `~/anthill/scripts/inject.sh` L304-305 — symlink distribution model; documented as *not* applicable to our npm model.
- Spec — `docs/specs/027-od-vendor-port/spec.md` — acceptance criteria, § Findings, 6 open questions.
- Project memory — `.claude/memory/od-vendor-port-plan.md` (informal port plan) and `~/.claude/projects/-home-goat-Agent0/memory/feedback_mcp_package_self_contained.md` (the in-package constraint).

## Follow-up — `PRODUCT_PIPELINE_OD` on/off toggle (post-dogfood, 2026-05-14)

The step-2 OD dogfood (artifacts `/tmp/bench/step2-OD/`, blind visual judge verdict captured in `.claude/memory/od-grounding-dogfood.md`) surfaced the need for an *easy, deliberate* switch between the OD-grounded path and the pre-OD inline 5-school method — for honest A/B'ing and as a clean operator escape hatch.

**Design.** A `PRODUCT_PIPELINE_OD` env var, read by the MCP server. Off-values `off`/`0`/`false`/`no`/`disabled` (case-insensitive); unset or anything else = on (default). When off, `assertVendorPresent` throws `OdDisabledError` (code `od-disabled`) — a **subclass of `VendorMissingError`**, so `tools.ts`'s existing `instanceof VendorMissingError` catch and the step-2 templates' "Manual escape" routing pick it up with no extra wiring; only the `code` differs so the agent can tell "deliberately off" from "broken install".

**Why this was cheap.** Spec 027's open-question-6 fail-loud design already built the entire escape route — the 4 templates already route around `od-vendor-missing` to `pipeline.md` § "Manual escape". The toggle just adds a *deliberate* trigger alongside the broken-install one.

**Why a distinct `od-disabled` code (not reusing `od-vendor-missing`).** `pipeline.md` § "Manual escape" documents that section as "a broken install where the vendored bundle did not ship" — an intentional toggle hitting that exact path would contradict the doc. A distinct code keeps the docs honest and lets the audit/agent distinguish the two.

Rejected: a `.mcp.json` block-comment toggle (too coarse — kills the whole pipeline, not just OD); template variants (not "easy"); a state-file flag / config tool (heavier than an env var, and `.mcp.json` already needs a restart to reload anyway).
