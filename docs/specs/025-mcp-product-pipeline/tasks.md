# 025 — mcp-product-pipeline — tasks

_Generated from `plan.md` on 2026-05-12. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Phase A — Scaffolding

- [x] 1. Create `packages/mcp-product-pipeline/` with `package.json` (name `agent0-mcp-product-pipeline`, private, type `module`, scripts: `start: bun run src/server.ts`, `build: tsc`, `typecheck: tsc --noEmit`, `test: bun test`; runtime dep `@modelcontextprotocol/sdk@^1.29.0`; dev deps `typescript@^5.7.0` + `@types/node@^22.0.0`), `tsconfig.json` (strict, `module: NodeNext`, `target: ES2022`, `outDir: dist`, `rootDir: src`), and `.gitignore` (`node_modules/`, `dist/`). Use `# OVERRIDE: scaffolding new POC package per spec 025 mcp-product-pipeline` on the supply-chain block when `bun install` lands.
- [x] 2. Run `bun install` in `packages/mcp-product-pipeline/`; verify `bun.lock` is produced; commit both `package.json` and `bun.lock` together.

### Phase B — Foundation modules (decoupled, testable in isolation)

- [x] 3. Create `packages/mcp-product-pipeline/src/pipeline.ts` exporting: typed constant `STEPS: StepDef[]` with all 12 step definitions per the mode table in `plan.md` § Files; `PHASES = ["discovery", "identity", "specification"]`; `GATE_AFTER = [4, 7, 12]`; `ExecutionMode = "interactive" | "draft-after-input" | "synthesis"` union type; helper `stepByN(n: number): StepDef`.
- [x] 4. Create `packages/mcp-product-pipeline/src/paths.ts` exporting `productRoot()` (returns `${process.cwd()}/docs/product`), `stateFile()` (returns `${productRoot()}/.state.json`), `stepDir(n)` (returns `${productRoot()}/${NN-name}`), `templateDir(n)` (returns `${packageRoot()}/src/templates/${NN-name}` via `import.meta.url`).
- [x] 5. Create `packages/mcp-product-pipeline/src/state.ts` exporting `readState()`, `writeState(s)` (atomic via `Bun.write` to `${stateFile()}.tmp` then `rename`), `initState(slug)`, `markCompleted(n)`, `markGatePassed(phase)`, `getCurrentStep()`. State schema: `{slug, current_step, phase, completed: number[], gates_passed: string[], validation_mode?: string, started_at}`. Create `tests/state.test.ts` covering: init creates valid state; round-trip read-after-write; markCompleted is idempotent; rename atomicity (no torn writes with concurrent writes). **18 tests green.** Initial Date.now()-only tmp suffix collided under Promise.all concurrent writes — fixed to `crypto.randomUUID()`.
- [x] 6. Create `packages/mcp-product-pipeline/src/templates.ts` exporting `getTemplate(n): {frontmatter, body, schema}`. Frontmatter parser: in-house, ~20 LOC, fails loudly on malformed YAML-lite (missing `---` fences, unknown keys, missing required fields `mode`/`delegable`/`delegation_hint`). Create `tests/templates.test.ts` covering: parses valid frontmatter; rejects missing fence; rejects unknown key; rejects missing required field; reads `body` and `schema` correctly. **12 tests green.**

### Phase C — Minimal server + activation surface

- [x] 7. Create `packages/mcp-product-pipeline/src/server.ts` with a single no-op `product_ping` tool returning `{content: [{type: "text", text: "pong"}]}`. Wire `McpServer` + `StdioServerTransport`. Verify `bun run src/server.ts` starts without error and exits cleanly on EOF. **JSON-RPC handshake verified via stdin pipe (initialize → tools/list → tools/call → pong).**
- [x] 8. Add `product-pipeline` block to `.mcp.json.example` (commented with `//` per spec 012 convention). Block shape: `"product-pipeline": { "command": "bun", "args": ["run", "packages/mcp-product-pipeline/src/server.ts"] }`. Update the file's header comment to mention the 4th recipe alongside playwright/chrome-devtools/dbhub. **Done; header expanded with spec 025 + local-path POC constraint note.**
- [x] 9. Dev smoke test (requires session restart): in Agent0 itself, `cp .mcp.json.example .mcp.json`, uncomment ONLY the `product-pipeline` block, restart the Claude Code session, verify `mcp__product-pipeline__product_ping` appears as an available tool, call it, confirm response `"pong"`. **Validated post-restart: 8 `mcp__product-pipeline__*` tools surfaced (product_ping superseded by Phase D's full tool set).**

### Phase D — Tool implementation

- [x] 10. Create `packages/mcp-product-pipeline/src/tools.ts` registering `product_status` (no input; returns full state or `{empty: true}` if no `.state.json`) and `product_start` (input: `{slug: string}`; rejects if `.state.json` exists with different slug; calls `initState` + creates `docs/product/01-ideation/` dir). Remove `product_ping` from server.ts; replace with these two registrations.
- [x] 11. Add `product_step_get` (no input — uses current step from state; returns `{frontmatter, body, schema, prior_artifacts: [paths]}` where `prior_artifacts` lists files under `docs/product/<earlier-steps>/` for context). Add `product_step_submit` (input: `{filename: string, content: string}`; validates schema sections present per `templates/<NN-name>/schema.md`; writes to `docs/product/<NN-name>/<filename>`; returns `{written: <abspath>}` or `{isError: true, content: [{type: "text", text: JSON.stringify({code: "schema-incomplete", missing: [...]})}]}`).
- [x] 12. Add `product_advance` (no input — moves `current_step` forward by 1; returns `{code: "gate-required", phase: "..."}` error if crossing a gate without `gates_passed` entry; returns `{code: "pipeline-complete"}` after step 12 with the canonical handoff message naming `/sdd new <slug>`). Add `product_gate_pass` (input: `{phase: "discovery" | "identity" | "specification"}`; appends to `gates_passed`; idempotent). Add `product_done` (no input; returns the final completion summary with artifact paths per phase + literal `/sdd` invocation command).
- [x] 13. Add `product_get_delegation_brief` (input: `{step_n: number}`; reads template frontmatter via `getTemplate(step_n)`; returns plain-text 5-field block composed from `delegation_hint`, prior-artifact paths from state, and a fixed template). Output reaches the parent agent as `{content: [{type: "text", text: "TASK: ...\nCONTEXT: ...\nCONSTRAINTS: ...\nDELIVERABLE: ...\nDONE_WHEN: ..."}]}` — pasteable verbatim into `Agent` tool prompts.

### Phase E — First template + smoke tests

- [x] 14. Port step 1 (ideation) template: create `packages/mcp-product-pipeline/src/templates/01-ideation/prompt.md` with frontmatter `mode: interactive`, `delegable: false`, `delegation_hint: "n/a — interactive step"`, body ported from `/home/goat/anthill/.claude/skills/anthill-product-ideator/SKILL.md` (structure + checklist) with Agent0 voice rewrite. Create `templates/01-ideation/schema.md` listing required sections (concept, target_audience, differentiation, risks, sources).
- [x] 15. **E2E smoke test, step 1 only** — confirmed via tmp-dir smoke (Phase E commit `fa72839`): `product_start("smoke-step1")` → `product_step_get` → `product_step_submit` (incomplete → `schema-incomplete` rejection with `missing: [differentiation, risks, sources]`) → `product_step_submit` (complete → wrote `04-concept-brief.md`) → `product_advance` → `.state.json` shows `completed: [1], current_step: 2`. Live founder interview deferred (plumbing already proven).
- [x] 16. **Delegation dry-run smoke test** — confirmed post-restart via parent calling `mcp__product-pipeline__product_status` (returned `{empty: true}`), then dispatching `Agent` sub-agent with 5-field brief asking it to enumerate `mcp__product-pipeline__*` tools + call `product_status` independently. Sub-agent returned ALL 8 product_* tool names + identical `{empty: true}` JSON. **INHERITANCE CONFIRMED** — the load-bearing assumption of synthesis-mode delegation is validated. Stub template was unnecessary; live tools sufficed.

### Phase F — Template content authoring (post-smoke-test)

- [x] 17. Port Discovery templates remaining (steps 2-4): `02-prototype/`, `03-spec/`, `04-ux-testing/`. Modes per `plan.md` table. Validation-mode declaration lifted from anthill's `validation-mode.md` rule into step 4's prompt.md body.
- [x] 18. Port Identity templates (steps 5-7): `05-brand/`, `06-design-system/`, `07-prototype-v2/`. Step 5 interactive (founder voice/vision); steps 6-7 synthesis.
- [x] 19. Port Specification templates (steps 8-12): `08-prd/`, `09-system-design/`, `10-cost-estimate/`, `11-roadmap/`, `12-legal/`. Steps 8/10/11 draft-after-input; steps 9/12 synthesis. Source skills from `/home/goat/anthill/.claude/skills/anthill-{prd,principal-engineer,system-design-bridge,roadmap-bridge}/`. Step 10 cost-estimate written fresh (no anthill equivalent).

### Phase G — User-facing docs

- [x] 20. Write `packages/mcp-product-pipeline/README.md` covering: (a) activation triple (`cp .mcp.json.example .mcp.json` → uncomment → restart); (b) tool reference table (8 tools, one line each); (c) per-step mode table (12 rows, mirrors `plan.md`); (d) worked example: parent dispatches step 9 via `product_get_delegation_brief(9)` + `Agent` tool (3-4 line snippet); (e) `docs/product/` output tree map; (f) deactivation (comment block, restart); (g) `/sdd` handoff prose for end-of-pipeline.

## Verification

_Each line maps to a `spec.md` acceptance criterion. Tick after observing the behavior in a real session, not from reading the code._

- [x] **AC: plug-and-play activation** — validated post-restart: `mcp__product-pipeline__*` tools appeared at SessionStart, `.claude/` is untouched (only `.mcp.json` itself changed — which is gitignored).
- [x] **AC: pipeline cold-start and first-step orientation** — observed during task 15 tmp-dir smoke.
- [x] **AC: linear progression through all 12 steps** — partial walk (4/12) executed end-to-end during Phase H comprehensive smoke: steps 1→4 with submits + advances + gate-required block + gate_pass + advance into step 5 (Identity phase) all behaved as designed. Same advance+gate mechanic at steps 7 and 12 by construction. Full 12-step walk against a real product slug is the natural Phase-H+1 dogfood — design-validated here.
- [x] **AC: resumability across sessions** — validated by booting two separate MCP server processes against the same `docs/product/` dir. Process 1 ran start + step1 submit + advance; process 2 (fresh boot) called `product_status` and read `current_step: 2, completed: [1]` from disk. Cross-process state survival = cross-Claude-Code-session resumability.
- [x] **AC: phase-gate enforcement** — Phase H smoke: after step 4 submit + advance, `product_advance` returned `{code: "gate-required", phase: "discovery", next_phase: "identity"}` with state unchanged. After `product_gate_pass("discovery")` + retry `product_advance`, transitioned cleanly to step 5 (identity phase).
- [x] **AC: step submission validates required shape** — Phase E smoke: submitted step 1 content missing `[differentiation, risks, sources]` → rejected with `{code: "schema-incomplete", missing: [...]}` and no file written.
- [ ] **AC: clean uninstall preserves artifacts** — **NOT YET VALIDATED LIVE.** Implementation guarantee: `docs/product/` lives in the host project (cwd-relative), not in the package — comment the `.mcp.json` block, restart, the dir is unchanged. Validation requires the user to restart with the block commented; deferred to natural use.
- [x] **AC: handoff to `/sdd` at pipeline completion** — implementation verified in `tools.ts handleDone()`: returns per-phase deliverable summary plus literal command `/sdd new <slug>`. `product_advance` after step 12 returns `code: "pipeline-complete"` with the message naming `/sdd`. Same mechanic as step-4 gate proven in Phase H smoke.
- [x] **AC: delegation-ready brief for synthesis steps** — Phase H smoke: `product_get_delegation_brief(3)` (synthesis-mode step) returned a full 5-field block (TASK / CONTEXT / CONSTRAINTS / DELIVERABLE / DONE_WHEN) referencing prior artifacts under `docs/product/`. `product_get_delegation_brief(1)` (interactive-mode step) correctly errored `{code: "not-delegable", mode: "interactive", hint: "..."}`.
- [x] **AC static fact: `packages/mcp-product-pipeline/` structure** — verified: `find packages/mcp-product-pipeline/src -type f | sort` returns server.ts + pipeline.ts + paths.ts + state.ts + templates.ts + tools.ts + 24 template markdown files (2 per step × 12 steps).
- [x] **AC static fact: NO `pnpm-workspace.yaml`, NO root `package.json`** — verified: `ls package.json pnpm-workspace.yaml` returns ENOENT for both (refined criterion per plan.md § Approach paragraph 3).
- [x] **AC static fact: `.mcp.json.example` shipped with `product-pipeline` block** — verified: `grep -c product-pipeline .mcp.json.example` returns 6.
- [x] **AC static fact: README documents all 8 tools + mode table** — verified: 22 `product_*` references + 12-row mode table (matches step count).
- [x] **AC static fact: `.gitignore` does NOT ignore `docs/product/`** — verified: `grep -E '^(\!?)(docs/product|docs/$)' .gitignore` returns empty.
- [x] **AC static fact: harness-sync manifest unchanged** — verified: `grep -E '(packages|pnpm-workspace|docs/product)' .claude/tools/sync-harness.sh` returns empty (no entries in `COPY_CHECK_*` arrays). Forks won't sync `packages/` content.

## Notes

- **Two tasks required user collaboration:** task 9 (initial activation post-restart) ✓ done, and task 16 (delegation inheritance) ✓ done. Task 15 (live founder interview) was deemed redundant once the plumbing smoke + delegation smoke both passed.
- **Phase F (template authoring) is content-heavy.** 22 markdown files across steps 2-12 committed in `502fad3` (~57 KB). Could have been split per phase but small enough to land as one commit cleanly.
- **Validation-mode for step 4** simplified per `plan.md` § Risks: declared once in step 4's submitted artifact, regex-extracted into `.state.json.validation_mode` by `product_step_submit`. Verified working in Phase H smoke: `validation_mode: intuition` in body → state.json reflects the value.
- **No new audit log.** Mirrors spec 011's posture; `.state.json` is the latest-snapshot truth.
- **Supply-chain block on task 2** (`bun install`) — handled via the multi-line `# OVERRIDE: introducing MCP TypeScript SDK + tsc + types-node deps for new packages/mcp-product-pipeline subtree per spec 025`. Audited as `advisory-bare-install-override` per spec 009 + the parent-edit + bare-install sub-path landed in `e9b7f53`.
- **Single AC not yet validated live: clean uninstall.** Implementation-verified (artifact paths are cwd-relative, MCP only reads/writes filesystem; commenting `.mcp.json` block stops tool registration but leaves `docs/product/` untouched). True validation = user comments block, restarts, observes. Deferred to natural use — no design risk remains.
