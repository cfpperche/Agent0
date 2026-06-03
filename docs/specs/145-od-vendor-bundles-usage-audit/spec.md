# 145 — od-vendor-bundles-usage-audit

_Created 2026-06-03._

**Status:** draft

## Intent

Decide the fate of the `.claude/skills/product/vendor/open-design/` tree (747 tracked files: 729 `skills/` bundles + `prompts/` + `frames/` + `templates/` + license/manifest), which **static analysis shows the `/product` pipeline never reads** — yet which is git-tracked and therefore propagated to every consumer on harness sync. Surfaced 2026-06-03 while reviewing spec 144: grepping the 13 pipeline-owned files (`SKILL.md` + `references/**` + `scripts/**`, excluding the sync engine and the vendored trees themselves) found **zero** references to `vendor/open-design/{skills,prompts,frames,templates}`. The OD content the generation flow actually consumes lives in the **sibling** `design-systems/` tree (150 `DESIGN.md`), reached via `references/od-catalog-index.json` (`"source": "design-systems/"`) at Step 14, and cited per `quality-checklist.md` "od-citation". The only consumer of `vendor/open-design/` is `sync-open-design.ts` — the engine that *maintains* it. **Counter-hypothesis (must be weighed, not dismissed):** spec 049's intent explicitly framed the anthill sibling-split as "`vendor/` for Apache-attributed **upstream**, `design-systems/` for the **consumed** `DESIGN.md` tree" — i.e. the vendor copy may be *intentional provenance/attribution material*, not dead weight. This spec is **investigate-then-decide**: confirm whether `vendor/open-design/` (esp. the 729-file `skills/`) is intended latent material or droppable, quantify the propagation cost, and only then propose an action. No removal happens without that confirmation.

## Acceptance criteria

- [ ] **Scenario: usage is confirmed by more than a static grep**
  - **Given** the hypothesis that `/product` never reads `vendor/open-design/`
  - **When** the audit runs (static grep of all pipeline files + `SKILL.md` prose for ad-hoc `Read` instructions + a check of whether any reference/doc routes an agent into the vendor bundles)
  - **Then** the audit produces a definitive "read / not-read at generation runtime" verdict per vendor subdir (`skills/`, `prompts/`, `frames/`, `templates/`), with the evidence, distinguishing "referenced by the sync engine" from "referenced by the pipeline"

- [ ] **Scenario: original intent is established from history, not inferred**
  - **Given** specs 027 / 049 / 143 and the anthill ADR (`adr-vendor-open-design.md`)
  - **When** the audit reads them
  - **Then** it states whether the vendor copy was intended as (a) consumed bundle source, (b) attribution/provenance-only upstream mirror, or (c) future-use latent material — citing the spec text, so the decision rests on documented intent

- [ ] **Scenario: the decision is made and, if "drop", scoped safely**
  - **Given** the usage verdict + intent finding
  - **When** the decision is taken
  - **Then** it is one of: KEEP (with the rule/SKILL.md updated to say *why* the unused-by-pipeline vendor tree is retained), or DROP (remove the relevant `vendored_paths[]` entries from `MANIFEST.json` + the dst tree), with the OD-engine `--verify` consequence worked out and Apache-2.0 attribution (`LICENSE`/`NOTICE`) preserved regardless

- [ ] Quantify the propagation cost: files × consumers carried for the unused tree (today 729 `skills/` × N consumers), as the concrete motivator for/against.

## Non-goals

- Spec 144's git-aware walk — already shipped (`528c475`); this is a separate question about *what is tracked in the first place*, not how the walk filters.
- Touching `design-systems/` (the genuinely-consumed tree) — out of scope; only `vendor/open-design/` is under audit.
- Removing the OD sync engine or changing the vendoring mechanism — at most this spec edits which `vendored_paths[]` are vendored, not how vendoring works.
- Dropping Apache-2.0 `LICENSE`/`NOTICE`/attribution — preserved under every outcome.

## Open questions

- [ ] **Is `vendor/open-design/skills/` (729 files) read at generation runtime at all, or only by the sync engine?** Static evidence says only the engine; confirm there is no prose-directed ad-hoc `Read`.
- [ ] **Was the vendor copy intended as attribution/provenance (per 049's "Apache-attributed upstream" framing), making retention correct?** If so, KEEP + document; the "dead weight" framing is wrong.
- [ ] **If droppable, what breaks?** `MANIFEST.json` `vendored_paths[]` has `vendor/open-design/skills/ ← design-templates/` and `…/frames/ ← assets/frames/` as independent paths; removing them changes `sync-open-design.ts --verify` scope — work out the exact consequence before cutting.
- [ ] **Owner / path to resolution:** needs the founder's call on the provenance-vs-weight intent (same author who shaped 027/049); the audit gathers evidence, the founder decides KEEP vs DROP.

## Context / references

- Trigger: spec 144 review (2026-06-03). `/product` reads `design-systems/` via `references/od-catalog-index.json`; `vendor/open-design/` referenced only by `scripts/sync-open-design.ts`.
- `docs/specs/049-od-vendor-port-to-skill/spec.md` § Intent — the "`vendor/` = Apache-attributed upstream, `design-systems/` = consumed" sibling-split framing (the KEEP counter-hypothesis).
- `docs/specs/027-od-vendor-port/`, `143-od-vendor-skills-remap/` — vendoring history; the `skills/ ← design-templates/` src remap.
- `.claude/skills/product/vendor/open-design/MANIFEST.json` § `vendored_paths` — `design-systems/` and `vendor/open-design/skills/` are independent upstream-vendored paths (not one generated from the other).
- anthill ADR `.anthill/memory/architecture/adr-vendor-open-design.md` (if reachable) — the origin of the sibling-split pattern.
- `.claude/skills/product/SKILL.md` line ~288 — describes the vendor as bundled/self-contained.
