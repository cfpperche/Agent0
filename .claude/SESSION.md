# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state — spec 026 Phase B task 11 (step 2 prototype) — SHIPPED + 4 iterations approved

Step 2 port + 4 rounds of refinements applied, validated, and user-approved across iterative visual review. Final approved form: v4 templates at `packages/mcp-product-pipeline/src/templates/02-prototype/` (1220 LOC). 78 tests green, tsc clean.

**Two commits on step 2:**
- `018478f` — Initial port + A/B/J benchmark refinements v1 (4 insights from Output Judge C: pricing-tile + compare-2zone + Linear OpenType + brief-extraction preflight)
- (this session's commit) — Refinements v2-v4 from user visual review: section rhythm 4-layer + anti-slop audit table in compare + brief-extraction Part 1/Part 2 split + explicit Hero/Dashboard eyebrows + charts & sparklines section #6

### Methodology cadence established for visual steps

Each round had: refine templates → dispatch single Producer (opus, sonnet timed out on v2) → user opens in browser via local HTTP server (`python3 -m http.server 8765` on `/tmp/bench/`) → user gives verbatim verdict → I refine templates. No judge needed after the initial bench — user's eye is the rubric. v2 sonnet timed out at reads → switched to opus for v3+v4. Producer cost ~$5/run.

### 4 iteration verbatim history

- **v1 → v2:** "compare page Anti-AI-slop da versão anthill continua muito melhor temos que igualar" + "conteúdo e estrutura da página da direction da versão refinada está boa porém anthill continua superior na forma como apresenta temos a impressão que estamos em uma landing page e não apenas seções soltas". Fix: 4-layer section rhythm (eyebrow + h2 + lead + body) on sections #3-#8 + full anti-slop audit table in compare.html Zone 2 (per-cell evidence, not summary).
- **v2 → v3:** "agente não produziu uma seção hero sample nem dashboard sample" (the page-hero with hero-pill was treated as marketing hero, triage view labeled "TRIAGE VIEW" without explicit "DASHBOARD" eyebrow) + "corrigir agora nessa v3" on brief-extraction discrimination. Fix: explicit `Hero Sample` / `Dashboard Sample` eyebrow content required + brief-extraction TWO-PART table (Part 1 brief-verbatim with source quotes, Part 2 invented placeholders explicitly marked).
- **v3 → v4:** "protótipo ter nas direções uma seção dedicada gráficos/sparks o que acha?" Fix: new required section #6 between dashboard and pricing — `CHARTS & SPARKLINES` eyebrow + 4-layer rhythm + ≥ 2 SVG charts (one brief-grounded primary chart of cycle-time, one flex secondary viz of different type). Schema enforces `<svg` substring + min_size 10240. 7 → 8 required surfaces total.

### Final 8-section structure per direction file

1. Header / topnav — page chrome, anchors to all 8 sections
2. Palette strip — eyebrow `PALETTE` + 6 swatches
3. Type sample — eyebrow `TYPOGRAPHY` + H1/H2/body/mono/caption
4. Hero sample — eyebrow `HERO SAMPLE` / `HERO` / `THE HOOK` (explicit, NOT hero-pill badge)
5. Dashboard sample — eyebrow `DASHBOARD SAMPLE` / `DASHBOARD` / `TRIAGE VIEW`
6. **Charts & sparklines** — eyebrow `CHARTS & SPARKLINES` / `DATA VIZ` / `CHARTS` (mandatory brief-grounded primary chart + flex secondary)
7. Pricing tile grid — eyebrow `PRICING` (3 tiers + "Most Popular" emphasis)
8. Personality footer / DS lineage — eyebrow `DESIGN SYSTEM LINEAGE` / `INFLUENCES`

Sections #3-#8 ALL use the 4-layer rhythm (eyebrow + h2 title + lead + body).

### Schema floors final

- `direction-{a,b,c}.html`: min_size 10240, contains: `<!DOCTYPE html` / `<style` / `:root` / `--background` / `--foreground` / `--primary` / `Most Popular` / `<svg`
- `compare.html`: min_size 4096, contains: `<!DOCTYPE html` / `direction-a` / `direction-b` / `direction-c` / `Palette` / `School` / `Anti-AI-slop` / `PASS`
- `REPORT.md`: min_size 6144, contains: all 7 required section headings + 5 dim names
- `screens/[0-9][0-9]-*.html`: glob with min_count 8, per_match_min_size 4096

### Bench artifacts produced this session

All under `/tmp/bench/`:
- `step2-A/` — anthill methodology baseline (Producer A from initial bench)
- `step2-B/` — Agent0 port v0 (Producer B from initial bench, pre-refinements)
- `step2-refined/` — v1 (4 judge insights applied)
- `step2-refined-v2/` — v2 (section rhythm + audit table)
- `step2-refined-v3/` — v3 (Hero/Dashboard eyebrows + brief-extraction split)
- `step2-refined-v4/` — v4 (charts/sparks section) ← FINAL APPROVED
- `step2-fixture.md`, `step2-user-impressions.md`, `step2-scorecard.md`, `step2-judge-randomization.txt`
- `step2-1` / `step2-2` symlinks (judge blind mapping)

Screenshots at `/home/goat/Agent0/.playwright-mcp/step2-bench/step2-{1,2}-{compare,direction-a,direction-b,direction-c}.png` (8 PNGs from the initial blind judge).

Local server still running on `127.0.0.1:8765` (bash ID `b434meu0u`) serving `/tmp/bench/`. Can be killed when no longer needed.

## Next step — STUDY the OD vendor before step 3 (user decision 2026-05-13)

User pause request: "antes do step3 vamos estudar o vendor open-design do anthill, escreva o handoff pra próxima sessão fresca". Step 3 (anthill-spec port) is BACKLOGGED behind a deep-dive study of the OD vendor bundle so the port plan can be informed by actual file inventory, manifest schema, and design decisions in the upstream — not just the snapshot summary in the existing memo.

### Goal for the next fresh session

Produce an OD vendor study document that takes the open architectural questions in `.claude/memory/od-vendor-port-plan.md` § "Open architectural questions" from "5 questions to resolve when scheduled" → "5 questions with concrete proposals + recommendation per question". This isn't yet the port itself — it's the spec material that the port will draw from.

### Concrete sub-questions to answer in the study

1. **Vendor location (memo Q1):** if we ship under `packages/mcp-product-pipeline/vendor/open-design/`, what's the npm tarball impact? Does Bun's package layout permit `include` of binary assets / large markdown trees? Are there precedents in our codebase (no — pure greenfield), how do shadcn/Cline ship vendored bundles?
2. **Sync mechanism (memo Q2):** what does anthill's actual sync tool look like? Read `/home/goat/anthill/.anthill/vendor/open-design/MANIFEST.json` history entries — what triggered each "bump"? Is there a sync script in anthill (e.g., `.anthill/tools/sync-od.sh` or similar)? Should we replicate (cost vs benefit) or do manual re-vendor on bump?
3. **License attribution surface (memo Q3):** Apache-2.0 means LICENSE + NOTICE must ship with the bundle. If we go path (a) bundled-in-package, npm `files` field needs explicit inclusion. Verify the `.LICENSE.provenance` shape and where it lives relative to LICENSE.
4. **DESIGN.md selection UX (memo Q4):** propose the manifest shape — single `ds-index.json` at vendor root with `{ name, palette_summary, mood, schools[] }` per system, OR per-system `summary.md` head metadata, OR raw `ls` of `.vendor/design-systems/`. Each has tradeoffs on per-turn token cost vs flexibility. Recommend with justification.
5. **Step 2 retrofit path (memo Q5):** when OD lands, exactly what changes in our current `packages/mcp-product-pipeline/src/templates/02-prototype/`? Quantify the LOC reduction in `references/pipeline.md` (the 5 canonical schools inline → 1-line "read .vendor/open-design/prompts/directions.ts"). Make the retrofit a concrete diff target.

### Files to read deeply (priority order)

1. `/home/goat/anthill/.anthill/vendor/open-design/MANIFEST.json` — full file (only ~3 KB; we read 80 lines earlier but the `history` section continues). Look at every `event` in history to understand the sync cadence.
2. `/home/goat/anthill/.anthill/vendor/open-design/prompts/{system.ts, discovery.ts, directions.ts}` — these are the canonical Open Design prompts. What's in `system.ts` is THE foundational system prompt our future port either inlines OR reads as a vendored source. Critical to read.
3. `/home/goat/anthill/.anthill/vendor/open-design/skills/web-prototype/SKILL.md` + `assets/template.html` + `references/{layouts.md, checklist.md}` — the canonical Web Prototype skill. Step 2's prototype methodology should ideally read from this seed rather than describe the 5 schools inline.
4. `/home/goat/anthill/.anthill/vendor/open-design/skills/saas-landing/SKILL.md` — the SaaS Landing variant; may matter for step 5/8 ports later.
5. `/home/goat/anthill/.anthill/design-systems/README.md` + 3-5 sample `DESIGN.md` files (e.g., linear-app, notion, stripe) to understand the structure agents would consume from.
6. `/home/goat/anthill/.anthill/vendor/open-design/frames/{iphone-15-pro,macbook,browser-chrome}.html` — the device chrome shells; understand the API for embedding direction/screen renders inside them.
7. `/home/goat/anthill/.anthill/vendor/open-design/templates/deck-framework.html` — pitch deck template; may matter for later port steps.
8. Does anthill have a `.anthill/tools/sync-od-vendor.sh` or equivalent? `ls /home/goat/anthill/.anthill/tools/` to find out.

### Output target

Write a study document at `docs/specs/NNN-od-vendor-port/spec.md` (use `/sdd new od-vendor-port` to scaffold). The spec answers the 5 sub-questions concretely + names a recommended path. Plan.md + tasks.md follow once spec is approved.

If during the study new questions surface, update `.claude/memory/od-vendor-port-plan.md` rather than overwriting the existing memo (keep it as the durable knowledge index; spec dir is the working plan).

### What NOT to do in the next session

- Don't start the actual port (writing code, copying files). Study only.
- Don't proceed to step 3 (spec) until the OD study lands. Step 3 is paused pending the OD planning outcome — the question "should step 3 wait for OD vendor before porting" is itself one of the open questions.
- Don't modify `packages/mcp-product-pipeline/src/templates/02-prototype/` — it's user-approved final form (commits 018478f + f32f42a).

### Anchoring file paths

- OD vendor at anthill: `/home/goat/anthill/.anthill/vendor/open-design/`
- Anthill design systems (73 systems): `/home/goat/anthill/.anthill/design-systems/`
- Existing OD vendor port memo: `/home/goat/Agent0/.claude/memory/od-vendor-port-plan.md`
- spec 026 docs (parent project, pause point): `/home/goat/Agent0/docs/specs/026-mcp-pipeline-deep-port/{spec,plan,tasks}.md`
- step 2 port (just-shipped, approved): `/home/goat/Agent0/packages/mcp-product-pipeline/src/templates/02-prototype/`
- step 1 port (reference for less visual steps, will inform step 3 when it resumes): `/home/goat/Agent0/packages/mcp-product-pipeline/src/templates/01-ideation/`
- anthill source for step 3 (BACKLOGGED): `/home/goat/anthill/.claude/skills/anthill-spec/`
- step 2 bench artifacts: `/tmp/bench/step2-*`

### Carryover system state

- HTTP server running on `127.0.0.1:8765` from this session (bash ID `b434meu0u`) serving `/tmp/bench/`. Survives this session as a background process. Kill with `pkill -f "http.server 8765"` when no longer needed.
- `.playwright-mcp/step2-bench/*.png` (8 PNGs from step 2 bench) — gitignored, project-local.
- `/tmp/bench/step2-{A,B,1,2,refined,refined-v2,refined-v3,refined-v4}/` directories all preserved on disk — methodological reference, can be wiped when starting fresh.

### Phase B remaining tasks (tasks.md numbering — step 3 PAUSED)

- [x] 10 step 1 ideation
- [x] **11 step 2 prototype** ← SHIPPED (4 iterations approved)
- [ ] **OD vendor study** ← INSERTED before step 3 (user direction 2026-05-13)
- [ ] **OD vendor port** ← after study lands
- [ ] 12 step 3 spec ← BACKLOGGED behind OD study/port
- [ ] 13 step 4 ux-testing
- [ ] 14 step 5 brand
- [ ] 15 step 6 design-system (visual + tokens.css consumed by 7+13)
- [ ] 16 step 7 prototype-v2 (visual)
- [ ] 17 step 8 PRD (establish user-story ID convention)
- [ ] 18 step 9 system-design (multi-artifact)
- [ ] 19 step 10 cost-estimate
- [ ] 20 step 11 roadmap
- [ ] 21 step 12 legal
- [ ] 22 step 13 prototype-v3 (NEW; synthesis; depends on 5/6/8)

### Why pause before step 3

User intuition: each port step that touches visual surfaces (step 2 just landed, step 5 brand, step 6 design-system, step 7 prototype-v2, step 13 prototype-v3) would benefit from the OD vendor's vendored design-system library (73 DESIGN.md files) being available. Step 2 ships without OD as interim — the methodology relies on agent training-data knowledge of named systems. For steps 5/6/13 that's a weaker grounding. Better to do the OD port FIRST (or at least decide its scope), then the visual lane of step 5/6/7/13 can build on it.

Step 3 (spec — markdown-only, no visual surface) is less load-bearing on OD but pauses too — both for sequencing simplicity and because the user explicitly asked for the pause.

### Phase B remaining tasks (tasks.md numbering)

- [x] 10 step 1 ideation
- [x] **11 step 2 prototype** ← SHIPPED (4 iterations approved)
- [ ] **12 step 3 spec** ← next
- [ ] 13 step 4 ux-testing
- [ ] 14 step 5 brand
- [ ] 15 step 6 design-system (visual + tokens.css consumed by 7+13)
- [ ] 16 step 7 prototype-v2 (visual)
- [ ] 17 step 8 PRD (establish user-story ID convention)
- [ ] 18 step 9 system-design (multi-artifact)
- [ ] 19 step 10 cost-estimate
- [ ] 20 step 11 roadmap
- [ ] 21 step 12 legal
- [ ] 22 step 13 prototype-v3 (NEW; synthesis; depends on 5/6/8)

## Decisions & gotchas (cumulative)

- **Iterative visual-review cadence beats one-shot judge for visual steps.** Step 2 had an initial bench (validated direction) + 4 user-eyeballed iterations (got the spec right). For steps with markdown-only output, a single judge run suffices. For visual steps, expect 3-5 visual iterations after the initial bench.
- **Producer model choice:** sonnet for cheap producers in initial bench (~$1-2 each). For follow-up refinement runs with heavy templates (8 sections + token enrichment + chart SVG requirements), opus is more reliable (sonnet timed out reading the v2 templates). Cost ~$5/run for opus.
- **Section rhythm: 4-layer (eyebrow + h2 + lead + body) is the discipline that distinguishes "mood board" from "marketing landing page".** Without explicit eyebrows, sections feel loose. With eyebrows but no h2+lead trio, sections look templated. All 4 layers required.
- **Brief-identifier extraction must split brief-verbatim from invented-placeholder.** Conflating them (claiming "@mara.ic" was brief-sourced when brief only said "Senior IC" abstractly) misleads downstream readers and weakens REPORT.md trust. Part 1 (verbatim with source quote) + Part 2 (invented placeholder with justification) is the canonical shape.
- **Hero and Dashboard sections need EXPLICIT eyebrow labels** — not "hero-pill" badges or "TRIAGE VIEW" without "DASHBOARD". A creative eyebrow that describes content rather than section type breaks the mood-board framing.
- **Charts/sparks as a dedicated section validates data-viz tokens** that palette + type sections can't reveal. Required: ≥ 2 SVG instances per direction (one brief-grounded primary + one flex secondary). Schema enforces `<svg` substring + 10240 min_size.
- **compare.html anti-slop audit must be a per-cell evidence TABLE, not a one-line summary** — 8 rules × 3 directions grid with specific evidence in each cell. Schema enforces "Anti-AI-slop" + "PASS" substrings.
- **OD vendor port still deferred.** Step 2 ships without it; pipeline.md describes 5 canonical schools inline. See `.claude/memory/od-vendor-port-plan.md` for 5 open architectural questions to resolve when scheduling the port.
- **Benchmark methodology adapted for visual steps** (Option C hybrid established 2026-05-13): parent renders Playwright PNGs at 1440×900, Judge C opus single-turn non-blind (REPORTs leak methodology). Medium confidence verdict is the expected ceiling. Useful for initial validation, less useful for iterative refinement after that.
- **Schema fenced block deviation:** spec/plan/tasks said "YAML fenced block", implementation uses **JSON** for zero-risk parsing. JSDoc explains. Functionally equivalent.
- **Anthill archived 2026-05-13** — `.claude/memory/anthill-archived.md`. No drift tracking; ports are one-way + final. Reference baseline for "the form" we're matching.

## Carryover from prior session-stretches (NOT in active lane)

- Pyshrnk CLAUDE.md reconciliation — long-standing parking lot
- Shrnk-mono harness-sync commit pending: 13 modified + 2 untracked there, suggested message `chore(harness-sync): adopt rule-load-debug + path-scoped frontmatter`. Orthogonal lane; not Agent0 itself.
- User-global hooks shadow project hooks — diagnostic `ls ~/.claude/hooks/` for any "capacity behaving weird" debug. See `.claude/memory/user-global-hooks-shadow.md`.
- Praxis-prototype lane (consultancy-site, separate repo): committed + deployed at https://cfpperche.github.io/praxis-prototype/. Possible refinement: bump `section-line-grid` opacity 0.045 → 0.07. Orthogonal lane.
