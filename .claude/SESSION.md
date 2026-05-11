# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state

Eight capacities on `main` plus the foundational hooks (compaction continuity, session handoff). Listed in spec order:

1. **Compaction continuity** — `PreCompact` snapshots last 12 real user turns into `.claude/COMPACT_NOTES.md` (gitignored); `SessionStart(source=compact)` re-injects it.

2. **Spec-driven development** — `/sdd` skill scaffolds `docs/specs/NNN-<slug>/{spec,plan,tasks}.md`. Rule `.claude/rules/spec-driven.md`. Spine of every non-trivial change for six specs running.

3. **Governance gate** _(spec 001)_ — `.claude/hooks/governance-gate.sh` on `PreToolUse(Bash)`. Destructive ops, hook bypass, blanket staging.

4. **Delegation capacity** _(spec 002)_ — 5-field handoff enforced; post-edit validator loop; audit at `.claude/delegation-audit.jsonl`.

5. **Reminders capacity** _(spec 003)_ — `/remind` skill, state at `.claude/REMINDERS.md`, auto-surfaced at SessionStart.

6. **BDD acceptance scenarios** _(spec 004)_ — Given/When/Then in `spec.md` for behavior, plain bullets for static facts. Validated empirically — sub-agents verify scenarios directly from the spec with zero clarification.

7. **TDD working agreement** _(spec 005)_ — Red→green→refactor; validator emits non-blocking `tdd-advisory:` warnings when prod files move without tests. Inert in this base repo (no stack); activates per-fork.

8. **Secrets scan** _(spec 006, this session)_ — `.claude/hooks/secrets-scan.sh` on `PreToolUse(Bash)` matching `git commit`: runs `gitleaks protect --staged`, blocks (`exit 2`) on findings with detector class + `file:line` on stderr, audits every invocation to `.claude/secrets-audit.jsonl`. Honours `# OVERRIDE: <reason ≥10 chars>` (start-of-line anchored, per the 002 fix). Fail-open when gitleaks absent. Companion `secrets-advise.sh` on `PostToolUse(Edit|Write|MultiEdit)` emits soft `secrets-advisory:` lines when `CLAUDE_SECRETS_ADVISE_ON_EDIT=1`, parent-exempt. Escape: `CLAUDE_SKIP_SECRETS_SCAN=1`. Starter `.gitleaks.toml` at repo root with `[extend].useDefault = true`. Rule `.claude/rules/secrets-scan.md`.

Also added this session:
- **`README.md`** at repo root — entry point for forks: quick-start, capacity table, per-fork checklist, layout.
- **`.claude/hooks/session-stop.sh` JSON shape fix** — old `{"hookSpecificOutput":{"hookEventName":"Stop", ...}}` shape no longer validates; Stop hook now emits top-level `{"decision":"block","reason":"<msg>"}`. The old shape was failing silently — the Stop nag wasn't actually blocking. Confirmed via the schema error and `claude-code-guide` lookup.

## WIP

Nothing in flight.

## Next steps

- **Cross-session smoke for the Stop-hook fix.** End a session with a dirty tree and stale `SESSION.md`; confirm the new shape produces a real block (not a silent schema-validation failure). The hook only chose to block on this session because I bumped SESSION.md — verify the inverse path.
- **V5 / V6 of spec 006 deferred** — `gitleaks:allow` inline and `.gitleaks.toml` path allowlist were not empirically smoke-tested (both are gitleaks-native features, work iff gitleaks honors them per its docs). Marked unchecked in `docs/specs/006-secrets-scan/tasks.md` with reasoning. Worth verifying on the first real fork; consider `/remind add` if discipline is at risk of being forgotten.
- **Fork checklist update** — `README.md` § *Per-fork checklist* now includes "install gitleaks (optional)" as step 4. Confirm this lands well on the first real fork.

## Decisions & gotchas

Newly discovered or load-bearing this session:

- **`AKIAIOSFODNN7EXAMPLE` is a gitleaks *stopword*, not a test vector.** Discovered independently by Brief 2 + Brief 3 of spec 006. Gitleaks 8.21.2 filters AWS detector matches containing the substring `EXAMPLE` (FP-reduction). The intuition "AWS-documented test key = gitleaks test vector" is wrong — gitleaks suppresses it. For verifications that need to actually trip the AWS detector, use a non-stopworded pattern-valid shape such as `AKIA1234567890ABCDEF`. Documented in `docs/specs/006-secrets-scan/tasks.md` § *Notes* and `plan.md` § *Risks*.

- **Stop hook output schema changed.** Old shape `{"hookSpecificOutput":{"hookEventName":"Stop","decision":"block","additionalContext":"<msg>"}}` is rejected by current Claude Code; `hookSpecificOutput` only accepts `PreToolUse | UserPromptSubmit | PostToolUse | PostToolBatch`. For Stop, top-level `{"decision":"block","reason":"<msg>"}` is the canonical shape; the agent reads `reason` after a block. The old shape was validation-failing silently — Stop nag had been broken for an unknown window. Worth a session-start verification for any other hook that wires `hookSpecificOutput`: only `session-stop.sh` was using the Stop variant; fixed.

- **Dogfood loop keeps paying off.** 002 (override regex false-positive, jq `// empty`, sticky stderr), 005 (untracked files in `git diff`), and now 006 (AKIA stopword) — every spec since 001 has surfaced at least one real implementation gotcha during delegated implementation that was invisible at spec/plan time. The pattern continues to validate "delegate substantial implementation to sub-agents with full 5-field briefs, parent runs verification + cross-doc updates + commit".

Carried forward from prior sessions (still load-bearing — full list in `.claude/rules/*` and `docs/specs/*/`):

- Path discipline: `.claude/` is harness configuration, `docs/specs/` is project artifacts (design memory).
- Hook event activation timing: `PreToolUse` / `PostToolUse` activate immediately on settings save; `SessionStart` / `Stop` register on the next session.
- Override marker is **start-of-line anchored** (002 fix). Governance-gate still uses the unanchored shape — port if it ever hits the same false-positive class.
- `agent_id` IS in the PostToolUse payload (undocumented but reliable) — only field that discriminates parent vs sub-agent.
- `additionalContext` from a PreToolUse hook renders as `system-reminder` in the parent's next turn.
- The validator is inert in this base repo; activates per-fork when a stack lockfile is present.
- Two bash traps in any new hook script: (1) `jq '.field // empty'` collapses `false` and missing into the same empty string — use the explicit `has` shape when distinguishing matters; (2) `exec N>file 2>/dev/null` is a sticky redirect that permanently silences FD 2 — probe writability in a subshell first.
