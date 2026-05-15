---
mode: synthesis
delegable: true
delegation_hint: "draft the step-3 spec bundle — functional-spec.md (pages, components, interactions, states, features, Gherkin acceptance scenarios) + architecture.md (module/data-model/flow shape) + architecture.html or architecture.json — synthesising the concept brief and prototype directions; no user interview"
---

# Step 3 — Spec

**Goal:** a multi-artifact specification bundle that pins down what the product DOES — every page, every component, every interaction, every state, decomposed into features with Gherkin acceptance scenarios — plus a preliminary architecture shape derived from it. The functional spec is the behavioral contract a developer reads to build; the architecture artifacts are the structural skeleton step 9 (system-design) deepens. Pure synthesis from steps 1+2 — sub-agent territory.

**Mode:** `synthesis`. Fully delegable. The parent calls `product_get_delegation_brief(3)` and dispatches an `Agent` sub-agent with the returned 5-field block. The sub-agent reads `docs/product/01-ideation/` + `docs/product/02-prototype/` and produces the bundle without further user input. There is no user checkpoint — step 3 is mid-Discovery, no gate.

**Output bundle** (all written atomically via one `product_step_submit` call — primary `content` + `extra_files`):

| File | Role | Floor |
|---|---|---|
| `functional-spec.md` | behavioral contract — pages, components, interactions, states, features, acceptance scenarios | ≥ 15 KB |
| `architecture.md` | structural shape — module decomposition, data model, key flows, integration points | ≥ 4 KB |
| `architecture.html` **or** `architecture.json` | the same architecture as a rendered diagram (mermaid / inline SVG) **or** a machine-readable graph | one of the two |

The architecture artifacts are **derived from `functional-spec.md`** — write the functional spec first, then read it back and extract the structure. This derivation chain is what keeps the three files in sync; see `references/architecture-shape.md`.

---

## How to conduct this step

Read `references/functional-spec-template.md` (the full output shape for `functional-spec.md`) and `references/anti-patterns.md` before drafting. Read `references/examples.md` for good/bad table shapes. Read `references/architecture-shape.md` before deriving the architecture artifacts. Run `references/checklist.md` before submitting.

### 1. Read prior artifacts

- **Concept brief (step 1)** — the *why*. Internalize the JTBD, the target persona(s), the killer flow named in the user-flow section, the anti-goals. The spec must not drift outside the concept's scope.
- **Prototype (step 2)** — the *what surfaces exist*. The 3 HTML directions + the chosen direction's hi-fi screens are the ground truth for which pages and components the product has. The spec decomposes what step 2 rendered; it does not invent new surfaces.

If a prior artifact is missing or thin, say so to the parent and stop — do not fabricate the missing input.

### 2. Identify pages & surfaces

List every distinct page/screen/surface the user sees — including the ones easy to forget: landing/marketing, auth (login, signup, forgot-password), settings/profile, admin/backoffice, empty-first-run. For each, write **name**, **purpose** (one sentence), **entry points** (how the user gets here), and a small **ASCII wireframe** sketch. Then, per page:

- **Components table** — `| Component | Type | Description |`. Type is one of `navigation`, `data-display`, `action`, `input`, `feedback`, `modal`, `form`, `media`. List every interactive element, even "obvious" ones (nav links, the back button).
- **Interactions table** — `| Component | Trigger | Action | Result |`. One row per interactive component. Trigger/action/result must all be concrete — "click → opens modal → new-project form appears", never "user can manage projects".
- **States table** — `| State | Condition | What the user sees |`. Every page needs at minimum empty / loading / error / populated; add filtered-empty, permission-denied, offline where they apply.

**Scale depth to surface importance.** Killer-flow surfaces and any page central to the persona's daily use get the full treatment — purpose, entry points, wireframe, and all three tables filled exhaustively. Trivial surfaces (a Skip-button-flanked onboarding micro-page, a single-form settings sub-page, an info-only confirmation page) get a compact treatment: one-line purpose + entry points, the wireframe may be omitted, and the three tables may collapse to a few rows each — covering them at the same depth as the killer flow produces a spec that is exhaustive on paper and unreadable in practice. The schema enforces *presence* of the section (every page appears with at least the three table headers and the states floor), not *parity of depth* across pages. When in doubt, give the surface the full treatment; the floor exists to catch genuine omissions, not to punish appropriate brevity.

### 3. Decompose into features

Each page surfaces 1–N features. A feature is "user can do X in context Y producing outcome Z". Be exhaustive *within the prototype's complexity budget* — don't invent features outside what steps 1+2 established. Per feature capture: **what it does** (one sentence), **happy-path behavior** (user actions + system responses, in sequence), **edge cases** (the ones that actually apply — empty, validation failure, network failure, race, permission denial, large input — not a generic list), **success criterion** (observable evidence it works; this feeds step 4 testing and step 8 PRD acceptance criteria).

### 4. Write acceptance scenarios (Gherkin)

For every feature with 3+ behavior branches, write 2–4 `Given` / `When` / `Then` scenarios — at minimum one happy path, one error path, one edge case. Each `Then` clause must be **assertion-shaped**: specific values, visible text, files, status — never "works correctly" or "is fast". These scenarios are the source spec for tests during implementation and map 1:1 to step 8 (PRD) acceptance criteria. Bold the keywords (`**Given**`, `**When**`, `**Then**`) so the section is machine-greppable.

### 5. Cross-cutting concerns

One paragraph each, only for the ones that apply: auth model (anonymous? login? roles/RBAC?), data persistence (local? remote? sync semantics? offline?), accessibility (screen-reader, keyboard nav), i18n. Stay shallow — this is the *shape* of the concern, not its system design. Deep treatment is step 9.

### 6. Navigation map + Decisions Pending

Draw an ASCII navigation diagram covering every page transition and its trigger. Then close `functional-spec.md` with a `## Decisions Pending` table — `| # | Question | Impact | Default if unresolved |` — capturing every unresolved choice (two reasonable alternatives, a scope-boundary call not explicitly confirmed, an IA decision affecting multiple pages). If there are genuinely none, write the explicit empty-state line. This table is the handoff contract step 8 (PRD) consumes — each row becomes a resolved requirement with a `from spec decision #N` back-reference.

### 7. Derive `architecture.md`

Read `functional-spec.md` back and extract the structural skeleton — see `references/architecture-shape.md` for the full shape. Sections: **Module Decomposition** (frontend pages/components → backend modules/services; new vs. extend), **Data Model** (entities + relationships + key fields, informal — no SQL DDL, no migration syntax; that's step 9), **Key Flows** (the killer flow traced through the modules, as numbered steps or a sequence sketch), **Integration Points** (external systems named, what is called, fallback posture). End with **Open Architecture Questions** — anything genuinely deferred to step 9 (scale, deployment topology, stack-specific choices).

### 8. Derive `architecture.html` OR `architecture.json`

Pick one (the agent's call — `references/architecture-shape.md` covers both):

- **`architecture.html`** — a single self-contained HTML file rendering the architecture as a diagram: a mermaid `graph`/`flowchart` block in a `<script type="module">` mermaid bootstrap, or an inline `<svg>`. Module nodes + data-model entities + flow edges. Human-readable at a glance.
- **`architecture.json`** — a machine-readable graph: `{ "modules": [...], "entities": [...], "flows": [...], "integrations": [...] }`. Consumable by tooling.

Whichever you choose, it must be *derivable from* `architecture.md` — same modules, same entities, same flows. Mismatch between the two is a failure.

### 9. Submit + advance

Call `product_step_submit` with `filename: "functional-spec.md"`, `content: <full functional spec>`, and `extra_files: [{ path: "architecture.md", content: ... }, { path: "architecture.html", content: ... }]` (or `architecture.json`). Layer 1 validates all three atomically — nothing is written unless every file passes. On `schema-incomplete`, the `failures` list names exactly which file failed which check (missing path / undersized / missing substring); fix and resubmit.

After a clean submit, call `product_advance` — step 3 is mid-Discovery, no gate, advances to step 4 (ux-testing). No human checkpoint: the synthesis is auditable in the artifacts themselves.

---

## Voice & rigor

- **Reader-oriented.** A developer building from `functional-spec.md` should never have to ask "what happens when X?". If they would, document X.
- **Product language in the functional spec; structural language in the architecture.** `functional-spec.md` describes behavior a non-technical stakeholder can follow — "saves your changes", "updates in real-time", not "POSTs to the API". `architecture.md` is where module names, entities, and integration points appear. Keep the two registers separate.
- **Don't pre-decide the stack.** "Persist state to the user's account" is a spec; "use Postgres with Prisma" is step-9 system-design. `architecture.md` names *modules and entities*, not *technologies and versions*.
- **Acceptance scenarios are assertion-shaped.** A `Then` a verifier can't check is not done.
- **Length budget.** `functional-spec.md` lands ≥ 15 KB for a non-trivial product (the deep-port floor — a thinner spec is almost certainly missing pages, states, or features). If you genuinely can't fill 15 KB, the prototype scope was probably too small for this pipeline — flag back to the parent rather than padding.
- **Three files, one truth.** `architecture.md` and `architecture.{html,json}` are *derived* — if they disagree with `functional-spec.md` or each other, that's a defect, not a variation.

## What this step does NOT do

- **Full system design** — scale assumptions, deployment topology, security/threat-model, stack-specific decisions. That's step 9. `architecture.md` here is the *preliminary* skeleton step 9 deepens; the `## Open Architecture Questions` section is the explicit handoff.
- **Visual / brand decisions** — step 5 (brand), step 6 (design-system).
- **Pricing, business model details** — step 8 (PRD) + step 10 (cost-estimate).
- **Test execution** — step 4 (ux-testing). But the success criteria and acceptance scenarios written here ARE the inputs to step 4's tests.
- **Comprehensive screen atlas** — step 13 (prototype-v3).

## What this step replaces

This template synthesises two archived anthill skills (see `.claude/memory/anthill-archived.md`):

- **`anthill-spec`** — the visual-spec discipline: pages → components → interactions → states → navigation map, plus the `## Decisions Pending` handoff table. Anthill produced a single stakeholder-readable `<slug>-spec.md`; we keep that rigor as `functional-spec.md` and add the feature decomposition.
- **`anthill-feature-refiner`** — the per-feature depth: problem framing, scope boundaries, the architecture section (module placement, data model, integration points), and Gherkin acceptance scenarios. Anthill ran this as an interactive discovery interview; in this pipeline the discovery already happened in step 1 (ideation), so step 3 is pure synthesis — the interview rounds collapse into reading the concept brief.

Anthill's runtime scaffolding — `.anthill/` rule references, `anthill-route`/`anthill-halt` protocols, `anthill-markdown-writer` REFORMAT pass, the deliverable-registry hook, the resumability file-scan — does not port. Resumability is `product_status` + `.state.json`; the halt protocol is the `schema-incomplete` validation error; the categorical upgrade is that anthill's single markdown becomes a three-artifact bundle persisted atomically through `extra_files`.
