# 078 — product-validation-findings-criterion — plan

_Drafted from `spec.md` on 2026-05-22. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Single-file fix. The `findings` criterion exists only in `quality-checklist.md § 04 — Validation`, and the quality judge assembles its rubric from there (`quality-judge.md § Rubric assembly`). Reword that one criterion so it grades the **unconditional core** (the markdown `## Findings` table, required by `schema.md` regardless of mode) and **scopes the YAML-frontmatter expectation to measurable-mode audits**.

The criterion today:

> **findings** — YAML `findings[]` ≥ 3, each carrying `severity` + `fix_skill_hint`

Reworded shape (final wording settled at implementation):

> **findings** — the `## Findings` table carries ≥ 3 substantive, severity-rated findings (each row a concrete issue + an actionable recommendation). **Additionally, when the audit ran in measurable mode** — HTML inputs, the `## Accessibility Review` table showing real measured contrast ratios rather than projected `warn`s — the YAML `findings[]` frontmatter must mirror the table (≥ 3 entries, each with `severity` + `fix_skill_hint`). A **projected-mode** audit legitimately omits the frontmatter; judge it on the markdown table alone — do not fail it for the absence.

The judge detects the audit branch by reading the report's `## Accessibility Review` table: `04-validation/prompt.md` step 4 already mandates each row be labelled with the mode it used (`measured` / `projected`). The criterion text names that signal so the judge does not have to guess.

The load-bearing change is the single criterion reword. A one-line cross-reference may optionally be added in `04-validation/prompt.md` step 7 or `schema.md § Optional YAML frontmatter` ("the quality judge grades this frontmatter only for measurable-mode audits") to close the loop both directions — decided at implementation on clarity-vs-redundancy grounds.

## Files to touch

**Modify:**
- `.claude/skills/product/references/quality-checklist.md` — § 04 — Validation, the `findings` criterion: reword per § Approach. The single load-bearing edit.
- _(optional — implementation judgement call)_ `.claude/skills/product/templates/pipeline/04-validation/prompt.md` step 7 and/or `04-validation/schema.md § Optional YAML frontmatter` — one cross-reference line that the judge grades the frontmatter only in measurable mode. Add only if it adds clarity, not redundancy.
- `docs/specs/078-product-validation-findings-criterion/spec.md` — status `draft` → `in-progress` → `shipped`.

**No edit:**
- `quality-judge.md` — the mechanism is unchanged; it already assembles the rubric from `quality-checklist.md`.
- The judge dispatch brief in `delegation-briefs.md` — unchanged.
- `04-validation/schema.md` Layer-1 block — the frontmatter stays Layer-1-optional; this spec touches only the judge's semantic criterion.

## Alternatives considered

### (b) Make the YAML frontmatter unconditional in the step-04 template

Rejected. The projected/measurable split is deliberate: `04-validation/prompt.md` step 7 states projected mode has "nothing structured to consume" — a projected audit's findings are tracked *handoffs*, not measured data. Forcing a structured `findings[]` block onto projected runs would fabricate a false impression of measured precision and contradict the step's own design. The rubric is the side that is wrong, not the template.

### Make the judge skip the `findings` criterion entirely for projected mode

Rejected — too blunt. A projected-mode report still owes ≥ 3 substantive severity-rated findings (the markdown table); skipping the criterion would stop grading that. The fix keeps the floor — it just moves it from "YAML frontmatter exists" to "the markdown findings table is substantive", which every report has unconditionally.

### Treat it as a one-file edit and skip the spec

Considered — the fix is plausibly one criterion in one file, and `spec-driven.md § When to skip` lists "one-file bug fixes with obvious cause". Rejected: it changes the behaviour of a quality gate (what makes the Discovery gate recommend `iterate`), is worth a PR-body description, and the founder explicitly asked for a spec. A tight spec is cheap insurance and the design record of *why* the criterion will read the way it does.

## Risks and unknowns

- **Branch-detection reliability.** The judge must tell measurable from projected. The signal — the `## Accessibility Review` table's `measured` / `projected` row labels (mandated by `prompt.md` step 4) — is reliable only if producers actually label the rows; the fallback signal is "are there real measured ratios". The criterion can spell out both. Low risk: the worst case is the judge treats an unlabelled measurable report as projected and under-checks the frontmatter — a `concern`, not a false `fail`.
- **No executable test.** `quality-checklist.md` is judge-rubric prose; there is no unit test. Validation is a dogfood, mirroring the spec-077 method: dispatch the `04-validation` judge against (1) a projected-mode report → expect `findings: pass`, and (2) a measurable-mode report missing the frontmatter → expect `findings: concern`/`fail`.
- **Scope creep.** Other `quality-checklist.md` criteria may carry a similar conditional smell — out of scope; flag separately, do not widen this spec.

## Research / citations

- Internal only — no web research. The bug was diagnosed empirically by the spec-077 dogfood: the `04-validation` quality-judge verdict (`outcome: fail`, `findings: fail`) against a correct projected-mode report, 2026-05-22.
- `docs/specs/077-product-validation-framing/notes.md § Open questions` — the bug log.
- `.claude/skills/product/references/quality-checklist.md` (§ 04 — Validation), `.../quality-judge.md` (§ Rubric assembly), `.../templates/pipeline/04-validation/{prompt,schema}.md` — the files inspected to scope the fix.
