# 077 — product-validation-framing — plan

_Drafted from `spec.md` on 2026-05-22. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Two independent concerns, done in order **A then B** (B's prompt edit lands inside the directory A renames, so the `git mv` must run first).

**Concern A — rename step 4 "UX Testing" → "Validation" (all three: directory, label, display).** This is mechanical but wide. Sequence: (1) `git mv` the step directory `templates/pipeline/04-ux-testing/` → `04-validation/` so the rename is one history-preserving move; (2) sweep the *display name* "UX Testing" / "UX testing" → "Validation" at its 6 sites; (3) sweep the *path slug* `04-ux-testing` → `04-validation` at its reference sites; (4) sweep the inline `(ux-testing)` parenthetical label → `(validation)` at its 8 prose sites; (5) a verification grep proves zero residue. The edits are **targeted per enumerated occurrence, not a blind tree-wide `sed`** — `ux-testing` is distinctive but `validation` collides with the step's already-correct `validation-report.md` / `validation_mode` vocabulary, so a blind substitution risks corrupting strings that are already right. The orchestrator (`SKILL.md`) needs **no edit**: it refers to step 4 only by number ("Step 04") and resolves the directory via the `{{step_label}}` / `<NN-step>` token derived from the `templates/pipeline/` listing — renaming the directory auto-propagates the label. The lone literal `04-ux-testing` strings are in reference *examples* and *cross-references*, all enumerated below.

**Concern B — close the audit loop with a 15b contrast criterion.** Step 4's accessibility review is shift-left (it audits the pre-token lo-fi prototype, so contrast is mostly *projected*); nothing shift-right re-verifies the rendered hi-fi output. Fix: add a `contrast` criterion to `quality-checklist.md § 15b — Hi-fi killer-flow mood` — the first surface where real tokens render. The `15b-hifi-mood` quality judge already assembles its rubric from that section (`quality-judge.md § Rubric assembly`), so the criterion is *automatically* graded with no orchestrator or state-machine change; a `fail` surfaces in the Phase 5 terminal handoff + `REPORT.md § Quality concerns` (Phase 4 has no gate — `quality-judge.md` line 103). Then correct step 4's projected-mode handoff paragraph so its stale "verify in step 7" wording names step 15b's contrast judge as the verifier. The 15b *producer* brief is deliberately left untouched — concern B is scoped to the judge rubric (matching spec acceptance criteria 4–5); nudging the producer toward AA is a possible follow-up, not this spec.

No `.state.json` version bump: `quality_verdicts` already grades whatever `quality-checklist.md` contains (v5-additive per spec 075), and the step-label change rides the existing v5 shape.

## Files to touch

**Rename (git mv — history-preserving):**
- `.claude/skills/product/templates/pipeline/04-ux-testing/` → `.../04-validation/` — whole subtree (`prompt.md`, `schema.md`, `references/{anti-patterns,checklist,examples,heuristics,report-template}.md`).

**Modify — A2, display name "UX Testing" / "UX testing" → "Validation":**
- `.claude/skills/product/templates/pipeline/04-validation/prompt.md` (post-move) — line ~7 title `# Step 4 — UX Testing` → `# Step 4 — Validation`.
- `.claude/skills/product/templates/report.md.tmpl` — line 14 table cell `| 04 | UX Testing |` → `| 04 | Validation |`.
- `.claude/skills/product/references/quality-checklist.md` — line 34 heading `### 04 — UX Testing` → `### 04 — Validation`. **Keep the `### 04 — ` prefix exact** — it is the `{{rubric_section}}` anchor the judge dispatch resolves by step number.
- `.claude/skills/product/references/pipeline-coverage.md` — line 38 table row `| 04 | UX Testing |` → `Validation`; line 62 lightening item `4. **04 UX Testing:**` → `4. **04 Validation:**`.
- `.claude/skills/product/references/delegation-briefs.md` — line 93 `### Step 04 — UX Testing (heuristic audit)` → `### Step 04 — Validation (heuristic audit)`.
- `.claude/skills/product/scripts/build-report.ts` — line ~63 `title: 'UX testing'` → `title: 'Validation'` (the `ARTIFACT_MANIFEST` entry; `id`/`step` stay `'04'`).

**Modify — A3, path slug `04-ux-testing` → `04-validation`:**
- `.claude/skills/product/references/state-machine.md` — line 30 `"04-ux-testing"` in the `completed_steps` example array.
- `.claude/skills/product/references/pipeline-coverage.md` — line 13 phase-map cell `04-ux-testing`.
- `.claude/skills/product/references/delegation-briefs.md` — line 100 `templates/pipeline/04-ux-testing/prompt.md + schema.md` in the Step-04 brief CONTEXT.
- `.claude/skills/product/templates/pipeline/14-design-system/references/audit-response.md` — line 3 `04-ux-testing/schema.md`.
- `.claude/skills/product/templates/pipeline/14-design-system/prompt.md` — line 162 `04-ux-testing/schema.md`.
- `.claude/skills/product/templates/pipeline/04-validation/references/report-template.md` (post-move) — residual `ux-testing` string in its own content.

**Modify — A4, inline `(ux-testing)` parenthetical label → `(validation)`:**
- `.claude/skills/product/templates/pipeline/01-ideation/prompt.md` — line 188.
- `.claude/skills/product/templates/pipeline/02-prototype/prompt.md` — line 356.
- `.claude/skills/product/templates/pipeline/03-spec/prompt.md` — lines 86, 124.
- `.claude/skills/product/templates/pipeline/03-spec/references/functional-spec-template.md` — line 10.
- `.claude/skills/product/templates/pipeline/09-legal/prompt.md` — line 170.
- `.claude/skills/product/templates/pipeline/10-roadmap/prompt.md` — lines 240, 281.
- `.claude/skills/product/templates/pipeline/14-design-system/references/section-floor.md` — line 42 (`step-4 ux-testing` → `step-4 validation`).

**Modify — B, the 15b criterion + the step-4 handoff paragraph:**
- `.claude/skills/product/references/quality-checklist.md` — under `### 15b — Hi-fi killer-flow mood`, add a new criterion bullet `- **contrast** — …` (stable `id: contrast`).
- `.claude/skills/product/templates/pipeline/04-validation/prompt.md` (post-move) — § "How to conduct this step" step 4, the markdown-spec / projected-mode branch: correct the stale `verify in step 7` example rationale and the "tracked handoff" sentence to name step 15b's contrast judge as the shift-right verifier.

**Modify — spec bookkeeping:**
- `docs/specs/077-product-validation-framing/spec.md` — flip `**Status:** draft` → `in-progress` at implementation start, `shipped` when acceptance is met.

**No edit (verified):** `.claude/skills/product/SKILL.md` — refers to step 4 by number only; `04-ux-testing` literal absent.

## Alternatives considered

### Display-name-only rename (leave `04-ux-testing/` directory + label)

Rejected — this was **OQ1, resolved by the founder 2026-05-22 to full rename**. A display-only rename leaves the directory slug `04-ux-testing` as a *new* lone holdout, reintroducing the exact self-discord the spec exists to kill. `/product` runs are ephemeral, so the step-id change carries no migration cost; the accepted price is the wider blast radius enumerated above.

### Splitting step 4 into 4a (audit) + 4b (gate-decision)

Rejected — co-location is correct. The audit *informs* the verdict (a sev-4 count is what makes `PROCEED` defensable or not) and both feed one gate; spec 066 deliberately killed redundant mid-steps. The step's job is coherent — "review the Discovery output, recommend to the gate" — only its *name* misdescribes that job. (Spec § Non-goals.)

### Blind tree-wide `sed 's/ux-testing/validation/'`

Rejected — faster but unsafe. `validation` already appears correctly across step 4's vocabulary (`validation-report.md`, `validation_mode`, `## Validation Mode`); a blind substitution cannot corrupt those (the search term is `ux-testing`), but the *inverse* risk is real for the display-name sweep ("UX Testing" as a phrase appears in historical specs and the `anthill-ux-audit` discussion that must NOT change). Targeted per-occurrence edits + a final verification grep is the safer shape for a rename whose correct/incorrect occurrences are interleaved.

### The stronger traceability loop-closure for concern B

Rejected for v1 — a machine cross-reference of step 4's `findings[]` `fix_skill_hint: screen-atlas` rows against the rendered 15b screens would be the "true" loop closure, but it is heavier, depends on step 4 having emitted measurable-mode frontmatter, and the plain WCAG-contrast criterion already catches the actual defect (un-accessible rendered output). Deferred. (Spec § Non-goals.)

## Risks and unknowns

- **Undiscovered hardcoded `04-ux-testing` literal.** The orchestrator resolves the step directory via the `{{step_label}}`/`<NN-step>` token (derived from the `templates/pipeline/` listing), so the rename should auto-propagate — but if some script hardcodes the literal `04-ux-testing`, it breaks silently. *Mitigation:* the final verification grep (`grep -rin "04-ux-testing"` across `.claude/skills/product/`, excluding `vendor/`) must return empty; any hit is a missed site.
- **`{{rubric_section}}` resolution.** The judge dispatch resolves the rubric section by the `### 04 — ` heading. Renaming the `<name>` half (`UX Testing` → `Validation`) is safe *only if* the orchestrator keys on the `### 04 —` numeric prefix, not the full string. SKILL.md line 83 describes it as "the `### NN — <name>` heading" — keyed by NN — so this is low risk, but keep the `### 04 — ` prefix byte-identical.
- **Pre-rename in-flight `.state.json`.** A `--from-step` resume of a run whose `completed_steps` already contains `04-ux-testing` would mismatch the renamed label. *Accepted* — OQ1's resolution explicitly accepted this; `/product` runs are ephemeral, no real long-lived state survives. No migration, no version bump.
- **`build-report.test.ts` regression.** Verified the suite asserts on numeric step ids (`['01','02','03','04']`) and artifact paths (`validation-report.md`), **not** the manifest `title` string — so the `title: 'UX testing'` → `'Validation'` change is test-safe. Still run the suite to confirm (SESSION.md baseline: 25/25 green).
- **TDD posture.** Concern A is a rename and concern B is a rubric-text addition — no production behavior change, no new test warranted. The executable safety net is the existing `build-report.test.ts` suite staying green; the behavioral check is the end-to-end `/product` dogfood (acceptance scenario 3). The validator may emit a `tdd-advisory:` on the `build-report.ts` edit — it is genuinely test-exempt (one-line display-string change, covered by the existing suite).
- **References outside `.claude/skills/product/`.** Acceptance criterion 7 scopes the no-residue check to the product skill. A stray `04-ux-testing` / "UX Testing" in `.claude/rules/` or `.claude/memory/` would be missed. *Mitigation:* a one-off grep across `.claude/` confirms the only outside hits are `.claude/memory/anthill-archived.md` (the *anthill* `anthill-ux-audit` skill — a different thing, untouched) and `docs/specs/` (historical record, untouched by design).

## Research / citations

Internal codebase exploration only — no web research needed (the rename is of our own pipeline; WCAG 2.1 AA contrast ratios 4.5:1 / 3:1 are already the established figures in step 4's own `references/heuristics.md` and `schema.md`).

- `grep -rn "04-ux-testing" / "UX Testing" / "ux-testing"` across `.claude/skills/product/` (excluding `vendor/open-design/`) — produced the enumerated blast radius.
- `.claude/skills/product/SKILL.md` lines 82–84, 96–105 — confirmed step-4 is referenced by number; the directory resolves via `{{step_label}}` / `<NN-step>`.
- `.claude/skills/product/references/quality-judge.md` §§ Rubric assembly, Verdict → gate routing — confirmed the `15b-hifi-mood` judge auto-grades whatever `quality-checklist.md § 15b` contains, and a Phase 4 `fail` surfaces at the terminal handoff (no gate).
- `.claude/skills/product/scripts/build-report.test.ts` lines 50, 213, 218 — confirmed the suite does not assert on the manifest `title`.
- `docs/specs/077-product-validation-framing/spec.md` — the contract this plan implements.
