# 026 — mcp-pipeline-deep-port

_Created 2026-05-13. Status: draft._

## Intent

Spec 025 shipped `packages/mcp-product-pipeline/` with the architectural plumbing (state machine, gates, delegation briefs, `/sdd` handoff) empirically validated through a 12-step dogfood walk producing ~57KB of markdown for a Linear-clone product. Dogfood follow-up exposed a content gap: anthill's source skills (`anthill-prototype`, `anthill-design-system`, `anthill-prd`, etc.) instruct the agent to produce **categorically richer artifacts** — at step 2 alone anthill generates 3 directional HTML prototypes + 8 screen HTMLs + REPORT.md + compare.html totaling ~290KB of *executable* (browser-renderable) output, against our single ~8KB `prototype-spec.md` that explicitly tells the agent "not pixels yet". Equivalent gaps exist at step 6 (anthill produces real design tokens and component variants; we produce prose describing them) and step 7 (anthill re-renders the HTML directions with brand + tokens; we re-render markdown). Beyond the three visual steps, anthill produces multi-artifact bundles for technical specs — step 3 / step 9 produce `feature.md` + `architecture.md` + `architecture.html` (rendered diagram) + `architecture.json` (machine-readable) where we produce a single markdown. Anthill is archived as of 2026-05-13 (see `.claude/memory/anthill-archived.md`) — quality benchmark, not a moving upstream.

The cause was Q2 in spec 025 (open-question): "port verbatim from anthill skills, or rewrite from scratch?" — resolved as "port structural parts verbatim, rewrite prose to match Agent0's terser style". That resolution treated the choice as stylistic. It was not — "terser style" effectively descategorized the entrypoint from `produces executable artifact` to `produces textual spec`. Spec 025's plumbing is largely preserved; this spec (a) ports the **execution content** of the anthill skills into our `templates/<NN-name>/prompt.md` (plus per-step `references/` siblings shipped inline via `product_step_get`), (b) extends `product_step_submit` with an `extra_files` map so multi-artifact bundles persist atomically through the MCP, (c) implements a 3-layer quality discipline on every visual/multi-artifact step — floor validation (path + min_size + content sniff), schema-enforced AI judgement (5-dimension critique blocks embedded in REPORT artifacts), and human visual checkpoint (browser-render review before `product_advance`), and (d) adds a 13th and final step `prototype-v3` — a synthesis step that consolidates ALL prior decisions into a comprehensive screen atlas (every screen, every state, brand+tokens applied, copy real, PRD-coverage scored) as the visual contract handed to engineering via `/sdd`.

This spec also clarifies the architectural rule going forward: when porting from anthill, **categorical artifact type is non-negotiable** — if the source step produces HTML / code / multi-file bundles, our port must do the same. Prose terseness is fine; output-shape downgrade is not. And: **quality is enforced by combining AI agent judgement (objective scoring embedded in artifacts) with human judgement (visualization checkpoint)** — not by latency-optimized automated checks. Latency is not a constraint.

## Acceptance criteria

- [ ] **Scenario: step 2 (prototype) produces 3 directional HTMLs + critique + visual checkpoint**
  - **Given** an active pipeline at step 2 with step 1 (ideation) completed
  - **When** the agent submits step 2 following the new template's `prompt.md` via `product_step_submit(2, REPORT_content, extra_files=[direction-a.html, direction-b.html, direction-c.html, compare.html])`
  - **Then** all 4 paths exist under `docs/product/02-prototype/<slug>/`, each direction-*.html is ≥ 8 KB and contains `<html` + `<style`, `REPORT.md` contains a `5-dimension critique` section with explicit per-direction scoring (Philosophy/Hierarchy/Execution/Specificity/Restraint, 1-5 each) AND a `Recommendation` section naming the winning direction with reasoning; the agent does NOT call `product_advance` automatically — the template instructs the agent to surface browser file:// URLs and request human confirmation before advancing; total artifact volume ≥ 60 KB

- [ ] **Scenario: step 6 (design-system) emits real design tokens + component variants**
  - **Given** an active pipeline at step 6 with steps 1-5 completed
  - **When** the agent submits step 6 following the new template
  - **Then** `docs/product/06-design-system/` contains at least: `tokens.css` (CSS custom properties with oklch or hex color values, type ramp, spacing scale), `components.md` (per-component variant table — primary/secondary/destructive states, sizes, density modes), `design-system.md` (overview prose); `tokens.css` is consumable by a downstream HTML/CSS file (no placeholders, no `[TBD]` markers)

- [ ] **Scenario: step 7 (prototype-v2) re-renders HTML with brand + tokens applied**
  - **Given** steps 2, 5 (brand), and 6 (design-system) are completed
  - **When** the agent submits step 7
  - **Then** `docs/product/07-prototype-v2/<slug>/` contains a re-rendered HTML set (at minimum the selected direction from step 2 + 4-8 screen HTMLs) using token references from `06-design-system/tokens.css` and copy matching the brand voice from step 5; opening any screen HTML in a browser renders a visually coherent result with the v1 prototype's flow preserved

- [ ] **Scenario: step 3 (spec) produces multi-artifact bundle**
  - **Given** an active pipeline at step 3 with step 2 completed
  - **When** the agent submits step 3
  - **Then** `docs/product/03-spec/` contains at least 3 artifacts: `functional-spec.md` (behavioral contract, ≥ 15 KB for a non-trivial product), `architecture.md` (system structure with data model + flow), and one of `architecture.html` (rendered diagram via mermaid or inline SVG) or `architecture.json` (machine-readable shape); the architecture artifacts are derivable from `functional-spec.md` so they stay in sync

- [ ] **Scenario: step 9 (system-design) produces architecture bundle**
  - **Given** an active pipeline at step 9 with step 8 (PRD) completed
  - **When** the agent submits step 9
  - **Then** `docs/product/09-system-design/` contains at minimum: `system-design.md` (≥ 20 KB), `architecture.md` (or `.json` for machine-readability), and a security-section file or block addressing OWASP/threat-model concerns

- [ ] **Scenario: step 13 (prototype-v3) is the comprehensive screen atlas after step 12**
  - **Given** steps 1-12 are completed, specification gate passed, pipeline at current_step=13
  - **When** the agent submits step 13 in `synthesis` mode reading steps 5 (brand), 6 (design-system), 8 (PRD), 9 (system-design), 11 (roadmap)
  - **Then** `docs/product/13-prototype-v3/<slug>/` contains: `screen-atlas.md` (navigable index with one row per screen → link to its HTML), `screens/01-<route>.html` … `screens/NN-<route>.html` (one HTML per PRD-derived screen, ≥ 8 KB each, brand+tokens applied, real copy not placeholder, all states covered — loading/empty/error/success), optional `flow.html`, and `REPORT.md` with `PRD coverage` (X/Y user stories mapped to screens) + `Design fidelity score` (1-5 per screen vs. step 6) + `States coverage matrix`; screen count is ≥ 8 for a non-trivial PRD; `product_done` fires automatically on `product_advance` after step 13 submit, surfacing `/sdd new <slug>` with screen-atlas.md as the primary visual reference

- [ ] **Scenario: re-dogfood produces ≥ 5x artifact volume vs spec 025 baseline**
  - **Given** a fresh fork-equivalent project directory with the MCP activated
  - **When** an agent walks all 13 steps end-to-end producing artifacts for a representative product (e.g. Linear-clone-v2 or a fresh product)
  - **Then** the total artifact volume under `docs/product/` is ≥ 285 KB (5x the 57 KB baseline from spec 025's Cycle dogfood); steps 2, 6, 7, 13 contain HTML/CSS files (not only markdown); steps 3, 9 contain ≥ 2 artifact files each; step 13's `screens/` dir contains ≥ 8 HTML files

- [ ] **Scenario: 3-layer quality discipline applies on every visual step**
  - **Given** any visual step (2, 6, 7, 13) being submitted
  - **When** validation runs against the submission
  - **Then** Layer 1 (floor) runs: every required path exists, each meets `min_size`, each contains the declared `contains` substrings; Layer 2 (AI judgement embedded) runs: the step's REPORT artifact contains the required critique sections (e.g. `5-dimension critique`, `PRD coverage`, etc. per step's `schema.md`); Layer 3 (human checkpoint) is encoded in the step's `prompt.md`: the agent's text response surfaces browser file:// URLs and explicitly requests user confirmation before calling `product_advance`

- [ ] **Scenario: extra_files persists multi-artifact bundles atomically**
  - **Given** the agent calls `product_step_submit(N, content, extra_files=[{path, content}, ...])` for a step that declares `required_files` in its schema
  - **When** all paths in `extra_files` are accepted by the validator (Layer 1 passes)
  - **Then** the MCP writes every file via mktemp + rename atomic write; `.state.json` records the step as completed only after all files are persisted; partial-write failure (e.g. one file's content fails Layer 1) returns `code: "schema-incomplete"` without writing ANY file from that submit call

- [ ] **Scenario: existing spec 025 plumbing is preserved with minimal surface change**
  - **Given** the deep-port shipped
  - **When** the existing test suite runs alongside new tests covering step 13 and `extra_files`
  - **Then** all 31 prior tests pass without modification; tool signatures are unchanged EXCEPT `product_step_submit` gains an optional `extra_files` parameter (backwards-compat — empty array = single-file submit, current behavior); `.state.json` schema unchanged; `STEPS` array extends from 12 to 13 entries; `GATE_AFTER` stays `[4, 7, 12]`

- [ ] **Scenario: per-step references resolve from packaged location**
  - **Given** a step template uses inline `references/<name>.md` content (mirroring anthill's skill layout)
  - **When** the agent calls `product_step_get(N)`
  - **Then** the response includes the prompt body PLUS any per-step references concatenated (or named separately in the response payload); the agent does not need to know the package's filesystem path to access reference content

- [ ] **Scenario: schema-level validation still fires on submit**
  - **Given** a step whose new template's `schema.md` lists required sections (e.g. step 2 requires `direction-a/b/c` and `compare`)
  - **When** the agent submits incomplete content
  - **Then** the MCP returns `code: "schema-incomplete"` with the missing sections enumerated, same shape as today; the new richer templates do NOT bypass validation

- [ ] All 13 step templates updated under `packages/mcp-product-pipeline/src/templates/<NN-name>/` with prompt.md content equivalent in instruction depth to the corresponding anthill source (mapping documented in `plan.md` § Step-to-skill mapping); per-step `references/` subdirs added where the source skill has them; step 13 (prototype-v3) is new — no direct 1:1 source, synthesizes patterns from anthill-prototype + anthill-prd PRD-coverage discipline + anthill-design-system
- [ ] Schema updates in each step's `schema.md` reflect the new artifact bundle shapes — required_files declared in YAML fenced block (path, min_size, contains[]) consumable by the new validator code
- [ ] `src/pipeline.ts` STEPS array extended from 12 to 13 entries; `src/tools.ts` `product_step_submit` accepts optional `extra_files` parameter (backwards-compat); `src/tools.ts` `product_step_get` response payload includes `references: { name: content }` map; remaining plumbing files (`server.ts`, `state.ts`, `paths.ts`) unchanged
- [ ] `README.md` updated to document the 13-step pipeline, per-step artifact bundles, the 3-layer quality discipline, and the screen-atlas as the `/sdd` handoff visual contract
- [ ] Re-dogfood artifacts shipped as evidence under `docs/specs/026-mcp-pipeline-deep-port/dogfood/` OR linked in spec body if hosted in a separate project dir (e.g. `/home/goat/<new-product-poc>/`)

## Non-goals

- **Re-architect MCP plumbing.** State machine, gates, delegation, handoff machinery from spec 025 stays as-is. Surface extensions are minimal and additive: `STEPS` array grows from 12 → 13 entries, `product_step_submit` gains optional `extra_files`, `product_step_get` response payload gains `references`. No new tool, no new gate, no schema break.
- **Port anthill's `.anthill/` runtime / hook / agent-memory layer.** Anthill skills sometimes reference `.anthill/memory/meetings/<gate>.md`, `anthill-halt`, `anthill-route`, halt-skill protocols. Those are anthill-specific harness extensions; the Agent0 base + `product_gate_pass` already covers the gating role. Strip such references during the port.
- **Port anthill's post-launch phase (anthill steps 14-20).** Anthill steps 14-20 (delivery / qa / security / gtm / metrics / iteration / learning) are event-driven, separate MCP later. Note: our step 13 (prototype-v3) is NEW — not the same as anthill's step 13 (delivery-plan); we deliberately use the slot for screen-atlas synthesis instead.
- **Port the 50 anthill domain-expert agents** (`anthill-cto`, `anthill-appsec`, `anthill-cmo`, etc.). The arch-review and security-review steps that anthill triggers via these agents stay future work; our step 9 templates can mention "have a security review pass" in prose without dispatching a specialized sub-agent.
- **`product_step_review` AI-judge sub-agent (Layer 4 of quality discipline).** Anthill-style automated render-test + 5-dim score via dispatched sub-agent with Playwright MCP is reserved for a follow-up spec. Layers 1-3 (floor + critique embedded + human visual checkpoint) are the MVP. The tool name is reserved; the surface is not built yet.
- **Skill-to-template porting tool / generator.** Manual port is acceptable for 13 steps; building a `port-skill.sh` automation would take longer than the manual work.
- **Stack-native code generation.** Anthill `anthill-prototype` has a `stack-native` mode that detects React/Vue/Svelte/Flutter and writes framework code. Our steps 2/7/13 stay HTML-mockup mode only — `stack-native` adds detection complexity that's downstream of `/sdd` engineering execution anyway.
- **Migrating spec 025's existing linear-clone-poc / Cycle dogfood artifacts.** Those stay on disk under `/home/goat/linear-clone-poc/` as evidence of the v1 baseline; the spec 026 dogfood produces fresh artifacts in a separate dir.
- **Backwards-compat shim for old `prototype-spec.md` shape.** Anyone running v1 templates can re-walk step 2 once the deep port lands; no migration path needed since this is pre-publication POC software.
- **Anthill drift-detection tooling.** Anthill is archived (2026-05-13); no upstream to track. No `check-anthill-drift.sh`, no version pin in template frontmatter. Mapping table in `plan.md` is sufficient audit-trail.

## Open questions

- [x] **Q1: How are per-step references shipped from the package to the agent?** **RESOLVED 2026-05-13:** map inline. `product_step_get(N)` response payload includes `{ prompt, schema, references: { name: content } }` — agent reads all references in one tool call, never touches package filesystem. Out-of-process clean; survives `npx -y github:...` install from arbitrary path. Trade-off: step 2 payload ~80 KB, absorbable.
- [x] **Q2: How does the agent persist multi-artifact bundles?** **RESOLVED 2026-05-13:** extend `product_step_submit` with optional `extra_files: { path: content }[]` map. MCP writes atomically (collect → mktemp → rename per file), validates Layer 1 (path + min_size + contains) before any write, returns `schema-incomplete` with missing-paths list on validation failure. Single-file submits remain backwards-compat (`extra_files` default empty array). MCP owns ALL artifacts on disk; agent's Write tool stays unused for product/ artifacts.
- [x] **Q3: Should each step's prompt reference an anthill source-skill version pin?** **RESOLVED 2026-05-13:** no pin. Anthill is archived (see `.claude/memory/anthill-archived.md`) — no upstream evolution to track against, drift-detection has zero value. A `Step-to-skill mapping` table in `plan.md` and `README.md` provides sufficient audit-trail for the port. Once content lands in our templates, it's ours; future evolution happens inside Agent0 + `packages/mcp-*`. Quality bar from anthill: equal-or-greater depth, equal artifact categories.
- [x] **Q4: How is artifact quality enforced on submit?** **RESOLVED 2026-05-13:** 3 layers, latency-irrelevant. Layer 1 — floor validation: `schema.md` declares `required_files` (YAML fenced block) with `path`, `min_size`, `contains[]` per file; validator runs cheap substring + size checks. Layer 2 — AI judgement embedded: schema enforces critique sections in REPORT artifacts (5-dimension scoring per step 2 direction; PRD-coverage + design-fidelity + states-matrix per step 13; equivalent per step 7). Layer 3 — human visual checkpoint: each visual step's `prompt.md` instructs the agent to surface `file://` URLs to the user and request explicit confirmation before calling `product_advance`. Layer 4 (deferred to v2): `product_step_review` tool dispatching AI-judge sub-agent with Playwright MCP for automated render + score.

## Context / references

- `docs/specs/025-mcp-product-pipeline/` — the plumbing this spec extends. Treat as frozen.
- `/home/goat/anthill/.claude/skills/anthill-prototype/` — 2311 LOC (SKILL.md + references/) — primary source for step 2 + step 7 port.
- `/home/goat/anthill/.claude/skills/anthill-design-system/`, `anthill-design-system-lead/` — sources for step 6 port.
- `/home/goat/anthill/.claude/skills/anthill-product-ideator/`, `anthill-prd/`, `anthill-roadmap-bridge/`, `anthill-system-design-bridge/`, `anthill-feature-refiner/` — sources for steps 1, 8, 11, 9, and 3-respectively.
- `/home/goat/anthill/.claude/skills/anthill-brand-designer/`, `anthill-corporate-counsel/`, `anthill-fpa/` (or `anthill-bizops-analyst/`), `anthill-ux-audit/` — sources for steps 5, 12, 10, 4.
- `.claude/memory/anthill-archived.md` — frozen-upstream context that drives Q3 (no version pin needed).
- Step 13 (prototype-v3) has no direct anthill 1:1 source — it's a synthesis step combining `anthill-prototype` patterns (HTML generation, multi-direction, embedded critique), `anthill-prd` PRD-coverage discipline, and `anthill-design-system` token application. Documented as new in `plan.md`.
- `/home/goat/anthill/docs/sdlc/02-prototype/pivota/` — reference output bundle (~290 KB) the deep port targets parity with.
- `/home/goat/anthill/docs/sdlc/cross-cutting/feature-specs/anthill-telegram-bridge*` — reference for the multi-artifact spec/architecture bundle shape (md + md + html + json).
- `/home/goat/linear-clone-poc/docs/product/` — baseline output the deep port targets ≥ 5x improvement against.
- `.claude/rules/spec-driven.md` — SDD discipline for this spec itself.
