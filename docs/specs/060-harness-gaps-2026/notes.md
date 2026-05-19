# 060 — harness-gaps-2026 — notes

_Created 2026-05-19._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

### 2026-05-19 — parent — chose `umbrella` over `epic` as the type value

Considered `epic` (Agile/Jira), `tracking` (Rust/Kubernetes OSS convention), `umbrella` (informal Anthropic/OSS), and `meta-spec`. `epic` carries too much Jira baggage and implies multi-sprint ticket grouping; `tracking` aligns with OSS but is more issue-shaped than spec-shaped. `umbrella` is descriptive without baggage and matches how the team already references this kind of artifact informally. Documenting the convention in `.claude/rules/spec-driven.md` so it propagates to forks via sync-harness.

### 2026-05-19 — parent — chose `**Type:**` line over YAML frontmatter

Existing 59 specs use bolded inline `**Status:**` near the top — no YAML frontmatter anywhere in `docs/specs/`. Adopting frontmatter for the new field would force migrating 59 specs OR live with mixed shapes. The bolded line matches the existing convention, costs one line, is grep-able (`grep -l "Type: umbrella" docs/specs/*/spec.md`), and avoids parser dependencies.

## Deviations

_(none yet — spec was just scaffolded)_

## Tradeoffs

### 2026-05-19 — parent — close §A1 (→ 062) instead of redesigning with Stop-hook

When discussing 062's design (rule-only v1 vs revised v1 with Stop-hook enforcement), pre-flight verification of competitive landscape revealed CC 2.1.144 already ships `/goal` natively. Surface confirmed via `strings /home/goat/.local/bin/claude | grep -iE '^/goal'` — full command set (`/goal <condition>`, `/goal clear`, `/goal`), description "Set a goal — keep working until the condition is met", internal `goal-command-nudge` identifier suggesting built-in enforcement mechanism.

Three options weighed: (A) close 062 cleanly, defer to CC native; (B) thin wrapper `/contract` adding Agent0 audit + persistence; (C) alternative with stricter semantics. Chose A.

Reason for A over B: Agent0's framing principle is **discipline ON TOP of CC**, not replication of canonical CC primitives. A wrapper around a primitive whose internals we haven't probed (`goal-command-nudge` mechanism, feature flag gate `isHidden: !T6()`) would commit us to a design before dogfood reveals the gap. The marginal value of B (forensic audit of /goal usage) is exactly what `feedback_speculative_observability.md` flags as anti-pattern.

The hour spent yesterday scaffolding 062 wasn't wasted — it forced reading the design space sharply enough to ask "does CC already do this?" at the right moment. Pre-flight verification (Task 1 of the original tasks.md) was the load-bearing step that surfaced this.

Row A1 in § Gap matrix updated from `→ 062` to `closed: superseded by CC native /goal (2.1.144+)`. Spec 062 marked `superseded` with full Closure section in `spec.md`; design memory preserved (acceptance criteria, plan, tasks outline) as historical reference if a future spec targets a concrete gap CC's `/goal` proves insufficient for.

### 2026-05-19 — parent — scaffold top-3 follow-ups immediately, defer the rest

The user said "vamos abrindo specs refinadas de followup ... por ordem de prioridade". Two interpretations: (a) open ALL §A+§B follow-up specs now, (b) open the top priority ones now and iterate. Chose (b): scaffolds only specs 061/062/063 (the three alta-prioridade rows). Tradeoff accepted: §A4-A8 + §B medium-priority rows wait for explicit prioritization. Reason: stale draft specs rot and signal noise; scaffold-when-ready preserves the umbrella matrix as the single source of truth for "what's pending".

## Open questions

_(none yet — spec was just scaffolded)_
