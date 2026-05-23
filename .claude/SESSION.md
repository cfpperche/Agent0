# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Session 2026-05-23 — spec 081 shipped end-to-end.** `/sdd plan` → `/sdd tasks` → implementation → tests → commit, all in one session under `/goal`. Commit `aa0b12b` (`feat(081): per-compaction history + runtime-state README`) — 17 files, +602/-71. Umbrella 080 MS-3 + MS-6 rows flipped to ✓. 5/5 test scenarios green under `.claude/tests/compaction-continuity/`.

## WIP — resume point

**No active WIP.** 081 is closed; tree is clean; 2 commits ahead of origin/main (the 079 carryover from prior session + 081 from this session).

Next umbrella child to scaffold: **082** (MS-1 frontmatter schema + PostToolUse advisory validator). Foundation for 083 (MS-2 event-sourcing) and 085 (MS-5+MS-7 cap+query+decay). 083/084/085 still unscaffolded.

## Next steps

1. `/sdd new memory-frontmatter-schema` (or similar slug) → scaffold 082 from the 080 gap-matrix MS-1 row.
2. After 082 ships → 083 (depends on 082) → 084/085 parallel-safe.
3. **Carryover:** 076 implementation (plan + tasks drafted); 075 task 14 (`/product` dogfood scenarios 3-6).
4. Dated reminders due: 029 05-30 · 035 06-07 · 046 07-01 · 060 07-19.
5. Push `aa0b12b` + prior carryover commit when ready (`git push origin main`).

## Decisions & gotchas

- **gitignore `dir/` blocks `!dir/file` exceptions.** Known git gotcha — when a parent dir is matched by `dir/` wholesale, the `!` exception inside it is skipped. Use `dir/*` (ignore contents glob) instead. Bit me on 081's runtime-state README; logged in `docs/specs/081-compact-history-runtime-readme/notes.md`. Rule-of-three demand test for promotion to `.claude/memory/<topic>.md` — one incident, wait for two more.
- **`set -euo pipefail` + unmatched glob trips the hook.** `ls dir/*.md 2>/dev/null | tail -1` in an empty dir returns non-zero through `pipefail`. Scope `|| true` to the failing step: `{ ls ... || true; } | tail -1`. Already in session-start.sh; same pattern likely needed elsewhere.
- **Agent0-as-product framing.** Rule-of-three demand test applies to speculative tooling inside the repo; does NOT apply to capacities Agent0 ships to forks. (Carried from prior session — still load-bearing for 082+.)
- **Decay engine pattern (085): mechanism + transparent overridable defaults.** ~10-line bash formula, all numerics in `.claude/memory.config.json`. Mirrors `delegation-gate` / `secrets-scan` shape. (Carried — relevant for 085 design.)
- **Słomka quote verbatim** for Hermes blog (due 2026-06-30): *"Skill poisoning is prompt injection with a save button."* Krzysztof Słomka, Medium 2026-04-20.

## Carryover (orthogonal — not touched this session)

- **076** — plan + tasks drafted, ready to implement.
- **075 task 14** — `/product` dogfood scenarios 3-6 pending.
- `docs/specs/074-subagent-personas/` — untracked draft; leave for originating session.
- `.claude/REMINDERS.md` items per startup readout.
