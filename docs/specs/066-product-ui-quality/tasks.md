# 066 — product-ui-quality — tasks

_Generated from `plan.md` on 2026-05-20. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Intervention 4 — token bridge (enabler; do first)

- [ ] 1. **Step 14 design-system brief — emit `@theme` block.** In `references/delegation-briefs.md`, extend the Step 14 brief so the produced `tokens.css` registers tokens under a Tailwind v4 `@theme` block (not only `:root` vars), so screen-writers get real utilities (`bg-primary`, `md:flex-row`). DONE: brief text mandates the `@theme` block + names the fallback `bg-[var(--token)]` idiom. (F2 enabler)

### Intervention 1 — brief edits

- [ ] 2. **Screen-writer brief CONSTRAINTS — mobile-first Tailwind mandate.** In the Next.js screen-writer brief (`delegation-briefs.md` ~442-511): add a CONSTRAINT requiring mobile-first responsive layout via Tailwind utility classes with breakpoint prefixes (`sm:`/`md:`/`lg:`), designed at 375 px first; replace the `delegation-briefs.md:468` line ("`var()` inline OR Tailwind") with a Tailwind-only mandate that forbids inline `style={{}}` for layout/positioning/sizing — inline `style` permitted only for genuinely runtime-dynamic values (computed bar height, % width). (F1, F2)
- [ ] 3. **Screen-writer brief — `_components/` import mandate.** Replace the `delegation-briefs.md:467` line ("extract to `_components/` if needed") with a mandate: import shared primitives from `app/_components/` (built by the component-builder dispatch); do NOT re-implement Card/Button/Input/etc. inline. (F5 consumer side)
- [ ] 4. **Screen-writer brief DONE_WHEN — responsive + import self-checks.** Add to the brief's DONE_WHEN: an inline mobile-first checklist (no fixed pixel widths on layout containers; breakpoint prefixes present; no inline layout `style`) and a "primitives imported from `app/_components/`, not redefined" check. (F1, F5)
- [ ] 5. **Atlas brief — responsive chrome + single wordmark.** In the Step 15a atlas brief: the route-group layout(s) it writes MUST be responsive (sidebar collapses to a drawer / bottom-nav below `md:`); the brand wordmark renders exactly once; no unfilled placeholder comments left in `layout.tsx`. (F4)
- [ ] 6. **Step 02 mood brief + Expo brief — mobile-first.** Add a mobile-first note to the Step 02 lo-fi mood brief; confirm the Expo screen-writer brief (`delegation-briefs.md:513-515`) inherits the responsive mandate via NativeWind, or explicitly scope Expo out with a one-line note. (F1)

### Intervention 2 — component-builder dispatch

- [ ] 7. **New component-builder brief.** Add a new 5-field brief § to `delegation-briefs.md` (before the screen-writer brief): a sub-agent reads `components.md` + `tokens.css` + `brand-book.md` and writes the shared `app/_components/*.tsx` set — responsive, Tailwind-styled, one component per `components.md` entry. (F5)
- [ ] 8. **SKILL.md Phase 4 — insert component-builder dispatch.** In `SKILL.md` Phase 4 Step 15, sequence the component-builder dispatch between atlas (15a) and the screen-writer fan-out (15b): atlas → component-builder → screen-writers. Update the step prose + any `.state.json` step accounting. (F5)

### Intervention 3 — visual gate + chrome validation

- [ ] 9. **SKILL.md Phase 4 — post-atlas chrome-validation check.** Add a parent-side orchestrator check after the atlas returns: grep `app/(<chrome>)/layout.tsx` for wordmark-string count > 1 and for unfilled placeholder comments; flag defects before the screen-writer fan-out. (F4)
- [ ] 10. **SKILL.md Phase 4 — Playwright visual gate.** Add to build-verification: render each representative route at 375 px and 1280 px via Playwright MCP, screenshot, run a `document.documentElement.scrollWidth > clientWidth` overflow check via `browser_evaluate`. **Advisory** — records in `REPORT.md`, never fails the run. **Best-effort** — if `mcp__playwright__*` tools are absent, skip with a `visual-gate-skipped` advisory; document the enable-`.mcp.json`-then-restart flow. (F3)
- [ ] 11. **report.md.tmpl — `## Visual check` section.** Add a `## Visual check` section to `templates/report.md.tmpl`: one row per route × viewport (screenshot path, horizontal-overflow result), plus a skipped-gate note. (F3)
- [ ] 12. **quality-checklist.md — responsive + component-reuse criteria.** Add a responsive/visual gate row and a component-reuse criterion to `references/quality-checklist.md` (currently 100 % static checks). (F1, F3, F5)

### Intervention 4 — supporting docs

- [ ] 13. **pipeline-coverage.md — document the component-builder sub-step.** Add the component-builder sub-step to `references/pipeline-coverage.md`; note the F6 budget interaction (Tailwind utilities + shared components shrink screen files — the 8-18 KB Step 15 target should hold without inline-style bloat). (F5, F6)
- [ ] 14. **Resync the Step 15 template.** Rewrite `templates/pipeline/15-screen-atlas/prompt.md` + `references/*.md` to match the live 15-step pipeline — remove every pre-spec-045 reference (`step 8 PRD`, `step 5 brand-book`, `step 6 design-system`, `prototype-v3`, `.html` screen output). (F8)

## Verification

_Acceptance checks tied to `spec.md` § Acceptance criteria._

- [ ] 15. **Skill validator passes.** `bash .claude/skills/skill/scripts/validate.sh .claude/skills/product` exits 0 (spec 033 compliance — non-skippable per `SKILL.md` § Notes).
- [ ] 16. **F1-F8 matrix self-audit.** Re-read the edited briefs / `SKILL.md` / `quality-checklist.md`; confirm each flaw F1-F6 + F8 traces to a concrete edit and F7 is referenced-only. Maps to `spec.md` static-fact criteria (screen-writer brief, quality-checklist, template resync).
- [ ] 17. **`/product` smoke run.** Run `/product` on a small idea (≤8 routes, `--stack=next`); verify `spec.md` § Acceptance scenarios: (1) a representative screen reflows cleanly at 375 px and holds at 1280 px; (2) `REPORT.md § Visual check` is populated; (3) `app/_components/` exists and screens import from it; (4) no duplicated wordmark in the chrome. (Full mei-saas 36-route re-run is the founder's call — not required to close this spec.)

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._
