# 065 — artifact-budget-discipline

_Created 2026-05-19._

**Status:** shipped

## Intent

Sub-agents producing budgeted artifacts (currently `/product`'s 15 steps; pattern reusable elsewhere) sometimes treat a size overshoot as a **compression task** instead of a **scope question**, entering silent trim-loops that burn tokens and converge sub-linearly without surfacing the underlying scope-mismatch. Empirical case: mei-saas 2026-05-19 `/product` Step 02 generated `direction-a.html` at 69 KB against a 30 KB target; sub-agent thrashed 6+ iterations (69 → 46.6 → 43.8 → 42.7 → 41.8 KB), diagnosed CSS-bloat only at iteration 6, and never aborted despite `references/pipeline-coverage.md` § Step 02 already documenting "soft overshoot trigger at max × 1.2 → partial-result with `oversize_reason`". The instruction exists; the sub-agent voluntarily ignored it. This spec codifies the principle as a project rule (`.claude/rules/artifact-budgets.md`), hardens the `/product` briefs to make trim-loop explicitly prohibited, and introduces a per-step `hard_abort_multiplier` so steps with legitimately variable output (system-design) tolerate more overshoot than tight-by-design artifacts (PRD 1-pager, mood board). Pattern is reusable: any future skill producing budgeted artifacts inherits the rule by reference.

## Acceptance criteria

- [x] **Scenario: rule codifies budget-as-scope-proxy with override grammar**
  - **Given** a new contributor reads `.claude/rules/artifact-budgets.md`
  - **When** they ask "what should I do when my output exceeds the budget by 30%?"
  - **Then** the rule names the answer unambiguously (emit partial-result with `oversize_reason`, do NOT trim-loop) and the `# OVERRIDE: <reason ≥10 chars>` escape with worked example

- [x] **Scenario: every `/product` step declares two-threshold overshoot semantics**
  - **Given** any of the 15 step briefs in `references/delegation-briefs.md`
  - **When** a sub-agent reads its brief CONSTRAINTS
  - **Then** the brief carries (a) `soft_overshoot_multiplier = 1.2` (cascade entry: emit partial-result with `oversize_reason`; may continue producing if the partial is useful to downstream), (b) `hard_abort_multiplier = 1.8` (STOP immediately, emit partial-result, no further production), and (c) the literal sentence "DO NOT enter a trim-loop and DO NOT re-emit at smaller scope; both are forbidden — on overshoot, emit partial-result with `oversize_reason` and stop"

- [x] **Scenario: v1 fixes uniform multipliers across all 15 steps**
  - **Given** any step in `references/pipeline-coverage.md` § Per-step table
  - **When** reading the multiplier columns
  - **Then** every value is identical: `soft_overshoot_multiplier = 1.2` and `hard_abort_multiplier = 1.8`. Per-step calibration is deferred per Non-goal — only differentiated when empirical data justifies.

- [x] **Scenario: Step 01's "re-emit at smaller scope" wording is replaced**
  - **Given** Step 01 (Ideation) brief in `references/delegation-briefs.md`
  - **When** reading CONSTRAINTS
  - **Then** the line "going over by ≥50% means re-emit at smaller scope" is removed and the same two-threshold cascade applies. Re-emit-at-smaller-scope is recognized as a sibling antipattern to trim-loop (both are "redo to fit budget" instead of "stop and report") and is explicitly forbidden in the new rule

- [x] **Scenario: hard-abort surfaces oversize_reason field to orchestrator**
  - **Given** a sub-agent produces output exceeding `hard_abort_multiplier × target`
  - **When** it returns to the parent
  - **Then** the partial-result REPORT contains `oversize_reason: "<root cause>"` field naming the dimension that bloated (CSS, fixture data, prose verbosity, etc.) — not just "too big"; example: `"CSS reached 16 KB covering light+dark+5 components; mood board needs 1 mode + 3 components"`

- [x] `.claude/rules/artifact-budgets.md` exists and is cross-referenced from `.claude/rules/delegation.md`, `.claude/skills/product/SKILL.md` § Notes, and `CLAUDE.md` § new "Artifact budgets" section

- [x] `.claude/skills/product/references/delegation-briefs.md` — all 15 step briefs updated with explicit `hard_abort_multiplier` value and the no-trim-loop sentence in CONSTRAINTS

- [x] `.claude/skills/product/references/pipeline-coverage.md` — overshoot language unified across all 15 steps (current mix of "soft overshoot trigger" and "HARD CEILING" prose replaced with the rule's canonical wording)

- [x] No new hook ships in v1 (observability deferred per `.claude/memory/feedback_speculative_observability.md` rule-of-three; only 1 trim-loop case observed)

- [x] mei-saas can sync via `sync-harness.sh --apply` and inherit the new rule + briefs without manual intervention. **Applied 2026-05-19** via `--apply --force --force-except=<7 fork-specific files>`; result `13 copied, 2 merged, 531 up-to-date, 7 customized-refused, 8 overwritten`. Spec 065 files (`artifact-budgets.md`, `CLAUDE.md`, `delegation.md`, product `SKILL.md` + `delegation-briefs.md` + `pipeline-coverage.md`) all landed; V1-V7 re-run against mei-saas paths all pass. The `--force-except` flag preserves fork customs (open-design vendor MANIFEST, ideation/system-design prompt tunings, `.mcp.json.example`, `.gitleaks.toml`, fork's own `sync-open-design.ts`).

## Non-goals

- **Re-calibrating budget values themselves.** Spec 056 owns the empirical calibration (6/15 steps done, 9 deferred). This spec only changes overshoot *semantics* (what the sub-agent does when it stops fitting), not the target ranges.
- **Observability hook for trim-loop detection.** A PostToolUse(Write) detector counting same-path re-writes is plausible, but only 1 case observed. Defer until rule-of-three (see `.claude/memory/feedback_speculative_observability.md`).
- **`/brainstorm` HTML output budget.** No drift observed; deferred until ≥3 cases (REMINDER to track).
- **`/sdd` artifact budgets.** Specs grow with scope by design (`notes.md` append-only, `tasks.md` decomposes). No budget needed.
- **Parent-agent budget discipline.** This rule targets sub-agent dispatches that explicitly receive a brief; parent-agent self-restraint is `.claude/rules/user-prompt-framing.md` territory.
- **Cross-skill schema for budget declaration.** The per-step multiplier lives in `/product`'s pipeline schema for now. A general "any skill declares budgets in `<skill>/budgets.yaml`" abstraction is premature — only 1 skill currently has budgets.
- **Per-step multiplier calibration.** v1 sets `soft_overshoot_multiplier = 1.2` and `hard_abort_multiplier = 1.8` uniformly across all 15 `/product` steps. Differentiated multipliers (mood board tight, system-design loose) are deferred until empirical dogfood data justifies the differentiation — same posture as spec 056's incremental calibration (6/15 done, 9 deferred). Uniform pair ships first; tuning becomes follow-up specs as cases accumulate.

## Open questions

**All resolved at spec time 2026-05-19** — locked decisions below; any reopening updates `plan.md`.

- [x] **Q1: Schema location for the multipliers.** Decided: both `soft_overshoot_multiplier` and `hard_abort_multiplier` declared in `references/pipeline-coverage.md` § Per-step table (canonical, machine-readable columns); brief generator inlines into CONSTRAINTS at dispatch time. Single source of truth, sub-agent receives via brief.
- [x] **Q2: Default values during migration.** Decided: no transitional default — all 15 steps ship in one diff with `soft_overshoot_multiplier = 1.2` and `hard_abort_multiplier = 1.8` uniform v1 baseline. Per-step calibration is a Non-goal. Existing `1.2× soft trigger` language in 7 briefs is preserved + made uniform across all 15; Step 01's `≥50% re-emit` language is removed (unified per Acceptance Criterion #3).
- [x] **Q6: How do the two thresholds (1.2× soft, 1.8× hard) differ behaviorally?** Decided: **1.2× = "consider stopping; partial-result is acceptable here"** — sub-agent has agency to keep producing IF the partial would be useless to downstream, but trim-loop and re-emit are forbidden; **1.8× = "STOP, no agency"** — emit partial-result immediately, no further production regardless of downstream usefulness. Both forbid trim-loop and re-emit-at-smaller-scope; the difference is sub-agent agency.
- [x] **Q3: `oversize_reason` field format.** Decided: free prose for v1 — one sentence naming the root-cause dimension (CSS, fixtures, prose verbosity, screen count, etc.). Structured shape (`{dimension, size_kb, target_kb}`) revisited only if aggregation use-case emerges.
- [x] **Q4: Override marker for budget exemption.** Decided: reuse existing `# OVERRIDE: <reason ≥10 chars>` grammar with `budget-exempt:` prefix convention (mirrors `tdd-exempt:` from `.claude/rules/tdd.md`). No new gate, no audit field change; the reason text is the documentation.
- [x] **Q5: `/skill` SKILL.md size?** Decided: out of scope. Tier (`cc-native` / `agentskills-portable` / `runtime-agnostic`) is the scope proxy already; byte budget would be redundant.

## Context / references

- `docs/specs/056-pipeline-size-reconciliation/` — calibration of `/product` step ranges; spec 065 sits in layer above (semantics, not values)
- `docs/specs/048-product-rename-and-layout/` — current `/product` v0.3.0 design; affected files live in `.claude/skills/product/`
- `docs/specs/002-delegation/` — `# OVERRIDE:` grammar lineage; same shape reused here
- `.claude/rules/delegation.md` § The 5-field handoff — CONSTRAINTS section is where the no-trim-loop sentence lands per-brief
- `.claude/memory/feedback_speculative_observability.md` — rule-of-three demand-test gating the deferred observability hook (Non-goal #2)
- `.claude/tools/sync-harness.sh` — mechanism for re-injecting Agent0 changes into forks (mei-saas in particular)
- Empirical case (mei-saas 2026-05-19 `/product` Step 02): trim-loop log captured in current session — 69 → 46.6 → 43.8 → 42.7 → 41.8 KB across 6+ iterations against 30 KB target; CSS bloat diagnosed only at iteration 6
