# 133 — image-fal-rest-migration — notes

_Created 2026-05-31._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.agent0/context/rules/spec-driven.md` § The four artifacts for purpose, and `.agent0/context/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

### 2026-05-31 — parent — failure-receipt http_code is 0 after migration (minor, intentional)

The pre-migration `sub_exec` captured the exact upstream HTTP code into the failure receipt (`{"status":"failure","http_code":<real>,...}`). The shared `fal-rest.sh run` dies non-zero on non-200 and writes the real code + fal error body to **stderr**, but does not return the code to the caller. So `/image`'s failure receipt now carries `http_code: 0` (a transport/lib-failure sentinel); the precise upstream code + body are on stderr (the agent sees them). The success receipt is byte-identical (`http_code: 200`). Accepted: the receipt's load-bearing field is `status`, and surfacing the fal error body on stderr is strictly more useful than a bare code. Not worth complicating the lib's clean die-on-error contract.

### 2026-05-31 — parent — wiring validated end-to-end without a paid call

`gen.sh exec` with a fake `FAL_KEY` against `fal-ai/flux/schnell` returned a real **HTTP 401** from `fal.run` *through* `fal-rest.sh run` (`{"detail":"No user found for Key ID and Secret"}` on stderr) and emitted the correct failure receipt. This exercises the full delegation path (FAL_REST resolver → lib → error handling → receipt) — the only thing unproven is a *successful* generation, which needs a real key + spend. `/image` suite (prepare/record) + `/video` suite both green.

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

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — the question, why it surfaced, what's blocked on it, who can decide}}
