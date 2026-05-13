# 026 — mcp-pipeline-deep-port — plan

_Drafted from `spec.md` on 2026-05-13. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

The work has two coupled axes: **plumbing extensions** (small, contained, but unlocking everything else) and **content port** (the bulk of the effort — 13 templates × ~2000 LOC of instruction each, plus references). Execution order is plumbing-first because content can't be tested without it; once `extra_files`, `references`, and the 13th STEPS entry are in place, the templates can be ported in pipeline order (1 → 13). The final mile is end-to-end dogfood of a fresh product, validating that artifact volume + categorical shape meet the spec's acceptance bar.

The 3-layer quality discipline is encoded uniformly: Layer 1 in the validator (parses `required_files` YAML from `schema.md`, runs path + min_size + contains checks atomically before any write), Layer 2 in each visual step's `schema.md` (declares critique-section requirements that the validator confirms in REPORT artifacts), Layer 3 in each visual step's `prompt.md` (instructs the agent to surface `file://` URLs and request explicit user confirmation before `product_advance`). No new tool is added — surface stays at 8 tools; `product_step_submit` gains an optional parameter, `product_step_get` response payload grows. Backwards-compat is preserved (`extra_files` defaults to empty array; single-file submits work unchanged).

Step 13 (prototype-v3) is the last to be implemented because it's the only step with no direct anthill source — it synthesizes patterns from `anthill-prototype` (HTML generation, multi-screen, embedded critique), `anthill-prd` (PRD-coverage scoring discipline), and `anthill-design-system` (token application). It lives in the Specification phase (no new gate), and `product_done` fires automatically when `product_advance` is called after its submit. The `/sdd new <slug>` handoff message is rewritten to point engineering at `screen-atlas.md` as the primary visual contract — not the PRD alone.

## Files to touch

**Create:**

Plumbing test additions:
- `packages/mcp-product-pipeline/tests/extra-files.test.ts` — atomicidade across `extra_files`, Layer 1 validation rejection, partial-write rollback
- `packages/mcp-product-pipeline/tests/required-files-schema.test.ts` — YAML fenced block parsing in `schema.md`, edge cases (special chars in `contains`, glob patterns for step 13)
- `packages/mcp-product-pipeline/tests/step13.test.ts` — STEPS array extension, `product_done` fires after step 13, screen-atlas validation

Step 13 template (new step):
- `packages/mcp-product-pipeline/src/templates/13-prototype-v3/prompt.md` — synthesis-mode prompt instructing screen atlas production
- `packages/mcp-product-pipeline/src/templates/13-prototype-v3/schema.md` — required_files for `screen-atlas.md`, `screens/*.html` glob, `REPORT.md` critique sections
- `packages/mcp-product-pipeline/src/templates/13-prototype-v3/references/screen-atlas-format.md` — atlas index conventions, navigation
- `packages/mcp-product-pipeline/src/templates/13-prototype-v3/references/states-coverage.md` — loading/empty/error/disabled/success matrix
- `packages/mcp-product-pipeline/src/templates/13-prototype-v3/references/prd-coverage-rubric.md` — how to map user stories to screens

Per-step `references/` subdirs (ported from anthill):
- `packages/mcp-product-pipeline/src/templates/02-prototype/references/` — visual-constraints.md, a11y-checklist.md, design-fidelity-checklist.md, anti-patterns.md, examples.md, od-bridge.md (HTML-mockup pipeline)
- `packages/mcp-product-pipeline/src/templates/06-design-system/references/` — examples.md, anti-patterns.md, checklist.md
- `packages/mcp-product-pipeline/src/templates/07-prototype-v2/references/` — token-mapping.md, design-fidelity-checklist.md (shared with step 2 conceptually but step-specific in instruction)
- `packages/mcp-product-pipeline/src/templates/03-spec/references/` — functional-spec-template.md, architecture-shape.md (multi-artifact patterns)
- `packages/mcp-product-pipeline/src/templates/09-system-design/references/` — architecture-shape.md, security-section.md, scale-assumptions.md
- Plus `references/` for steps 1, 4, 5, 8, 10, 11, 12 as the anthill sources have them — confirm during port

Dogfood evidence:
- `docs/specs/026-mcp-pipeline-deep-port/dogfood/` — re-dogfood output (or link in spec body if hosted under `/home/goat/<new-product-poc>/`)

**Modify:**

Plumbing core:
- `packages/mcp-product-pipeline/src/pipeline.ts` — `STEPS` array gains 13th entry `{ n: 13, slug: "prototype-v3", phase: "specification" }`; `GATE_AFTER` unchanged `[4, 7, 12]`; helper functions (`stepByN`, `isGateAfter`, `gateClosingPhase`) auto-cover the extension since they operate on the array
- `packages/mcp-product-pipeline/src/templates.ts` — `getTemplate(n)` extended to load all `references/*.md` siblings into a map; new `parseRequiredFiles(schemaBody)` helper extracts the YAML fenced block declaring `required_files: [{path, min_size, contains[]}]`
- `packages/mcp-product-pipeline/src/tools.ts`:
  - `product_step_get(N)` response payload extended: `{ prompt, schema, references: { name: content }, required_files: [...] }`
  - `product_step_submit(N, content, extra_files?)` extends signature; new validation pass — for each entry in `extra_files` AND the primary `content`, run Layer 1 checks against `required_files`; if any fail, return `code: "schema-incomplete"` with `missing_or_invalid` list; if all pass, write all files atomically (mktemp+rename per file inside one operation)
  - `product_advance` after step 13: returns `code: "pipeline-complete"` (already implemented); `product_done` message rewritten to reference screen-atlas
- All 13 templates' `prompt.md` and `schema.md` — see Step-to-skill mapping table below for per-step source + content shape

Tests (existing):
- `packages/mcp-product-pipeline/tests/state.test.ts` — extend step-count fixtures from 12 to 13
- `packages/mcp-product-pipeline/tests/templates.test.ts` — extend to validate frontmatter on step 13 + references loading
- All 31 prior tests must continue passing; no API break

Documentation:
- `packages/mcp-product-pipeline/README.md` — 13-step pipeline diagram, per-step artifact bundles, 3-layer quality discipline section, `/sdd` handoff workflow updated
- `.mcp.json.example` — header note acknowledges 13 steps (cosmetic)

**Delete:**
- None.

## Step-to-skill mapping

Required by spec.md AC. Documents the anthill source for each template ported. Pin column intentionally absent — anthill is archived, no version tracking needed (see `.claude/memory/anthill-archived.md`).

| Step | Slug | Anthill source(s) | Output bundle (deep port target) |
|---|---|---|---|
| 1 | ideation | `anthill-product-ideator` | `01-ideation/04-concept-brief.md` (single artifact OK; same as today, content depth increases) |
| 2 | prototype | `anthill-prototype` (html-mockup mode) + references | `02-prototype/<slug>/{direction-a,b,c}.html`, `compare.html`, `REPORT.md` with 5-dim critique |
| 3 | spec | `anthill-feature-refiner` + `anthill-spec` | `03-spec/{functional-spec.md, architecture.md, architecture.html or .json}` |
| 4 | ux-testing | `anthill-ux-audit` | `04-ux-testing/validation-report.md` (single artifact; richer content) |
| 5 | brand | `anthill-brand-designer` | `05-brand/brand-book.md` + voice-samples (single artifact; multi-section) |
| 6 | design-system | `anthill-design-system` + `anthill-design-system-lead` | `06-design-system/{tokens.css, components.md, design-system.md}` |
| 7 | prototype-v2 | `anthill-prototype` (re-invoked) + `anthill-design-system` (token mapping) | `07-prototype-v2/<slug>/{direction-final.html, screens/*.html}` |
| 8 | prd | `anthill-prd` | `08-prd/prd.md` (single artifact; richer) |
| 9 | system-design | `anthill-system-design-bridge` + `anthill-principal-engineer` | `09-system-design/{system-design.md, architecture.json or .html, security.md}` |
| 10 | cost-estimate | `anthill-fpa` or `anthill-bizops-analyst` | `10-cost-estimate/cost-estimate.md` (single artifact; richer with sensitivity) |
| 11 | roadmap | `anthill-roadmap` + `anthill-roadmap-bridge` | `11-roadmap/roadmap.md` (single artifact; phased + milestones + risks) |
| 12 | legal | `anthill-corporate-counsel` + `anthill-privacy-dpo` + `anthill-ip-counsel` | `12-legal/legal-posture.md` (single artifact; multi-section regulated-aspects) |
| 13 | prototype-v3 | **NEW** — synthesis from `anthill-prototype` patterns + `anthill-prd` PRD-coverage discipline + `anthill-design-system` token application | `13-prototype-v3/<slug>/{screen-atlas.md, screens/*.html, flow.html, REPORT.md}` |

## Alternatives considered

### Split into three specs (026a plumbing / 026b content port / 026c step 13)

Rejected. The three changes are deeply coupled: content port REQUIRES `extra_files` + references plumbing to land first; step 13 REQUIRES STEPS extension + the new Layer 2 critique-section schema vocabulary. Splitting creates artificial commit barriers and forces three separate dogfood walks instead of one cohesive end-to-end validation. The bundled shape also makes the "categorical artifact upgrade" thesis verifiable in one diff.

### Per-step micro-PRs (one PR per template port)

Rejected. Individual step ports don't validate the spec's central claim (artifact volume ≥ 5x, categorical shape change, 3-layer quality applied consistently). A PR for step 2 alone produces an HTML bundle but doesn't prove the discipline works; the discipline IS the cross-cutting deliverable. Per-step PRs also explode review surface (13 PRs × CI + review cycles) for no architectural gain — the templates are conceptually one logical change.

### In-place evolution of spec 025 templates (no new spec)

Rejected. The plumbing changes (`extra_files`, `references`, 13-step) are architectural extensions deserving their own design memory. Appending to 025's already-closed `tasks.md` would (a) lose the rationale for the gap-discovery → resolution → re-dogfood arc, and (b) make 025 ambiguous about what shipped when. Specs are git-tracked design memory; their boundaries should match logical scope.

### Defer step 13 to a later spec (027)

Rejected. Step 13 is load-bearing to the "screen-atlas hands off to /sdd" thesis. Without it, the deep port leaves the engineering handoff weaker than the planning phase produced — engineering gets PRD prose + design tokens but no comprehensive visual surface. The whole point of going deep is that engineering should receive an executable visual contract. Deferring would mean shipping a spec that knowingly leaves the most consequential handoff under-served.

### Verbatim copy of anthill skill content (no rewrite)

Rejected. Anthill skills reference `.anthill/runtime/`, `anthill-route`, `anthill-halt`, `anthill-memory/meetings/`, SOUL.md personas — runtime extensions that don't exist in the Agent0 + MCP world. Mechanical verbatim port is impossible because the references break. Structural port (preserve checklists, schemas, instruction depth; strip `.anthill/` references; rewrite halt-protocol into `product_step_submit` validation errors) IS the work. This is also why Q3's "no source pin" is fine — once the content lands in our templates, it's ours; "stay faithful to upstream" is a non-constraint.

### Implement Layer 4 (`product_step_review` with Playwright sub-agent) in MVP

Rejected. Layers 1-3 already deliver objective floor + AI-judgement-in-artifact + human-checkpoint. Layer 4 is automated render-test + 5-dim auto-score via dispatched sub-agent. The marginal value over Layer 2 (which already embeds the 5-dim critique in REPORT) is real but small for MVP — the human visual checkpoint (Layer 3) catches what Layer 2 might fake. Layer 4 becomes valuable once the workflow is at scale (10+ products through the pipeline) and the human-bottleneck becomes load-bearing. Reserved name in non-goals, hook defined.

## Risks and unknowns

- **Risk: payload size on `product_step_get(2)`.** Anthill `anthill-prototype` references total ~80 KB (shadcn-bootstrap.md alone is 917 LOC). The response payload at step 2 will be ~80-100 KB. MCP stdio has no hard cap, but consumes context budget. Mitigation: agents cache the response naturally per session; delegated sub-agents pay the cost once in their own context budget. Acceptable.

- **Risk: `extra_files` atomicidade with large step 13 payloads.** Comprehensive screen atlas for non-trivial PRD = 8-30 screens × ~20-25 KB HTML each. Step 13 submit could be ~500 KB - 1 MB. Implementation: collect all files in memory → validate all (Layer 1) → write all (mktemp + rename per file). Memory cost is bounded by 1 MB worst case. If the MCP process is killed mid-write, mktemp files orphan — cleanup on next start via prefix scan. Manageable.

- **Risk: schema.md YAML edge cases.** `contains: ["</style>"]` could trip YAML quoting if not single-quoted. Document the format in `templates.ts` doc + a reference file; enforce by parser. Tests cover special-char cases.

- **Risk: step 13 `required_files` needs glob support.** Screen count is product-dependent; can't list `screens/01-foo.html`, `screens/02-bar.html` etc. statically in schema. Need glob support: `screens/[0-9]+-*.html` with min-count constraint. Implement as a new YAML field shape: `required_glob: { pattern, min_count, per_match_min_size, per_match_contains[] }`. Implementation choice belongs in plumbing phase.

- **Risk: re-dogfood discovers residual quality gaps.** 3 layers catch obvious failures but quality is qualitative. A determined-to-be-bad agent (or a model regression) can still produce bad-looking but Layer-1-passing HTML. Layer 4 is reserved for this exact failure mode. MVP accepts the residual; the dogfood walk surfaces patterns; spec 027 (if needed) adds Layer 4 with concrete failure-case examples.

- **Risk: anthill content references `.anthill/`-specific halt/route/memory primitives.** Each ported template needs review pass to strip these. Mitigation: per-step "stripped/replaced" notes in plan.md as the port lands, captured in the commit messages.

- **Unknown: which anthill skills genuinely have rich `references/` and which don't.** Step 4 (ux-audit), step 10 (fpa), step 12 (corporate-counsel) may be lighter — confirm during port; `references/` subdir is optional per step.

- **Unknown: dogfood product slug.** Linear-clone-poc was used for spec 025. For spec 026, options: re-dogfood Linear-clone (regression comparison apples-to-apples) OR fresh product (avoid bias from agent memorizing prior decisions). Decide before tasks.md is locked.

- **Unknown: how to express step 13's PRD-coverage scoring concretely.** "X/Y user stories covered" requires the PRD (step 8) to enumerate user stories with stable identifiers. Step 8 template needs a "user-stories with ID" convention. Confirm during step 8 port.

## Research / citations

- `.claude/memory/anthill-archived.md` — frozen-upstream context driving Q3 / drift-detection rejection (2026-05-13)
- `.claude/memory/agent0-purpose.md` — Agent0 template-forever posture; harness stays generic, packages stay opt-in
- `/home/goat/anthill/.claude/skills/anthill-prototype/SKILL.md` — primary content source for step 2 + step 7 (2311 LOC including references)
- `/home/goat/anthill/.claude/skills/anthill-design-system/SKILL.md` + references — content source for step 6 (351 LOC)
- `/home/goat/anthill/.claude/skills/anthill-prd/`, `anthill-roadmap/`, `anthill-system-design-bridge/`, etc. — content sources per mapping table
- `/home/goat/anthill/docs/sdlc/02-prototype/pivota/` — reference output bundle (~290 KB; 8 screens HTML + 3 directions + REPORT + compare); the deep port's volume target
- `/home/goat/anthill/docs/sdlc/cross-cutting/feature-specs/anthill-telegram-bridge*` — reference for multi-artifact spec/architecture bundle shape (md + md + html + json + security md = ~132 KB per feature)
- `/home/goat/linear-clone-poc/docs/product/` — spec 025 baseline (~57 KB); volume to beat by ≥ 5x
- `docs/specs/025-mcp-product-pipeline/spec.md` + `plan.md` — plumbing this spec extends; frozen surface
- `.claude/rules/spec-driven.md` — SDD discipline shape; this spec follows the rule itself
- Anthropic MCP SDK 1.29.0 docs (referenced from spec 025; payload-size considerations re: `product_step_get` references map)
