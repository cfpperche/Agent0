# 079 — product-stack-aware-handoff — notes

_Created 2026-05-22._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — what was ambiguous, what was decided, why}}

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

### 2026-05-23 — parent — historical mention of `app-skeleton` retained in SKILL.md v0.5.0 changelog paragraph

Task 12 said `grep -n 'app-skeleton' .claude/skills/product/SKILL.md` should return nothing. The v0.5.0 paragraph I added in task 11 names the deleted dirs explicitly ("the bundled `templates/app-skeleton/{next,expo}/` directories and `references/stack-defaults.md` snapshot are deleted") to mirror the v0.4.0 paragraph shape ("the v2/v3 36-route per-route screen-writer fan-out is **deleted**"). The match is historical-context, not a live consumer reference — readers landing on the changelog see what changed and why.

Equally, the description in the frontmatter was tightened to "No stack code ships — Phase 5 reads system-design + roadmap to compute a stack-aware umbrella matrix; the foundation child's `/sdd plan` researches the declared stack." (replacing "Standalone (bundled templates)."), and the version pointer bumped from "v0.4.0 per spec 066." to "v0.5.0 per spec 079." — both correctness fixes not explicitly in tasks.md but follow-through on the version bump.

The verification at task 33 (`rg -F 'app-skeleton' .claude/ docs/specs/`) accepts historical specs as known matches; the SKILL.md changelog paragraph belongs in the same category — past-behavior reference in living documentation. No corrective action taken.

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — options considered in-flight, chosen path, accepted cost}}

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — the question, why it surfaced, what's blocked on it, who can decide}}
