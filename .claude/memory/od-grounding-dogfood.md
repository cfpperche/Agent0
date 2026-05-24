---
name: od-grounding-dogfood
description: Spec 027 step-2 dogfood (2026-05-14) — citation-by-path real, but grounding alone does not buy visual quality. Blind judge result was confounded (1-pass OD vs 4x-refined baseline).
metadata:
  type: project
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
2. **Possible guidance gap — canvas contrast.** With the 72-system catalogue available, the Producer clustered directions A and B on dark-canvas composites (`linear-app`+`vercel`, `voltagent`+`warp`) — school-distinct but visually similar — despite the fixture explicitly asking for 3 *contrasting* families. Having the vendored catalogue did not steer the agent toward canvas-level contrast. If a second dogfood repeats this, `od-bridge.md` / `prompt.md` need a harder canvas-contrast rule.
3. **First-pass Producer output bug:** `--primary` and `--accent` were assigned the same hex in one direction — iteration-fixable, but a credibility crack a judge will catch.

## The toggle this produced

`PRODUCT_PIPELINE_OD=off` (env var on the MCP server) flips the OD tools to return `code: "od-disabled"`, routing step 2 to the pre-OD inline 5-school "Manual escape" path. Built as a spec 027 follow-up (see `docs/specs/027-od-vendor-port/{plan,tasks}.md` § Follow-up / Phase 7) specifically so OD-grounded vs pre-OD can be A/B'd honestly going forward — next time with matched iteration counts.

## Pointers

- Artifacts: `/tmp/bench/step2-OD/` (wipe-able), baseline `/tmp/bench/step2-refined-v4/`, randomization `/tmp/bench/od-judge-randomization.txt`.
- Next fair re-match: either iterate the OD run to 4 passes, or judge it against the *first-pass* baseline — not `refined-v4`.
