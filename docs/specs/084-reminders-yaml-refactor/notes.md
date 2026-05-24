# 084 — reminders-yaml-refactor — notes

_Created 2026-05-24._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — what was ambiguous, what was decided, why}}

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

### 2026-05-24 — parent — readout tier order inverted (python-first, not yq-first)

`plan.md` § Approach step 3 ordered the readout tier as yq-first → python-fallback. Implementation inverted to python-first → yq-fallback. Reason: the canonical formatted output (id + context + indented sub-bullets for `due` / `check_command` / `links`) is produced by `reminders-helper.py readout`. yq emits a single-line shape via filter projection, which is functional but loses the sub-bullet structure. Python+PyYAML is broadly available (every modern Linux/macOS dev box) and the readout runs once per session boot — fast-path-via-yq optimization buys ~50ms while costing output consistency. Inversion makes the agent's reading experience identical whether the helper or the fallback runs. yq remains a graceful tier-2 fallback for forks without PyYAML; raw-YAML stays as tier-3.

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — options considered in-flight, chosen path, accepted cost}}

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._

### 2026-05-24 — parent — yq tier-2 fallback unverified locally

T14 verification could only exercise tier 1 (Python helper) and tier 3 (raw YAML fallback) — `yq` is not installed on the dev machine. The hook code that delegates to `yq eval` is structurally correct (mirrors helper-tier logic) but unproven in execution. Re-run T14 on a machine with `yq` (e.g. `brew install yq` or `apt install yq`) to verify the filter query handles status/snoozed_until correctly. Until then, treat tier 2 as a design-intent fallback rather than a verified path. Tier 1 covers the canonical case; tier 3 covers the worst case; the gap is the mid-tier convenience.
