# 076 — product-dogfood-fixes — notes

_Created 2026-05-22._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-05-22 — parent — OQ#8 resolved as (b)+(c) synthesis — `# SKILL-DIRECTED:` marker

The spec's OQ#8 listed three candidates: (a) accept the advisory as noise, (b) skill emits an explicit signal, (c) gate skips `escalation` when a model is declared. Re-reading the gate (`.claude/hooks/delegation-gate.sh:198-216`) showed that (c) as worded is too blunt — `MODEL_SPECIFIED=true` is *already* the precondition for the current `escalation` branch, so inverting it would silence the legitimate ad-hoc case (parent picked sonnet for a multi-signal task and should reconsider opus). (a) was rejected because the founder explicitly listed #8 as a finding worth fixing, and 18+ false advisories per `/product` run train the agent to ignore advisories generally — the "advisory rot" failure mode.

Chosen: a hybrid where the skill adds `# SKILL-DIRECTED: <slug>` to each brief (mirrors the existing `# OVERRIDE:` grammar so the convention is familiar; ≥10-char slug rule reused), and the gate learns to suppress *only* `escalation` when the marker is present. `model-discipline` deliberately keeps firing — the marker certifies that a declared model was a conscious choice, not that forgetting to declare one is excused. Audit row records `skill_directed: "<slug>" | null` so adoption is greppable (`jq 'select(.skill_directed)'`).

Why this over (b) puro with some other mechanism: the `Agent` tool surface only exposes `prompt` + `model` + `subagent_type` + `description` + `isolation`. There is no metadata channel orthogonal to the prompt. The marker lives in the prompt body — the same surface `# OVERRIDE:` already uses — so the grammar generalizes rather than introducing a new field.

Implementation footprint: ~5 lines in `delegation-gate.sh` (grep for marker before the `score >= 2 && model != opus` branch), 1 line per brief in `.claude/skills/product/references/delegation-briefs.md` (Steps 02-15), one new field in the audit-row builder, and a § Advisories update in `.claude/rules/delegation.md` documenting the marker. Other skills opt in by adding the same marker line; no skill is forced to adopt.

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
