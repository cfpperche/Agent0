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

## Next step — Phase B task 12 (step 3 spec port)

Source: anthill `anthill-spec` skill. Step 3 produces the visual spec — stakeholder-readable blueprint of the prototype's pages/components/interactions. Less ambitious visually than step 2 (no HTML mood boards), more rigorous on functional/interaction surface.

**Methodology to reuse for step 3:** the iteration cadence (refine templates → single producer → user opens in browser → verdict → refine) worked well; less need for blind judge once templates exist + user is reviewing visually. Step 3 may not have a benchmark-vs-anthill phase at all since output is markdown, not HTML.

### Anchoring file paths

- spec 026 docs: `/home/goat/Agent0/docs/specs/026-mcp-pipeline-deep-port/{spec,plan,tasks}.md`
- step 2 port (just-shipped reference for shape conventions): `/home/goat/Agent0/packages/mcp-product-pipeline/src/templates/02-prototype/`
- step 1 port (reference for less visual steps): `/home/goat/Agent0/packages/mcp-product-pipeline/src/templates/01-ideation/`
- anthill source for step 3: `/home/goat/anthill/.claude/skills/anthill-spec/` (verify exact dir on first read)
- anthill output reference: `/home/goat/anthill/docs/sdlc/03-spec/<slug>-spec.md` (single file)
- step 2 bench artifacts (kept for methodology reference): `/tmp/bench/step2-*`
- OD vendor port memo: `/home/goat/Agent0/.claude/memory/od-vendor-port-plan.md`

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
