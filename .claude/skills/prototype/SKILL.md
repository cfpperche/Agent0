---
name: prototype
description: Agile frontend to the 13-step mcp-product-pipeline. Covers ALL planning steps (ideation / spec / UX audit / brand / design system / PRD / system design / cost / roadmap / legal) PLUS the 3 prototype passes (v1 mood + killer flow / v2 brand-tuned / v3 PRD-coverage atlas) in fluid agile mode at a single "standard" depth tier. Output is a complete monorepo at user-specified path with all 13 pipeline artifacts. 4 phases - Discovery / Identity / Specification / Synthesis - with 3 condensed AskUserQuestion gates between them. Standalone (no MCP runtime dep, templates bundled). Flags - `<idea>` `--stack=<next|expo>` `--out=<path>` `--from-step=NN` `--skip-prd` `--skip-brand`. See `.claude/skills/prototype/references/{pipeline-coverage,state-machine,delegation-briefs,quality-checklist}.md`. Supersedes spec 034's v1 (sitemap-only scope).
license: MIT
compatibility: Designed for Claude Code. Body references `.claude/` conventional paths, dispatches Agent tool with 5-field handoffs (delegation-gate), uses AskUserQuestion at phase gates, optionally uses Playwright MCP for screenshots. Not portable to runtimes that lack these surfaces.
metadata:
  agent0-portability-tier: cc-native
  version: "2.0"
argument-hint: "<idea>" --out=<path> [--stack=<next|expo>] [--from-step=NN] [--skip-prd] [--skip-brand]
---

# /prototype — 13-step agile frontend

Takes a founder's one-line idea and produces a complete v1-ready product package at `<--out>`: concept brief, mood + killer-flow prototype, functional spec, UX audit, brand book, design system, brand-tuned prototype, PRD, system design, cost estimate, roadmap, legal posture, full PRD-coverage screen atlas. Agile counterpart to `mcp-product-pipeline` — same artifacts, lighter calibration ("standard" tier), fluid 4-phase shape with 3 condensed user gates instead of the heavy pipeline's 3 Layer-3 checkpoints.

**v2 of spec 034** — see `docs/specs/036-prototype-skill-refactor/` for the refactor rationale. The v1 (sitemap + tokens + screens only, no planning artifacts) is superseded.

**Required reading before execution:**
- `references/pipeline-coverage.md` — what each of the 13 steps produces at standard tier
- `references/state-machine.md` — `.state.json` shape + phase/step progression + resume support
- `references/delegation-briefs.md` — 5-field briefs for all 14 sub-agent dispatches (13 step-specific + 1 per-stack screen-writer)
- `references/quality-checklist.md` — per-step gate criteria the skill checks before declaring a step complete

## Argument parsing

User invokes as `/prototype "<idea>" --out=<path> [flags]`. The raw argument string is `$ARGUMENTS`. Parse it yourself:

1. First quoted-token is `<idea>` — refuse with `usage: /prototype "<idea>" --out=<path> [flags]` if missing.
2. `--out=<path>` is REQUIRED — refuse if missing. Resolve to absolute path.
3. Optional flags (any order after idea): `--stack=<name>` (next | expo; default: web stack inferred from idea → next), `--from-step=NN` (resume from step N), `--skip-prd` (omit Step 08 dispatch — degenerate; not recommended), `--skip-brand` (omit Step 05 + fall back to `templates/default-tokens.css`).
4. Compute `slug` = kebab-case from idea (lowercase, alphanumeric + hyphens, max 40 chars).

## Phase 0 — Setup + idempotency check + resume detection

1. **Idempotency check** — if `<out>` exists and is non-empty:
   - If `--from-step=NN` was passed AND `<out>/.state.json` exists: read state, validate `slug`/`idea`/`flags.stack` match the invocation; if mismatch, abort with `state mismatch — clear --out dir or pick different --from-step`. If match, jump to step NN.
   - Else (no `--from-step` OR no `.state.json`): prompt `<out> exists and is non-empty. Overwrite? (y/N) ▷`. On `y` → `rm -r <out>` (NOT `rm -rf` — governance-gate blocks combined flags). On `n` / no answer → abort cleanly with `aborted; pick a different --out or rm the existing dir yourself`. Exit 0.
2. **Init** — `mkdir -p <out>`; write fresh `<out>/.state.json` per `state-machine.md` v2 shape with `phase=0, step=0, started_at=<ISO>, gates_passed=[], completed_steps=[], blocked_steps=[], iterations={discovery:0, identity:0, specification:0}, completed_at=null`.

## Phase 1 — Discovery (pipeline steps 01-04)

**Read `references/delegation-briefs.md` § "Phase 1 — Discovery" BEFORE dispatching.** Each Agent call uses the 5-field template there.

1. **Step 01 — Ideation** (BLOCKING) — dispatch Sub-agent A per § Step 01 brief. **model: opus.** Returns `<out>/concept-brief.md`. If BLOCKED: ABORT the entire run (Step 01 feeds everything downstream).
2. **Steps 02 + 03 + 04 — parallel fan-out** — once Step 01 returns, dispatch THREE sub-agents in ONE MESSAGE (parallel tool calls) per the § Step 02 / 03 / 04 briefs. All `sonnet`. Worked example shape:
   ```
   <single message with 3 Agent tool calls>:
     Agent(brief = Step 02 direction-writer, model=sonnet)
     Agent(brief = Step 03 spec-writer, model=sonnet)
     Agent(brief = Step 04 audit-writer, model=sonnet)
   ```
   Awaiting all 3 returns is a single conversational beat (not 3 round-trips). Note: Step 02 additionally fans out N per-route screen-writers (cap=5) for killer-flow screens — those dispatch INSIDE Step 02 from a sub-orchestrator pattern.
3. **Update `.state.json`** — append to `completed_steps`; any BLOCKED to `blocked_steps`.
4. **Gate** — `AskUserQuestion` with 3 options:
   - `continue` → proceed to Phase 2 (append `discovery` to `gates_passed`).
   - `iterate` → user names which step(s) to re-dispatch (sub-prompt). Re-dispatches with augmented brief. Increment `iterations.discovery`. Re-gate after.
   - `abort` → exit cleanly; set `flags.from_step = current_step`; print resume command.

## Phase 2 — Identity (pipeline steps 05-07)

Steps run STRICTLY SERIAL (each depends on the prior):

1. **Step 05 — Brand book.** Dispatch per § Step 05 brief. Returns `<out>/brand-book.md`. If `--skip-brand`: skip dispatch, `cp templates/default-tokens.css <out>/tokens.css` + write minimal `<out>/brand-voice.md` with neutral tone.
2. **Step 06 — Design system.** Dispatch per § Step 06 brief. Reads brand-book + audit findings (Step 04). Returns 3 files: `tokens.css`, `components.md`, `design-system.md`.
3. **Step 07 — Prototype v2.** Dispatch direction-final writer (Sub-agent (a)) per § Step 07 brief. Then dispatch N screen re-writers (Sub-agent (b)) per § Per-stack screen-writer in PARALLEL (cap=5), one per route from Step 02's sitemap. Inheritance discipline: same N + same filenames + same flow as Step 02; the v2 pass APPLIES brand + tokens + audit fixes to identical structure.
4. **Update `.state.json`**.
5. **Gate** — `AskUserQuestion` (same shape as Phase 1).

## Phase 3 — Specification (pipeline steps 08-12)

1. **Step 08 — PRD** (BLOCKING; downstream depends on US-NN inventory). Dispatch per § Step 08. Returns `<out>/prd.md`.
2. **Steps 09 + 10 + 11 + 12 — parallel fan-out** — once Step 08 returns, dispatch FOUR sub-agents in ONE MESSAGE per § Step 09-12 briefs. All sonnet. (Step 10 nominally depends on Step 09 in heavy pipeline; standard tier relaxes — sub-agents read system-design draft from `<out>` if present, fall back gracefully if Step 09 is still running.)
3. **Update `.state.json`**.
4. **Gate** — `AskUserQuestion`.

## Phase 4 — Synthesis (pipeline step 13)

NO GATE — Phase 4 closes the pipeline; the `/sdd new <slug>` handoff is the implicit "next" gate.

1. **Step 13 — Atlas writer** (Sub-agent (a)) — dispatch per § Step 13. Returns `<out>/screen-atlas.md` with PRD coverage matrix + design-fidelity scores + states-coverage matrix.
2. **Step 13 — Per-route screen writers** (Sub-agent (b)) — dispatch N screen-writers in parallel (cap=5) per § Per-stack screen-writer. N = full PRD coverage at standard tier (killer-flow + 1 edge-state minimum; legal-mandatory surfaces from Step 12 net-new at Step 13).
3. **Stitch step — wire token import + verify.** Stack-specific:
   - **Next.js:** Verify `<out>/app/globals.css` contains the token import via strict regex: `grep -qE '^@import.*tokens\.css' <out>/app/globals.css`. The bundled `templates/monorepo-skeleton/next/app/globals.css` SHIPS this line as line 1 — if missing (e.g. user edited template), prepend it via `sed -i '1i @import "../tokens.css";' <out>/app/globals.css`. DO NOT use the v1 loose-substring `grep -q 'tokens.css'` (matched comments, gave false-positive — root cause of 2026-05-17 dogfood render-raw bug).
   - **Expo:** Tokens consumed via `tailwind.config.js` → no inline import needed.
4. **Build verification:**
   - Install verification: `cd <out> && pnpm install --frozen-lockfile` (next) or `bun install` (expo). MUST include OVERRIDE marker for supply-chain hook:
     ```
     # OVERRIDE: /prototype Phase 4 build verification — bundled-template install per spec 036
     cd <out> && pnpm install --frozen-lockfile
     ```
   - Typecheck: `cd <out> && node_modules/.bin/tsc --noEmit` (direct bin path; pnpm v11 deps-status can block `pnpm typecheck`).
   - Lint: `cd <out> && node_modules/.bin/biome check .` (same reason).
   - Capture per-step exit codes + durations for REPORT.md `## Build health` section. Do NOT fail the build on typecheck/lint non-zero — record and continue (founder can iterate).
5. **Author REPORT.md inline.** Read `templates/report.md.tmpl`, substitute placeholders from `.state.json` + Phase outputs. See `quality-checklist.md` for the per-step gate criteria scoring.

## Phase 5 — Handoff message

Print to chat:

```
Prototype ready at <out>/.

  Pipeline coverage: 13/13 steps completed (or N/13 if any BLOCKED — see REPORT.md § Blocked steps).
  Run: cd <out> && pnpm dev   (open http://localhost:3000)
  Report: <out>/REPORT.md
  Concept brief: <out>/concept-brief.md
  PRD: <out>/prd.md
  Atlas: <out>/screen-atlas.md

  Phase wall-clock: <total elapsed from started_at to completed_at>
  Gate iterations: discovery=<n> identity=<n> specification=<n>

  Engineering handoff: /sdd new <slug>
```

Then update `<out>/.state.json` with `completed_at` ISO timestamp.

## Worked example — parallel dispatch in a single message

Phase 1 Step 02+03+04 (and Phase 3 Step 09+10+11+12) require a SINGLE message with N parallel Agent tool calls. The Agent tool returns N results bundled into one tool-result block — not N round-trips through the user. Example (3 calls):

```
[single assistant message with three <tool_use> blocks]:
  <tool_use name="Agent" id="A1">
    subagent_type: general-purpose
    model: sonnet
    description: Step 02 — direction-writer
    prompt: <TASK + CONTEXT + CONSTRAINTS + DELIVERABLE + DONE_WHEN per delegation-briefs.md § Step 02>
  </tool_use>
  <tool_use name="Agent" id="A2">
    subagent_type: general-purpose
    model: sonnet
    description: Step 03 — spec-writer
    prompt: <... per § Step 03>
  </tool_use>
  <tool_use name="Agent" id="A3">
    subagent_type: general-purpose
    model: sonnet
    description: Step 04 — audit-writer
    prompt: <... per § Step 04>
  </tool_use>
```

Dispatching the three serially (one Agent call per message, awaiting each in turn) is a v1 orchestration bug, NOT v2 behaviour. Wall-time penalty alone (~3x) makes this critical to enforce.

## Unknown / extra subcommand

This skill does not have subcommands beyond the initial invocation. If `$ARGUMENTS` starts with an unrecognized token (not a quoted idea and not a flag), refuse with the usage hint:

```
/prototype "<idea>" --out=<path> [--stack=<name>] [--from-step=NN] [--skip-prd] [--skip-brand]
```

## Notes

- **Spec 033 compliance is non-skippable.** Run `bash .claude/skills/skill/scripts/validate.sh .claude/skills/prototype` before commit; exit 0 required.
- **Validator scope is REPO-WIDE, not per-edited-file.** The post-edit validator (delegation-gate hook) runs Biome over the WHOLE prototype dir, not just the sub-agent's edited file — one bad Biome format error blocks ALL subsequent sub-agents until cleaned. **Mitigation:** the orchestrator runs `node_modules/.bin/biome check --write .` (parent-side) between Phase 3 and Phase 4 batches as a one-pass fixer. (Dogfood finding #4, 2026-05-17.)
- **Concurrency cap 5** for screen-writer fan-outs (Steps 02 / 07 / 13). Proven non-OOM on 17-route dogfood. Re-evaluate if Phase 4 with 12+ atlas screens surfaces context pressure.
- **Output dir is `--out=<path>`**, NOT hardcoded `/tmp/`. v1 hardcoded `/tmp/prototype-<slug>/` made `gh repo create --source=.` flow awkward. v2 lets the founder scaffold-direct-to-target.
- **No MCP product-pipeline calls.** v2 is standalone — bundled templates at `templates/pipeline/01-ideation/` … `13-prototype-v3/` (copied verbatim from `packages/mcp-product-pipeline/src/templates/` at 2026-05-18). Quarterly REMINDERS check for drift sync (see REMINDERS.md).
- **`--skip-prd` is degenerate.** PRD feeds Steps 09-13 (system-design references US-NN; atlas's coverage matrix depends on PRD inventory). Skipping it produces a partial pipeline with downstream gaps marked in REPORT.md. Not recommended for real founders; useful for dev iteration only.
- **OD vendor index at `references/od-catalog-index.json`** snapshot from 2026-05-18 (72 vendors). Step 06 design-system brief reads this to pick 1-2 catalog vendors. Full per-vendor `DESIGN.md` files are NOT bundled (size budget) — Step 06 brief reads them from `packages/mcp-product-pipeline/design-systems/<vendor>/DESIGN.md` if the package is present; falls back to mood-only inheritance if absent.
- **Spec 034 superseded.** Set its `**Status:**` line to `superseded by 036-prototype-skill-refactor` after v2 ships.
