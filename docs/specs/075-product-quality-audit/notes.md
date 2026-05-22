# 075 — product-quality-audit — notes

_Created 2026-05-22._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention._

## Design decisions

### 2026-05-22 — parent — `## Target` schema sections renamed `## Size floor`, not column-edited

Task 2 could have surgically removed the `max_size` column from each schema's `## Target` table. Instead each `## Target (canonical size budget…)` section was replaced wholesale with a `## Size floor (anti-stub — spec 075)` section: a 2-3-column table carrying only `min_size` + a floor rationale, plus a one-line pointer to the 200 KB catastrophe cap. Rationale: the whole *framing* of `## Target` — "canonical size budget", "single source of truth for budgets" — is what spec 075 retires; a column deletion would leave the stale framing. A section replacement is cleaner and self-documents the retirement.

### 2026-05-22 — parent — quality-judge verdict JSON shape (task 5)

The judge returns one verdict object per **judge-unit** (steps 01-14 = the step; Step 15 splits into `15a-screen-atlas` / `15b-hifi-mood` / `15c-fixture-spec`, judged separately — they already carry separate gates per `quality-checklist.md § 2`). Shape:

```json
{
  "step": "08-system-design",
  "judged_at": "2026-05-22T16:40:00Z",
  "model": "opus",
  "criteria": [
    { "id": "structure",    "verdict": "pass",    "note": "all 8 required H2 present incl RACI + Risk Register" },
    { "id": "completeness", "verdict": "pass",    "note": "data-flow.json has 5 flows; security.md present" },
    { "id": "right-sizing", "verdict": "concern", "note": "§ Risk Register restates the security.md threat model — ~2 KB duplication" }
  ],
  "scope_assessment": "Correctly scoped for a full multi-phase ERP; the lone concern is internal duplication, not over-scope.",
  "outcome": "concern"
}
```

- `criteria[]` — one row per assembled rubric criterion. `id` is the criterion's stable label (task 6/7 fix the canonical per-step set; `quality-checklist.md` criteria are currently prose clauses without IDs). `verdict` ∈ `pass | concern | fail`. `note` is the one-line actionable rationale — on a `concern`/`fail` it MUST name the section + dimension (the signal `oversize_reason` aimed at; spec.md acceptance criterion 3).
- `right-sizing` is **one of the `criteria[]` rows**, not a special top-level field — it carries the scope-aware, anti-verbosity grade (spec.md criteria 2/3).
- `scope_assessment` — top-level one-liner; the human-readable headline for `REPORT.md § Quality concerns` and the gate summary. Distinct from the `right-sizing` criterion: that criterion grades per-section bloat, `scope_assessment` is the whole-artifact scope-fit headline. This field is spec.md acceptance criterion 1's "**plus** a one-line scope assessment".
- `model` — the judge model actually used (`opus` default; `sonnet` is the documented cost knob). Recorded so post-hoc analysis can separate opus from sonnet verdicts.
- `outcome` — max-severity rollup of `criteria[]`: `fail` if any criterion `fail`, else `concern` if any `concern`, else `pass`. Pre-computed so `SKILL.md`'s routing (task 9) keys on one field. Only `outcome: fail` routes (gate `iterate` pre-population / Phase 4 handoff flag); `concern` is surfaced in REPORT.md but takes no gate action. Routing is a **global rule** — any `fail` routes — per the spec.md open-question resolution ("Marking is a global rule … not per-step checkboxes"); the § Intent "load-bearing criterion" phrasing is the superseded draft framing, so the shape needs no per-criterion load-bearing marker.

### 2026-05-22 — parent — `.state.json` `quality_verdicts` field; v5-additive, NO version bump (task 5)

New field on `.state.json`:

```json
"quality_verdicts": {
  "01-ideation": { "...verdict object..." },
  "08-system-design": { "...verdict object..." }
}
```

A **map keyed by judge-unit label → verdict object** (shape above). Map, not array: a re-dispatched step (gate `iterate`) overwrites its key idempotently; a missing key = "not judged yet". Phase 0 inits it `{}`.

**Decision: stay on `version: 5` — additive, NO bump to v6.** This resolves the plan.md § Risks v5-additive-vs-v6 question, decided against `state-machine.md`:

- The resume version-gate (`state-machine.md` line 151) is **strict refuse-all-non-5** and does **no field-level migration** — it accepts a v5 file wholesale or aborts. A version bump is therefore *expensive*: bumping to v6 would make the gate **refuse every existing v5 state file**, force-aborting any `/product` run started before 075 ships and resumed after — for a change that needs no migration.
- `quality_verdicts` is **purely additive and back-compatible both directions**: a pre-075 orchestrator ignores the unknown key; a post-075 orchestrator treats an absent key as `{}`. It is **never a resume-control input** — resume trusts `completed_steps`, not verdicts — so there is zero mis-orchestration risk across the change.
- The v4→v5 precedent is decisive: `state-machine.md` line 53 states v4→v5 was bumped for a **behavioral** Phase-4/5 break and was *explicitly "not a field-shape change"*. So the version's *real* bump-rule, as practiced, is **"bump when a resume across the change would mis-orchestrate"** — not "bump on any field touch". An additive ignore-if-absent field does not meet that bar.
- Line 48's literal wording — "Increments when shape changes" — contradicts that practiced rule and would mislead the next maintainer. **Task 10 will reword line 48** to: *increments when a resume across the change would mis-orchestrate (a behavioral phase/step break, or a non-back-compatible field change); a purely additive field an older reader can ignore and a newer reader can treat as absent does NOT bump.* `quality_verdicts` becomes the worked example of the non-bumping case.

Follow-on for task 10: add `quality_verdicts` to the documented v5 shape; reword the line-48 bump-rule; document the verdict→gate routing.

## Deviations

### 2026-05-22 — parent — the "15-schema sweep" was a 6-schema sweep

`plan.md` and `tasks.md` task 2 said "sweep all 15 `schema.md`". A `grep` survey showed **only 6 of the 15 carried `max_size`** — `02-prototype`, `03-spec`, `08-system-design`, `09-legal`, `10-roadmap`, `15-screen-atlas`. The other 9 schemas only ever had `min_size` floors (no ceiling to retire). So task 2 touched 6 files, not 15. No plan change needed — the outcome (no `max_size` anywhere) is identical; the count was just over-stated out of caution.

### 2026-05-22 — parent — task 1 also updated `CLAUDE.md`

`tasks.md` task 1 named only `.claude/rules/artifact-budgets.md`. But `CLAUDE.md` § Artifact budgets carried a 1-sentence summary of the `× 1.2 / × 1.8` cascade — leaving it would be a doc-vs-reality contradiction the moment the rule changed. So task 1 also rewrote that `CLAUDE.md` block (now § "Artifact size cap"). Recorded so the reviewer expects the `CLAUDE.md` diff.

### 2026-05-22 — parent — task 3 extended from cascade-strip to a full brief ceiling-scrub

`tasks.md` task 3 scoped the `delegation-briefs.md` work narrowly: strip the "Overshoot cascade" boilerplate, replace with the catastrophe-cap note. Doing it surfaced that task 2's `## Target` → `## Size floor` schema rename had orphaned **6 brief pointers** to the now-gone `schema.md § Target`, and that ~10 briefs still carried inline `"X-Y KB hard ceiling"` lines + range-based `DONE_WHEN` size checks — i.e. Move 1's "retire the ceiling instrument" goal was only half-met at the brief layer. The *enforced* instrument (cascade + schema `max_size`) was already gone after tasks 1-2, but the briefs still verbally instructed sub-agents to hit a ceiling — the exact trimming pressure spec 075 exists to kill. The user (2026-05-22) chose the full scrub over fix-pointers-only / defer. Task 3 therefore also: retargeted the 6 `§ Target` pointers → `§ Size floor`; replaced inline ceilings → `≥ N KB` anti-stub floors; rewrote `DONE_WHEN` size clauses → floor-only. ~35 edits total, not the ~17 the plan implied. No `plan.md` rewrite needed — the outcome still matches Move 1's stated intent ("retire the ceiling instrument"); the plan just understated the brief-layer edit count. Two `size targets` cross-pointers into `pipeline-coverage.md` stay for task 4 (it owns that file).

### 2026-05-22 — parent — task 12 verification found Move 1's schema sweep was incomplete — 3 schemas fixed

`tasks.md` task 12 is a verification step ("grep all 15 `schema.md` — confirm no stale `max_size` ceiling"). It found a real defect: **3 schemas — `06-ost`, `07-sitemap-ia`, `12-gtm-launch` — still carried a hard size ceiling.** Move 1 task 2 swept for the literal `max_size` JSON token and found 6 schemas; it missed these 3 because they expressed the ceiling as **prose** — a `## Size targets` section with `Floor:` *and* `Ceiling: N KB hard` lines (plus retired "trim to Backlog / push to PRD" language) + a `File size N-M KB` validation rule. The `grep max_size` never matched them.

Fix (done here, inside task 12 — a verification task that uncovers a defect must fix it; the spec's acceptance criterion "each schema's `max_size` ceiling is removed" is otherwise not met): each `## Size targets` section → a `## Size floor (anti-stub — spec 075)` section in the canonical Move-1 format (the spec-075 explanation + a `| Artifact | min_size floor | rationale |` table + the 200 KB catastrophe-cap line); the `Ceiling:` lines dropped; the `File size N-M KB` validation rules → `≥ N KB` floor-only. `pipeline-coverage.md`'s "Canonical source" column for these 3 rows was `(legacy)` (correct at task-4 time — no `§ Size floor` section existed then); now retargeted to `<step>/schema.md § Size floor ✓ 075`.

Lesson for any future ceiling-scrub: grep the *prose* (`Ceiling`, `Size targets`, `N-M KB`), not just the JSON token. Net outcome unchanged — all 15 schemas now carry a floor and zero ceilings.

## Tradeoffs

_None surfaced beyond those weighed at plan time._

## Open questions

_None open — the four `spec.md` open questions were resolved 2026-05-22 before `plan.md` locked._
