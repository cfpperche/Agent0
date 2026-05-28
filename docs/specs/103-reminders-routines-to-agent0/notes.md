# 103 — reminders-routines-to-agent0 — notes

_Created 2026-05-28._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — what was ambiguous, what was decided, why}}

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

### 2026-05-28 — parent — grep guard caught 4 files outside the planned list

`plan.md` § Files to touch enumerated the shipped-surface files from the pre-flight grep. The post-rewrite grep guard surfaced 4 more tracked files with stale path stems that the enumerated list missed: the two relocated routine *definitions* (`.agent0/routines/{hook-chain-bench,cc-platform-audit}.md` — self-referencing their own state path), and two project-memory files (`.agent0/memory/{bertolini-dogfood-loop,hook-chain-latency}.md`), plus `.claude/skills/image/references/tier-pricing.md`. All fixed with the same sed stems. Lesson: the guard must run repo-wide, not just over the planned list — the plan list is a starting point, not the closure set.

### 2026-05-28 — parent — fixture 01 needed an explicit `.agent0` mkdir

`01-reminders-fixture.sh` created only `$TMPDIR/.claude/skills/...` (the helper still lives under `.claude/skills/`, correctly), then wrote the data to `$TMPDIR/.agent0/reminders.yaml`. The sed repointed the write target but no `mkdir -p "$TMPDIR/.agent0"` existed, so the redirect failed. Added the mkdir. Fixtures 02/04 were unaffected (their mkdir lists contained `.claude/routines`, which sed rewrote to `.agent0/routines`, creating `.agent0` as a side effect).

### 2026-05-28 — parent — also completed a pre-existing harness-sync doc gap

`harness-sync.md` § Manifest scope prose-listed COPY_CHECK_FILES but already omitted `.claude/routines/.gitkeep` (pre-existing doc/script drift). Rather than carry the stale omission, added `.agent0/routines/.gitkeep` to the prose list while documenting the capacity-only relocation posture (task 15).

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — options considered in-flight, chosen path, accepted cost}}

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — the question, why it surfaced, what's blocked on it, who can decide}}
