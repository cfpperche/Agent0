# 126 — site-refactor — plan

_Drafted from `spec.md` on 2026-05-30. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Phased, in-place, content-first — the phase order *is* the spec's phase gate, not a convenience. The refactor lands the developer-facing OSS-landing thesis in five passes, all kept in lockstep across the three content locales (`/en/`, `/pt/`, `/es/`):

- **Phase 0 — baseline + audit (no user-visible change).** Capture the reproducible quality baseline named in the acceptance scenario (Lighthouse/meta/a11y for the three locale URLs, with tool/command/viewport/thresholds) into a tracked artifact, and audit the *real* capacity/MCP inventory against the repo — the copy claims "Eighteen capacities", `capacities.ts` holds ~14, and the repo actually ships 20+ (per `CLAUDE.md`), so the number is stale in both directions. Phase 0 produces the truth table the copy will use.
- **Phase 1 — content/positioning (THE GATE).** Rewrite `strings.ts` + `capacities.ts` + `mcps.ts` for the developer audience: sharpen the governance/discipline value story, replace the hardcoded "Eighteen" with the audited current count (or a non-numeric framing that can't re-stale), and make the inventory multi-runtime-true (Claude Code **and** Codex CLI, per spec 121 — today's copy is Claude-only). "Harness" framing stays. **This phase's copy architecture must be approved before Phase 2 starts.**
- **Phase 2 — visual/brand.** Extend the existing `@theme` token seed in `global.css` into a coherent, reusable design system; modernize the component visuals. Subordinate to the approved Phase 1 copy.
- **Phase 3 — architecture/code.** Component/IA restructure as the new narrative requires (in scope per spec); keep the locale-driven `STRINGS[locale]` data flow.
- **Phase 4 — perf/SEO/a11y guardrail.** Resolve the `og:image` gap (add asset + tags) and the missing `twitter:title`/`twitter:description`, then re-run the Phase 0 baseline and assert equal-or-better; check contrast/semantics. Final: `bun run build` green.

## Files to touch

**Create:**
- `docs/specs/126-site-refactor/baseline.md` (or a `notes.md` block) — the Phase 0 reproducible baseline artifact (URLs, tool/command, viewport, thresholds, current metrics).
- `site/public/og-image.*` — the missing Open Graph image asset (Phase 4); tier/source decided with the visual/brand OQ.

**Modify:**
- `site/src/i18n/strings.ts` — core copy rewrite (hero dev-value, kill "Eighteen capacities", section copy) across en/pt/es.
- `site/src/i18n/capacities.ts` — sync inventory to the audited real set; add multi-runtime truth; fix stale entries.
- `site/src/i18n/mcps.ts` — currency pass on the MCP list.
- `site/src/layouts/Landing.astro` — add `og:image`, `twitter:title`, `twitter:description`; verify hreflang/canonical; possibly section reordering (Phase 3).
- `site/src/styles/global.css` — extend `@theme` tokens into the design system (Phase 2).
- `site/src/components/*.astro` — `Hero`, `CapacityGrid`, `McpGrid`, `WhyBuilt`, `QuickStart`, `HowToExtend`, `Faq`, `Header`, `Footer` — visual + structural refactor (Phases 2–3), preserving the dev-oriented CTAs.

**Delete:**
- None expected (in-place). If IA restructure merges/splits sections, component deletions happen in Phase 3 with the rename recorded here.

## Alternatives considered

### Rebuild `site/` from scratch (possibly new stack)
Rejected — the user explicitly chose in-place evolution; a rebuild discards a working Astro 5 + Tailwind 4 + 3-locale build for no gain the thesis needs, and violates the no-shipped-stack-opinions discipline. The existing `@theme` tokens + i18n data flow are assets, not debt.

### Outcome-led consultancy positioning (the original premise)
Rejected — the Claude×Codex debate resolved site identity as the OSS-project developer landing; "lead with business outcomes / demote the harness" is now an explicit non-goal. Building it would serve a visitor this surface doesn't have.

### Content-only refresh (skip visual + architecture)
Rejected — the user scoped all four axes as a "complete" refactor. Content-first *sequencing* (the phase gate) satisfies the "don't build visual on an unresolved premise" concern without dropping the visual/architecture axes.

## Risks and unknowns

- **Inventory re-staling.** A hardcoded count went stale once (18 vs ~14 vs 20+); hardcoding a new number repeats the failure. Unknown: derive the count/list from the repo at build time, or accept a dated snapshot + a maintenance note? Decide in Phase 0/1. (Auto-generation is heavier scope — flag before adding.)
- **Baseline tooling availability.** The acceptance scenario needs a runnable Lighthouse/audit command; unknown whether it's installed locally or needs `npx`/PageSpeed. Resolve in Phase 0 so the baseline is actually reproducible, not aspirational.
- **`og:image` asset dependency.** Phase 4 needs a real image; ties to the unresolved visual/brand source-of-truth OQ — could block the SEO guardrail if visual direction stalls.
- **Multi-runtime truth churn.** Copy must reflect Claude Code + Codex CLI (spec 121); the runtime matrix may evolve, so phrasing should avoid runtime-specific magic numbers too.
- **Assumption:** the three locales stay copy-parity; if pt/es translations lag the en rewrite, the "no untranslated fallback" scenario fails — translation is part of each phase, not a trailing task.

## Research / citations

- `docs/specs/126-site-refactor/debate.md` — Claude×Codex debate; resolved gate + converged synthesis (the source of the thesis).
- `docs/specs/024-public-landing/` — originating spec; the OSS-landing historical contract.
- Code read at plan time: `site/src/layouts/Landing.astro` (meta/OG gaps — no `og:image`, `twitter:card` only), `site/src/i18n/capacities.ts` (~14 entries), `site/src/i18n/strings.ts` ("Eighteen capacities" stale copy, Claude-only framing), `site/src/styles/global.css` (`@theme` token seed).
- `CLAUDE.md` — the real, current capacity list (20+; multi-runtime) that the inventory audit reconciles against.
- Memory: `feedback_no_shipped_stack_opinions`, `feedback_bio_framing`, `feedback_consultancy_positioning` (scope-clarified to NOT apply here), `feedback_speculative_observability`.
