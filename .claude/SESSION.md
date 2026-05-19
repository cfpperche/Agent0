# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Spec 064 (project-scoped routines) FULLY DOGFOODED** (2026-05-19). 3 commits:
- `850190c` — scaffold spec dir (spec.md / plan.md / tasks.md / notes.md)
- `265772a` — ship v1 capacity (rule + skill + 3 tools + hook + integrations)
- next commit — first real routine (`cc-platform-audit`) + drift output applied to memo

All 4 post-ship follow-ups exercised end-to-end this session:

1. **Push to origin** ✓ — `9bbba4e..265772a main -> main`
2. **First real `/routine run` dispatch** ✓ — invoked `cc-platform-audit` via Skill tool: WebFetched <https://code.claude.com/docs/en/hooks>, detected drift (29 → 32 hook events since 2026-05-11 snapshot), applied edits to `.claude/memory/cc-platform-hooks.md` adding 3 new events (`PermissionDenied`, `TaskCreated`, `TaskCompleted`) + fixed Agent0-usage count (8 of 32, not 9 of 29). Queue→completed archived, last-completed.json populated. Skill prose-based dispatch works.
3. **`sync-harness --apply`** ✓ — all 12 spec-064 files landed in `/tmp/sync-fork-test-2756236`: skill subdir, .gitkeep, rule, 3 tools, hook, CLAUDE.md merged with new `## Routines` section, settings.json gained routines-readout entry, .gitignore got `.routines-state/`. Idempotent re-apply: 0 copied, 0 merged. 4 customized-refused = pre-existing fork drift in product skill + delegation.md (unrelated to 064).
4. **First real routine created + scheduled** ✓ — `.claude/routines/cc-platform-audit.md` (weekly Mon 9am UTC). Real crontab entry installed; next natural fire ~6 days.

## WIP (uncommitted)

- `M docs/specs/059-product-phase0-harness-aware/tasks.md` — orthogonal carryover (not this session)
- This session's work fully committed after the two pending commits ship.

## Next steps

1. **Watch for first natural cron fire** — Monday 2026-05-25 09:00 UTC. Queue file should appear without manual intervention. Confirms cron+leader-flag path works under real timing, not just `bash run-routine.sh` direct invocation.
2. **Run cc-platform-audit again** after the natural fire — verifies idempotency: second run should report `no-drift-detected since 2026-05-19T22:34:40Z` because the memo already reflects current state.
3. **`/routine run cc-platform-audit` dispatch shape works empirically**; tune the prompt body if next dispatch surfaces clarity issues.
4. **First REAL fork adoption** (not /tmp synthetic) — mei-saas or acmeyard would exercise full sync into an active project. Founder call when ready.
5. Carryover from prior cycles: spec 029 adoption check due 2026-05-30; spec 046 dogfood gate due 2026-07-01; mei-saas `/product` Phase 0 still pending founder.

## Decisions & gotchas

- **First-real-dispatch unknown closed**: SKILL.md prose-instructions are executable by Claude — the validation step (file exists, queue non-empty), pop-oldest, read-prompt-body, dispatch, archive (mv + last-completed.json write), FIFO cap — all happened in-session via Edit + Bash tools. No script needed for `run` dispatch.
- **Cc-platform-audit drift output is uncommitted by design** — the routine prompt explicitly says "DO NOT commit, leave diff for human review". Founder reviews the cc-platform-hooks.md edits before committing.
- **Sync-harness `--apply` worked but the second invocation showed 0 changes because the first invocation copied everything** — Bash hook governance gate blocking the test setup made me run apply twice; second was no-op (correct idempotency). Verified explicitly via `ls` checks on each landed file.
- **Real crontab entry now active** in user's crontab — `0 9 * * 1 bash /home/goat/Agent0/.claude/tools/run-routine.sh cc-platform-audit`. Uninstall via `bash .claude/tools/uninstall-routines.sh` if you want to halt the weekly fire.
- **Phase 2 still deferred** per rule-of-three demand test. v1 with this single real routine is the first data point; need ≥2 more routines proving value before promoting to `claude -p` autonomous executor.

## Carryover (orthogonal — not touched this session)

- mei-saas `/product` Phase 0 ready (founder owns next step)
- Spec 046 dogfood gate due 2026-07-01
- Spec 029 adoption check due 2026-05-30
- Spec 026 Phase C/D pending
- Acme Yard substrate work at `/home/goat/acmeyard`
- `.claude/REMINDERS.md` items per startup readout
