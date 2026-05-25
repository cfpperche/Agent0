---
name: bertolini-dogfood-loop
description: External paste-and-go autonomous-loop wizard (Bertolini gist 2026-05-24). Novel piece — strict-order cascade classification with default-to-issue. Not adopted in Agent0; single sample, rule-of-three test (cf. skill-eval-pattern).
metadata:
  type: reference
  created_at: 2026-05-24T19:42:00Z
  last_accessed: 2026-05-24T19:42:00Z
  confirmed_count: 0
---

# Bertolini's dogfood-loop pattern (external reference)

External pattern captured 2026-05-24, **not adopted**. Saved so the signal survives session compaction and future occurrences can hit rule-of-three.

## Sources

- Bertolini "how" thread: <https://x.com/brunobertolini/status/2058617644769493017>
- The wizard gist: <https://gist.github.com/brunobertolini/d583141b9909909eeaba6273ff87cdc0>
- Original "24h autonomous" tweet: <https://x.com/brunobertolini/status/2058574005347422229>
- Parent inspiration — Boris Cherny's auto-mode + multi-clauding tip: <https://x.com/bcherny/status/2058519809214607704>

## What the pattern is

A paste-and-go wizard prompt for Claude Code that arms a cron-recurring autonomous browser-exploration + auto-fix loop against a product SaaS app. 8-step setup: discovery → 7 `AskUserQuestion` config → pre-flight checks → state file → cron prompt → confirmation → arm via `CronCreate` → final report. Setup ~2min. Documented caveat: linear session-context burn — even Max 20x plan exhausts fast.

Stack: Claude Code + `CronCreate` + state file on disk + per-project "scenario" skills (`dogfood-*` / `loop-*`).

## The novel piece (what Agent0 has nowhere)

**Strict-order finding classification with default-to-issue.** Four categories evaluated in fixed order; first match wins; fall-through to ultimate default when uncertain:

1. `backend_fix` — auto-fix allowed. Requires explicitly-named wrong line of code.
2. `tracking_fix` — auto-fix allowed. Requires named event-typo / payload-shape-wrong.
3. `ui_issue` — issue only. All visual/layout/taste-based findings.
4. `needs_product` — issue only. **ULTIMATE DEFAULT when unsure.**

The cascade-with-conservative-default is the discipline: a finding that doesn't cleanly match an auto-fixable bucket routes to "open an issue, don't touch code". Agent0's existing taxonomies (post-edit-validator output, code-review, `/product` quality-judge) are plane-single — no cascade, no default-to-conservative.

## Why not adopted (2026-05-24 decision)

Rule-of-three demand test (precedent: [[skill-eval-pattern]] — 5 industry posts converged on the same skill-eval recipe and Agent0 still didn't build). Single sample so far. Three structural reasons compound:

- Agent0 is meta-harness, not product-SaaS — no browser-exploration scenarios to dogfood
- State-file primitive already exists via `/routine` (`.claude/.routines-state/<slug>/queue/` + `last-completed.json`)
- In-fire TDD-loop + branch-isolation already covered by post-edit-validator + delegation worktree-isolation

## When to revisit

If 2+ further situations surface where cascade classification with default-to-conservative would help — another fork independently arriving at it, a new producer (security-review, validator, judge) needing it, or a real Agent0 use-case for it — then promote the **meta-rule** (not the Bertolini taxonomy) as a short section in `.claude/rules/delegation.md` § Advisories. Don't build a wizard; do edit the rule.

The Bertolini taxonomy itself (`backend_fix` / `tracking_fix` / `ui_issue` / `needs_product`) is bound to product-SaaS-with-analytics and won't generalize. The exportable pattern is just the meta-shape: ordered buckets, named match criteria, conservative default at the bottom.

## Cross-references

- [[skill-eval-pattern]] — analogous deferral; same rule-of-three reasoning
- `.claude/rules/routines.md` — overlapping capacity (cron + state-file)
- `.claude/rules/delegation.md` — likely landing site if/when the meta-rule promotes
