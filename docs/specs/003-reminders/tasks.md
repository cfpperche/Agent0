# 003 — reminders — tasks

_Generated from `plan.md` on 2026-05-10. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. **Skill skeleton.** Create `.claude/skills/remind/SKILL.md` with frontmatter (`description`, `argument-hint: <add "<text>" [--due <YYYY-MM-DD>] | list | dismiss <N>>`), an `## Argument parsing` section that mirrors `/sdd`'s `$ARGUMENTS`-splitting guidance, and empty stub headers for `## Subcommand: add`, `## Subcommand: list`, `## Subcommand: dismiss`, `## Unknown subcommand`, and `## Notes`. After write, sanity-check that the skill name `remind` appears in the available-skills list (live skill discovery — no restart needed).
- [x] 2. **`add` subcommand.** Filled per spec: non-empty + no-newline + strict `^[0-9]{4}-[0-9]{2}-[0-9]{2}$` validation; first-use header creation; bullet shape `- <text>` or `- <text>  ·  due: <date>`; echo back `added: <line>`.
- [x] 3. **`list` subcommand.** Filled per spec: absent/empty → `no pending reminders`; otherwise verbatim cat + `<N> reminder(s)` count using the binding bullet definition (`^[[:space:]]*- ` after H1).
- [x] 4. **`dismiss` subcommand.** Filled per spec: absent-file refusal; positive-integer validation; in-range check with `dismiss: only <count> reminder(s); cannot dismiss <N>` format; deletes the Nth bullet only, preserves the rest in order; echoes `dismissed: <line>`.
- [x] 5. **Unknown subcommand + Notes.** Usage hint mirrors `argument-hint`; Notes restate the discipline (deletion-is-dismissal, no auto-commit, no stable IDs, not knowledge, not work-state).
- [x] 6. **Readout hook.** Created `.claude/hooks/reminders-readout.sh` (executable, POSIX-only). Verified output for (a) file with bullets → framed block with content, (b) file absent → `(no pending reminders)` inside the frame.
- [x] 7. **Wire hook in `settings.json`.** Appended a second `command` entry inside the existing `hooks.SessionStart[0].hooks` array. JSON re-validated with `jq` after the edit. _Note: between two reads of `settings.json`, the parallel 002-delegation work added `delegation-gate.sh` (PreToolUse:Agent) and `post-edit-validate.sh` (PostToolUse) entries. My edit is purely additive on the SessionStart array — no conflict._
- [x] 8. **Rule doc.** Created `.claude/rules/reminders.md` modeled after `session-handoff.md`: definition (vs `SESSION.md`, vs `MEMORY.md`); flow (skill writes, hook reads); what-to-write / what-NOT; discipline; files; gotchas.

## Verification

- [x] 9. **Walked the 7 spec acceptance scenarios end-to-end.** Results:
  1. `add "circle back on caching"` → file created with header, bullet appended, would echo `added: - circle back on caching`. ✓
  2. `add "review pricing" --due 2026-09-01` → bullet appended with `  ·  due: 2026-09-01` suffix. ✓
  3. `add "x" --due 2026/09/01` → refused with `add: --due must be strict YYYY-MM-DD (got: 2026/09/01)`, no file write. ✓
  4. `list` after three valid adds → file verbatim + `3 reminder(s)`. ✓
  5. `dismiss 2` → second bullet gone, first and third preserved in original order; would echo `dismissed: - review pricing  ·  due: 2026-09-01`. ✓
  6. `dismiss 7` against 2 remaining → refused with `dismiss: only 2 reminder(s); cannot dismiss 7`, file unchanged. ✓
  7. Hook output via direct invocation (`bash .claude/hooks/reminders-readout.sh`) produced the framed block with the current file content. Empty-state path tested by temporarily removing the file. ✓
- [x] 10. **File / git state confirmed.** `.claude/REMINDERS.md` is NOT in `.gitignore` (the only `.gitignore` change in this branch is from 002-delegation work). `reminders-readout.sh` has the executable bit set. `git status` shows all new files as untracked (not silently ignored). ✓
- [x] 11. **Hand off.** Updated `.claude/SESSION.md` — capacity in Current state #4, WIP captures the next-session smoke-check + test-data status + parallel 002-delegation context, Next steps proposes commit grouping, Decisions & gotchas restates reminders discipline.

## Notes

- **Granularity consolidation.** Tasks 1–5 were drafted to break the skill file into incremental writes for human-paced review. For AI-paced execution I wrote `SKILL.md` complete in one pass; each subcommand section matches the per-task contract independently. Boxes ticked because the content lands the contracts; git history shows one file creation rather than five.
- **Test data left in `.claude/REMINDERS.md`.** Three test bullets remain in the file after the verification walk (`circle back on caching`, `update README after auth lands`; `review pricing` was dismissed in scenario 5). Per the discipline (no auto-stage / no auto-commit / founder reviews diff), I did NOT delete them — the founder decides whether to commit the file empty-or-with-test-data, delete it for a clean slate (the skill recreates it on first real `add`), or replace with real reminders before the commit.
- **Parallel work in the same branch.** While this spec was in flight, a separate 002-delegation effort modified `.claude/settings.json`, `.gitignore`, and added `delegation-gate.sh` / `post-edit-validate.sh` / `validators/` / `rules/delegation.md`. All additive; no conflicts surfaced. Worth coordinating with the founder before any single commit to keep the histories clean (commit each spec's surface independently).
