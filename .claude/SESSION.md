# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Session 2026-05-21 — specs 068–071 shipped + pushed (`e14a0ee`); 072 shipped, committed local (`3d76f9f`, unpushed). Three streams: 068/069 + 070/071 + mei-saas-validation/072.**

- **068 (`harness-sync-baseline-reconciliation`, `ea56cbe`)** — `sync-harness` plain-file path now does 3-way reconciliation (fork vs recorded baseline vs Agent0): stale auto-updates, customized refuses, upstream-removed orphans delete. Baseline at `<fork>/.claude/harness-sync-baseline.json`.
- **069 (`product-overwrite-git-safety`, `e45161a`)** — `/product` Phase 0 overwrite no longer `rm -r <out>`; new tested `clear-target.sh` clears only non-harness `<remaining>`, preserving `.git/` + harness (Gap F).
- **070 (`propagation-hygiene`, `de676b6`)** — de-leaked Agent0-internal spec pointers from fork-bound files (CLAUDE.md, 16 rules, 4 root configs); deleted the `## PHP / Laravel` CLAUDE.md section; capacity↔spec linkage moved to `.claude/memory/capacity-spec-index.md`.
- **071 (`claude-md-capacity-index`, `b3b6004`)** — compressed CLAUDE.md managed block ~2795→~727 words (−74%); `sync-harness.sh` reconciles the block as a baseline-tracked 3-way unit. harness-sync suite 32/32.
- **072 (`sync-harness-self-overwrite`, `3d76f9f`)** — `sync-harness.sh` syncs itself, so a stale `--apply` overwrote the running script → bash read-offset crash (hit in the mei-saas validation). Fix: `_self_rebootstrap` re-execs from a temp copy. Suite 33/33.

## WIP (uncommitted)

- `SESSION.md` + `.claude/REMINDERS.md` dirty — uncommitted (REMINDERS.md awaits founder review; SESSION.md: coordinate with the parallel session).
- **mei-saas fork**: 27 modified + 3 new from the 069/070/071 validation sync, uncommitted there; checkpoint `a2c8ec2` local to mei-saas.

## Recent commits (anchors)

- `3d76f9f` feat(072) · `e14a0ee` chore(session) · `b3b6004` feat(071) · `de676b6` feat(070) · `e45161a` fix(069) · `b170015` fix(068 gitleaks) · `ea56cbe` feat(068).
- `main` is **1 ahead of `origin/main`** — `3d76f9f` (072) unpushed; 068–071 are at `e14a0ee`. Stale branches `068-*` and `070-propagation-hygiene` deleted this session.

## Next steps

1. **`/product` dogfood** — unblocked (Gap F fixed → safe directly against the mei-saas repo; `clear-target.sh` preserves `.git/` + checkpoint `a2c8ec2`). `--out=/home/goat/mei-saas`, `--stack=next`; needs the mei-saas idea string (or pull it from the fork's `docs/REPORT.md` / `.state.json`).
2. **070 follow-ups** (deferred — `.claude/memory/propagation-hygiene.md` § Not-yet-cleaned): memory cross-refs in rules/CLAUDE.md; spec citations in hooks/tools/skills code comments. Opportunistic, not spec-worthy yet.
3. **Pre-071 forks + managed block** — first sync after 071 hits a one-time `--force` (managed-block append-only → 3-way); documented in `harness-sync.md`.
4. Spec 064 cron natural fire — Mon 2026-05-25 09:00 UTC.
5. **Push `main`** — `3d76f9f` (072) is committed but unpushed.

## Decisions & gotchas

- **`sync-harness.sh` + `set -euo pipefail`** — any new bare-statement function called from `main` MUST `return 0` on skip paths; a bare `return <non-zero>` aborts the whole script.
- **CLAUDE.md merge was never "append-only"** — `_merge_claude_md_managed_block` already wholesale-replaced; 071's real fix was giving it a baseline so it stops refusing on section-body divergence.

## Carryover (orthogonal — not touched this session)

- Spec 046 dogfood gate due 2026-07-01; spec 029 adoption check due 2026-05-30.
- `.claude/REMINDERS.md` items per startup readout.
- Stray untracked `bo-*.png` at repo root — not ours.
