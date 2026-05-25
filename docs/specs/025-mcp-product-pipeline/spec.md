# 025 — mcp-product-pipeline

_Created 2026-05-12._

**Status:** shipped

## Intent

A local MCP server (`packages/mcp-product-pipeline/`) that owns a 12-step product-planning pipeline — from raw idea to engineering-ready specification — without injecting anything into the Agent0 harness of the fork that activates it. The pipeline lifts the Discovery (steps 1-4), Identity (steps 5-7), and Specification (steps 8-12) phases from the anthill SDLC, drops the post-launch + delivery phases (separate MCP later, different shape: event-driven not sequential), and hands off cleanly to Agent0's `/sdd` once step 12 (legal) closes. The MCP is the **pipeline state machine**; Agent0 stays the **interlocutor** that translates user intent into tool calls.

The activation surface is a single block in `.mcp.json` (copy from `.mcp.json.example`, uncomment, restart session). Zero hooks installed, zero rules added, zero skills copied, zero CLAUDE.md mutations. Deactivation is the inverse: comment the block, restart. Artifacts written to `docs/product/01-ideation/` through `docs/product/12-legal/` (chosen layout — `docs/sdlc/` rejected because "SDLC" overpromises and collides semantically with `docs/specs/`, which is engineering territory the `/sdd` handoff will populate post-step-12). The state file `docs/product/.state.json` is git-tracked design memory, same posture as `docs/specs/NNN-*/`.

This is the proof-of-concept for the larger thesis: **Agent0 stays a thin harness core; capability extensions ship as opt-in MCP servers in `packages/`**. The harness-sync manifest already excludes everything outside `.claude/`, `.githooks/`, `.gitignore`, `.gitleaks.toml`, `CLAUDE.md`, `.mcp.json.example` — so a `packages/` subtree naturally stays out of forks; only the example `.mcp.json` block reaches them. If the pattern proves out, the next MCP (post-launch loops, founder-coach personas, others) follows the same shape with near-zero marginal harness cost.

## Acceptance criteria

- [ ] **Scenario: plug-and-play activation in a fresh fork**
  - **Given** a fork of Agent0 with no `.mcp.json` configured, and the user wants to start a new project's planning pipeline
  - **When** the user runs `cp .mcp.json.example .mcp.json`, uncomments the `product-pipeline` block, and restarts the Claude Code session
  - **Then** the Agent0 session has `product_*` MCP tools available; no file under `.claude/` of the fork was modified or created by the activation; no entry was added to `.claude/settings.json`

- [ ] **Scenario: pipeline cold-start and first-step orientation**
  - **Given** an activated MCP, empty `docs/product/`, and the user telling Agent0 "vamos planejar um clone de TikTok"
  - **When** Agent0 calls `product_status` (returns empty), then `product_start("tiktok-clone")`, then `product_step_get`
  - **Then** `docs/product/.state.json` exists with `{slug:"tiktok-clone", current_step:1, phase:"discovery", completed:[], gates_passed:[]}`; `product_step_get` returns the ideation step's intent + guide questions + output schema; the agent has enough structure to conduct the interview without further MCP queries

- [ ] **Scenario: linear progression through all 12 steps**
  - **Given** an active pipeline for slug `tiktok-clone`
  - **When** the agent walks steps 1→12 in order, calling `product_step_submit` then `product_advance` per step, and `product_gate_pass` at each phase boundary (after steps 4, 7, 12)
  - **Then** `docs/product/01-ideation/` through `docs/product/12-legal/` each contain the submitted artifact(s) as markdown; `.state.json` records `completed:[1..12]` and `gates_passed:["discovery","identity","specification"]`; the final `product_advance` after step 12 returns a "pipeline-complete" signal with the canonical handoff message naming `/sdd` as the next phase

- [ ] **Scenario: resumability across sessions**
  - **Given** a pipeline paused mid-step-5 (brand) — `.state.json` says `current_step:5, completed:[1,2,3,4], gates_passed:["discovery"]` — and the Claude Code session has been closed and reopened
  - **When** the agent calls `product_status` after the user says "continuar de onde paramos"
  - **Then** the MCP reports current step 5, lists steps 1-4 as completed, lists `discovery` as passed and `identity`/`specification` as pending; `product_step_get` returns step 5's prompt without any reference to having "lost context"

- [ ] **Scenario: phase-gate enforcement**
  - **Given** steps 1-4 are completed but `product_gate_pass("discovery")` has not been called
  - **When** the agent calls `product_advance` (expecting to move into step 5)
  - **Then** the MCP returns a structured error `{code:"gate-required", phase:"discovery→identity", hint:"call product_gate_pass('discovery') with explicit user confirmation"}`; `.state.json` is unchanged; no step-5 artifact is created

- [ ] **Scenario: step submission validates required shape**
  - **Given** the pipeline is at step 1 (ideation) and the expected output schema requires sections `[concept, target_audience, differentiation, risks]`
  - **When** the agent calls `product_step_submit` with a markdown body missing the `risks` section
  - **Then** the MCP returns `{code:"schema-incomplete", missing:["risks"]}`; no file is written under `docs/product/01-ideation/`; the agent can fix the draft and retry

- [ ] **Scenario: clean uninstall preserves artifacts**
  - **Given** a pipeline completed up to step 12 with full artifacts under `docs/product/`
  - **When** the user comments the `product-pipeline` block in `.mcp.json` and restarts the session
  - **Then** `docs/product/` and all 12 step directories remain on disk and human-readable; no Agent0 functionality is broken; `product_*` tools are absent from the session

- [ ] **Scenario: handoff to `/sdd` at pipeline completion**
  - **Given** step 12 (legal) has just been submitted and `product_advance` reports pipeline-complete
  - **When** the agent surfaces the completion message to the user
  - **Then** the message names the deliverables (one short bullet per phase: discovery / identity / specification with paths) AND explicitly says "the planning phase is closed; engineering execution starts via `/sdd new <feature-slug>` populating `docs/specs/NNN-*/`"; the user has zero ambiguity about what comes next

- [ ] **Scenario: delegation-ready brief for synthesis steps**
  - **Given** the pipeline is at a `synthesis`-mode step (e.g. step 9, system-design) where the agent intends to delegate the work to a sub-agent via the `Agent` tool to preserve parent context
  - **When** the agent calls `product_get_delegation_brief(9)` before issuing the `Agent` dispatch
  - **Then** the MCP returns a complete 5-field handoff block (TASK / CONTEXT / CONSTRAINTS / DELIVERABLE / DONE_WHEN) referencing `product_step_get`, prior artifacts under `docs/product/`, and `product_step_submit` — ready to paste into the `Agent` prompt without further composition; the brief reflects the step's `mode` and `delegation_hint` declared in the template frontmatter

- [ ] `packages/mcp-product-pipeline/` exists with `package.json`, `src/server.ts` (stdio MCP via `@modelcontextprotocol/sdk`), `src/state.ts` (state file I/O), `src/templates/<NN-name>/` for each of the 12 steps containing at least `prompt.md` (frontmatter with `mode` + `delegable` + `delegation_hint`, followed by step intent + guide questions) and `schema.md` (output shape)
- [ ] `pnpm-workspace.yaml` at repo root declares `packages/*` as workspaces (enables future MCPs without restructuring)
- [ ] `.mcp.json.example` ships a commented `product-pipeline` block pointing at the local-path `bun run packages/mcp-product-pipeline/src/server.ts` invocation with a 2-3 line header comment explaining activation + deactivation
- [ ] `packages/mcp-product-pipeline/README.md` documents: activation workflow (the cp+uncomment+restart triple), tool reference (all 8 tools with one-line descriptions), the per-step `mode` table (interactive / draft-after-input / synthesis) showing which steps the parent agent should delegate vs conduct directly, expected `docs/product/` output tree, deactivation, and the `/sdd` handoff at completion
- [ ] `.gitignore` does NOT ignore `docs/product/` or `docs/product/.state.json` (artifacts are git-tracked design memory)
- [ ] The harness-sync manifest is NOT extended — `packages/`, `pnpm-workspace.yaml`, and `docs/product/` (when present in a fork) do not appear in `sync-harness.sh`'s `COPY_CHECK_*` arrays

## Non-goals

- **Steps 13-20 of the anthill SDLC.** Delivery (13-17: delivery-plan, qa, security, gtm + cross-cutting) is execution territory — Agent0 + `/sdd` already covers this. Post-launch (18-20: metrics, iteration, learning) is event-driven (reaction to telemetry / churn / feedback), not sequential — fundamentally different shape, deserves its own MCP later. Not a regression to drop these here; the pipeline ends where pure planning ends.
- **`@anthropic-ai/claude-code` plugin integration.** This MCP is plain stdio MCP, consumed by any MCP-aware host. We do NOT ship a `.claude-plugin/plugin.json` manifest in this iteration. Marketplace listing is deferred.
- **npm publication.** POC ships local-path invocation in `.mcp.json.example` (`bun run /abs/path/packages/mcp-product-pipeline/src/server.ts`). `npx -y github:...` and `npm publish` are follow-ups when the surface stabilizes.
- **Multi-product support in one repo.** v1 assumes 1 fork = 1 product (single slug). The `.state.json` schema reserves the slug field but the MCP rejects `product_start` if a state file already exists with a different slug. Multi-slug is a v2 question if a real-world fork hits it.
- **Migration from anthill `docs/sdlc/` trees.** A fork that has prior anthill output gets no auto-migration. The MCP starts fresh; manual copy is the path if the user wants to seed initial content.
- **Meeting-file gates.** Anthill required `.anthill/memory/meetings/<gate>-*.md` files for phase transitions. POC simplifies: `product_gate_pass(phase)` is a single tool call the agent makes after explicit user confirmation. The audit trail is `.state.json` itself plus the agent's natural-language record in the conversation.
- **SOUL.md personas / agent role-playing.** Anthill's "CEO / CMO / CTO" persona machinery is out of scope. The Agent0 base agent conducts every step in its default voice; specialized personas can come from a different MCP later if proven valuable.
- **Anything inside `.claude/`.** No hooks, no rules, no skills, no settings.json mutation, no CLAUDE.md section. The fork's harness is untouched. The MCP communicates exclusively through its tools.
- **Capacity catalog entry on the public landing page (spec 024).** The landing page advertises the harness core capacities. MCPs in `packages/` are a different layer (opt-in extensions); they get their own surface treatment later if/when the pattern proves out.
- **Auto-detection / SessionStart hint.** Spec 012's `mcp-recipes-hint.sh` will NOT be extended to detect `docs/product/` and suggest activating this MCP. Activation stays a deliberate user action — the recipe is in `.mcp.json.example` and `packages/mcp-product-pipeline/README.md`, that's it.

## Open questions

- [ ] **Q1: Should `docs/product/.state.json` be human-editable, or owned by the MCP?** Default-resolution: human-readable JSON, no checksum/seal; the MCP re-reads on every call and tolerates manual edits (e.g. user manually un-completes a step). The state IS the filesystem contents (the markdown artifacts) — `.state.json` is just a fast index. Worst case of manual edit corruption: MCP returns a clear error rather than crashing.

- [ ] **Q2: Template content — port verbatim from anthill skills, or rewrite from scratch?** The anthill skills (`anthill-product-ideator`, `anthill-prd`, `anthill-roadmap-bridge`, etc.) are well-tuned prompts with checklists, schemas, citation rules. Porting verbatim is faster and inherits the discipline; rewriting decouples Agent0 from anthill's voice. Default-resolution: port the structural parts (sections, checklists, schemas) verbatim, but rewrite the prose/voice to match Agent0's terser style. Both anthill and Agent0 are Apache 2.0 / similar-permissive so no licensing block.

- [ ] **Q3: How explicit is the `/sdd` handoff message at step 12 completion?** Default-resolution: include in the completion response a structured suggestion the agent can mostly echo to the user — exact paths of artifacts produced, plus the literal next-step command (`/sdd new <slug-derived-from-product-name>`). Avoids ambiguity about whether the agent should keep going or stop.

## Context / references

- `/home/goat/anthill/` — source of the 12-step pipeline structure, skill templates, and the "harness as plugin" approach that proved too heavy and motivated this redesign.
- `/home/goat/anthill/.anthill/config/pipeline.yaml` — canonical 20-step registry; the first 12 entries are the scope of this spec.
- `/home/goat/anthill/.claude/skills/anthill-product-ideator/`, `anthill-prd/`, `anthill-roadmap-bridge/`, `anthill-system-design-bridge/`, `anthill-feature-refiner/` — source templates for steps 1, 8, 11, 9, and refinement-shaped helpers respectively.
- `docs/specs/012-mcp-recipes/` — established the `.mcp.json.example` activation pattern this MCP slots into.
- `docs/specs/016-harness-sync/` — establishes that `packages/` stays out of fork sync scope; this spec validates the assumption.
- `docs/specs/024-public-landing/` — recent reference for monorepo subtree pattern (`site/` for landing, now `packages/mcp-product-pipeline/` for first MCP).
- `.claude/rules/mcp-recipes.md` — the activation workflow doc the README will mirror in shape.
- `.claude/rules/spec-driven.md` — the `/sdd` handoff convention at pipeline completion.
- Model Context Protocol TypeScript SDK: https://github.com/modelcontextprotocol/typescript-sdk — primary dependency for `src/server.ts`.
