---
name: anthill-port-workflow
description: Observed stable workflow that emerged from porting anthill skills (steps 5-8 of spec 026 Phase B) — port → audit smells → write template → dogfood (opus sub-agent) → fold gaps same-session → validator → commit → SESSION.md handoff. Pattern, not rule; future ports may deviate when justified.
metadata:
  type: project
---

The pattern that emerged consistently across [[anthill-archived]] ports of steps 5 (brand), 6 (design-system), 7 (prototype-v2), and 8 (PRD) in spec 026 Phase B. Each step followed the same 7-phase loop and produced commits with similar structure. Worth memorializing as a reference for future ports; **NOT a rule** — it's an observed pattern that future steps may deviate from when the deviation is justified.

## The 7 phases

1. **Locate anthill source + read existing stub.** Each MCP step has a scaffolded `prompt.md` + `schema.md` from spec 025; the port replaces those with deeper content. Always `wc -l` the anthill source first to know the depth target.

2. **Audit anthill source for over-prescription smells** per [[feedback_anthill_port_smart_not_rigid]]. The 4 canonical smells:
   - **Magic numbers** (e.g., "at least 2 success metrics", "8 screens", "5 dimensions") — calibrate to dynamic / product-class-driven.
   - **Single-orchestrator** (one agent does everything) — split into `delegable: partial` with parent-only inputs + sub-agent synthesis.
   - **Undynamic defaults** (one template fits all) — add a calibration table by product class / size / scope.
   - **One-mode template** (single output shape) — support multiple modes (catalog vs custom vs mixed; frontmatter vs prose-routed vs projected; etc).

3. **Write the MCP template files.** Target ~150-200 LOC for prompt.md, ~80-100 LOC for schema.md, ~100-200 LOC each for references/. Step 6 ported with 6 references (catalog complexity warranted it); steps 5/7/8 ported with 2-3. Smart-not-rigid means the convention isn't a hard floor.

4. **Dogfood the port.** Stage inputs at `/tmp/bench/026-dogfood-step<N>/inputs/` from prior-step outputs. Dispatch a single `Agent` sub-agent (model: opus) with a 5-field handoff brief that includes:
   - Template paths (in order) to read as instructions
   - Input file paths
   - Founder pre-locked decisions when the step is `draft-after-input` mode (substitutes for the parent's live interview; keeps the bench fair)
   - Output destination
   - Required final-message format (size + Layer-1 self-check + section coverage + gap findings)

5. **Fold same-session gaps.** The dogfood always surfaces template gaps (steps 5/6/7/8 surfaced 2/3/7/7 respectively). Apply all fixes inline in the same commit — do NOT defer to a "follow-up". The fold IS the discipline; it's what separates a port that learns from a port that ships partial.

6. **Run validator + commit.** `bun tsc --noEmit` clean + `bun test` pass (109 baseline). Commit message follows the canonical shape: `feat(026): Phase B task <N> — step <N> <name> port + dogfood-driven fixes`. Body documents each smart-not-rigid calibration applied + each gap folded with the dogfood-finding context.

7. **Update SESSION.md handoff + tasks.md checkbox + (optional) v2 dogfood for empirical validation.** Step 7 added a v2 re-run that validated the Gap-7 fix empirically (10 leaks → 0); step 8 added a blind-judge comparison vs anthill (37-20 win). Both are optional — the canonical 7-step loop is enough for steps without specific validation concerns.

## Observed metrics per port

| Step | LOC port | Dogfood gaps | Same-session fixes | Commit hash |
|---|:---:|:---:|:---:|---|
| 5 brand | ~250 | 2 | 2 | `e4f6361` + `d13263d` |
| 6 design-system | ~400 (6 refs) | 3 | 3 | `9e233c4` + `2d4697c` |
| 7 prototype-v2 | ~705 (3 refs) | 7 | 7 + 1 micro-fix (`c599905`) | `75119df` |
| 8 PRD | ~525 (2 refs) | 7 (5 dogfood + 2 judge) | 7 | `4502c47` |

Pattern: depth per step doesn't predict gap count; visual / multi-artifact steps (6, 7) and Specification-phase steps (8) consistently surfaced more gaps than terse-single-artifact ports (5).

## When to deviate from this workflow

- **The step has no anthill analog (e.g., step 13 prototype-v3 NEW).** Skip phase 1; substitute "synthesize from steps 5+6+8 source materials" + audit phase still applies.
- **The step is a port-improvement, not a new port.** Single commit, no dogfood needed unless the change is structural.
- **The step's risk profile is low** (e.g., step 9-11-12 system-design / cost / roadmap / legal — narrative-heavy, less structural). Consider a smoke-test pattern: sub-agent runs Layer-1 self-check + 3 sample sections, NOT full output emission. Saves ~70% of dogfood cost where the template is predictable. **(Not yet adopted as default — the canonical 7-step loop is still the standard.)**
- **The user explicitly skips a phase** (e.g., "ship without dogfood for this iteration") — deviation is justified by the user's authority, not the workflow's silence.

## Cross-references

- [[anthill-archived]] — quality-floor reference; no longer evolves.
- [[feedback_anthill_port_smart_not_rigid]] — the audit lens.
- [[consumer-contract-discipline]] — sibling pattern; document the consumer contract IN the producer template.
- [[agent0-purpose]] — Agent0 is the template-forever base; ports flow INTO `packages/mcp-*`, not into the harness core.

## Anti-pattern

A port that transcribes anthill verbatim without applying the audit (phase 2). The smart-not-rigid memory exists because the early Agent0 ports leaned toward verbatim transcription; recurring user feedback corrected the pattern toward calibration.

A port that skips the dogfood (phase 4) under time pressure. Steps 5/6/7/8 all surfaced gaps that pure code-review didn't catch — the dogfood is the empirical layer that the audit phase alone can't replace.

A port that defers gap-folds to a follow-up commit (phase 5). The discipline is same-session because deferred gaps rot — they get rediscovered weeks later via accident, by which point context to fix them properly is gone.
