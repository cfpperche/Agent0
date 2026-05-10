# 003 — reminders — plan

_Drafted from `spec.md` on 2026-05-10. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Mirror the existing capacity pattern in this repo: one **skill** (`/remind`) owns the user-facing actions; one **hook** owns the session-start injection; one **rule** documents the capacity for agents who don't load the skill. State lives in a single markdown file alongside `SESSION.md`, git-tracked, so it survives across machines and clones.

The skill at `.claude/skills/remind/SKILL.md` parses `$ARGUMENTS` (same pattern as `/sdd`) and dispatches to per-subcommand instructions that Claude executes with Read/Write/Edit/Bash. Validation lives in the skill prompt — not a separate script — because the validation surface is small (non-empty text; strict `YYYY-MM-DD`; positive integer in range) and matches how `/sdd` handles its own checks. The session-start readout is a separate, narrow shell hook (`reminders-readout.sh`) registered as a second entry in the existing `SessionStart` hooks array, rather than grafted onto `session-start.sh`. Two small scripts keep each concern independently toggle-able from `settings.json` and avoid entangling the source-branching logic in `session-start.sh`.

## Files to touch

**Create:**

- `.claude/skills/remind/SKILL.md` — skill entry. Frontmatter (`description`, `argument-hint`) plus a subcommand-dispatch body modelled on `.claude/skills/sdd/SKILL.md`. Three subcommand sections (`add`, `list`, `dismiss`), an unknown-subcommand fallback, and a Notes section restating the discipline (no auto-stage/commit, no checkbox-marking, no ID promises).
- `.claude/hooks/reminders-readout.sh` — POSIX bash. Reads `${CLAUDE_PROJECT_DIR}/.claude/REMINDERS.md`; if the file is absent or has no bullet lines (`^[[:space:]]*- `), prints a one-line "no pending reminders" message inside a framed block consistent with `session-start.sh`'s formatting; otherwise prints the file verbatim inside the same frame. No `set -e` surprises — degrade silently if the file is unreadable.
- `.claude/rules/reminders.md` — short capacity doc: what reminders are, what they are NOT (vs `SESSION.md`, vs `MEMORY.md`), the discipline (deletion-is-dismissal, no stable IDs, no auto-commit), and a pointer to the skill. Same shape as `session-handoff.md` / `compaction-continuity.md`.

**Modify:**

- `.claude/settings.json` — extend the existing `SessionStart` array with a second hook entry running `reminders-readout.sh`. No other changes.

**Delete:**

- _none._

State file (`.claude/REMINDERS.md`) is **created on first `/remind add`** by the skill itself, not committed empty. The header text on first creation is `# Reminders` followed by a blank line.

## Alternatives considered

### Single combined hook (extend `session-start.sh`)

Rejected. `session-start.sh` already branches on `source` (`startup` / `resume` / `clear` → `SESSION.md`; `compact` → `COMPACT_NOTES.md`). Grafting a third concern onto that branch tree entangles the kill-switches: disabling the readout would require commenting code inside `session-start.sh` instead of just removing one entry from `settings.json`. Two narrow scripts under one `SessionStart` array stays composable and matches the existing-hook style (each `.sh` does one thing).

### Stable IDs per reminder (timestamp prefix or short hash)

Rejected. IDs would make `dismiss <id>` survive reordering and concurrent edits — but reordering doesn't happen (append-only between mutations) and concurrency doesn't happen (single-user workflow). What IDs *would* introduce: extra width per bullet in the session-start readout, a parse-vs-display mismatch ("the user sees position 4, the file says id `1762`"), and an implicit promise to support `edit <id>` later that we don't want to make. Position-as-display-index is simpler and matches how someone reads the file by eye.

### JSON / sqlite state file

Rejected. The whole premise of the capacity is "single readable file, hook just `cat`s it". JSON loses readability and forces `reminders-readout.sh` to either dump raw JSON or render it (adding logic and a parser dependency). Sqlite loses grep, `git diff`, and human-edit affordances entirely. Plain markdown keeps every consumer (founder eyeballing, agent reading the injection, future tooling) on the same surface.

### Per-item file under `.claude/reminders/`

Rejected. Multi-file means: `list` becomes a directory walk with sort-key questions; `dismiss N` becomes ordering-dependent across the filesystem; the readout hook has to iterate and concatenate; "added one reminder" shows up in `git status` as a new file rather than a one-line diff. Bounded count + action-shaped content means single file is the right granularity.

## Risks and unknowns

- **Bullet-line detection.** `dismiss N` and `list`'s count both depend on identifying which lines are bullets. Definition (locked here): a bullet is a line whose first non-whitespace character is `-` followed by a space, occurring **after** the H1 header. The skill enforces single-line bullets — `add` rejects text containing newlines so continuation lines can't drift the count.
- **First-`add` header creation.** When `.claude/REMINDERS.md` is absent, `add` must create it with the H1 (`# Reminders`) before appending. `dismiss` and `list` must behave correctly when the file is absent (skip silently for `dismiss` with the standard out-of-range error path; emit "no pending reminders" for `list`).
- **POSIX portability of the hook.** Confirmed environment: WSL2 bash 4+. The hook uses only `cat`, `grep -E`, `printf` — no GNU-only flags. Tasks phase verifies on this environment.
- **Readout when empty.** Spec acceptance requires a "single short line, not multi-line block" when there are no reminders. Implementation choice: a 3-line framed block (`=== REMINDERS ===\n(no pending reminders)\n=== end REMINDERS ===\n`) consistent with the other SessionStart frames. If that reads as noisy in practice, fall back to a single unframed line in a follow-up — not blocking this spec.
- **Concurrent edit by the founder.** Out of scope. Read-modify-write within one `/remind` call is atomic; interleaving with a human editor open is the founder's choice and not defended against.
- **Built-in name collision.** Resolved: `/remind` is not a Claude Code built-in (confirmed via `claude-code-guide` this session).

## Research / citations

- **`/remind` name availability** — confirmed not a built-in slash command in current Claude Code. Source: https://code.claude.com/docs/en/skills.md (skills configuration section, surfaced via the `claude-code-guide` agent on 2026-05-10). Skills take precedence over built-ins of the same name, so the name is doubly safe.
- **In-repo prior art consulted** (no external sources needed):
  - `.claude/skills/sdd/SKILL.md` — subcommand parsing via `$ARGUMENTS`, frontmatter shape, unknown-subcommand fallback.
  - `.claude/hooks/session-start.sh` — SessionStart hook shell template, framed-block output convention, `CLAUDE_PROJECT_DIR` env var.
  - `.claude/rules/session-handoff.md`, `.claude/rules/compaction-continuity.md` — adjacent state-file-plus-hook documentation shape.
