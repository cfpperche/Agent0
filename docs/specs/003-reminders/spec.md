# 003 — reminders

_Created 2026-05-10._

**Status:** shipped

## Intent

Long-running projects accumulate *deferred intent* — action-shaped items that aren't urgent enough to do now but shouldn't be lost ("circle back on caching when the first user complains", "review pricing assumption in Q3", "update README after the auth refactor lands"). Today these sit in three failure-prone places: chat scrollback (lost on `/clear` or compaction), `TODO` comments in code (rot with the file, invisible across the repo), or the founder's head (lossy).

This capacity gives the agent and the founder one plain-text, greppable, diff-able place to capture, list, and dismiss those items. Mechanism is intentionally minimal: a single markdown file with a bullet list, optionally tagged with a due date, cat'd into context at session start so deferred items resurface without anyone remembering to look. It is not a task manager, not a knowledge base, and not a session work-state log — it complements the existing `SESSION.md` (in-flight work) and `MEMORY.md` (durable knowledge) by occupying the third gap: *future* work too small or too distant for either.

## Acceptance criteria

The capacity is delivered when all of the following hold against a fresh session of this repo.

**Surface**

- [ ] A slash command `/remind` exists with three subcommands: `add`, `list`, `dismiss`.
- [ ] The reminders state file lives at `.claude/REMINDERS.md` and is git-tracked (no entry in `.gitignore`).
- [ ] A `SessionStart` hook reads `.claude/REMINDERS.md` and injects its content (or a friendly "no pending reminders" line if absent/empty) into the agent's context, alongside the existing `SESSION.md` injection.

**`add "<text>" [--due <YYYY-MM-DD>]`**

- [ ] Refuses with a clear error if `<text>` is missing or empty after trim — no file write.
- [ ] If `--due` is provided, validates strict `YYYY-MM-DD` (e.g. `2026/09/01` or `2026-9-1` → refused, no file write).
- [ ] On first use, creates `.claude/REMINDERS.md` with a top-level header.
- [ ] Appends one bullet line per call: `- <text>` without due date; `- <text>  ·  due: <date>` (visually-separated suffix) when `--due` given.
- [ ] Reports back exactly what was added.

**`list`**

- [ ] If the file is absent or contains no bullets, emits a friendly "no pending reminders" message and exits.
- [ ] Otherwise outputs the file verbatim — no renumbering, no filtering, no transformation.
- [ ] Reports the bullet count; positions are the bullet's 1-indexed order top-to-bottom (header and blank lines do not count).

**`dismiss <N>`**

- [ ] Refuses if the file doesn't exist, if `N` is not a positive integer, or if `N` is out of range (error includes the current bullet count).
- [ ] Deletes the Nth bullet line (1-indexed) and only that line — header, blank lines, and the other bullets are preserved exactly, in original order, with no renumbering.
- [ ] Does NOT mark with a checkbox, move to an archive section, or rewrite the file beyond removing the one line. Deletion IS dismissal.
- [ ] Reports the dismissed bullet's text back to the user.

**Session-start surfacing**

- [ ] Starting a new session in this repo shows the current reminders without the agent (or the user) running `/remind list`.
- [ ] If there are no reminders, the read-out is a single short line, not a multi-line block.

## Non-goals

- **Not a task manager.** No priorities, no assignees, no status fields beyond presence/absence, no sub-tasks, no dependencies.
- **Not a knowledge base.** Facts, decisions, conventions, and learnings belong in `MEMORY.md` or `.claude/rules/`. Reminders are for *do this thing*, not *know this thing*.
- **Not a session work-state log.** In-flight work belongs in `SESSION.md`. Reminders are *future* work that won't fit the next session's first five minutes.
- **No alternative storage.** No JSON, no sqlite, no per-item file, no separate due-date index. One markdown file is the contract — the hook just cats it.
- **No stable IDs.** Position numbers are display indices for the current `list` output only. The pattern is "list, then dismiss the position you see right now" — re-list between multi-dismisses. Do not introduce IDs, hashes, slugs, or timestamps to make positions stable.
- **No auto-stage, no auto-commit.** Every mutation leaves the file dirty in the working tree; the founder reviews before history is written. Git diff is the audit trail.
- **No history / archive section.** Reminders are pure current-state. Dismissed items are gone from the file; the git log of `.claude/REMINDERS.md` is the only history.
- **No checkbox-marking on dismiss.** The deletion is the dismissal — both because it keeps the file lean and because it keeps the session-start injection short.

## Open questions

- [ ] Confirm `/remind` is not a built-in Claude Code slash command (built-ins shadow user skills, per the `/plan` lesson in `SESSION.md`). Fallback names if shadowed: `/reminders`, `/recall`.
- [ ] Decide whether the session-start read-out is a second entry in the existing `SessionStart` hook array (separate script `reminders-readout.sh`) or an extension of `session-start.sh`. Lean toward separate script for separation-of-concerns; plan phase to confirm.

## Context / references

- `.claude/rules/session-handoff.md` — `SESSION.md` as in-flight work-state. Reminders are deliberately disjoint from this.
- `.claude/rules/compaction-continuity.md` — adjacent state-file-plus-hook pattern (`COMPACT_NOTES.md` written by `PreCompact`, injected by `SessionStart`). Reminders follow the same shape but with manual write (via `/remind add`) instead of hook write.
- `.claude/rules/memory-placement.md` — disambiguates project-shared state vs personal memory. Reminders chosen as project-shared (`.claude/REMINDERS.md`, git-tracked).
- `.claude/skills/sdd/SKILL.md` — `/remind` will follow the same subcommand-parsing pattern (parse `$ARGUMENTS`, not positionals).
