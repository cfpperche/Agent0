---
name: prototype
description: Hi-fi prototype generator. Use when the user types `/prototype "<idea>"` and wants a working, monorepo-scaffolded, stack-native prototype (NOT HTML mockups) at /tmp/prototype-<slug>/ — real Next.js or Expo code that compiles and runs. Agile counterpart to the 15-step mcp-product-pipeline. ≤5 discovery questions, 4 parallel sub-agents in Phase 2, per-route sub-agents (cap 5 concurrent) in Phase 3, REPORT.md authored inline in Phase 4. Flags - `--stack=<name>` (next|expo), `--skip-prd`, `--skip-brand`. See `.claude/skills/prototype/references/` for sitemap-schema, stack-defaults, quality-checklist, delegation-briefs.
license: MIT
compatibility: Designed for Claude Code. Body references `.claude/` conventional paths, dispatches Agent tool with 5-field handoffs (delegation-gate), optionally uses Playwright MCP for screenshots. Not portable to runtimes that lack these surfaces.
metadata:
  agent0-portability-tier: cc-native
  version: "0.1"
argument-hint: "<idea>" [--stack=<name>] [--skip-prd] [--skip-brand]
---

# /prototype — hi-fi prototype generator

Takes a founder's one-line product idea and produces a working monorepo-scaffolded hi-fi prototype at `/tmp/prototype-<slug>/`. Real code in the chosen stack (Next.js 16 or Expo SDK 55) — not HTML mockups. The agile counterpart to the 15-step `mcp-product-pipeline`: same quality bar on artifacts that matter (sitemap completeness, design fidelity, brand voice, states coverage) but parallelized execution and minimal ceremony.

See spec `docs/specs/034-prototype-skill/` for the rationale. See `references/` files for: `stack-defaults.md` (versions + scaffold facts), `sitemap-schema.md` (sitemap.yaml shape), `quality-checklist.md` (4-dim fidelity rubric + states matrix), `delegation-briefs.md` (5-field templates for every subagent dispatch — required reading before Phase 2).

## Argument parsing

User invokes as `/prototype "<idea>" [flags]`. The raw argument string is `$ARGUMENTS`. Parse it yourself:

1. First token after `prototype` is the quoted `<idea>` — refuse with `usage: /prototype "<idea>" [flags]` if missing or empty after quote-strip.
2. Optional flags (any order after idea): `--stack=<name>` where name ∈ {next, expo}; `--skip-prd`; `--skip-brand`.
3. Compute `slug` = kebab-case derived from idea (lowercase, alphanumeric + hyphens, max 40 chars, trim leading/trailing hyphens). Example: `"linear-clone for SMB SaaS"` → `linear-clone-for-smb-saas`.

## Phase 0 — Setup + idempotency check

1. If `/tmp/prototype-<slug>/` already exists: prompt user `prototype-<slug> already exists at /tmp/. Overwrite? (y/N)`. On `n` or no answer, abort with `aborted; rename via different idea or wait for current state to be saved`. On `y`, run `rm -r /tmp/prototype-<slug>` (NOT `rm -rf` — governance-gate blocks the combined flags per spec 001).
2. Create the prototype dir: `mkdir -p /tmp/prototype-<slug>`.
3. Initialize a tiny state file at `/tmp/prototype-<slug>/.state.json` with `{slug, idea, flags, phase: 0, started_at: <ISO>}` so resumability is possible if a phase blocks (not required for v1; future hook).

## Phase 1 — Discovery (≤5 questions)

**Read `.claude/skills/prototype/references/stack-defaults.md` BEFORE asking platform/stack questions** — recommendations must reference the file's per-platform-target table.

For each question, state an opinionated default; founder confirms/overrides. Skip questions whose answer is obvious from the idea, OR whose flag was supplied. Use the `AskUserQuestion` tool to surface options when interactive.

1. **Platform target** — web / mobile / desktop / CLI / multi. Default heuristic: "linear-clone" / "SaaS" / "dashboard" → web; "tracker" / "scanner" / "tap-to-X" → mobile. Skip if `--stack=` set (stack implies platform: next → web; expo → mobile).
2. **Frontend stack** — read recommendation from `stack-defaults.md` § Recommendation by platform target. Default: web → "Next.js 16 + React 19 + Tailwind 4 + Biome"; mobile → "Expo SDK 55 + React Native + expo-router + NativeWind". Skip if `--stack=` set.
3. **Backend / data layer** — none / local-storage / SQLite / Postgres+API. Default: none (prototype-only, mock data inline). Skip if obvious from idea.
4. **Auth shape** — none / local / OAuth / magic-link. Default: none. Skip if obvious from idea.
5. **Persona + product class** — ask for a 1-sentence persona + product class (Micro / Mobile / Dev Tool / SMB SaaS / Venture). Required for screen-count calibration per `sitemap-schema.md` Rule 7.

Record answers in `.state.json` before proceeding.

## Phase 2 — Parallel scaffold (4 sub-agents)

**Read `.claude/skills/prototype/references/delegation-briefs.md` BEFORE dispatching.** Each Agent call MUST use the 5-field template there (TASK / CONTEXT / CONSTRAINTS / DELIVERABLE / DONE_WHEN) — the delegation-gate hook returns exit 2 otherwise.

Dispatch ALL FOUR in a single message (parallel tool calls):

- **Subagent A — Sitemap generator** (subagent_type: general-purpose, model: sonnet). Brief substituted from `delegation-briefs.md` § Phase 2 — Subagent A. Returns `/tmp/prototype-<slug>/sitemap.yaml`.
- **Subagent B — Brand + tokens** (subagent_type: general-purpose, model: sonnet). Brief substituted. Returns `/tmp/prototype-<slug>/tokens.css` + `brand-voice.md`. If `--skip-brand`, cp `.claude/skills/prototype/templates/default-tokens.css` to `/tmp/prototype-<slug>/tokens.css` and produce a minimal `brand-voice.md` with neutral tone (no subagent dispatch needed).
- **Subagent C — Monorepo scaffolder** (subagent_type: general-purpose, model: sonnet). Brief substituted. Subagent runs `cp -r .claude/skills/prototype/templates/monorepo-skeleton/<stack>/ /tmp/prototype-<slug>/` then `cd /tmp/prototype-<slug> && pnpm install` (next) or `bun install` (expo). Returns `dep-install-status`.
- **Subagent D — PRD-1pager** (subagent_type: general-purpose, model: sonnet). Brief substituted. If `--skip-prd`, NOT dispatched (marked SKIPPED in REPORT.md).

After all return, validate each artifact per `sitemap-schema.md` Rules 1-7 (skill side, not subagent). If sitemap validation fails, offer the user (a) re-dispatch Subagent A with augmented brief, or (b) edit `sitemap.yaml` manually.

**After scaffold + sitemap validated:** substitute `PROTOTYPE_SLUG` literal in all bundled template files with the actual slug. Use sed:
```bash
find /tmp/prototype-<slug> -type f \( -name '*.json' -o -name '*.tsx' -o -name '*.ts' -o -name '*.css' \) -exec sed -i "s|PROTOTYPE_SLUG|<slug>|g" {} +
```

## Phase 3 — Parallel build (per-route, cap 5 concurrent)

**Read `.claude/skills/prototype/references/delegation-briefs.md` § Phase 3 — Screen-writer BEFORE dispatching.** Pick the stack-specific brief.

For each route in `sitemap.yaml`:
1. Build the 5-field brief by substituting route metadata, sitemap entry, tokens path, brand-voice path.
2. Dispatch via Agent tool (subagent_type: general-purpose, model: sonnet) — Phase 3 dispatches use sonnet per `.claude/rules/delegation.md` § Advisories task-fit table (mechanical implementation).
3. **Concurrency cap: 5.** Dispatch 5 in parallel; await any return; dispatch next from queue.
4. On any subagent failure (validator-style rejection OR explicit can't-do response), mark the route `BLOCKED` in `.state.json`; continue with remaining routes. The whole build does NOT fail on one bad screen.

**Concurrency probe note** (spec 034 plan Risk #1 + Open Q #1): observe parent context pressure during the first dogfood. If OOM signals appear, drop cap to 3 here AND in `delegation-briefs.md` § Concurrency cap.

## Phase 4 — Stitch + verify + REPORT.md (inline)

The skill (NOT a subagent) does these steps:

1. **Wire token import (next-stack only):** append `@import "../tokens.css";` line to `/tmp/prototype-<slug>/app/globals.css`. (Expo stack consumes tokens via tailwind.config.js — no inline import.)
2. **Wire navigation (sub-route page files):** for each route in `sitemap.yaml`, the screen-writer subagent has already created its `page.tsx` (next) or `index.tsx` (expo) per the brief. Verify each file exists; mark missing as BLOCKED in `.state.json`.
3. **Run install verification:** in the prototype dir, run `pnpm install --frozen-lockfile` (next) or `bun install` (expo) → capture exit code + duration for REPORT.
4. **Run typecheck + lint:** `cd /tmp/prototype-<slug> && pnpm typecheck && pnpm lint` → capture per-step exit + duration. If either fails, RECORD the failure in REPORT.md `## Build health` section — do NOT fail the prototype build (founder may iterate).
5. **Start dev server, capture screenshot per route (if Playwright MCP available):**
   - `command -v playwright` OR check for `mcp__playwright__browser_navigate` tool availability.
   - If available: start `pnpm dev` in background, navigate to each route, take screenshot, save to `/tmp/prototype-<slug>/screenshots/<route-slug>.png`, stop dev server.
   - If NOT available: skip gracefully, mark "screenshots N/A — Playwright MCP unavailable" in REPORT.md.
6. **Author REPORT.md inline:**
   - Read `.claude/skills/prototype/templates/report.md.tmpl`.
   - Substitute all placeholders from `.state.json` + Phase 3 returns + Phase 4 measurements.
   - Score each screen 1-5 per dim per `quality-checklist.md` § Design fidelity (Token / Voice / Component / Brief-fit). Inspect each screen file + matched sitemap entry + tokens.css + brand-voice.md.
   - Build the states matrix per `quality-checklist.md` § States coverage matrix.
   - List gap-audit entries: per missing required_category, name what the agent auto-compensated (e.g., "auth required by schema — agent added /login, /signup, /reset without founder explicit mention").
   - Write the substituted REPORT.md to `/tmp/prototype-<slug>/REPORT.md`.

## Phase 5 — Handoff message

Print to chat:

```
Prototype ready at /tmp/prototype-<slug>/.

  Run: cd /tmp/prototype-<slug> && <pnpm dev|bunx expo start>
  Open: http://localhost:3000 (next) or scan QR code (expo)
  Report: /tmp/prototype-<slug>/REPORT.md

  Sitemap: <N_WIRED>/<N_TOTAL> routes wired
  Fidelity: <below_threshold_count> screens below 3/5 threshold (see REPORT.md § Fidelity scorecard)
  Build: typecheck <ok|FAIL>, lint <ok|FAIL>, dev <ok|FAIL>
  Skill compliance: <skill-validate-status>

  Engineering handoff: /sdd new <slug>
```

## Unknown / extra subcommand

This skill does not have subcommands beyond the initial invocation. If `$ARGUMENTS` starts with an unrecognized token (not a quoted string and not a flag), refuse with the usage hint:

```
/prototype "<idea>" [--stack=<name>] [--skip-prd] [--skip-brand]
```

## Notes

- **Spec 033 compliance is non-skippable.** Run `bash .claude/skills/skill/scripts/validate.sh .claude/skills/prototype` before commit; exit 0 required.
- **Output goes to /tmp.** The prototype dir at `/tmp/prototype-<slug>/` is gitignored by virtue of being in `/tmp`; the skill never writes into the Agent0 repo itself.
- **No MCP product-pipeline calls.** This skill explicitly bypasses `mcp__product-pipeline__*` tools — see spec 034 Non-goals.
- **Concurrency cap of 5** in Phase 3 is the design. Drop to 3 if dogfood reveals OOM (update this file AND `delegation-briefs.md`).
- **Defer cleanup confirmation.** Phase 0 prompts before `rm -r` on idempotent re-run; never auto-deletes without consent.
- **Stack staleness.** `references/stack-defaults.md` was snapshotted 2026-05-17; quarterly re-research is REMINDERS.md tracked.
