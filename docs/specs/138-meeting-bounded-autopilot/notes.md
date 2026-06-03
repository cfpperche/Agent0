# 138 — meeting-bounded-autopilot — notes

_Created 2026-06-02._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.agent0/context/rules/spec-driven.md` § The four artifacts for purpose, and `.agent0/context/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — what was ambiguous, what was decided, why}}

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

### 2026-06-03 — parent — friction counter is blind to un-recorded human direction (measurement gap)

The OD-overengineering meeting (`.agent0/meetings/open-design-overengineering-for-agent0-2026-06-03T16-24-35Z/`) registered `max_consecutive_model_turns: 4` — `meeting.sh friction` reports the **mechanical half MET**. But it surfaced a real measurement gap: the human (founder) actively directed **every round** ("more turns on craft", "what do you suggest", "synthesize") — they were never absent. That direction just didn't produce a *recorded transcript turn* (the human steers via conversation + `--speaker`, not `append-turn`), so the friction counter — which counts recorded turns — can't see it and reports 4 consecutive model turns as if unattended.

Implication for the demand test: this is **NOT a qualifying meeting**. The gate needs BOTH halves, and the intent half ("explicit human *continue unattended*") was firmly absent — the opposite, the human was hands-on throughout. So **0 qualifying meetings still** (this does not count toward the rule-of-three).

The genuine finding worth keeping: the mechanical signal **over-reports** when a human orchestrates without recording turns. Before the autopilot is ever built, the friction measure should either (a) require the intent half as the real gate (mechanical alone is too loose), or (b) record a lightweight "human directed (no turn)" marker so the counter isn't fooled. Owner: founder, at reopen time. Not acting now — the spec stays shelved; this is the honest data point so a future evaluation isn't misled by a "4" that wasn't really unattended.
