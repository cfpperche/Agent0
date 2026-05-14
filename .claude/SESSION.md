# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state — spec 027 OD vendor port SHIPPED + committed (`99b3612`)

All 32 tasks done, 104 tests pass (78 existing + 26 new), `bun tsc --noEmit` clean. The Open Design vendor bundle (72 design systems + 31 skill bundles + prompts/frames/templates) now ships inside `packages/mcp-product-pipeline/`, pinned at SHA `d25a7aaf…`, checksum-verified. Committed staging only the 027 paths — spec 028's uncommitted files were left untouched.

What landed: `vendor/open-design/` skeleton + `MANIFEST.json`; `scripts/sync-open-design.ts` (bun-native port of anthill's engine, `--check`/`--bump`/`--apply`/`--verify`/`--gen-ds-index`); content bootstrapped by copy; `src/od.ts` fail-loud resolver; 2 MCP tools (`product_design_systems_index`, `product_design_system_path` → 10 tools total); `prepublishOnly` drift gate; step-2 retrofit (`od-bridge.md` + `pipeline.md`/`prompt.md`/`schema.md` route through the MCP tools, DS-by-path citation schema-enforced).

## Spec 028 sdd-refine-interview — SHIPPED + committed (`60e8a03`)

`/sdd refine` discovery-interview subcommand, ported from anthill's archived feature-refiner. All 5 tasks + 5 verifications done. New: `.claude/skills/sdd/references/{question-bank,checklist}.md`. Modified: `.claude/skills/sdd/SKILL.md` (`## Subcommand: refine` — 5-step process with 🔒/🔓/🟢 freedom annotations, 3 entry shapes, inline quality-score table) + `.claude/rules/spec-driven.md` (§ Workflow gains optional Step 0 "Refine"). Method-only port — anthill's output paths, 12-section template, ecosystem handoffs, and markdown-writer dependency not carried. Committed staging only the 028 paths; 027 + parallel lanes left untouched.

## Spec 027 dogfood — DONE; `PRODUCT_PIPELINE_OD` toggle added (UNCOMMITTED)

The full step-2 OD-grounded dogfood ran this session. Findings + the durable nugget are in `.claude/memory/od-grounding-dogfood.md`. Short version: 027 is mechanically sound (citation-by-path real, `validateLayer1` passes, MCP tools live over stdio); a blind opus judge scored the single-pass OD run 3.87 vs the 4×-refined pre-OD baseline 4.73 — **but that's confounded** (1 pass vs 4 iterations), do NOT read it as "OD is worse". Confound-independent findings: grounding ≠ visual quality (iteration-bound); the Producer clustered 2 of 3 directions on dark-canvas composites despite the fixture asking for contrast (possible `od-bridge.md`/`prompt.md` guidance gap); a first-pass `--primary`==`--accent` token bug.

**Follow-up shipped this session — `PRODUCT_PIPELINE_OD` on/off toggle (UNCOMMITTED, 12 files + 1 new):** env var on the MCP server; off-values `off`/`0`/`false`/`no`/`disabled` make the OD tools return `code: "od-disabled"` (via `OdDisabledError extends VendorMissingError`), routing step 2 to the pre-OD "Manual escape" path. Touches `src/od.ts`, `src/tools.ts` (descriptions only), 4 step-2 templates, `.mcp.json.example`, `README.md`, `tests/od.test.ts` (+5 tests → 109 pass), `docs/specs/027-od-vendor-port/{plan,tasks}.md` (§ Follow-up / Phase 7), `.claude/memory/{MEMORY.md,od-grounding-dogfood.md}`. `bun tsc --noEmit` clean. **Not committed — user was asked, answer pending.**

## Next steps

1. **Commit the toggle work** — user was asked "quer que eu commite?" at session end; if yes, stage the 13 paths (all 027-related: `packages/mcp-product-pipeline/`, `docs/specs/027-od-vendor-port/`, `.mcp.json.example`, `.claude/memory/`) and commit. On `main` — branch-first rule applies unless user says otherwise.
2. **Fair OD re-match** (optional) — the blind-judge result was confounded. To measure 027 honestly: either iterate the OD run to 4 passes, or re-judge it against the *first-pass* baseline (not `refined-v4`). See `.claude/memory/od-grounding-dogfood.md` § Pointers.
3. **Spec 026 Phase B step 3 (markdown spec port)** — BACKLOGGED, unblocked. Markdown-only output, likely doesn't need OD grounding.
4. **reminder cleanup** — the `od-vendor-port-plan` reminder in `.claude/REMINDERS.md` is satisfied by shipped 027; `.claude/memory/od-vendor-port-plan.md` already marked SUPERSEDED in the MEMORY.md index. Dismiss the reminder.
5. **Future OD bump** — first real `--bump`/`--apply` against upstream still untested (network-bound); `--check` IS dogfooded (upstream HEAD `75498838…` ≠ pin `d25a7aaf…`).

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
