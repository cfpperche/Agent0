---
mode: interactive
delegable: false
delegation_hint: "n/a — interactive step; parent must conduct the discovery interview directly"
---

# Step 1 — Ideation

**Goal:** produce a concept brief that names the product, the audience it serves, what makes it different from existing options, and the risks/assumptions worth surfacing before any prototype is drawn.

**Mode:** `interactive`. This step requires a 5–8 question discovery interview with the founder. Sub-agents have no user channel — the parent agent MUST conduct this step directly. Do NOT delegate via `product_get_delegation_brief`.

**Output file (suggested):** `04-concept-brief.md` in `docs/product/01-ideation/`. The filename is the agent's choice; only `.md` extension is enforced. Required sections are listed in `schema.md` — `product_step_submit` rejects with `schema-incomplete` if any are missing.

---

## How to conduct this step

1. **Open the conversation.** Tell the user this is step 1 of 12 (Discovery phase) and that the goal is to lock the product concept before drawing any screens. Keep the framing light — this is a working session, not an interrogation.

2. **Interview — 5 to 8 questions, one at a time.** Use the user's answers to refine subsequent questions. Sample questions to choose from (don't ask them all robotically; pick the ones that close the biggest gaps for the answers you've already gathered):

   - "What's the product in one sentence — the version you'd say to a friend, not the pitch deck version?"
   - "Who's the first user you have in mind? Be specific — role, company size or context, what they do today instead."
   - "What does this person try first when the problem hits, and what makes that attempt unsatisfying?"
   - "What's the closest thing that already exists? Why isn't it enough?"
   - "What does success look like 6 months in? Number of users, revenue, behavior change — pick whichever is meaningful."
   - "What's the single assumption that, if wrong, kills this idea?"
   - "Is there a regulated/sensitive aspect (PII, money, health, minors, employment, fairness) that you already know we'll have to design around?"
   - "Is this 'I want to learn / play' or 'I want to ship this to real users in 6 months'? Effort budget changes accordingly."

3. **Synthesise — draft the concept brief.** Cover at minimum the required sections in `schema.md`. Be concrete: name the audience by role + context, not "professionals". Quote the user's words where they're sharper than yours. Mark any factual claim about competitors / market size / pricing as `[Estimated]` unless cited.

4. **Cite sources.** If you make a factual claim about an existing competitor, a market trend, or any number, name the source inline as `(source: <url-or-publication>)`. If you have no source for a claim, soften it ("we believe", "Estimated") or drop it.

5. **Submit.** Call `product_step_submit` with `filename` and the full markdown content. If it rejects with `schema-incomplete`, add the missing section headers (`## Section Name` — slugified to lowercase-dashed for matching) and resubmit.

6. **Advance.** Once submission succeeds, call `product_advance`. Step 1 is mid-Discovery (no phase gate yet — that comes after step 4), so advance moves directly to step 2 (prototype).

---

## Voice & rigor

- Translate user input into a brief; don't editorialise.
- Prefer specific over generic. "A solo accountant who serves 30 small-business clients" beats "small business professionals".
- Risks section is for things that would change the product if wrong — not generic startup risks ("market may not exist"). Be precise: "Risk: users won't pay for an AI co-pilot when ChatGPT exists for free — mitigation: deliver a workflow ChatGPT can't, not just an interface to it."
- The brief should be readable in 3 minutes. If it's longer, you're padding.

## What this step does NOT do

- This is not a PRD. PRD comes in step 8 with detailed requirements, user stories, acceptance criteria.
- This is not a market research deep dive. Step 1 captures the founder's clearest articulation of the concept; market validation happens in steps 3 (spec) and 4 (ux-testing).
- This is not a business plan. Cost estimate and roadmap come in steps 10 and 11.
