# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state — spec 026 Phase B tasks 12+13 SHIPPED + COMMITTED · 4 dogfood-driven prompt corrections (Gaps A/B/C/D) SHIPPED + COMMITTED in `4522eb3`. Working tree clean.

Specs 027 + 028 shipped earlier. **Task 12** (step 3 spec port) committed `4050de9`. **Task 13** (step 4 ux-testing port — `anthill-ux-audit` Nielsen-10 + WCAG-2.1-AA as always-on expert-audit spine; Agent0's `validation_mode` 3-mode posture preserved as user-level layer on top; Layer 1 enforces `validation_mode:` line presence) + **Gaps A/B/C/D corrections** committed `4522eb3`.

**The 4 Gaps closed this session** (canonical examples for the durable port-audit pattern — see [[feedback_anthill_port_smart_not_rigid]]):

- **Gap A (step 3)** — `03-spec/prompt.md` § "Pages & Surfaces" gained a "Scale depth to surface importance" paragraph licensing tiered depth (full on killer-flow surfaces, compact on trivial micro-pages). Schema enforces presence, not parity.
- **Gap B (step 4)** — `04-ux-testing/prompt.md` § "Accessibility review" split into HTML-measurable vs. spec-projected branches; projected case phrases each `warn` as a tracked step-6/7 handoff. Closes the auditing-a-spec-as-if-it-were-HTML false-confidence failure.
- **Gap C (step 2)** — `02-prototype/prompt.md` gained new § 3.5 "Fan-out" prescribing 3-parallel sub-agents with pre-attributed angles, replacing the implicit single-Producer pattern that empirically converges directions (spec 027 dogfood's "2 of 3 dark-canvas"). Pattern empirically validated this session at two scales: Turn 1 (3 sub-agents · categorical angles · Cool Brutalist / Warm Humanist / Editorial Minimalist · zero convergence) and Turn 2 (8 sub-agents · same tokens · 8 distinct product surfaces · full ~370 KB bundle passes Layer 1).
- **Gap D (step 2)** — Turn-2 screen count was hardcoded `8` in 8 places. Now product-calibrated: schema floor `min_count: 3` (universal sanity), prompt § 9 rewritten with calibration table (Scale → N: Micro 3-5 / Mobile 4-7 / Dev Tool 4-8 / SMB SaaS 6-10 / Venture 10-15) + 5-step derivation procedure + 2 contrasting example lists. Section heading `## Turn 2 — Hi-Fi Screens` count-agnostic; slug accepts both new and legacy for backwards-compat. **Caught by user reading the pipeline critically, not by dogfood execution** — durable meta-finding: audit every magic constant in every future port.

**Durable behavioral memory captured** — `~/.claude/projects/-home-goat-Agent0/memory/feedback_anthill_port_smart_not_rigid.md` codifies the 4-smell port-audit pattern (magic numbers / single-orchestrator / undynamic defaults / one-mode-templates) with the canonical Gap C/D examples + how-to-apply checklist + Phase B future audit targets (steps 6/7/9/13). MEMORY.md index updated.

**Dogfood artifacts live + reusable next session:**
- `/tmp/bench/026-task12-13/` — step 3 + step 4 artifacts from the initial dogfood (pre-Gap-fix)
- `/tmp/bench/026-dogfood-step2/` — full step-2 bundle for Linear-Clone in **Cool Brutalist** direction: 3 mood-boards + compare.html + REPORT.md + 8 hi-fi screens (Turn 2) · ~370 KB · all gates pass
- HTTP server still up at `http://127.0.0.1:8765/` (kill: `pkill -f "http.server 8765"`)

## Next steps

1. **Re-dogfood step 3 + step 4 against the Cool Brutalist HTML bundle** (THIS is the immediate next work — validates the 4 Gap fixes under correct conditions). Step 3: decompose the 12 Linear-Clone surfaces using 8 real HTML screens + 4 spec-projected (stress-tests Gap A tiered-depth license). Step 4: open each of the 8 screens in a browser, measure contrast, observe focus, tabulate semantics — full *measurable* WCAG audit (stress-tests Gap B HTML-mode branch). Recommend sequential — step 4 benefits from step-3's fresh decomposition as context.
2. **Spec 026 Phase B — remaining steps** (tasks 14-22): step 5 brand, 6 design-system (HIGH PRIORITY — tokens feed 7+13), 7 prototype-v2, 8 PRD, 9 system-design, 10 cost, 11 roadmap, 12 legal, 13 prototype-v3 NEW. **Apply the [[feedback_anthill_port_smart_not_rigid]] audit pattern to each port** — read the anthill source end-to-end first, list every magic number + default + always-X, propose calibration improvements BEFORE drafting, dogfood inline against linear-clone-poc, apply corrections same-session.
3. **Fair OD re-match** (optional) — see `.claude/memory/od-grounding-dogfood.md` § Pointers + reminder list.
4. **Future OD bump** — first real `--bump`/`--apply` against upstream still untested (network-bound). See reminder list.

Verified: `bun tsc --noEmit` clean throughout, 109 tests pass, `getTemplate(2|3|4)` parse with the edited prompts.

## Next steps

1. **User reviews `/tmp/bench/026-dogfood-step2/compare.html`** and picks/iterates/rejects the 3 directions. After lock-in, re-dogfood step 3 + step 4 against real HTML.
2. **Commit task 13 + dogfood corrections** — uncommitted: 7 task-13 paths + the 3 dogfood-correction edits to `02-prototype/prompt.md`, `03-spec/prompt.md`, `04-ux-testing/prompt.md` + `docs/specs/026-mcp-pipeline-deep-port/tasks.md` + `.claude/SESSION.md`. Single thematic commit per the established session rhythm. On `main`.
3. **Spec 026 Phase B — remaining steps** (tasks 14-22): step 5 brand, 6 design-system (HIGH PRIORITY — tokens feed 7+13), 7 prototype-v2, 8 PRD, 9 system-design, 10 cost, 11 roadmap, 12 legal, 13 prototype-v3 NEW. Anthill sources at `/home/goat/anthill/.claude/skills/anthill-*`. **Apply the dogfood pattern to each new port** — produce real artifact against linear-clone, surface gaps, fix prompts inline.
4. **Fair OD re-match** (optional) — see `.claude/memory/od-grounding-dogfood.md` § Pointers + reminder list.
5. **Future OD bump** — first real `--bump`/`--apply` against upstream still untested (network-bound). See reminder list.

## Decisions & gotchas (cumulative)

- **Port-task pattern (tasks 12, 13)** — each anthill→template port: rewrite `prompt.md` + `schema.md`, ship a `references/` dir (5 files: a content template + a domain rubric/shape + anti-patterns + checklist + examples — mirrors the 01-ideation port). Always re-verify with `bun tsc --noEmit` + `bun test` + a `getTemplate(N)` / `validateLayer1` smoke test before checking the task box. **Then dogfood pointedly against linear-clone-poc** — produce real artifacts in `/tmp/bench/`, validate against the real `validateLayer1`, surface guidance gaps the schema can't catch, and fix the prompts inline in the same session. This pattern surfaced Gaps A/B/C in this session.
- **Step-2 fan-out pattern (dogfood-validated)** — the empirically-correct orchestration of step 2's Turn 1 is: parent runs discovery + attributes 3 categorically distinct angles, dispatches 3 sub-agents in parallel (one direction each, `model: opus`, angle locked in CONSTRAINTS, same-response dispatch), parent does cross-cutting (compare.html + REPORT.md) once they return. The single-Producer pattern converges directions on a single aesthetic axis ("2 of 3 dark-canvas" — spec 027 dogfood). Fan-out makes that structurally impossible. Now prescribed in `02-prototype/prompt.md` § 3.5.
- **Disclose partial-DS-fits + brief-specified accents** — emergent positive property from this session's fan-out dogfood. Sub-agents grading their own DS-catalogue fit *honestly* admit when a citation is partial (Warp listed but only its terminal-block layout DNA borrowed; warm parchment palette swapped) or when an accent was brief-specified rather than DS-inherited (oxblood from the brief, not from any DS). Promoted to explicit rule in `02-prototype/prompt.md` § 3.5 CONSTRAINTS — both the HTML's lineage section AND the sub-agent's DELIVERABLE message must disclose.
- **Audit hardcoded numbers in each ported template (Gap D pattern)** — Gap D's lesson: every magic constant in a deep-ported prompt deserves the question "is this calibrated to anything?". The "8 screens" came from anthill / spec-026-plan convention, not empirical derivation; it over-prescribed for micro-products and under-served venture-scale. Fix shape: schema floor at universal sanity (low number); prompt teaches calibration with a class-mapping table + derivation procedure. Apply this pattern when porting steps 6 (design-system token counts? color stops?), 7 (screen count again?), 9 (sections? threat-model items?), 13 (screen-atlas count). Audit BEFORE shipping each port — the user catches what the dogfood-execution misses, and post-ship corrections are noisier than pre-ship calibration.
- **Task 13 reframe** — the step-4 heuristic audit runs for *every* validation mode, including `not-applicable` (CLI/API products get heuristics adapted to terminal UX). `not-applicable` is no longer "skip the audit"; it only means *user-level* validation doesn't fit the product class.
- **Task 12 step-3/step-9 boundary** — step 3's `architecture.md` is the *preliminary* skeleton (module decomposition / data model / key flows / integration points, names not technologies); step 9 (system-design) deepens it. The `## Open Architecture Questions` section is the explicit step-9 handoff. Architecture artifacts are *derived from* `functional-spec.md` (derivation chain, not parallel authoring).
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
