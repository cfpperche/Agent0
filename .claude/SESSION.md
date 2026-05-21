# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Session 2026-05-21 — specs 070 + 071 shipped and committed on `main`. Working tree clean.**

**070 (`propagation-hygiene`, `de676b6`)** — de-leaked Agent0-internal spec pointers (`docs/specs/0NN`, `Spec NNN`, hyphenated `spec-NNN`/`pre-NNN`/`post-NNN`) from every fork-bound file: CLAUDE.md, 16 `.claude/rules/*.md`, and the 4 root config files (`.mcp.json.example`, `.gitleaks.toml`, `.githooks/pre-commit`, `.gitignore`). Deleted the per-stack `## PHP / Laravel` CLAUDE.md section (PHP detection folded inline into the capacity sections). Relocated the capacity↔spec linkage to `.claude/memory/capacity-spec-index.md` and recorded the maintainer discipline in `.claude/memory/propagation-hygiene.md` (memory, not a rule — it must not propagate).

**071 (`claude-md-capacity-index`, `b3b6004`)** — compressed CLAUDE.md's `AGENT0:BEGIN/END` managed block from ~2795 → ~727 words (~3.6K → ~0.9K tokens, −74%): each capacity is now a one-line index entry pointing at its rule. Changed `sync-harness.sh` so the managed block is reconciled as a single baseline-tracked 3-way unit (synthetic key `CLAUDE.md#managed-block`) — stale block auto-updates, customized refuses. harness-sync suite **32/32 pass**.

## WIP (uncommitted)

None. 069 (`e45161a`), 070 (`de676b6`), 071 (`b3b6004`) all committed on `main`. `git status` is clean apart from this file.

## Recent commits (anchors)

- `b3b6004` feat(071) claude-md-capacity-index.
- `de676b6` feat(070) propagation-hygiene.
- `e45161a` fix(069) /product overwrite preserves .git + harness.
- `b170015` fix(068) gitleaks exemption — was `origin/main` at session start.
- 070+071 are **local commits** — not pushed; push `main` if origin tracking is wanted.

## Next steps

1. **Push `main`** if desired — 069/070/071 are local-only.
2. **070 follow-ups** (deferred, recorded in `.claude/memory/propagation-hygiene.md` § Not-yet-cleaned surfaces): (a) memory cross-references — rules/CLAUDE.md still point at specific `.claude/memory/<file>.md` which forks don't have; (b) spec citations in `.claude/hooks|tools|skills` code comments. Clean opportunistically; neither is spec-worthy alone yet.
3. **Already-synced forks + 071** — the managed-block merge went append-only → 3-way; a pre-071 fork hits a one-time `--force` first-sync (documented in `harness-sync.md` § CLAUDE.md managed-block merge).
4. **`/product` dogfood** — Gap F (069) fixed, so it is safe to run directly against the mei-saas repo (`clear-target.sh` preserves `.git/` + harness). `--stack=next`, original mei-saas idea string.
5. Spec 064 cron natural fire — Mon 2026-05-25 09:00 UTC.

## Decisions & gotchas

- **Stale branch `070-propagation-hygiene`** exists (created early in the session before work was redirected to `main`, matching the repo's 068/069 → main practice). Harmless; `git branch -d` it if tidiness wanted.
- **The CLAUDE.md merge was never "append-only".** `_merge_claude_md_managed_block` already wholesale-replaced the region; the real bug 071 fixed was that it had no baseline, so it refused on any section-body divergence. Fixed via baseline 3-way.
- **`sync-harness.sh` + `set -euo pipefail`** — any new bare-statement function called from `main` MUST `return 0` on its skip paths; a bare `return <non-zero>` aborts the whole script (cost 22/31 test failures before the one-char fix).
- **propagation-hygiene is a maintainer discipline in memory, not a rule** — a rule would ship to forks where it is inert, reproducing the leak it forbids.

## Carryover (orthogonal — not touched this session)

- Spec 046 dogfood gate due 2026-07-01; spec 029 adoption check due 2026-05-30.
- `.claude/REMINDERS.md` items per startup readout.
