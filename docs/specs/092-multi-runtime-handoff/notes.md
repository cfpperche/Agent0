# 092 — multi-runtime-handoff — notes

_Created 2026-05-26._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

### 2026-05-26 — Codex CLI — Pointer marker is the implemented compatibility discriminator

Implementation used the plan's content-marker mechanism: `.claude/SESSION.md` starts with `<!-- AGENT0_HANDOFF_POINTER -->`, and `session-start.sh` treats any legacy `SESSION.md` without that first non-blank line as migration-window handoff content. This avoids size-threshold false positives and keeps the hook bash-only.

### 2026-05-26 — Codex CLI — Compact source uses compact-history, not COMPACT_NOTES

The synthesis named `COMPACT_NOTES.md` as example compact-specific context, but the current shipped capacity already uses per-event `.claude/.compact-history/*.md` snapshots. The implementation and spec wording use compact-history as the concrete artifact; this preserves current behavior while satisfying the "handoff plus compact context" requirement.

## Deviations

### 2026-05-26 — Codex CLI — Updated adjacent public docs and rules

The plan listed the core hook/rule/entrypoint files. During implementation, `README.md` and sibling rules (`reminders.md`, `routines.md`, `runtime-introspect.md`, `spec-driven.md`, `memory-placement.md`, `artifact-budgets.md`) also needed small wording updates so the repo no longer presents `.claude/SESSION.md` as live handoff state. These edits are documentation consistency, not new behavior.

## Tradeoffs

### 2026-05-26 — Codex CLI — Stale-claim advisory deferred

No TTL or stale-claim advisory was added to hooks. `Active Work` bullets now require a release condition, and stale-claim automation remains a follow-up only if dogfood shows repeated failures. This keeps v1 focused on a single canonical file and avoids speculative nag behavior.

## Open questions

### 2026-05-26 — Codex CLI — None open for v1 implementation

Q3 resolved by implementing after spec 090 had already shipped. Q4 resolved by deferring stale-claim automation while keeping release condition mandatory. Future automation can be scoped by a follow-up spec if the convention proves insufficient.
