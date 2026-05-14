# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state — spec 027 OD vendor port SHIPPED + committed (`99b3612`)

All 32 tasks done, 104 tests pass (78 existing + 26 new), `bun tsc --noEmit` clean. The Open Design vendor bundle (72 design systems + 31 skill bundles + prompts/frames/templates) now ships inside `packages/mcp-product-pipeline/`, pinned at SHA `d25a7aaf…`, checksum-verified. Committed staging only the 027 paths — spec 028's uncommitted files were left untouched.

What landed: `vendor/open-design/` skeleton + `MANIFEST.json`; `scripts/sync-open-design.ts` (bun-native port of anthill's engine, `--check`/`--bump`/`--apply`/`--verify`/`--gen-ds-index`); content bootstrapped by copy; `src/od.ts` fail-loud resolver; 2 MCP tools (`product_design_systems_index`, `product_design_system_path` → 10 tools total); `prepublishOnly` drift gate; step-2 retrofit (`od-bridge.md` + `pipeline.md`/`prompt.md`/`schema.md` route through the MCP tools, DS-by-path citation schema-enforced).

## Spec 028 sdd-refine-interview — SHIPPED + committed (`60e8a03`)

`/sdd refine` discovery-interview subcommand, ported from anthill's archived feature-refiner. All 5 tasks + 5 verifications done. New: `.claude/skills/sdd/references/{question-bank,checklist}.md`. Modified: `.claude/skills/sdd/SKILL.md` (`## Subcommand: refine` — 5-step process with 🔒/🔓/🟢 freedom annotations, 3 entry shapes, inline quality-score table) + `.claude/rules/spec-driven.md` (§ Workflow gains optional Step 0 "Refine"). Method-only port — anthill's output paths, 12-section template, ecosystem handoffs, and markdown-writer dependency not carried. Committed staging only the 028 paths; 027 + parallel lanes left untouched.

## WIP — spec 027 dogfood (resume here after session restart)

027 was dogfooded at the **surface level this session**: MCP stdio handshake + 10-tool list + both OD tools live (happy + fail-loud); template wiring (`od-bridge` surfaces in `product_step_get(2)` references); `--check` against live upstream (detected drift vs pin, wrote report, `gh api compare` worked — artifacts then reverted, dogfood-only). `runtime/od-sync/.gitignore` gained `staging-*/`.

**Pending: the full step-2 OD-grounded dogfood.** User chose "restart first" so `.mcp.json` reloads the 10-tool server and the Producer sub-agent can call the real OD tools. **Plan (resume post-restart):**
1. Reuse `/tmp/bench/step2-fixture.md` + `/tmp/bench/brief_B.md` (SwiftBoard) **verbatim** — same input as the pre-OD bench, so OD grounding is the only variable. Output → `/tmp/bench/step2-OD/`.
2. Dispatch **1 opus Producer** (5-field brief): produce 3 OD-grounded directions + `compare.html` + `REPORT.md`. CONTEXT = fixture + brief + step-2 template set (`prompt.md`/`pipeline.md`/`od-bridge.md`/`schema.md`); the Producer calls `product_design_systems_index` + `product_design_system_path` for real. CONSTRAINTS = cite ≥3 vendored `DESIGN.md` **by path**, real brief data only.
3. Verify mechanically: `validateLayer1` against `schema.md` (the new `design-systems/` contains-floor must pass); confirm real `design-systems/<x>/DESIGN.md` paths in REPORT.
4. Serve `/tmp/bench/step2-OD/` via http.server → user visual review.
5. Compare vs pre-OD baseline `/tmp/bench/step2-refined-v4/` — is the citation chain now verifiable-by-path? Are the 3 directions more distinct for being grounded in distinct vendored sources?
   - Pre-OD baseline gotcha: v4's REPORT cites design systems from **training-data recollection** ("Linear · hairline 1px · hsl(220 17% 7%)…") — the 027 wedge is replacing that with a pinned vendored `DESIGN.md` path. That contrast IS the dogfood verdict.

## Next steps (after the dogfood)

1. **Spec 026 Phase B step 3 (markdown spec port)** — BACKLOGGED, now unblocked. Step 3 output is markdown-only so it likely doesn't need OD grounding.
2. **reminder/memory cleanup** — the `od-vendor-port-plan` reminder in `.claude/REMINDERS.md` and `.claude/memory/od-vendor-port-plan.md` are now satisfied by shipped 027. Dismiss the reminder, mark the memory superseded.
3. **Future OD bump** — first real `--bump`/`--apply` against upstream is untested (network-bound). `--apply` is built + unit-covered but not run against live upstream; `--check` IS now dogfooded (upstream HEAD `75498838…` ≠ pin `d25a7aaf…`).

## Decisions & gotchas (cumulative)

- **Spec 027 deviations** (in `docs/specs/027-od-vendor-port/{plan,tasks}.md`): (a) real counts are **72 design systems / 31 skill bundles**, not the spec's 73/33 — anthill reality; (b) anthill's `MANIFEST.json` had **stale recursive-tree checksums** that didn't match its own on-disk content — recomputed the 3 tree checksums from the vendored content so `--verify` passes; (c) provenance headers reference `454e8373…` not the pin `d25a7aaf…` — anthill bumped the pin without re-applying. A future `--apply` reconciles (c).
- **`product_design_systems_index` returns `vendor_paths`** (absolute roots for skills/prompts/frames/templates) beyond the `{name,mood,palette_summary}` index — so `od-bridge.md` can teach the agent to reach SKILL.md/template.html without a per-subtree resolver tool.
- **MCP-package self-contained rule** (2026-05-13). New capacities for `packages/mcp-product-pipeline/` live INSIDE the package — never under Agent0's `.claude/`. Anthill's vendor-edit-block hook became a package-internal `prepublishOnly` verifier. See [[feedback_mcp_package_self_contained]].
- **Anthill archived 2026-05-13** — `.claude/memory/anthill-archived.md`. One-way port reference; filesystem readable at `/home/goat/anthill/`.
- **Spec 026 Phase B task 11 (step 2)** — SHIPPED + 4 iterations. 8 sections per direction file, 4-layer section rhythm, charts/sparks section mandatory, brief-extraction Part 1/Part 2 split. Methodology: refine → single opus Producer → user visual review → iterate.
- **Producer model for visual steps** — sonnet times out on heavy templates; opus is the reliable choice (~$5/run).

## Carryover from prior session-stretches (NOT in active lane)

- Pyshrnk CLAUDE.md reconciliation — long-standing parking lot.
- Shrnk-mono harness-sync commit pending: 13 modified + 2 untracked there. Orthogonal lane.
- User-global hooks shadow project hooks — diagnostic `ls ~/.claude/hooks/` for any "capacity behaving weird" debug. See `.claude/memory/user-global-hooks-shadow.md`.
- Praxis-prototype lane (consultancy-site, separate repo): deployed at https://cfpperche.github.io/praxis-prototype/. Possible refinement: bump `section-line-grid` opacity 0.045 → 0.07.
- Local HTTP server from prior session at `127.0.0.1:8765` may still be running. Kill with `pkill -f "http.server 8765"`.
- Step 2 bench artifacts under `/tmp/bench/step2-*` — wipe-able.
