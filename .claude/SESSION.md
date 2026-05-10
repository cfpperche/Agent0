# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state

Four pieces of infrastructure on `main` (or in flight on this branch):

1. **Compaction continuity** — `PreCompact` snapshots last 12 real user turns into `.claude/COMPACT_NOTES.md` (gitignored); `SessionStart(source=compact)` re-injects it. `CLAUDE.md` § *Compact Instructions* steers the summarizer.

2. **Spec-driven development** — `/sdd` skill (`.claude/skills/sdd/`) scaffolds `docs/specs/NNN-<slug>/{spec,plan,tasks}.md`. Rule `.claude/rules/spec-driven.md`. Templates use `{{NNN}} / {{SLUG}} / {{DATE}}` metadata + content slots. End-to-end used for 003-reminders this session.

3. **Governance gate** — `.claude/hooks/governance-gate.sh` on `PreToolUse(Bash)` blocks destructive ops (`rm -rf` variants, `git push --force/-f`, `git reset --hard`), hook bypass (`--no-verify`), and blanket staging (`git add -A/--all/./*`, `git commit -a/-am/-ma/--all`). Escape: inline `# OVERRIDE: <reason ≥10 chars>`. Spec at `docs/specs/001-governance-gate/`.

4. **Reminders capacity** _(this session)_ — `/remind` skill (`.claude/skills/remind/SKILL.md`, subcommands `add "<text>" [--due <YYYY-MM-DD>]` / `list` / `dismiss <N>`). State file `.claude/REMINDERS.md` (git-tracked, created on first `add`). Second entry under `SessionStart[0].hooks` calls `.claude/hooks/reminders-readout.sh`, which cats the file (or `(no pending reminders)` in a frame) into context. Rule `.claude/rules/reminders.md`. Spec at `docs/specs/003-reminders/`.

## WIP

Reminders capacity is built and verified inside this session, with two tails:

- **Acceptance criterion #7 (session-start auto-surfacing) verifies only on the next session.** SessionStart hook registration is per-session, so the `reminders-readout.sh` entry registered in this session's `settings.json` save will actually fire only on the next session start. Smoke check on next start: the `=== REMINDERS ===` frame should appear with whatever bullets are in `.claude/REMINDERS.md` at that moment.

- **`.claude/REMINDERS.md` contains test data from the verification walk** — bullets `circle back on caching` and `update README after auth lands` (`review pricing` was dismissed in scenario 5). Per the no-auto-anything discipline I did not delete; founder reviews `git diff` and decides: commit empty, delete entirely (skill recreates on first real `add`), or replace with real reminders before the commit.

- **Parallel 002-delegation work is also in this branch.** Not from this session, but landed alongside: `.claude/hooks/delegation-gate.sh`, `.claude/hooks/post-edit-validate.sh`, `.claude/validators/`, `.claude/rules/delegation.md`, `docs/specs/002-delegation/`, plus a `.gitignore` addition (`.claude/.delegation-state/` and `.claude/delegation-audit.jsonl`). `settings.json` also gained a `PreToolUse(Agent)` entry and a `PostToolUse(Edit|Write|MultiEdit)` entry. No conflicts with reminders, but coordinate before committing so each spec's surface lands as a separate commit.

## Next steps

- **Smoke-check** on next session: confirm the `=== REMINDERS ===` frame appears at start. If not, inspect `settings.json` and re-trace `reminders-readout.sh`.
- **Commit grouping** (recommendation): one commit for 003-reminders (`.claude/skills/remind/`, `.claude/hooks/reminders-readout.sh`, `.claude/rules/reminders.md`, the `settings.json` SessionStart additive lines, `docs/specs/003-reminders/`), separate from 002-delegation. Decide on `REMINDERS.md` content (test bullets / empty / real) before staging.
- Use `/remind add ...` itself for any deferred items from this session that don't fit the next session's first five minutes.

## Decisions & gotchas

- **Path discipline.** `.claude/` is *harness configuration* (rules, skills, hooks, settings, state files) — what the Claude Code runtime reads to shape its own behavior. `docs/` is *project artifacts* (specs, design memory). Specs live in `docs/specs/NNN-<slug>/`.

- **PreToolUse activates mid-session; SessionStart / Stop don't.** SessionStart and Stop register on the *next* session. PreToolUse takes effect immediately after the `settings.json` save. This is why reminders auto-surfacing has to be smoke-checked next session.

- **Skill discovery is live.** A new `.claude/skills/<name>/SKILL.md` with valid frontmatter appears in the available-skills list within the same session — confirmed twice now (`sdd` and `remind`). Description changes also flow through.

- **`/plan` is built-in.** Avoid that name for user skills. `/remind`, `/sdd` verified free. For future skills: ask `claude-code-guide` before claiming a name — it checks current docs against the built-in list.

- **Governance self-test obstacle.** The gate scans the *entire* bash command string, so test runners that include `git push --force` etc. as fixture data trigger the gate against themselves. Workaround: write fixtures to a separate file via the Write tool (not Bash) and have the runner read them.

- **Combined-flag regex for `git <verb>`.** The gate's pattern allows optional `([^[:space:];|&]+[[:space:]]+)*` between `git` and the verb so `git -C /path push --force`, `git --no-pager commit --no-verify`, etc. are caught. `--force-with-lease` stays allowed by design.

- **Compaction notes are mechanical, not semantic.** PreCompact captures raw signal (user prompts verbatim, assistant text verbatim, tool names + truncated args). `/compact` does the semantic pass. Tool outputs and thinking blocks are dropped.

- **SDD content vs structure.** The `/sdd` skill provides *structure*; Claude provides *content* only after the user describes intent. Never auto-fill `spec.md`. Same discipline now applies to `/remind`: the skill executes a contract; it does not invent reminders.

- **Reminders ≠ memory ≠ session-state.** `/remind add` is for *action-shaped future items*. Facts and decisions → `MEMORY.md` (personal) or `.claude/rules/<topic>.md` (project). In-flight work → `SESSION.md`. One-file fixes → just do them.

- **Reminder dismissal is deletion, not check-marking.** Position numbers are display indices for the current `list` output only — re-list between multi-dismisses. Audit is `git log -- .claude/REMINDERS.md`, not an in-file archive.

- **OpenSpec is the documented upgrade path** for multi-week / multi-contributor specs (`.claude/rules/spec-driven.md`). Adds an `openspec/` tree alongside `docs/specs/` — no conflict.
