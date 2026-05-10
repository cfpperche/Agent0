# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state

Five capacities on `main`, plus the two foundational hooks (compaction continuity, session handoff). Listed in spec order:

1. **Compaction continuity** — `PreCompact` snapshots last 12 real user turns into `.claude/COMPACT_NOTES.md` (gitignored); `SessionStart(source=compact)` re-injects it. `CLAUDE.md` § *Compact Instructions* steers the summarizer.

2. **Spec-driven development** — `/sdd` skill (`.claude/skills/sdd/`) scaffolds `docs/specs/NNN-<slug>/{spec,plan,tasks}.md`. Rule `.claude/rules/spec-driven.md`. End-to-end used for 002-delegation this session, with the workflow paying off when dogfood revealed bugs cheaply during plan/task execution.

3. **Governance gate** _(spec 001)_ — `.claude/hooks/governance-gate.sh` on `PreToolUse(Bash)`. Blocks destructive ops, hook bypass, blanket staging. Escape: inline `# OVERRIDE: <reason ≥10 chars>`.

4. **Delegation capacity** _(spec 002, this session, `c2d15f9`)_ — Two hooks plus a project-side validator. `PreToolUse(Agent)` via `.claude/hooks/delegation-gate.sh` enforces a 5-field handoff (TASK / CONTEXT / CONSTRAINTS / DELIVERABLE-or-DONE_WHEN), logs every dispatch to `.claude/delegation-audit.jsonl`, and emits an opus-escalation advisory when 2+ signals fire on a non-opus model. `PostToolUse(Edit|Write|MultiEdit)` via `.claude/hooks/post-edit-validate.sh` runs `.claude/validators/run.sh` on sub-agent edits only (parent edits exempt by `agent_id` detection), with a per-agent loop budget defaulting to 5. Same `# OVERRIDE:` escape as governance. Rule `.claude/rules/delegation.md`.

5. **Reminders capacity** _(spec 003, prior session + this session's `657df34`)_ — `/remind` skill with subcommands `add | list | dismiss`. State at `.claude/REMINDERS.md`. SessionStart hook `reminders-readout.sh` surfaces it at start. Rule `.claude/rules/reminders.md`.

## WIP

Nothing in flight. Both 002-delegation and the deferred 003-reminders `settings.json` wiring landed this session.

## Next steps

- **Cross-session smoke** on next start: confirm the `=== REMINDERS ===` frame appears (the 003 acceptance criterion #7 deferred from the prior session) and that the delegation gate fires on the first real `Agent` call (audit log gains an entry, advisory surfaces if signals fire).
- **Push to origin** — branch is 2 commits ahead of `origin/main` after this session.
- **Validator is currently inert** in this base repo (no language stack → `no-stack-detected` → `ok=true` always). When this template is forked into a real project, plug in the actual typecheck+test commands by editing `.claude/validators/run.sh` (or override at runtime via `CLAUDE_DELEGATION_VALIDATOR=/abs/path`).

## Decisions & gotchas

- **Path discipline.** `.claude/` is *harness configuration* (rules, skills, hooks, settings, state files) — what the Claude Code runtime reads to shape its own behavior. `docs/` is *project artifacts* (specs, design memory). Specs live in `docs/specs/NNN-<slug>/`.

- **PreToolUse activates mid-session; SessionStart / Stop / PostToolUse don't.** SessionStart and Stop register on the *next* session. PreToolUse takes effect immediately after the `settings.json` save. PostToolUse also activates mid-session (confirmed via the dogfood probe this session). This is why reminders auto-surfacing has to be smoke-checked next session.

- **Skill discovery is live.** A new `.claude/skills/<name>/SKILL.md` with valid frontmatter appears in the available-skills list within the same session — confirmed three times now (`sdd`, `remind`, plus the dogfood Skill invocations).

- **`/plan` is built-in.** Avoid that name for user skills. `/remind`, `/sdd` verified free. For future skills: ask `claude-code-guide` before claiming a name.

- **Compaction notes are mechanical, not semantic.** PreCompact captures raw signal (user prompts verbatim, assistant text verbatim, tool names + truncated args). `/compact` does the semantic pass. Tool outputs and thinking blocks are dropped.

- **SDD content vs structure.** The `/sdd` skill provides *structure*; Claude provides *content* only after the user describes intent. Never auto-fill `spec.md`. Same discipline applies to `/remind`.

- **Override marker (delegation 002): start-of-line anchored + audit-honest.** Discovered during dogfood: the original unanchored regex captured `# OVERRIDE:` from prose that *documented* the marker, treating a perfectly formatted brief as a bypass. Fix: anchored to `^[[:space:]]*# OVERRIDE: `, AND validation always runs (override only suppresses the *block*, not the check). Audit `formatted` field reflects the actual check result, not whether validation was skipped. Same shape governance still uses but with this refinement — consider porting if governance ever has the same false-positive class.

- **`agent_id` IS in PostToolUse payload.** Documented as not exposed (`code.claude.com/docs/en/hooks.md`); empirically present and reliable. Spec 002 plan.md captures the discovery. `session_id` and `transcript_path` are *inherited from parent* and useless for actor detection — only `agent_id` discriminates. Loop-budget counters key on `agent_id`.

- **`additionalContext` from PreToolUse renders as system-reminder in parent.** Plan-flagged risk #2 ("not yet confirmed empirically that the parent agent reliably sees the advisory") resolved positive: the harness injects the string verbatim as a `system-reminder` block on the parent's next turn after the `Agent` dispatch. Confirmed via the live dogfood.

- **Two bash gotchas now in `.claude/rules/delegation.md`** — both bit during post-edit-validate.sh implementation and would re-bite anyone copying the patterns: (1) `jq '.field // empty'` collapses `false` and missing into the same empty string, so validator `ok=false` silently fails-open; use `if type=="object" and has("ok") then (.ok|tostring) else "" end`. (2) `exec 9>"$LOCK_PATH" 2>/dev/null` is a *sticky* stderr redirect — it permanently silences FD 2 for the rest of the script. Probe writability in a subshell first.

- **OpenSpec is the documented upgrade path** for multi-week / multi-contributor specs (`.claude/rules/spec-driven.md`). Adds an `openspec/` tree alongside `docs/specs/` — no conflict.
