# 077 — product-validation-framing — tasks

_Generated from `plan.md` on 2026-05-22. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. Flip `docs/specs/077-product-validation-framing/spec.md` `**Status:** draft` → `in-progress`.
- [x] 2. `git mv .claude/skills/product/templates/pipeline/04-ux-testing .claude/skills/product/templates/pipeline/04-validation` — history-preserving directory rename (carries `prompt.md`, `schema.md`, `references/*`). Must run before tasks 7–8.
- [x] 3. **A2 — display name sweep** (`UX Testing` / `UX testing` → `Validation`) at 6 sites: `04-validation/prompt.md` line ~7 title; `templates/report.md.tmpl` line 14 table cell; `references/quality-checklist.md` line 34 heading (keep the `### 04 — ` prefix byte-identical); `references/pipeline-coverage.md` lines 38 + 62; `references/delegation-briefs.md` line 93; `scripts/build-report.ts` line ~63 `title: 'UX testing'` (leave `id`/`step` `'04'`).
- [x] 4. **A3 — path slug sweep** (`04-ux-testing` → `04-validation`) at 6 sites: `references/state-machine.md` line 30; `references/pipeline-coverage.md` line 13; `references/delegation-briefs.md` line 100; `14-design-system/references/audit-response.md` line 3; `14-design-system/prompt.md` line 162; the residual `ux-testing` string in `04-validation/references/report-template.md`.
- [x] 5. **A4 — inline parenthetical sweep** (`(ux-testing)` / `ux-testing` label → `(validation)` / `validation`) at 8 sites: `01-ideation/prompt.md` line 188; `02-prototype/prompt.md` line 356; `03-spec/prompt.md` lines 86 + 124; `03-spec/references/functional-spec-template.md` line 10; `09-legal/prompt.md` line 170; `10-roadmap/prompt.md` lines 240 + 281; `14-design-system/references/section-floor.md` line 42.
- [x] 6. **B1 — 15b contrast criterion.** In `references/quality-checklist.md` under `### 15b — Hi-fi killer-flow mood`, add a criterion bullet with stable `id: contrast` — body/large text + interactive UI meet WCAG 2.1 AA contrast (4.5:1 body, 3:1 large text + UI components) against the screen's own `:root` token values; below-AA is a `fail`; name it the shift-right verification of step 4's projected-mode `warn` handoffs.
- [x] 7. **B2 — step-4 handoff paragraph.** In `04-validation/prompt.md` § "How to conduct this step" step 4 (the markdown-spec / projected-mode branch), correct the stale `verify in step 7` example rationale and the "tracked handoff" sentence to name step 15b's contrast judge as the shift-right verifier.

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria. Each maps to a checklist item there._

- [x] 8. **No residue** — `grep -rIn "04-ux-testing" .claude/skills/product/ | grep -v vendor/` returns empty, and `grep -rIne "UX Testing|UX testing" .claude/skills/product/ | grep -v vendor/` returns empty (spec acceptance criterion 7 + scenario 1). Then `grep -rIn "04-ux-testing\|UX Testing" .claude/` outside `docs/specs/` — confirm the only hits are `.claude/memory/anthill-archived.md` (the *anthill* skill, untouched).
- [x] 9. **Vocabulary consistency** — inspect the renamed step's display name, directory, judge-unit label, artifact filename, state field, section heading, regex line: all read "validation"; no holdout (spec scenario 2).
- [x] 10. **15b criterion present** — `references/quality-checklist.md § 15b` carries the `contrast` criterion with a stable `id` (spec scenario 4 + the `quality-checklist.md` plain criterion); `04-validation/prompt.md` projected-mode paragraph names step 15b as the verifier (spec criterion 6).
- [x] 11. **Tests green** — run the `build-report.test.ts` suite; it must stay 25/25 (baseline per `SESSION.md`). Confirms the `build-report.ts` title rename is non-breaking.
- [x] 12. **End-to-end run** — a `/product` invocation through Phase 1 (or a representative `--from-step` resume across step 4): step 4 dispatches, submits `validation-report.md`, `validation_mode` extracts into `.state.json`, the Discovery gate fires, no path/label resolves to a stale `04-ux-testing` (spec scenario 3). Heavy — may be paired with the pending "069 live validation" / "075 task 14" dogfood runs against `/home/goat/mei-saas`.
- [x] 13. **Close** — tick all `spec.md § Acceptance criteria` boxes that pass; flip `spec.md` `**Status:** in-progress` → `shipped`.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._

- Append in-flight decisions / deviations / tradeoffs / open-questions to `docs/specs/077-product-validation-framing/notes.md` as they surface (per `.claude/rules/spec-driven.md` § The four artifacts).
- Task 12 (end-to-end run) is the only heavy task — if a full `/product` run is not run immediately, scenario 3 stays unticked and the spec stays `in-progress` until a dogfood covers it; tasks 1–11 + 13-minus-scenario-3 can otherwise complete independently.
