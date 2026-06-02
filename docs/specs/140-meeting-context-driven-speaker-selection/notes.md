# 140 — meeting-context-driven-speaker-selection — notes

_Created 2026-06-02._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.agent0/context/rules/spec-driven.md` § The four artifacts for purpose, and `.agent0/context/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

### 2026-06-02 — parent — marker parses the body file, not the rendered turn

`_marker_from_body` reads the last non-empty line of the `--body-file`, before the turn block is assembled. When a turn also carries an inline `Sources:` block, the author must put the `Next:` directive on the very last line (after Sources) for it to be detected — the `turn-prompt.md` instruction says exactly this. The `--sources-file` path (separated sources) renders Sources *after* the body, so a marker + separated sources would show the directive before Sources in the rendered transcript; functionally fine (marker still parsed from the body file) and the common meeting path uses inline sources, so not worth complicating.

### 2026-06-02 — parent — `next_speaker` set only by --next; advance no longer rotates

`cmd_advance` lost the `csv_successor` round-robin branch entirely; `next_speaker` changes only when an explicit `--next <id>` is passed (which `append-turn` derives from the body marker). With no marker the stored default persists. `resolve-speaker` is the single place that applies the full precedence + roster-validation, so the SKILL calls it rather than reading `next_speaker` raw.

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

_None — implementation followed the plan._

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — options considered in-flight, chosen path, accepted cost}}

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — the question, why it surfaced, what's blocked on it, who can decide}}
