# 182 — product-positioning-reset — plan

_Drafted from `spec.md` on 2026-06-09. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Reset the public narrative without expanding Agent0's mechanism surface. First update `README.md` so the repo-level entrypoint explains the north star and the few load-bearing loops instead of a stale capacity count. Add a root MIT license so public use is not blocked by ambiguity. Then align the landing page strings across English, Portuguese, and Spanish, keeping detailed capacity pages intact for now. Finally, add a short proof document that states what the current evidence does and does not prove.

The work is deliberately copy/content-only plus one license file. It should not sync consumers, inspect local consumer adoption, or add any new harness measurement machinery.

## Files to touch

**Create:**
- `LICENSE` — root MIT license.
- `docs/product/positioning-proof.md` — concise evidence and limits document.
- `docs/specs/182-product-positioning-reset/` — spec artifacts for this work.

**Modify:**
- `README.md` — first-contact product thesis, quick start, work loop, proof/limits, license section.
- `site/src/i18n/strings.ts` — landing page copy in en/pt/es.
- `site/src/config.ts` — reopen the public landing by default while preserving an explicit maintenance override.

**Delete:**
- None.

## Alternatives considered

### Measure local consumer adoption now

Rejected because the user is still the only Agent0 user and many local projects are intentionally demos or dogfood fixtures. Measuring them now would overstate evidence and create busywork. The proof document will explicitly say external adoption is not yet proven.

### Build analytics or dogfood-health tooling

Rejected because this pass is positioning and proof hygiene, not a new harness capacity. Adding tooling would contradict the goal of avoiding more meta-governance.

### Rewrite all site pages and capacity docs

Rejected because the first-contact surfaces carry most of the product perception risk. Detailed capacity pages can remain as reference material until a later content pass proves it is needed.

## Risks and unknowns

- The root `LICENSE` needs the correct copyright holder. This pass uses `cfpperche` unless the owner supplies a different legal name.
- Landing page copy exists in three locales; content changes must keep each locale coherent even if not perfectly idiomatic marketing copy.
- README should avoid hiding Agent0's real depth while no longer leading with capacity count as the proof of value.
- This pass does not prove external demand; it only improves the honesty and clarity of the public story.
- Reopening the site can expose detailed capacity pages that were not fully rewritten in this pass; the currency check and source links are the validation floor.

## Research / citations

- `README.md`
- `site/src/i18n/strings.ts`
- `site/src/config.ts`
- `.agent0/context/rules/agent0-governance-doctrine.md`
- `.agent0/context/rules/runtime-capabilities.md`
- `.agent0/.runtime-state/claude-exec/20260609T144545Z-agent0-product-defense/last-message.md`
