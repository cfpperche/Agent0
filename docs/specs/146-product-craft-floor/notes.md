# {{NNN}} — {{SLUG}} — notes

_Created {{DATE}}._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.agent0/context/rules/spec-driven.md` § The four artifacts for purpose, and `.agent0/context/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-06-03 — parent — OQ convergence with Codex (codex-exec) + spec-premise corrections

All spec-146 OQs resolved in one `codex-exec` convergence pass (read-only, web — Codex inspected OD's `apps/daemon/src/lint-artifact.ts`). Decisions: (1) standalone `scripts/craft-floor-check.ts`, JSON the judge consumes; (2) `craft-floor` on judge-units `02-prototype` + `15b-hifi-mood` only — **not** `15a-screen-atlas` (Codex: it's a contract/inventory artifact, penalizing its doc-shell styling is wrong); (3) **rule triage** — ship 5 deterministic (`default-indigo-accent`, `trust-gradient`, `emoji-feature-icon`, `filler-copy`, `sans-display-when-serif-bound`), downgrade 2 to judge-only guidance (`rounded-card-colored-left-border`, `invented-metrics` — regex-noisy); (4) brand exception = parse bound `DESIGN.md` hex + custom-props + display-font, suppress exact-match / `var()` usage; (5) JSON `{findings, suppressed, summary}`, judge `fail` iff `active_p0>0`.

**Premise corrections found while grounding (the spec/meeting were slightly off):**
- The real visual judge-units are `02-prototype` / `15a-screen-atlas` / `15b-hifi-mood` (sub-units of step 15), not a top-level "15b" step — `15b-hifi-mood` IS a real judge-unit, so the reference holds; `15a` exists too and was explicitly scoped OUT.
- Brand-exception is load-bearing, not theoretical: e.g. Linear's bound accent is `#5e6ad2`/`#7170ff` (indigo-violet) — a legit brand purple. The rule must target the **exact Tailwind-default hex list**, not "any indigo", AND suppress any hex the bound `DESIGN.md` declares.
- The quality-judge is an `opus` sub-agent graded against `quality-checklist.md` criteria (stable `id` bullets per judge-unit); it does NOT run deterministic checks itself — so the check must be a separate script whose JSON the judge reads. This confirms OQ1's standalone-script answer.

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
