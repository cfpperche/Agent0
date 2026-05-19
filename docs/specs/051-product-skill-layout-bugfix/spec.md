# 051 — product-skill-layout-bugfix

_Created 2026-05-18._

**Status:** shipped

## Intent

Two real-runtime bugs surfaced by the 2026-05-18 visual audit of the spec-048 dogfood at `/tmp/dogfood-erp/`. The dogfood claimed "tsc + biome clean" but nobody opened the running app — static type-check is not feature-check (CLAUDE.md § "For UI or frontend changes" rule). Both bugs are mechanical and ship-blocking for a real founder demo.

**Bug 1 — `<title>PROTOTYPE_SLUG`** literal on every tab + `<html lang="en">` on a PT-BR product. The skeleton template at `.claude/skills/product/templates/monorepo-skeleton/next/app/layout.tsx` ships a marker `title: "PROTOTYPE_SLUG"` and a hardcoded `lang="en"`. The skill's Phase 4 stitch step verifies the token import (`@import "../docs/design-system/tokens.css"`) but never substitutes the title placeholder and never adjusts the lang attribute. Result: every prototype ships with a leaked placeholder in the browser tab and the wrong language declaration for SEO + screen readers + browser locale handling.

**Bug 2 — Async + `'use client'` mismatch** on dynamic-segment pages (`/check-in/[id]`, `/prontuario/[id]`, `/booking/[slug]`). Sub-agents put `'use client'` at top of file AND made the page default-export an `async` function (Next.js 16 `params: Promise<{...}>` pattern). Next.js explicitly blocks this combination — runtime error: `<X>Page is an async Client Component. Only Server Components can be async at the moment.` The per-stack screen-writer brief at `.claude/skills/product/references/delegation-briefs.md` § Per-stack screen-writer never mentions the Server-async wrapper + sibling-Client-component pattern, so sub-agents reach for `'use client'` as a habit when they see state/event handlers in the page, breaking the runtime even though tsc passes.

Both bugs are skill-template + skill-brief defects. Fix the skill once → every future `/product` run inherits the correct shape. The /tmp/dogfood-erp/ instance gets a retro-fix to validate the fix patterns end-to-end (dev server clean, console error count = 0, title renders correctly).

Scope kept tight: bugs (3) and (4) from the audit (shared chrome contract + state-toggle dev chips bleeding into production) are deferred to a follow-on spec because they require structural choices (shared `<AppShell>` contract, `_states/` convention) — out of scope here.

## Acceptance criteria

### A. Skill Phase 4 stitch — layout placeholder substitution

- [ ] **Static fact:** `.claude/skills/product/SKILL.md` Phase 4 has a documented stitch substep (after token-import verification, before build verification) that substitutes `PROTOTYPE_SLUG` in `<out>/app/layout.tsx` with a resolved title and adjusts `lang="en"` to `lang="pt-BR"` when the brief is Brazilian
- [ ] **Static fact:** Title resolution priority is documented as: (a) brand-book.md `## Product Name` section if present, (b) fallback to the literal `<idea>` string from `.state.json`
- [ ] **Static fact:** Lang detection heuristic is documented as: PT-BR if any of `concept-brief.md` / `sitemap.yaml` / `brand-book.md` contains any of the literal substrings `R$` / `LGPD` / `NFS-e` / `Pix`; else keep `lang="en"`
- [ ] **Scenario: PROTOTYPE_SLUG substituted on real dogfood**
  - **Given** `/tmp/dogfood-erp/app/layout.tsx` carries `title: "PROTOTYPE_SLUG"` and `<html lang="en">`
  - **When** the operator re-runs the Phase 4 stitch step (or applies the retro-fix per Phase D)
  - **Then** the file reads `title: "ERP para salões de beleza"` and `<html lang="pt-BR">`; the browser tab on `http://localhost:3001/` shows the new title; no `PROTOTYPE_SLUG` substring remains in `<out>/app/`

### B. Per-stack screen-writer brief — async/client rule

- [ ] **Static fact:** `.claude/skills/product/references/delegation-briefs.md` § Per-stack screen-writer § Next.js stack adds a CONSTRAINTS bullet explicitly stating that `'use client'` MUST NOT appear at the top of an `async` page component
- [ ] **Static fact:** The bullet documents the canonical pattern: Server `page.tsx` (no directive, async function, awaits `params`, passes resolved values as props) + sibling `<route>/_<Name>Client.tsx` (with `'use client'`, receives props, owns hooks + state + event handlers)
- [ ] **Static fact:** The bullet names the runtime error verbatim so sub-agents can recognize it: `is an async Client Component. Only Server Components can be async at the moment`
- [ ] **Scenario: 3 retro-fixed dogfood pages clean in dev server**
  - **Given** `/tmp/dogfood-erp/app/{check-in,prontuario,booking}/[*]/page.tsx` carry both `'use client'` and `async function` (the bug shape)
  - **When** the operator applies the canonical pattern (split into Server async wrapper + sibling Client component)
  - **Then** opening `/check-in/abc123`, `/prontuario/abc123`, `/booking/lumiere-haus` in the running dev server shows the React DevTools console error count drop to 0 for these routes (HMR Fast Refresh + favicon 404 noise excluded)

### C. Skill compliance preserved

- [ ] **Static fact:** `bash .claude/skills/skill/scripts/validate.sh .claude/skills/product` exits 0 (no regression vs spec 048 gate D / spec 049 gate D)
- [ ] **Static fact:** `.claude/skills/product/SKILL.md` description still ≤1024 chars (spec 033 limit; unchanged)

## Non-goals

- **Shared chrome contract** (audit finding #3 — Sidebar/Logo/Nav-labels inconsistent across pages because each sub-agent invents its own shell). Requires structural change: shared `app/_components/AppShell.tsx`, prescribed in atlas brief + screen-writer brief. Deferred to spec 052 (or wherever) — explicitly out of scope.
- **State-toggle dev chips on production pages** (audit finding #4 — `default / loading / empty / error` chips visible on Dashboard + Agenda). Requires a `/_states/<route>/` convention or Storybook-equivalent. Deferred to the same follow-on spec.
- **Locale flag (`--locale=pt-BR`)** — first-pass detection via concept-brief content substrings is good enough; a real flag is a small follow-on if the substring heuristic produces false positives. Not in scope here.
- **Validator extension for async+'use client' incompatibility** — could grep `app/**/page.tsx` for the bug shape and emit an advisory or hard-block in the post-edit validator. Useful but bigger surface — separate spec if false-positive rate is low.
- **Favicon ship** — the audit caught a 404 on `/favicon.ico`. Cosmetic, fixable in 30 seconds by adding `app/favicon.ico` to the skeleton. Not blocking enough for this spec; will fold into the follow-on shell spec or land separately.
- **Retro-fixing every `'use client'` page** in /tmp/dogfood-erp/ that doesn't have `async` (e.g., Dashboard, Agenda, Caixa) — those work fine even with `'use client'` because they're not async. Only the 3 dynamic-segment async pages need the split.
- **Re-running the full `/product` pipeline** to validate the skill changes end-to-end. Retro-fix on the existing dogfood is the cheaper validation; full re-run can happen when the next real founder kicks off a `/product` invocation.

## Open questions

None — design straightforward; bugs mechanical; retro-fix is the validation surface.

## Dependencies + cross-references

- **Spec 048 (shipped 2026-05-18)** — created the skeleton template + Phase 4 stitch step that this spec patches. Spec 048's gate E ("dogfood ERP salões de beleza") technically passed with these bugs latent because the gate only required tsc + biome clean, not dev-server smoke-test. Lesson preserved as Risk #1 below; follow-on spec may extend Phase 4 to include a `pnpm dev` warmup smoke-test.
- **Spec 049 (shipped 2026-05-18)** — OD vendor port to skill. Independent; this spec touches different surfaces.
- **Audit narrative** — captured inline in conversation 2026-05-18 ("auditoria visual" critique); the screenshots at `/home/goat/Agent0/audit-{01..07}-*.png` are the evidence trail. Not git-tracked; conversation transcript is the audit memory.
- **Future spec 052 (candidate) — `product-skill-shared-shell`** — picks up audit findings #3 (chrome inconsistency) + #4 (dev chips bleeding) + #5 (validator dev-server smoke-test). Structural; bigger surface.

## Lineage

- Bug 1 root cause: spec 036 (v2 layout) shipped the `PROTOTYPE_SLUG` marker as the title placeholder, and the Phase 4 stitch step only ever stitched the token import — title substitution was never coded. Spec 045 (v3) inherited intact. Spec 048 (production-shaped layout) inherited intact. First time anyone opened the running app was 2026-05-18 (this audit).
- Bug 2 root cause: Next.js 16 made `params` a `Promise` (spec 045's `templates/monorepo-skeleton/next/` was scaffolded for Next.js 16.2.6 per `stack-defaults.md`). The screen-writer brief documented `await params` but assumed sub-agents knew the Server-only constraint on async. They didn't.
- Both bugs are "skill defaults the agent didn't know to question" — the fix shape is identical: tighten the skill so the next run doesn't reproduce them.
