# 155 — visual-contract-acceptance-gate — notes

_Created 2026-06-05._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.agent0/context/rules/spec-driven.md` § The four artifacts for purpose, and `.agent0/context/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-06-05 — parent — Reused `agent-browser verify-contract` fixture-spec; extended in place

The existing `verify_contract()` already shipped the `render`-tier format (`{required:[{role,name}], max_console_errors}`) + `report.json`. Rather than a parallel format, added two optional arrays (`interactions`, `flow`) and drove them through the wrapper's act-verb passthrough. `add_check` gained a 4th `flaky` arg → a failing flaky step is a `warn` (new field on each check object) and does NOT flip `overall`. Backward compatible: render-only fixtures produce the identical report shape plus a `warn:false` on each check.

### 2026-06-05 — parent — Added fixture-JSON validity guard (exit 3)

`verify-contract` now runs `jq -e . "$fixture"` up front; a malformed fixture is a usage error (exit 3) with no report written, rather than silently producing a partial report from swallowed jq errors. This made the "malformed → exit 3" acceptance testable and closes a quiet-failure hole.

### 2026-06-05 — parent — `app/`-segment + bare `.php` is a Laravel false-positive; excluded `.php`

The detector's UI-dir set includes `app/` (Next.js app-router). A Laravel `app/Http/Controllers/*.php` then false-flagged. Resolved by adding `php` to the server-language exclusion (templates `.blade.php` are matched as surfaces *before* that exclusion, so Blade views are not lost). Plain non-Blade `.php` UI is rare and advisory-only — acceptable.

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

### 2026-06-05 — parent — `shellcheck` unavailable → gate uses `bash -n`

`tasks.md` V7 and the plan mentioned a `shellcheck` clean check, but `shellcheck` is not installed in this environment. The `squad.json` gate and the verification use `bash -n` (syntax check, always available) on every new/changed shell file instead. Functionally covers the syntax-clean intent; a consumer with `shellcheck` can add it to their gate.

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
