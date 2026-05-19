# 032 — pipeline-industry-alignment

_Created 2026-05-17._

**Status:** superseded by 048-product-skill-foundation

## Intent

Realign `packages/mcp-product-pipeline` (spec 025 + spec 026 baseline) against 2025-2026 industry standards for product development pipelines. The current 13-step shape was lifted from `anthill/.anthill/config/pipeline.yaml` (steps 1-12) plus a step-13 synthesis; web research (48 sources, captured 2026-05-17) surfaced 8 substantive gaps and 2 unconventional choices vs Marty Cagan/SVPG, Teresa Torres, Atlassian/ProductPlan/Productboard, Lenny Rachitsky, Stage-Gate, Lean Product Process, Shape Up, and GDPR Art 25 / shift-left literature. The triggering symptom: step 13 dogfood (Octant Linear-clone) produced 9 screens covering 16 PRD user-stories, but the user observed the atlas misses surfaces a real user encounters (login, password reset, team invite, error pages, issue creation, billing flow). Root cause per research: PRDs scope user-stories, sitemaps scope screen inventory — and we have no IA/sitemap step. Adjacent root causes: PRD is monolithic+static (industry says release-scoped+living), legal sits at the end (GDPR mandates by-design + DPIA-before-processing), no market-research/problem-validation/GTM/post-launch steps. This spec is the **parent**: it locks the new pipeline shape, the new artifact responsibilities, the new gate placements, and the decomposition into N child specs that ship the change incrementally.

## Acceptance criteria

_Three classes of criteria below: (A) shape decisions locked in this spec; (B) child-spec decomposition; (C) verification that the new pipeline produces "all screens a user sees" on a redogfood of the Octant case._

### A. Shape decisions locked

- [x] **Decision 1: PRD shape = Camp C (hybrid).** PRD becomes a 1-pager (problem · why-now · success-metrics · top 3-5 user-stories with stable US-NN IDs); Opportunity Solution Tree (OST, Torres) becomes a sibling living artifact; the hi-fi prototype (renamed step) is the executable spec engineering consumes. PRD is release-scoped — each release (v1, v2, vN) gets its own 1-pager + OST snapshot.
- [x] **Decision 2: Pipeline scope = Option 3.** Core pipeline ends at `/sdd` handoff (status quo); add a callable, repeatable `post-launch-review` step that captures real-world metrics vs declared success-metrics, updates OST with new opportunities, and decides whether to ship PRD-v2 or stay on v1. The new step is NOT part of the linear `GATE_AFTER` sequence — it is invoked by founder intent post-launch, N times per product.
- [x] **Decision 3: Brand × PRD order = Option 2 (PRD-first).** PRD (1-pager) precedes brand-book. Industry default (Formlabs/Aha/Atlassian); with PRD shrunk to 1-pager (Decision 1), brand-first ordering loses its justification (1-pager doesn't need voice-tuned upfront; brand fully lands in design-system + prototype).
- [x] **Decision 4: Legal placement = shift-left.** GDPR Art 25 + DPIA-before-processing + IAPP/ICO shift-left posture obligate legal as a planning-phase artifact, not an end-of-pipeline gate. Legal moves into the Specification phase adjacent to system-design (instead of step 12 final position). DPIA is triggered by system-design's data-flow inventory.
- [x] **Decision 5: Sitemap / Information Architecture = own step.** This is the root cause of the "atlas sub-covers" symptom. PRDs enumerate user-stories (P0/P1/P2 priorities); sitemaps enumerate **full screen inventory** including auth set (login, signup, password-reset, email-verify, invite-accept), error/empty/404, admin/team-management, and CRUD-creation flows. Sitemap step sits between PRD/OST and prototype-v3 (atlas) and is the spine the atlas inherits from.
- [x] **Decision 6: Market/competitive research + problem-validation = folded into Discovery.** Step 1 (ideation) extends to include lightweight market sizing (TAM/SAM/SOM brief) + 3-5 problem-validation interview summaries seeding the OST. Not new steps — bullet expansion of existing step 1 + step 3 (early-spec). Avoids over-stepifying the discovery phase.
- [x] **Decision 7: GTM / launch / positioning = own step.** Sits in the Specification phase between roadmap and the visual-contract handoff. Industry-mandatory (Stage-Gate stage 6, Asana 9-step GTM, HubSpot, PMA). Cost-estimate (steps 10) covers financial model — NOT positioning, launch plan, or pricing strategy.
- [x] **Decision 8: 3-stage prototype = collapsed to 2 stages.** Cagan-aligned: lo-fi (current step 2, discovery) + hi-fi (renamed step, visual-contract handoff). Current step 7 (prototype-v2 — brand+tokens applied to killer flow) is folded INTO the hi-fi prototype's responsibility — there is one final prototype, not two named refinements. Reduces conceptual overhead and aligns with SVPG "Flavors of Prototypes".
- [x] **Decision 9: North Star metric = artifact within PRD 1-pager.** PRD's success-metrics line carries the NSM + supporting metrics. Not a separate step. Acceptance criteria in PRD reference the NSM.
- [x] **Decision 10: RACI / risk register = folded into system-design.** Not a separate step. System-design carries the risk register, dependency map, and stakeholder RACI matrix as required sections.
- [x] **Decision 11 (resolves Q1): post-launch-review = sibling-not-step.** Out of `STEPS` array. New `POST_LAUNCH_ACTIONS` array in `pipeline.ts` + dedicated MCP tool surface (`product_post_launch_review_start` / `_get` / `_submit`). Industry-aligned with Stage-Gate stage 6 + Build-Measure-Learn loop being structurally distinct from planning stages. Type system stays clean — `STEPS` keeps `n: number`; sibling has its own type.
- [x] **Decision 12 (resolves Q2): OST = own linear step.** Separate directory between Discovery and PRD-1pager. Lifecycle: initial snapshot during planning (linear), updates via Decision 11 sibling post-launch-review. Torres-aligned; first-class artifact, not embedded sub-section of PRD.
- [x] **Decision 13 (resolves Q3): sitemap step output = structured YAML with schema-enforced `required_categories`.** Primary artifact `sitemap.yaml` (machine-readable); per-route fields `path / category / states / covers_us`. Atlas consumes YAML deterministically (no LLM re-extraction). Schema `required_categories: [marketing, auth, primary, admin, error]` enforces inventory completeness — this is the **direct mechanical fix for the "atlas under-cover" root cause** that triggered spec 032.
- [x] **Decision 14 (resolves Q4 mechanics of Decision 8): step 7 deleted, step 13 absorbs, slug renamed.** Path (a): `packages/mcp-product-pipeline/src/templates/07-prototype-v2/` deleted entirely with tombstone preserved in `docs/specs/037-*/artifacts/deleted-step-7-prototype-v2.md`. Step 13 (`prototype-v3`) absorbs brand+tokens-applied responsibility; **slug renamed `prototype-v3` → `screen-atlas`**. Phase B task 22 calibration (recent, dogfooded, 4-dim schema swap, 7 over-prescription smells folded) preserved + extended.
- [x] **Decision 15 (resolves Q5): PRD-1pager template = hybrid Lenny Rachitsky bones + 3 our-specific sections.** Inherits Lenny's 6 sections (Problem · Why now · Success metrics · Solution sketch · User stories · Anti-goals); adds 3 sections (Release scope · NSM as dedicated slot · Upstream/downstream refs). Attribution comment: "based on Lenny Rachitsky's 1-pager template (lennysnewsletter.com/p/prds-1-pagers-examples)". Discipline: each section ≤ 3 bullets to preserve 1-pager honesty.
- [x] **Decision 16 (resolves Q6): hard cutover.** Version bump `0.1.0 → 0.2.0` on 037 ship. No deprecation phase, no `pipelineVersion` runtime switch. `docs/specs/032-pipeline-industry-alignment/MIGRATION-NOTES.md` documents shape-by-shape changes for any future fork to re-cherry-pick. Rationale: pre-1.0 + `private: true` + filesystem-only consumption + zero current external consumers per `.claude/memory/forks-ephemeral-dogfood.md`.
- [x] **Decision 17 (resolves Q7): redogfood validation = verbatim source brief + gap-audit per step + fresh dogfood directory walked end-to-end.** Fresh dir `/tmp/bench/032-redogfood-octant-fresh/`; walk new pipeline linearly 1→15 + sibling post-launch-review at the end. `gap-audit.md` produced documenting at each step where mechanisms compensated for source-brief omissions vs where they leaked. 026 dogfood atlas serves as **comparator-where-step-boundaries-overlap** (specifically: 026 step 13 atlas vs 032 step 15 screen-atlas).

#### Resulting STEPS array shape (15 linear + 1 sibling)

| n | name | phase | gate-after? | notes |
|---|---|---|---|---|
| 1 | ideation | discovery | — | extended w/ market sizing (Decision 6) |
| 2 | prototype | discovery | — | lo-fi (unchanged) |
| 3 | spec | discovery | — | extended w/ problem-validation interviews (Decision 6) |
| 4 | ux-testing | discovery | ✓ close | unchanged |
| 5 | prd-1pager | specification | — | reshaped per Decision 1 + 15 |
| 6 | ost | specification | — | new (Decision 12) |
| 7 | sitemap-ia | specification | — | new (Decision 5 + 13) — root-cause fix |
| 8 | system-design | specification | — | extended w/ RACI + risk (Decision 10) |
| 9 | legal | specification | — | moved earlier (Decision 4 shift-left) |
| 10 | cost-estimate | specification | — | unchanged |
| 11 | roadmap | specification | — | unchanged |
| 12 | gtm-launch | specification | ✓ close | new (Decision 7) |
| 13 | brand | identity | — | unchanged content; reordered after spec (Decision 3) |
| 14 | design-system | identity | ✓ close | unchanged |
| 15 | screen-atlas | visual-contract | — | renamed from prototype-v3 (Decision 14); absorbs step-7 work |
| — | post-launch-review | sibling | — | callable repeatable (Decision 11) |

`PHASES` becomes 4: `discovery → specification → identity → visual-contract` (was 3). `GATE_AFTER` becomes `[4, 12, 14]` (was `[4, 7, 12]`). Step 15 fires `product_done` (unchanged semantics).

### B. Child-spec decomposition

- [ ] **Scenario: child-specs enumerated and ordered**
  - **Given** the 17 shape decisions above are locked
  - **When** the parent plan.md is drafted
  - **Then** plan.md lists exactly the child specs needed (one per coherent ship unit), each with: target NNN, slug, ship-order dependency, single-sentence intent, estimated effort (S/M/L), and gate-acceptance line. Target decomposition: ~5-7 child specs; not 1 (too monolithic) and not 15 (over-fragmented).

### C. End-to-end re-dogfood validation

- [ ] **Scenario: redogfood Octant PRD against new pipeline produces "all screens a user sees"**
  - **Given** the new pipeline is implemented end-to-end and `/tmp/bench/032-redogfood-octant/` is a fresh dogfood directory using the same source brief as the 026 Octant case
  - **When** the founder walks the pipeline 1→end and generates the screen atlas at the visual-contract step
  - **Then** the atlas's screen inventory includes auth set (login, signup, password-reset, email-verify, invite-accept), error/empty/404, team-management, issue-creation form, billing flow — i.e., resolves the gaps observed on the 026 dogfood. PRD-coverage report explicitly distinguishes "PRD user-story coverage" (the current metric) from "sitemap surface coverage" (the new metric); both ≥95%.

- [ ] **Scenario: post-launch-review re-runnable and updates OST**
  - **Given** a product has shipped (i.e., `/sdd` handoff fired and engineering executed)
  - **When** the founder invokes `post-launch-review` step 6 weeks post-launch with real metrics (analytics export, user feedback summary)
  - **Then** the step produces: (1) metrics-vs-declared-success scorecard, (2) OST update — new opportunities added, validated ones marked, killed ones marked, (3) a structured decision artifact recommending "ship PRD-v2 now" / "extend v1" / "kill product" with reasoning. Re-running the step N times produces a versioned history of reviews under `docs/product/<post-launch-review-step-dir>/review-NN.md`.

- [x] `docs/specs/032-pipeline-industry-alignment/research-report.md` exists and contains the verbatim 48-source industry research that grounds this spec.

## Non-goals

- **NOT a rewrite of the MCP server architecture.** `pipeline.ts`, `tools.ts`, `state.ts`, schema parsing, validator, and the porter→judge→calibrate Phase B loop all stay. The change is the STEPS array contents + per-step templates + the new repeatable-step concept.
- **NOT a DAG / parallel-track pipeline.** Linear sequence with `GATE_AFTER` boundaries is preserved. Brand+PRD parallel (Option 3 in the Brand×PRD discussion) is rejected — it would require sequencer redesign and is not justified by the research at this scale.
- **NOT a port of any external pipeline.** Industry references inform decisions; the implementation is Agent0-native. No transcription of anthill, no transcription of Stage-Gate, no transcription of Cagan's framework. Calibration over rigidity, per `.claude/memory/feedback_anthill_port_smart_not_rigid.md`.
- **NOT a metrics/observability platform.** `post-launch-review` step ingests metrics the founder already collected from external tools (Amplitude, Mixpanel, PostHog, ad-hoc CSV). The MCP does not deploy probes, scrape analytics, or own telemetry infra.
- **NOT a /sdd replacement.** Engineering execution stays in `/sdd new <slug>`. The handoff boundary at the visual-contract step is preserved.
- **NOT auto-discovery of new product class calibrations.** Step-N calibration ranges (Micro 3-5 / Mobile 4-7 / Dev Tool 4-8 / SMB SaaS 6-10 / Venture 10-15) are preserved as-is; sitemap step adds *coverage requirements*, not *count overrides*.

## Open questions

_All 7 open questions resolved 2026-05-17 in item-by-item discussion → folded into Decisions 11-17 (§ Acceptance criteria § A above). This section is now empty by design. Resolution audit trail preserved in `tasks.md` § Notes for git-grep._

## Context / references

- **Triggering session conversation (2026-05-17):** founder observed step 13 atlas under-covers from "user's perspective". Item-by-item discussion locked Decisions 1-3 (Camp C / Option 3 / Option 2); spec extends to Decisions 4-10 from research + analysis; Decisions 11-17 locked via second item-by-item pass resolving original Q1-Q7. Resolution audit trail in `tasks.md` § Notes.
- **Research report:** `docs/specs/032-pipeline-industry-alignment/research-report.md` — 48 sources, 2026-05-17, captured by general-purpose agent web-research dispatch.
- **Predecessor specs:**
  - `docs/specs/025-mcp-product-pipeline/` — original 12-step MCP from anthill port.
  - `docs/specs/026-mcp-pipeline-deep-port/` — Phase B calibration of templates 5-13 (just shipped; commits `15d200d`..`4016e6c`).
- **Current pipeline source of truth:**
  - `packages/mcp-product-pipeline/src/pipeline.ts` — STEPS array, GATE_AFTER, phase definitions.
  - `packages/mcp-product-pipeline/src/templates/<NN-name>/{prompt,schema}.md` — per-step templates.
- **Industry standards referenced (top 10 of 48; full list in research-report.md):**
  - Cagan / SVPG — `https://www.svpg.com/high-fidelity-prototypes/` (PRD-is-dead canonical argument)
  - Torres — `https://www.producttalk.org/continuous-discovery-habits/` (OST framework)
  - Atlassian — `https://www.atlassian.com/agile/product-management/requirements` (PRD = release-scoped)
  - Lenny Rachitsky — `https://www.lennysnewsletter.com/p/prds-1-pagers-examples` (1-pager template)
  - Shape Up — `https://basecamp.com/shapeup/2.2-chapter-08` (per-cycle pitch, not product-wide PRD)
  - GDPR Art 25 — `https://gdpr-info.eu/art-25-gdpr/` (privacy by design + default obligation)
  - EDPB — `https://www.edpb.europa.eu/sites/default/files/files/file1/edpb_guidelines_201904_dataprotection_by_design_and_by_default_v2.0_en.pdf` (DPIA-before-processing)
  - Stage-Gate International — `https://www.stage-gate.com/blog/the-stage-gate-model-an-overview/` (canonical discovery-to-launch with gates)
  - Eleken — `https://www.eleken.co/blog-posts/sitemap-ux` (sitemap = surface inventory, PRD ≠ sitemap)
  - Raw.Studio — `https://raw.studio/blog/empty-states-error-states-onboarding-the-hidden-ux-moments-users-notice/` ("hidden UX moments" framing the atlas-undercover root cause)
- **Memory references:**
  - `.claude/memory/feedback_anthill_port_smart_not_rigid.md` — port-as-refinement-not-transcription discipline informs Decision 6 + 8 (we resist over-stepifying gaps).
  - `.claude/memory/feedback_mcp_package_self_contained.md` — all template/artifact changes live inside `packages/mcp-product-pipeline/`, never under Agent0 `.claude/`.
