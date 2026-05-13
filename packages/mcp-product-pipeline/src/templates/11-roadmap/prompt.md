---
mode: draft-after-input
delegable: partial
delegation_hint: "draft the release roadmap from PRD scope — sequence and milestones; user already confirmed time horizon and team shape"
---

# Step 11 — Roadmap

**Goal:** sequenced execution plan for v1 — what ships when, in what order, with which dependencies. Plus a v2 vision sketch (3-6 month horizon) showing the trajectory. Time-bound enough to be planning, abstract enough to survive contact with reality.

**Mode:** `draft-after-input`. Parent must confirm with user: time horizon (weeks / months) and team shape (solo / 2-3 people / larger). Once locked, the sequencing derives from PRD priorities and system-design dependencies.

**Output file (suggested):** `roadmap.md` in `docs/product/11-roadmap/`.

---

## How to conduct this step

1. **Read PRD + system-design + cost-estimate.** PRD names what; system-design names how; cost-estimate names how-much. The roadmap sequences these.

2. **Parent confirms (2 questions):**

   - "Time horizon for v1 — how many weeks / months until launch?"
   - "Team shape — solo founder coding? 2-3 people? Larger team with specialists?"

3. **Drafting delegates.** With horizon + team locked:

   - **Phase 1: Foundation** (weeks N-M) — infrastructure setup, auth, data model, deployment pipeline. The boring-but-load-bearing layer. No user-visible features.
   - **Phase 2: Killer flow** (weeks N-M) — the one flow from spec.killer-flow walks end-to-end. v1 is mostly this.
   - **Phase 3: Surrounding features** (weeks N-M) — the rest of must-haves from PRD.
   - **Phase 4: Polish + launch prep** (weeks N-M) — performance, accessibility, error states, onboarding, analytics, observability floor.

   Sequence within phase is by dependency — auth before features that need auth, data model before features that read/write data.

4. **Milestones, not gantt charts.** Per phase: end-of-phase milestone (observable: "killer flow walks end-to-end on staging", not "Sprint 3 done"). 3-6 milestones across v1 total.

5. **Risks + buffer.** Each phase has at least one risk named (single biggest unknown). Total buffer: add 30% to estimates. (Engineering is consistently wrong about how long things take. Bake the failure in.)

6. **v2 sketch.** 3-5 bullets describing the next 3-6 months post-v1 launch. Drives platform / extension decisions in v1 ("we'll need a public API in v2, so design the internal API with that in mind").

7. **Submit + advance.** Mid-Specification, no gate. After submit, advance moves to step 12 (legal — last step!).

---

## Voice & rigor

- Concrete dates only if dates are real (real launch deadline, conference window). Otherwise weeks-from-start ("Week 3-6: Phase 2"). Dates without commitment rot fast.
- The killer flow gets a phase to itself. Don't split it across phases — it's the spine.
- Resist heroic estimates. Solo founder building v1 in 3 weeks works for very-small v1s; everything else slips.
- Risks are SPECIFIC. "Schedule slip" is not a risk; "OpenAI tokens may exceed budget if usage 3x our assumption — mitigation: per-user rate limit ships with auth" is.
- v2 vision is a sketch, not a plan. 3-5 bullets max. Anchors strategic decisions in v1.

## What this step does NOT do

- Sprint planning. Roadmap is months/phases; sprints are weeks. Sprints come post-pipeline.
- Detailed task breakdowns. Per-feature engineering specs come from `/sdd new <feature>` post-pipeline.
- Hiring plans. Cost-estimate touched team cost; hiring sequence is post-handoff.
- Post-launch growth roadmap. Post-launch territory (future MCP step 18+).
