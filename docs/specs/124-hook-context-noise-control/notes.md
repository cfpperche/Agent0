# 124 — hook-context-noise-control — notes

_Created 2026-05-30._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.agent0/context/rules/spec-driven.md` § The four artifacts for purpose, and `.agent0/context/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-05-30 — parent — Startup brief owns the visible SessionStart surface

`startup-brief.sh` is the only registered model-visible `SessionStart` hook for Agent0. It preserves the
session-state side effects that `session-stop.sh` depends on, but summarizes handoff/reminders/routines/memory
into one bounded `AGENT0_STARTUP_BRIEF` block. The older readout scripts remain directly callable helpers
because their parsing and fallback behavior is still useful for tests and debugging.

### 2026-05-30 — parent — Prompt context uses capsules, not rule bodies

`context-inject.sh` now emits prompt-selected capsules with source pointers by default. Full fragment inventory
is available only via `AGENT0_CONTEXT_DIAGNOSTIC=1` or `AGENT0_CONTEXT_MODE=index`. This keeps false-positive
selection cheap and makes the agent explicitly read `.agent0/context/rules/<slug>.md` before relying on details
that no longer fit in the hook output.

### 2026-05-30 — parent — Reminder summaries are one line per reminder

The first startup probe stayed under budget, but still exposed long raw reminder sub-bullets. The aggregator now
prints only a compact first-line summary per due/unscheduled reminder, appends the due date when present, and
omits check/link sub-bullets from model-visible startup context.

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

None.

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

### 2026-05-30 — parent — Caps favor predictable startup over completeness

The startup brief keeps default caps at 6,000 bytes / 80 lines and prompt context at five fragments / 6,000
bytes. This can omit lower-priority reminders or secondary context matches, but each section includes pointers
to the durable source files or commands so the agent can intentionally fetch detail when the task needs it.

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._

None.
