# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Session 2026-05-23 — closed.** 076 (product-dogfood-fixes) shipped end-to-end: 6 findings across 7 commits (a2d4ed6 → 2e10a6b close). Harness propagated to both forks via `sync-harness.sh --apply` (mei-saas `a689604` clean 18-file sync; codexeng `6271101` large 99-file catch-up including 31 deletes from spec 066/077 retired template dirs + 2 customizations preserved). Tree clean. 11 commits to push on Agent0 main.

## WIP — resume point

**No active WIP.** All work shipped + committed. Next session starts cold on 082 scaffolding (umbrella 080 MS-1).

## Next steps

1. **`/sdd new memory-frontmatter-schema`** → scaffold umbrella-080 child **082** (MS-1 frontmatter schema + PostToolUse advisory validator). Foundation for 083 (MS-2 event-sourcing) and 085 (MS-5+MS-7 cap+query+decay). All three unscaffolded.
2. 5 remaining 076 findings from the original 10-finding triage table (#1, #2-byte-window, #6, #7, #10) were covered by spec 075 — no follow-up specs pending unless dogfood surfaces new findings.
3. Dated reminders due: 029 05-30 · 035 06-07 · 046 07-01 · 060 07-19.
4. Push pending commits: `git push origin main` (Agent0 11 + mei-saas 1 + codexeng 6).

## Decisions & gotchas

- **076 — SKILL-DIRECTED slug min ≥3 chars, NOT ≥10.** The ≥10 was copied from `# OVERRIDE:` whose payload is human prose; SKILL-DIRECTED carries machine slugs (`product` is 7 chars). Live task-25 test caught it. Logged in `docs/specs/076-product-dogfood-fixes/notes.md` § Deviations 2026-05-23.
- **`CLAUDE_PROJECT_DIR` fallback ≠ project dir for ad-hoc gate runs.** Gate uses `${CLAUDE_PROJECT_DIR:-$PWD}`; piping a payload from `/tmp` writes audit rows to `/tmp/.claude/delegation-audit.jsonl`, NOT the real log. `export CLAUDE_PROJECT_DIR=/home/goat/Agent0` or accept the sandbox. Logged in 076 notes.md.
- **sync-harness customizations refused:** codexeng's `.mcp.json.example` + `.claude/rules/mcp-recipes.md` are intentional fork-locals; sync skipped them as expected. Use `--force-except=GLOB` to keep specific paths customized while force-syncing others, never blanket `--force`.

## Carryover (orthogonal — not touched this session)

- `docs/specs/074-subagent-personas/` — untracked draft; leave for originating session.
