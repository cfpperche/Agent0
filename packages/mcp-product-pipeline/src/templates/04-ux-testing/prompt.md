---
mode: draft-after-input
delegable: partial
delegation_hint: "draft the UX testing report in the validation_mode the user already declared; raw observations or founder's bet rationale will be in the parent's conversation"
---

# Step 4 — UX Testing

**Goal:** declare HOW the concept was validated before crossing into Identity phase. Three legal modes — pick exactly one. The mode is recorded in `.state.json.validation_mode` and gates further decisions downstream.

**Mode:** `draft-after-input`. The parent MUST conduct the mode-selection dialogue with the user (it's a posture choice, not a writing task). Once declared, the report writing can delegate.

**Output file (suggested):** `validation-report.md` in `docs/product/04-ux-testing/`. The artifact MUST contain a line of the exact shape `validation_mode: <tested|intuition|not-applicable>` (the MCP regex-extracts this and stores it in state).

---

## The three validation modes

| Mode | When to use | Required evidence |
|---|---|---|
| `tested` | You ran a real UX test (5+ users, prototype clickthrough, structured observations) | Test report — recruits, tasks, observations, verdict |
| `intuition` | Founder's bet — no users tested yet, but the segment/comparables/differentiation argument is strong enough to proceed and validate post-launch | Articulated bet — why this segment, what comparables exist, what makes the differentiation defensible |
| `not-applicable` | Non-software product class where UX testing as conventionally defined doesn't fit (e.g. infrastructure tool, API-only product, narrow internal automation) | Statement of why not-applicable + what substitute signal will validate post-launch |

There is no fourth mode. "Skip" is `not-applicable`; "I'll do it later" is `intuition` (you're betting it works).

---

## How to conduct this step

1. **Parent asks the user:** "How was this concept validated — `tested` (you ran a real UX test), `intuition` (founder's bet, validate post-launch), or `not-applicable` (non-software-product class where UX testing doesn't fit)?"

2. **Based on mode, gather the right input:**

   - **`tested`:** ask for the test report contents — number of users, what they were asked to do, what you observed, the verdict (PROCEED / PIVOT / KILL). If you have a separate `report.md` or notes, ask for the path.

   - **`intuition`:** ask the user to articulate the bet — which user segment, what comparables exist, what makes the differentiation defensible. Push for specificity. "I think it'll work" is not an articulated bet.

   - **`not-applicable`:** ask why testing doesn't fit AND what post-launch signal will validate. ("DAU is meaningless for a CLI library; PyPI download trajectory + GitHub stars in month 1 is the proxy.")

3. **Drafting can delegate.** Once mode + input are in hand, the artifact writing is mechanical synthesis. Either parent writes inline OR `product_get_delegation_brief(4)` + `Agent` dispatch.

4. **The artifact MUST include the `validation_mode:` line.** Place it near the top, on its own line. The MCP's `product_step_submit` regex-extracts it and stores in `.state.json.validation_mode` so step 5+ can reference.

5. **Submit + gate.** Step 4 is the LAST step of Discovery phase. After `product_step_submit`, calling `product_advance` returns `code: "gate-required", phase: "discovery"`. The parent then asks the user to explicitly confirm the discovery phase is closed, calls `product_gate_pass("discovery")`, then `product_advance` again to enter Identity phase (step 5 brand).

---

## Voice & rigor

- Be honest about which mode you're in. The choice has downstream consequences — `intuition` mode commits the team to validate post-launch, which means metrics infrastructure and a feedback loop need to exist in step 17 (GTM, future MCP). Declaring `tested` without real tests is the worst posture: you skip the bet AND don't have the evidence.
- For `tested`: include the recruits' demographics/role even briefly. "5 designers from agencies" beats "5 users".
- For `intuition`: cite at least 2 comparable products by name, and name what the differentiation is. Vague "we're like X but better" is not enough.
- For `not-applicable`: name the substitute signal explicitly. "Post-launch validation via PyPI download trajectory month-over-month, target 200+ in month 1" is concrete.

## What this step does NOT do

- Pick the validation mode FOR the user. The mode is a posture decision; the user owns it.
- Replace real UX testing. `intuition` mode is legitimate but is a bet, not a substitute for evidence.
- Cross the discovery gate automatically. `product_advance` after step 4 deliberately requires explicit `product_gate_pass("discovery")` so the phase transition is a conscious decision.
