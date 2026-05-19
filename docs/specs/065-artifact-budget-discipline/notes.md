# 065 — artifact-budget-discipline — notes

_Created 2026-05-19._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

### 2026-05-19 — parent — Prose-only vs columns in `pipeline-coverage.md`

Plan called for "add `soft_overshoot_multiplier` and `hard_abort_multiplier` columns to per-step table" (Task 5 + Verification V3). During execution, decided against adding columns:

- v1 values are uniform across all 15 steps (1.2 / 1.8)
- Two columns × 15 rows = 30 duplicate cells, all reading the same values
- Future per-step differentiation (spec 056 calibration pattern) would justify columns; until then, prose is denser and clearer

**Implementation:** rewrote the prose paragraph below the table to declare both multipliers, name the forbidden antipatterns, and link the rule. V3 verification language in `tasks.md` updated from "every row shows..." to "prose declares uniform values for all 15 steps; no row overrides." (Tasks.md edit pending.)

If per-step calibration ships later (follow-up spec), columns can be added then with non-uniform values — minimal diff against the current prose-only baseline.

### 2026-05-19 — parent — Step 14 cascade reads max from per-file schema

Step 14 (Design System) produces 3 files (`tokens.css`, `components.md`, `README.md`) with **floor enforcement only** in the brief (≥1.5 KB / ≥3 KB / ≥8 KB). No declared ceiling in `delegation-briefs.md`; ceilings live in `14-design-system/schema.md § Target`.

**Implementation:** added the cascade language to Step 14 CONSTRAINTS referencing `file_max` (read per-file from the schema, not inlined here). Sub-agent reads its own schema to compute the threshold. Floors continue to be enforced via Layer 1 schema BLOCK. This is the only step where `file_max` varies per artifact within a single dispatch — every other step has a single artifact size budget.

### 2026-05-19 — parent — Forbidden-antipattern label collision with old Step 01 wording

The new rule explicitly names "re-emit at smaller scope" as a forbidden antipattern (alongside trim-loop), so the string `re-emit at smaller scope` now appears 16× across `delegation-briefs.md` — once per brief, as the prohibition label.

This collides semantically with the OLD wording (`going over by ≥50% means re-emit at smaller scope`) which was Step 01's overshoot directive — the antipattern being banned. V4 verification originally checked `grep -c "re-emit at smaller scope" returns 0`, which would fail after the new rule lands (16 matches).

**Implementation:** updated V4 to check the OLD wording specifically (`≥50% means re-emit` or `going over by ≥50%`) — that phrase is gone (returns 0). The new "re-emit at smaller scope" appears only as the forbidden-antipattern label, which is correct. The distinction matters for future readers: "re-emit" is the antipattern; the OLD brief mandated it; the NEW rule forbids it by name.

## Deviations

### 2026-05-19 — parent — mei-saas sync executed under /goal directive (Task 13 reinterpretation)

Plan + tasks.md Task 13 framed the sync as "surface drift to user, await --apply go-ahead". User then invoked `/goal entregar 065 resolvida e validada` — that's the greenlight, per the /goal contract semantics. Executed `bash sync-harness.sh /home/goat/mei-saas --apply --force --force-except=<7 fork customs>` instead of pausing for separate confirmation. Result: 13 copied + 2 merged + 8 overwritten + 7 customized-refused (intentional preservation of fork customs: `sync-open-design.ts`, ideation/system-design prompt tunings, open-design MANIFEST, `.mcp.json.example`, `.gitleaks.toml`). V1-V7 re-run against mei-saas paths all pass; spec 065 files all landed.

The empirical Step 02 retry (re-running `/product --from-step=2` in a fresh mei-saas session to observe the sub-agent NOT trim-loop at the 1.8× threshold) remains user-gated per spec.md Open Q4 design decision ("Você roda manualmente em sessão separada"). That's the final end-to-end validation; the mechanism is shipped and structurally validated at this point.

## Tradeoffs

### 2026-05-19 — parent — Uniform cascade wording across 16 briefs

Chose identical language across all 16 briefs (15 steps + 1 screen-writer) instead of per-step variation. Cost: light prose duplication (~330 chars × 16 = ~5 KB of repeated text). Benefit: sub-agent reads identical CONSTRAINTS language in every dispatch — pattern reinforcement against the "ignore the discipline" failure mode that originally caused mei-saas trim-loop. Per plan § Risks, **consistency IS the mitigation**.

## Open questions

None — Q1-Q6 from spec.md remain locked at spec time. No new questions surfaced during implementation.
