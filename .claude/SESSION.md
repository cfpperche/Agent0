# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state — spec 026 Phase B task 11 (step 2 prototype) — SHIPPED + benchmark validated + refined

This session ported step 2 (prototype) end-to-end: read anthill source, scoped + decided architecture, wrote 9 template files (1098 LOC), ran A/B/J benchmark (port wins 31/28 over anthill baseline, Δ=+3, medium confidence), applied 4 refinement insights from judge (1141 LOC final). 78 tests green throughout, tsc clean. Bundled commit: templates + benchmark refinements in one commit per user direction.

### Phase B task 11 — DONE (single bundled commit + this session handoff)

**Step 2 port produces** 5 root files + 8 hi-fi screens (Turn 2):
- `direction-a/b/c.html` (≥8 KB each, all 7 required surfaces: header / palette strip / type sample / hero / dashboard sample / **pricing tile grid** / personality footer-DS-lineage)
- `compare.html` (≥4 KB, 2-zone: 3-column at-a-glance hero + deeper property table)
- `REPORT.md` (≥6 KB, all required sections + 5-dim crit + anti-slop audit + brief compliance + Turn 2 plan)
- `screens/<NN-name>.html` × 8 (≥4 KB each, Turn 2 after user direction pick)

**Bundle stats:** 1141 LOC across 9 files. Anthill html-mockup-relevant source was ~1100 LOC → ~104% volume (depth justified by 4 refinements). Stripped: full-product-blueprint, mobile-native-blueprint, shadcn-bootstrap (all stack-native, out of scope).

### A/B/J benchmark — DONE (Option C hybrid, parent-rendered Playwright)

Setup: brief_B.md as shared input, fixture pre-answered SwiftBoard Linear-clone direction, both producers sonnet/≤60min/web-search-allowed, parent rendered 8 PNGs at 1440×900 via Playwright MCP, Judge C opus single-turn non-blind (REPORTs leak methodology).

**Verdict (Judge C):** step2-1 (Agent0 port) **31/35** vs step2-2 (anthill) **28/35**, Δ=+3, medium confidence.

Dimension breakdown:
- TIE: D1 Visual execution, D2 Direction distinctness, D3 Authorial voice
- Anthill wins: D4 Page structure (pricing-tile-UI as dedicated surface per direction)
- Port wins: D5 REPORT substance (deeper citations + score-gap mitigation prose), D6 compare.html shape (3-column at-a-glance), D7 Brief fidelity (verbatim identifiers vs plausible substitutes)

**User visual analysis (2026-05-13, before judge):** "estrutura do compare A venceu, B parece mais autoral... qualidade gráfica de A venceu porém criou-se landing pages, estrutura das páginas de B foi mais completa... ideal é mix". Saved at `/tmp/bench/step2-user-impressions.md` (pre-judge, uncontaminated).

User re-review after judge: "D4 — A vence no geral porém B tem coisas indispensáveis (Hero/Dashboard/DS Lineage). D6 — A vence com certeza, página completa só perde na forma de apresentar lado a lado onde B é superior."

### 4 refinements applied to templates

1. **Pricing-tile UI as required surface** (insight from judge D4 + user re-review) — prompt.md § 4 list now has 7 required sections (was 6); section #6 is "Pricing tile grid (3 tiers, Most Popular emphasis)". schema.md adds "Most Popular" to direction-{a,b,c} contains check. pipeline.md build phase rules add #3.
2. **compare.html 2-zone shape** (insight from judge D6 + user "A's complete page + B's at-a-glance form") — prompt.md § 5 rewrites compare requirement: Zone 1 (3-column at-a-glance hero visible at 1440×900) + Zone 2 (property table below). schema.md adds "Palette" + "School" + bumps min_size 2 KB → 4 KB.
3. **Linear OpenType cv01/ss03** (insight from judge D3) — pipeline.md § "5 canonical schools" table gains "School-specific tells" column; modern-minimal row carries `font-feature-settings: "cv01", "ss03"` for Linear-anchored direction. Build phase rule #4 enforces.
4. **Brief-extraction preflight table** (insight from judge D7) — prompt.md § 1 expanded: agent MUST pin a brief-identifier extraction table in chat BEFORE writing HTML, enumerating product name, issue ID prefix, persona slugs, sprint label, north-star metric, pricing tier values. Refuses to substitute plausible variants.

### OD vendor port plan registered as deferred architectural commitment

Memory at `.claude/memory/od-vendor-port-plan.md`. Anthill's OD vendor bundle (3.1 MB, Apache-2.0, 73 design systems + 33 skill bundles + prompts + frames at github.com/nexu-io/open-design) proved high-value in pivota (DS citation chain in REPORT). Memo captures 5 open architectural questions (vendor location, sync, license, DESIGN.md UX, step 2 interim gap). Step 2 port ships WITHOUT OD vendor; `pipeline.md` describes 5 canonical schools inline + leans on agent's training-data knowledge of named DS. When OD ports, pipeline.md simplifies + DESIGN.md citation becomes mandatory. Reminder added to `.claude/REMINDERS.md`.

## Next step — Phase B task 12 (step 3 spec port)

Source: anthill `anthill-spec` skill. Step 3 produces the visual spec — a stakeholder-readable blueprint of the prototype's pages/components/interactions. Less ambitious visually than step 2 (no HTML mood boards), more rigorous on functional/interaction surface.

### Anchoring file paths

- spec 026 docs: `/home/goat/Agent0/docs/specs/026-mcp-pipeline-deep-port/{spec,plan,tasks}.md`
- step 2 port (just-shipped reference): `/home/goat/Agent0/packages/mcp-product-pipeline/src/templates/02-prototype/`
- anthill source for step 3: `/home/goat/anthill/.claude/skills/anthill-spec/` (verify exact dir name on first read)
- anthill output reference: `/home/goat/anthill/docs/sdlc/03-spec/<slug>-spec.md` (single file, not directory)
- step 2 benchmark artifacts (reuse methodology): `/tmp/bench/step2-{fixture,scorecard,user-impressions}.md` + `/tmp/bench/step2-{1,2}/` + `/home/goat/Agent0/.playwright-mcp/step2-bench/*.png`
- OD vendor port memo: `/home/goat/Agent0/.claude/memory/od-vendor-port-plan.md`

### Phase B remaining tasks (tasks.md numbering)

- [x] 10 step 1 ideation
- [x] **11 step 2 prototype** ← JUST SHIPPED
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

- **Benchmark methodology adapted for visual steps** (2026-05-13 step 2 trial succeeded): Option C hybrid — parent renders Playwright PNGs at 1440×900 desktop, Judge C opus single-turn non-blind (because REPORTs self-describe methodology — different from step 1 where briefs didn't). Worked well; medium-confidence verdict is the expected ceiling for non-blind output judging. Cost ~$5.
- **Step 2 is the only multi-turn step** — Turn 1 (3 directions + compare + REPORT) gates a Layer 3 user-direction pick, then Turn 2 (8 hi-fi screens) generates. Other steps are single-turn. Layer 3 checkpoint mechanic established here may inform step 7 (prototype-v2) future port.
- **Pricing-tile-UI is a Turn 1 mood-board surface, not a Turn 2 detail.** This was the judge insight that surprised: pricing as PRODUCT UI in the direction file gives founders a second product surface (beyond dashboard) for direction comparison. Embedded into prompt.md § 4 as required.
- **Brief-extraction table is the discipline that separates brief-grounded mockups from plausible-but-substituted ones.** Step 2's biggest factor on D7 (port won 5/5 vs anthill 4/5) was using "@mara.ic" verbatim instead of "Maya Chen" plausible. The new prompt.md § 1 extraction table enforces this for all future steps generating HTML.
- **OD vendor is a real architectural commitment.** Step 2 ships without it as interim — pipeline.md describes 5 canonical schools inline. When OD ports, pipeline.md shrinks + DESIGN.md citation becomes mandatory. See `.claude/memory/od-vendor-port-plan.md` for 5 open questions.
- **Benchmark methodology established (step 1 + step 2 trials succeeded)** — Output Judge C blind on step 1 (briefs don't self-describe), non-blind on step 2 (REPORTs do). Both reached medium-high confidence verdict. Use opus for judges, sonnet for producers, single trial per side unless ambiguous. Cost ~$2-5/step.
- **Schema fenced block deviation:** spec/plan/tasks said "YAML fenced block", implementation uses **JSON** for zero-risk parsing. JSDoc explains. Functionally equivalent.
- **Anthill archived 2026-05-13** — `.claude/memory/anthill-archived.md`. No drift tracking; ports are one-way + final.
- **`required_glob` is fully supported by the schema parser** (`pattern` + `min_count` + `per_match_min_size` + `per_match_contains`) — used for the screens/ subfolder; useful pattern for future multi-artifact steps.

## Carryover from prior session-stretches (NOT in active lane)

- Pyshrnk CLAUDE.md reconciliation — long-standing parking lot
- Shrnk-mono harness-sync commit pending: 13 modified + 2 untracked there, suggested message `chore(harness-sync): adopt rule-load-debug + path-scoped frontmatter`. Orthogonal lane; not Agent0 itself.
- User-global hooks shadow project hooks — diagnostic `ls ~/.claude/hooks/` for any "capacity behaving weird" debug. See `.claude/memory/user-global-hooks-shadow.md`.
- Praxis-prototype lane (consultancy-site, separate repo): committed + deployed at https://cfpperche.github.io/praxis-prototype/. Possible refinement: bump `section-line-grid` opacity 0.045 → 0.07. Orthogonal lane.
