# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

Single small uncommitted change: `.claude/rules/delegation.md` (+6 lines) — new `## Why DONE_WHEN exists (the /goal connection)` section that frames DONE_WHEN as the local materialization of upstream Claude Code `/goal` (shipped v2.1.139, 2026-05-12, docs at `code.claude.com/docs/en/goal`). The framing is "contract, not promise" — a goal statement without a verifier is just a fancier prompt; the post-edit-validator + runtime-introspect are the verifier that makes the contract real. Rule-bucket (not memory) so the framing propagates to forks via sync-harness.

Trigger was studying Saboo Shubham's "ultimate guide to /goal" tweet (x.com/Saboo_Shubham_/status/2054988166541770782) — he describes the convergence between Codex CLI, Claude Code, and his Hermes orchestrator. Verified `/goal` is a real built-in CC slash command via claude-code-guide (autonomous main-agent loop using a Stop hook + evaluator model — NOT a subagent dispatch).

`bun tsc --noEmit` and tests not re-run this session (single-rule-doc edit, no code touched). Prior session's spec-026 Phase B tasks 11/12/13 dogfood already landed in commits up through `492d6ee`.

## Next steps

1. **Decide commit on the `delegation.md` /goal-framing edit.** User was offered "commit já / ler diff antes" — left pending when this turn closed. Suggested message: `docs(rules/delegation): frame DONE_WHEN as the /goal primitive (contract not promise)`. One-file commit, no test impact.
2. **Spec 026 Phase B — tasks 14-22**: step 5 brand, **step 6 design-system (HIGH priority — tokens feed 7 + 13)**, 7 prototype-v2, 8 PRD, 9 system-design, 10 cost, 11 roadmap, 12 legal, 13 prototype-v3 NEW. Apply `feedback_anthill_port_smart_not_rigid` to each port.
3. **Fair OD re-match + future OD `--bump`/`--apply`** — both still pending in `.claude/REMINDERS.md`, deferred-style not urgent.

## Decisions & gotchas

- **`/goal` is upstream-real, not just Saboo-wrapper.** Built-in CC slash command at v2.1.139+. Mechanism: prompt-based Stop hook + evaluator model (Haiku default) that judges done/not-done each turn within the same session. Not a subagent dispatch. `/goal` and `Agent` compose (you can dispatch sub-agents from within a `/goal` loop, and each dispatch still passes through the 5-field delegation gate).
- **Recurring drift caught this session:** I proposed saving the `/goal` framing as a memory; user reminded that memory content does NOT ship to forks (only `.gitkeep` scaffold via sync-harness). Saved `feedback_agent0_changes_ship_via_rules_not_memory.md` to CC per-user memory so I stop drifting.

## Carryover (orthogonal lanes, not active)

- Pyshrnk CLAUDE.md reconciliation — long-standing parking lot.
- Shrnk-mono harness-sync commit pending (13 modified + 2 untracked there).
- Praxis-prototype lane (consultancy-site, separate repo): deployed at https://cfpperche.github.io/praxis-prototype/. Possible `section-line-grid` opacity bump 0.045 → 0.07.
- Bench artifacts: `/tmp/bench/026-dogfood-step2/` (~370 KB) + `/tmp/bench/026-dogfood-step3-4/` (~157 KB) — wipe-able unless promoted to spec dogfood/.
