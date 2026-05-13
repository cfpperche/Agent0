---
mode: draft-after-input
delegable: partial
delegation_hint: "draft the cost model from system-design — infrastructure, third-party services, team allocation — business model already confirmed with user"
---

# Step 10 — Cost Estimate

**Goal:** financial model for v1 — build cost (one-time / first 3 months) and run cost (per-month at expected scale). Plus the pricing/business model the product uses to monetise (if revenue-generating). Sub-agent does most of the math after the user locks the business model.

**Mode:** `draft-after-input`. Parent must confirm with user: pricing model (free / freemium / one-time / subscription / usage-based / hybrid / not-for-profit). Once locked, the model derivation is mechanical from system-design inputs.

**Output file (suggested):** `cost-estimate.md` in `docs/product/10-cost-estimate/`.

---

## How to conduct this step

1. **Read system-design.** Stack drives infra cost (managed Postgres vs self-hosted, Vercel vs Fly, etc); integrations drive third-party cost (Stripe fees, OpenAI tokens, etc); scale assumptions drive volume.

2. **Parent locks the business model (1-2 questions):**

   - "Pricing model: free, freemium, one-time purchase, subscription, usage-based, hybrid, or not-for-profit?"
   - "If revenue-generating: ballpark target price point? (Order of magnitude — $10/mo, $100/mo, $1k/mo, $10k/mo — not exact)"

   If not-for-profit / internal tool, skip the pricing portion; cost model still applies.

3. **Drafting delegates.** With model locked, the sub-agent:
   - **Build cost** — estimate dev time (in weeks or person-months) for v1 scope from the PRD + system-design. Convert to dollars using a sensible rate placeholder. Acknowledge it's an estimate.
   - **Run cost / month at expected scale** — infrastructure line items (hosting, database, CDN, storage, monitoring), third-party SaaS (auth provider, payment provider, email, AI APIs if used). Per-line: vendor name, pricing tier, expected monthly cost at the v1 scale-assumption.
   - **Revenue model** (if applicable) — pricing tiers, projected ARR at 100/1000/10000 users at conservative paid conversion rates. Unit economics: CAC placeholder, payback period back-of-envelope.
   - **Break-even** — at what user count does revenue cover run cost.

4. **Mark estimates clearly.** Every number that's not a current vendor price gets `[Estimated]`. The PRD's success-metric should inform the scale-assumption used.

5. **Sensitivity callouts.** Where small assumption changes blow up the cost — name them. ("If OpenAI tokens hit 10x the projection, monthly cost moves from $400 to $4000 — usage cap recommended in implementation.")

6. **Submit + advance.** Mid-Specification, no gate. After submit, advance moves to step 11 (roadmap).

---

## Voice & rigor

- Estimates marked `[Estimated]` are fine; numbers presented as facts when they aren't are not. Vendor pricing pages are factual; user-count projections are estimates.
- Order of magnitude is what matters. "$2k/mo at 1000 users" is useful; "$2,143/mo at 1000 users" is false precision.
- Build cost is the most-likely-wrong number. Use a range, not a point. ("12-20 weeks at $150/hr = $72k-120k").
- If unit economics don't work (run-cost-per-user > price), surface this loudly. Don't bury it.
- For not-for-profit / internal tools, the cost model is still useful — it justifies budget asks and surfaces vendor lock-in cost.

## What this step does NOT do

- Detailed financial planning. This is a one-page-ish artifact for the product spec, not a CFO model.
- Pricing decisions. Pricing tier values are an estimate / starting point; real pricing comes from market test.
- Fundraising deck inputs. Step 17 GTM (future MCP).
- Capacity planning under viral growth. v1 scale assumption.
