# 065 — artifact-budget-discipline — plan

_Drafted from `spec.md` on 2026-05-19. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Codify the principle as a rule first (`.claude/rules/artifact-budgets.md`), then propagate to the only current consumer (`/product`). The rule is the canonical reference everything else points at; the `/product` changes are mechanical applications of it.

Order of work matches dependency:

1. **Write the rule** — `.claude/rules/artifact-budgets.md` defines budget-as-scope-proxy, two-threshold cascade (1.0× = DONE; >1.2× soft = partial-result, sub-agent has agency; >1.8× hard = STOP, no agency), no-trim-loop prohibition + no-re-emit-at-smaller-scope prohibition (both are forbidden "redo to fit budget" antipatterns), `oversize_reason` field format, and the `# OVERRIDE: budget-exempt:` escape (reuses spec 002 grammar). One worked example (the mei-saas Step 02 trim-loop) keeps it concrete.
2. **Register in CLAUDE.md** — append a `## Artifact budgets` capacity section so the harness inventory references it; this is what makes the rule discoverable for any skill that grows a budget later.
3. **Add multiplier columns to pipeline schema** — `references/pipeline-coverage.md` § Per-step table gains TWO columns: `soft_overshoot_multiplier = 1.2` and `hard_abort_multiplier = 1.8`, both uniform across all 15 steps (per Open Q2). Adjacent prose explaining the cascade semantics links to the new rule. Existing line 22 (`exceeding max_size × 1.2 triggers sub-agent partial-result...`) gets rewritten to describe both thresholds + the forbidden antipatterns.
4. **Inline into briefs** — `references/delegation-briefs.md` updates each of the 15 step briefs:
   - **7 briefs with existing 1.2× language** (Steps 02, 03, 08, 09, 10, 15 — direction + screen-writer): preserve 1.2× as soft threshold; add 1.8× hard threshold; add the no-trim-loop + no-re-emit sentence.
   - **7 briefs WITHOUT overshoot semantics** (Steps 04, 05, 06, 07, 11, 12, 13): add both thresholds + the forbidden-antipatterns sentence.
   - **1 brief with `≥50% re-emit` anomaly** (Step 01): remove the re-emit language; replace with the standard two-threshold + forbidden-antipatterns sentence per acceptance criterion #3.
   - **Step 14** (only floors): add the cascade semantics for ceiling cases of `tokens.css` / `components.md` / `README.md`.
   Same edit shape × 15 with three variations (existing-1.2× preserve / no-overshoot add / Step 01 replace).
5. **Cross-reference** — `.claude/skills/product/SKILL.md` § Notes gains one line pointing at the rule; `.claude/rules/delegation.md` gains a paragraph-level reference to artifact-budgets.md alongside the existing TDD/secrets/supply-chain mentions.
6. **Validate the discipline** — re-read the rule + a sample brief; mentally walk a sub-agent through "I generated 55 KB against 30 KB target (1.83× ratio)" → confirms the trigger fires and the next step is partial-result, not trim. No automated test (rule-only ship).
7. **Sync to mei-saas** — `sync-harness.sh /home/goat/mei-saas --check` first (preview drift), review, `--apply`. User retries Step 02 in fresh session.

The change is **textual + structural**. Zero new hooks, zero new state files, zero new validators. Sub-agent's behavior changes because the brief explicitly forbids trim-loop now, not because anything detects or intercepts.

## Files to touch

**Create:**
- `.claude/rules/artifact-budgets.md` — canonical rule; budget-as-scope-proxy, overshoot semantics, no-trim-loop, `oversize_reason` format, override grammar, worked example, cross-refs to delegation/product

**Modify:**
- `CLAUDE.md` — append `## Artifact budgets` capacity section (~6 lines) between existing `## PHP / Laravel` and `## Compact Instructions`
- `.claude/skills/product/SKILL.md` — single line in `## Notes` linking to the rule
- `.claude/skills/product/references/pipeline-coverage.md` — add `hard_abort_multiplier` to per-step calibration table; set all 15 entries to `1.8`; add one prose paragraph explaining semantics + link to rule
- `.claude/skills/product/references/delegation-briefs.md` — update CONSTRAINTS block of each of 15 step briefs to inline `hard_abort_multiplier = 1.8` and the no-trim-loop sentence; verify DONE_WHEN already accepts partial-result (likely does — `oversize_reason` mentioned for several steps per inventory)
- `.claude/rules/delegation.md` — 1-2 sentences cross-referencing artifact-budgets.md, probably in § The 5-field handoff CONSTRAINTS guidance or as a new paragraph after § *Why DONE_WHEN exists*

**Delete:** none.

## Alternatives considered

### Build a PreToolUse(Write) detector hook for trim-loops

Rejected because rule-of-three (`.claude/memory/feedback_speculative_observability.md`) demands ≥3 observed cases before construction; we have 1 (mei-saas Step 02). The detector would count same-path Write/Edit calls in a session window; useful but premature. Recorded as REMINDER instead — revisit when 2 more cases land.

### Lower the budget targets themselves

Rejected because budget *values* are spec 056's domain (calibration via dogfood); this spec is about overshoot *semantics*. Conflating them would either (a) duplicate spec 056's empirical posture or (b) preempt its calibration with arbitrary numbers. Clean separation: 056 owns ranges, 065 owns "what happens when you overshoot".

### Per-step `hard_abort_multiplier` from day 1 (differentiated values)

Rejected at spec time (see § Open questions Q2). Rationale: ship the *semantics* uniformly first, gather data, then differentiate. Initial proposal had Step 02 (mood board) at ≤1.3×, Step 05 (PRD) at ≤1.2×, Step 08 (system-design) at ≥1.8× — user pushed back: "deixa fixo 1.8 para todos como proposta inicial". Differentiated multipliers become follow-up specs as empirical data accumulates (mirror of spec 056's 6/15-calibrated-9-deferred pattern).

### Structured `oversize_reason` field (`{dimension, size_kb, target_kb}`)

Rejected at spec time (Open Q3). Free prose is enough for v1 — sub-agent writes one sentence naming the root cause. Structured shape is over-engineering until an aggregation use-case appears (e.g., "show me all overshoot reasons across the last 50 dispatches by dimension"). Revisit if pattern emerges.

### Cross-skill `<skill>/budgets.yaml` schema

Rejected as Non-goal. Only `/product` has artifact budgets today; abstracting prematurely would force `/brainstorm`, `/sdd`, etc. to opt out, adding noise. When a second skill grows budgets, that's the moment to extract a shared schema (rule-of-two for schema extraction is the right threshold here, not three — schemas have higher migration cost than detectors).

## Risks and unknowns

- **Sub-agents may still ignore the explicit "no trim-loop / no re-emit" sentence** — discipline is rule-only, no hook intercepts. The threshold value (1.8×) is secondary to the no-trim-loop discipline: the current docs already had 1.2× partial-result on 7 steps and it was ignored. Mitigation: the sentence is short, explicit, with worked example; the brief inlines it (not buried in a reference doc); the cross-ref from `delegation.md` makes it part of the standard CONSTRAINTS reading the sub-agent already does. If ignored ≥3 times → escalate to PostToolUse(Write) detector hook (deferred per § Alternatives).
- **Two-threshold cascade may confuse sub-agents** — 1.2× and 1.8× must be behaviorally distinct (agency vs no-agency on continuing production) or sub-agent collapses them into one rule and ignores the nuance. Mitigation: rule documentation includes a decision table per zone (DONE / soft / hard) with concrete examples; brief CONSTRAINTS uses identical phrasing across all 15 briefs to reinforce the pattern.
- **`1.8×` uniform multiplier may be wrong for some steps.** Empirical risk: mood board at 1.8× = 30 KB × 1.8 = 54 KB allowed before hard-abort; that's still a lot of HTML for "design direction review". Conversely, system-design at 1.8× = 42 KB × 1.8 = 75 KB, may be too tight for complex schemas. Mitigation: accept this; calibration is the explicit follow-up. The point of v1 is the *semantics*, not the *values*.
- **Orchestrator behavior on partial-result is not formally defined** for `/product`. If the orchestrator currently treats partial-result as failure and retries with the same brief, the no-trim-loop discipline could be defeated by orchestrator-level retries instead of sub-agent-level trim-loops. Need to verify `references/state-machine.md` and orchestrator code during implementation; if behavior is unclear, escalate to user before shipping.
- **mei-saas sync drift unknown.** Fork has been running independently since ~2026-05-19 bootstrap; some `.claude/` files may be customized. `sync-harness.sh --check` will report drift before `--apply`; user reviews diff.
- **Brief generator vs static briefs** — assumption: each step's brief is statically inlined in `delegation-briefs.md` (15 blocks, edit each). If there's actually a generator that composes briefs from `pipeline-coverage.md` at dispatch time, edit volume shifts (smaller in briefs, but generator change needed). Verify during Task 1.

## Research / citations

- **Inventory subagent (this session)** — surveyed 31 budget declarations across `/product` (15 steps), `/brainstorm`, `/sdd`, `/skill`, state files (`SESSION.md`, `COMPACT_NOTES.md`, `REMINDERS.md`, `MEMORY.md`). Confirmed only `/product` has scope-proxy budgets; everything else is runtime/script limit (different class).
- **`docs/specs/056-pipeline-size-reconciliation/`** — empirical calibration approach; spec 065 inherits "ship v1 uniform, calibrate via dogfood" posture
- **`docs/specs/002-delegation/`** — `# OVERRIDE: <reason ≥10 chars>` grammar; reused with `budget-exempt:` prefix convention
- **`.claude/memory/feedback_speculative_observability.md`** — rule-of-three demand-test gating the deferred trim-loop detector hook
- **`.claude/rules/tdd.md`** — `tdd-exempt:` prefix convention precedent for `budget-exempt:`
- **Empirical case** — mei-saas 2026-05-19 `/product` Step 02 trim-loop log: 69 → 46.6 → 43.8 → 42.7 → 41.8 KB across 6+ iterations against 30 KB target; CSS bloat (16 KB) diagnosed only at iteration 6. Worked example for the rule.
