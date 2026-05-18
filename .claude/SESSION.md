# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Spec 036 (`prototype-skill-refactor`) — IN-PROGRESS.** Drafted + Pass A + Pass B shipped this session. Pass C + Pass D pending. The skill is mid-refactor: v2 4-phase orchestration body landed, 13-step delegation briefs written, 14 sub-agent shells declared, OD vendor index extracted (72 vendors @ 21.6 KB). v1 still routable until v2 dogfood validates (per spec 034 supersede order in tasks.md).

Triggered by 2026-05-17 dogfood "skill rejeitada" user feedback. `/prototype` v1 was scoped as agile *alternative* to 13-step mcp-product-pipeline but covered only ~25-30% (8 steps missing entirely). v2 reframes as agile *frontend* covering all 13 steps at single "standard" depth tier, standalone (templates bundled, no MCP runtime dep), `--out=<path>` flag (drop /tmp hardcode), `--from-step=NN` resume support, 3 `AskUserQuestion` gates between phases.

This session also produced a complete /prototype v1 dogfood at `/tmp/prototype-claude-code-governance-dashboard/` (17 routes, 10 KLoC TSX, dev server runs, 5 dogfood findings — all 5 will be fixed in Pass C). The tokens.css import bug (false-positive grep heuristic — root cause of "skill rejeitada") was caught + fixed live + propagated to v2 design.

## WIP (in flight)

**Pass C + Pass D of spec 036.** Tasks 14-23 in `docs/specs/036-prototype-skill-refactor/tasks.md`. Pass C = 5 template bug fixes (~30 min). Pass D = ops/docs hygiene (REMINDERS quarterly entry, supersede spec 034, CLAUDE.md pointer, delete v1 prd-1pager template). Then Pass E = live dogfood replay (scenario 10 acceptance — same brief as 2026-05-17, verify design system renders) — gate before spec 036 status flips `draft → shipped`.

## Next steps

1. **Pass C** (5 template bug fixes — tasks 14-19): `pnpm-workspace.yaml` placeholders → literal true/false; `package.json` add test script; `globals.css` prepend tokens.css import; SKILL.md add validator-scope advisory; symmetric expo `package.json` fix.
2. **Pass D** (tasks 20-23): REMINDERS quarterly drift-sync item; spec 034 status → `superseded by 036-prototype-skill-refactor`; CLAUDE.md `## Prototype skill` pointer; delete v1 `prd-1pager.md.tmpl`.
3. **Live dogfood (acceptance gate)** — replay "Claude Code governance dashboard" brief; verify all 13 step artifacts produced; verify design system renders (NOT raw HTML).
4. **Spec 036 status flip** to `shipped` after dogfood passes.
5. **Push deferred 7+ commits to origin** when user authorizes (currently 6 ahead per pre-spec-036 count + at least 1 more from this commit).

## Decisions & gotchas

- **5 spec 036 open questions resolved 2026-05-18:** Step 1=opus + Steps 2-13=sonnet; quarterly REMINDERS drift sync (no script); `AskUserQuestion` structured at 3 gates; degrade gracefully + log on mid-pipeline BLOCKED, abort only on Step 01 or Step 13 fail; Phase 0 overwrite prompt (no `--force` flag).
- **Validator scope is repo-wide gotcha** (Pass B SKILL.md Notes documents). One bad Biome format error in any file blocks ALL subsequent sub-agents in the same dispatch batch until cleaned. Run `biome check --write .` between batches as parent-side mitigation.
- **OD catalog index bundled at 21.6 KB** (72 vendors with category + mood + palette_primary + vendor_path). Full per-vendor DESIGN.md NOT bundled (size budget) — Step 06 reads them from `packages/mcp-product-pipeline/design-systems/<vendor>/DESIGN.md` if present, falls back to mood-only otherwise.
- **Bundled pipeline templates 1.3 MB total** (13 step dirs × 60-160 KB each). Skill dir grew from ~250 KB → 1.5 MB. Acceptable (no per-skill size cap; SKILL.md body is 163 lines / ~2400 tokens — well under 5000 cap).
- **Sub-agent parallel-dispatch discipline rediscovered.** Spec 034 dogfood revealed serial-1 dispatching even when skill body said parallel. v2 SKILL.md now has an explicit literal "5 Agent tool calls in one message" worked example.

## Carryover (orthogonal lanes, not active)

- **Pre-existing dirty (NOT touched this session):** `.claude/REMINDERS.md` (sibling-session edits from prior), `.claude/skills/brainstorm/templates/render.html.tmpl` (older session WIP). NOT included in this session's commit.
- **Sibling sessions:** hermes-core 8th surface decision (Cookbook/Recipes was top recommendation; user thinking). `cfpperche/claude-core` and `cfpperche/hermes-core` repos at separate paths.
- **Dogfood artifacts at /tmp/:** `/tmp/prototype-claude-code-governance-dashboard/` (17-route Next.js v1 dogfood, contains design-system-fix patch — wipe-able; v2 replay will create new dir).
- **Spec 029** adoption check due 2026-05-30.
- **Spec 026 Phase C/D** still pending (orthogonal track).
