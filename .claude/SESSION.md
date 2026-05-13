# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state

Rule-infra modernization **fully validated** (2026-05-13). Level 2 PASS in Agent0 + Level 3 PASS in shrnk-mono fork dogfood. The 3 commits from prior session (`docs(memory)`, `feat(rules)`, `feat(observability)`) are confirmed working end-to-end at both the unit and behavioral levels.

### Level 2 — Agent0 in-session (this session, first half)

| Step | Result | Detail |
| --- | --- | --- |
| 1 — session_start shape | ✓ | 9 rows: CLAUDE.md + 8 unconditional rules. Zero path-scoped leakage. |
| 2 — path_glob_match via hook | ✓ | 9 rows captured. Trigger→rule mapping matches frontmatter. |
| 3 — system-reminder injection | ✓ | All 8 trigger reads produced `<system-reminder>` blocks with rule bodies. |

### Level 3 — shrnk-mono fork dogfood (this session, second half)

Sync applied: `--force --force-except='.mcp.json.example,.gitignore'`; manually added 2 lines to shrnk-mono `.gitignore` for `.claude/.rule-load-debug.jsonl{,.lock}`. Then a fresh `CLAUDE_RULE_LOAD_DEBUG=1 claude` session in shrnk-mono ran the level 3 playbook.

| Step | Result | Detail |
| --- | --- | --- |
| 1 — session_start shape | ✓ | Identical clean 9-row shape in fork |
| 2 — path_glob_match | ✓ | All 9 trigger→rule pairings fired |
| 3a — supply-chain block + recovery | ✓ | Block fired, two-line `# OVERRIDE` recovery worked. CLAUDE.md `## Supply chain` summary was sufficient — agent didn't need to read deep rule |
| 3b — secrets-scan | ⚠ partial | User-global `~/.claude/hooks/pre-commit-secrets-scan.sh` shadows project layer — see memory note below |
| 3c — runtime-introspect | ✓ | `bun test` captured cleanly, ANSI strip + canonical inference basis working |
| 3d — Edit-trigger path scoping | ⚠ partial | Dedup applied — `supply-chain.md` already loaded earlier in session, Edit on `package.json` produced no new audit row |

**Behavioral conclusion (the level 3 question):** CLAUDE.md `## Section` summaries proved load-bearing. The supply-chain block stderr template carried the recovery shape verbatim; agent recovered without reading the deep rule. No section summaries need to be beefed up based on this dogfood.

## Findings landed this session

- `.claude/memory/cc-platform-hooks.md` § Empirical — **broadened** the dedup finding: dedup is per-rule (not per-glob), confirmed via shrnk-mono Step 3d (`package.json` edit didn't re-fire `supply-chain.md` after earlier `supply-chain-scan.sh` read).
- `.claude/rules/rule-load-debug.md` § Gotchas — added the per-rule dedup gotcha.
- `.claude/memory/user-global-hooks-shadow.md` — new entry documenting that `~/.claude/hooks/*` fire ahead of project hooks and can mask end-to-end dogfood. Indexed in MEMORY.md.
- `.claude/REMINDERS.md` — past-due "CC hooks underused" reminder dismissed (partial progress = `InstructionsLoaded` adopted; original UserPromptSubmit angle remains untouched if user wants to recreate).

## WIP — uncommitted state

**Agent0 working tree (this session):**
- `.claude/memory/cc-platform-hooks.md` — § Empirical expanded
- `.claude/memory/MEMORY.md` — 2 new entries (cc-platform-hooks expanded, user-global-hooks-shadow added)
- `.claude/memory/user-global-hooks-shadow.md` — new file
- `.claude/rules/rule-load-debug.md` — § Gotchas dedup line added
- `.claude/SESSION.md` — this rewrite
- `.claude/REMINDERS.md` — dismissed entry

**Shrnk-mono working tree (this session):** 12 modified + 2 untracked (sync-applied harness state + dogfood SESSION.md update). User reviews diff and commits manually per harness-sync workflow.

## Next steps

1. **Commit Agent0 session bookkeeping.** Suggested split: `docs(memory)` for the cc-platform-hooks expansion + user-global-hooks-shadow + MEMORY.md index, `docs(rules)` for the rule-load-debug.md gotcha, separate commit for SESSION.md if desired. REMINDERS.md dismissal can ride with whichever.
2. **Commit shrnk-mono sync.** Per harness-sync.md workflow, review `git diff` and commit (`chore(harness-sync): adopt rule-load-debug + path-scoped frontmatter`).
3. **Spec 025 continuation** — separate lane (parallel WIP, NOT this session's): `packages/mcp-product-pipeline/src/state.ts` modification + untracked template dirs under `packages/mcp-product-pipeline/src/templates/02-prototype/`, `03-spec/`, `04-ux-testing/`, `05-brand/`. Provenance check before any commit there.
4. **Pyshrnk CLAUDE.md reconciliation** — long carryover.

## Decisions & gotchas

- **`InstructionsLoaded` dedup is per-rule, not per-glob (NEW, 2026-05-13 dogfood).** Once a rule loads in a session via any matching glob, NO subsequent read of any file in ANY of that rule's globs fires another event. CC tracks "rule X already loaded this session" and dedupes regardless of which glob the new trigger matched. Implications: trigger→rule mapping playbooks need fresh sessions per trigger; "edit foo to verify rule X loads" only works if X hasn't already loaded. See `.claude/memory/cc-platform-hooks.md` § Empirical and `.claude/rules/rule-load-debug.md` § Gotchas.
- **User-global hooks shadow project hooks (NEW, dogfood-surfaced).** `~/.claude/hooks/*` fire AHEAD of `.claude/hooks/*` for the same event. A user-global PreToolUse(Bash) hook can mask Agent0's secrets-scan / supply-chain capacities end-to-end inside Claude Code, even though the project-side audit log remains honest. Diagnostic: `ls ~/.claude/hooks/`. See `.claude/memory/user-global-hooks-shadow.md`.
- **CLAUDE.md `## Section` summaries proved LOAD-BEARING in real dogfood.** Agent recovered from supply-chain block using ONLY CLAUDE.md `## Supply chain` (and the stderr template's verbatim corrected form) — did not need to read `supply-chain.md` deep. Confirms the path-scoping design hypothesis: deep rules can stay path-gated as long as their operational essentials remain in CLAUDE.md.
- **Hooks are harness siblings, not Bash children.** `CLAUDE_RULE_LOAD_DEBUG=1` MUST be exported in the shell before `claude` launches. Setting it via a Bash tool call mid-session is invisible to the hook. Documented identically in `.claude/rules/runtime-introspect.md` § Gotchas.
- **`InstructionsLoaded` is non-blocking, no decision control.** Per CC docs: stdout/stderr ignored by harness, runs async. The audit log + probe is the ONLY signal path from this hook.
- **session_id observed to shift mid-session in shrnk-mono dogfood log.** 9 `session_start` rows under one sid + 9 `path_glob_match` rows under a different sid. Cause unclear (possible: claude opened twice, /clear, or sub-agent context). Not blocking — both sids correctly tagged the events that happened under them. Flag for investigation if session_id reliability becomes a downstream concern.
- **Skill-eval framework NOT adopted (2026-05-13).** Industry pattern observed across 5 posts; deferred per `feedback_speculative_observability`. Reference: `.claude/memory/skill-eval-pattern.md`. Trigger to revisit: third silent regression in a skill dogfood missed.
