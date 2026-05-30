# 126 — site-refactor — tasks

_Generated from `plan.md` on 2026-05-30. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

**Phase 0 — baseline + audit (no user-visible change)**
- [x] 1. Pick + verify the audit tool/command (Lighthouse via `npx`, or PageSpeed) is actually runnable locally; record the exact command + viewport.
- [x] 2. Capture the pre-refactor baseline for `/en/`, `/pt/`, `/es/` (perf, SEO meta/OG, a11y) into `docs/specs/126-site-refactor/baseline.md`, with pass/fail thresholds.
- [x] 3. Audit the real capacity + MCP inventory against `CLAUDE.md` and the repo; produce the truth table (count + per-capacity currency + multi-runtime status) Phase 1 will use. Decide hardcode-snapshot vs build-time-derive and note it in `plan.md`.

**Phase 1 — content/positioning (THE GATE)**
- [x] 4. Rewrite the hero copy in `strings.ts` (en/pt/es) to state developer value (governance/discipline of the harness), removing stale/unverifiable claims; keep "harness" framing.
- [x] 5. Replace the "Eighteen capacities" copy + sync `capacities.ts` to the audited set; make it multi-runtime-true (Claude Code + Codex CLI, per spec 121), across all three locales.
- [x] 6. Currency pass on `mcps.ts` + the remaining section copy (`whyBuilt`, `quickStart`, `howToExtend`, `faq`) for the dev audience, all three locales in lockstep.
- [x] 7. Enforce claim classes: every capability claim cites a real basis; remove any business-result-metric copy. **Get the copy architecture approved before Phase 2.**

**Phase 2 — visual/brand**
- [x] 8. Extend the `@theme` token seed in `global.css` into a coherent, reusable design system (color/space/type/radius scales, component primitives).
- [x] 9. Apply the design system to the components (`Hero`, `CapacityGrid`, `McpGrid`, `WhyBuilt`, `QuickStart`, `HowToExtend`, `Faq`, `Header`, `Footer`), preserving the dev-oriented CTAs.

**Phase 3 — architecture/code**
- [x] 10. Restructure component/IA as the new narrative requires (merge/split/reorder sections in `Landing.astro`); record any component create/delete/rename back in `plan.md`. Keep the `STRINGS[locale]` data flow.

**Phase 4 — perf/SEO/a11y guardrail**
- [x] 11. Add the `og:image` asset + `og:image`/`twitter:title`/`twitter:description` tags in `Landing.astro`; verify hreflang/canonical still correct.
- [x] 12. Fix any contrast/semantics/a11y issues surfaced against the Phase 0 baseline.

## Verification

_Each maps to a `spec.md` acceptance scenario._
- [x] 13. Root (`/Agent0/`) canonicalizes/redirects to `/en/` cleanly — no blank/broken intermediate. *(Scenario: root canonicalizes)*
- [x] 14. Each locale hero states developer value accurately; capacity/MCP inventory matches repo reality, no dead "Eighteen". *(Scenarios: hero value + current inventory)*
- [x] 15. No business-result-metric claim ships; capability claims all cite a basis. *(Scenario: claim classes)*
- [x] 16. Three locales (`/en/`,`/pt/`,`/es/`) carry the refactor with no untranslated fallback. *(Scenario: locales in lockstep)*
- [x] 17. `bun run build` succeeds on Astro 5 + Tailwind 4, no stack swap. *(Scenario: build + stack preserved)*
- [x] 18. Re-run the Phase 0 audit; perf/SEO-OG (incl. resolved `og:image`)/a11y are equal-or-better vs baseline. *(Scenario: non-functional non-regression)*
- [x] 19. Confirm the phase boundary held: Phase 1 copy was approved before Phase 2 visual work started. *(Scenario: phase boundary)*

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._

- The premise reversal (outcome-led → OSS-dev-landing) is the headline of this spec's history — see `debate.md` Synthesis. The PR description should lead with it so reviewers don't expect a consultancy pivot.
- `dist/` is gitignored; the deploy is GitHub Pages (`cfpperche.github.io/Agent0/`) — "rebuilt dist" is local verification, not a tracked deliverable.
