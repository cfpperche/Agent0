# agent0-mcp-product-pipeline

A local MCP server that owns a 12-step product-planning pipeline — from raw idea to engineering-ready specification — with zero injection into the host project's Claude Code harness. Spec: [`docs/specs/025-mcp-product-pipeline/`](../../docs/specs/025-mcp-product-pipeline/).

## What it does

Lifts the Discovery (steps 1-4), Identity (steps 5-7), and Specification (steps 8-12) phases from the anthill SDLC and exposes them as 8 MCP tools. Activate it on a project, walk a product slug through the pipeline, end up with 12 markdown artifacts under `docs/product/<NN-name>/` ready to feed Agent0's `/sdd` for engineering execution.

The MCP is the **pipeline state machine**; your Agent0 session is the **interlocutor**. Disable the MCP and the markdown stays — pure plug-and-play.

## Activation

```bash
# 1. From the repo root, copy the example file (if .mcp.json doesn't exist yet)
cp .mcp.json.example .mcp.json

# 2. Open .mcp.json and REMOVE the `//` markers on the product-pipeline block:
#    "product-pipeline": {
#      "command": "bun",
#      "args": ["run", "packages/mcp-product-pipeline/src/server.ts"]
#    }

# 3. Restart your Claude Code session (.mcp.json is loaded at session start, not hot-reloaded)
```

After restart, the 8 `mcp__product-pipeline__product_*` tools appear in the agent's tool surface. No hook installed. No rule added. No skill copied. No CLAUDE.md change. The host harness is untouched.

**Compatibility note.** This is a local-path POC — the `args` reference `packages/mcp-product-pipeline/src/server.ts` relative to the project's cwd. It works ONLY when the host project has the `packages/mcp-product-pipeline/` subtree on disk — i.e. within the Agent0 repo itself, or a fork that has cloned it. Forks without `packages/` wait for the v2 publish path (see spec.md § non-goals). The activation pattern is the long-term contract; only the distribution mechanism shifts.

## Tool reference (8 tools)

| Tool | Input | Returns |
|---|---|---|
| `product_status` | — | full state from `docs/product/.state.json`, or `{empty: true}` if no pipeline |
| `product_start` | `slug: string` (kebab-case) | initialises state + creates `01-ideation/` dir |
| `product_step_get` | — | current step's `{mode, delegable, delegation_hint, prompt, schema, prior_artifacts}` |
| `product_step_submit` | `filename: string`, `content: string` | writes artifact OR rejects with `schema-incomplete` listing missing sections |
| `product_advance` | — | moves current step forward by 1; rejects with `gate-required` at phase boundaries (after steps 4, 7, 12) |
| `product_gate_pass` | `phase: "discovery" \| "identity" \| "specification"` | records the phase-boundary confirmation; idempotent |
| `product_done` | — | terminal summary with per-phase deliverables + literal `/sdd new <slug>` handoff |
| `product_get_delegation_brief` | `step_n: number` | pasteable 5-field handoff block for dispatching the step to a sub-agent via the `Agent` tool; rejects `not-delegable` if the step's mode is `interactive` |

All tools return JSON-wrapped text. Errors have shape `{isError: true, content: [{type: "text", text: JSON.stringify({code, hint, ...})}]}` so the agent can pattern-match.

## Per-step execution-mode map

The 12 steps are NOT uniformly delegable. Each template declares one of three modes in its YAML frontmatter, and the table below mirrors that source-of-truth.

| Step | Phase | Mode | Delegable | Parent's role |
|---|---|---|---|---|
| 01 ideation | Discovery | interactive | false | conducts 5-8 question discovery interview with founder |
| 02 prototype | Discovery | draft-after-input | partial | collects direction (entry surface / killer flow / complexity), then can delegate drafting |
| 03 spec | Discovery | synthesis | true | fully delegable — sub-agent synthesises from ideation |
| 04 ux-testing | Discovery | draft-after-input | partial | confirms validation_mode (tested / intuition / not-applicable) live; drafting delegates |
| 05 brand | Identity | interactive | false | conducts founder voice/vision interview |
| 06 design-system | Identity | synthesis | true | fully delegable — sub-agent derives from brand book |
| 07 prototype-v2 | Identity | synthesis | true | fully delegable — applies design-system to prototype |
| 08 prd | Specification | draft-after-input | partial | confirms priorities + success metric live; drafting delegates |
| 09 system-design | Specification | synthesis | true | fully delegable — pure derivation from PRD |
| 10 cost-estimate | Specification | draft-after-input | partial | confirms business model live; drafting delegates |
| 11 roadmap | Specification | draft-after-input | partial | confirms horizon + team shape; drafting delegates |
| 12 legal | Specification | synthesis | true | fully delegable — articulates legal posture (NOT legal advice) |

Roughly half the steps are fully delegable to a sub-agent via `product_get_delegation_brief`. This is the architectural payoff: synthesis-mode steps run entirely in sub-agent context (template + prior artifacts + draft never enter the parent's window), and the parent only sees a short return summary.

## Worked example — dispatching step 9 (system-design) to a sub-agent

```
1. Parent: product_get_delegation_brief({"step_n": 9})

   Returns a 5-field block:

   TASK: draft the system design — stack, services, data model, integrations, deployment topology — from the PRD; no user input required, pure synthesis
   CONTEXT: call product_step_get to receive the step 9 (system-design) template (prompt + schema). Prior artifacts to read for synthesis: docs/product/08-prd/prd.md, ... (others). The product-pipeline MCP exposes the same tool surface in your sub-agent context — you can call product_step_get and product_step_submit directly.
   CONSTRAINTS: do NOT interview the user (sub-agents have no user channel). Do NOT modify docs/product/.state.json by hand — only via the MCP tools. ...
   DELIVERABLE: an artifact file submitted via product_step_submit, landing under docs/product/09-system-design/.
   DONE_WHEN: product_step_submit returned success (no schema-incomplete error). ...

2. Parent dispatches via the Agent tool, pasting the brief verbatim as the prompt.

3. Sub-agent (fresh context): calls product_step_get(9), reads the prior artifacts,
   drafts the system-design.md, calls product_step_submit, returns a short summary
   to the parent ("written docs/product/09-system-design/system-design.md").

4. Parent calls product_advance to move to step 10.
```

## Output tree

When the pipeline is fully walked for a slug:

```
docs/
└── product/
    ├── .state.json              # pipeline index — slug, current_step, phase, completed, gates_passed, started_at
    ├── 01-ideation/
    │   └── <your-files>.md      # concept brief (required sections per template's schema.md)
    ├── 02-prototype/
    │   └── <your-files>.md      # prototype spec
    ├── 03-spec/
    │   └── <your-files>.md      # functional spec
    ├── 04-ux-testing/
    │   └── <your-files>.md      # validation report (contains validation_mode: line)
    ├── 05-brand/
    │   └── <your-files>.md      # brand book
    ├── 06-design-system/
    │   └── <your-files>.md      # design tokens + components
    ├── 07-prototype-v2/
    │   └── <your-files>.md      # branded prototype spec
    ├── 08-prd/
    │   └── <your-files>.md      # PRD
    ├── 09-system-design/
    │   └── <your-files>.md      # system design
    ├── 10-cost-estimate/
    │   └── <your-files>.md      # cost + revenue model
    ├── 11-roadmap/
    │   └── <your-files>.md      # phased roadmap + v2 vision
    └── 12-legal/
        └── <your-files>.md      # legal posture (briefing for counsel)
```

`docs/product/` is git-tracked design memory (NOT gitignored). When the pipeline closes, all 12 dirs are populated.

## Deactivation

```bash
# 1. Open .mcp.json and re-comment the product-pipeline block (re-add `//` markers).
# 2. Restart Claude Code.
```

After restart, the `product_*` tools are absent. `docs/product/` stays — readable, diffable, useful as input to whatever comes next.

## /sdd handoff at completion

When `product_advance` is called after step 12 has been submitted and `product_gate_pass("specification")` has been confirmed, it returns:

```json
{
  "code": "pipeline-complete",
  "slug": "<your-slug>",
  "message": "Product planning complete. Engineering execution starts via /sdd new <feature-slug> populating docs/specs/NNN-*/.",
  "next_action": "call product_done for the full handoff summary"
}
```

`product_done` then returns a structured summary naming the deliverables per phase and the literal command:

```
/sdd new <your-slug>
```

The user runs that command and Agent0's `/sdd` workflow (see `.claude/rules/spec-driven.md`) scaffolds `docs/specs/NNN-<slug>/{spec,plan,tasks}.md` to drive engineering execution. The MCP can be deactivated at this point — the planning phase is closed.

## Development

```bash
cd packages/mcp-product-pipeline
bun install         # one-time
bun test            # run unit tests (state.ts + templates.ts)
bun run typecheck   # tsc --noEmit
bun run start       # boot the stdio MCP server manually (mostly for debugging)
```

## Implementation map

| File | Responsibility |
|---|---|
| `src/server.ts` | stdio MCP server boot + `McpServer` instantiation |
| `src/tools.ts` | 8 `product_*` handlers + `registerAllTools` |
| `src/pipeline.ts` | 12-step constant registry + `ExecutionMode`/`Phase` types + gate helpers |
| `src/state.ts` | atomic `.state.json` I/O (mktemp + rename, UUID-suffixed tmp) |
| `src/templates.ts` | YAML-lite frontmatter parser + `getTemplate(n)` |
| `src/paths.ts` | cwd-relative artifact paths vs `import.meta.url`-relative template paths |
| `src/templates/<NN-name>/prompt.md` | per-step prompt content (frontmatter: mode + delegable + delegation_hint) |
| `src/templates/<NN-name>/schema.md` | per-step required-section list |
| `tests/state.test.ts` | state I/O unit tests (18 tests) |
| `tests/templates.test.ts` | frontmatter parser unit tests (12 tests) |

## Non-goals (v1)

- npm publication — POC uses local-path. Distribution shape is the most-likely-to-change part of the design.
- Steps 13-20 (delivery + post-launch) — separate MCP later. Post-launch is event-driven, not sequential.
- Multi-product support — 1 fork = 1 product. `.state.json` rejects re-init with a different slug.
- Migration from anthill `docs/sdlc/` — starts fresh; manual copy if seeding from prior content.
- SOUL.md personas / agent role-playing — Agent0 conducts every step in its default voice.

See [`docs/specs/025-mcp-product-pipeline/spec.md`](../../docs/specs/025-mcp-product-pipeline/spec.md) for full non-goals.

## License

Same as Agent0. Apache 2.0 (when Agent0 publishes) — see repo root `LICENSE` once present.
