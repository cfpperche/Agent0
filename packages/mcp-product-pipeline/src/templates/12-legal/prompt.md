---
mode: synthesis
delegable: true
delegation_hint: "draft the legal & compliance posture for v1 — terms, privacy, data handling, regulated-aspect treatments — derived from PRD audience and system-design integrations"
---

# Step 12 — Legal

**Goal:** the FINAL step. Legal & compliance posture for v1 — what terms apply, what data is collected and how it's handled, which regulations matter, what licenses the product is published under. Sub-agent territory: derives from PRD (audience + integrations), spec (data handled), and system-design (where data lives). When step 12 closes, the planning pipeline is DONE.

**Mode:** `synthesis`. Fully delegable. The sub-agent reads prior artifacts and produces a structured posture document. This is NOT legal advice — it's the founder's articulation of intended posture, used to brief actual legal counsel later.

**Output file (suggested):** `legal-posture.md` in `docs/product/12-legal/`.

---

## How to conduct this step

1. **Read PRD + spec + system-design + brand.** PRD names the user (jurisdiction often implied by target audience); spec names what data is handled; system-design names where it lives + which third parties touch it; brand sometimes implies posture (consumer-friendly vs enterprise-formal terms).

2. **Cover the standard posture areas:**

   - **Terms of Service.** Acceptance model (clickwrap vs browsewrap), key clauses (acceptable use, payment / cancellation, dispute resolution, governing law jurisdiction). Note known-unknown: "Counsel to review."
   - **Privacy posture.** What PII is collected, where it's stored (cite system-design data-model), with which third parties it's shared (cite integrations), retention period, deletion mechanism. Cookie posture if web. GDPR / CCPA / LGPD applicability based on audience.
   - **Data handling.** Encryption at rest / in transit, backup retention, breach notification commitment, sub-processor disclosure (Stripe, OpenAI, etc — the integrations from step 9).
   - **Licensing.** If shipping open-source components, license compatibility. If publishing OSS, the project's own license choice with rationale.
   - **Regulated aspects.** If product touches PII / money / health / minors / employment / fairness — call out the specific regulatory frames (HIPAA / GDPR / COPPA / SOC2 / PCI / etc) that apply and the posture toward them.
   - **AI-specific concerns (if AI is in the stack).** Training-data provenance, model-output liability, user disclosure of AI involvement, opt-out from data usage for model improvement.

3. **The escape clause.** Top of document: "This is the founder's articulated legal posture for v1, NOT legal advice. Counsel review required before launch." Real lawyers write the actual ToS / Privacy Policy.

4. **Submit + final gate.** Step 12 closes the Specification phase AND the pipeline. After submit, `product_advance` returns `code: "gate-required", phase: "specification"`. Parent confirms with user, calls `product_gate_pass("specification")`, then `product_advance` returns the `pipeline-complete` signal with the `/sdd new <slug>` handoff. The parent then calls `product_done` for the full deliverable summary.

---

## Voice & rigor

- This artifact is for briefing real counsel, not replacing them. Write it in a way a non-lawyer founder can hand to their lawyer and have a productive 30-minute conversation.
- Cite the system-design integrations explicitly. "We use Stripe (system-design § integrations) — Stripe's data-processing addendum applies; PCI scope reduced to the redirect/tokenization model."
- Regulated-aspect callouts are mandatory if any apply. Don't bury them. "This product collects health data (PRD § users — fitness coaching context) — HIPAA may apply; counsel must confirm whether covered-entity vs business-associate model fits."
- Open-source license choice should be deliberate. MIT / Apache 2.0 / AGPL each have downstream consequences; pick with reasoning.
- The escape clause is at the TOP, not the bottom. Visibility matters.

## What this step does NOT do

- Draft actual ToS / Privacy Policy. Those are lawyer artifacts. This document is the BRIEFING for that work.
- Tax / corporate structure decisions. Different category, different professional.
- Trademark / patent strategy. Brand book (step 5) mentioned name; trademark search is outside scope.
- Employment / IP-assignment agreements. Separate corporate artifact.

---

## When this step closes

When `product_step_submit` succeeds for step 12 AND `product_gate_pass("specification")` is called AND `product_advance` returns `pipeline-complete`:

1. Parent calls `product_done` for the final summary.
2. Summary names the deliverables per phase and the literal `/sdd new <slug>` command to begin engineering execution.
3. User comments out the `product-pipeline` block in `.mcp.json`, restarts session, and continues with Agent0 base + `/sdd` for implementation.

The MCP has done its job.
