# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state

Seven capacities on `main` plus the foundational hooks (compaction continuity, session handoff). Listed in spec order:

1. **Compaction continuity** — `PreCompact` snapshots last 12 real user turns into `.claude/COMPACT_NOTES.md` (gitignored); `SessionStart(source=compact)` re-injects it. `CLAUDE.md` § *Compact Instructions* steers the summarizer.

2. **Spec-driven development** — `/sdd` skill scaffolds `docs/specs/NNN-<slug>/{spec,plan,tasks}.md`. Rule `.claude/rules/spec-driven.md`. The workflow has been the spine of every non-trivial change for four specs running; dogfood reliably catches design bugs cheaply during plan/task execution.

3. **Governance gate** _(spec 001)_ — `.claude/hooks/governance-gate.sh` on `PreToolUse(Bash)`. Blocks destructive ops, hook bypass, blanket staging. Escape: inline `# OVERRIDE: <reason ≥10 chars>`.

4. **Delegation capacity** _(spec 002, `c2d15f9`)_ — `PreToolUse(Agent)` enforces a 5-field handoff (TASK / CONTEXT / CONSTRAINTS / DELIVERABLE-or-DONE_WHEN), logs to `.claude/delegation-audit.jsonl`, emits an opus-escalation advisory on ≥2 signals. `PostToolUse(Edit|Write|MultiEdit)` runs `.claude/validators/run.sh` on sub-agent edits only (parent edits exempt by `agent_id` detection), with a per-agent loop budget of 5. Rule `.claude/rules/delegation.md`.

5. **Reminders capacity** _(spec 003, `eb2dd2e` + `657df34`)_ — `/remind` skill with `add | list | dismiss`. State at `.claude/REMINDERS.md`. SessionStart hook `reminders-readout.sh` surfaces it at start. Rule `.claude/rules/reminders.md`.

6. **BDD acceptance scenarios** _(spec 004, `2689c49`)_ — `/sdd` template now scaffolds acceptance criteria as Given/When/Then scenarios for behavior + plain checkbox bullets for static facts. Rule extension at `.claude/rules/spec-driven.md § Acceptance scenarios`. Empirically validated: a delegated sub-agent can verify a scenario directly from `spec.md` with zero follow-up clarification (live test, 2 tool calls). Specs 001-003 keep their flat checklists as historical record.

7. **TDD working agreement** _(spec 005, `3115cf6`)_ — Cultural discipline (red→green→refactor), reinforced by an additive `warnings` field on the validator JSON contract. `.claude/validators/run.sh` detects per-stack test patterns + honors `CLAUDE_TDD_TEST_PATTERNS` env var override + unions `git diff` with `git ls-files --others --exclude-standard` to catch untracked test files. `post-edit-validate.sh` echoes each warning to stderr with `tdd-advisory:` prefix on exit-0 paths. Rule `.claude/rules/tdd.md`. Inert in this base repo (no language stack); fires when a project plugs in a stack.

## WIP

Nothing in flight. Branch is at `origin/main` after this session (`3115cf6` pushed).

## Next steps

- **Cross-session smoke** on next start: confirm the `=== REMINDERS ===` frame appears (003 acceptance #7, deferred from the original /remind session) and that the delegation gate fires on the first real `Agent` call (audit log gains an entry, advisory surfaces if signals fire).
- **Validator inert in this base repo** — remains the dogfood baseline. When this template is forked into a real project: edit `.claude/validators/run.sh` per-stack branches with the actual typecheck+test commands, OR set `CLAUDE_DELEGATION_VALIDATOR=/abs/path` to a project script that emits the JSON contract. The TDD warnings logic also activates automatically once a stack is detected.
- **Optional next iterations** if the discipline gets exercised hard and exposes friction:
  - `Background` shared-Given section in BDD scenarios (parked in 004 plan as "revisit if specs feel repetitive").
  - Per-`agent_id` file-tracking in the validator (parked in 005 plan as "revisit if `git diff` parent+sub conflation produces real false-results").
  - `cd "$CLAUDE_PROJECT_DIR"` at the top of `run.sh` to fix the parent-side test gotcha (see § *Decisions & gotchas*).

## Decisions & gotchas

- **Path discipline.** `.claude/` is *harness configuration* (rules, skills, hooks, settings, state files). `docs/` is *project artifacts* (specs as design memory). Specs live in `docs/specs/NNN-<slug>/`, never under `.claude/`.

- **Activation timing of hook events.** `PreToolUse` and `PostToolUse` activate immediately after the `settings.json` save. `SessionStart` and `Stop` register on the *next* session — that's why "reminders auto-surface" and "session-handoff Stop nag" need cross-session smoke checks rather than same-session validation.

- **Skill discovery is live.** A new `.claude/skills/<name>/SKILL.md` with valid frontmatter appears in the available-skills list within the same session. Description changes also flow through.

- **`/plan` is built-in.** Avoid that name for user skills. `/remind`, `/sdd` verified free. For new skills: ask `claude-code-guide` before claiming a name.

- **Compaction notes are mechanical, not semantic.** `PreCompact` captures raw signal (user prompts verbatim, assistant text verbatim, tool names + truncated args). `/compact` does the semantic pass. Tool outputs and thinking blocks are dropped.

- **SDD content vs structure.** The `/sdd` skill provides *structure*; Claude provides *content* only after the user describes intent. Never auto-fill `spec.md`. Same discipline applies to `/remind`.

- **Override marker (delegation 002): start-of-line anchored + audit-honest.** Dogfood-discovered: original unanchored regex captured `# OVERRIDE:` from prose that *documented* the marker. Fix: anchored to `^[[:space:]]*# OVERRIDE: `, AND validation always runs (override only suppresses the *block*, not the check). Governance gate still uses the unanchored shape — port if it ever hits the same false-positive class.

- **`agent_id` IS in PostToolUse payload** (undocumented but reliable). Spec 002 plan.md captures the discovery. `session_id` and `transcript_path` are inherited from parent and useless for actor detection — only `agent_id` discriminates. Loop-budget counters key on `agent_id`.

- **`additionalContext` from PreToolUse renders as `system-reminder`** in the parent's next turn. Confirmed empirically (002 + 004 live tests). The same channel carries TDD warnings via stderr echo from the post-edit hook.

- **Validator stack-detection is cwd-anchored, not `CLAUDE_PROJECT_DIR`-anchored.** `[ -f bun.lockb ]` resolves against `pwd`, not the env var. In production this is fine — the harness sets cwd to the project dir before invoking the hook. But parent-side tests need `(cd $TMP && bash <repo>/.claude/validators/run.sh)` to actually trigger detection. Fixable with `cd "${CLAUDE_PROJECT_DIR:-$PWD}" || exit 0` at the top of `run.sh`; not done because the gap is parent-side-test-only and the validator stays small.

- **Bash gotchas in `.claude/rules/delegation.md`** — both bit during post-edit-validate.sh implementation: (1) `jq '.field // empty'` collapses `false` and missing into the same empty string — use `if type=="object" and has("ok") then (.ok|tostring) else ""`. (2) `exec N>file 2>/dev/null` is a *sticky* stderr redirect that permanently silences FD 2. Probe writability in a subshell first.

- **`git diff --name-only` does NOT include untracked files** (caught by spec 005 dogfood). A sub-agent's `Write` of a new test file leaves it untracked; plain `git diff` would miss it and the TDD warning would falsely fire. Validator unions `git diff --name-only` with `git ls-files --others --exclude-standard` and dedupes via `sort -u`.

- **Dogfood loop is the design discipline.** Three real bugs (override marker false-positive in 002, jq-`// empty` + sticky-stderr-redirect in 002, untracked-files in 005) all surfaced via real implementation passes, not by review. The pattern: delegate substantial implementation to sub-agents with full 5-field briefs, parent runs verification + cross-doc updates + commit. Cheaper than testing in CI; faster than catching in review.

- **OpenSpec is the documented upgrade path** for multi-week / multi-contributor specs (`.claude/rules/spec-driven.md`). Adds an `openspec/` tree alongside `docs/specs/` — no conflict.
