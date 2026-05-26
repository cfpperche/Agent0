# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Session 2026-05-26 — Spec 090 shipped end-to-end via cross-runtime `/sdd` dogfood.**

Multi-runtime entrypoints landed: `AGENTS.md` at repo root, byte-identical Agent0 managed block in both `CLAUDE.md` and `AGENTS.md`, asymmetric sync (CLAUDE = structured marker merge; AGENTS = plain baseline-tracked because Codex provides native override-chain primitives), 3-tier capability classification preamble in AGENTS.md, drift script + 6 test fixtures + harness-sync 33-test suite all green. Implementation by Codex CLI; spec/plan/tasks scaffolded + debate by Claude Code; two Claude-side audit passes drove one round of follow-ups that closed the two LOW findings.

Cross-runtime `/sdd debate` proved out empirically: 3 rounds Claude↔Codex on spec 090, 2 rounds Claude↔Codex on spec 092, all rounds wrote directly to `debate.md` via file tools — zero copy-paste, zero broker scripts, zero new infra in either skill.

## WIP

Spec 092 (multi-runtime-handoff) is **mid-cycle, synthesis written but not applied**:

- `docs/specs/092-multi-runtime-handoff/debate.md` — converged at end of Round 2 (7 accepts by Codex; 7 resolutions confirmed by Claude). Synthesis section filled by Claude with `Resolution: converged` + ~9 proposed `spec.md` changes. `## Applied changes` placeholder still — synthesis NOT yet applied to spec.md.
- Pending decision: ask Codex CLI to audit the synthesis (prompt prepared in conversation history) OR apply directly without cross-review.

Spec 091 (sdd-debate-runner) is **explicitly paused** per the user; do not continue without an explicit "resume 091" instruction.

`.claude/SESSION.md` is the only file modified by this session-end handoff write.

## Next steps

1. **Push** (4 commits ahead of `origin/main`: `b3ed057` + `a0c6850` + `2fd41e2` + `5385919`) — user decides timing.
2. **Spec 092 — synthesis review or apply.** Either run the prepared Codex-audit prompt or apply directly to `spec.md` + fill `## Applied changes`. If apply: ~9 acceptance edits + 4 non-goals + 5 open-question updates + 2 reference appends per the synthesis text.
3. **Spec 091 — resume only on explicit user instruction.**
4. **Codex side port of `/sdd debate`** — track whether the Codex-CLI port matches the runtime-neutral protocol (initiating/reviewing role detection via `**Initiating agent:**` metadata; counter requires Round N-1 critique filled; legacy fallback infers initiator from round headers). Spec 089 documents the contract; Codex's port is out-of-repo.

## Decisions & gotchas

- **Cross-runtime `/sdd debate` empirically works.** Two real specs (090, 092) reviewed by the peer runtime, both produced concrete spec edits before plan locked. Convergence at Round 2 (092) and Round 3 (090); 3-round cadence held.
- **Asymmetric sync is honest, not a hack.** CLAUDE.md = structured merge (one per project); AGENTS.md = baseline-tracked (Codex's `AGENTS.override.md` + nested chain handles fork customization natively). Future maintainers tempted to "fix" the asymmetry must read spec 090 first.
- **Helpers at `.claude/tools/lib/managed-block.sh`** — sourced by `sync-harness.sh` and `check-instruction-drift.sh`. New tools touching markers/regions source from here, not re-implement.
