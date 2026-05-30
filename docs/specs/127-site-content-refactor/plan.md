# 127 — site-content-refactor — plan

_Drafted from `spec.md` on 2026-05-30. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Manifest-first, then pages, then guard. The anti-restaling mechanism is built *before* the content so the content is authored against a validated source-of-truth, not after.

- **Phase A — typed manifest + currency check (the guard).** Extend the capacity model into a typed manifest carrying the structured/derivable fields (`id`, `slug`, `theme`, `runtimeStatus`, `sourcePaths[]`, `historySpec?`, `localeCoverage`). Write a build-time check (a `bun test` or a prebuild script) that fails when: a `sourcePath` doesn't exist on disk, a card's primary target is `docs/specs/00*`, a themed capacity has no explanatory route, or a resolved-locale page is missing. This guard is what makes the spec durable — it lands first and stays green throughout.
- **Phase B — content audit + fixes (single page).** Reconcile every `strings.ts`/`capacities.ts`/`mcps.ts` surface against the live repo; fix the named defects (`.claude/settings.json` → `.codex/hooks.json` for the Codex path; soften the "cannot drift out of" overclaim). Re-point card "learn more" through the resolved hierarchy (on-site page → current rule/skill → optional history link); drop/repoint stale `spec NNN` badges.
- **Phase C — grouped explanatory pages + overview (en).** ~5–6 themed pages (safety gates / spec workflow / validators / runtime & session / skills & tooling) + a "how the harness works" overview. Each capacity block states its per-runtime status from the manifest (derived) with hand-authored prose/examples. New routes under `/en/...`.
- **Phase D — route/nav/meta wiring.** Nav links to the new pages; language switch degrades gracefully for the en-only routes (pt/es land on a "translation pending" affordance or the en page, per the documented exception — decided in Phase D, not silently); per-page title/description/OG; root redirect preserved.
- **Phase E — pt/es follow-up stub (tracked, not shipped).** Record the pt/es route parity as a tracked blocking follow-up (reminder + notes), per the 126 exception.

## Files to touch

**Create:**
- `site/src/data/capabilities.ts` (or extend `capacities.ts`) — the typed manifest (theme, runtimeStatus, sourcePaths, historySpec, slug).
- `site/scripts/check-currency.ts` + a `bun test` wrapper (or `.agent0/tests/site/`) — the build-time currency check.
- `site/src/pages/en/<theme>.astro` × ~5–6 + `site/src/pages/en/how-it-works.astro` — grouped explanatory pages + overview.
- A shared explanatory-page layout/component reusing the 126 design tokens.

**Modify:**
- `site/src/i18n/capacities.ts` — add theme/runtimeStatus/sourcePaths/historySpec; repoint links; drop stale `spec` badges.
- `site/src/i18n/strings.ts` — audit/fix all surfaces (the two named defects + any other stale copy), all three locales for the *landing* (en for new pages).
- `site/src/i18n/mcps.ts` — currency pass (still empty/placeholder is fine if no MCP ships).
- `site/src/components/CapacityGrid.astro` — card "learn more" → on-site page; history link affordance.
- `site/src/components/Header.astro` / `Footer.astro` — nav to new pages; language-switch handling for en-only routes.
- `site/package.json` — wire the currency check into a `test`/`prebuild` script.

**Delete:** none expected (in-place, additive routes).

## Alternatives considered

### Per-capacity pages (~23)
Rejected at the gate — ~23×3 = ~69 hand-authored pages that duplicate the rules and re-stale instantly; doc-bloat for an OSS-landing audience. Grouped-by-theme covers the same ground at a maintainable size.

### Hand-authored pages with no manifest/check
Rejected — that is literally a bigger version of the staleness 126 hit (the "Eighteen" and the stale badges). The manifest + currency check is the spec's reason to exist; without it the work decays in months.

### Full en/pt/es parity for new routes in v1
Rejected at the gate in favor of en-first — but as an *explicit, tracked exception to 126*, not an implicit loophole. The landing stays full 3-locale; only the new explanatory routes are en-first with pt/es as blocking follow-up.

### Render the rules' markdown directly (single source, zero prose drift)
Rejected — violates "no auto-generated docs dump" and reads as machine output. The derive/curate split keeps the single-source benefit for structured bits while letting prose be written for a human reader.

## Risks and unknowns

- **runtime-capabilities.md is prose, not structured.** Deriving per-capacity status classes needs either a parse or a hand-maintained mapping in the manifest. Risk: the mapping itself re-stales. Mitigation: the currency check should flag manifest entries whose `sourcePath` changed since last audit (mtime/hash) — exact design is a Phase A unknown.
- **Build-time fs checks in Astro.** The 404/path check must run where it can read the repo (a prebuild script or test, not client code). Confirm the cleanest hook (`bun test` in CI vs an Astro integration).
- **Language-switch UX for en-only routes.** Switching to pt/es on a new explanatory page has no target yet; the degrade (redirect to en page? disabled switch? "pending" note?) must be a deliberate, documented choice in Phase D.
- **Scope of "audit every surface."** The audit could surface more stale copy than the two named defects; budget for it. The currency check only catches *structured* staleness, not prose drift — prose audit is manual in Phase B.
- **Assumption:** grouped themes map cleanly onto the 23 capacities; a capacity that spans two themes (e.g. secrets-scan = safety + validator) needs a primary-theme rule (decide in Phase A).

## Research / citations

- `docs/specs/127-site-content-refactor/debate.md` — converged debate; the 8 accepted critique points are the acceptance backbone.
- `docs/specs/126-site-refactor/` — predecessor + the locale exception it amends.
- Code read at plan time: `site/src/i18n/capacities.ts` (current model + link targets), `site/src/i18n/strings.ts` (stale copy), `site/src/components/CapacityGrid.astro` (card link wiring), `site/src/layouts/Landing.astro` (meta/route shape), `site/astro.config.mjs` (i18n routing).
- `CLAUDE.md` + `.agent0/context/rules/runtime-capabilities.md` — source of truth for content + per-capacity runtime status.
