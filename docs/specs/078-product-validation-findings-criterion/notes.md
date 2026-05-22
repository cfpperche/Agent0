# 078 — product-validation-findings-criterion — notes

_Created 2026-05-22._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

### 2026-05-22 — parent — Kept the fix to one file; skipped the optional prompt/schema cross-reference

`plan.md § Files to touch` left it open whether to also add a cross-reference line in `04-validation/prompt.md` step 7 or `schema.md § Optional YAML frontmatter` ("the quality judge grades the frontmatter only in measurable mode"). Decided to **skip it** — the fix is the single criterion reword in `quality-checklist.md`. Two reasons: (1) the spec-075 principle — producer-facing templates (`prompt.md`/`schema.md`) deliberately do not mention the judge, so a "the judge grades X" line there would leak judge-awareness into the producer's context; (2) the project's doc separation is intentional — `schema.md` is the structural contract, `quality-checklist.md` is the judge rubric; they are read separately by design. The original contradiction (the criterion demanding frontmatter *for projected mode too*) is fully resolved by the criterion reword alone — the reworded criterion now explicitly cites `04-validation/prompt.md` step 7 for the projected carve-out, so a reader is pointed at the consistent contract from the rubric side.

### 2026-05-22 — parent — Dogfood confirmed the two-clause criterion separates cleanly

The reworded `findings` criterion has a base clause (≥3 substantive severity-rated findings in the markdown `## Findings` table — always graded) and a measurable-mode-only additional clause (the YAML `findings[]` frontmatter must mirror the table). Dogfood in ephemeral `/tmp/078-dogfood` — the `04-validation` quality judge dispatched against two hand-built fixtures, both lacking the YAML frontmatter: a **projected-mode** report → `findings: pass` (carve-out applied, the bug is fixed); a **measurable-mode** report → `findings: fail` (the measurable clause held — the floor is preserved). Scenario 3 (a thin <3 findings set fails either mode) validated by criterion-text inspection: both judge runs explicitly confirmed they apply the "≥3 substantive" floor — a separate <3 fixture would only re-test wording the criterion plainly states.

## Deviations

_(none yet)_

## Tradeoffs

_(none yet)_

## Open questions

_(none yet)_
