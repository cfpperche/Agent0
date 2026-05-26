# 093 — runtime-capability-registry — notes

_Created 2026-05-26._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-05-26 — parent — Upstream does not record a fork sync baseline

During implementation, `rg`/`git ls-files` confirmed that `.claude/harness-sync-baseline.json` does not exist in the Agent0 upstream repo. The baseline is fork-local state written by `sync-harness.sh --apply` in downstream forks, per `.claude/rules/harness-sync.md`; Agent0 upstream validates manifest coverage by running `sync-harness.sh --check --agent0-path "$(pwd)" "$(pwd)"`. The plan/task text was adjusted accordingly so this spec does not introduce a new upstream baseline file.

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

_None beyond the baseline decision recorded above; the plan was updated before continuing._

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

_None beyond the tradeoffs already captured in `debate.md`._

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._

_None._
