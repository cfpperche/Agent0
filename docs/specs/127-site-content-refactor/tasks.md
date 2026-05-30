# 127 — site-content-refactor — tasks

_Generated from `plan.md` on 2026-05-30. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

**Phase A — typed manifest + currency check (the guard, lands first)**
- [ ] 1. Design the typed manifest schema (`id`, `slug`, `theme`, `runtimeStatus`, `sourcePaths[]`, `historySpec?`, `localeCoverage`) and decide the primary-theme rule for cross-theme capacities; record in `plan.md`.
- [ ] 2. Populate the manifest for all 23 capacities from `CLAUDE.md` + `.agent0/context/rules/runtime-capabilities.md` (theme, current sourcePaths, per-runtime status, optional historySpec).
- [ ] 3. Write the currency check (`site/scripts/check-currency.ts` + `bun test` wrapper) that FAILS when: a `sourcePath` 404s on disk, a card's primary target is `docs/specs/00*`, a themed capacity lacks an explanatory route, or a resolved-locale page is missing. Wire it into `package.json` (`test`/`prebuild`).

**Phase B — content audit + fixes (existing single page)**
- [ ] 4. Audit every `strings.ts` surface (hero/whyBuilt/quickStart/howToExtend/faq/mcps/nav/footer/meta) against the live repo; fix the named defects (`.claude/settings.json` → `.codex/hooks.json`; soften "the agent cannot drift out of") + any other stale copy found, all 3 locales.
- [ ] 5. Re-point card "learn more" through the resolved hierarchy (on-site page → current rule/skill → optional history link); drop or repoint stale `spec NNN` badges in `capacities.ts` + `CapacityGrid.astro`.

**Phase C — grouped explanatory pages + overview (en)**
- [ ] 6. Build the shared explanatory-page layout/component reusing 126 design tokens.
- [ ] 7. Author the ~5–6 grouped-by-theme pages under `/en/`; each capacity block shows derived per-runtime status (enforcement/advisory/read-only/convention/planned + works-now-vs-planned) with hand-authored prose/examples.
- [ ] 8. Author the `/en/how-it-works` overview (hooks ↔ rules ↔ skills ↔ runtimes, the lifecycle, the multi-runtime story).

**Phase D — route/nav/meta wiring**
- [ ] 9. Wire nav (Header) + landing links to the new pages; ensure none are orphaned.
- [ ] 10. Per-page title/description/OG for each new route; preserve root redirect; confirm hreflang/canonical correctness.
- [ ] 11. Decide + implement the language-switch degrade for en-only explanatory routes (deliberate, documented — not silent).

**Phase E — tracked follow-up**
- [ ] 12. Record pt/es route parity for the new pages as a tracked blocking follow-up (reminder + notes), per the documented 126 exception.

## Verification

_Each maps to a `spec.md` acceptance scenario._
- [ ] 13. No card's primary "learn more" targets `docs/specs/00*`; all resolve to on-site page or current rule/skill. *(Scenario: no superseded-spec links)*
- [ ] 14. ≈5–6 themed pages + the overview exist and render; each capacity has an explanatory home. *(Scenario: grouped pages + overview)*
- [ ] 15. Every content surface reconciles with current state; the two named defects are gone. *(Scenario: content-surface audit)*
- [ ] 16. Per-capacity runtime status matches `runtime-capabilities.md` (status class + works-now-vs-planned). *(Scenario: per-capacity runtime status)*
- [ ] 17. The currency check FAILS on each pinned drift condition (test it with a deliberately-broken fixture) and PASSES clean. *(Scenario: anti-restaling currency check)*
- [ ] 18. Every new route exists for the resolved locale set, has a language-switch equivalent, is linked from the landing, preserves the redirect, carries title/description/OG. *(Scenario: route/nav/meta)*
- [ ] 19. `bun run build` green on Astro 5 + Tailwind 4; no stack swap. *(Scenario: build + stack preserved)*

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._

- The manifest + currency check is the durable deliverable — it's what stops 127 from becoming the next 126 staleness. The PR should lead with it.
- en-first for new routes is an explicit, tracked exception to 126's no-locale-reduction; pt/es is task 12 (blocking follow-up), not abandoned.
