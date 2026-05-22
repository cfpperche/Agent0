# 078 — product-validation-findings-criterion

_Created 2026-05-22._

**Status:** shipped

## Intent

The `/product` quality judge grades step 04 (Validation) against a rubric in `quality-checklist.md`. Its `findings` criterion reads — verbatim — **"findings — YAML `findings[]` ≥ 3, each carrying `severity` + `fix_skill_hint`"**. It demands the optional YAML frontmatter *unconditionally*. But the step-04 template makes that frontmatter *conditional*: `04-validation/prompt.md` step 7 is titled "(Recommended for measurable mode)" and says "Skip the frontmatter when the audit ran in branch (ii) projected mode — there's nothing measurable to hand off"; `04-validation/schema.md § Optional YAML frontmatter` agrees ("Optional, not required by Layer 1"). The `/product` standard tier audits in **projected mode by default**.

So a step-04 producer that correctly follows its own template — projected mode, a populated markdown `## Findings` table, no frontmatter — *always* draws a `findings: fail` from the `04-validation` quality judge. That `fail` rolls the judge's `outcome` to `fail`, which pre-populates the Discovery gate's recommended option as `iterate`. The judge is penalising the producer for correctly obeying the prompt.

This was surfaced by the spec-077 dogfood (2026-05-22): a clean projected-mode `validation-report.md` — 16 severity-rated findings, all 10 required sections, 32 KB — received `outcome: fail` *solely* on the `findings` criterion. The bug predates spec 077; 077's dogfood only revealed it.

The fix reconciles the rubric with the template. The `findings` criterion must grade what *every* step-04 report carries regardless of audit mode — the severity-rated markdown `## Findings` table, required by `schema.md` unconditionally — as its core, and treat the YAML `findings[]` frontmatter as a **measurable-mode-only** sub-check: required when the audit was measurable, legitimately absent when projected.

## Acceptance criteria

- [x] **Scenario: a projected-mode report is not false-failed on `findings`**
  - **Given** a `validation-report.md` produced in projected mode — no YAML frontmatter, a populated severity-rated `## Findings` table with ≥ 3 findings
  - **When** the `04-validation` quality judge grades it
  - **Then** the `findings` criterion verdict is `pass` — the markdown findings table satisfies it; the absent frontmatter is not held against a projected-mode audit

- [x] **Scenario: a measurable-mode report still owes the structured frontmatter**
  - **Given** a `validation-report.md` produced in measurable mode — HTML inputs, real measured contrast ratios in the `## Accessibility Review` table
  - **When** the judge grades it
  - **Then** the `findings` criterion still expects the YAML `findings[]` block (≥ 3 entries, each with `severity` + `fix_skill_hint`); a measurable-mode report that omits it is a `concern` or `fail`

- [x] **Scenario: a genuinely thin findings set still fails, in either mode**
  - **Given** a report with fewer than 3 findings, or a `## Findings` table of stubs
  - **When** the judge grades it
  - **Then** `findings` is `fail` regardless of audit mode — the fix does not weaken the floor, it only stops punishing a correct projected-mode omission

- [x] The `findings` criterion text in `quality-checklist.md § 04 — Validation` no longer contradicts `04-validation/prompt.md` step 7 + `04-validation/schema.md § Optional YAML frontmatter` — a reader holding the rubric and the template sees one consistent contract.

## Non-goals

- Changing the projected/measurable audit-branch split itself, or making the YAML frontmatter unconditional — that contradicts the step's design rationale (projected mode has "nothing structured to consume").
- Touching any other step's criteria in `quality-checklist.md`, or any other `findings`-shaped criterion elsewhere.
- Adding a deterministic Layer-1 check for the frontmatter — the frontmatter stays `schema.md`-optional; this spec is only about the judge's *semantic* criterion.
- Re-opening spec 077 (shipped) — this is the separate, pre-existing bug 077's dogfood surfaced.

## Open questions

- [ ] None blocking. One plan-level wording detail: how the criterion instructs the judge to *detect* the audit branch (measurable vs projected). Candidate signal — the `## Accessibility Review` table's per-row `measured` / `projected` labelling, which `04-validation/prompt.md` step 4 already mandates, plus the presence of real measured ratios. A criterion-wording choice for `plan.md`, not a blocker.

## Context / references

- `docs/specs/077-product-validation-framing/notes.md § Open questions` — where this bug was logged, from the 077 dogfood.
- `.claude/skills/product/references/quality-checklist.md § 04 — Validation` — the `findings` criterion to reword (the single load-bearing change).
- `.claude/skills/product/templates/pipeline/04-validation/prompt.md` step 7 + `04-validation/schema.md § Optional YAML frontmatter` — the conditional-frontmatter contract the rubric must be reconciled to.
- `.claude/skills/product/references/quality-judge.md § Rubric assembly` — how the judge consumes `quality-checklist.md` criteria.
- spec 077 — the rename whose dogfood surfaced this.
