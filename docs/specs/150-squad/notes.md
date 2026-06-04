# {{NNN}} — {{SLUG}} — notes

_Created {{DATE}}._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.agent0/context/rules/spec-driven.md` § The four artifacts for purpose, and `.agent0/context/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-06-04 — parent — gate contract is `squad.json` (not `.yaml`) in v1

The debate said "squad.yaml or squad.json". Chose **JSON** for v1: `jq` is already a harness-wide dependency and parses it natively; YAML would add a `yq` dependency for marginal ergonomic gain. `squad-contract.md` documents this as a v1 decision; a `squad.yaml` form is a future nicety. The skill/rule/CLAUDE index all say `squad.json`.

### 2026-06-04 — parent — deterministic core fully tested; live pump is a separate dogfood

`squad.sh` (state machine: turn-lock, budget, gate, terminal states, guard, rollback) is shell-unit-tested 8/8 — every invariant, including the load-bearing "agreement ≠ done" (gate red + both proposed → status stays `running`). The **live autonomous pump** (a real 2-agent loop writing code via the exec bridges) is NOT unit-tested — it costs tokens, needs a target spec, and runs wall-clock. The test suite IS the dry-run of the state machine the pump drives; a real dogfood on a tiny low-risk pre-planned spec is the honest next validation, gated separately. This is scoped explicitly (spec § last acceptance bullet) — not a gap hidden behind a green suite.

### 2026-06-04 — parent — out-of-turn detection model (v1)

git can't attribute a working-tree change to a specific agent, so v1 "out-of-turn" = changes present in the working-tree fingerprint (`git status --porcelain`) when **no turn is open** (`turn_open=false`), compared against the boundary snapshot taken at the last `turn-end`. `guard` → `aborted_conflict`. Forbidden/human-gated path patterns are matched against the changed paths → `aborted_policy` / `human_checkpoint_required`. Run-dir lives under `.agent0/.runtime-state/squads/` (inherits the existing gitignore; zero new entry); the durable record is the spec + the git history of the turns.

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
