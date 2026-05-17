# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Spec 026 Phase B COMPLETE.** All 13 templates (steps 1-13) ported + calibrated. This session shipped tasks 20+21+22 in 6 commits (`15d200d` task 20 port · `c8f5575` task 20 calibration · `40cd650` task 21 port · `3a71715` task 21 calibration · `2be4f0c` task 22 port · `0146332` task 22 calibration). `tasks.md` checkboxes 20/21/22 flipped to `[x]`. Working tree has the tasks.md edit + an unrelated `site/...claude-core.astro` modification from prior session + leftover PNG screenshots (untouched). Validators: `bunx tsc --noEmit` clean, `bun test` 120 pass / 0 fail / 227 expect() — preserved across all 6 commits.

**Loop pattern held across all 3 tasks** (port → dogfood → judge → calibrate → re-dogfood → re-judge):
- Task 20 (step 11 roadmap): MCP 30/30 vs anthill 17→19. 5 KEEPs + 2 CUTs absorbed.
- Task 21 (step 12 legal): MCP 29→30/30 vs anthill 19/19. 6 KEEPs + 4 CUTs. **Porter caught a bug**: old skeleton said step 12 closed the pipeline; actually step 13 does (LAST_STEP=13). Corrected in new prompt.
- Task 22 (step 13 prototype-v3 NEW): no anthill comparator (NEW step). Dogfood-only calibration; 7 over-prescription smells folded same-session. Schema literal swapped 5-dim → 4-dim (Token Hygiene / Voice Match / Component Reuse / Brief Fit; Specificity dropped, Audit-fix → narrative-only).

## Next steps

1. **Spec 026 Phase C — docs + decisions** (tasks 23-25). Pick dogfood slug (a) re-Linear-clone vs (b) fresh product; update `packages/mcp-product-pipeline/README.md` with 13-step pipeline diagram; update `.mcp.json.example` header (cosmetic; says "12 steps").
2. **Spec 026 Phase D — end-to-end dogfood validation** (tasks 26-31). Walk 1→13 in chosen dogfood dir; verify `product_done` after step 13 fires `pipeline-complete` + `/sdd new <slug>` handoff; measure artifact volume ≥285 KB; ship dogfood evidence to `docs/specs/026-*/dogfood/`.
3. **Memorialize port→judge→calibrate as 8th phase of `.claude/memory/anthill-port-workflow.md`** — observed 4× now (steps 9/10/11/12) plus the NEW-step variant (step 13 = dogfood-only calibration when no anthill comparator). Still pending from 2 sessions ago.
4. **REMINDERS unchanged** — fair OD re-match, OD `--bump/--apply` upstream test, spec 029 adoption check (due 2026-05-30).

## Carryover (orthogonal lanes, not active)

- **Step-12 v2 + step-13 schema follow-on**: porter flagged a future schema-parser extension (multi-`any_of_contains_*` arrays per concept) as the right way to hard-enforce step-12 patent/IPAA surfaces and step-13 legal-screen mandate when current dogfood is no longer enough.
- **4-dim model upstream propagation** — step 7's design-fidelity 5-dim model (Token/Voice/Component/Audit-fix/Specificity) was deliberately NOT touched; if a future spec wants the 4-dim shape uniformly across steps 2/7/13, that's a separate refactor.
- **Step-10 nits** (cash-vs-GAAP reconciliation + headcount-plan callout) — unchanged.
- **Step-13 open questions deferred to Phase D dogfood**: synthesis-mode Open Decisions framing live test; `partial` US-NN status usage; per-component vs per-screen states matrix tension.
- **Architecture HTML rendering** (step-9 open Q1) + **Pyshrnk CLAUDE.md reconciliation** — long-standing parking lots.
- **Bench artifacts (~10+ MB wipe-able):** `/tmp/bench/026-dogfood-step{11,12,13}/` — output-a0, output-a0-v2, output-anthill per step (step 13 has output-a0 only — NEW step, no comparator).

## Decisions & gotchas

- **Schema literal-anchor mid-spec swap is now precedent.** Step 13 calibration swapped `| Screen | Token | Voice | Component | Audit-fix | Specificity |` → `| Screen | Token Hygiene | Voice Match | Component Reuse | Brief Fit |`. Documented in calibration revisions paragraph for git-log greppability. If schema swaps recur, consider a `.claude/rules/` discipline on the "before vs after" notation.
- **Pre-emptive KEEP/CUT inheritance works.** Step 12 absorbed step-11's 5 KEEPs (user-flow names, concern tags, real-human acceptance, step-4 lineage, sub-bullet exit criteria) BEFORE its own judge ran — landed at 29/30. Step 13 absorbed all the above PLUS step-12's transitive-dep + Alice/Mayo + PIIA discipline pre-emptively. The dogfood phase catches what pre-emptive can't.
- **NEW-step calibration variant**: when no anthill comparator exists, dogfood-A0 alone surfaces over-prescription smells. Step 13 was the first instance — 7 smells folded same-session, validates the 7-phase workflow's "skip phase 1 [anthill source]; audit phase still applies" provision.
