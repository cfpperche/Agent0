---
mode: synthesis
delegable: true
delegation_hint: "draft step-9 system-design bundle — system-design.md (stack, services, data model, apis, integrations, deployment, non-functional, evaluation table, alternatives considered, decisions locked, open decisions) + architecture.json (component graph derived from system-design.md) + security.md (threat model, auth/authz, data classification, secrets, regulated aspects) — synthesising step 3 architecture.md skeleton + step 8 PRD; no user input required; fully delegable"
---

# Step 9 — System Design

**Goal:** technical architecture for v1 — stack choices, service decomposition, data model, APIs, integrations, deployment topology, non-functional posture, security floor. The artifact engineering reads to start building (`/sdd new <feature>` consumes this design post-pipeline). **Deepens step 3's preliminary `architecture.md` skeleton** into the production design.

**Mode:** `synthesis` with `delegable: true`. Fully delegable. Sub-agent reads `docs/product/03-spec/architecture.md` + `docs/product/08-prd/prd.md` (plus earlier artifacts for context) and produces the design without user input. This step generates 20+ KB of design content that the parent never needs to load — canonical example of why MCP architecture pays off.

**Output bundle** (all written atomically via one `product_step_submit` call — primary `content` + `extra_files`):

| File | Role | Floor |
|---|---|---|
| `system-design.md` | primary — the design itself; the document engineering consumes | ≥ 20 KB |
| `architecture.json` | machine-readable component graph derived from system-design.md (renders to HTML in a future visualisation refinement; spec 026 ships JSON-only) | structural shape — `title`, `components[]`, `arrows[]`, `summary_prose` |
| `security.md` | sibling — threat model + security posture, deeper than a single section in system-design.md | ≥ 3 KB |

---

## How to conduct this step

Read `references/architecture-shape.md` for the section catalogue + derivation chain (step 3 → step 9). Read `references/security-section.md` for the threat-model lens (STRIDE-lite + OWASP top-10) + auth/authz floor. Read `references/scale-assumptions.md` for how to derive perf budgets from the PRD's success metric + the over-engineering anti-pattern catalog.

### 1. Read everything prior

- **PRD** — `docs/product/08-prd/prd.md`. v1-scope drives the design's surface area (P0 requirements name the entities, APIs, integrations); success-metric drives scaling assumptions; acceptance-criteria-per-user-story drives functional contracts the design must satisfy.
- **Functional spec + preliminary architecture** — `docs/product/03-spec/functional-spec.md` + `docs/product/03-spec/architecture.md`. The spec's pages/components/interactions are what the design must implement; `architecture.md` is the *skeleton* this step deepens — same modules, same entities, same flows, but with concrete tech choices, deployment shape, non-functional rigor, and full security treatment.
- **Concept brief** — `docs/product/01-ideation/04-concept-brief.md`. Scale class + persona for sanity-check ("does this design fit a micro-product or an SMB SaaS?").

If the PRD is missing or thin, stop and report to the parent — the design is synthesis of the PRD, not invention. If `architecture.md` is missing (step 3 not yet ported, or skipped), call it out in `## Open Decisions` and proceed with the PRD alone.

### 2. The two-floor depth ladder (bridge-floor → canonical-rigor)

**Bridge-floor (minimum)** — the consolidated decisions already locked in the PRD's Technical Considerations + Open Questions resolutions. Mirror the 6 sections from the anthill `system-design-bridge` skill: stack / integrations / data model / decisions locked / security & privacy / observability. Every system-design.md MUST cover at least these.

**Canonical-rigor (the 20 KB target)** — add the design rigor the PRD didn't capture: service decomposition with comms protocol, full API endpoint catalog with contract intent, deployment topology, non-functional budgets (perf / reliability / scale), the principal-engineer evaluation table (Simplicity / Reliability / Scalability / Operability / Security with concern levels), the trade-offs table (Option / Pros / Cons / Recommendation per major decision), alternatives considered per major choice with reasoning.

The depth scales with the product's complexity. A micro-product PRD with 3 user stories produces ~12 KB system-design.md and may not need the trade-offs table; an SMB SaaS PRD with 25+ user stories lands ≥ 25 KB and exercises the full canonical rigor. The 20 KB Layer-1 floor is the universal sanity line for v1 SMB-SaaS-or-larger products; compact-mode micro-products may legitimately land under and require the `# OVERRIDE: tdd-exempt: <reason>` shape adapted to system-design ("# OVERRIDE: compact-product: <product class>"). Default to SMB SaaS Full depth when the brief is silent.

### 3. The canonical system-design.md structure

The primary writes against this 11-section spine (full shape with depth conventions lives in `references/architecture-shape.md`):

1. **Overview** — one paragraph: what's being built, who it serves, where the system runs. Names the product class (micro / mobile / dev-tool / SMB-SaaS / venture-scale) inherited from the brief so depth calibration is visible.
2. **Stack** — concrete language + framework + database + ORM + frontend choices with version major. One sentence rationale each, anchored to the PRD's success metric or a v1 constraint (NOT abstract preference). Anti-pattern: "Postgres because it's reliable"; good: "Postgres because the task-completion event needs transactional consistency across the analytics-event write and the kanban-position update (US-07, US-12)".
3. **Services** — service decomposition. Most v1s are monoliths — state plainly if so. Modular monolith / multi-service variants name each service + responsibility + communication protocol (REST / RPC / events / shared DB). Anti-pattern: 5 microservices for a v1 with 8 P0 requirements.
4. **Data model** — entities + relationships in typed pseudo-schema. Key indexes, soft-delete posture, multi-tenancy strategy (if applicable). Cross-references the PRD's user-story IDs (`US-NN`) so a reader can trace each entity back to the requirement that needs it. Derived from `architecture.md § Data Model` and deepened.
5. **APIs** — endpoint catalog (public + internal). One row per endpoint with `Method | Path | Contract intent | Source`. Don't write OpenAPI specs — that's implementation. Name endpoints + contract intent ("`POST /tasks/:id/complete` — moves task to completed, returns updated task object, emits `task.completed` event").
6. **Integrations** — third-party services + per-integration: what it's used for, alternatives considered + rejected with one-line reason, vendor lock-in posture (replaceable / sticky / load-bearing). Stripe / Resend / Auth0 / Cloudflare R2 / OpenAI API / etc.
7. **Deployment** — host (Vercel / Fly / Railway / AWS / on-prem), CI/CD shape, secrets management, observability floor (logs at minimum, metrics if scale matters, distributed tracing if multi-service). Region posture + multi-region strategy if compliance demands it.
8. **Non-functional** — perf budgets (target p95 latency, p99 outliers acceptable), scale assumptions (target concurrent users for v1 derived from PRD success metric — see `references/scale-assumptions.md`), reliability posture (target uptime, RTO/RPO if data is precious), accessibility floor (WCAG inherited from step 4 audit).
9. **Evaluation** — the principal-engineer assessment table. Five dimensions × three concern levels:
   ```markdown
   | Dimension | Assessment | Concern Level |
   |---|---|---|
   | Simplicity | <one-line> | Low/Medium/High |
   | Reliability | <one-line> | Low/Medium/High |
   | Scalability | <one-line> | Low/Medium/High |
   | Operability | <one-line> | Low/Medium/High |
   | Security | <one-line> | Low/Medium/High |
   ```
   Each row's Assessment column is ONE specific sentence ("Single Postgres instance, no read replica — recovery requires restore-from-backup with ~30 min RTO"), not abstract praise. Concern Level is the honest take, not aspirational.
10. **Alternatives considered** — per major choice (stack, DB, deployment platform, auth, payment), 1-2 alternatives rejected with one-line reason. Catches resume-driven design AND surfaces tradeoffs for the founder's review. Format:
    ```markdown
    ### Stack: chose Next.js + Postgres + Prisma
    - **Rejected: Remix + Postgres + Drizzle.** Remix's nested-route model is a better fit for nested resources but adds learning cost for the EM persona who's used to App Router. Drizzle's edge-runtime story is stronger but Prisma's mature migrations matter more at v1.
    - **Rejected: T3 stack (Next + tRPC + Prisma).** tRPC's type-safety is appealing but commits us to TypeScript on both ends; we want the option to add a Python ML service later (US-23 — sentiment analysis backlog item).
    ```
11. **Decisions locked / open** — two sub-sections.
    - **Decisions locked**: table consolidating the decisions the PRD already resolved (the bridge-skill role — extract from PRD's `## Technical Considerations` + Open Questions that PRD resolved). One row per decision: `# | Decision | Choice | Source (PRD §)`.
    - **Open decisions**: things this step deferred to implementation OR genuinely unresolved. Each carries the deciding signal that will close it ("Background job queue: BullMQ vs SQS — decide when actual job volume known, likely 2 weeks post-launch"). Open decisions without a deciding signal are red flags — name the trigger.

### 4. Derive `architecture.json`

The architecture JSON is a machine-readable component graph derived from system-design.md — same services, entities, and flows reformatted for tooling consumption. JSON-only in spec 026; a future refinement may add HTML rendering (see `references/architecture-shape.md § JSON-to-HTML refinement deferred`).

Required top-level shape:

```json
{
  "title": "<Product Name> — System Architecture v1",
  "summary_prose": "One-to-three-sentence plain-language description (becomes <figcaption> when rendered).",
  "components": [
    { "id": "web", "label": "Web App", "type": "frontend", "sublabel": "Next.js 15 App Router" },
    { "id": "api", "label": "API", "type": "backend", "sublabel": "Next.js Route Handlers" },
    { "id": "db", "label": "Postgres", "type": "db", "sublabel": "Supabase managed" }
  ],
  "arrows": [
    { "from": "web", "to": "api", "label": "REST" },
    { "from": "api", "to": "db", "label": "Prisma" }
  ]
}
```

`type` enum: `frontend | backend | db | cloud | security | bus | external`. Categorise each component honestly — `external` for third-party (Stripe, Resend), `cloud` for managed infra without a behavioural role (CDN, Cloudflare R2), `security` for auth gateways / WAF / IAM. The future renderer maps type → palette; categorisation now keeps later visualisation cheap.

`arrows[].from` and `.to` MUST reference component IDs that exist in `components[]`. Mismatched IDs are caught at submit time.

### 5. Write `security.md`

Sibling file (NOT a section in system-design.md) so step 12 (legal-posture) and downstream consumers can cite security.md directly without scraping section anchors. Required sub-sections:

- **Threat model** — STRIDE-lite (Spoofing / Tampering / Repudiation / Information disclosure / Denial of service / Elevation of privilege) or OWASP top-10 lens. For each row, the relevant risk for this product + the mitigation posture at v1 (or `accepted` with rationale if v1 deliberately defers).
- **Auth / authz** — auth model (session / JWT / OAuth provider), authz model (role-based / per-resource / org-scoped), session lifecycle, MFA posture.
- **Data classification + retention** — what data is collected, classification tier (public / internal / PII / regulated), retention window per tier, deletion posture (hard / soft / anonymised). GDPR/LGPD posture if PII is collected.
- **Secrets handling** — where secrets live (env vars / vault / cloud KMS), rotation posture, exposure surface (which secrets land in which deployment artifact).
- **Regulated aspects** — flag domain-specific regulation (HIPAA for health, PCI for payment, SOC 2 if enterprise-target, AI-specific governance if LLMs are user-facing). Cross-reference step 12 (legal-posture) for the full compliance treatment; this is the engineering-readable summary.

Depth ladder: micro-products may land at 3-4 KB; SMB SaaS and venture-scale typically 5-10 KB. The 3 KB floor is universal sanity; deeper is welcome.

### 6. Calibrate by product class (smart, not rigid)

| Product class (concept brief § Identity · Scale) | system-design.md depth | Sections to keep / cut |
|---|---|---|
| **Micro-Product / CLI helper / single-purpose tool** | Compact (~12 KB; may trigger override) | Keep 1, 2, 4, 5 (1-3 endpoints), 7 (host + secrets), 8 (perf only), 11. Cut 3 (monolith-only), 9 (table optional), 10 (1 alternative per major choice) |
| **Mobile App** | Standard (~20 KB) | Full structure; § 7 covers app-store deployment + crash reporting |
| **Developer Tool / API-first** | Standard-Expanded (~22 KB) | Full structure; § 5 grows (rate-limit posture, SDK versioning, deprecation policy); § 8 covers SLA |
| **SMB SaaS (the spec 026 default)** | Full (~22-28 KB) | Full structure; § 6 typically 5-10 integrations; § 11 carries 3-5 open decisions |
| **Venture-Scale / Marketplace / multi-persona** | Expanded (~28-40 KB) | Full structure + § 3 multi-service decomposition; § 8 expands to per-region scaling; § 11 carries the multi-team coordination decisions |

Brief field missing or ambiguous → default to **SMB SaaS (Full)**. Mark the chosen depth in `## Overview` opening sentence ("v1 system design for an SMB SaaS — full template depth applied.").

### 7. Submit + advance

Call `product_step_submit` with:
- `step: 9`
- `filename: "system-design.md"`
- `content: <full system design>`
- `extra_files: [{ path: "architecture.json", content: <JSON string> }, { path: "security.md", content: <full security treatment> }]`

Layer 1 validates all three atomically — nothing is written unless every file passes. On `schema-incomplete`, the `failures` list names exactly which file failed which check (missing path / undersized / missing substring); fix and resubmit.

On success, `product_advance` moves to step 10 (cost-estimate — synthesis, reads this system-design.md + the PRD to model build cost + run cost + unit economics).

**No gate at step 9.** The next gate is at step 12 (closing Specification). Steps 8 → 12 advance fluidly through Specification phase.

---

## Voice & rigor

- **Justify against the PRD, not abstract preference.** "Postgres because we need transactional consistency on the task-completion event" beats "Postgres because it's reliable". Cite PRD section / user story / success metric per choice.
- **Resist over-engineering.** v1 with 5 microservices that talk over Kafka is wrong unless the PRD's scale assumptions demand it. The PRD's primary success metric is the rigor anchor — if "week-1 activation rate" is the target, you don't need a multi-region active-active setup.
- **Alternatives considered matter.** Per major choice (stack, DB, deployment platform, auth, payment), name 1-2 rejected alternatives with reason. This catches resume-driven design AND surfaces tradeoffs for review.
- **Diagrams beat prose for topology.** `architecture.json` (the component graph) carries the visual contract; system-design.md prose explains *why*, not *what* the diagram already shows.
- **Name uncertainty explicitly.** "Background job queue: TBD between BullMQ and SQS — decide in implementation when actual job volume is known" is honest; pretending the queue choice is locked when it isn't is the regression mode this section prevents.
- **Evaluation table concern levels are HONEST, not aspirational.** A v1 with a single Postgres instance and no read replica has `Reliability: Medium` (single point of failure, accepted at v1 scale) — not `Low` (which would imply HA setup that doesn't exist).
- **PRD user-story IDs (`US-NN`) cross-reference the design.** Entities, APIs, integrations cite the user story that needs them. This makes step 13 (prototype-v3) PRD-coverage scoring honest — every user story has a design path to a screen.

## What this step does NOT do

- **Engineering specs / tasks.** That's `/sdd new <feature>` post-pipeline. The system design is the contract; `/sdd` produces the implementation plan per feature.
- **Implementation.** No code. No package versions beyond major (Next.js 15, not 15.0.3). No file paths inside `src/`.
- **Operations runbooks.** Post-launch territory. The deployment section names the *shape*, not the operational playbook.
- **Cost modeling.** Step 10 cost-estimate consumes this system-design.md to model infrastructure cost + unit economics.
- **Full compliance treatment.** `security.md` is the engineering-readable summary; step 12 (legal-posture) is the canonical compliance artifact.
- **Marketing / GTM.** Step 17 GTM (future MCP).

## What this step replaces

Step 9 ports two anthill skills into one adaptive template:

1. **`anthill-system-design-bridge`** (169 LOC SKILL.md + 176 LOC `extraction-template.md` reference) — the light path for non-tested validation modes that consolidated decisions already locked in the PRD into 6 sections (stack / integrations / data model / decisions locked / security & privacy / observability). The MCP port absorbs this as the **bridge-floor** that every system-design.md must cover.

2. **`anthill-principal-engineer`** (159 LOC SKILL.md + 4 references — checklist 26 + diagram-design 78 + examples 33 + anti-patterns 26) — the canonical path with the 5-step process (context → evaluate → assess → checklist → diagram). The MCP port absorbs this as the **canonical-rigor** layered on top of the bridge-floor: evaluation table, trade-offs, alternatives considered, the architecture.json component graph.

Three points where the MCP port diverges from the anthill source:

- **Single-template adaptive depth, not two skills behind a `validation_mode` flag.** Anthill split bridge vs canonical via PRD frontmatter (`validation_mode: intuition | tested | not-applicable`). The MCP doesn't carry the `validation_mode` plumbing; the template grows depth based on the PRD's complexity (P0 count, integration count, persona count) rather than a flag. Compact-mode micro-products land at bridge-floor; SMB SaaS and venture-scale exercise canonical-rigor.
- **JSON-only architecture artifact in spec 026.** Anthill's `anthill-principal-engineer` Step 5c renders HTML via `.anthill/scripts/render-architecture-diagram.mjs` (Cocoon-AI-derived, MIT). The MCP port emits the structural JSON; HTML rendering is deferred to a post-spec-026 visualisation refinement (vendor the renderer into `packages/mcp-product-pipeline/scripts/`). Spec 026 V5 accepts "one of `architecture.json` / `architecture.html`" — JSON-only satisfies acceptance.
- **`security.md` sibling file, not a section in system-design.md.** Anthill's `principal-engineer` puts security treatment in the evaluation table + one section. The MCP port elevates security to a sibling so step 12 (legal-posture) and downstream consumers can cite security.md as a stable contract.

Anthill's `architecture.yaml` constraint (declared `pattern`, `layers`, `vertical_slice` that the assessment must respect or challenge) is not ported — the MCP doesn't model fork-level architecture constraints. If a fork needs this, it lives in the fork's `CLAUDE.md` and the agent reads it as ordinary repo context.
