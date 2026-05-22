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

## Tradeoffs

_None surfaced beyond those weighed at plan time._

## Open questions

_None open — the four `spec.md` open questions were resolved 2026-05-22 before `plan.md` locked._
