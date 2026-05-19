# 053 — Plan

## Approach

Edit `delegation-briefs.md § Per-stack screen-writer` to add four explicit CONSTRAINT blocks. Each block has a do/don't list + DONE_WHEN clause the sub-agent self-checks. No new files; no sub-agents.

## Files to touch

- `.claude/skills/product/references/delegation-briefs.md` — body change in `§ Per-stack screen-writer`; new CONSTRAINTS clauses for: (a) metadata export, (b) states implementation evidence, (c) Biome anti-pattern checklist, (d) primary metric prominence.
- `.claude/skills/product/references/quality-checklist.md` — add gate criteria for the four new requirements at Step 15.
- `.claude/skills/product/references/sitemap-schema.md` — add optional `primary_metric: string` field on route schema.
- `.claude/skills/product/templates/pipeline/07-sitemap-ia/prompt.md` — instruct Step 07 sub-agent to emit `primary_metric` when the route has a load-bearing operational value.

## Alternatives considered

- **Sub-agent SOUL/persona for screen-writer.** Rejected — the gaps are mechanical, not personality. A persona that "cares about a11y" still drifts; a constraint that bans `<div role="status">` does not.
- **Post-write QA agent (`screen-writer-qa`).** Rejected this session (see `.claude/SESSION.md` "REPROVADA" entry). `.claude/agents/` propagates to forks via sync-harness; agents must be capability-generic, not skill-specific.
- **Hard-fail validator on Biome anti-patterns.** Rejected — would worsen the validator-cascade Wave-1 problem (spec 057). Brief-time enforcement is cheaper.
- **Move all UI-quality concerns to the design-system step (014).** Rejected — design tokens cannot enforce per-route metadata or state implementation; those are page-level concerns.

## Risks

- **Brief inflation.** Each new CONSTRAINT adds tokens; over-prescriptive briefs degrade sub-agent agency on legitimate variations. Cap added budget at ~500 tokens.
- **State enforcement may force "empty-state-for-the-sake-of-it"** — sub-agent invents copy for a degenerate case the product doesn't actually have. Mitigation: open question #2 above — allow `deferred_states`.
- **Sitemap schema change ripples.** New `primary_metric` field is optional; existing sitemaps without it pass validation unchanged. No migration needed.
