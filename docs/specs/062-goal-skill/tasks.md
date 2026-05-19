# 062 — goal-skill — tasks

_Generated from `plan.md` on 2026-05-19. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [ ] 1. **Pre-flight: native `/goal` compatibility check.** Run `/help` in Claude Code; check whether v2.1.139+ exposes a native `/goal`. Document the version present and whether it conflicts with our skill name. If conflict, either (a) rename skill to `/contract` or `/done-when`, or (b) confirm CC's namespace resolution prefers skill over native (verify per the SKILL.md description's primacy). Update plan if rename needed.
- [ ] 2. Read `.claude/skills/remind/SKILL.md` and `.claude/skills/sdd/SKILL.md` end-to-end for subcommand parsing convention + state-file path patterns.
- [ ] 3. Scaffold via `/skill new goal --tier cc-native` (the meta-skill). Confirm the generated SKILL.md frontmatter passes `/skill validate goal`.
- [ ] 4. Write `SKILL.md` body:
  - § Argument parsing (mirror `/sdd` pattern: `$ARGUMENTS`, split, first token is subcommand)
  - § Subcommand: `start "<description>"` — parse, ask 1-2 inference questions via `AskUserQuestion` if no `DONE_WHEN:` line, write state file
  - § Subcommand: `status` — read state file, format as table-ish summary
  - § Subcommand: `close [--override <reason ≥10 chars>]` — append history row, delete state file; `--override` allowed without verifier pass
  - § Subcommand: `list` — for now, alias of `status` (single active goal per session)
  - § State file shape (link to template)
  - § Loop budget mechanics (count, advance, exhaust)
  - § Compaction survival (rely on state file persistence + SessionStart re-inject)
- [ ] 5. Write `.claude/skills/goal/templates/state.json.tmpl`:
  ```json
  {
    "session_id": "{{SESSION_ID}}",
    "started_at": "{{ISO_TS}}",
    "description": "{{DESCRIPTION}}",
    "done_when": "{{VERIFIER}}",
    "iterations": 0,
    "budget": 10,
    "last_attempt_at": null,
    "last_attempt_result": null
  }
  ```
- [ ] 6. Write `.claude/skills/goal/references/loop-budget-tuning.md`:
  - When to raise budget (long-running verifications, e.g. multi-stack build)
  - When to lower (single-file changes — budget 3 is plenty)
  - `CLAUDE_GOAL_LOOP_BUDGET` env var override
- [ ] 7. Write `.claude/rules/goal-active.md`:
  - Frontmatter with `paths:` (verify in step 8 whether path-glob can predicate on existence; if not, drop and use unconditional load + top-of-body guard)
  - Body: "When `.claude/.goal-state/<session_id>.json` exists, before declaring task complete, run the recorded verifier. On pass, invoke `/goal close`. On fail, surface the failure and continue work. Loop budget enforced at the skill; do not exceed."
- [ ] 8. **Verify conditional rule loading.** Check `.claude/rules/rule-load-debug.md` and the `InstructionsLoaded` hook capacity to confirm whether `paths:` predicates can match on dynamic existence. If not, document the fallback (always load, top-of-body guard).
- [ ] 9. Update `.claude/hooks/session-start.sh`:
  - Detect active goal state file
  - If present, emit `=== /goal ACTIVE ===` block with description + done_when + iterations remaining
  - Place injection alongside `SESSION.md` and `COMPACT_NOTES.md` blocks
- [ ] 10. Verify `.claude/hooks/pre-compact.sh` does NOT need changes (state file persists across compaction automatically; only SessionStart re-injection matters).
- [ ] 11. Update `.gitignore`:
  - `.claude/.goal-state/*` (and `!.claude/.goal-state/.gitkeep`)
  - `.claude/.goal-history.jsonl`
  - `.claude/.goal-history.jsonl.lock`
- [ ] 12. Update `CLAUDE.md` § capacity inventory: add `## /goal` paragraph similar to `## Reminders` paragraph; cross-reference `user-prompt-framing.md` and `delegation.md`.
- [ ] 13. Update `.claude/rules/user-prompt-framing.md` § Cross-references — add link to `/goal` as the explicit-contract escalation path.
- [ ] 14. Manual dogfood: invoke `/goal start "ship some non-trivial task"`, complete it, verify the lifecycle end-to-end (state file created → verifier failure → re-iterate → verifier pass → state cleared → history row appended).

## Verification

- [ ] **Scenario: implicit DONE_WHEN** — `/goal start "fix the failing test"` → skill asks "What verifies done?" via AskUserQuestion with default options; user picks "bun test passes"; state file written with that verifier.
- [ ] **Scenario: explicit DONE_WHEN** — `/goal start "refactor X. DONE_WHEN: bun typecheck shows zero errors"` → no questions, state file written.
- [ ] **Scenario: verifier-driven completion** — agent declares done; rule directs verifier execution; on pass, history row appended; state file deleted; on fail, agent receives failure context and iterates.
- [ ] **Scenario: loop budget exhaustion** — pre-seed state file with `iterations: 10`; fire next "done" declaration; skill reports partial result + override path.
- [ ] **Scenario: compaction survival** — start a goal, force `/compact`, verify next SessionStart injects the goal state correctly.
- [ ] **Scenario: `/goal close --override "manual decision"`** — state file deleted, history row records override reason.
- [ ] `/skill validate goal` exits 0 (agentskills.io compliance)
- [ ] `jq -e .` round-trips on state file
- [ ] `.claude/.goal-history.jsonl` is gitignored (`git check-ignore` confirms)

## Notes

- The skill explicitly does NOT replace `user-prompt-framing.md` — the 3-question check stays as the lightweight default for substantive prompts. `/goal` is the opt-in escalation when the user wants the agent locked into a verifier loop.
- The skill creates an audit surface (`.claude/.goal-history.jsonl`) that joins naturally with the delegation audit log on `session_id`. Post-hoc analysis can ask "in this session, did the agent open a goal, dispatch N sub-agents, and close the goal?" — useful for spec-026 visibility intent (`.claude/memory/visibility-intent.md`).
- If `/skill new goal` reports a name collision with a native `/goal`, document the rename in `notes.md` and proceed with the alternative name. The mechanism is more important than the literal slash-command.
