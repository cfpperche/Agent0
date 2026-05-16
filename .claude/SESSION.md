# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

Spec 026 Phase B tasks 18 + 19 SHIPPED with **port → judge → calibrate** loop validated twice. Working tree clean. 120 tests pass; `bun tsc --noEmit` clean. Origin up to date (4 commits pushed this session: `0002aef` step-9 port · `e21720f` step-9 calibration · `7458853` step-10 port · `b282c21` step-10 calibration).

**Pattern observed (loop ran 2x consecutively):** port anthill skill → dogfood Octant PRD → side-by-side judge vs anthill canonical → apply KEEPs/CUTs → re-dogfood → re-judge confirms. Both calibrations landed at 30/30 (anthill at 22 and 26 respectively).

- **Step 9 system-design (task 18):** 3-artifact bundle (system-design.md ≥20 KB + architecture.json + sibling security.md). 11 required H2 sections. Calibration: +biggest-eng-risk + cost-ceiling pointer + modular-monolith disclaimer + Trade-off Triggers digest H3; −meta-commentary − Locked sub-section. Final: MCP 30 vs anthill 22.
- **Step 10 cost-estimate (task 19):** single artifact (cost-estimate.md ≥10 KB). 8 required + 4 conditional H2 sections. Calibration: +§ Projections monthly cadence + § Recommendations 3-5 decisões com `*Flip if:*` + Probability column 25/50/25 on Scenarios. Step-9 CUTs carried pre-emptively. Final: MCP 30 vs anthill 26.

## Next steps

1. **Spec 026 Phase B — remaining tasks 20-22**: step 11 roadmap (next; `anthill-roadmap` + `anthill-roadmap-bridge`) · step 12 legal (closes Specification gate — fires) · step 13 prototype-v3 NEW (visual step, depends on steps 5/6/8). Expected same port→judge→calibrate loop per task.
2. **Step-10 nits surfaced by judge (NOT blocking, pick up next iteration):** cash-vs-GAAP reconciliation paragraph + explicit headcount-plan callout. Sub-paragraph additions, not architectural.
3. **REMINDERS unchanged** — fair OD re-match, OD `--bump/--apply` upstream test, spec 029 adoption check (due 2026-05-30).

## Carryover (orthogonal lanes, not active)

- **Spec 030 session-edit-attribution** — already shipped per parallel hermes-agent session; verify via `/sdd list` if needed.
- **Memorialize port→judge→calibrate loop**: ran 2x → worth updating `.claude/memory/anthill-port-workflow.md` (exists from prior session) with the post-judge calibration phase as observed-8th-phase. Deferred to next session.
- **Architecture HTML rendering deferred** (step-9 open Q1) — vendor Cocoon-AI renderer into `packages/mcp-product-pipeline/scripts/`. Not blocking spec 026 acceptance.
- **Pyshrnk CLAUDE.md reconciliation** — long-standing parking lot.
- **Praxis-prototype** (separate repo): deployed at https://cfpperche.github.io/praxis-prototype/.
- **Bench artifacts (~2 MB, wipe-able):** `/tmp/bench/026-dogfood-step{2,3-4,5,6,7,8,9,10}/` — output-a0, output-a0-v2, output-anthill per step.

## Decisions & gotchas

- **Port→judge→calibrate is now THE workflow** for spec 026 Phase B. Each task ships in 2 commits (port + calibration). Token cost ~150-200k per loop (sub-agents parallel) — well-bounded.
- **Step-9 CUTs propagate forward.** Step 10 absorbed both step-9 CUTs (no meta-commentary, no Locked sub-section) without judge prompting — both judges agreed they were anti-patterns. Each future step inherits.
- **Anthill judge bundle for step 10 sits at 26/30** (vs step-9 anthill at 22). FPA skill is more decision-shaped than principal-engineer — closer to recommendations. The MCP-vs-anthill gap narrows when the anthill source is already decision-shaped.
