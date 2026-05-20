# 066 — product-ui-quality — plan

_Drafted from `spec.md` on 2026-05-20. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

The eight flaws funnel into **four intervention points** in the `/product` skill — all are prose/config edits to the skill's own briefs, checklist, and templates; no new runtime code except the visual-gate invocation, which reuses the Playwright MCP already in the harness.

1. **Screen-writer + atlas brief edits (F1, F2, F4, F5 consumer side).** The Next.js screen-writer brief in `delegation-briefs.md` is the highest-leverage edit: it must (a) mandate mobile-first responsive layout via Tailwind v4 utility classes with breakpoint prefixes (`sm:`/`md:`/`lg:`), (b) forbid inline `style={{}}` for layout/positioning/sizing — the mechanical root of F1, since a React inline-style object cannot hold an `@media` query — narrowing inline `style` to genuinely runtime-dynamic values only (a computed bar height, a percentage width), (c) replace "extract to `_components/` if needed" with "import shared primitives from `app/_components/` — do NOT re-implement". The atlas brief gains: the route-group layout MUST be responsive (sidebar collapses to a drawer/bottom-nav below `md:`) and render the brand wordmark exactly once.

2. **New component-builder dispatch (F5).** Insert a sub-step between the atlas (15a) and the screen-writer fan-out (15b): one sub-agent reads `components.md` + `tokens.css` + `brand-book.md` and writes the shared `app/_components/*.tsx` set. Screen-writers then import, not re-derive. This also reduces F7 cascade pressure — fewer interdependent files written concurrently.

3. **Phase 4 visual gate (F3) — advisory.** Phase 4 build-verification gains a Playwright pass: render each representative route at 375 px and 1280 px, screenshot, and run a mechanical `document.documentElement.scrollWidth > clientWidth` overflow check via `browser_evaluate` (a real pass/fail signal, not just a screenshot). Results land in `REPORT.md § Visual check`. **Advisory** per the resolved open question — never fails the run; **best-effort** — if `mcp__playwright__*` tools are absent (MCP not enabled, or same session that wrote `.mcp.json`), the gate skips with a `visual-gate-skipped` advisory. A parallel lightweight parent-side grep check after the atlas returns catches F4 chrome defects (wordmark count > 1, unfilled placeholder comments) without needing a browser.

4. **Doc resync + token bridge (F8, F2 enabler).** `templates/pipeline/15-screen-atlas/` is rewritten to match the live 15-step pipeline. Step 14's design-system brief is extended to emit the tokens as a Tailwind v4 `@theme` block so screen-writers get clean `bg-primary md:flex-row` utilities instead of arbitrary-value `bg-[var(--primary)]` noise.

Order of work: brief edits first (cheapest, highest impact, independently testable by re-reading the brief), then the component-builder dispatch, then the visual gate, then the doc resync. F6 (bloat) needs no dedicated edit — it falls out of F2 (utility classes are terse) + F5 (shared components). F7 stays referenced-only.

## Files to touch

**Modify:**
- `.claude/skills/product/references/delegation-briefs.md` — Next.js screen-writer brief (~442-511): mobile-first responsive CONSTRAINT; Tailwind-only mandate replacing the `var()`-inline-OR-Tailwind line; `_components/` import mandate; responsive + import self-checks in DONE_WHEN. Atlas brief (Step 15a): responsive route-group layout + wordmark-exactly-once. Step 14 design-system brief: emit a Tailwind v4 `@theme` token block. Step 02 mood brief: mobile-first note.
- `.claude/skills/product/references/delegation-briefs.md` — **new § component-builder brief** (5-field) inserted before the screen-writer brief.
- `.claude/skills/product/SKILL.md` — Phase 4 Step 15: insert the component-builder dispatch between 15a (atlas) and 15b (screen-writers); add the post-atlas chrome-validation check; add the Playwright visual gate to build-verification.
- `.claude/skills/product/references/quality-checklist.md` — add a responsive/visual gate row + a component-reuse criterion (currently 100 % static).
- `.claude/skills/product/references/pipeline-coverage.md` — document the component-builder sub-step; note the F6 budget interaction.
- `.claude/skills/product/templates/report.md.tmpl` — add `## Visual check` (per route × viewport: screenshot path, horizontal-overflow result).
- `.claude/skills/product/templates/pipeline/15-screen-atlas/prompt.md` + `references/*.md` — resync with the live 15-step pipeline (drop `step 8 PRD`, `step 5 brand-book`, `prototype-v3`, `.html` output references).

**Create:**
- No new files. The mobile-first checklist is inlined in the screen-writer brief (same precedent as the Biome anti-pattern checklist already inlined there — React-specific, should not propagate to non-JS forks via a generic rule).

**Delete:**
- None. F8 is a resync, not a removal.

## Alternatives considered

### Visual gate as a hard block (fail the run on overflow)

Rejected. The resolved open question chose advisory for v1, and there is a hard technical reason beyond posture: the Playwright MCP requires `.mcp.json` + a session restart to become available (observed in the mei-saas transcript). A hard block would brick every run where MCP is not yet enabled. Advisory + skip-with-advisory degrades gracefully; promotion to a block is a v2 decision once MCP availability is reliable.

### Ship a pre-built component library in the skeleton

Rejected. A generic `Button`/`Card`/`Input` set baked into `templates/monorepo-skeleton/next/` would fight the per-product design system — each run's `components.md` + `tokens.css` + brand voice are product-specific. The per-run component-builder dispatch (reads *this* run's design-system artifacts) is correct; a shipped set would be overwritten or ignored.

### "Be responsive" as a soft instruction, without forbidding inline layout styles

Rejected. This is effectively the status quo (the brief is silent, screen-writers default to inline). The inline-`style={{}}` permission is the *mechanical* blocker — an inline style object physically cannot express a media query. Without forbidding inline styles for layout, "be responsive" is unenforceable regardless of how emphatically it is stated.

### A separate "Step 16 — visual QA"

Rejected. Phase 4 already performs post-generation build verification (install / tsc / biome / dev-server smoke-test). The visual gate is the same class of check; a new pipeline step adds state-machine + `.state.json` complexity for no benefit.

## Risks and unknowns

- **Playwright MCP availability.** The visual gate is best-effort; the same session that writes `.mcp.json` cannot use it (needs restart). Mitigation: skip-with-advisory; document the enable-then-restart flow in the SKILL.md Phase 4 text.
- **Tailwind v4 `@theme` bridge.** If Step 14's `tokens.css` is not `@theme`-shaped, `bg-primary`-style utilities will not resolve. Mitigation: extend the Step 14 brief to emit the `@theme` block; fallback idiom `bg-[var(--token)]` documented in the screen-writer brief.
- **Component-builder adds a third serial stage** (atlas → components → screens). Likely net-neutral-to-positive on wall-time (screen-writers do less, cascade pressure drops) but unverified until a real run.
- **`delegation-briefs.md` is 63 KB** with many sibling briefs — edits must be surgical and consistent across the doc.
- **Re-validation cost.** The acceptance criterion "fresh run reproduces none of F1-F8" implies a full `/product` re-run (~90-120 min, heavy tokens). Mitigation: verify with a small smoke idea (≤8 routes) rather than re-running the full mei-saas 36-route build; the mei-saas re-run is the founder's call.
- **Expo parity.** The Expo screen-writer brief (`delegation-briefs.md:513-515`) inherits the Next.js brief by reference; NativeWind is already mobile-first. Confirm the responsive mandate carries over or is explicitly scoped out (non-goal).

## Research / citations

- [Tailwind CSS v4 — Theme variables](https://tailwindcss.com/docs/theme) and [Tailwind CSS v4.0 release](https://tailwindcss.com/blog/tailwindcss-v4) — `@theme` directive is the CSS-first token mechanism; v4 keeps the mobile-first breakpoint-prefix model (`sm:`/`md:`/`lg:`).
- [Design Tokens That Scale in 2026 (Tailwind v4 + CSS Variables) — Mavik Labs](https://www.maviklabs.com/blog/design-tokens-tailwind-v4-2026/) — `@theme` as the single source of truth bridging tokens → utilities.
- [Playwright Visual Testing — Codoid](https://codoid.com/automation-testing/playwright-visual-testing-a-comprehensive-guide-to-ui-regression/) and [Visual Regression for Small & Medium Screens](https://sergeipetrukhin.vercel.app/playwright-visual-small-screens) — multi-viewport via viewport sizing / device descriptors; scrollbar-induced horizontal shift is a detectable layout-failure signal.
- mei-saas dogfood evidence — `spec.md § Context` flaw matrix F1-F8.
- `.claude/skills/product/` — `SKILL.md`, `references/delegation-briefs.md`, `references/quality-checklist.md`, `templates/pipeline/15-screen-atlas/`.
