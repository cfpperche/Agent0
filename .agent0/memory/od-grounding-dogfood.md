---
name: OD grounding dogfood
description: Spec 027 step-2 dogfood — grounding-by-path buys provenance, not one-shot
  polish. Fair re-match CLOSED 2026-06-02 (apparatus gone); canvas-contrast residual fixed.
metadata:
  type: project
  created_at: '2026-05-14T19:59:56-03:00'
  last_accessed: '2026-05-24'
  confirmed_count: 0
---
# OD grounding dogfood — what spec 027 actually buys

Dogfooded 2026-05-14, the day spec 027 (Open Design vendor port) shipped. The step-2 prototype stage was run end-to-end with the OD vendor in the loop, on the SwiftBoard brief (`/tmp/bench/step2-fixture.md` + `brief_B.md`) — the same input the pre-OD step-2 benchmark used, so OD grounding is the only variable.

## What worked — the capability is sound

- The two MCP tools (`product_design_systems_index`, `product_design_system_path`) are live over the real stdio boundary; fail-loud paths verified.
- The citation-by-path wedge is real: the Producer resolved 6 vendored design systems via the path resolver, read each `DESIGN.md` before writing HTML, and `REPORT.md` carried 13 `design-systems/<x>/DESIGN.md` path citations. `validateLayer1` passes against the new `design-systems/` schema floor.
- `--check` against live upstream works (detected drift vs the pin).

## What the blind visual judge found — and the confound

A blind judge (opus, Playwright-rendered, randomized A/B labels) scored the single-pass OD-grounded run **3.87** vs the pre-OD baseline **4.73** — the OD run lost, decisively, on every dimension or tied.

**Do NOT read this as "OD grounding is worse."** It is not apples-to-apples: the baseline (`step2-refined-v4`) is the product of **4 refinement iterations**; the OD run was **one Producer pass, zero iterations**. The judge compared a first draft against a 4×-polished artifact.

## The durable, confound-independent findings

1. **Grounding-by-path is mechanically sound but does not, by itself, buy visual quality.** Visual quality is iteration-bound — the wedge gives you a verifiable citation chain and pinned palette values, not a better-looking first draft. The 027 value proposition is *provenance and reproducibility*, not *one-shot polish*.
2. **Guidance gap — canvas contrast. ADDRESSED 2026-06-02.** With the 72-system catalogue available, the Producer clustered directions A and B on dark-canvas composites (`linear-app`+`vercel`, `voltagent`+`warp`) — school-distinct but visually similar — despite the fixture explicitly asking for 3 *contrasting* families. The school-diversity "Hard rule" in `02-prototype/prompt.md` did not catch this (different schools can still share one canvas tone). Fixed by adding an explicit **canvas-contrast clause** to that rule: ≥2 distinct canvas tones across the 3 directions, don't ship 3 dark canvases. This is the durable residual that closed reminder `r-2026-05-14`.
3. **First-pass Producer output bug:** `--primary` and `--accent` were assigned the same hex in one direction — iteration-fixable, but a credibility crack a judge will catch.

## The toggle this produced — NOW DEFUNCT

`PRODUCT_PIPELINE_OD=off` (env var on the MCP server) flipped the OD tools to return `code: "od-disabled"`, routing step 2 to the pre-OD "Manual escape" path, built so OD-grounded vs pre-OD could be A/B'd honestly. **Gone as of 2026-06-02:** the MCP server (`packages/mcp-product-pipeline/`) was deleted when the pipeline moved into the `/product` skill (specs 048+), and the toggle survives only in `docs/specs/027/{plan,tasks}.md`. The current OD-unavailable fallback is `02-prototype/references/pipeline.md` § "Manual escape — OD vendor unavailable" (no env toggle).

## Fair re-match — CLOSED 2026-06-02 as overtaken-by-events

Reminder `r-2026-05-14` (fair OD re-match) was closed without re-running. The entire apparatus is gone: MCP server deleted, `PRODUCT_PIPELINE_OD` toggle defunct, `/tmp/bench/` artifacts wiped. Re-running would mean rebuilding the benchmark from scratch under the `/product`-skill architecture to re-confirm finding #1 (already durable here). Decision (founder-ratified): close it; extract only the concrete residual — the canvas-contrast rule (finding #2, now ADDRESSED). If a *defensible iteration-matched number* for the 027 provenance claim is ever wanted, scope it as a fresh `/sdd` spec under the current architecture, not a `/tmp` benchmark.

## Pointers

- Original artifacts (`/tmp/bench/step2-OD/`, `step2-refined-v4/`, `od-judge-randomization.txt`) — **wiped** (were `/tmp`, gone by 2026-06-02). Not recoverable.
- Canvas-contrast rule: `.claude/skills/product/templates/pipeline/02-prototype/prompt.md` § "Pick 3 direction families" → **Canvas contrast (load-bearing)** clause.
- The headline 3.87-vs-4.73 number is confounded — do not cite it as evidence either way.
