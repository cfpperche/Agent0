# 117 — remove-hook-chain-latency — notes

_Created 2026-05-29._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

### 2026-05-29 — parent — Crontab cleanup: surgical line-removal, not `install-routines.sh` re-run

The HANDOFF suggested re-running `install-routines.sh` to drop the dangling `hook-chain-bench` entry. Chose the surgical `crontab -l | grep -v 'run-routine.sh hook-chain-bench' | crontab -` instead. Two reasons: (1) `install-routines.sh` is interactive (leader-designation prompt), awkward mid-implementation; (2) the installed block carries a *pre-existing, independent* defect — stale `.claude/tools/run-routine.sh` paths (routines moved to `.agent0/` in spec 103/105 but the crontab was never regenerated). A full re-install would silently repair that too, conflating two unrelated changes in one removal PR. The surgical edit removes exactly the in-scope line and leaves the pre-existing condition visible (see Open questions).

### 2026-05-29 — parent — KEEP the two `memory-placement.md` spec-096 mentions

`memory-placement.md:57` and `:247` reference `hook-chain-latency.md` as the canonical `move-full` disposition example from the 2026-05-27 spec-096 audit. Applied the spec-115 keep-vs-rewire test: *describes a past event still true → keep; describes live wiring of the deleted capacity → rewire*. These describe a historical rule→memory move (still-true history), not live wiring. Decisive precedent: those same two lines already cite `compaction-continuity.md` and `rule-load-debug.md` — removed in specs 114/115 — and both of those removal specs KEPT the lines. Consistency demands the same disposition here.

### 2026-05-29 — parent — `capacity-spec-index.md` untouched (no row existed)

HANDOFF anticipated a "Hook chain latency" row to remove. A full read of the file found none — the capacity was maintainer-internal memory, never a fork-propagated rule/capacity, so it was never indexed. Adding a "removed" annotation row would be noise (nothing to annotate). Left untouched.

## Deviations

_None. Execution followed plan.md exactly._

## Tradeoffs

_None surfaced in-flight beyond the design decisions above._

## Open questions

### 2026-05-29 — parent — Pre-existing stale crontab paths (out of scope, flagged for routines capacity)

The installed `AGENT0-ROUTINES` crontab block still points `cc-platform-audit` at `/home/goat/Agent0/.claude/tools/run-routine.sh` and `.claude/.routines-state/`, both relocated to `.agent0/` by specs 103/105. This means `cc-platform-audit`'s monthly cron likely fails silently (missing script path). This is independent of the hook-chain-latency removal and was deliberately NOT bundled. Owner: whoever next touches the routines capacity — fix is one `bash .agent0/tools/install-routines.sh` re-run (regenerates the block from `.agent0/routines/*.md` with correct paths). Worth a `/remind` if not addressed soon.
