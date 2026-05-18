# Delegation briefs — 5-field templates per sub-agent (v2)

Every `Agent` tool call dispatched by `/prototype` v2 MUST use the 5-field handoff per `.claude/rules/delegation.md` (TASK / CONTEXT / CONSTRAINTS / DELIVERABLE / DONE_WHEN). The delegation-gate hook returns exit 2 otherwise.

**14 briefs total:** 13 step-specific (one per pipeline step) + 1 per-stack screen-writer template (reused by steps 02/07/13 for per-route fan-out).

**Per-step model assignment** (per spec 036 Q1 resolution): Step 01 = `opus` (concept brief multi-source synthesis); Steps 02-13 = `sonnet` (mechanical with dense brief + bundled template).

**Substitution placeholders** ({{...}}) are replaced inline by the orchestrator (SKILL.md) before dispatch. The orchestrator reads `.state.json` for `slug`, `idea`, `out`, `flags.stack` and the prior-step outputs by path.

## Phase 1 — Discovery

### Step 01 — Ideation (concept brief)

**model:** `opus`  ·  **subagent_type:** `general-purpose`

```
TASK: Produce concept-brief.md for the product idea "{{idea}}" — a deep concept brief covering market fit, persona, mechanics, growth, monetization, and risks.

CONTEXT: Read .claude/skills/prototype/templates/pipeline/01-ideation/prompt.md for the canonical brief structure (17 sections in the heavy pipeline; we target a STANDARD-TIER subset). Read .claude/skills/prototype/templates/pipeline/01-ideation/references/concept-brief-template.md for the section shape. Read .claude/skills/prototype/templates/pipeline/01-ideation/references/discovery-playbook.md for the 5-track market discovery process. Read .claude/skills/prototype/references/pipeline-coverage.md § "Per-step output + size targets" for the standard-tier calibration. Use WebSearch + WebFetch for 5-8 market discovery searches (NOT the canonical 15-25 — standard tier).

CONSTRAINTS:
- Standard tier: target 4-10 KB output (NOT the canonical 12-25 KB).
- Cover the standard-tier minimum sections: Hook (problem + audience) / Mechanics (user flow) / Monetization (business model) / Growth loop / Competitive positioning / Risks / Anti-goals / JTBD statement. SKIP critique-mode (4-7 challenger concepts) at standard tier.
- Cite at least 5 unique sources (web or repo) with inline [N] references.
- Name placeholder discipline: if final product name not yet decided, use `**Working name:** <placeholder> (placeholder, never shipped; final at Step 05 brand-book § Product Name)`.
- Do NOT invent statistics — every claim either cites a source OR is hedged ("anecdotally", "in this researcher's view").

DELIVERABLE: concept-brief.md at {{out}}/concept-brief.md

DONE_WHEN: File exists; size ≥ 4 KB; all 8 standard-tier sections present (H2 headings); ≥ 5 unique [N] source citations; placeholder discipline applied if name not finalized.
```

### Step 02 — Prototype v1 (direction + killer-flow screens)

Two sub-agent dispatches: (a) one direction-writer for the visual mood board; (b) N screen-writers for the killer flow.

**(a) Direction writer — model:** `sonnet`  ·  **subagent_type:** `general-purpose`

```
TASK: Produce direction-a.html — a single HTML mood board proposing the visual direction for "{{idea}}".

CONTEXT: Read concept-brief.md at {{out}}/concept-brief.md for product persona + mechanics. Read .claude/skills/prototype/templates/pipeline/02-prototype/prompt.md for the canonical mood-board structure (the heavy pipeline produces 3 directions; we produce ONE at standard tier — per spec 036 Q1 lightening). Read .claude/skills/prototype/references/od-catalog-index.json for the 72-vendor catalog; pick 1-2 vendors whose mood matches the product and cite them by name + vendor_path. Read .claude/skills/prototype/templates/pipeline/02-prototype/schema.md for the 8 mandatory sections (palette strip / type sample / hero / dashboard / charts / pricing / FooterCTA + design-system lineage citation).

CONSTRAINTS:
- Standard tier: ONE direction only (not 3 mood boards + compare picker). Direction-pick collapses into the Phase 1 gate.
- 8 mandatory sections present. Cite 1-2 OD vendors by name + vendor_path.
- Self-contained HTML — single file, all inline styles + SVG. No external assets.
- CSS uses :root custom properties (--color-primary, --background, --foreground) — vendor-agnostic naming.
- Includes "Most Popular" string token + at least one `<svg` element (catalog citation discipline).

DELIVERABLE: direction-a.html at {{out}}/direction-a.html

DONE_WHEN: File exists; size ≥ 6 KB; contains :root + --background + --foreground + --primary tokens; contains "Most Popular"; contains at least one `<svg`; cites at least 1 OD vendor name in HTML comment header.
```

**(b) Screen writer — reused by steps 02 / 07 / 13.** See § Per-stack screen-writer below.

### Step 03 — Spec (functional + architecture)

**model:** `sonnet`  ·  **subagent_type:** `general-purpose`

```
TASK: Produce functional-spec.md decomposing "{{idea}}" into pages, components, interactions, states, features with Gherkin acceptance scenarios + a preliminary architecture skeleton.

CONTEXT: Read concept-brief.md at {{out}}/concept-brief.md for product scope. Read direction-a.html + screens/ at {{out}}/ for surface inventory. Read .claude/skills/prototype/templates/pipeline/03-spec/prompt.md for canonical structure (functional-spec ≥ 15 KB + architecture.md ≥ 4 KB separate in heavy mode; standard tier combines to 8-12 KB single file). Read .claude/skills/prototype/templates/pipeline/03-spec/schema.md.

CONSTRAINTS:
- Standard tier: combined functional-spec.md (skip separate architecture.md / architecture.json). 8-12 KB target.
- Sections required: Product Overview / Pages & Surfaces (table per page with components/interactions/states) / Features (with Gherkin **Given**/**When**/**Then** scenarios) / Navigation Map / Cross-cutting concerns / Acceptance Scenarios / Edge Cases / Non-goals / Decisions Pending / Preliminary Architecture (module decomposition + data-model sketch + key flows).
- Scale depth to surface importance — killer flow gets full treatment; trivial pages collapse to 2-4 table rows.
- Every "Decisions Pending" row has either a source citation OR a default value.

DELIVERABLE: functional-spec.md at {{out}}/functional-spec.md

DONE_WHEN: File exists; size 8-12 KB; contains **Given** / **When** / **Then** keywords; contains "Pages & Surfaces" + "Features" + "Preliminary Architecture" section headers; ≥ 3 Gherkin scenarios.
```

### Step 04 — UX Testing (heuristic audit)

**model:** `sonnet`  ·  **subagent_type:** `general-purpose`

```
TASK: Produce validation-report.md — heuristic audit (Nielsen's 10 + WCAG 2.1 AA) on the Phase 1 prototype surfaces + validation mode declaration.

CONTEXT: Read direction-a.html at {{out}}/direction-a.html + screens/ at {{out}}/screens/ for the rendered surfaces (PROJECTED-mode audit at standard tier — infer what would render without opening in browser). Read functional-spec.md at {{out}}/functional-spec.md for declared behavior. Read .claude/skills/prototype/templates/pipeline/04-ux-testing/prompt.md + schema.md for audit shape.

CONSTRAINTS:
- Standard tier: PROJECTED mode (not MEASURED). Audit infers contrast / tab order / a11y from spec + HTML inspection. Mark findings as `warn` with "verify in step 7" tracking.
- Heuristic-only — Nielsen's 10 (visibility, match real-world, user control, consistency, error prevention, recognition, flexibility, minimal design, error recovery, help docs) + WCAG 2.1 AA top issues (color contrast, focus management, semantic HTML, alt text, keyboard nav).
- validation_mode: must be one of `tested` / `intuition` / `not-applicable` — for standard tier prototype, default `intuition` (projected audit on hi-fi but not user-tested with real humans yet).
- YAML frontmatter: `findings[]` with `{id, severity 1-4, heuristic, location, issue, recommendation, fix_skill_hint}` where fix_skill_hint ∈ `{design-system, prototype-v2, deferred}`.
- ≥ 3 findings minimum (if fewer, audit was too shallow — re-look).

DELIVERABLE: validation-report.md at {{out}}/validation-report.md (with YAML frontmatter)

DONE_WHEN: File exists; size 5-8 KB; contains `Nielsen` + `WCAG` substring; contains `validation_mode: intuition` (or other valid value) line; YAML frontmatter parses with ≥ 3 findings entries each carrying severity + fix_skill_hint.
```

## Phase 2 — Identity

### Step 05 — Brand (brand book)

**model:** `sonnet`  ·  **subagent_type:** `general-purpose`

```
TASK: Produce brand-book.md — voice + visual direction posture + we-are/we-are-not contrast pair for "{{idea}}".

CONTEXT: Read concept-brief.md at {{out}}/concept-brief.md for persona + audience. Read direction-a.html at {{out}}/direction-a.html for visual lineage. Read .claude/skills/prototype/templates/pipeline/05-brand/prompt.md for canonical 7-section structure (we target 2-3 section snapshot at standard tier — per spec 036 Q1 lightening).

CONSTRAINTS:
- Standard tier: 2-3 sections (NOT canonical 7). Voice Samples + Visual Direction posture + ONE "We are / We are not" pair minimum. Skip the founder-interview turn — synthesize from concept-brief + direction-a directly.
- Voice samples: 3 minimum (one-liner per surface type — headline, microcopy, CTA label).
- Visual Direction names the feel (e.g. "Cool Brutalist", "Warm Premium") + 2-3 posture decisions (e.g. "hairline 1px borders only" / "monospace dominant" / "single saturated accent"). NO hex codes (step 06 handles).
- "We are / We are not" pair: contrast — NOT a flat adjective list. (e.g. "We are: terse, technical, data-dense. We are NOT: friendly, conversational, emoji-rich.")
- Header includes **Version:** and **Date:** for audit trail.
- 4-8 KB target.

DELIVERABLE: brand-book.md at {{out}}/brand-book.md

DONE_WHEN: File exists; size 4-8 KB; contains **Version:** + **Date:** + **We are** + **We are not** + 3+ voice samples + visual-direction posture (named feel + 2+ posture decisions).
```

### Step 06 — Design System (tokens + components + narrative)

**model:** `sonnet`  ·  **subagent_type:** `general-purpose`

```
TASK: Produce tokens.css + components.md + design-system.md applying the brand-book to concrete semantic design tokens for "{{idea}}". Prefer catalog path (cite 1-2 OD vendors).

CONTEXT: Read brand-book.md at {{out}}/brand-book.md for posture + voice. Read concept-brief.md at {{out}}/concept-brief.md for product class. Read .claude/skills/prototype/references/od-catalog-index.json for the 72-vendor catalog — pick 1-2 vendors whose mood + category match the brand-book; their DESIGN.md path (vendor_path field) is the lineage citation source. Read validation-report.md at {{out}}/validation-report.md frontmatter `findings[]` and filter `fix_skill_hint: "design-system"` — these are token tunes to apply. Read .claude/skills/prototype/templates/pipeline/06-design-system/prompt.md + schema.md.

CONSTRAINTS:
- Standard tier: catalog path PREFERRED — if 1-2 vendors match, inherit their tokens with brand-tuned overrides. Custom path only when zero vendors match (rare).
- Semantic token names ONLY — `--color-primary` not `--color-blue-500`; `--space-md` not `--space-12`. NO visual naming.
- tokens.css: dark-first :root block + @media (prefers-color-scheme: light) overrides for color tokens. Includes color (foreground/background/muted/primary/accent/success/warning/danger) + spacing (xs/sm/md/lg/xl) + radius (sm/md/lg) + font (family-sans/family-mono + size scale). 1.5+ KB.
- components.md: per-component anatomy + variants + states. 3+ KB.
- design-system.md: overview + tokens narrative + audit-response section (which step-04 findings were applied as token tunes) + catalog lineage (if catalog path). 8+ KB.
- Resist token inflation — 8-14 colors, 5-7 type scales target.

DELIVERABLE: 3 files at {{out}}/: tokens.css + components.md + design-system.md

DONE_WHEN: tokens.css ≥ 1.5 KB valid CSS with :root block; components.md ≥ 3 KB; design-system.md ≥ 8 KB + contains "Audit Response" section header + (if catalog path) cites OD vendor name + vendor_path.
```

### Step 07 — Prototype v2 (brand + tokens applied; audit fixes inlined)

Two-part dispatch like step 02: direction-final writer + N screen re-writers.

**(a) Direction-final writer — model:** `sonnet`  ·  **subagent_type:** `general-purpose`

```
TASK: Produce direction-final.html — the design-system showcase proving brand + tokens hold together across the killer-flow surfaces for "{{idea}}".

CONTEXT: Read brand-book.md + tokens.css + components.md + design-system.md at {{out}}/. Read direction-a.html at {{out}}/direction-a.html for inheritance (same posture, same 8 sections — final brand-tuned). Read validation-report.md frontmatter findings with `fix_skill_hint: "prototype-v2"` — inline those fixes into the showcase. Read .claude/skills/prototype/templates/pipeline/07-prototype-v2/prompt.md + schema.md.

CONSTRAINTS:
- Refinement, not redesign — same 8-section rhythm as direction-a.html; replace placeholder tokens with step-06 tokens (`var(--color-primary)` etc); voice-tune copy from step-05 brand-book voice samples.
- Inline step-04 audit fixes tagged `prototype-v2` — focus-visible restore, semantic HTML, skip-link, etc.
- Brand-name rename pass: if step-05 brand-book finalized a name differing from step-01 placeholder, propagate everywhere.
- 8+ KB.

DELIVERABLE: direction-final.html at {{out}}/direction-final.html

DONE_WHEN: File exists; size ≥ 8 KB; references tokens.css via @import or inline var(--color-*); cites step-06 design-system.md in HTML comment header; brand-name from step-05 propagates.
```

**(b) Screen re-writer:** see § Per-stack screen-writer below. Inheritance — same N + same filenames as step-02 screens.

## Phase 3 — Specification

### Step 08 — PRD

**model:** `sonnet`  ·  **subagent_type:** `general-purpose`

```
TASK: Produce prd.md — canonical product spec with stable US-NN user-story IDs, P0/P1/P2 tiering, ONE primary success metric, acceptance criteria per story for "{{idea}}".

CONTEXT: Read concept-brief.md + functional-spec.md + validation-report.md frontmatter + direction-final.html + brand-book.md + design-system.md at {{out}}/. Step 04 findings: `design-system` → "(resolved at step 06)" annotation; `prototype-v2` → "(resolved at step 07)" annotation; `deferred` → Backlog. Read .claude/skills/prototype/templates/pipeline/08-prd/prompt.md + schema.md.

CONSTRAINTS:
- 6-10 KB. Skip in-PRD competitive analysis (concept-brief already covers).
- User-story IDs: zero-padded sequential (US-01, US-02, ...). APPEND-don't-renumber discipline (step 13 atlas's coverage matrix depends on stable IDs).
- P0/P1/P2 tiering — hard cut. Everything else is Backlog or explicit non-goal.
- ONE primary success metric (not two equal; supporting observability metrics are optional read-only).
- Spec-Pending decisions from step-03 RESOLVED inline (founder-locked → apply; spec-default applies → state reason; genuinely open → Open Questions).
- Section headers required: Problem / Audience / Success Metric / User Stories (table with US-NN | priority | story | acceptance) / Audit Response / Open Questions / Backlog / Non-goals.

DELIVERABLE: prd.md at {{out}}/prd.md

DONE_WHEN: File exists; size 6-10 KB; contains literal table-row `| US-NN |` (at least one); contains "Success Metric" section header; ONE primary metric named (NOT two with equal priority); P0/P1/P2 tiers visible in table.
```

### Step 09 — System Design

**model:** `sonnet`  ·  **subagent_type:** `general-purpose`

```
TASK: Produce system-design.md (bridge-floor) + security.md for "{{idea}}".

CONTEXT: Read prd.md (scope drives scale assumption) + functional-spec.md (preliminary architecture) + concept-brief.md (product class + audience) at {{out}}/. Read .claude/skills/prototype/templates/pipeline/09-system-design/prompt.md + schema.md.

CONSTRAINTS:
- Standard tier: BRIDGE-FLOOR (6 sections: Stack / Integrations / Data Model / Decisions Locked / Security / Observability). 12+ KB. SKIP trade-off triggers + alternatives-considered + non-functional budgets (defer to engineering phase via /sdd new).
- Every choice justified against PRD success metric or v1 constraint — NOT abstract preference.
- Monolith-within-modules disclaimer when applicable (modules = behavioral boundaries, not service boundaries).
- security.md: STRIDE-lite threat model + auth/authz + data classification + secrets handling + AI-specific section (only when LLM in Integrations). 3+ KB. SKIP regulated-aspect deep dive (step-12 legal covers).

DELIVERABLE: system-design.md + security.md at {{out}}/

DONE_WHEN: system-design.md ≥ 12 KB + 6 section headers present; security.md ≥ 3 KB + contains "Threat Model" + "Auth" + "Data Classification" + "Secrets" section headers.
```

### Step 10 — Cost Estimate

**model:** `sonnet`  ·  **subagent_type:** `general-purpose`

```
TASK: Produce cost-estimate.md — single-scenario burn rate + run-cost line items for v1 of "{{idea}}".

CONTEXT: Read system-design.md at {{out}}/system-design.md (stack + integrations drive line items). Read prd.md (success metric drives scale assumption). Read concept-brief.md (audience drives revenue assumptions if applicable). Read .claude/skills/prototype/templates/pipeline/10-cost-estimate/prompt.md + schema.md.

CONSTRAINTS:
- Standard tier: SINGLE-SCENARIO only (NOT bear/base/bull). 5-8 KB.
- Build cost as a RANGE (never single point) broken down by phase (Foundation / Killer Flow / Surrounding / Polish). Includes hourly rate or weekly-rate assumption with source/confidence.
- Run cost line items at v1 scale: tabular per vendor (vendor / tier / monthly cost / source). Count must match system-design § Integrations list (audit discipline).
- Assumptions table required — every model input has source + confidence (high / med / low).
- Top 5 financial risks (one-liner each).
- 3-5 Recommendations with action verbs + "flip if" deciding signal per recommendation.
- SKIP unit economics / sensitivity analysis / scenario analysis (defer to post-launch real data).

DELIVERABLE: cost-estimate.md at {{out}}/cost-estimate.md

DONE_WHEN: File exists; size 5-8 KB; contains "Assumptions" + "Run Cost" + "Recommendations" section headers; run-cost vendor count matches system-design integration count.
```

### Step 11 — Roadmap

**model:** `sonnet`  ·  **subagent_type:** `general-purpose`

```
TASK: Produce roadmap.md — 3-phase MVP/Growth/Polish sketch for v1 of "{{idea}}".

CONTEXT: Read prd.md (user stories + priorities) + system-design.md (dependencies) + cost-estimate.md (build cost ranges per phase) + concept-brief.md (product class calibration) + validation-report.md (validation_mode drives canonical-vs-bridge mode) at {{out}}/. Read .claude/skills/prototype/templates/pipeline/11-roadmap/prompt.md + schema.md.

CONSTRAINTS:
- Standard tier: 3-phase sketch (MVP / Growth / Polish) with phase titles USER-FLOW SHAPED (e.g. "Sign up, land in empty workspace") NOT label-shaped ("Foundation"). 5-8 KB.
- Mode by validation_mode: `tested` → canonical timeline-aware (week ranges + milestones + buffer); `intuition`/`not-applicable` → bridge mode (priority-tier grouping P0→MVP, P1→Growth, P2→Polish, no week commitments).
- Slices end-to-end user value (Shape Up style) — NO horizontal layers like "Phase 1: all backend".
- Deliverables table per phase: rows reference step-08 US-NN / step-09 § / step-10 §.
- Milestones are observable end-of-phase deliverables (founder recognizes complete).
- Skip risks+buffer table + v2-vision sketch + concern tags + dependency graph (defer to engineering phase).
- § Overview 2-3 one-liners. § Horizon (duration + team shape). § Open Decisions table.

DELIVERABLE: roadmap.md at {{out}}/roadmap.md

DONE_WHEN: File exists; size 5-8 KB; 3 phase headers present + each phase has 1-3 milestones + deliverables table per phase + § Open Decisions section.
```

### Step 12 — Legal Posture

**model:** `sonnet`  ·  **subagent_type:** `general-purpose`

```
TASK: Produce legal-posture.md — founder's articulated legal posture briefing for v1 of "{{idea}}". This is a BRIEFING for counsel, NOT the actual Terms/Privacy/DPA documents.

CONTEXT: Read prd.md (audience drives jurisdiction exposure) + system-design.md (Integrations name every sub-processor + AI-in-stack signal) + cost-estimate.md (budget for DPA/legal review/SOC 2 audit) + roadmap.md (legal-review timing trigger) + brand-book.md (voice tone for ToS) at {{out}}/. Read .claude/skills/prototype/templates/pipeline/12-legal/prompt.md + schema.md.

CONSTRAINTS:
- Standard tier: BRIEF CHECKLIST + POSTURE (4-7 KB). NOT canonical full GDPR article-grid or per-flow controller-vs-processor analysis (those are counsel work).
- TOP-OF-DOCUMENT escape clause (NOT bottom): "This is founder's posture, NOT legal advice. Counsel review required before launch."
- Sections required: Terms Model / Privacy Posture (regulation applicability checklist GDPR/LGPD/CCPA Yes/No based on audience) / Data Handling Snapshot / Licensing (product license + OSS compatibility flag) / Sub-Processor Disclosure (extracted from system-design § Integrations — count must match) / IP Assignment Posture / Open Decisions.
- Conditional sections (fire only when applicable):
  - § Regulated Aspects — fires if PRD audience touches health/minors/payment/enterprise/etc
  - § AI-Specific — fires if system-design § Integrations includes OpenAI/Anthropic/etc LLM API
  - If condition not met, OMIT entire section (do NOT emit as "N/A").

DELIVERABLE: legal-posture.md at {{out}}/legal-posture.md

DONE_WHEN: File exists; size 4-7 KB; escape clause at TOP (line 1-5); contains "Terms" + "Privacy" + "Licensing" + "Sub-Processor" + "Open Decisions" section headers; sub-processor count matches system-design integration count.
```

## Phase 4 — Synthesis

### Step 13 — Prototype v3 (screen atlas)

Two-part dispatch: atlas writer + N screen writers covering ALL US-NN from PRD.

**(a) Atlas writer — model:** `sonnet`  ·  **subagent_type:** `general-purpose`

```
TASK: Produce screen-atlas.md — navigable index + PRD coverage matrix + design-fidelity scores + states-coverage matrix + user-flow walkthrough for the complete prototype of "{{idea}}".

CONTEXT: Read ALL prior artifacts at {{out}}/: concept-brief, functional-spec, validation-report, brand-book, tokens.css, components.md, design-system.md, direction-final.html, prd.md (US-NN inventory), system-design.md, cost-estimate.md, roadmap.md, legal-posture.md. Read .claude/skills/prototype/templates/pipeline/13-prototype-v3/prompt.md + schema.md.

CONSTRAINTS:
- 8+ KB. Sections required: Overview / Screens Index (table: screen filename | US-NN covered | states | category) / PRD Coverage Matrix (every US-NN from step-08 listed: covered → screen filename; deferred → "deferred — reason") / Design Fidelity (4-dim per screen: Token Hygiene / Voice Match / Component Reuse / Brief Fit; 1-5 per dim; Min column gates ≥ 3) / States Coverage Matrix (screens × loading/empty/error/disabled/success cells: ✓/—/`[gap]`) / User Flow Walkthrough (killer flow end-to-end) / Open Decisions.
- Atlas is the INDEX — NOT a re-render of any single screen.
- PRD coverage matrix is load-bearing — silent undercoverage is the failure mode.
- Legal-mandatory surfaces (consent dialog, privacy notice, AI-disclosure badge if applicable from step-12) are NET-NEW at step 13 — step 7 typically does not render them.

DELIVERABLE: screen-atlas.md at {{out}}/screen-atlas.md

DONE_WHEN: File exists; size ≥ 8 KB; contains all 7 section headers; PRD coverage matrix lists every US-NN from prd.md (covered → screen file OR deferred → reason); design-fidelity table has 4-dim Min column.
```

**(b) Screen writer:** see § Per-stack screen-writer below. N calibrated per product class (killer-flow + 1 edge-state minimum; full PRD coverage at standard).

## Per-stack screen-writer (reused by steps 02 / 07 / 13)

Dispatched ONCE PER ROUTE, capped at 5 concurrent. Brief is templated per stack.

### Next.js stack

**model:** `sonnet`  ·  **subagent_type:** `general-purpose`

```
TASK: Write the Next.js page file for route {{path}} in the {{slug}} prototype ({{step_label}} pass).

CONTEXT:
- Pipeline step context: {{step_label}} ({{02|07|13}}). Step 02 = pre-brand v1; Step 07 = brand+tokens applied; Step 13 = full PRD-coverage with all states.
- Sitemap entry: {{route_yaml_excerpt}} (path / category / states / covers_us / components)
- Tokens (when available — step 07+): {{out}}/tokens.css (use var(--color-*) inline / Tailwind utility-classes)
- Voice (when available — step 07+): {{out}}/brand-voice.md or brand-book.md (match ON-brand voice for copy)
- Stack defaults: .claude/skills/prototype/references/stack-defaults.md § Next.js
- Target file: {{out}}/app{{path_to_file_path}}/page.tsx (root `/` → app/page.tsx)

CONSTRAINTS:
- ≤ 3 component definitions per file (extract to separate files if needed; do NOT cluster many inline).
- Implement ALL declared states from sitemap entry; for primary routes, ALWAYS implement default + loading + empty + error regardless of declaration (auto-augment).
- Token reads via var(--color-*) inline OR Tailwind utility classes that map to tokens — NO hard-coded #hex or px values (1px borders are idiomatic CSS exception).
- Mock data inline OR in {{out}}/lib/mock-data.ts.
- Soft token budget: 4000 tokens output.
- Buttons: explicit type attribute (Biome a11y).

DELIVERABLE: The page.tsx file at the target location; if mock-data.ts was added, that too.

DONE_WHEN: File exists at deliverable path; valid TypeScript (will be Phase-4-verified by tsc); declared states visibly implemented; uses tokens via var() or Tailwind utility classes (NO hex/px violations).
```

### Expo stack

Same shape as Next.js brief above, with React Native components (View / Text / Pressable / TextInput / FlatList) instead of HTML; className via NativeWind for styling (NOT StyleSheet.create); target file path is `{{out}}/app{{path}}.tsx` (Expo router file convention, no `/page.tsx` suffix).

## Concurrency cap

Phase 1 Step 02 screen writers + Phase 2 Step 07 screen writers + Phase 4 Step 13 screen writers: **MAX 5 concurrent `Agent` calls** each. If sitemap has >5 routes, queue rest and dispatch as earlier ones return.

**Cap=5 was proven non-OOM** on spec 034's 17-route dogfood (2026-05-17). Re-evaluate only if a real Phase 4 dogfood with 12+ screens surfaces context pressure.

## Failure handling

Per spec 036 Q4 resolution:

- **Step 01 BLOCKED** or **Step 13 BLOCKED** → ABORT the entire run (these are upstream-of-everything or final deliverable).
- **Any other step BLOCKED** → degrade gracefully: append `{step_label, reason, artifacts_partial}` to `.state.json.blocked_steps`; log to REPORT.md `## Blocked steps`; continue to next step. Downstream consumers note the gap in their handoff message.

Screen-writer (per-route) failures within a single step (02/07/13): mark the specific route as BLOCKED in `.state.json`; continue with remaining routes. The whole step does NOT fail on one bad screen.

## Cross-references

- `pipeline-coverage.md` — phase/step map + size targets per step
- `state-machine.md` — `.state.json` shape + gate semantics + resume support
- `quality-checklist.md` — per-step gate criteria the skill checks before declaring complete
- `SKILL.md` — orchestration body that dispatches these briefs
- `.claude/rules/delegation.md` — 5-field handoff discipline
- `templates/pipeline/<step>/prompt.md` — canonical step brief (sub-agents read this directly)
