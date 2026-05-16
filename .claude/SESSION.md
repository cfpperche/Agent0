# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**2 commits ahead of origin** (push pending): prior session's pipeline-improvement cumulative + a parallel session's `0002aef feat(026): Phase B task 18 — step 9 system-design port + dogfood` (committed at 13:45 by a sibling). Working tree this session (post-update):

- `docs/specs/030-session-edit-attribution/` — spec + plan + tasks all FILLED (0 placeholders); status `draft`; ready to implement.
- `docs/specs/031-brainstorm/` — untracked, **NOT this session's work**; a parallel session scaffolded a `/brainstorm` skill spec (divergent ideation, complement to `/sdd refine`). Leave alone; sibling owns it.

This session: (a) read the prior `hermes-agent` transcript at user request; (b) diagnosed the spec-023 false-positive (worktree-delta misattribution when a sibling session edits during your lifetime) with forensic timing evidence; (c) scaffolded + filled **spec 030 session-edit-attribution** — primary `edited-files.txt` tracker via new `PostToolUse(Edit|Write|MultiEdit)` hook, spec 023 demoted to fallback (NOT superseded), 7 acceptance scenarios, 15 implementation tasks, 6 verification checks.

## Next steps

1. **Implement spec 030** — work `docs/specs/030-session-edit-attribution/tasks.md` top-to-bottom. Order: test-dir scaffold → new hook with payload parse + flock append → smoke test → settings.json registration → session-stop.sh primary-step extension → 7 scenario tests → rule doc update → run-all.sh → perf check → status flip to `shipped`.
2. **Spec 026 Phase B remaining tasks 19-22** — step 10 cost, step 11 roadmap, step 12 legal (closes Specification — gate fires), step 13 prototype-v3 NEW. (Task 18 step-9 committed by sibling as `0002aef`.)
3. **Untracked sibling spec 031-brainstorm** — coordinate with the owner (other session) before touching; surfacing here so future sessions don't accidentally git-add it.
4. **REMINDERS.md** unchanged — fair OD re-match, OD `--bump/--apply` upstream test, spec 029 adoption check (due 2026-05-30).

## Decisions & gotchas

- **Spec 023 has a known false-positive mode** (the one motivating spec 030): a session that doesn't edit anything but is open while another process/session modifies the worktree still gets nagged. Evidence: hermes session 95b868a2 — empty `start-porcelain.txt` at 13:23, step-09 files modified out-of-band 13:26/13:27, sibling captured them at 13:27:33, hermes Stop fired at 13:27:48. Spec 030 fixes this structurally; until it ships, parallel-session work risks spurious nags — discipline is to immediately update SESSION.md and let the once-per-session block clear.
- The hermes-agent transcript IS the only home of those Hermes Agent insights (research-only session, no memory write — by design).
- **Spec 023 stays `shipped`, NOT superseded.** Its porcelain-compare remains live as fallback for Bash-driven edits, IDE saves, and legacy sessions. The rule doc rewrite in spec 030 must preserve that semantic.

## Carryover (orthogonal lanes, not active)

- Pyshrnk CLAUDE.md reconciliation — long-standing parking lot.
- Shrnk-mono harness-sync commit pending.
- Praxis-prototype (separate repo): deployed at https://cfpperche.github.io/praxis-prototype/.
- Bench artifacts (wipe-able, ~1.5 MB combined): `/tmp/bench/026-dogfood-step{2,3-4,5,6,7,8}/` + `/tmp/bench/026-comparison-anthill/`.
- 10 `step7-*.png` screenshots at repo root from prior dogfood visualizations — wipe-able, not source.
