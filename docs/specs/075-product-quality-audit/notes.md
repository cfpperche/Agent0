# 075 — product-quality-audit — notes

_Created 2026-05-22._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention._

## Design decisions

### 2026-05-22 — parent — `## Target` schema sections renamed `## Size floor`, not column-edited

Task 2 could have surgically removed the `max_size` column from each schema's `## Target` table. Instead each `## Target (canonical size budget…)` section was replaced wholesale with a `## Size floor (anti-stub — spec 075)` section: a 2-3-column table carrying only `min_size` + a floor rationale, plus a one-line pointer to the 200 KB catastrophe cap. Rationale: the whole *framing* of `## Target` — "canonical size budget", "single source of truth for budgets" — is what spec 075 retires; a column deletion would leave the stale framing. A section replacement is cleaner and self-documents the retirement.

## Deviations

### 2026-05-22 — parent — the "15-schema sweep" was a 6-schema sweep

`plan.md` and `tasks.md` task 2 said "sweep all 15 `schema.md`". A `grep` survey showed **only 6 of the 15 carried `max_size`** — `02-prototype`, `03-spec`, `08-system-design`, `09-legal`, `10-roadmap`, `15-screen-atlas`. The other 9 schemas only ever had `min_size` floors (no ceiling to retire). So task 2 touched 6 files, not 15. No plan change needed — the outcome (no `max_size` anywhere) is identical; the count was just over-stated out of caution.

### 2026-05-22 — parent — task 1 also updated `CLAUDE.md`

`tasks.md` task 1 named only `.claude/rules/artifact-budgets.md`. But `CLAUDE.md` § Artifact budgets carried a 1-sentence summary of the `× 1.2 / × 1.8` cascade — leaving it would be a doc-vs-reality contradiction the moment the rule changed. So task 1 also rewrote that `CLAUDE.md` block (now § "Artifact size cap"). Recorded so the reviewer expects the `CLAUDE.md` diff.

### 2026-05-22 — parent — task 3 extended from cascade-strip to a full brief ceiling-scrub

`tasks.md` task 3 scoped the `delegation-briefs.md` work narrowly: strip the "Overshoot cascade" boilerplate, replace with the catastrophe-cap note. Doing it surfaced that task 2's `## Target` → `## Size floor` schema rename had orphaned **6 brief pointers** to the now-gone `schema.md § Target`, and that ~10 briefs still carried inline `"X-Y KB hard ceiling"` lines + range-based `DONE_WHEN` size checks — i.e. Move 1's "retire the ceiling instrument" goal was only half-met at the brief layer. The *enforced* instrument (cascade + schema `max_size`) was already gone after tasks 1-2, but the briefs still verbally instructed sub-agents to hit a ceiling — the exact trimming pressure spec 075 exists to kill. The user (2026-05-22) chose the full scrub over fix-pointers-only / defer. Task 3 therefore also: retargeted the 6 `§ Target` pointers → `§ Size floor`; replaced inline ceilings → `≥ N KB` anti-stub floors; rewrote `DONE_WHEN` size clauses → floor-only. ~35 edits total, not the ~17 the plan implied. No `plan.md` rewrite needed — the outcome still matches Move 1's stated intent ("retire the ceiling instrument"); the plan just understated the brief-layer edit count. Two `size targets` cross-pointers into `pipeline-coverage.md` stay for task 4 (it owns that file).

## Tradeoffs

_None surfaced beyond those weighed at plan time._

## Open questions

_None open — the four `spec.md` open questions were resolved 2026-05-22 before `plan.md` locked._
