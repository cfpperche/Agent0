# 126 — site-refactor — notes

_Created 2026-05-30._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.agent0/context/rules/spec-driven.md` § The four artifacts for purpose, and `.agent0/context/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-05-30 — parent — Phase 0 inventory audit + derive-count decision

**Audit (truth table).** `capacities.ts` shipped **14** entries; the hero copy claims "Eighteen"; `CLAUDE.md` lists **20** top-level capacity sections. Resolution:
- **Keep** (real capacities, not all top-level CLAUDE.md `##`): `governance` (spec 001 rule), `reminders` (skill), `bdd` (acceptance-scenario practice).
- **Add the 9 missing** that the repo ships now: `vuln-audit`, `image-gen`, `skill-compliance`, `product`, `routines`, `artifact-size-cap`, `user-prompt-framing`, `runtime-capabilities`, `runtime-entrypoints`.
- Net post-audit set ≈ 23.

**Derive-count decision (plan Risk: inventory re-staling).** A hardcoded word ("Eighteen") went stale once; hardcoding "Twenty-three" repeats the failure. Decision: the displayed count **derives from `CAPACITIES.length`** at render time — the copy can never disagree with the data again. The `whatYouGet` string drops the hardcoded number; the component interpolates the length. (Build-time *generation* of the whole list from the repo was rejected as heavier scope per the plan — the array stays hand-curated, only the *count* is derived.)

**Multi-runtime truth (Codex R2 #2).** Current copy is Claude-Code-only; spec 121 made the harness multi-runtime (Claude Code + Codex CLI). Capacity descriptions and the hero/why copy must stop saying "for Claude Code" exclusively and reflect both runtimes.

**Baseline.** Captured in `baseline.md`; Lighthouse perf deferred (Chrome won't connect in this WSL session) — static SEO/meta/a11y/bundle baseline recorded, `og:image`/`twitter:title|description` confirmed absent (Phase 4 targets).

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

### 2026-05-30 — parent — Phases 2–4: conservative visual scope; root-redirect + og:image fixes

**Visual axis (Phase 2) delivered conservatively, on purpose.** The acceptance criterion is "coherent, reusable design system (tokens/components), not ad-hoc" — the existing `@theme` token system in `global.css` already satisfies this (every component consumes `var(--color-*)`; verified by a rendered screenshot). The spec's OQ5 (visual/brand source of truth) explicitly defers *bold* visual direction to the user at plan time, so a speculative full redesign of a clean, working site would have been reckless and out of mandate. The one visual change made is additive and low-risk: a subtle masked grid-accent in the hero that ties the page to the new `og-image` (same visual language). A larger redesign remains available as a follow-on once OQ5 is answered.

**IA (Phase 3) — no restructure.** Task 10 was conditional ("as the new narrative requires"). The dev-OSS-landing narrative is served by the existing section order (Hero → Capacities → MCPs → Why → QuickStart → Extend → FAQ); restructuring working sections without a driving need would add regression risk for no gain. In-scope, not required, not done.

**og:image (Phase 4) generated, not stubbed.** Authored an on-brand 1200×630 OG card (HTML) and rendered it to a real PNG via headless `google-chrome --screenshot` (Lighthouse's protocol couldn't connect in WSL, but the one-shot screenshot path works). Committed at `site/public/og-image.png`; `Landing.astro` now emits `og:image` + dimensions + `twitter:title`/`twitter:description`/`twitter:image`.

**Root redirect (bonus fix).** `astro.config.mjs` had `i18n.routing.redirectToDefaultLocale: true`, which auto-generated a **2-second** meta-refresh root page that overrode the hand-written `src/pages/index.astro`. Set it to `false` so the instant redirect (JS `location.replace` + 0s meta-refresh + canonical) takes effect — eliminates the 2s blank intermediate.

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — options considered in-flight, chosen path, accepted cost}}

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — the question, why it surfaced, what's blocked on it, who can decide}}
