# 077 — product-validation-framing

_Created 2026-05-22._

**Status:** shipped

## Intent

Step 4 of the `/product` pipeline is named **"UX Testing"**, but the name describes neither what the step does nor what it is for. The step does two jobs: an **expert heuristic audit** (Nielsen 10 + WCAG 2.1 AA, severity-rated findings) that runs every time, and a **validation-posture declaration** (`validation_mode` ∈ `tested`/`intuition`/`not-applicable`, plus a `PROCEED/PIVOT/KILL` verdict that feeds the Discovery gate). The name is a fossil: it was inherited from the archived `anthill-ux-audit` skill, which was audit-only; spec 025 bolted the three-mode validation posture and the verdict on top, and the name never grew with the scope. It is also wrong on a second count — "Testing" overpromises: real user testing happens only in the rare `tested` branch, while the default is expert *evaluation*. The strongest evidence is internal: the step's own outputs already say "validation" four times — the artifact `validation-report.md`, the state field `.state.json.validation_mode`, the section `## Validation Mode`, the regex-extracted `validation_mode:` line — and the step *name* is the lone holdout.

The same discussion (2026-05-22) that surfaced the naming problem also surfaced an audit-loop gap. Step 4's accessibility review is **shift-left only**: it audits the lo-fi step-2 prototype, where real tokens do not yet exist, so contrast checks are mostly *projected* (`warn`, deferred as handoffs to steps 14/15). Nothing **shift-right** re-verifies the rendered output: step 15b (hi-fi killer-flow mood) is the first surface where real tokens render, yet its quality rubric (`quality-checklist.md § 15b`) carries no accessibility criterion. The projected `warn` handoffs are never confirmed closed.

This spec does two things: **(A)** renames step 4 "UX Testing" → "Validation" so the step name matches its job and its own vocabulary; **(B)** adds a WCAG 2.1 AA contrast criterion to step 15b's quality rubric so the hi-fi mood is actually audited — closing the loop step 4 opens. The step is **not** split: the audit and the gate-recommendation are correctly co-located (the audit informs the verdict; both feed one gate) — only the name is wrong.

## Acceptance criteria

- [x] **Scenario: step 4 reads as "Validation" wherever a step name is displayed**
  - **Given** the `/product` skill templates and references
  - **When** an agent or user reads any display of step 4's name — the `pipeline-coverage.md` phase map, `04-*/prompt.md` title, `delegation-briefs.md`, `quality-checklist.md`, the report templates, `SKILL.md`
  - **Then** it reads "Validation", never "UX Testing"

- [x] **Scenario: step 4's vocabulary is internally consistent**
  - **Given** the renamed step
  - **When** you inspect the step's display name, its directory, its judge-unit/step label, its artifact filename, its state field, its section heading, and its regex line
  - **Then** all of them use "validation" — no component is a holdout reading "ux-testing" / "UX Testing"

- [x] **Scenario: a `/product` run still completes through Phase 1 after the rename**
  - **Given** the renamed step 4
  - **When** `/product` advances through Phase 1 (or a representative resume/advance across step 4)
  - **Then** step 4 dispatches, submits `validation-report.md`, `validation_mode` extracts into `.state.json`, and the Discovery gate fires — no path, label, or manifest entry resolves to a stale `04-ux-testing` / "UX Testing"

- [x] **Scenario: the hi-fi mood is audited for contrast**
  - **Given** a `/product` run reaching step 15b (hi-fi killer-flow mood)
  - **When** the `15b-hifi-mood` quality judge grades the rendered screens against its assembled rubric
  - **Then** the rubric includes a WCAG 2.1 AA contrast criterion, and a screen shipping body/UI text below AA contrast yields a `concern`/`fail` that surfaces in the Phase 5 terminal handoff message and `REPORT.md § Quality concerns`

- [x] `quality-checklist.md § 15b — Hi-fi killer-flow mood` carries the new contrast criterion with a stable `id`.

- [x] Step 4's projected-mode handoff paragraph names step 15b's contrast judge as the shift-right verifier, correcting the stale "verify in step 7" wording in that one paragraph.

- [x] No stale `UX Testing` display string and no stale `04-ux-testing` path reference remains in `.claude/skills/product/`, excluding the vendored `vendor/open-design/` tree and historical `docs/specs/`.

## Non-goals

- **Splitting step 4 into two steps** (audit vs. gate-decision). Co-location is correct — the audit informs the verdict and both feed one gate; spec 066 deliberately killed redundant mid-steps. Only the name is wrong.
- **A hard gate or a Phase 4 gate for the 15b contrast criterion.** It stays an advisory judge criterion: a `fail` surfaces at the terminal handoff, it never BLOCKs (consistent with `quality-judge.md` — the judge never autonomously blocks).
- **Traceability cross-referencing.** The 15b criterion is a plain WCAG-contrast check, NOT a machine cross-reference of step 4's `findings[]` `fix_skill_hint: screen-atlas` rows against the rendered screens. That stronger loop closure is deferred.
- **A blanket fix of every stale step-number cross-reference** inside step 4's templates (leftover "step 6" / "step 7" meaning the current steps 14 / 15). Only the one handoff paragraph touched by concern B is corrected here; the rest is a separate cleanup.
- **Renaming the artifact `validation-report.md` or the `validation_mode` field.** Those already say "validation" — they are the target the step name is being aligned *to*.
- **Touching the vendored `vendor/open-design/` tree.**

## Open questions

- [x] **OQ1 — Rename the step directory too, or display name only?** **Resolved 2026-05-22 (founder): full rename — all three.** The directory `templates/pipeline/04-ux-testing/` → `04-validation/`, the judge-unit/step label `04-ux-testing` → `04-validation`, and the display name "UX Testing" → "Validation" all move together. A display-only rename was rejected: it would leave the directory slug as a *new* lone holdout, reintroducing the self-discord this spec exists to kill. `/product` runs are ephemeral (no long-lived `.state.json` survives the rename), so the step-id change carries no migration cost; the accepted price is the wider blast radius — every `04-ux-testing` path reference moves.

## Context / references

- Discussion 2026-05-22 (this session) — the two-angle analysis of step 4: the name conflates audit + gate-recommendation, and the audit is shift-left with no shift-right verification.
- `.claude/skills/product/templates/pipeline/04-ux-testing/{prompt,schema}.md` — the step being renamed.
- `.claude/skills/product/references/quality-checklist.md` § 15b — where concern B's criterion lands.
- `.claude/skills/product/references/quality-judge.md` — judge-unit `15b-hifi-mood`; verdict routing (Phase 4 has no gate → a `fail` surfaces in the terminal handoff + `REPORT.md`).
- `.claude/skills/product/references/pipeline-coverage.md` — the phase↔step map; the rename's primary display surface.
- spec 025 — introduced the three-mode validation posture + verdict: the scope expansion the "UX Testing" name never tracked.
- spec 045 — `/prototype` pipeline realign; the screen-atlas absorbed the old step 7 (origin of the stale "step 7" cross-references).
- spec 066 — Phase 4 = visual contract; step 15b = hi-fi killer-flow mood.
- spec 075 — the quality judge that grades `quality-checklist.md` criteria per judge-unit.
- `.claude/memory/anthill-archived.md` — the archived `anthill-ux-audit` skill: the origin of the "UX Testing" name.
