# 179 — sdd-close-advisory — notes

_Created 2026-06-09._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.agent0/context/rules/spec-driven.md` § The four artifacts for purpose, and `.agent0/context/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-06-09 — parent — Advisory noise control: opt-in via `**Closure:**`, not recency

The original plan scoped the validator advisory by **recency** (only nag recently-touched/created shipped specs). Implementing and dogfooding it overturned that. Three signals were tried:

1. **Git mtime** (`git log -1 --format=%ct -- <dir>`) → flagged ~115 specs. Cause: Agent0 is a *consolidation repo* (spec 102 imported the corpus), so specs 001 and 020 both report commit date `2026-05-25` despite `_Created` of `2026-05-10/11`. Git mtime = migration date, not authoring date. Rejected.
2. **`_Created` line, 14-day rolling window** → still flagged ~80 specs. Cause: Agent0 ships ~4 specs/day, so 14 days ≈ 80 specs; and the closure convention is hours old, so every pre-convention spec trips `missing-closure`. Rejected — recency is simply the wrong axis in a high-cadence repo.
3. **Opt-in via the `**Closure:**` line** (chosen) → **0 advisories** on the live corpus. A spec declaring `**Closure:**` has asserted "done with this evidence"; the advisory just checks the artifacts back that assertion. Specs without the line never opted in → never nagged. This exactly mirrors spec-verify's `**Verify:**` opt-in, needs zero date/git machinery, is migration-immune, and is silent by default — the doctrine-aligned outcome (`feedback_speculative_observability`).

Consequence: `missing-closure` is demoted from an advisory finding to a tool-only finding (under opt-in, absence of the line *is* the opt-out, so it cannot also be a nag).

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

### 2026-06-09 — parent — Dropped recency/date/git logic from the validator pass

`plan.md` initially specified a recency gate (and a git-unavailable fallback). Both were removed after the dogfood (see Design decisions above). The shipped validator block has no `date`, no git, no `CLAUDE_SDD_CLOSE_RECENCY_DAYS` — just the `**Closure:**` opt-in guard. `spec.md` acceptance scenarios 4-5 and the open questions were rewritten to match before continuing.

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._

## Verification log

### 2026-06-09T12:24:37Z — pass (1/1) — source: tasks.md
- `bash .agent0/tests/sdd-close/run-all.sh` — pass
