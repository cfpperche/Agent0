# 025 — mcp-product-pipeline — plan

_Drafted from `spec.md` on 2026-05-12. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Build a single-process Node/Bun-runnable stdio MCP server using `@modelcontextprotocol/sdk@1.29.0` (the stable v1 line — v2 is still `2.0.0-alpha.2` as of 2026-05-12 and not viable for POC). The server exposes 8 tools (`product_status`, `product_start`, `product_step_get`, `product_step_submit`, `product_advance`, `product_gate_pass`, `product_done`, `product_get_delegation_brief`) whose handlers act on two persistent surfaces: `docs/product/.state.json` (pipeline index, ~10 fields of JSON) and `docs/product/<NN-name>/*.md` (the actual artifacts). The 12 step definitions — name, phase, output filename(s), required schema sections, guide questions — live in `src/pipeline.ts` as a typed constant; the per-step prompt content lives in `src/templates/<NN-name>/{prompt.md, schema.md}` markdown files (with YAML frontmatter declaring `mode` + `delegable` + `delegation_hint`) so they're trivially editable, reviewable in diffs, and contributable by non-coders.

**Delegation-aware design.** Each step declares one of three execution modes in its `prompt.md` frontmatter: `interactive` (parent must conduct — user interview required, e.g. steps 1 ideation, 5 brand), `draft-after-input` (parent collects direction from user, then delegates the documentation drafting, e.g. steps 2, 8 prd, 10 cost, 11 roadmap), or `synthesis` (fully delegable — derives from prior artifacts without user interaction, e.g. steps 3 spec, 6 design-system, 7 prototype-v2, 9 system-design, 12 legal). The 8th tool `product_get_delegation_brief(step_n)` returns a ready-to-paste 5-field handoff block (TASK / CONTEXT / CONSTRAINTS / DELIVERABLE / DONE_WHEN per `.claude/rules/delegation.md`) that the parent agent issues to the `Agent` tool — eliminating the ceremony of composing the brief from scratch and ensuring the sub-agent's dispatch always references the right MCP tool calls and artifact paths. This is the architectural lever that keeps the parent's context budget intact: synthesis-mode steps run entirely in sub-agent context (template + prior artifacts + draft never enter the parent's window), and the parent only sees the sub-agent's short return summary.

Order of construction prioritises end-to-end thinness before content depth: scaffold the bun package and the simplest possible MCP server (one no-op tool to confirm the stdio handshake works against Claude Code), then implement the pipeline state machine with the 8 tools but only step 1's template content. Smoke-test end-to-end against a real `.mcp.json` activation — including one delegation-mode dry-run (synthesis step) to verify a sub-agent can call `product_step_get` and `product_step_submit` from its own context. Only then port the remaining 11 step templates. This sequence catches structural issues (path resolution, tool schema serialization, sub-agent MCP tool inheritance, state file race) before investing in 12 sets of content authoring, and gives an early demo-able milestone where "step 1 ideation" works fully against the user-facing TikTok-clone scenario from spec.md.

**Refinement to spec acceptance criterion #8:** the spec said "`pnpm-workspace.yaml` at repo root declares `packages/*` as workspaces". Codebase audit on 2026-05-12 surfaced that `site/` (spec 024) is a standalone Bun subdir with its own `bun.lock` and no root `package.json` — workspace tooling was deliberately skipped. The new MCP follows that pattern: `packages/mcp-product-pipeline/` is a self-contained Bun project with its own `package.json` + `bun.lock`. No root `package.json`, no `pnpm-workspace.yaml`, no `bun` `workspaces` field. Future MCPs replicate the pattern. If we ever hit shared-deps friction (3+ packages duplicating big dependencies), introduce bun workspaces then — for two packages it's premature. The "no restructuring" guarantee the spec criterion sought is preserved: adding a third package is `mkdir packages/<name> && bun init` in that dir, no root touch.

## Files to touch

**Create — package scaffolding:**
- `packages/mcp-product-pipeline/package.json` — name `agent0-mcp-product-pipeline`, private, type `module`, bin `dist/server.js` (or `src/server.ts` for direct bun-run mode), single runtime dep `@modelcontextprotocol/sdk@^1.29.0`, dev deps `typescript` + `@types/node`. Scripts: `start` (bun run src/server.ts), `build` (tsc), `typecheck`.
- `packages/mcp-product-pipeline/tsconfig.json` — extends a strict base; `module: NodeNext`, `target: ES2022`, `outDir: dist`, `rootDir: src`.
- `packages/mcp-product-pipeline/.gitignore` — `node_modules/`, `dist/`.
- `packages/mcp-product-pipeline/README.md` — activation workflow, tool reference (8 tools, one-line each), the per-step mode table (interactive/draft-after-input/synthesis), a worked example showing the parent dispatching a synthesis step via `product_get_delegation_brief` + `Agent` tool, `docs/product/` output tree map, deactivation, `/sdd` handoff prose.
- `packages/mcp-product-pipeline/bun.lock` — emitted by `bun install` after package.json lands; committed (matches `site/bun.lock` precedent).

**Create — server source:**
- `packages/mcp-product-pipeline/src/server.ts` — entrypoint. Instantiates `McpServer({ name: "agent0-product-pipeline", version: "0.1.0" })`, registers the 8 tools via `server.registerTool(...)`, connects `StdioServerTransport`, awaits.
- `packages/mcp-product-pipeline/src/pipeline.ts` — typed constant `STEPS: StepDef[]` with the 12 step definitions (n, name, phase, dir, output files, required schema sections, gate-after). Single source of truth for ordering and gate boundaries. Also exports `PHASES` (discovery/identity/specification), `GATE_AFTER` (steps 4, 7, 12), and the `ExecutionMode` union type (`"interactive" | "draft-after-input" | "synthesis"`) consumed by template-frontmatter parsing and the delegation-brief tool.
- `packages/mcp-product-pipeline/src/state.ts` — read/write `docs/product/.state.json` via Bun's `Bun.file()` + atomic `mktemp + rename` for writes. Exports `readState()`, `writeState()`, `initState(slug)`, and helpers `getCurrentStep()`, `markCompleted(n)`, `markGatePassed(phase)`.
- `packages/mcp-product-pipeline/src/templates.ts` — small module that reads `templates/<NN-name>/prompt.md`, parses YAML frontmatter (using a minimal in-house parser — see § Alternatives for why we skip `gray-matter`), exposes `getTemplate(n)` returning `{frontmatter: {mode, delegable, delegation_hint}, body, schema}`. Frontmatter is the contract; missing/malformed fields fail loudly at server boot, not at first call.
- `packages/mcp-product-pipeline/src/tools.ts` — single file with the 8 tool handlers (status, start, step_get, step_submit, advance, gate_pass, done, get_delegation_brief). Each handler is ~20-50 lines: validate input → read state → enforce invariants → mutate state + filesystem → return structured response. Errors return `{isError: true, content: [{type: "text", text: JSON.stringify({code, hint, ...})}]}` so the agent can pattern-match. The 8th tool `get_delegation_brief` composes its output from the step's `delegation_hint` frontmatter, prior-artifact paths from `.state.json`, and a fixed 5-field template — output is plain text the parent agent pastes verbatim into the `Agent` tool prompt.
- `packages/mcp-product-pipeline/src/paths.ts` — small helper that resolves `docs/product/` and template dirs relative to `process.cwd()` (project root) for artifact writes, and relative to `import.meta.url` (package internals) for template reads. Catches the "MCP runs from project root, templates live in package dir" path-resolution trap up front.

**Create — templates (24+ markdown files).** Every `prompt.md` starts with YAML frontmatter declaring three fields: `mode: interactive | draft-after-input | synthesis`, `delegable: true | partial | false`, `delegation_hint: "<short TASK string used by product_get_delegation_brief>"`. Per-step mode assignment (locked here so template authoring is unambiguous):

| Step | Mode | Delegable | Rationale |
|---|---|---|---|
| 01-ideation | interactive | false | 5-8 question discovery interview; parent must conduct |
| 02-prototype | draft-after-input | partial | parent collects direction; delegates mockup-spec drafting |
| 03-spec | synthesis | true | derives from ideation; no new user input |
| 04-ux-testing | draft-after-input | partial | `tested` mode needs user observation; `intuition` is synthesis |
| 05-brand | interactive | false | founder voice/vision input required |
| 06-design-system | synthesis | true | derives from brand book |
| 07-prototype-v2 | synthesis | true | applies design-system to prototype |
| 08-prd | draft-after-input | partial | parent confirms priorities; delegates documentation |
| 09-system-design | synthesis | true | pure architecture derivation from PRD |
| 10-cost-estimate | draft-after-input | partial | parent confirms pricing/business model; delegates the financial model |
| 11-roadmap | draft-after-input | partial | parent confirms time window + focus; delegates release plan |
| 12-legal | synthesis | true | applies legal templates to product data |

- `packages/mcp-product-pipeline/src/templates/01-ideation/{prompt.md, schema.md}` — mode `interactive`. Ported from `anthill-product-ideator/SKILL.md` (structure + checklist) with Agent0 voice rewrite.
- `packages/mcp-product-pipeline/src/templates/02-prototype/{prompt.md, schema.md}`
- `packages/mcp-product-pipeline/src/templates/03-spec/{prompt.md, schema.md}`
- `packages/mcp-product-pipeline/src/templates/04-ux-testing/{prompt.md, schema.md}` — includes the `tested`/`intuition`/`not-applicable` validation-mode declaration (lifted from anthill's `validation-mode.md` rule).
- `packages/mcp-product-pipeline/src/templates/05-brand/{prompt.md, schema.md}`
- `packages/mcp-product-pipeline/src/templates/06-design-system/{prompt.md, schema.md}`
- `packages/mcp-product-pipeline/src/templates/07-prototype-v2/{prompt.md, schema.md}`
- `packages/mcp-product-pipeline/src/templates/08-prd/{prompt.md, schema.md}` — ported from `anthill-prd`
- `packages/mcp-product-pipeline/src/templates/09-system-design/{prompt.md, schema.md}` — ported from `anthill-principal-engineer` + `anthill-system-design-bridge`
- `packages/mcp-product-pipeline/src/templates/10-cost-estimate/{prompt.md, schema.md}`
- `packages/mcp-product-pipeline/src/templates/11-roadmap/{prompt.md, schema.md}` — ported from `anthill-roadmap-bridge`
- `packages/mcp-product-pipeline/src/templates/12-legal/{prompt.md, schema.md}`

**Modify:**
- `.mcp.json.example` — add a 4th commented block `product-pipeline`. Shape:
  ```
  //    "product-pipeline": {
  //      "command": "bun",
  //      "args": ["run", "packages/mcp-product-pipeline/src/server.ts"]
  //    }
  ```
  Header comment updated to mention `product-pipeline` alongside the existing playwright/chrome-devtools/dbhub trio, pointing at `packages/mcp-product-pipeline/README.md` for details.
- `.gitignore` — explicitly NOT modified for `docs/product/`; verify the existing rules don't accidentally ignore it (a `docs/` rule would be a problem; quick `grep '^docs' .gitignore` to confirm). If the file is clean, no change needed.

**Delete:**
- None. POC is additive.

## Alternatives considered

### Python MCP server using `mcp` (the Python SDK)

Rejected because the rest of Agent0's tooling — site/ (Astro+Bun), hooks (Bash), validators (Bash) — has no Python footprint. Adding Python would force every fork that activates this MCP to have a working Python toolchain (uv or system python), which inverts the "zero injection" promise on the host side. TypeScript+Bun keeps the runtime dependency identical to what's already installed for the site/ subtree. Python's MCP SDK is solid (Anthropic-maintained), so the rejection is purely about consistency, not capability.

### MCP TypeScript SDK v2 (`@modelcontextprotocol/server@2.0.0-alpha.2`)

Rejected because v2 is still `alpha.2` (verified npm registry, 2026-05-12). v2 splits the package (`@modelcontextprotocol/server` + `/client`), uses Standard Schema for input validation (Zod v4, Valibot, ArkType — bring-your-own), and has a different `registerTool` signature. The README on `main` warns "v1.x remains the recommended version for production use" with v1 supported "at least 6 months after v2 ships". v2 will eventually be the right move; doing the POC on alpha software locks in upgrade pain when the API changes (which it will, between alpha and stable). v1.29.0 is mature, Bun-compatible, and works.

### `pnpm-workspace.yaml` + root `package.json` (literal spec criterion)

Rejected (refining spec criterion #8) because the existing precedent is `site/` as a standalone Bun subdir. Adopting pnpm-workspace introduces a tooling family (pnpm) the project doesn't use, just to satisfy a structural label. Bun's workspace support via root `package.json` `workspaces` field would be the consistent alternative — but with only two packages (`site/` and `mcp-product-pipeline/`) and zero shared deps, workspace tooling adds setup cost without dedupe payoff. Each package self-installs `node_modules` independently, which is exactly what `site/` does today. Revisit when a third package appears or shared deps emerge.

### Embed step templates as TypeScript string constants

Rejected because templates are content, not code. Markdown files render natively in editors, diff cleanly in PRs, and let humans (designers, founders, technical writers) contribute without TypeScript awareness. The runtime cost of `fs.readFile` per step_get call is negligible (called <12 times per pipeline lifetime, in human-conversational latency). A TS-constants approach also tangles content updates with code reviews — wrong split.

### Collapse `product_step_submit` + `product_advance` into a single `product_step_complete` tool

Rejected because the gap between submit and advance is semantically meaningful: it lets the agent surface the saved artifact to the user (and let the user request edits) **before** the pipeline state changes. A unified tool would lock the agent into "save and move on" behavior, eliminating the chance for the user to course-correct without backtracking state. Two tools = two distinct operations the agent (and user) controls. Cost is one extra tool invocation; readability and recoverability gain outweigh.

### SQLite (`Bun.sqlite`) for state

Rejected because we have one record per pipeline (1 fork = 1 product per spec non-goal). JSON file is human-readable, diffable, git-trackable, and editable by hand for recovery scenarios. SQLite buys nothing at this scale and removes the "open `.state.json` in an editor to see what's going on" affordance. The state index IS deliberately a thin reflection of the filesystem; complicating storage would invert that.

### Skip templates entirely; have `product_step_get` return only a checklist

Rejected because the templates ARE the value-add of the MCP. Without porting anthill's curated prompts (interview questions, citation requirements, validation modes, schema constraints, examples), the MCP is a glorified linear state machine that any 50-line shell script could provide. The 12 anthill skills represent meaningful product-discovery discipline; the MCP exists to deliver that discipline to a fork that doesn't have anthill installed. Stripping templates would deliver the structure without the substance.

### `gray-matter` package for frontmatter parsing

Rejected to keep the dep tree minimal. The frontmatter contract is fixed (3 fields, all required, simple string values) so a 20-line in-house parser handles it without pulling in `gray-matter`'s 200+ KB transitive tree (`js-yaml`, `stripBom`, `extend`, `kind-of`). Format is YAML-lite, not full YAML: `---` fences, `key: value` per line, string values without quoting needed. The parser fails loudly at server boot if any template's frontmatter is malformed — better to crash early at dev time than silently degrade at user-call time. If we ever need richer frontmatter (lists, nested keys), revisit.

### Separate `meta.json` file per step instead of frontmatter

Rejected because frontmatter colocates the metadata with the content it describes; `meta.json` next to `prompt.md` doubles the file count (24 → 36) and invites drift where the metadata says one thing and the prompt prose says another. Frontmatter forces edits to land in the same file, in the same diff. Standard markdown editors (Obsidian, VS Code's markdown preview) render frontmatter natively or hide it cleanly. The trade-off — parsing complexity — is negligible (see preceding alternative).

### Hardcode delegation briefs in `tools.ts` instead of computing from `delegation_hint` frontmatter

Rejected because the brief content is per-step domain knowledge, not server plumbing. Authors editing step 9 (system-design) shouldn't have to touch TypeScript to tweak the sub-agent's CONTEXT line — they edit `09-system-design/prompt.md`'s frontmatter and the change reaches `product_get_delegation_brief` automatically. Keeps the content/code split clean (templates own content, server owns mechanism).

## Risks and unknowns

- **Path resolution under MCP stdio invocation.** `.mcp.json` uses `"command": "bun", "args": ["run", "packages/mcp-product-pipeline/src/server.ts"]`. Claude Code spawns this with cwd set to the project root (per MCP convention) — meaning `process.cwd()` is the fork's root, while `import.meta.url` is the package src dir. The MCP must write artifacts to `cwd/docs/product/` and read templates from `<package>/src/templates/`. Mistake-prone; `src/paths.ts` exists specifically to centralize this. Verify in smoke test before porting all 12 templates.
- **`@modelcontextprotocol/sdk` exports under Bun.** The package is `type: "module"` (ESM); bun handles ESM natively. The `/server/mcp.js` and `/server/stdio.js` subpath imports might require careful resolution — verify with a "hello world" first.
- **Tool schema serialization.** v1 SDK accepts Zod schemas or raw JSONSchema for `inputSchema`. Need to confirm which shape the SDK ships to clients (Claude Code reads the manifest); Zod via `zod-to-json-schema` is the typical path. If using Zod, pin a compatible version.
- **Race condition on `.state.json`.** Two MCP tool calls in flight simultaneously could last-write-wins. For POC, accepted — the agent serializes its calls in practice (sequential model output). Add `fcntl`-style locking only if a real-world race surfaces.
- **Template content authoring time.** 12 steps × 2 files = 24 markdown files. Anthill skills are dense (the `anthill-product-ideator/SKILL.md` is ~400 lines). Porting all 12 thoughtfully is a meaningful content-engineering investment; the end-to-end-first approach in § Approach mitigates by validating structure before doing the bulk of the content work.
- **Unknown: validation-mode declaration semantics for step 4.** Anthill required identical mode declared across artifacts in steps 02/03/04. Translating this to MCP shape: does `product_step_submit` for step 4 fail if the previous artifacts don't already declare a mode? POC simplification: declare mode on step 4 only, store in `.state.json.validation_mode`, no cross-step consistency enforcement. Revisit if real-world use shows the simpler shape misses bugs.
- **Unknown: `.state.json` placement during `product_start` when `docs/product/` doesn't exist.** Tool must `mkdir -p docs/product/` before writing. Verify the directory creation happens via Bun's `Bun.write` (which creates parents) or explicit `fs.mkdir(..., {recursive: true})`. Smoke-test on fresh fork to confirm.
- **Unknown: behavior when user activates MCP mid-conversation (without restart).** Claude Code's stated contract is that `.mcp.json` is loaded at SessionStart; mid-session changes don't reload. The READMEs all say "restart the session". POC accepts this; if Claude Code adds hot-reload later, the MCP doesn't change.
- **Sub-agent MCP-tool inheritance assumption.** Plan assumes sub-agents dispatched via `Agent` tool inherit the session's MCP tool surface (so they can call `product_step_get` / `product_step_submit` themselves). This matches Claude Code's documented behavior — MCPs register at session level, not per-agent — but the synthesis-step delegation pattern depends on it. **Mitigation:** the end-to-end smoke test (single delegation dry-run before content authoring) covers this explicitly; if the assumption breaks, the fallback is "parent agent calls MCP tools itself and passes content to sub-agent via the brief's CONTEXT field" — workable but doubles parent context cost. Worth confirming before scaling to all 12 templates.
- **Parent compliance with mode declarations.** The `mode` frontmatter is *advisory* — the MCP doesn't enforce that the parent delegates `synthesis` steps. A parent that ignores the mode and conducts every step inline still works correctly (just burns more context). Mitigation: the README + template prompt body restate the mode at the top of each step's content, so the parent agent reads "this is a synthesis step — consider delegation" naturally during step_get. No machine-enforced gate; same posture as `.claude/rules/delegation.md` (advisory model-discipline, not block).

## Research / citations

- `@modelcontextprotocol/sdk` npm metadata (probed 2026-05-12): `latest = 1.29.0`, modified `2026-03-30`, MIT-licensed, Node >= 18, type `module`, supports Bun + Deno + Node.
- `@modelcontextprotocol/server` npm metadata (probed 2026-05-12): `latest = 2.0.0-alpha.2` (v2 pre-stable; rejected for POC).
- MCP TypeScript SDK GitHub README (`main` branch, 2026-05-12): confirms v2 in development, v1 recommended for production, Standard Schema in v2, Zod-based in v1. URL: <https://github.com/modelcontextprotocol/typescript-sdk>.
- MCP v1 API docs: <https://ts.sdk.modelcontextprotocol.io/>.
- `/home/goat/anthill/.anthill/config/pipeline.yaml` — canonical 12-step structure (steps 1-12 lifted verbatim into `pipeline.ts`).
- `/home/goat/anthill/.claude/skills/anthill-product-ideator/SKILL.md`, `anthill-prd/SKILL.md`, `anthill-roadmap-bridge/SKILL.md`, `anthill-system-design-bridge/SKILL.md` — source content for templates.
- `/home/goat/anthill/.claude/rules/validation-mode.md` — validation-mode declaration semantics for step 4 (UX testing).
- Agent0 `docs/specs/012-mcp-recipes/` and `.mcp.json.example` — established `.mcp.json` activation pattern.
- Agent0 `docs/specs/016-harness-sync/` — confirms `packages/` is implicitly out of fork sync scope (manifest only enumerates `.claude/` + 4 explicit root files).
- Agent0 `site/package.json` + `site/bun.lock` — established "standalone Bun subdir" precedent (no root package.json, no workspaces).
- Agent0 `.claude/rules/research-before-proposing.md` — protocol followed for this plan (web fetch on npm registry + SDK README before locking on v1).
