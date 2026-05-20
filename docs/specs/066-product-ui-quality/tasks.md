# 066 — product-ui-quality — tasks

_Generated from `plan.md` on 2026-05-20 (re-derived after the restructure rewrite). Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Enablers

- [ ] 1. **Step 14 `@theme` block.** In `references/delegation-briefs.md`, extend the Step 14 design-system brief so the produced `tokens.css` registers tokens under a Tailwind v4 `@theme` block (not only `:root` vars) — the downstream component-library child needs real utilities. (F2 enabler)
- [ ] 2. **Phase 0 seeds `.mcp.json`.** In `SKILL.md` Phase 0, add a step that seeds `<out>/.mcp.json` with the Playwright MCP block (append-aware if the file exists; source the block from `.mcp.json.example` / mcp-recipes). (F3)

### Subtraction — delete the screen-writer fan-out

- [ ] 3. **Delete the screen-writer briefs.** Remove the Next.js and Expo screen-writer brief sections from `references/delegation-briefs.md`; grep the rest of the doc + `SKILL.md` for dangling references to them and fix each. (F2/F6; F7 moot)
- [ ] 4. **Rewrite `SKILL.md` Phase 4.** Delete the per-route fan-out and everything serving it — waves/cap=5, parent-write degradation, between-wave biome sweeps, the token-import stitch, build-verification (install/tsc/biome), the dev-server smoke-test. Phase 4 is rebuilt in tasks 7. (F2/F6/F7)

### Phase 4 reshape — the visual contract

- [ ] 5. **Rewrite the atlas brief.** In `delegation-briefs.md`, the Step 15a atlas brief now produces `docs/screen-atlas.md` only — the navigable contract document, **no `app/` writes**. (F4)
- [ ] 6. **Adapt the hi-fi-mood brief.** From the Step 02 mood brief, derive a hi-fi-mood brief: 3-5 brand+tokens-applied killer-flow screens (same screens Step 02's lo-fi mood selected) as self-contained static HTML with a `<style>` block carrying `@media` breakpoints — mobile-first, never `style=` attributes for layout. (F1)
- [ ] 7. **Add the fixture-spec brief + wire Phase 4.** Add a brief that emits `docs/fixture-spec.md` (one persona from the concept brief, one coherent entity set from system-design, internally consistent dates). Then in `SKILL.md` Phase 4, write the new Step 15 sequence: atlas → hi-fi mood → fixture-spec → best-effort Playwright visual check (375 + 1280 px, horizontal-overflow check via `browser_evaluate`; advisory, `visual-gate-skipped` advisory if `mcp__playwright__*` absent; results to `REPORT.md`). (F9, F3)

### Phase 5 — mandatory SDD handoff

- [ ] 8. **Create `references/sdd-handoff.md`.** Define the Phase 5 output: the umbrella spec shape (`**Type:** umbrella`, child-matrix sliced by roadmap phase, standing constraints — Tailwind utility classes / no inline `style` for layout / fixture coherence), and child #1 (foundation) contents (skeleton + tooling + route-group dirs + thin `layout.tsx` shells). Note the fallback to a single "app build" child when the roadmap has no usable phase structure.
- [ ] 9. **Rewrite `SKILL.md` Phase 5.** `/product` writes — directly under `docs/specs/` using the `sdd` templates as base — the filled umbrella spec + the foundation child spec (child #1); children #2..N listed in the umbrella matrix, not scaffolded. The Phase 5 handoff message prints the umbrella path, not `pnpm dev`. (per `sdd-handoff.md`)

### Supporting resync

- [ ] 10. **`quality-checklist.md`.** Replace the Step 15 criteria (36-route fan-out checks) with atlas-completeness + hi-fi-mood criteria.
- [ ] 11. **`pipeline-coverage.md`.** Reshape the Step 15 row for the atlas-only role; document Phase 5 (SDD handoff).
- [ ] 12. **`state-machine.md`.** Update the `.state.json` shape for the new Phase 4/5; bump `version` 4 → 5 (refuse-silent-upgrade posture preserved).
- [ ] 13. **`report.md.tmpl`.** Reshape `REPORT.md`: atlas coverage + hi-fi-mood visual-check section + the SDD-handoff (umbrella path); drop the 36-route build-health section.
- [ ] 14. **Rewrite `templates/pipeline/15-screen-atlas/`.** Rewrite `prompt.md` + `references/` for the atlas-only role — no screen-writer references, no per-route `.html` output, current 15-step numbering; prune obsolete screen-writer-specific reference files. (F8)

## Verification

_Acceptance checks tied to `spec.md` § Acceptance criteria._

- [ ] 15. **Skill validator passes.** `bash .claude/skills/skill/scripts/validate.sh .claude/skills/product` exits 0 (spec 033 compliance — non-skippable).
- [ ] 16. **F1-F9 matrix self-audit.** Re-read the edited `SKILL.md` / briefs / checklist / templates; confirm each flaw F1-F9 traces to a concrete edit and the `spec.md` static-fact criteria all hold (no surviving screen-writer brief, Phase 5 prints umbrella path, template resynced, `@theme` emitted, etc).
- [ ] 17. **`/product` smoke run.** Run `/product` on a small idea (`--stack=next`); verify `spec.md` § Acceptance scenarios: (1) ends at `screen-atlas.md` + hi-fi mood + lo-fi mood, no `app/**/page.tsx`; (2) an umbrella spec + child #1 are scaffolded under `docs/specs/`; (3) the hi-fi mood uses `<style>`+`@media`, reflows at 375 px; (4) the component-library child #2 derives from `components.md`; (5) `docs/fixture-spec.md` exists and is internally coherent.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._
