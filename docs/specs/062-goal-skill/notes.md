# 062 — goal-skill — notes

_Created 2026-05-19._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

### 2026-05-19 — parent — close spec 062 without implementation; CC native /goal covers the gap

Pre-flight empirical check (Task 1 of original tasks.md) discovered that Claude Code 2.1.144 ships `/goal` as a native slash command — surfaced via `strings /home/goat/.local/bin/claude | grep -iE '^/goal'`. Native command signature matches what we were designing:

- `/goal <condition>` to set
- `/goal clear` to stop early
- `/goal` alone to query active state
- Internal mechanism referenced as `goal-command-nudge` (likely a system-prompt inject or hook)
- Description: "Set a goal — keep working until the condition is met" (built-in loop semantics)

Three options weighed:

- **A. Close 062, defer to CC native** — chosen.
- **B. Build thin wrapper `/contract` adding Agent0 audit + persistence** — rejected: marginal value (audit) is exactly what `feedback_speculative_observability.md` flags as anti-pattern; build-when-drift-observed, not preemptively.
- **C. Build alternative with stricter semantics (Stop hook + verifier loop)** — rejected: would compete with the canonical primitive; Agent0's frame is discipline ON TOP of CC, not replication.

Rationale for A over B: a wrapper around a primitive whose semantics we don't yet fully understand (`goal-command-nudge` internals not probed, feature flag gate not investigated) would commit us to a design before we've dogfooded the real thing. Closing cleanly preserves optionality — if CC's `/goal` proves insufficient via observed dogfood drift, a targeted follow-up spec is the path.

What was preserved:
- `spec.md` Acceptance criteria + Non-goals + Open questions — historical design memory of how WE would have shaped this primitive
- `plan.md` Approach + Alternatives considered — comparison framework still valuable for the next CC-native-vs-build decision
- `tasks.md` 10-task implementation outline — if a follow-up rebuilds, this is the starting structure

Lesson: pre-flight verification of competitive landscape (Task 1 in `tasks.md`) caught what would have been ~200-300 lines of redundant skill code. The hour spent drafting the spec was not wasted — it surfaced the right question to ask at the right time.

## Deviations

## Deviations

_(none yet)_

## Tradeoffs

_(none yet)_

## Open questions

_(none yet — see `spec.md` § Open questions for pre-flight unknowns)_
