---
mode: synthesis
delegable: true
delegation_hint: "draft the system design — stack, services, data model, integrations, deployment topology — from the PRD; no user input required, pure synthesis"
---

# Step 9 — System Design

**Goal:** technical architecture for v1 — stack choices, service decomposition, data model, key APIs, integrations, deployment shape. The artifact engineering reads to start building.

**Mode:** `synthesis`. Fully delegable. Sub-agent reads `docs/product/08-prd/` (and earlier artifacts if needed for context) and produces the design without user input. This is the canonical example of why the MCP architecture pays off: this step generates 5-15 KB of design content that the parent never needs to load.

**Output file (suggested):** `system-design.md` in `docs/product/09-system-design/`. Diagrams as text (mermaid, ascii) or referenced as images in a `diagrams/` subfolder.

---

## How to conduct this step

1. **Read the PRD.** v1-scope drives surface area; success-metric drives scaling assumptions; acceptance-criteria drives functional contracts.

2. **Stack — pick concretely.** Don't write "a modern web framework"; write "Next.js 15 App Router + React Server Components" or whatever the actual choice is. Cite the choice rationale (1-2 lines per choice): why this language, why this framework, why this database. Avoid resume-driven design ("we use Kafka because it's cool"); justify against the PRD.

3. **Service decomposition.** Most v1s are monoliths. State that clearly if so. If multi-service, name each service + responsibility + how they communicate (REST / RPC / events / shared DB).

4. **Data model.** Entities + relationships. Don't draw full ER diagrams; a typed pseudo-schema is enough:
   ```
   User { id, email, name, created_at, ... }
   Project { id, user_id (FK), title, ... }
   Task { id, project_id (FK), title, status: enum, ... }
   ```
   Mention key indexes, soft-delete posture, multi-tenancy strategy if relevant.

5. **APIs / interfaces.** Public API endpoints, internal service boundaries, third-party integrations. Don't write OpenAPI specs — that's implementation. Name endpoints + their contract intent ("`POST /tasks/:id/complete` — moves task to completed, returns updated task object").

6. **Integrations.** Third-party services (Stripe, Resend, Auth0, Cloudflare R2, OpenAI API, etc). Per integration: what it's used for, alternative considered + rejected, vendor lock-in posture.

7. **Deployment shape.** Where it runs (Vercel / Fly / Railway / AWS / on-prem), CI/CD shape, secrets management, observability floor (logs at minimum, metrics if scaling matters).

8. **Non-functional concerns.** Performance budgets (target p95 latency, etc), security floor (auth model recap from spec, rate limiting, secrets handling), scale assumptions (target concurrent users for v1).

9. **Submit + advance.** Synthesis-mode; no gate. After submit, advance moves to step 10 (cost-estimate — draft-after-input).

---

## Voice & rigor

- Justify choices against the PRD, not abstract preferences. "Postgres because we need transactional consistency on the task-completion event" beats "Postgres because it's reliable".
- Resist over-engineering. v1 with 5 microservices that talk over Kafka is wrong unless the PRD's scale assumptions demand it.
- Alternatives considered matter. Per major choice (stack, DB, deployment platform), name 1-2 alternatives rejected with reason. This catches resume-driven design and surfaces tradeoffs for review.
- Diagrams beat prose for topology. A text-based mermaid sequence diagram for the killer flow is worth a page of words.
- Note where the design is uncertain. "Background job queue: TBD between BullMQ and SQS — decide in implementation when actual job volume is known" is fine.

## What this step does NOT do

- Engineering specs / tasks. That's `/sdd new <feature>` post-pipeline.
- Implementation. No code. No package versions (just framework names + major versions).
- Operations runbooks. Post-launch territory.
- Cost modeling. Step 10 cost-estimate (which reads this design to model infra cost).
