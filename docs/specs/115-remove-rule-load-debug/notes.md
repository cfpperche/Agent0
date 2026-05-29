# 115 — remove-rule-load-debug — notes

_Created 2026-05-29._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-05-29 — parent — KEEP boundary for historical narrative outside docs/specs

The repo-wide grep (acceptance T15) surfaced three live (non-`docs/specs/`) hits that were deliberately NOT removed, because they are accurate historical narrative of past reclassifications rather than live wiring of the deleted capacity:

- `.agent0/memory/propagation-hygiene.md:66` — names `rule-load-debug` as one of 6 rule files whose citation-pointer was cleaned in spec 070 (2026-05-21). At that time it WAS a rule; the sentence is frozen audit history. Removing the name would falsify the record. (Already listed as a KEEP in `spec.md` § Non-goals.)
- `.claude/rules/memory-placement.md:58` and `:247` — cite `rule-load-debug.md` as a canonical example of the spec-096 `move-full` rule→memory disposition. The 096 move genuinely happened; the example is illustrative of the routing-tree rationale and remains true. This is the **same KEEP precedent spec 114 applied to its own `memory-placement.md:58` compaction-continuity mention** (recorded in the prior HANDOFF's "Intentional KEEPs"). Consistency with that precedent decided it.

The operative test: does the line describe *live wiring of the now-deleted capacity* (→ remove) or *a historical event that remains factually true* (→ keep)? All three are the latter.

### 2026-05-29 — parent — cc-platform-hooks.md empirical section: sever pointer, keep finding

`spec.md`/`plan.md` said "keep the empirical dedup finding, sever the cross-references". In flight, line 137's *example* also named `rule-load-debug.md`'s globs (a now-deleted doc that, since spec 096, wasn't even a path-scoped rule anymore — so the example was already partly stale). Rather than leave a dangling name, generalized the example to "when one file path matches the globs of two different path-scoped rules" — preserves the platform finding verbatim in substance while removing the dead reference. The `InstructionsLoaded` event-table row (a platform fact about all 29 CC events) and the dedup finding itself are untouched in meaning.

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — what the plan said, what was done instead, why}}

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — options considered in-flight, chosen path, accepted cost}}

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — the question, why it surfaced, what's blocked on it, who can decide}}
