# 052 — product-skill-shared-shell

_Created 2026-05-18._

**Status:** shipped

## Intent

Three coupled fixes for the structural defects that the 2026-05-18 visual audit caught and that spec 051 only addressed the symptoms of. Spec 051 patched the leaking `PROTOTYPE_SLUG` + the async/'use client' bug — bandaids. The deeper findings (#3 chrome inconsistency, #4 dev-mode chips bleeding into product surface, #5 the verification gap that let both ship) are *systemic*: every screen-writer sub-agent invents its own shell, none of them stop to ask whether mode-toggles belong in production, and the orchestrator never opens the running app. This spec installs the structural guardrails so the next `/product` run cannot reproduce these failure shapes.

**Fix A — Route-group chrome.** Stop telling sub-agents to "remember to import `<AppShell>`" — that's the failure shape. Use Next.js 16's *route groups* (folder-name in parens, organisational-only, doesn't affect URLs) to make shared chrome *implicit via routing*. Sitemap categories `primary` + `admin` route under `app/(app)/` which carries `app/(app)/layout.tsx` (sidebar + topbar shared across Dashboard / Agenda / Caixa / Comissões / NFS-e / Estoque / Configurações). `marketing` / `auth` / `booking` stay flat — their pages opt out by living outside the `(app)` group. The atlas sub-agent writes `app/(app)/layout.tsx` (and optionally `app/(marketing)/layout.tsx`) ONCE, before per-route screen-writers dispatch. Sub-agents then write into the prescribed group; the chrome is inherited via Next's nested-layout cascade — there is no chrome contract for them to break.

**Fix B — Idiomatic states pattern.** Sub-agents currently embed `default / loading / empty / error` *chips* inline in production page bodies (anti-pattern — bleeds dev-mode UI into product surface; audit caught it on Dashboard + Agenda). Next.js 16 already has the right primitives: `loading.tsx` / `error.tsx` / `not-found.tsx` are *sibling files* to `page.tsx`; the framework wires them into Suspense + ErrorBoundary at the segment level. The brief's CONSTRAINTS forbid inline state-toggle chips and require sibling state files when sitemap declares the states. Empty state is part of the page's actual rendering logic (data-driven branch), not a developer toggle.

**Fix C — Phase 4 dev-server smoke-test.** The verification gap is the meta-bug: tsc + biome don't catch runtime errors, and nobody opened the dev server before declaring spec 048's dogfood "shipped". Adding a `pnpm dev` background warmup + HTTP-200 probe of 1 representative route per sitemap category to Phase 4 build verification closes the loop. The smoke-test takes ~45s wall-clock; the alternative is shipping spec-051-class bugs every time.

Out of scope: per-stack refactor of existing skeleton (Expo doesn't have route groups in the same sense — its `app/_layout.tsx` is the cascade); scope stays Next.js-first. Validator extension to grep for inline chip patterns deferred.

## Acceptance criteria

### A. Route-group chrome

- [ ] **Static fact:** `.claude/skills/product/references/delegation-briefs.md` § Step 15 (atlas) brief mandates the atlas write `app/(app)/layout.tsx` containing the shared sidebar + topbar before per-route screen-writers dispatch
- [ ] **Static fact:** `.claude/skills/product/references/delegation-briefs.md` § Per-stack screen-writer § Next.js stack declares the category→route-group mapping: `primary` + `admin` → `app/(app)/<route>/page.tsx`; `marketing` + `auth` + `booking` → flat `app/<route>/page.tsx`; `error` covered by Next.js convention (`app/not-found.tsx`, `app/error.tsx` at root)
- [ ] **Static fact:** `.claude/skills/product/SKILL.md` Phase 4 step 2 (per-route screen-writers) dispatches AFTER the atlas Sub-agent (a) has returned its layout files — sequence is explicit (atlas first, then route-writers fan-out)
- [ ] **Static fact:** The atlas brief's DONE_WHEN mentions: `app/(app)/layout.tsx` exists; contains the shared sidebar nav matching the sitemap's `primary`+`admin` categories; uses tokens via `var(--color-*)` (NO hex/px); no `'use client'` directive at top (layouts can stay Server Components even with interactive children)

### B. Idiomatic states pattern

- [ ] **Static fact:** `.claude/skills/product/references/delegation-briefs.md` § Per-stack screen-writer § Next.js stack adds CONSTRAINTS bullet banning inline `default | loading | empty | error` state-toggle chips in production page bodies
- [ ] **Static fact:** The same bullet prescribes the Next.js sibling-file convention: when the sitemap entry's `states` field declares `loading` → emit `<route>/loading.tsx`; declares `error` → emit `<route>/error.tsx`; declares `404` → emit `<route>/not-found.tsx`; empty state is page-internal rendering logic (data-driven branch), NOT a toggle
- [ ] **Static fact:** The skeleton template `.claude/skills/product/templates/monorepo-skeleton/next/app/` ships root-level `loading.tsx` + `error.tsx` + `not-found.tsx` as minimal defaults (each ≤30 LOC, tokens-only, no hex/px) so every route inherits a baseline state UX even when the screen-writer doesn't override

### C. Phase 4 dev-server smoke-test

- [ ] **Static fact:** `.claude/skills/product/SKILL.md` Phase 4 step 4 (build verification) is extended with a documented smoke-test subroutine: start `pnpm dev` on a probe port (default `--port 3099`) in background; wait until the dev server logs "Ready"; HTTP-probe ONE representative route per sitemap category (picked by the orchestrator from the routes list); kill the dev server cleanly when done
- [ ] **Static fact:** Each probed route MUST return HTTP 200; if any returns ≥400 OR the response body contains the Next.js dev error overlay marker (substring `__next-dev-overlay-error` OR `nextjs__container_errors`), the smoke-test is marked failed
- [ ] **Static fact:** Smoke-test result captured in `<out>/docs/REPORT.md` § "Build health" — new subsection `## Dev-server smoke-test` with one row per probed route showing HTTP status + ms latency
- [ ] **Static fact:** Smoke-test failure does NOT abort the run (same posture as tsc / biome failures per spec 045 — record + continue) BUT the REPORT highlights failed routes in a way the founder cannot miss (✗ marker + explicit `## Action required` note when any failed)
- [ ] **Scenario: smoke-test catches the spec-051 bug shape**
  - **Given** a hypothetical sub-agent regression that re-introduces `'use client'` + `async function Page` on a dynamic-segment route
  - **When** Phase 4 smoke-test probes that route
  - **Then** dev server responds 500 (Next.js runtime error renders the overlay), smoke-test marks the route ✗, REPORT.md `## Action required` block surfaces the failing route + suggests cross-checking the brief

### D. Skill compliance preserved

- [ ] **Static fact:** `bash .claude/skills/skill/scripts/validate.sh .claude/skills/product` exits 0 (no regression vs spec 048/049/051 gates)
- [ ] **Static fact:** SKILL.md description still ≤1024 chars; SKILL.md body still under the agentskills.io 5000-token recommendation (this spec adds ~200 tokens to Phase 4; previous specs' size discipline preserved)

## Non-goals

- **Retro-fixing the /tmp/dogfood-erp/ instance.** Spec 051 retro-fixed the bugs it patched; for spec 052, the structural changes (move 24 routes into `app/(app)/`, write the shared layout, emit 24 sibling state files) are more surgery than validation justifies. Skill changes alone — next `/product` run is the real cross-check.
- **Expo stack route-group equivalent.** Expo Router uses `app/_layout.tsx` for the cascade and lacks the `(group)` URL-eliding convention. Cross-stack convergence is a separate spec — for now, Phase A is Next.js-only and the Expo brief documents that the route-group concept doesn't apply.
- **Validator extension to grep for inline chip patterns** (`useState<"default" | "loading" | ...>`-style toggles in page bodies). Brief CONSTRAINTS is the v1 fix; validator becomes a candidate if sub-agents ignore the brief in future dogfoods.
- **Storybook integration** for state showcase. Sibling `loading.tsx`/`error.tsx` IS the Next.js-native showcase mechanism; reaching for Storybook is over-engineering for the prototype tier.
- **Smoke-test extension to crawl all sitemap routes** (not just 1 per category). Wall-clock + flakiness cost grows linearly; one per category catches structural breakage; full crawl is a separate concern (and the existing Phase 4 tsc already touches every file).
- **Performance probing in the smoke-test** (Lighthouse / Core Web Vitals). Out of scope — perf is a `/sdd` post-handoff concern.
- **Authentication-real dev-server probe.** Probed routes are public per Next.js dev defaults; if the prototype implements gates, smoke-test sees the public landing — that's fine for v1.

## Open questions

None — the three fixes are well-shaped; choices are documented inline.

## Dependencies + cross-references

- **Spec 048 (shipped 2026-05-18)** — skill foundation; Phase 4 stitch step is the surface this spec extends with substep 4-c (smoke-test) and substep 2 (atlas-first sequence).
- **Spec 049 (shipped 2026-05-18)** — OD vendor port; independent.
- **Spec 051 (shipped 2026-05-18)** — symptomatic patches; this spec is the structural follow-on the 051 lineage note flagged. Spec 051's Non-goals explicitly named these three deferrals.
- **Audit narrative (conversation 2026-05-18)** — findings #3 (chrome inconsistency) + #4 (dev-toggle chips) + #5 (verification gap) are this spec's intent surface.

## Lineage

- 2026-05-18 visual audit of spec-048 dogfood at `/tmp/dogfood-erp/` surfaced 4 distinct defect classes; spec 051 took 2 (PROTOTYPE_SLUG placeholder + async/client bug); spec 052 takes the remaining 3 (chrome, states-as-chips, dev-server smoke-test gap).
- Next.js 16 idioms confirmed via official docs ([Route Groups](https://nextjs.org/docs/app/api-reference/file-conventions/route-groups), [loading.js](https://nextjs.org/docs/app/api-reference/file-conventions/loading), [error.js](https://nextjs.org/docs/app/api-reference/file-conventions/error), [not-found.js](https://nextjs.org/docs/app/api-reference/file-conventions/not-found)) — using framework-native conventions instead of inventing skill-side abstractions.
- Lesson from spec 051: "skill defaults the agent didn't know to question" is the recurring failure shape. Spec 052 institutionalises the corrective by making the *structure* carry the discipline (route groups make chrome inheritable; sibling files make states a framework concept; smoke-test catches regression).
