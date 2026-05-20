# 066 — product-ui-quality — tasks

_Generated from `plan.md` on 2026-05-20 (re-derived after the restructure rewrite). Implemented 2026-05-20. All boxes checked — see § Notes for the verification record._

## Implementation

### Enablers

- [x] 1. **Step 14 `@theme` block.** `references/delegation-briefs.md` Step 14 brief now mandates `tokens.css` register tokens under a Tailwind v4 `@theme` block (real utilities for the downstream component-library child); DONE_WHEN updated. (F2 enabler)
- [x] 2. **Phase 0 seeds `.mcp.json`.** `SKILL.md` Phase 0 new step 3 seeds `<out>/.mcp.json` with the Playwright MCP block (append-aware merge if the file exists). (F3)

### Subtraction — delete the screen-writer fan-out

- [x] 3. **Delete the screen-writer briefs.** The Next.js + Expo `.tsx` screen-writer briefs were removed from `delegation-briefs.md`; `§ Per-stack screen-writer` replaced by `§ Mood-screen-writer`; the doc header, Step 02 (b) pointer, Concurrency cap, Failure handling, Cross-references, and `sitemap-schema.md` cross-refs all resynced. (F2/F6; F7 moot)
- [x] 4. **Rewrite `SKILL.md` Phase 4.** The per-route fan-out, waves/cap=5, parent-write degradation, between-wave biome sweeps, token-import stitch, layout.tsx placeholder stitch, build verification, and dev-server smoke-test are all deleted. (F2/F6/F7)

### Phase 4 reshape — the visual contract

- [x] 5. **Rewrite the atlas brief.** `delegation-briefs.md § Step 15a` now produces `docs/screen-atlas.md` only — the navigable contract document, no `app/` writes, no layout files. (F4)
- [x] 6. **Adapt the hi-fi-mood brief.** `§ Mood-screen-writer` is one brief, two modes — lo-fi (Step 02) and hi-fi (Step 15b): 3-5 brand+tokens-applied killer-flow screens as self-contained static HTML with `<style>`+`@media`, mobile-first, never `style=` for layout. (F1)
- [x] 7. **Add the fixture-spec brief + wire Phase 4.** `§ Step 15c` brief emits `docs/fixture-spec.md` (one persona, one coherent entity set, consistent dates). `SKILL.md` Phase 4 = dispatch 15a+15b+15c in one message → best-effort Playwright visual check (375 + 1280 px, horizontal-overflow probe; `visual-gate-skipped` advisory if absent) → REPORT.md. (F9, F3)

### Phase 5 — mandatory SDD handoff

- [x] 8. **Create `references/sdd-handoff.md`.** Defines the umbrella spec shape (`**Type:** umbrella`, child-matrix sliced by roadmap phase, standing constraints), child #1 (foundation) contents, and the single-`app-build`-child fallback for a degenerate roadmap.
- [x] 9. **Rewrite `SKILL.md` Phase 5.** `/product` writes the filled umbrella + foundation child specs directly under `<out>/docs/specs/` (sdd templates as base); children #2..N are matrix rows. The handoff message prints the umbrella path, not `pnpm dev`.

### Supporting resync

- [x] 10. **`quality-checklist.md`** rewritten — per-step gates 01-14 + visual-contract gates (15a/15b/15c) + SDD-handoff gates; the fan-out / build-health / fidelity-scorecard sections removed.
- [x] 11. **`pipeline-coverage.md`** reshaped — Step 15 row is atlas + hi-fi mood + fixture-spec; Phase 5 documented; v0.4.0 / 5-phase.
- [x] 12. **`state-machine.md`** — `.state.json` bumped 4 → 5; `phase` enum gains `sdd-handoff`; Phase 4/5 progression + resume validation + failure handling updated.
- [x] 13. **`report.md.tmpl`** rewritten — atlas coverage + visual-check section + SDD-handoff (umbrella path); 36-route build-health / fan-out-degradation sections dropped.
- [x] 14. **`templates/pipeline/15-screen-atlas/`** rewritten — `prompt.md` + `schema.md` for the atlas-only role (current numbering, no MCP, no screen-writer); 4 obsolete reference files pruned. (F8)

## Verification

- [x] 15. **Skill validator passes.** `bash .claude/skills/skill/scripts/validate.sh .claude/skills/product` exits 0 (`rule8-body-token-warn` is a pre-existing non-blocking warning).
- [x] 16. **F1-F9 matrix self-audit.** Each flaw traces to a concrete edit (see § Notes); all 9 static-fact acceptance criteria in `spec.md` hold by direct inspection.
- [x] 17. **`/product` synthetic smoke trace.** The 5 `spec.md` acceptance scenarios were traced against the rewritten `SKILL.md` Phase 0→5 + the briefs (verification method: synthetic trace, per the spec-059 precedent — a full live `/product` run is a multi-hour dogfood; the live mei-saas re-run is the downstream confirmation the spec already names as "the first re-validation target").

## Notes

### F1-F9 self-audit (task 16)

| Flaw | Resolved by |
|---|---|
| F1 mobile-first absent | `§ Mood-screen-writer` brief mandates mobile-first `@media`; `sdd-handoff.md § Standing constraints` makes it a build-layer constraint every SDD child inherits |
| F2 inline `style={{}}` sanctioned | the `.tsx` screen-writer brief carrying the sanction is deleted; `sdd-handoff.md` standing constraint forbids inline layout style |
| F3 no visual gate | Phase 0 seeds `.mcp.json`; Phase 4 step 3 is a best-effort Playwright check; SDD children verify via Playwright per the standing constraint |
| F4 chrome unvalidated | the atlas writes no `app/` layouts; chrome components are child #2's job, wired into child #1's thin shells |
| F5 no shared component layer | `components.md` is the named input spec for child #2 (component-library) in the umbrella matrix |
| F6 inline-style bloat | dissolves with the deleted fan-out |
| F7 validator-cascade | moot for `/product` (no fan-out); root harness flaw → spec 067 |
| F8 Step 15 template desynced | `15-screen-atlas/{prompt,schema}.md` rewritten; 4 obsolete reference files pruned |
| F9 incoherent fixtures | `§ Step 15c` emits `fixture-spec.md`; `sdd-handoff.md` standing constraint mandates the foundation child's `lib/mock-data.ts` as the one source |

### Synthetic smoke trace (task 17)

Each `spec.md` scenario traced against the rewritten skill body: (1) Phase 4 produces `screen-atlas.md` + hi-fi mood + lo-fi mood, no `app/**/page.tsx`, no fan-out ✓; (2) Phase 5 steps 1-2 scaffold the umbrella + foundation child under `docs/specs/` ✓; (3) `§ Mood-screen-writer` hi-fi mode mandates `<style>`+`@media` mobile-first, no `style=` layout ✓; (4) `sdd-handoff.md § Child-spec matrix` names `components.md` as child #2's input spec ✓; (5) `§ Step 15c` emits `fixture-spec.md` ✓. The live `/product` dogfood (mei-saas re-run) is the downstream confirmation.
