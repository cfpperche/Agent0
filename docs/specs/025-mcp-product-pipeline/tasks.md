# 025 — mcp-product-pipeline — tasks

_Generated from `plan.md` on 2026-05-12. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Phase A — Scaffolding

- [ ] 1. Create `packages/mcp-product-pipeline/` with `package.json` (name `agent0-mcp-product-pipeline`, private, type `module`, scripts: `start: bun run src/server.ts`, `build: tsc`, `typecheck: tsc --noEmit`, `test: bun test`; runtime dep `@modelcontextprotocol/sdk@^1.29.0`; dev deps `typescript@^5.7.0` + `@types/node@^22.0.0`), `tsconfig.json` (strict, `module: NodeNext`, `target: ES2022`, `outDir: dist`, `rootDir: src`), and `.gitignore` (`node_modules/`, `dist/`). Use `# OVERRIDE: scaffolding new POC package per spec 025 mcp-product-pipeline` on the supply-chain block when `bun install` lands.
- [ ] 2. Run `bun install` in `packages/mcp-product-pipeline/`; verify `bun.lock` is produced; commit both `package.json` and `bun.lock` together.

### Phase B — Foundation modules (decoupled, testable in isolation)

- [ ] 3. Create `packages/mcp-product-pipeline/src/pipeline.ts` exporting: typed constant `STEPS: StepDef[]` with all 12 step definitions per the mode table in `plan.md` § Files; `PHASES = ["discovery", "identity", "specification"]`; `GATE_AFTER = [4, 7, 12]`; `ExecutionMode = "interactive" | "draft-after-input" | "synthesis"` union type; helper `stepByN(n: number): StepDef`.
- [ ] 4. Create `packages/mcp-product-pipeline/src/paths.ts` exporting `productRoot()` (returns `${process.cwd()}/docs/product`), `stateFile()` (returns `${productRoot()}/.state.json`), `stepDir(n)` (returns `${productRoot()}/${NN-name}`), `templateDir(n)` (returns `${packageRoot()}/src/templates/${NN-name}` via `import.meta.url`).
- [ ] 5. Create `packages/mcp-product-pipeline/src/state.ts` exporting `readState()`, `writeState(s)` (atomic via `Bun.write` to `${stateFile()}.tmp` then `rename`), `initState(slug)`, `markCompleted(n)`, `markGatePassed(phase)`, `getCurrentStep()`. State schema: `{slug, current_step, phase, completed: number[], gates_passed: string[], validation_mode?: string, started_at}`. Create `tests/state.test.ts` covering: init creates valid state; round-trip read-after-write; markCompleted is idempotent; rename atomicity (no torn writes with concurrent writes).
- [ ] 6. Create `packages/mcp-product-pipeline/src/templates.ts` exporting `getTemplate(n): {frontmatter, body, schema}`. Frontmatter parser: in-house, ~20 LOC, fails loudly on malformed YAML-lite (missing `---` fences, unknown keys, missing required fields `mode`/`delegable`/`delegation_hint`). Create `tests/templates.test.ts` covering: parses valid frontmatter; rejects missing fence; rejects unknown key; rejects missing required field; reads `body` and `schema` correctly.

### Phase C — Minimal server + activation surface

- [ ] 7. Create `packages/mcp-product-pipeline/src/server.ts` with a single no-op `product_ping` tool returning `{content: [{type: "text", text: "pong"}]}`. Wire `McpServer` + `StdioServerTransport`. Verify `bun run src/server.ts` starts without error and exits cleanly on EOF.
- [ ] 8. Add `product-pipeline` block to `.mcp.json.example` (commented with `//` per spec 012 convention). Block shape: `"product-pipeline": { "command": "bun", "args": ["run", "packages/mcp-product-pipeline/src/server.ts"] }`. Update the file's header comment to mention the 4th recipe alongside playwright/chrome-devtools/dbhub.
- [ ] 9. Dev smoke test (requires session restart): in Agent0 itself, `cp .mcp.json.example .mcp.json`, uncomment ONLY the `product-pipeline` block, restart the Claude Code session, verify `mcp__product-pipeline__product_ping` appears as an available tool, call it, confirm response `"pong"`. Add `.mcp.json` to `.gitignore` (it's developer-local per spec 012). **Requires user collaboration — agent reports the steps; user restarts and reports back.**

### Phase D — Tool implementation

- [ ] 10. Create `packages/mcp-product-pipeline/src/tools.ts` registering `product_status` (no input; returns full state or `{empty: true}` if no `.state.json`) and `product_start` (input: `{slug: string}`; rejects if `.state.json` exists with different slug; calls `initState` + creates `docs/product/01-ideation/` dir). Remove `product_ping` from server.ts; replace with these two registrations.
- [ ] 11. Add `product_step_get` (no input — uses current step from state; returns `{frontmatter, body, schema, prior_artifacts: [paths]}` where `prior_artifacts` lists files under `docs/product/<earlier-steps>/` for context). Add `product_step_submit` (input: `{filename: string, content: string}`; validates schema sections present per `templates/<NN-name>/schema.md`; writes to `docs/product/<NN-name>/<filename>`; returns `{written: <abspath>}` or `{isError: true, content: [{type: "text", text: JSON.stringify({code: "schema-incomplete", missing: [...]})}]}`).
- [ ] 12. Add `product_advance` (no input — moves `current_step` forward by 1; returns `{code: "gate-required", phase: "..."}` error if crossing a gate without `gates_passed` entry; returns `{code: "pipeline-complete"}` after step 12 with the canonical handoff message naming `/sdd new <slug>`). Add `product_gate_pass` (input: `{phase: "discovery" | "identity" | "specification"}`; appends to `gates_passed`; idempotent). Add `product_done` (no input; returns the final completion summary with artifact paths per phase + literal `/sdd` invocation command).
- [ ] 13. Add `product_get_delegation_brief` (input: `{step_n: number}`; reads template frontmatter via `getTemplate(step_n)`; returns plain-text 5-field block composed from `delegation_hint`, prior-artifact paths from state, and a fixed template). Output reaches the parent agent as `{content: [{type: "text", text: "TASK: ...\nCONTEXT: ...\nCONSTRAINTS: ...\nDELIVERABLE: ...\nDONE_WHEN: ..."}]}` — pasteable verbatim into `Agent` tool prompts.

### Phase E — First template + smoke tests

- [ ] 14. Port step 1 (ideation) template: create `packages/mcp-product-pipeline/src/templates/01-ideation/prompt.md` with frontmatter `mode: interactive`, `delegable: false`, `delegation_hint: "n/a — interactive step"`, body ported from `/home/goat/anthill/.claude/skills/anthill-product-ideator/SKILL.md` (structure + checklist) with Agent0 voice rewrite. Create `templates/01-ideation/schema.md` listing required sections (concept, target_audience, differentiation, risks, sources).
- [ ] 15. **E2E smoke test, step 1 only** (requires session restart): with MCP active, parent agent walks `product_status` → `product_start("tiktok-clone")` → `product_step_get` → conducts interview with user → `product_step_submit({filename: "04-concept-brief.md", content: <draft>})` → `product_advance`. Verify: `docs/product/.state.json` reflects `current_step: 2, completed: [1]`; `docs/product/01-ideation/04-concept-brief.md` exists and contains the draft; `product_advance` did NOT cross the discovery gate (step 2 is still in discovery phase). **Requires user collaboration for the interactive interview portion.**
- [ ] 16. **Delegation dry-run smoke test** (requires session restart, but no template authoring — uses a stub template): create `templates/00-test-synthesis/prompt.md` with `mode: synthesis`, `delegable: true`, `delegation_hint: "draft a one-line synthesis test artifact"`. Manually set state to point at step 0 (or use a debug tool to seed state). Parent agent calls `product_get_delegation_brief(0)`, pastes the returned brief into an `Agent` tool dispatch; sub-agent runs in fresh context; sub-agent successfully calls `product_step_get(0)` AND `product_step_submit` from its own MCP tool surface; returns short summary; parent verifies artifact landed. **Confirms `plan.md` § Risks "Sub-agent MCP-tool inheritance assumption".** Delete the `00-test-synthesis` template after the test passes — it's scaffolding, not product content.

### Phase F — Template content authoring (post-smoke-test)

- [ ] 17. Port Discovery templates remaining (steps 2-4): `02-prototype/`, `03-spec/`, `04-ux-testing/`. Modes per `plan.md` table. Validation-mode declaration lifted from anthill's `validation-mode.md` rule into step 4's prompt.md body.
- [ ] 18. Port Identity templates (steps 5-7): `05-brand/`, `06-design-system/`, `07-prototype-v2/`. Step 5 interactive (founder voice/vision); steps 6-7 synthesis.
- [ ] 19. Port Specification templates (steps 8-12): `08-prd/`, `09-system-design/`, `10-cost-estimate/`, `11-roadmap/`, `12-legal/`. Steps 8/10/11 draft-after-input; steps 9/12 synthesis. Source skills from `/home/goat/anthill/.claude/skills/anthill-{prd,principal-engineer,system-design-bridge,roadmap-bridge}/`.

### Phase G — User-facing docs

- [ ] 20. Write `packages/mcp-product-pipeline/README.md` covering: (a) activation triple (`cp .mcp.json.example .mcp.json` → uncomment → restart); (b) tool reference table (8 tools, one line each); (c) per-step mode table (12 rows, mirrors `plan.md`); (d) worked example: parent dispatches step 9 via `product_get_delegation_brief(9)` + `Agent` tool (3-4 line snippet); (e) `docs/product/` output tree map; (f) deactivation (comment block, restart); (g) `/sdd` handoff prose for end-of-pipeline.

## Verification

_Each line maps to a `spec.md` acceptance criterion. Tick after observing the behavior in a real session, not from reading the code._

- [ ] **AC: plug-and-play activation** — verify in a fresh fork (or Agent0 itself with a clean state) that activation touches zero files under `.claude/` and no `settings.json` entry was added. Confirm by `git status` after the cp + uncomment + restart triple — only `.mcp.json` should appear, nothing else.
- [ ] **AC: pipeline cold-start and first-step orientation** — observed during task 15.
- [ ] **AC: linear progression through all 12 steps** — run end-to-end on a real or fixture slug; verify `.state.json` ends with `completed: [1..12]`, `gates_passed: ["discovery", "identity", "specification"]`; verify final `product_advance` returns pipeline-complete with `/sdd` handoff text.
- [ ] **AC: resumability across sessions** — pause mid-pipeline (e.g. at step 5), close session, reopen; verify `product_status` returns the expected current step and history.
- [ ] **AC: phase-gate enforcement** — after step 4 submit + advance, attempt `product_advance` without `product_gate_pass("discovery")`; verify error `{code: "gate-required", phase: "discovery→identity"}` is returned and state is unchanged.
- [ ] **AC: step submission validates required shape** — submit a step 1 draft missing the `risks` section; verify `{code: "schema-incomplete", missing: ["risks"]}` and no file written.
- [ ] **AC: clean uninstall preserves artifacts** — comment the `.mcp.json` block, restart, verify `docs/product/` still present and readable, `product_*` tools absent.
- [ ] **AC: handoff to `/sdd` at pipeline completion** — observed at the tail of the end-to-end run; verify the completion message includes the literal `/sdd new <slug>` command.
- [ ] **AC: delegation-ready brief for synthesis steps** — observed during task 16 (smoke test) and again during step 9 of the end-to-end run.
- [ ] **AC static fact: `packages/mcp-product-pipeline/` structure** — `find packages/mcp-product-pipeline/src -type f | sort` returns the expected list (server.ts, pipeline.ts, paths.ts, state.ts, templates.ts, tools.ts, templates/<12 dirs>/{prompt.md, schema.md}).
- [ ] **AC static fact: NO `pnpm-workspace.yaml`, NO root `package.json`** — `ls /home/goat/Agent0 | grep -E '^(package\.json\|pnpm-workspace\.yaml)$'` returns empty (refined criterion per plan.md § Approach paragraph 3).
- [ ] **AC static fact: `.mcp.json.example` shipped with `product-pipeline` block** — `grep -c product-pipeline .mcp.json.example` returns ≥1.
- [ ] **AC static fact: README documents all 8 tools + mode table** — manual inspection.
- [ ] **AC static fact: `.gitignore` does NOT ignore `docs/product/`** — `grep -E '^(\!?)(docs/product|docs/$)' .gitignore` returns empty.
- [ ] **AC static fact: harness-sync manifest unchanged** — `grep -E '(packages|pnpm-workspace|docs/product)' .claude/tools/sync-harness.sh` returns empty (or only inside comments).

## Notes

- **Two tasks require user collaboration** for full verification: task 9 (initial activation smoke test) and tasks 15-16 (step 1 + delegation smoke tests). Agent prepares the artifacts; user restarts the session and reports observations.
- **Phase F (template authoring) is content-heavy.** Plan estimates 24+ markdown files across steps 2-12. Consider committing each phase (Discovery / Identity / Specification) as its own commit for review granularity.
- **Validation-mode for step 4** simplified per `plan.md` § Risks: declared once in step 4's submitted artifact, stored in `.state.json.validation_mode`, no cross-step consistency enforcement in v1. Revisit if real-world use shows the simpler shape misses bugs.
- **No new audit log.** Mirrors spec 011's posture; `.state.json` is the latest-snapshot truth.
- **Supply-chain block expected on task 2** (`bun install`) — use the verbatim `# OVERRIDE: <reason>` marker shape from `.claude/rules/supply-chain.md` § Override grammar. The override must be a two-line Bash command (start-of-line anchor); inline-trailing markers are rejected.
