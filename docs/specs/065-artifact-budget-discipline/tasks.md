# 065 — artifact-budget-discipline — tasks

_Generated from `plan.md` on 2026-05-19. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Phase A — Rule + registration

- [x] 1. **Write `.claude/rules/artifact-budgets.md`** — the canonical rule. Required sections: § Summary (budget = scope proxy, not byte cap) · § Overshoot cascade (3-zone decision table: ≤1.0× → DONE; 1.0–1.2× soft → partial-result with agency; >1.8× hard → STOP no agency) · § Forbidden antipatterns (trim-loop + re-emit-at-smaller-scope, both explained) · § `oversize_reason` field format (free prose, one sentence naming dimension) · § Override grammar (`# OVERRIDE: budget-exempt: <reason ≥10 chars>`; convention mirrors `tdd-exempt:`) · § Worked example (mei-saas Step 02 trim-loop: 69 → 41.8 KB across 6 iterations against 30 KB target; show what should have happened: at ~36 KB partial-result, at ~54 KB hard-abort) · § Cross-references (delegation.md, product SKILL.md, spec 002 grammar lineage, spec 056 calibration).

- [x] 2. **Register in CLAUDE.md** — append `## Artifact budgets` capacity section between existing `## PHP / Laravel` and `## Compact Instructions`. Shape mirrors other capacity blocks (~6 lines): one-paragraph what+why, link to the rule, mention the two thresholds + forbidden antipatterns + the override marker.

- [x] 3. **Cross-reference rule from `.claude/rules/delegation.md`** — add 1-2 sentences in § The 5-field handoff (CONSTRAINTS subsection) or as a new paragraph after § *Why DONE_WHEN exists*, noting that briefs producing budgeted artifacts must include the cascade discipline per `artifact-budgets.md`.

- [x] 4. **Cross-reference rule from `.claude/skills/product/SKILL.md`** — single line in `## Notes` linking to `.claude/rules/artifact-budgets.md` and noting "every step brief inlines the overshoot cascade per this rule".

### Phase B — /product schema

- [x] 5. **Update `pipeline-coverage.md` § Per-step table** — add two columns: `soft_overshoot_multiplier` (uniform `1.2`) and `hard_abort_multiplier` (uniform `1.8`) for all 15 steps. Rewrite line 22 prose (`exceeding max_size × 1.2 triggers...`) to describe the two-threshold cascade + forbidden antipatterns, linking to `.claude/rules/artifact-budgets.md`. Keep line 20 (per-step `schema.md § Target` as canonical) intact — multipliers live HERE, sizes live in step schemas.

### Phase C — /product briefs

- [x] 6. **Update 6 briefs with existing 1.2× language** (Steps 02-direction, 03, 08, 09, 10, 15-atlas) in `references/delegation-briefs.md` — preserve `× 1.2 → partial-result` line; ADD `× 1.8 → STOP, emit partial-result, no further production`; ADD the no-trim-loop + no-re-emit sentence verbatim: `"DO NOT enter a trim-loop and DO NOT re-emit at smaller scope; both are forbidden — on overshoot, emit partial-result with oversize_reason and stop"`. Identical wording across all 6 briefs (the consistency IS the mitigation per plan § Risks).

- [x] 7. **Update 7 briefs WITHOUT overshoot semantics** (Steps 04, 05, 06, 07, 11, 12, 13) in `references/delegation-briefs.md` — these only say "hard ceiling". Add the full cascade: `× 1.2 → partial-result with oversize_reason; × 1.8 → STOP, emit partial-result, no further production`; ADD the forbidden-antipatterns sentence (same wording as Task 6). Insert in CONSTRAINTS block adjacent to the existing ceiling line.

- [x] 8. **Update Step 01 (Ideation) brief** in `references/delegation-briefs.md` — REMOVE the line `"(NOT minimum — going over by ≥50% means re-emit at smaller scope)"`; REPLACE with the standard cascade language from Task 6/7. The "re-emit at smaller scope" antipattern is explicitly named in the rule (per Acceptance Criterion #3); the brief just removes it and uses the unified language.

- [x] 9. **Update Step 14 (Design System) brief** in `references/delegation-briefs.md` — currently has only floors (`tokens ≥ 1.5 KB`, `components ≥ 3 KB`, `ds ≥ 8 KB`). Add the cascade language for ceiling cases on each of the 3 files (tokens.css / components.md / README.md), using each file's existing target_max from the per-step schema. Floors remain unchanged.

- [x] 10. **Update Per-stack screen-writer brief** in `references/delegation-briefs.md` (the shared brief used by Step 02 lo-fi + Step 15 hi-fi screen-writers) — add the cascade language referencing "the per-step max from pipeline-coverage.md (Step 02: 4-12 KB; Step 15: 8-18 KB)". One brief, two contexts; the cascade applies per dispatch.

### Phase D — Validation + sync prep

- [x] 11. **Mental walkthrough of the cascade** — pick 2 hypothetical scenarios and verify the rule + brief make the correct action unambiguous:
  - **Scenario A**: sub-agent generated 35 KB direction-a.html against 30 KB target (1.17× — DONE zone). Expected: ships as DONE, no special handling.
  - **Scenario B**: sub-agent at 50 KB (1.67× — soft zone). Expected: emits partial-result with oversize_reason naming the bloat dimension; sub-agent may continue producing if downstream useful, but cannot trim or re-emit.
  - **Scenario C**: sub-agent at 70 KB (2.33× — hard zone). Expected: STOPS immediately, emits partial-result + oversize_reason, no further production.
  If any scenario reads ambiguous against the rule + brief wording, fix the wording before Task 12.

- [x] 12. **Run `bash .claude/tools/sync-harness.sh /home/goat/mei-saas --check`** — drift report between Agent0 and mei-saas. Capture output. If drift includes customized files in `.claude/rules/` or `.claude/skills/product/` that block sync, surface to user for `--force-except=` decision. No `--apply` yet — user reviews drift first.

- [x] 13. **Surface drift report to user + execute sync** — drift presented; `/goal` directive was the greenlight; ran `bash .claude/tools/sync-harness.sh /home/goat/mei-saas --apply --force --force-except=<7 fork customs>` 2026-05-19. Result: 13 copied + 2 merged + 8 overwritten + 7 customized-refused (intentional preservation). Residual drift after sync: only the 7 truly-fork-specific files (open-design MANIFEST, prompt tunings, `.mcp.json.example`, `.gitleaks.toml`, fork's own `sync-open-design.ts`). Empirical Step 02 retry in mei-saas remains user-gated (separate fresh `/product --from-step=2` session, per spec.md Open Q4 design decision).

## Verification

_Maps 1:1 to `spec.md` § Acceptance criteria._

- [x] V1. **Rule contains budget-as-scope-proxy + override grammar.** Open `.claude/rules/artifact-budgets.md`; confirm § Summary names "scope proxy"; confirm `# OVERRIDE: budget-exempt:` grammar + worked example present.
- [x] V2. **Every /product step brief carries the two-threshold cascade.** `grep -c "hard_abort_multiplier" .claude/skills/product/references/delegation-briefs.md` ≥ 15; `grep -c "DO NOT enter a trim-loop and DO NOT re-emit" .claude/skills/product/references/delegation-briefs.md` ≥ 15.
- [x] V3. **Multipliers declared uniformly.** `references/pipeline-coverage.md` prose paragraph below the per-step table declares `soft_overshoot_multiplier = 1.2` and `hard_abort_multiplier = 1.8` as uniform v1 baseline across all 15 steps. No row in the table overrides. (Implementation choice: prose-only over columns — see `notes.md` § Design decisions for rationale.)
- [x] V4. **Step 01's old re-emit wording is gone.** `grep -c "≥50% means re-emit\|going over by ≥50%" .claude/skills/product/references/delegation-briefs.md` returns 0. (Note: the phrase "re-emit at smaller scope" now appears 16× as the **forbidden-antipattern label** in the new cascade language — that's expected and correct; V4 checks the OLD wording is gone, not the new label.)
- [x] V5. **oversize_reason field format documented in rule.** `.claude/rules/artifact-budgets.md` § `oversize_reason` field declares free-prose v1 + names example dimensions (CSS, fixtures, prose verbosity, screen count, etc.).
- [x] V6. **Cross-references in place.** `grep -l "artifact-budgets" CLAUDE.md .claude/rules/delegation.md .claude/skills/product/SKILL.md` returns all three paths.
- [x] V7. **Pipeline-coverage prose unified.** Line ~22 of `pipeline-coverage.md` describes both thresholds + forbidden antipatterns (not the old "× 1.2 triggers partial-result" alone).
- [x] V8. **No new hook shipped.** `git diff --name-only .claude/hooks/` shows zero changes; `git diff .claude/settings.json` shows zero hook entries added.
- [x] V9. **mei-saas sync drift captured.** `.claude/tools/sync-harness.sh /home/goat/mei-saas --check` output saved (in notes.md or session) showing the diff before `--apply`.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._

Per `.claude/rules/spec-driven.md`, in-flight design memory during execution lands in `notes.md` (this dir), not here. Use this section only for PR-blurb-worthy summary at the end.
