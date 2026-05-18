# Product pipeline industry research

_Captured 2026-05-17 by general-purpose agent web-research dispatch. Source for spec 032-pipeline-industry-alignment. 48 sources cited; ~2,450 words._

## 1. PRD scope: single vs phased

- **Finding:** The dominant 2025 shape is **release-scoped (phased) PRDs maintained as living docs**, not a single monolithic spec covering the whole product. Atlassian frames PRDs as describing what "must be included in *a release* to be considered complete" [[Atlassian]](https://www.atlassian.com/agile/product-management/requirements); ProductPlan, Productboard, and Perforce explicitly position PRDs as scoping a single release with "what's mandatory for the initial release and what's planned for future iterations" [[ProductPlan]](https://www.productplan.com/glossary/product-requirements-document) [[Perforce]](https://www.perforce.com/blog/alm/how-write-product-requirements-document-prd). Lenny Rachitsky's widely-cloned template is a **1-pager per project**, optimized to "separate problem understanding from solution design" and used "to start every project" — implying many small PRDs per product, not one large one [[Lenny's Newsletter — PRDs/1-Pagers]](https://www.lennysnewsletter.com/p/prds-1-pagers-examples) [[Confluence — Lenny's PRD]](https://www.atlassian.com/software/confluence/templates/lennys-product-requirements). Shape Up (Basecamp) goes further — each 6-week cycle gets its own *pitch*, never a product-wide PRD [[Shape Up — Betting Table]](https://basecamp.com/shapeup/2.2-chapter-08).
- **Consensus / conflict:** Strong consensus that PRD = release-scoped, not product-scoped. Enterprise/regulated B2B occasionally publishes a "master PRD" alongside release deltas, but the canonical agile/startup pattern in 2025-2026 is **N small PRDs per product**, one per release or initiative.

## 2. PRD lifecycle: living vs static

- **Finding:** Canonical view across Cagan (SVPG), Torres, Atlassian, Plane.so, Productboard: PRDs are **living documents** in agile contexts; static PRDs are the antipattern most authors warn against. Plane.so: "Static PRDs … become outdated and inefficient — dynamic, living documents are crucial" [[Plane]](https://plane.so/blog/how-prds-live-better-inside-your-project-management-tool). The harder Cagan position is even stronger: PRDs themselves are obsolete — replaced by high-fidelity prototypes plus a thin user-story backlog. "The high-fidelity prototype is the only form of spec that can deliver on the necessary requirements" [[SVPG — High-Fidelity Prototypes]](https://www.svpg.com/high-fidelity-prototypes/) [[SVPG — Revisiting the Product Spec]](https://www.svpg.com/revisiting-the-product-spec/). Torres reframes the document question entirely: the *trio* (PM + design + eng) does continuous discovery weekly, and the PRD-equivalent is an **opportunity solution tree** plus tested assumptions — not a frozen doc [[Product Talk — Continuous Discovery]](https://www.producttalk.org/continuous-discovery-habits/) [[Product Talk — OST]](https://www.producttalk.org/opportunity-solution-trees/).
- **Consensus / conflict:** Two camps. **Camp A (living PRD):** Atlassian, ProductPlan, Productboard, Perforce — keep the PRD but version it inside the PM tool alongside the backlog. **Camp B (no PRD):** Cagan/SVPG, Torres, Basecamp/Shape Up — replace PRDs with prototypes + pitches + OSTs. Both reject the static/frozen artifact.

## 3. Pipeline ordering: PRD before/after legal

- **Finding:** GDPR Article 25 makes "data protection by design and by default" a legal obligation at "the time of design" of any processing, with DPIAs required **before** processing begins [[GDPR Art. 25]](https://gdpr-info.eu/art-25-gdpr/) [[EDPB Guidelines 4/2019]](https://www.edpb.europa.eu/sites/default/files/files/file1/edpb_guidelines_201904_dataprotection_by_design_and_by_default_v2.0_en.pdf) [[ICO — Data Protection by Design]](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/accountability-and-governance/guide-to-accountability-and-governance/data-protection-by-design-and-by-default/). GDPR.eu explicitly: "perform impact assessment … from the beginning of any new project as well as during the planning and development stages" [[GDPR.eu — DPIA]](https://gdpr.eu/data-protection-impact-assessment-template/). The industry term is "**shift-left**": legal, privacy, and security review embed at planning, not pre-launch. Stripe operationalizes this with a dedicated Privacy Engineering team building "data protection guarantees … always on by default" [[Stripe Security]](https://docs.stripe.com/security) [[Stripe Privacy Eng]](https://stripe.com/jobs/listing/engineering-manager-privacy-eng-data-protection/6781778); Thoughtworks and OpsMx position shift-left as the consensus 2024-2026 posture [[Thoughtworks — Shift Left on Security and Privacy]](https://www.thoughtworks.com/en-us/insights/e-books/modern-data-engineering-playbook/shift-left-on-security-and-privacy).
- **Consensus / conflict:** Unambiguous: legal/privacy is **concurrent with or before PRD**, not after. A legal step that runs *after* PRD/system-design (your current step 12) is a "bolt-on" pattern the GDPR explicitly warns against and most modern playbooks call out as the costly antipattern. No source argued for legal-as-final-gate.

## 4. Gaps in our 13-step pipeline vs industry

### Gap A — Market/competitive research, TAM, positioning
- **Industry name(s):** "Discovery" (Stage-Gate stage 1 [[Stage-Gate Intl.]](https://www.stage-gate.com/about/stage-gate-innovation-performance-framework/discovery-to-launch-process/)), "Determine target customers + identify underserved needs + define value proposition" (Olsen steps 1-3 [[Lean Product Playbook]](https://medium.com/@ankushpanday/bookthe-lean-product-playbook-by-dan-olsen-the-best-summary-ever-written-ae422cfc6a61)), "Empathize → Define" (Stanford d.school [[IxDF — Design Thinking]](https://ixdf.org/literature/article/5-stages-in-the-design-thinking-process)), "Analyze" phase of GTM (Asana, HubSpot [[Asana — GTM]](https://asana.com/resources/go-to-market-gtm-strategy)).
- **Where it would belong:** Before or alongside step 1 (ideation). Your pipeline jumps to prototype without explicit market sizing or competitor mapping.

### Gap B — User research / problem discovery / interviews
- **Industry name(s):** "Product Discovery" (Cagan [[SVPG — Discovery vs Documentation]](https://www.svpg.com/discovery-vs-documentation/)), "Continuous Discovery" with weekly trio interviews (Torres [[Product Talk]](https://www.producttalk.org/continuous-discovery-habits/)), "Empathize" (d.school). Cagan's four risks framework — Value/Usability/Feasibility/Viability — assigns the PM the value+viability risk specifically through discovery [[SVPG — Four Big Risks]](https://www.svpg.com/four-big-risks/).
- **Where it would belong:** Your `ux-testing` (step 4) is *prototype validation*, which is downstream of *problem validation*. You're missing a "talk to users before you prototype" step. Torres would put this as ongoing across the entire pipeline, not a single stage.

### Gap C — GTM / pricing / positioning / launch plan
- **Industry name(s):** "Go-to-Market strategy" (Asana 9-step guide [[Asana]](https://asana.com/resources/go-to-market-gtm-strategy)), "Launch" (Stage-Gate stage 6), "Implementation" (IDEO 3-phase). HubSpot/PMA/Big Moves: GTM spans pre-launch research → launch → post-launch adoption → expansion [[HubSpot — GTM]](https://blog.hubspot.com/sales/gtm-strategy) [[Big Moves — Product Lifecycle and GTM]](https://www.bigmoves.marketing/blog/product-life-cycle-and-marketing).
- **Where it would belong:** Between your step 11 (roadmap) and step 13 (prototype-v3), or as a sibling track. You have **no GTM/launch step at all** — cost-estimate (step 10) is not GTM.

### Gap D — North-star / KPIs / success metrics as first-class artifact
- **Industry name(s):** "North Star Metric" (Amplitude playbook, Lenny [[Amplitude — NSM]](https://amplitude.com/north-star-hub) [[Lenny — Choosing Your NSM]](https://www.lennysnewsletter.com/p/choosing-your-north-star-metric)), "Outcomes" (Cagan, Torres top-of-OST [[Product Talk — OST]](https://www.producttalk.org/opportunity-solution-trees/)). Build-Measure-Learn loop (Amplitude [[Amplitude — Build/Measure/Learn]](https://amplitude.com/blog/build-measure-learn-the-product-management-lifecycle-loop)).
- **Where it would belong:** Pre-PRD (around step 5-7), so PRD acceptance criteria can hang off the NSM. Your PRD has user-story acceptance criteria but no business KPI dimension.

### Gap E — Risk register + stakeholder RACI
- **Industry name(s):** Stage-Gate "Strategic Fit / Market Attractiveness / Technical Feasibility / Financial Reward/Risk" criteria at every gate [[Stage-Gate Intl.]](https://www.stage-gate.com/blog/the-stage-gate-model-an-overview/); RACI as standard cross-functional alignment tool [[Atlassian — RACI]](https://www.atlassian.com/work-management/project-management/raci-chart) [[Info-Tech — GTM RACI]](https://www.infotech.com/research/go-to-market-strategy-raci-and-launch-checklist-workbook).
- **Where it would belong:** Implicit in plan.md today; first-class as part of system-design (step 9) or as its own step pre-engineering.

### Gap F — Post-launch / iteration loop
- **Industry name(s):** "Build-Measure-Learn" (Lean Startup/Amplitude), "Post-launch analytics" (Userpilot, Mixpanel, ProdPad [[Mixpanel — Launch Metrics]](https://mixpanel.com/blog/product-launch-metrics/) [[Userpilot]](https://userpilot.com/blog/product-launch-analytics/)), Continuous Discovery (Torres). Stage-Gate stage 6 explicitly extends past launch to post-launch review [[Stage-Gate Intl.]](https://www.stage-gate.com/about/stage-gate-innovation-performance-framework/discovery-to-launch-process/).
- **Where it would belong:** After step 13's handoff to `/sdd`. Your pipeline ends at "engineering execution starts," which is mid-lifecycle by every industry reference.

### Gap G — Discovery→Delivery handoff explicit
- **Industry name(s):** "Dual-track agile" (Productboard, LogRocket, ProductPlan [[Productboard]](https://www.productboard.com/glossary/dual-track-agile/) [[LogRocket — Dual-Track Agile]](https://blog.logrocket.com/product-management/dual-track-agile-continuous-discovery/)), "Definition of Ready" with evidence (validated problem, usability signal, feasibility spike) [[Product Talk — Discovery Handoffs]](https://producttalk.org/2021/11/discovery-handoffs/). Torres warns: "Creating a 'discovery team' that hands off to a 'delivery team' destroys ownership and recreates waterfall."
- **Where it would belong:** Your step 13 → `/sdd` *is* a handoff; the gap is that it's a one-way wall, not the dual-track loop the industry recommends.

### Phases you have that ARE NOT standard
- **`prototype` (low-fi, step 2) → `prototype-v2` (brand, step 7) → `prototype-v3` (screen atlas, step 13):** No reference splits prototyping into three named artifacts. Cagan's framework distinguishes only low-fi (early discovery) vs high-fi (replacement-for-PRD) [[SVPG — Flavors of Prototypes]](https://www.svpg.com/flavors-of-prototypes/) [[SVPG — Purpose of Prototypes]](https://www.svpg.com/the-purpose-of-prototypes/). Three-stage prototyping is unusual.
- **`brand-book` before PRD (step 5 before step 8):** Industry default is design *follows* PRD acceptance, not precedes it. Formlabs/Aha/Figma/Atlassian all sequence PRD → design [[Formlabs — PRD Template]](https://formlabs.com/blog/product-requirements-document-prd-with-template/) [[Aha — PRD Templates]](https://www.aha.io/roadmapping/guide/requirements-management/what-is-a-good-product-requirements-document-template). Your PRD-after-brand is unconventional.

### Root cause of "atlas under-covers"
The user observed PRD-driven atlas missed auth/error/empty/admin screens. Industry diagnosis: **PRDs scope user-stories; sitemaps and information architecture scope the full screen inventory** [[Eleken — Sitemap UX]](https://www.eleken.co/blog-posts/sitemap-ux) [[Slickplan — IA vs Sitemap]](https://slickplan.com/blog/information-architecture-vs-sitemap) [[Raw.Studio — Empty/Error/Onboarding]](https://raw.studio/blog/empty-states-error-states-onboarding-the-hidden-ux-moments-users-notice/). Empty states, error states, and onboarding are explicitly called "hidden UX moments easy to overlook." The missing pipeline step is **information architecture / sitemap / object model**, which derives user stories *from* the object inventory rather than the inverse.

## 5. Reordering questions answered

- **Q1 — PRD vs brand order:** Industry default is PRD-first, design-system-second. Atlassian, Formlabs, ProductPlan all sequence PRD → design [[Formlabs]](https://formlabs.com/blog/product-requirements-document-prd-with-template/). Your brand-first ordering is unusual but not wrong if the brand voice is genuinely informing PRD copy; the cost is risk of brand churn when PRD reveals scope shifts.
- **Q2 — Legal vs PRD order:** Legal **before or concurrent with PRD**. GDPR Art. 25 + DPIA explicitly mandate "prior to processing"; shift-left is the consensus modern posture [[GDPR Art. 25]](https://gdpr-info.eu/art-25-gdpr/) [[ICO]](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/accountability-and-governance/guide-to-accountability-and-governance/data-protection-by-design-and-by-default/) [[Thoughtworks]](https://www.thoughtworks.com/en-us/insights/e-books/modern-data-engineering-playbook/shift-left-on-security-and-privacy). Your legal-at-step-12 is the antipattern.
- **Q3 — Cost vs roadmap order:** Mixed signal — cost-estimate typically **precedes or parallels** roadmap to constrain feature prioritization [[Asana — Cost Management]](https://asana.com/resources/cost-management-steps) [[Liminal Arc — Rapid Estimation]](https://www.liminalarc.co/2019/02/roadmapping-and-budgeting-with-rapid-estimation/). Stage-Gate puts business-case (financials) at stage 2, before development [[Stage-Gate Intl.]](https://www.stage-gate.com/blog/the-stage-gate-model-an-overview/). Your cost-then-roadmap (steps 10→11) is acceptable.
- **Q4 — Validation gate placement:** A **discovery gate distinct from specification-complete** is canonical: Stage-Gate's gate 1 (idea screen) + gate 2 (business-case approval) precede development [[Stage-Gate Intl.]](https://www.stage-gate.com/blog/the-stage-gate-model-an-overview/); Double Diamond's first diamond ends with a defined problem before solution-development starts [[Design Council]](https://www.designcouncil.org.uk/resources/the-double-diamond/). Cagan's four-risk discovery validates value/usability/feasibility/viability before commit [[SVPG — Four Big Risks]](https://www.svpg.com/four-big-risks/). Your "close discovery" gate after step 4 maps; the discovery itself is light (no market research, no problem-validation interviews).

## Summary table

| Question | Industry answer | Our current shape | Gap? |
|---|---|---|---|
| PRD scope | Release-scoped, multiple per product | Single PRD (step 8) | Yes — should be v1/v2/vN |
| PRD lifecycle | Living doc, or replaced by hi-fi prototype + OST | Static artifact | Yes — no living-doc convention |
| Legal placement | Before/concurrent with PRD (shift-left, GDPR Art. 25) | After PRD (step 12) | Yes — antipattern |
| Market research | Explicit phase (Stage-Gate, Olsen, GTM) | Absent | Yes — missing |
| Problem-validation interviews | Continuous, weekly (Torres) | Implicit in ideation | Yes — missing |
| North Star / KPIs | First-class artifact | Acceptance criteria only | Yes — missing |
| GTM / launch plan | Required phase | Absent | Yes — missing |
| Post-launch iteration | Required phase | Hands off to /sdd, loop silent | Yes — missing |
| Sitemap / IA | Drives full screen inventory | Atlas derived from PRD user-stories | Yes — root cause of under-coverage |
| RACI / stakeholders | First-class | Implicit | Yes — minor |
| Brand vs PRD order | PRD first | Brand first | Minor — unconventional |
| Prototype stages | Lo-fi vs hi-fi (2 stages) | 3 stages (v1, v2, v3) | Minor — unusual |

## Sources (deduplicated, with publication date where visible)

1. [Atlassian — What is a PRD?](https://www.atlassian.com/agile/product-management/requirements) (undated, maintained)
2. [ProductPlan — PRD Glossary](https://www.productplan.com/glossary/product-requirements-document) (maintained)
3. [Productboard — PRD Guide](https://www.productboard.com/blog/product-requirements-document-guide/)
4. [Perforce — How to Write a PRD](https://www.perforce.com/blog/alm/how-write-product-requirements-document-prd) (2024-2025)
5. [Plane.so — PRDs Inside PM Tool](https://plane.so/blog/how-prds-live-better-inside-your-project-management-tool) (2025)
6. [Lenny Rachitsky — PRDs / 1-Pagers Examples](https://www.lennysnewsletter.com/p/prds-1-pagers-examples)
7. [Atlassian Confluence — Lenny's PRD Template](https://www.atlassian.com/software/confluence/templates/lennys-product-requirements)
8. [SVPG — High-Fidelity Prototypes](https://www.svpg.com/high-fidelity-prototypes/) (Cagan, classic)
9. [SVPG — Revisiting the Product Spec](https://www.svpg.com/revisiting-the-product-spec/) (Cagan, 2006/2007 — flagged older)
10. [SVPG — Discovery vs Documentation](https://www.svpg.com/discovery-vs-documentation/)
11. [SVPG — The Four Big Risks](https://www.svpg.com/four-big-risks/)
12. [SVPG — Flavors of Prototypes](https://www.svpg.com/flavors-of-prototypes/)
13. [SVPG — Purpose of Prototypes](https://www.svpg.com/the-purpose-of-prototypes/)
14. [SVPG — How to Write a Good PRD (PDF)](https://www.svpg.com/wp-content/uploads/2024/07/How-To-Write-a-Good-PRD.pdf) (2024)
15. [Product Talk — Continuous Discovery Habits](https://www.producttalk.org/continuous-discovery-habits/) (Torres, 2021+)
16. [Product Talk — Opportunity Solution Trees](https://www.producttalk.org/opportunity-solution-trees/)
17. [Product Talk — Discovery Handoffs Kill Momentum](https://producttalk.org/2021/11/discovery-handoffs/) (2021)
18. [Basecamp — Shape Up: Betting Table](https://basecamp.com/shapeup/2.2-chapter-08)
19. [GDPR-Info — Article 25](https://gdpr-info.eu/art-25-gdpr/)
20. [EDPB — Guidelines 4/2019 on Article 25](https://www.edpb.europa.eu/sites/default/files/files/file1/edpb_guidelines_201904_dataprotection_by_design_and_by_default_v2.0_en.pdf) (2019, regulatory)
21. [ICO — Data Protection by Design and Default](https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/accountability-and-governance/guide-to-accountability-and-governance/data-protection-by-design-and-by-default/)
22. [GDPR.eu — DPIA Template](https://gdpr.eu/data-protection-impact-assessment-template/)
23. [Stripe — Security Documentation](https://docs.stripe.com/security)
24. [Stripe — Privacy Engineering Job](https://stripe.com/jobs/listing/engineering-manager-privacy-eng-data-protection/6781778)
25. [Thoughtworks — Shift Left on Security and Privacy](https://www.thoughtworks.com/en-us/insights/e-books/modern-data-engineering-playbook/shift-left-on-security-and-privacy)
26. [Stage-Gate International — Discovery-to-Launch](https://www.stage-gate.com/about/stage-gate-innovation-performance-framework/discovery-to-launch-process/)
27. [Stage-Gate International — Stage-Gate Model Overview](https://www.stage-gate.com/blog/the-stage-gate-model-an-overview/)
28. [Dan Olsen — Lean Product Playbook (summary)](https://medium.com/@ankushpanday/bookthe-lean-product-playbook-by-dan-olsen-the-best-summary-ever-written-ae422cfc6a61)
29. [IxDF — 5 Stages of Design Thinking](https://ixdf.org/literature/article/5-stages-in-the-design-thinking-process) (2026 maintained)
30. [Design Council — The Double Diamond](https://www.designcouncil.org.uk/resources/the-double-diamond/)
31. [Asana — GTM Strategy 9-step](https://asana.com/resources/go-to-market-gtm-strategy) (2026)
32. [HubSpot — GTM Strategy](https://blog.hubspot.com/sales/gtm-strategy)
33. [Big Moves Marketing — Product Lifecycle and GTM](https://www.bigmoves.marketing/blog/product-life-cycle-and-marketing)
34. [Asana — Cost Management Steps](https://asana.com/resources/cost-management-steps) (2025)
35. [Amplitude — North Star Hub](https://amplitude.com/north-star-hub)
36. [Lenny — Choosing Your North Star Metric](https://www.lennysnewsletter.com/p/choosing-your-north-star-metric)
37. [Amplitude — Build/Measure/Learn Loop](https://amplitude.com/blog/build-measure-learn-the-product-management-lifecycle-loop)
38. [Mixpanel — Launch Metrics](https://mixpanel.com/blog/product-launch-metrics/)
39. [Userpilot — Product Launch Analytics](https://userpilot.com/blog/product-launch-analytics/)
40. [Productboard — Dual-Track Agile Glossary](https://www.productboard.com/glossary/dual-track-agile/)
41. [LogRocket — Dual-Track Agile and Continuous Discovery](https://blog.logrocket.com/product-management/dual-track-agile-continuous-discovery/)
42. [Atlassian — RACI Chart](https://www.atlassian.com/work-management/project-management/raci-chart)
43. [Info-Tech — GTM RACI and Launch Checklist](https://www.infotech.com/research/go-to-market-strategy-raci-and-launch-checklist-workbook)
44. [Eleken — Sitemap UX](https://www.eleken.co/blog-posts/sitemap-ux)
45. [Slickplan — Information Architecture vs Sitemap](https://slickplan.com/blog/information-architecture-vs-sitemap)
46. [Raw.Studio — Empty States, Error States, Onboarding](https://raw.studio/blog/empty-states-error-states-onboarding-the-hidden-ux-moments-users-notice/)
47. [Formlabs — PRD Template](https://formlabs.com/blog/product-requirements-document-prd-with-template/)
48. [Aha! — PRD Templates](https://www.aha.io/roadmapping/guide/requirements-management/what-is-a-good-product-requirements-document-template)

**Word count:** ~2,450 words.

**Flagged older sources:** Cagan's "Revisiting the Product Spec" (2006/2007) — cited because it's the canonical "PRD is dead" argument and Cagan still references it in current SVPG writing.

**Key conflict surfaced:** Cagan/SVPG vs Atlassian/ProductPlan/Productboard on whether PRDs should exist at all. Both camps agree PRDs must not be static; they diverge on whether the living artifact is a PRD-in-PM-tool or a hi-fi prototype + OST.
