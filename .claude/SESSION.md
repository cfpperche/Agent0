# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state

Eight capacities on `main`. Spec 006 (secrets-scan) shipped + committed (`b2047ee`), but a fundamental timing bug was discovered the moment it was first dogfooded — see § *Decisions & gotchas*. Spec 007 (`secrets-scan-timing`) was opened to fix it: `spec.md` + `plan.md` + `tasks.md` are drafted and approved by the user; implementation is the WIP for next session.

Spec order recap: 001 governance-gate · 002 delegation · 003 reminders · 004 BDD · 005 TDD · 006 secrets-scan · 007 secrets-scan-timing (in flight). `README.md` exists at repo root as the fork entry point. The Stop-hook JSON-shape fix from earlier this session has been **empirically validated cross-event** — this very SESSION.md update was triggered by it blocking correctly when the session was about to end with a stale handoff.

## WIP

**Spec 007 — secrets-scan-timing — implementation phase, 11 tasks unstarted.** Read `docs/specs/007-secrets-scan-timing/tasks.md` top-to-bottom and work through them; the plan is approved. Headline:

1. Ship `.githooks/pre-commit` (full implementation: gitleaks call + audit + env-var override path + `staged_files_count`).
2. `git config core.hooksPath .githooks` in Agent0 (dogfood activation).
3. Refactor `.claude/hooks/secrets-scan.sh` into a pure preflight gate (remove scan, add shape gating + `updatedInput` env-var injection).
4. Stderr template for shape rejection (mitigation for Claude Code issue #24327).
5. Smoke-test the layered hooks in tandem.
6. Update `README.md` per-fork checklist + layout.
7. Rewrite `.claude/rules/secrets-scan.md` § *What fires* + new gotchas.
8. Update `CLAUDE.md` § *Secrets scan*.
9. Write `tests/secrets-scan/` scenario scripts + `run-all.sh`.
10. `.gitignore` adjustments.
11. Amend 006 `tasks.md` § *Notes* with pointer to 007.

Verification: V1–V11 mapped 1:1 to spec.md scenarios + static facts. Delegate implementation to sub-agents per the established pattern; pay attention to the model-discipline open question below.

## Next steps

- **Model discipline — decided: both (a) and (b), pending execution next session.**
  - **(a) Parent passes explicit `model` per task-fit table going forward.** Mechanical implementation (brief with detailed fields, regex ready, patterns to copy) → `sonnet`. Schema/protocol lookup, short research with obvious source → `haiku` or `sonnet`. Multi-source comparative research with opinionated recommendation → `opus` if ≥2 signals (cross-domain + security/schema), else `sonnet`. Architecture review, subtle trade-offs → `opus`. Exploratory debugging without clear hypothesis → `opus`. Reasoning: this session's 8 dispatches all went out with `model: null, model_specified: false`, so the harness default ran for everything — likely sonnet or whatever Claude Code defaults to for `general-purpose`. Opus-worthy tasks (comparative research) passed silently.
  - **(b) Extend `.claude/hooks/delegation-gate.sh` to advise when `model` is unspecified.** Current logic emits the escalation advisory only when "≥2 signals fire AND non-opus model **specified**". Add: when `model_specified == false` AND any signal fires, emit a different advisory nudging the parent to declare a model explicitly (with the task-fit table inline so the agent doesn't have to remember it). This is a small bash addition — a few lines around the existing advisory block. Sub-task of spec 002 follow-up; could fit as a one-task extension or roll into spec 007's tasks if it lands in the same commit window.
- **V5 / V6 of spec 006 deferred** — `gitleaks:allow` inline and `.gitleaks.toml` path allowlist were not empirically smoke-tested. After spec 007 lands they should be re-validated as part of the new layered model. Marked unchecked in `docs/specs/006-secrets-scan/tasks.md`.
- **Spec 006 was committed with documentation test vectors** (`AKIA1234567890ABCDEF`) intact in `tasks.md` and SESSION.md. The strings are deliberately fabricated, not real credentials. They will continue to trip future `gitleaks detect --log-opts` history scans — that is correct behavior; documenting the gate's contract requires showing what shape triggers it. No action needed.

## Decisions & gotchas

Newly discovered or load-bearing this session:

- **Spec 006 secrets-scan has a fundamental timing bug.** `PreToolUse(Bash)` fires *before* the bash command executes, so compound `git add ... && git commit ...` invocations defeat the gate — `gitleaks protect --staged` scans an empty index because `git add` has not run yet. Discovered by post-commit audit-log inspection: both this session's commits audited as `decision: "allow", finding_count: 0` despite the diff containing pattern-valid AKIA strings (`gitleaks detect --log-opts="b2047ee^..b2047ee"` finds 4). Reproduction in a fresh probe-repo with the same content via `gitleaks protect --staged` finds 2, confirming the timing hypothesis. Fix is spec 007 (in flight).

- **Spec 007 design resolved: layered defense.** Primary = `.githooks/pre-commit` activated via `core.hooksPath` (native git hook, fires after staging is finalized, sees real index). Secondary = the existing `.claude/hooks/secrets-scan.sh` retained and extended for shape gating + override-marker handling + `session_id`/`agent_id` audit context that cannot live in a native hook process. Cross-layer override flow uses Claude Code's PreToolUse `hookSpecificOutput.updatedInput` to inject `CLAUDE_SECRETS_OVERRIDE_REASON='<reason>'` into the bash subprocess env → inherited by git → read by the native hook. Tradeoff accepted: one new line in README per-fork checklist (`git config core.hooksPath .githooks`).

- **`gitleaks protect --staged` was deprecated in 2025** in favor of `gitleaks git --pre-commit --staged` per gitleaks' own `.pre-commit-hooks.yaml`. Spec 006 ships the deprecated form; spec 007 migrates both layers. Minimum gitleaks version becomes 8.20 (where `git` subcommand exists).

- **`core.hooksPath` is the Lazarus Group's 2025 attack vector.** The install step in README is MANUAL by design — never auto-applied by a `post-checkout` or `git-init` hook. Encoded in `plan.md` § *Risks* and will be in `.claude/rules/secrets-scan.md` § *Gotchas* once 007 lands.

- **Stop-hook fix validated cross-event.** The earlier-session fix (top-level `decision`/`reason` instead of the now-rejected `hookSpecificOutput.Stop` shape) successfully blocked when this session was about to end with stale SESSION.md. Removes one item from the prior "Next steps" list.

- **AKIA test-vector reminder (carried from spec 006 § Notes):** use `AKIA1234567890ABCDEF` for scenarios that need a detector trip (non-stopworded, pattern-valid). `AKIAIOSFODNN7EXAMPLE` is stopworded by gitleaks 8.21.2 and will silently *not* trip — known-bad fixture choice.

- **Sub-agent dogfood loop continues to surface real bugs.** 002 (override regex false-positive, jq `// empty`, sticky stderr), 005 (untracked files in `git diff`), 006 (AKIA stopword + the timing bug), and the Stop-hook JSON-shape change this session. Pattern still validates: delegate substantial implementation with full 5-field briefs, parent runs verification + cross-doc updates + commit + investigates audit-log anomalies.

Carried forward from prior sessions (still load-bearing — full list in `.claude/rules/*` and `docs/specs/*/`):

- Path discipline: `.claude/` is harness, `docs/specs/` is project artifacts.
- Hook event activation timing: `PreToolUse` / `PostToolUse` activate immediately on settings save; `SessionStart` / `Stop` register on the next session.
- Override marker is **start-of-line anchored** (002 fix). Governance-gate still uses unanchored — port if it hits the same false-positive class.
- `agent_id` IS in the PostToolUse payload (undocumented but reliable).
- `additionalContext` from PreToolUse renders as `system-reminder` in the parent's next turn.
- Validator is inert in this base repo; activates per-fork when a stack lockfile is present.
- Two bash traps in any new hook script: (1) `jq '.field // empty'` collapses `false` and missing into the same empty string — use `has` shape when distinguishing matters; (2) `exec N>file 2>/dev/null` is sticky — probe writability in a subshell first.
