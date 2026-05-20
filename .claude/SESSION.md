# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Top-3 picks from umbrella 060 closed out today** (post-research session 2026-05-19):

- **Spec 061 (SubagentStop hook): in-progress.** Backbone shipped — close rows pairing with dispatch via `tool_use_id`. Mid-session probe-fire confirmed bridge: `agent-<id>.meta.json.toolUseId` matches PreToolUse's `tool_use_id`. Loop-budget detection, `edit_count` from per-sub-agent transcript JSONL. Tests deferred per rule-of-three.
- **Spec 062 (/goal skill): superseded.** Empirical pre-flight on CC 2.1.144 binary (`strings | grep ^/goal`) found native `/goal` already shipped with full surface (`/goal <cond>`, `/goal clear`, `goal-command-nudge` internal). Building wrapper = accidental complexity. Closed with design memory preserved.
- **Spec 063 (worktree-isolation): in-progress.** Pre-flight found CC ships rich native worktree stack (`Agent.isolation`, `EnterWorktree`/`ExitWorktree` tools, `.claude/worktrees/` convention, `--worktree` CLI). Option B redirect: dropped 6th brief field; added (a) `tool_input.isolation` audit (13th dispatch field), (b) validator scoping via `git rev-parse --show-toplevel` in post-edit-validate.sh, (c) rule § Worktree isolation. E2e verified for audit field; validator-cwd fix not exercised (Explore probes don't edit).

**Parallel session work** (in git log, not touched by me): 064 (project-scoped routines), 065 (artifact-budget discipline), harness-sync settings-merge bug fix across 3 repos.

## WIP (uncommitted)

- `M docs/specs/059-product-phase0-harness-aware/tasks.md` — orthogonal carryover, untouched
- 7 PNGs (`v*-*.png`) — untracked carryover

## Recent commits (anchors for the day)

- 063 ship: `9f8d24c` (audit + scoping + rule)
- 062 closure: `9bbba4e` (superseded by CC native /goal)
- 061 cluster: `ef8c501 → 608729a` (4 commits: pre-flight → gate ext → stop hook → docs)
- Parallel session: 064 `850190c`, 065 `ff35d17`, settings-merge fix `0702c6a`

## Next steps

1. **Spec 064 cron natural fire** — Monday 2026-05-25 09:00 UTC; `cc-platform-audit` should queue without manual intervention.
2. **Statusline runtime check** — open fresh CC in mei-saas/acmeyard; statusline from `.claude/presence/statusline.mjs` should render. Validates settings.json non-hooks-keys fix end-to-end.
3. **Umbrella 060 next batch** — re-evaluate §A4-A8 + §B medium-priority rows; scaffold based on observed dogfood signal.
4. **Validator-cwd fix exercise** — first real sub-agent Edit/Write dispatch will exercise the spec 063 scoping path; watch validator stderr for any toplevel-derivation issues.

## Decisions & gotchas

- **Pre-flight empirical pattern PAID 3/3** (specs 061/062/063): probe CC binary + tool surface BEFORE design saves substantial work (062 closed entirely; 063 redirected to ~50% of original scope; 061 found hook payload bridge that locked the design). Candidate for `.claude/memory/feedback_*.md` discipline entry — "for specs touching CC primitives, sondar binary/tools first".
- **Mid-session hook reg ATIVOU** in settings.local.json for both 061 and 063 probes — contradicts `session-handoff.md`'s "Hooks only register on next session". Likely a `settings.local.json` vs `settings.json` distinction or behavior change in 2.1.144. Orthogonal observation; cleanup deferred.
- **Audit row schema growth**: dispatch row 11 → 12 (tool_use_id, 061) → 13 (isolation, 063). Documented in `.claude/rules/delegation.md` § Audit log.

## Carryover (orthogonal — not touched this session)

- Spec 046 dogfood gate due 2026-07-01
- Spec 029 adoption check due 2026-05-30
- Spec 026 Phase C/D pending
- mei-saas `/product` Phase 0 (founder owns next step)
- `.claude/REMINDERS.md` items per startup readout
