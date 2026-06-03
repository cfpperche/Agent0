# {{NNN}} — {{SLUG}} — notes

_Created {{DATE}}._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.agent0/context/rules/spec-driven.md` § The four artifacts for purpose, and `.agent0/context/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-06-03 — parent — consumer-side OD cache is out of harness scope (vindicates the fix)

Live verification against consumer `tese` revealed its sync baseline (716 entries) records **zero** `extracted-*` paths, yet `extracted-c128ffd5…/` exists on tese's disk. So that cache was placed by tese's **own** OD-engine run (the prior session's fix-forward), not propagated by sync-harness. After this fix the harness never walks, checks, or records it — and the deletion pass correctly finds no harness-recorded cache orphan to remove on tese. This is the intended end-state: the consumer's gitignored OD runtime cache is the OD-engine's concern, fully invisible to the harness. The cleanup-summary path (for consumers whose *baseline* did record over-propagated cache) is exercised by fixture test 39 sub-test C rather than by a live consumer, because no reachable consumer happens to carry baseline-recorded cache.

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

### 2026-06-03 — parent — `set -e` errexit trap in the advisory helper (build-time bug, fixed)

First implementation had `advise_dirty_once()` use guard-clauses `[ cond ] || return`. Under the script's `set -euo pipefail`, when `AGENT0_GIT_SOURCE=0` the `[ "$AGENT0_GIT_SOURCE" -eq 1 ] || return` ran `return` whose status was the failed test (1), so the function returned non-zero. Called as a bare statement in `walk_copy_check`, that tripped errexit and **aborted the walk before the for-loop** — silently producing an empty manifest. It only surfaced in the non-git path (test 40), because the git path set the flag to 1 and dodged the bad branch (test 39 passed, masking it). Fix: rewrote the helper with a positive `if` block and an explicit `return 0`. Lesson for the suite: the existing 38 tests all used plain-dir SRCs, which now exercise the non-git fallback — they kept passing, so the abort was specific to a fresh non-git scenario with content to walk.

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — options considered in-flight, chosen path, accepted cost}}

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — the question, why it surfaced, what's blocked on it, who can decide}}
