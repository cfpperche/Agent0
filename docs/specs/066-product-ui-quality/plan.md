# 066 — product-ui-quality — plan

_Drafted from `spec.md` on 2026-05-20 (re-derived after the restructure rewrite). Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

The restructure touches only the **tail** of `/product` — Phase 0 (one seed), Step 14 (one addition), and Phases 4-5 (the substantive rewrite). Steps 01-13 are untouched. The strategy is subtractive first, then additive: delete the screen-writer fan-out, then build the two replacements (the hi-fi mood + the SDD handoff).

**1. Delete the screen-writer fan-out.** In `SKILL.md` Phase 4 § Step 15, remove the per-route screen-writer fan-out and everything that served it — waves/cap=5, parent-write degradation, between-wave biome sweeps, the token-import stitch, build-verification (install/tsc/biome), the dev-server smoke-test. In `delegation-briefs.md`, delete the Next.js and Expo screen-writer brief sections. This single subtraction resolves F2/F6 and makes F7 moot for `/product`.

**2. Reshape Phase 4 into the visual contract.** Step 15 becomes: (a) the atlas sub-agent produces `docs/screen-atlas.md` only — the navigable contract document, **no `app/` writes**; (b) a hi-fi-mood step produces 3-5 brand+tokens-applied killer-flow screens as self-contained static HTML — the proven Step 02 mechanism, but with a `<style>` block carrying `@media` breakpoints (mobile-first) instead of `style=` attributes; (c) a fixture/seed spec is emitted (`docs/fixture-spec.md`) from the concept-brief persona + system-design entities — one persona, one coherent entity set, consistent dates; (d) if the Playwright MCP is loaded, the hi-fi mood is screenshotted at mobile+desktop and overflow-checked (advisory, best-effort). The atlas brief is rewritten for the atlas-only role; a hi-fi-mood brief is adapted from the Step 02 mood brief.

**3. Add Phase 5 — mandatory SDD handoff.** `/product` writes, directly under `docs/specs/`: a filled umbrella spec (`**Type:** umbrella`, child-matrix sliced by roadmap phase, standing constraints baked in) plus the foundation child spec (child #1, ready to start). Children #2..N are *listed in the umbrella matrix*, not pre-scaffolded. The Phase 5 message points at the umbrella, not `pnpm dev`. A new `references/sdd-handoff.md` defines the umbrella shape, the child-matrix format, the standing constraints, and child #1's contents.

**4. Phase 0 + Step 14 enablers.** Phase 0 seeds `<out>/.mcp.json` with the Playwright block (append-aware). Step 14's design-system brief emits the Tailwind v4 `@theme` token block.

**5. Resync the supporting artifacts.** `quality-checklist.md`, `pipeline-coverage.md`, `state-machine.md` (`.state.json` Phase 4/5 shape — bump to v5), `report.md.tmpl`, and `templates/pipeline/15-screen-atlas/` all updated for the atlas-only / handoff reality.

**Open-question resolutions** (from `spec.md`): **OQ1** — `/product` writes the umbrella + child #1 spec files **directly** (using the `sdd` templates as a base), NOT by invoking `/sdd new` skill-to-skill — because `/product` must *fill* the specs from pipeline artifacts, which `/sdd new` does not do, and nesting skill invocations adds fragility. **OQ2** — child #1 (foundation) owns the skeleton + tooling + route-group dirs + thin `layout.tsx` shells; the shared chrome *components* (Sidebar, MarketingHeader…) belong to child #2 (component library), which also wires them into the shells — keeps all components in one child. **OQ3** — the hi-fi mood covers the same killer-flow screens Step 02's lo-fi mood selected (visual lineage preserved).

Order of work: enablers (4) → subtraction (1) → Phase 4 reshape (2) → Phase 5 (3) → supporting resync (5) → verify.

## Files to touch

**Modify:**
- `.claude/skills/product/SKILL.md` — Phase 0 (`.mcp.json` seed); Phase 4 § Step 15 (delete fan-out; reshape to atlas + hi-fi mood + fixture-spec + visual check); Phase 5 (SDD handoff message → umbrella path); § Notes.
- `.claude/skills/product/references/delegation-briefs.md` — **delete** the Next.js + Expo screen-writer brief sections; rewrite the atlas brief (atlas-only, no `app/` writes); adapt a hi-fi-mood brief from the Step 02 mood brief; add the Step 14 `@theme` instruction.
- `.claude/skills/product/references/quality-checklist.md` — Step 15 criteria → atlas completeness + hi-fi mood (drop the 36-route fan-out criteria).
- `.claude/skills/product/references/pipeline-coverage.md` — Step 15 reshaped; Phase 5 documented; F6 budget note moot.
- `.claude/skills/product/references/state-machine.md` — `.state.json` Phase 4/5 shape; bump `version` 4 → 5 (consistent with the existing refuse-silent-upgrade posture).
- `.claude/skills/product/templates/report.md.tmpl` — REPORT.md → atlas coverage + hi-fi mood visual-check section + the SDD-handoff (umbrella path); drop 36-route build-health.
- `.claude/skills/product/templates/pipeline/15-screen-atlas/` (`prompt.md` + `references/`) — rewritten for the atlas-only role (closes F8).

**Create:**
- `.claude/skills/product/references/sdd-handoff.md` — defines the Phase 5 output: umbrella spec shape (`Type: umbrella`, child-matrix by roadmap phase, standing constraints — Tailwind/no-inline-layout-style, fixture coherence), and child #1 (foundation) contents.

**Delete:**
- None as whole files; the screen-writer brief removal is a within-file deletion in `delegation-briefs.md`. Obsolete screen-writer-specific files under `templates/pipeline/15-screen-atlas/references/` are pruned as part of the rewrite.

## Alternatives considered

### Keep the screen-writer fan-out and fix it (the original spec 066 framing)

Rejected. The original `plan.md` (committed `9fa8706`) tried this — 17 tasks editing the screen-writer brief to mandate Tailwind, add a visual gate, insert a component-builder. But making a *blind parallel fan-out* produce responsive, consistent, visually-verified UI is the hard problem the original `/product` design already lost. Removal is structurally simpler than repair: deleting the fan-out resolves F2/F6 outright and makes F7 moot, where the repair plan only mitigated them. Confirmed across the 2026-05-20 design discussion.

### `/product` invokes `/sdd new` skill-to-skill to scaffold the handoff

Rejected. `/sdd new` only does mkdir + template-copy + placeholder substitution — it deliberately does NOT fill `spec.md` (the user owns intent). `/product` Phase 5 must fill the umbrella + child #1 from the pipeline artifacts, so it would invoke `/sdd new` and *then* fill anyway. Writing the dirs directly (with the `sdd` templates as the base) is one step instead of two and avoids nesting one skill's control flow inside another's.

### Pre-scaffold all child specs (#2..N) at handoff time

Rejected. Eight empty child-spec dirs that sit untouched for months are clutter and rot. The umbrella's child-matrix *tracks* them (the spec-060 umbrella pattern); the founder materializes each via `/sdd new <phase>` when reaching it.

### Make the hi-fi mood a real partial Next.js render

Rejected. Any Next.js `.tsx` generation re-introduces the fan-out failure mode (validator interaction, build infra, the cascade). Self-contained static HTML is the Step 02 mechanism — empirically clean in the mei-saas dogfood — and needs no skeleton.

## Risks and unknowns

- **`.state.json` v4 → v5.** Phase 4/5 shape changes; an in-flight v4 run would mismatch. Mitigated by the existing refuse-silent-upgrade posture (state-machine already aborts on stale versions) — v5 is consistent, not novel.
- **Umbrella quality depends on the roadmap.** The child-matrix is sliced by Step 10's phases; a thin or poorly-phased roadmap yields a thin slicing. The umbrella generation should fall back to a single "app build" child if the roadmap has no usable phase structure.
- **`delegation-briefs.md` is 63 KB** — deleting two brief sections + rewriting the atlas brief is a large surgical edit; risk of leaving dangling cross-references elsewhere in the doc.
- **Visual check is best-effort.** Phase 0 seeds `.mcp.json`, but MCP is not live until a session restart — the check runs in the same `/product` run only if Playwright was already loaded. Honest degradation: advisory skip.
- **Expo symmetry.** Deleting the Expo screen-writer brief means the Expo path also ends at atlas + handoff. Confirm the Expo handoff (NativeWind, Expo Router) is coherent, or scope Expo to a follow-up.
- **Verification cost.** The final acceptance criterion needs a real `/product` smoke run; ~heavy but bounded once the fan-out (the slow part) is gone.

## Research / citations

- [Tailwind CSS v4 — Theme variables](https://tailwindcss.com/docs/theme) / [v4 release](https://tailwindcss.com/blog/tailwindcss-v4) — `@theme` directive; v4 keeps mobile-first breakpoint prefixes. Grounds the Step 14 `@theme` addition + the hi-fi mood `@media` requirement.
- [Playwright visual / responsive testing](https://codoid.com/automation-testing/playwright-visual-testing-a-comprehensive-guide-to-ui-regression/) — multi-viewport; horizontal-overflow as a layout-failure signal. Grounds the best-effort visual check.
- `.claude/rules/spec-driven.md` § umbrella spec type; `docs/specs/060-harness-gaps-2026/` — the canonical umbrella + child-matrix pattern the Phase 5 handoff mirrors.
- mei-saas dogfood (`/product` "Simplis", 2026-05-19/20) + the mei-saas agent's follow-up report (2026-05-20) — the F1-F9 evidence base in `spec.md § Context`.
- `.claude/skills/product/SKILL.md`, `references/delegation-briefs.md`, `references/state-machine.md` — the artifacts being restructured.
