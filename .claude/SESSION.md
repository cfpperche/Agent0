# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state — spec 026 deep-port, Phase B in flight

**Phase A (plumbing extensions) shipped + validated. Phase B task 10 (step 1 ideation port) shipped + empirically validated via A/B/J benchmark + refined.**

Origin/main = local main = `099e4fb refactor(026): step 1 refinements from A/B/J benchmark insights`. 78 tests green, tsc clean, no uncommitted work in spec 026 lane.

### Phase A — DONE (commit `93ca5aa`)
- `STEPS` array 12 → 13 (step 13 prototype-v3 reserved; `GATE_AFTER` unchanged [4,7,12])
- `product_step_submit(N, content, extra_files?)` — atomic multi-file persist
- `product_step_get(N)` response gains `references` map + parsed `required_files`
- `parseRequiredFiles(schemaBody)` — JSON fenced block (`json/yaml` deviation documented inline)
- `validateLayer1` + `globToRegExp` exported for unit testing
- 47 new tests across 3 files (extra-files / required-files-schema / step13) — 78 total

### Phase B task 10 — DONE (commits `8c18b34` + `099e4fb`)
Step 1 ideation port: 1355 LOC across `prompt.md` (171) + `schema.md` (81) + 6 references (1103). Anthill source was 1509 LOC; 90% volume preserved minus anthill-specific orchestration (resumability, COMPANY.md, handoff manifest — covered by our `.state.json` + `product_advance` + `product_done`).

**A/B/J benchmark validated the thesis for step 1:**
- Output Judge C (opus, blind): Brief 1 (port) = 85, Brief 2 (anthill) = 77, +8 delta, medium-high confidence
- Process Judge P (opus, non-blind on JSONLs): Producer A = 28/30, Producer B = 29/30 (tie, low confidence)
- 0 fabricated citations on either side (19 of A, 17 of B — all WebSearch-verifiable)

Three insights from judges incorporated into step 1 refinements (commit `099e4fb`):
1. `references/examples.md` gained "Core Value = primitive, not feature list" good/bad example (anthill's "triage inbox as primitive" framing)
2. `references/checklist.md` tightened: originality "names a primitive", unit econ "math reproducible from inputs", estimate count ≥ 10 markers target
3. `prompt.md` ranking stage explicit: Feasibility axis carries fixture constraints (AI-deferred → AI-heavy concepts get downscored on Feasibility, not just Risk)

## Next step — Phase B task 11 (step 2 prototype port)

**This is the highest-priority visual step and the materialization of spec 026's central thesis** (HTML executable vs markdown spec). Source: anthill `anthill-prototype` skill = 2311 LOC total (SKILL.md 402 + references/ 1909). Output target: `02-prototype/<slug>/` containing `direction-a.html` + `direction-b.html` + `direction-c.html` + `compare.html` + `REPORT.md` (with 5-dim critique per direction) + optional `screens/` subfolder. ≥ 60 KB total artifact.

### Plan for step 2

1. **Read anthill source** at `/home/goat/anthill/.claude/skills/anthill-prototype/SKILL.md` + 6 references (`shadcn-bootstrap.md` 917 LOC alone, `full-product-blueprint.md` 274, `mobile-native-blueprint.md` 191, `od-bridge.md` 186, plus 4 smaller).

2. **Strip** anthill-specific bits during port: the `--mode=stack-native` branch (out of scope per spec 026 non-goals), `anthill-halt` / `anthill-route` references, `.anthill/runtime/` paths, prerequisite-loop language (replaced by our `product_step_get` returning prior-step artifacts).

3. **Write our `templates/02-prototype/`:**
   - `prompt.md` — html-mockup pipeline (discovery → direction picker → 3 directions HTML → REPORT.md 5-dim critique). Layer 2 schema-enforced critique sections. Layer 3 prompt instructs `surface file:// URLs + await user confirmation` before `product_advance`.
   - `schema.md` — `required_files` JSON fenced block: `direction-a/b/c.html` (min_size 8192, contains `<html` + `<style`), `compare.html` (min_size 2048), `REPORT.md` (contains "5-dimension critique" + "Recommendation").
   - `references/` — port `visual-constraints.md`, `a11y-checklist.md`, `design-fidelity-checklist.md`, `anti-patterns.md`, `examples.md`, `od-bridge.md`. Trim `shadcn-bootstrap.md` to essentials (917 LOC is heavy; goal ≤ 400 LOC after Agent0-shaping).

4. **A/B/J benchmark for step 2** (per user request to validate per step):
   - Fixture in `/tmp/bench/fixture.md` reused/adapted from step 1
   - Pre-supplied "direction decisions" (the agent can't conduct user interview)
   - Producer A reads anthill-prototype bundle; Producer B reads our port; output to `/tmp/bench/step2-A/` and `/tmp/bench/step2-B/` (now directories, not single files)
   - **Judge adaptation for visual step:** Output judge must score on HTML quality, not just markdown text. Three options: (a) score REPORT.md + sample structural metadata from HTMLs; (b) dispatch Playwright MCP sub-agent to render screenshots; (c) hybrid. **Discuss with user before dispatching** — methodology adaptation needed per spec 026 plan § Step 13 Layer 2 considerations.

5. **Refinement loop** — same shape as step 1: any insights from judges that anthill produced but our port missed → incorporate back into templates, commit, push.

### Anchoring file paths

- spec 026 docs: `/home/goat/Agent0/docs/specs/026-mcp-pipeline-deep-port/{spec,plan,tasks}.md`
- step 1 port (reference): `/home/goat/Agent0/packages/mcp-product-pipeline/src/templates/01-ideation/`
- step 2 target: `/home/goat/Agent0/packages/mcp-product-pipeline/src/templates/02-prototype/`
- anthill source for step 2: `/home/goat/anthill/.claude/skills/anthill-prototype/`
- anthill output reference (parity target ~290KB): `/home/goat/anthill/docs/sdlc/02-prototype/pivota/`
- step 1 benchmark artifacts (for reuse / methodology reference): `/tmp/bench/{scorecard,process-scorecard,fixture,brief_A,brief_B}.md`
- plumbing tests: `packages/mcp-product-pipeline/tests/{state,templates,extra-files,required-files-schema,step13}.test.ts`

### Phase B remaining tasks (tasks.md numbering)

- [x] 10 step 1 ideation
- [ ] **11 step 2 prototype** ← next
- [ ] 12 step 3 spec
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

## Decisions & gotchas

- **Benchmark methodology established (step 1 trial succeeded)**, NOT yet adapted for visual steps. Output Judge C blind + Process Judge P non-blind (path-attribution unavoidable). Use opus for judges, sonnet for producers, single trial per side unless results are ambiguous. Cost ~$2/step. Discuss visual-step adaptation BEFORE step 2 benchmark.
- **Schema fenced block deviation:** spec/plan/tasks said "YAML fenced block", implementation uses **JSON** for zero-risk parsing. JSDoc explains. Functionally equivalent; just a different surface dialect. If spec gets re-read, adjust.
- **Anthill archived 2026-05-13** — see `.claude/memory/anthill-archived.md`. No drift tracking needed; ports are one-way + final. Quality bar from anthill: equal-or-greater depth, equal artifact categories.
- **Git divergence resolved** (carryover from prior reconciliation session): parallel session's `git reset --hard` had moved my Phase A commit out of local history. Rebased parallel session's 3 commits onto Phase A via `git rebase --onto`. Tests stayed green throughout. Lesson: push early, push often during long sessions with parallel collab; `origin/main` saved the work.
- **WebFetch not used by either step 1 producer** — both relied on WebSearch result snippets. All citations were traceable (no fabrication), but worth flagging if a stricter "must fetch and read" rubric ever applies.

## Carryover from prior session-stretch (Tier 2 / dotclaude / harness-sync lane)

These are NOT in my active lane; left here so the next session sees them.

- Pyshrnk CLAUDE.md reconciliation — long-standing parking lot
- Shrnk-mono harness-sync commit pending: 13 modified + 2 untracked there, suggested message `chore(harness-sync): adopt rule-load-debug + path-scoped frontmatter`. Orthogonal lane; not Agent0 itself.
- User-global hooks shadow project hooks — diagnostic `ls ~/.claude/hooks/` for any "capacity behaving weird" debug. See `.claude/memory/user-global-hooks-shadow.md`.
