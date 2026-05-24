# 083 — memory-events-journal — notes

_Created 2026-05-24._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

### 2026-05-24 — parent — Accept stale-MEMORY.md drift; converge to frontmatter truth and update divergent `name:` fields in this diff

First run of `bash .claude/tools/memory-project.sh` against the current 13 entries produced a 13-line diff vs the committed `MEMORY.md` — two distinct causes:

1. **Reordering.** Current MEMORY.md was hand-ordered (visibility-intent first, then cc-platform-hooks, then recently-added entries appended). Projection sorts by filename slug under `LC_ALL=C`. Reorder is expected and is the deterministic design.

2. **Content drift.** Hand-MEMORY.md descriptions had been edited independently from the entries' `description:` frontmatter. Examples:
   - `cc-platform-hooks` frontmatter says "32 CC hook events"; hand-MEMORY still said "29".
   - `od-grounding-dogfood`, `product-pipeline-empirical-baseline`, others — hand-MEMORY descriptions were shorter/older summaries.
   - 9 of 13 entries have `name:` in kebab-case (`anthill-archived`, `forks-ephemeral-dogfood`, etc.) but hand-MEMORY rendered them as Title Case displays ("Anthill archived", "Forks are ephemeral dogfood").

The first kind (descriptions out of date) is fine — the projection brings them current; that's the whole point. The second kind (kebab `name:` would render uglier than the hand-curated displays) is a regression in user-facing quality.

**Decision:** in this same diff, update the 9 divergent entries' `name:` to match the hand-curated display so the projected `MEMORY.md` doesn't visually regress. The 082 schema treats `name:` as the canonical display label — this aligns the field with its semantic purpose retroactively.

Entries to update (slug → new display name):
- `anthill-archived` → `Anthill archived`
- `anthill-port-workflow` → `Anthill-port workflow`
- `capacity-spec-index` → `Capacity → spec index`
- `consumer-contract-discipline` → `Consumer-contract discipline`
- `forks-ephemeral-dogfood` → `Forks are ephemeral dogfood`
- `od-grounding-dogfood` → `OD grounding dogfood`
- `product-pipeline-empirical-baseline` → `/product pipeline empirical baseline`
- `propagation-hygiene` → `Propagation hygiene`
- `user-global-hooks-shadow` → `User-global hooks shadow project hooks`

4 entries already have Title-Case `name:` (`Agent0 base repo purpose`, `Claude Code platform hooks`, `Skill-eval pattern (observed externally)`, `Visibility capacity intent`) — no change.

After the `name:` updates, re-run projection. Verify zero diff against the manually-corrected MEMORY.md target.

## Deviations

_(none yet)_

## Tradeoffs

_(none yet)_

## Open questions

_(none yet — spec OQs cover the design space)_
