# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Session 2026-05-21 — specs 068–072 all shipped + pushed; `main` clean and in sync with `origin`.**

- **072 (`sync-harness-self-overwrite`)** — `sync-harness.sh` had a latent self-overwrite crash (it is in its own propagation manifest; an `--apply` overwrote the running script → bash read-offset corruption). Fix: `_self_rebootstrap` pre-flight re-execs from a temp copy. harness-sync suite 33/33.
- The **mei-saas fork** was caught up to Agent0's full harness (specs 069–072) via `sync-harness.sh`, committed + pushed (`98a899f`). Validation suites passed; the pre-072→072 transitional crash was observed live and self-healed on re-run, exactly as the `harness-sync.md` gotcha documents.

## WIP (uncommitted)

- None. Agent0 working tree is clean.

## Next steps

1. **070 follow-up #1 — memory-ref de-leak (→ spec 073, or direct: it is mechanical).** 11 dangling `.claude/memory/<file>.md` pointers across 8 fork-bound files (7 `.claude/rules/*.md` + CLAUDE.md) — `MEMORY.md`, `feedback_speculative_observability.md`, `cc-platform-hooks.md`. A fork gets only `.claude/memory/.gitkeep`, so each path is a dangling pointer — same class as spec 070's spec-citation leak, distinct cause. Recorded in `.claude/memory/propagation-hygiene.md` § Not-yet-cleaned. **This is the designated next Agent0 task.**
2. **`/product` dogfood of mei-saas** — queued; runs in a mei-saas-rooted session (kickoff prompt prepared 2026-05-21). Live-validates spec 069's Phase 0 overwrite (`clear-target.sh` must preserve `.git/` + harness). mei-saas baseline is clean + pushed; checkpoint `a2c8ec2` is the safety net.
3. Dated reminders (not yet due): spec 029 adoption 2026-05-30 · spec 035 missed-clarification count 2026-06-07 · spec 046 gate 2026-07-01 · spec 060 §A/§B review 2026-07-19.

## Decisions & gotchas

- **`sync-harness.sh` + `set -euo pipefail`** — any new bare-statement function called from the orchestration tail MUST `return 0` on its skip paths; a bare non-zero `return` aborts the whole script.
- **070 follow-up #2 (spec citations in hook/tool code comments) is deliberately OUT of scope** — code comments are not instruction-context, low harm; 070 deferred them on purpose. Do not bundle into 073.

## Carryover (orthogonal — not touched this session)

- `.claude/REMINDERS.md` items per startup readout.
- Discussion items parked: SOUL.md per sub-agent (delegation brief); `/product` full-stack expansion (caminhos A/B/C).
