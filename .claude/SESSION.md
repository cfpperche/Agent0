# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state — spec 026 Phase B task 12 (step 3 spec port) SHIPPED, UNCOMMITTED

Specs 027 (OD vendor port + `PRODUCT_PIPELINE_OD` toggle) and 028 (`/sdd refine`) are both shipped + committed — 027's toggle landed in `12dd6e4` (the prior session's "commit the toggle" next-step is done). Working tree was clean at session start.

This session shipped **spec 026 Phase B task 12 — step 3 spec port** (`anthill-spec` + `anthill-feature-refiner` → `templates/03-spec/`). UNCOMMITTED, 7 files:

- `templates/03-spec/prompt.md` — rewritten. Synthesis of `anthill-spec` (pages→components→interactions→states→nav-map + `## Decisions Pending` handoff table) and `anthill-feature-refiner` (per-feature depth + architecture section + Gherkin acceptance scenarios). `mode: synthesis`, `delegable: true`.
- `templates/03-spec/schema.md` — rewritten. `required_files` block: 3-artifact bundle — `functional-spec.md` (≥15 KB, primary `content`) + `architecture.md` (≥4 KB, extra_file) + one of `architecture.html`/`.json` (extra_file, via `required_glob`). 9 required H2 sections for `functional-spec.md`.
- `templates/03-spec/references/` — 5 new files: `functional-spec-template.md`, `architecture-shape.md`, `anti-patterns.md`, `checklist.md`, `examples.md`. (Plan named only the first two; added the other 3 to match the 01-ideation port shape.)

Verified: `bun tsc --noEmit` clean, 109 tests pass, `getTemplate(3)` + `validateLayer1` smoke-tested (valid bundle / json variant / missing-diagram / undersized-spec all behave correctly).

Also this session: `.claude/REMINDERS.md` — dismissed the satisfied `od-vendor-port-plan` reminder, added 2 (fair OD re-match; first real OD `--bump/--apply`). `docs/specs/026-*/tasks.md` — task 12 checked + Notes filled. Both UNCOMMITTED.

## Next steps

1. **Commit task 12 + reminders** — user was asked "quer que eu commite?" at session end; answer pending. If yes, stage the 7 task-12 paths + `.claude/REMINDERS.md` + `docs/specs/026-mcp-pipeline-deep-port/tasks.md`. On `main` — branch-first rule applies unless user says otherwise.
2. **Spec 026 Phase B — remaining steps** (tasks 13-22): step 4 ux-testing, 5 brand, 6 design-system (HIGH PRIORITY — tokens feed 7+13), 7 prototype-v2, 8 PRD, 9 system-design, 10 cost, 11 roadmap, 12 legal, 13 prototype-v3 NEW. Then Phase C (docs) + Phase D (end-to-end dogfood). Anthill sources at `/home/goat/anthill/.claude/skills/anthill-*`.
3. **Fair OD re-match** (optional) — the spec-027 blind-judge result was confounded. See `.claude/memory/od-grounding-dogfood.md` § Pointers + reminder list.
4. **Future OD bump** — first real `--bump`/`--apply` against upstream still untested (network-bound). See reminder list.

## Decisions & gotchas (cumulative)

- **Task 12 step-3/step-9 boundary** — step 3's `architecture.md` is the *preliminary* skeleton (module decomposition / data model / key flows / integration points, names not technologies); step 9 (system-design) deepens it. The `## Open Architecture Questions` section in `architecture.md` is the explicit step-9 handoff. Boundary tabled in `references/architecture-shape.md` + the prompt's "What this step does NOT do". Architecture artifacts are *derived from* `functional-spec.md` (derivation chain, not parallel authoring).
- **`required_glob` "one of" gotcha** — to express "one of `architecture.html`/`.json`", use `architecture.[hj][a-z]*`, NOT `architecture.[hj]*`. `globToRegExp` treats a `*` immediately after `]` as a char-class quantifier (the `[0-9]+` feature), so `[hj]*` compiles to `[hj]*` (zero+ of h/j) — matches nothing useful. The trailing `[a-z]*` is the actual wildcard. Documented inline in `schema.md`.
- **`extractRequiredSections` is greedy** — it treats ANY schema.md line of shape `- <lowercase-kebab-token>` as a required section. When authoring a schema.md, keep non-required bullets multi-word or `**bold**`-prefixed so they don't get picked up. (The pre-port 03-spec schema.md had a latent bug here — bare `- data-model` etc. under "Recommended" were silently required; the rewrite fixed it.)
- **Spec 026 Phase B task 11 (step 2)** — SHIPPED + 4 iterations (8 sections/direction, 4-layer rhythm, charts/sparks mandatory, brief-extraction Part1/Part2 split). Methodology: refine → single opus Producer → user visual review → iterate. Note: tasks.md checkbox for task 11 is still `[ ]` (stale) — full closure arguably Phase-D-gated like the other visual steps.
- **MCP-package self-contained rule** (2026-05-13) — new capacities for `packages/mcp-product-pipeline/` live INSIDE the package, never under Agent0's `.claude/`. See [[feedback_mcp_package_self_contained]].
- **Anthill archived 2026-05-13** — `.claude/memory/anthill-archived.md`. One-way port reference; filesystem readable at `/home/goat/anthill/`.
- **Producer model for visual steps** — sonnet times out on heavy templates; opus is the reliable choice (~$5/run).
- **Spec 027 deviations** (in `docs/specs/027-od-vendor-port/{plan,tasks}.md`): real counts 72 DS / 31 skill bundles (not 73/33); anthill `MANIFEST.json` had stale tree checksums (recomputed); provenance headers reference `454e8373…` not pin `d25a7aaf…` — a future `--apply` reconciles.

## Carryover from prior session-stretches (NOT in active lane)

- Pyshrnk CLAUDE.md reconciliation — long-standing parking lot.
- Shrnk-mono harness-sync commit pending: 13 modified + 2 untracked there. Orthogonal lane.
- User-global hooks shadow project hooks — diagnostic `ls ~/.claude/hooks/` for any "capacity behaving weird" debug. See `.claude/memory/user-global-hooks-shadow.md`.
- Praxis-prototype lane (consultancy-site, separate repo): deployed at https://cfpperche.github.io/praxis-prototype/. Possible refinement: bump `section-line-grid` opacity 0.045 → 0.07.
- Local HTTP server from prior session at `127.0.0.1:8765` may still be running. Kill with `pkill -f "http.server 8765"`.
- Step 2 bench artifacts under `/tmp/bench/step2-*` — wipe-able.
