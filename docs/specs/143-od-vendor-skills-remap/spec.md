# 143 — od-vendor-skills-remap

_Created 2026-06-02._

**Status:** shipped (2026-06-02 — on origin/main, propagated to 4 consumers)

## Intent

The OD pin advance to `c128ffd5` (shipped in `5233ab3`, already pushed to Agent0 + 3 consumers) silently reorganized the upstream `skills/` tree out from under the `/product` pipeline. At `c128ffd5`, upstream's `skills/` is a **154-bundle creative set** (ad-creative, apple-hig, html-ppt-*, orbit-*, …), while the bundles the pipeline was built against — `web-prototype`, `saas-landing`, and 29 others — **moved to `design-templates/`** (verified 2026-06-02: 31/31 present, byte-structure parity, e.g. `design-templates/web-prototype/{SKILL.md, assets/template.html, example.html, references/{checklist,layouts}.md}` matches the old `skills/web-prototype/` exactly). The `MANIFEST.json` vendored-path still maps `src: "skills/"`, so `--apply` now vendors the wrong tree; the pipeline keeps working ONLY because spec 142's not-yet-fixed orphan bug left the old bundles on disk. This spec re-points the skills vendored-path **`src: "skills/"` → `src: "design-templates/"`** (keeping `dst: "vendor/open-design/skills/"` so the pipeline's `vendor/open-design/skills/<bundle>` references need **zero edits**), re-applies, and confirms the 31 pipeline bundles resolve from their new upstream home. It is the **hard predecessor of spec 142** (orphan-prune): once `skills/` vendors `design-templates/`, the stale upstream creative set becomes the orphan set 142 can safely prune. This spec does NOT implement pruning (142 owns that) and does NOT re-pin (stays at `c128ffd5`).

## Acceptance criteria

- [x] **Scenario: the skills vendored-path is re-pointed to the upstream `design-templates/` tree**
  - **Given** the `MANIFEST.json` vendored-path `{ src: "skills/", dst: "vendor/open-design/skills/", kind: "skill-bundle-tree", recursive: true }`
  - **When** spec 143 lands
  - **Then** its `src` is `"design-templates/"` (dst unchanged), and `--apply` stages the `design-templates/` tree into `vendor/open-design/skills/`, recomputing the path's tree checksum for the new content

- [x] **Scenario: every pipeline-referenced bundle resolves from the new source**
  - **Given** the pipeline references `vendor/open-design/skills/{web-prototype,saas-landing,…}` (31 bundles named across `02-prototype/{prompt.md,references/{od-bridge.md,pipeline.md}}`)
  - **When** `--apply` completes with the new mapping
  - **Then** all 31 resolve on disk (e.g. `vendor/open-design/skills/web-prototype/assets/template.html` exists and carries the `c128ffd5` provenance header)

- [x] **Scenario: zero pipeline-template edits required**
  - **Given** the dst root stays `vendor/open-design/skills/`
  - **When** the remap lands
  - **Then** no `templates/pipeline/**` file needs a path edit — the rename is invisible to consumers of the vendored paths (the `src` change is internal to the manifest)

- [x] **Confirmation (static): `design-templates/` is the correct upstream home.** Verified 2026-06-02 against the extracted `c128ffd5` tarball: 31/31 pipeline bundles present under `design-templates/`, identical file structure; `skills/` at `c128ffd5` is a disjoint creative set. Spec 027's "mirror upstream exactly" contract → mirror the tree that actually holds the pipeline's bundles.

- [x] **Hand-off to 142 (cross-ref, not this spec's job):** after the remap + apply, the now-orphaned upstream creative `skills/` bundles remain on disk and `--verify` stays red until spec 142 prunes them. 143 makes the pipeline correctly *sourced*; 142 makes `--verify` *green*. _(confirmed: `--verify` fails only on `skills/`, passes on the other 6 paths)_

## Non-goals

- Implementing orphan pruning or making `--verify` green — that is spec 142 (the successor); 143 only corrects the source mapping.
- Re-pinning / advancing / reverting the OD pin — stays at `c128ffd5`; this is a mapping fix, not a pin change.
- Touching the `design-systems/` or `frames/` vendored paths — only the skill-bundle path is mis-mapped.
- Editing pipeline templates' bundle paths — explicitly avoided by keeping the dst root stable.
- Restructuring / extracting the OD vendor (`r-2026-06-01`, founder-gated).

## Open questions

_All 4 resolved at `/sdd plan` — see `plan.md` § OQ resolutions._

- [x] **Whole tree vs only 31** → whole `design-templates/` tree (per spec 027 no-partial-vendor).
- [x] **Keep dst vs rename** → keep `dst: "vendor/open-design/skills/"` (zero pipeline edits, min blast radius).
- [x] **`kind` label** → keep `"skill-bundle-tree"` (verified: not functionally used; display-only).
- [x] **Provenance path** → accept natural change to `:design-templates/<bundle>/…` (names the real upstream path; confirmed in V1).

## Context / references

- `docs/specs/142-od-sync-orphan-prune/debate.md` § Synthesis — the Claude Code ↔ Codex CLI debate that surfaced this reorg as the root cause behind 142's premise; OQ4 resolution names 143 as predecessor.
- `docs/specs/142-od-sync-orphan-prune/spec.md` § Intent (Premise correction) — the successor spec; 142 must not run before 143.
- `docs/specs/141-od-sync-apply-completeness/` — the engine spec whose `--apply` (now content-true) will perform the remap apply.
- Evidence (2026-06-02): `c128ffd5` `skills/` = 154 creative bundles; `design-templates/` = 111 bundles incl. all 31 pipeline ones with structure parity; pipeline references in `templates/pipeline/02-prototype/{prompt.md, references/od-bridge.md, references/pipeline.md}`.
- `.claude/skills/product/vendor/open-design/MANIFEST.json` — the `vendored_paths[]` entry to edit (the `skill-bundle-tree`).
- `5233ab3` — the advance that introduced the mis-mapping; `r-2026-06-01` — the distinct OD-extraction.
