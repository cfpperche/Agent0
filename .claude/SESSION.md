# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state

Three pieces of infrastructure shipped this session (`a037bf4` → `c944316` → `67c93a2` on `origin/main`):

1. **In-session compaction continuity** — `PreCompact` hook snapshots last 12 real user turns + assistant text/tool_use verbatim into `.claude/COMPACT_NOTES.md` (gitignored). `SessionStart` with `source=compact` re-injects it. `CLAUDE.md` has `## Compact Instructions` to steer the summarizer.

2. **Spec-driven development** — `/sdd` skill (`.claude/skills/sdd/`) scaffolds and progresses `docs/specs/NNN-<slug>/{spec,plan,tasks}.md`. Rule at `.claude/rules/spec-driven.md` defines when SDD applies (3+ files / new module / API change / vague request / reversibility cost) and when to skip (typo / rename / one-file fix). Templates use `{{NNN}} / {{SLUG}} / {{DATE}}` metadata + `{{intent}}` etc. content slots.

3. **Governance gate** — `.claude/hooks/governance-gate.sh` blocks three pattern families on `PreToolUse(Bash)`: destructive (`rm -rf` variants, `git push --force/-f`, `git reset --hard`), hook bypass (`git commit/push --no-verify`), and blanket staging (`git add -A/--all/./*`, `git commit -a/-am/-ma/--all`). Escape: inline `# OVERRIDE: <reason ≥10 chars>` marker. Spec at `docs/specs/001-governance-gate/`.

## WIP

Nothing in flight. All three pieces are committed, pushed, and dogfood-validated.

## Next steps

- Use `/sdd new <slug>` as the entry point for the next non-trivial change. The skill writes to `docs/specs/NNN-<slug>/`.
- If the governance gate misfires on a real workflow (false positive), capture the offending command + family and decide whether to refine the regex or accept the `# OVERRIDE:` marker as the right escape for that case.
- Watch for compaction in the next long session — verify the `COMPACT_NOTES.md` snapshot is useful when SessionStart re-injects it post-compact.

## Decisions & gotchas

- **Path discipline.** `.claude/` is *harness configuration* only (rules, skills, hooks, settings) — what the Claude Code runtime reads to shape its own behavior. `docs/` is *project artifacts* (specs, design memory). Specs live in `docs/specs/NNN-<slug>/` — dual-consumer, read by humans (review/audit) AND agents (execution guidance). Do not put specs under `.claude/`.

- **PreToolUse activates mid-session.** Unlike `SessionStart` / `Stop` (lifecycle-bound — register-on-next-session), `PreToolUse` activates immediately after the `settings.json` save. Confirmed empirically on `67c93a2`.

- **Governance self-test obstacle.** The gate scans the *entire* bash command string for patterns, so test runners that include `git push --force` etc. as fixture data trigger the gate against themselves. Workaround: write fixtures to a separate file via the Write tool (not Bash) and have the bash runner read them in. Same pattern for any future test infrastructure that needs to exercise the gate.

- **Combined-flag regex for `git <verb>`.** The pattern allows optional `([^[:space:];|&]+[[:space:]]+)*` between `git` and the verb so `git -C /path push --force`, `git --no-pager commit --no-verify`, etc. are caught. `--force-with-lease` stays allowed by design (the `\b` terminator and `([[:space:]]|$)` boundary excludes it).

- **Compaction notes are mechanical, not semantic.** PreCompact captures raw signal (user prompts verbatim, assistant text verbatim, tool names + truncated args). `/compact` already does the semantic summarization — a second semantic pass would be redundant and lossy. Tool outputs and thinking blocks are dropped (stale post-compact).

- **SDD content vs structure.** The `/sdd` skill provides *structure* (file scaffolding, template substitution); Claude provides *content* on the user's intent — never auto-fill `spec.md` without the user describing the change. Templates use `{{NNN}} / {{SLUG}} / {{DATE}}` metadata (substituted at scaffold time) plus content slots like `{{intent}}` / `{{criterion 1}}` (intentionally left for filling).

- **Skill discovery is live.** Adding `.claude/skills/<name>/SKILL.md` with valid frontmatter makes the skill appear in the available-skills list within the same session — no restart needed. Description changes also flow through.

- **`/plan` is built-in.** Avoid that name for user skills. Free names verified: `/spec`, `/sdd`, `/tasks`. The current skill is `/sdd` (subcommands `new`, `plan`, `tasks`, `list`) parsed from `$ARGUMENTS`, not `$1`/`$2` — harness substitution for positionals differs between slash invocation and Skill tool invocation.

- **OpenSpec is the documented upgrade path.** `.claude/rules/spec-driven.md` points at OpenSpec for multi-week / multi-contributor work. Doesn't conflict with `docs/specs/`; just adds an `openspec/` tree alongside.
