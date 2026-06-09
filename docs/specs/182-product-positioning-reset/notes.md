# 182 — product-positioning-reset — notes

_Created 2026-06-09._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.agent0/context/rules/spec-driven.md` § The four artifacts for purpose, and `.agent0/context/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

### 2026-06-09 — parent — Exclude consumer adoption measurement

The user clarified that Agent0 is still a single-user local project and that some consumer repos are intentionally demos created for dogfood. This spec therefore treats local projects as qualitative context only and explicitly excludes adoption or dogfood-health measurement from the delivery.

### 2026-06-09 — parent — Reopen the public landing

The landing source was updated but preview initially showed only the maintenance page because `UNDER_CONSTRUCTION` defaulted to `true`. Since this spec is about first-contact positioning, the public landing must render by default. `site/src/config.ts` now keeps the explicit pause switch (`PUBLIC_UNDER_CONSTRUCTION=true`) but defaults to the real site.

### 2026-06-09 — parent — Validation evidence

Commands:

```bash
cd site && bun run build
bash .agent0/tools/agent-browser.sh verify-contract \
  http://127.0.0.1:4321/Agent0/en/ \
  docs/specs/182-product-positioning-reset/visual-contract.json \
  .agent0/.runtime-state/visual-contract/spec-182
git diff --check -- README.md LICENSE site/src/i18n/strings.ts site/src/config.ts docs/product/positioning-proof.md docs/specs/182-product-positioning-reset
```

Results:

- `bun run build`: pass.
- `agent-browser.sh verify-contract`: pass, including en/pt/es hero headings and zero console errors; report at `.agent0/.runtime-state/visual-contract/spec-182/report.json`.
- `git diff --check`: pass.

## Deviations

## Tradeoffs

## Open questions
