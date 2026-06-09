# 182 — product-positioning-reset — tasks

_Generated from `plan.md` on 2026-06-09. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. Rewrite the README first-contact sections around the governance/evidence harness thesis, removing stale capacity-count framing.
- [x] 2. Add the root MIT license.
- [x] 3. Align the landing page copy in `site/src/i18n/strings.ts` across en/pt/es.
- [x] 4. Add `docs/product/positioning-proof.md` with current evidence, limits, and non-claims.
- [x] 5. Reopen the public landing by default while preserving an explicit maintenance override.
- [x] 6. Close the spec artifacts with checked acceptance criteria and closure evidence.

## Verification

- [x] `README.md` no longer contains "Eight capacities" / "No license file shipped" framing.
- [x] `LICENSE` exists and README points to it.
- [x] `bun run build` passes in `site/`.
- [x] `agent-browser.sh verify-contract` passes against the reopened local preview.
- [x] `git diff --check` passes.
- [x] The proof document states that local dogfood is not external adoption.

## Notes

- Consumer adoption/dogfood-health measurement is intentionally excluded from this pass per user direction on 2026-06-09.
- Verification evidence: `bun run build` from `site/` passed on 2026-06-09; visual-contract proof was run against local preview; `git diff --check -- README.md LICENSE site/src/i18n/strings.ts site/src/config.ts docs/product/positioning-proof.md docs/specs/182-product-positioning-reset/*` passed.
