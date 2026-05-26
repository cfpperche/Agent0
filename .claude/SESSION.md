# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Session 2026-05-26 — Spec 089 (`sdd-debate-artifact`) shipped: `6da3f4b`.**

Adds `/sdd debate` subcommand + 5th SDD artifact (`debate.md`) for cross-model spec review. Originally drafted as broker-human copy-paste; pivoted within the same session to **dual-agent direct-file mode** after user feedback that their workflow is two CLI agents in separate sessions (Claude Code + Codex CLI). Both agents read and write `debate.md` directly via native file tools; human alternates active agent and decides when to ask for synthesis. Zero infra in this skill (no API key, no MCP, no script). Codex CLI maintains its own port of the skill; concurrency control is out of scope (assume turn-based human orchestration).

Deviation logged in `docs/specs/089-sdd-debate-artifact/notes.md` § Deviations.

## WIP

None. Working tree clean post-commit.

## Next steps

1. **Push** (3 commits ahead of origin: `6da3f4b`, `a934e8b`, `63665e5`) — founder decides timing.
2. **First real `/sdd debate` invocation** — when the next high-stakes spec lands (schema / public API / security shape), run debate against it. Track in conversation whether the GPT-5/Codex critique produced a real spec edit; ≥3 such "produced edit" debates = rule-of-three trigger for spec 090 (promote toward direct-API or sharper protocol if needed).
3. **Spec 029** (`sdd-list-in-flight`) due 2026-05-30 — check `/sdd list --in-flight` adoption; if unused, revert template change (reminder `r-2026-05-16-spec-029-sdd-list`).
4. **Codexeng fork** — still has 14 modified + 5 untracked pending founder commits (sequence in codexeng's SESSION.md: V6 founder eyeball → V7 ship spec 004 → commit specs 002/003/004 → push → first live brand-text validates spec 088 V9).
5. **Mei-saas fork** — 13 modified + 2 untracked pending maintainer commit.
6. **Codex side** — port spec 089's `/sdd debate` protocol into Codex CLI's skill equivalent before the first dogfood debate run.

## Decisions & gotchas

- **Dual-agent debate uses the file as sole shared state.** Each `/sdd debate` invocation reads `debate.md`, writes the next empty Claude-side slot (position / counter / synthesis), reports the handoff. No auto-convergence, no round-count cap, no copy-paste. The human decides when to ask for synthesis.
- **Re-invoking `/sdd debate` on an in-flight debate is the orchestration pattern**, not an error. Refusal logic keys on the `**Resolution:**` placeholder line — present-as-placeholder = in-flight (continue), present-as-concrete-value = complete (archive existing to `debate-N.md` before new scaffold).
- **The original broker-human posture was wrong-shaped** for the user's real workflow. The pivot happened ~5 minutes after the original ship. Documented in `notes.md` § Deviations as historical record; the spec's own acceptance scenarios were rewritten to match shipped reality before re-tick.
