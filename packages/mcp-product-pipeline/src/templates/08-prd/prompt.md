---
mode: draft-after-input
delegable: partial
delegation_hint: "draft the PRD synthesising concept, spec, prototype-v2 — user priorities already locked; you produce the structured document"
---

# Step 8 — PRD (Product Requirements Document)

**Goal:** the canonical product spec — what's in v1, what's out, what success looks like, acceptance criteria. The PRD is the artifact engineering (step 9 system-design) and downstream execution (`/sdd new` post-handoff) consume.

**Mode:** `draft-after-input`. Parent must extract two pieces of input from the user that no prior artifact captured: feature priority (must-have vs nice-to-have for v1) and success metric (the single observable result that says v1 worked). Once those are locked, the document writing delegates.

**Output file (suggested):** `prd.md` in `docs/product/08-prd/`.

---

## How to conduct this step

1. **Read everything prior.** Concept brief (1), spec (3), prototype-v2 (7). The PRD is mostly synthesis of these with two priority calls layered on top.

2. **Parent collects priority + metric (2 questions):**

   - "Walk through the feature list from the spec — for each, is it must-have, should-have, or nice-to-have for v1?" (Force the cut. If everything is must-have, the v1 is too big.)
   - "What's the single observable metric that says v1 worked? Pick one — not three. DAU? Activation rate? Revenue? NPS? Time-to-value? Something custom?"

   Optionally a third: "Launch timeline — soft target (week / month / quarter)? This shapes what's in v1 vs v2."

3. **Drafting delegates.** With priorities + metric locked, the PRD is structural synthesis. Sub-agent reads the prior artifacts + the priority notes + writes the document.

4. **Acceptance criteria are BDD scenarios.** For each must-have feature, write 2-4 Given/When/Then scenarios. These map directly to test cases in implementation and to engineering specs in the post-pipeline `/sdd` phase.

5. **Submit + advance.** Mid-Specification phase. After submit, advance moves to step 9 (system-design — pure synthesis, fully delegable).

---

## Voice & rigor

- Cut hard. v1 PRDs that list 30 must-haves don't ship. 5-10 must-haves with a thesis is shippable.
- Acceptance criteria are observable behaviors, not implementation details. "User can mark task done" is implementation; "When user clicks 'Done' on a task in dashboard, the task disappears from active list and appears in 'Completed' with timestamp" is acceptance.
- Success metric is non-negotiable. Two metrics = no metric (every team optimizes the easier one). Pick ONE.
- Open questions / known unknowns belong in the PRD explicitly. "Pricing model TBD — see step 10" is fine; pretending you have an answer when you don't isn't.

## What this step does NOT do

- Architecture / stack decisions. Step 9 system-design.
- Pricing / cost modeling. Step 10 cost-estimate.
- Release sequencing within v1. Step 11 roadmap if v1 ships in stages, otherwise the PRD is monolithic.
- Marketing positioning / launch strategy. Step 17 GTM (future MCP).
- Engineering specs / task decomposition. That's the `/sdd new <feature>` post-pipeline phase.
