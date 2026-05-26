# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Session 2026-05-25 (evening) — Spec 088 (`image-skill-curl-exec`) shipped end-to-end via `/goal`-driven SDD flow.**

Triggered by a codexeng dogfood session that empirically diagnosed the fal.ai hosted MCP as broken on `gpt-image-2` (hangs ≥990s server-side; CC client mis-renders timeout as `"user doesn't want to proceed"`). Spec 088 lands the architectural response: **hybrid MCP + REST**. `/image` keeps the MCP recipe for discovery (`search_models`, `get_model_schema`, `get_pricing`, `recommend_model`) but routes generation through a new `gen.sh exec` curl path (POST `fal.run/<model>` with `Authorization: Key $FAL_KEY`). V1–V8 PASS empirically; V9 (live brand-text drift) deferred to next brand-text call.

Earlier today (afternoon): `cc-platform-audit` routine fixed 32→29 hooks narrative drift in `.claude/memory/cc-platform-hooks.md` — still uncommitted.

## WIP — two atomic commits queued

1. **Memory drift fix** — `M .claude/memory/cc-platform-hooks.md` + `M .claude/memory/MEMORY.md` (9+/9-). Single-purpose.
2. **Spec 088 implementation:**
   - `M .claude/rules/image-gen.md` (+6/-1)
   - `M .claude/skills/image/SKILL.md` (+19/-11)
   - `M .claude/skills/image/references/tier-pricing.md` (+18/-2)
   - `M .claude/skills/image/scripts/gen.sh` (+159/-2)
   - `M assets/generated/.manifest.jsonl` (+1) — V1 smoke test evidence
   - `?? docs/specs/088-image-skill-curl-exec/` — status: shipped

The two are independent; commit separately, order doesn't matter.

## Next steps

1. **Commit both** atomically — memory drift first, then spec 088 (or reverse).
2. **In codexeng** (separate repo): finish spec 004 V6 (founder eyeball on og-card.png) + V7 (status → shipped); commit specs 002 + 003 + 004; push. Codexeng's SESSION.md has the resume point.
3. **Manual upstream issues** (founder, not agent-actionable):
   - fal.ai Discord (`discord.gg/fal-ai`): `run_model` hang + `"No token data found"` 1.14s poll loop. Ask whether `gpt-image-2` should route via `submit_job`+`check_job`.
   - `anthropics/claude-code` GH issue: MCP timeout mis-rendered as `"The user doesn't want to proceed with this tool use"`. Reference #20335, #16837.
4. **Spec 029** (`sdd-list-in-flight`) due 2026-05-30 — check `/sdd list --in-flight` adoption; if unused, revert template change. Reminder `r-2026-05-16-spec-029-sdd-list`.

## Decisions & gotchas

- **Hybrid MCP + REST is now the documented Agent0 pattern for fal.ai.** MCP for discovery, curl for generation. See `.claude/rules/image-gen.md` § *Gotchas* (new top bullet) + spec 088. Forks inherit via sync-harness.
- **`gen.sh` has 3 subcommands** now: `prepare` → `exec` → `record`. The pre-call cost-print contract is preserved at `prepare`.
- **Dim parser bug found + fixed during smoke test.** `file <jpg>` puts `density 1x1` BEFORE the real image dims; `head -1` was picking up `1x1`. Fixed: ffprobe-first, fall back to `file | tail -1`. Verified end-to-end.
- **brand-text TIER_TABLE cost** bumped $0.040 → $0.200 to match `quality=high` schema default. AC ceilings should target $0.20.
- **3 Open Questions on spec 088** deferred to founder: `--quality` flag, auto-downscale strategy (graceful-degrade picked as v1), gotcha-promotion (done in this spec's commit).
- **Codexeng spec 004 § Deviations entry `2026-05-25 (late)`** is the empirical source — 21,655 "No token data found" polls in 1.14s cadence, `run_model still running 990s+`, closed-source Vercel-hosted server (no upstream fix path).
