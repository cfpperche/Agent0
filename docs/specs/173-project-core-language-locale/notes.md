# 173 - project-core-language-locale - notes

_Created 2026-06-08._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.agent0/context/rules/spec-driven.md` § The four artifacts for purpose, and `.agent0/context/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

### 2026-06-08 — parent — Reuse project-core instead of a new language channel

Language/locale is always-on project framing, so the existing `.agent0/project-core.md` mirror is a better fit than reintroducing prompt-time context injection or adding duplicated manual sections to both entrypoints.

## Deviations

### 2026-06-08 — parent — Runtime capabilities row updated

The plan initially named `language.md` and `harness-sync.md` only for documentation updates. Implementation also updated `runtime-capabilities.md` because project-core language/locale is now an explicit shared customization/sync surface.

## Tradeoffs

## Open questions
