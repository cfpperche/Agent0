# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state — spec 027 OD vendor port FULLY DRAFTED (spec + plan + tasks), user-approved, ready to implement

`docs/specs/027-od-vendor-port/{spec,plan,tasks}.md` all complete and approved. spec.md has 6 open questions; plan.md resolves all 6 in a decision table; tasks.md is 32 tasks across 6 phases + verification. Nothing implemented yet — next session starts at task 1.

### Resolved this session

- **Vendor location:** inside the package — `packages/mcp-product-pipeline/vendor/open-design/`. Ships via npm tarball. Anthill's `(a)`/`(b)`/`(c)` debate resolved to `(a)`.
- **Sync mechanism:** port anthill's `~/anthill/scripts/sync-open-design.ts` (659 LOC, 3 subcommands `--check`/`--bump`/`--apply`) into `packages/mcp-product-pipeline/scripts/sync-open-design.ts`. Runtime artifacts at `packages/mcp-product-pipeline/runtime/od-sync/`.
- **License attribution:** LICENSE + NOTICE + `.LICENSE.provenance` ship inside the vendor tree; npm package automatically distributes them.
- **Edit-block protection (user constraint 2026-05-13):** anthill's `.claude/hooks/vendor-edit-block.sh` does NOT port to Agent0's harness. Translated into a package-internal `prepublishOnly` checksum verifier. See [[feedback_mcp_package_self_contained]] — generalised rule.

### Open questions — all 6 resolved in plan.md decision table

1. `design-systems/` placement → **sibling** of `vendor/` (`packages/mcp-product-pipeline/design-systems/`).
2. DS index shape → **generate** `vendor/open-design/.cache/ds-index.json` during `--apply`.
3. `prompts/*.ts` transform → **both** — vendor the `.ts` (server imports it) + generate `.extracted.md` (agent reads it).
4. `runtime/od-sync/` → **commit** the `.md` reports, gitignore the tarball cache.
5. npm license → in-tree `LICENSE`/`NOTICE` in the vendor subtree; `package.json` `license` stays the package's own; no SPDX compound.
6. (NEW question, added this session) vendor missing at runtime → **fail loud**, no silent fallback; inline 5-school content retained in `pipeline.md` as documented manual escape.

### Key plan decision — bootstrap by COPY, not fresh extraction

Phase 3 of the plan: the initial port copies anthill's already-extracted vendor tree at pinned SHA `d25a7aaf…`, then runs `--verify`. Deterministic, offline, byte-identical to what anthill benchmarked. The `sync-open-design.ts --apply` path is built + tested but is for *future* bumps, not the initial port.

### Why this matters for spec 026 Phase B

Step 2 (shipped 2026-05-13, commits `018478f` + `f32f42a`) describes the 5 canonical visual schools inline in `references/pipeline.md`. Once spec 027 lands, step 2's `pipeline.md` simplifies to `read .vendor/open-design/skills/web-prototype/SKILL.md` and DS citation in REPORTs becomes mandatory rather than nice-to-have. Steps 5/6/7/13 (all visual-surface) inherit the same dependency.

## Next steps

1. **Implement spec 027** — work `tasks.md` top-to-bottom from task 1. Phase 1 (skeleton) → 2 (sync engine) → 3 (content bootstrap by copy) → 4 (prepublishOnly) → 5 (MCP tools) → 6 (consumer doc + step-2 retrofit) → tests → verification. Phase dependency order documented in tasks.md Notes.
2. **Commit spec 027** — `docs/specs/027-od-vendor-port/` is untracked; commit before or alongside the first implementation phase.
3. **Spec 026 Phase B step 3 (markdown spec port)** — still BACKLOGGED; pick up after spec 027 lands OR earlier if step 3 turns out not to need OD grounding (likely — step 3 output is markdown-only).

## Uncommitted changes this session

- `docs/specs/027-od-vendor-port/{spec,plan,tasks}.md` — new, all drafted + approved.
- `~/.claude/projects/-home-goat-Agent0/memory/feedback_mcp_package_self_contained.md` — new, captures the "everything in-package, no Agent0 hooks" rule (per-user memory, not git-tracked).
- `~/.claude/projects/-home-goat-Agent0/memory/MEMORY.md` — index updated with the above pointer.

No code changes to `packages/mcp-product-pipeline/` this session — spec 027 is planning only, implementation not started.

## Decisions & gotchas (cumulative)

- **MCP-package self-contained rule** (NEW 2026-05-13). New capacities for `packages/mcp-product-pipeline/` live INSIDE the package — never under Agent0's `.claude/hooks|rules|tools/`. Anthill's vendor-edit-block hook translates to a package-internal `prepublishOnly` verifier; same protection, zero coupling to the harness. Forks consuming the MCP via npm don't inherit Agent0 surface they don't own.
- **Anthill's OD vendor architecture is the canonical reference** (ADR `~/anthill/.anthill/memory/architecture/adr-vendor-open-design.md`). Commit-pinned tarball + MANIFEST.json with `pinned_sha`/`history`/`vendored_paths[]` + LICENSE/NOTICE provenance. Rejected: submodule (onboarding friction, no selective extraction), fork (maintenance burden, obscures provenance), daemon-fetch (no offline, non-determinism). We mirror the architecture; we don't redesign it.
- **Anthill archived 2026-05-13** — `.claude/memory/anthill-archived.md`. One-way port reference. Filesystem still readable at `/home/goat/anthill/`.
- **Spec 026 Phase B task 11 (step 2)** — SHIPPED + 4 iterations approved. Final form: 8 sections per direction file, 4-layer section rhythm (eyebrow + h2 + lead + body), explicit Hero/Dashboard eyebrows, charts/sparks section #6 mandatory, brief-extraction Part 1/Part 2 split. Schema floors locked. Methodology cadence established: refine → single opus Producer → user visual review → iterate.
- **Producer model choice for visual steps** — sonnet times out reading heavy templates; opus is the reliable choice (~$5/run).

## Carryover from prior session-stretches (NOT in active lane)

- Pyshrnk CLAUDE.md reconciliation — long-standing parking lot.
- Shrnk-mono harness-sync commit pending: 13 modified + 2 untracked there. Orthogonal lane.
- User-global hooks shadow project hooks — diagnostic `ls ~/.claude/hooks/` for any "capacity behaving weird" debug. See `.claude/memory/user-global-hooks-shadow.md`.
- Praxis-prototype lane (consultancy-site, separate repo): committed + deployed at https://cfpperche.github.io/praxis-prototype/. Possible refinement: bump `section-line-grid` opacity 0.045 → 0.07.
- Local HTTP server from prior session at `127.0.0.1:8765` may or may not still be running. Kill with `pkill -f "http.server 8765"` if encountered.
- Step 2 bench artifacts under `/tmp/bench/step2-*` — can be wiped when starting fresh.
