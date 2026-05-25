# 018 — githooks-activation-hint

_Created 2026-05-11._

**Status:** shipped

## Intent

The native git pre-commit hook (`.githooks/pre-commit`, primary gitleaks block per spec 006-007) is **inert** until the developer runs `git config core.hooksPath .githooks` in the fork. That step is **manual by design** — auto-activation on clone/init is the 2025 Lazarus Group "Contagious Interview" vector (`.claude/rules/secrets-scan.md` § Gotchas). But silence isn't the right opposite of auto-activation: a fork that adopted the secrets-scan capacity (via spec 016 sync) but forgot the activation command has a hook file that never runs. The agent and developer have no signal that gitleaks is dormant. Add a one-line SessionStart advisory that fires when `.githooks/` exists in the project but `git config core.hooksPath` is not pointing at it — passive prompt, single-command remediation, silent once activated. Same shape as the mcp-recipes / reminders / runtime-introspect hints already shipping.

## Acceptance criteria

- [ ] **Scenario: hook dir exists, config absent → advisory fires**
  - **Given** the project has `.githooks/pre-commit` and `git config --get core.hooksPath` returns empty (or any value other than `.githooks`)
  - **When** a Claude Code session starts
  - **Then** the SessionStart additional-context includes a `=== githooks-activation ===` block naming the activation command `git config core.hooksPath .githooks` and the consequence ("native git hooks NOT activated — secrets-scan native pre-commit inert")

- [ ] **Scenario: hook dir exists, config correctly set → advisory silent**
  - **Given** the project has `.githooks/pre-commit` and `git config --get core.hooksPath` returns `.githooks`
  - **When** a Claude Code session starts
  - **Then** no `=== githooks-activation ===` block is emitted

- [ ] **Scenario: no `.githooks/` dir → advisory silent**
  - **Given** the project has no `.githooks/` directory (capacity not installed)
  - **When** a Claude Code session starts
  - **Then** no `=== githooks-activation ===` block is emitted (no nag for projects that haven't adopted secrets-scan)

- [ ] **Scenario: opt-out via env var**
  - **Given** `.githooks/` exists, config absent, `CLAUDE_SKIP_GITHOOKS_HINT=1` set in the launching shell
  - **When** a Claude Code session starts
  - **Then** no advisory block is emitted, regardless of config state

- [ ] `.claude/hooks/session-start.sh` extended with the activation-check block, placed after the SESSION.md / COMPACT_NOTES.md / runtime-introspect blocks (consistent positioning with other capacity hints).
- [ ] `.claude/rules/secrets-scan.md` § Gotchas updated: "manual activation" gotcha gains a sentence pointing at the SessionStart hint so future maintainers know the advisory exists.
- [ ] Tests under `.claude/tests/githooks-activation/` cover the four scenarios above using tmp-dir fixtures with mock `.githooks/` directories.
- [ ] No new audit log. Pure recommendation, same posture as mcp-recipes-hint.

## Non-goals

- **Auto-activation.** Lazarus vector. The whole point of this spec is to make the manual step DISCOVERABLE, not automatic. Do NOT run `git config core.hooksPath .githooks` from the hook; emit the command for the developer to run.
- **Per-hook coverage.** v1 only checks the `core.hooksPath` config. If a future spec ships `.githooks/commit-msg` or `.githooks/pre-push`, the advisory text continues to name only the activation command (one config setting covers all of `.githooks/*`). No per-file validation.
- **Detection of the gitleaks binary.** The activation advisory fires regardless of whether `gitleaks` is installed — the existing `.githooks/pre-commit` already fails open when gitleaks is missing (`skip-no-engine` audit row). Adding gitleaks-presence checks to the SessionStart hint duplicates that logic poorly.
- **Detection of misconfigured `core.hooksPath`.** If `core.hooksPath` is set to something other than `.githooks` (e.g. a fork using a different hook dir), the advisory fires the same as if unset. Acceptable: the only "correct" value Agent0 ships is `.githooks`.
- **Hint when `.githooks/` exists but is empty.** Edge case; spec 007 ships `.githooks/pre-commit` as the canonical content. An empty `.githooks/` is unsupported terrain.
- **Cross-platform shell detection.** Hook is bash, same baseline as every other hook in this repo. `git config --get` is POSIX-portable.

## Open questions

- [ ] **Block label** — `githooks-activation` vs `secrets-scan-activation`? The former is more future-proof (any githook), the latter is more specific to today's usage. Proposal: `githooks-activation` — matches the underlying mechanism, not the current sole consumer.
- [ ] **Position in session-start.sh** — before or after the runtime-introspect hint? Proposal: AFTER (consistent with "things you may want to do" ordering — SESSION first, COMPACT second, runtime-introspect third, githooks-activation fourth). Cosmetic but worth fixing once.
- [ ] **What if the project is not a git repo at all?** `git config --get` exits non-zero in a non-git dir. The hook should treat that as "no advisory" (silent), not error. Confirm via test scenario or just defensive `2>/dev/null`.

## Context / references

- `docs/specs/006-secrets-scan/` + `docs/specs/007-secrets-scan-timing/` — the two specs that establish `.githooks/pre-commit` as the primary block. Activation has been manual since 006; this spec adds the missing signal.
- `.claude/rules/secrets-scan.md` § Gotchas — current documentation of the manual-activation requirement, lives only there today (no session-time signal).
- `docs/specs/012-mcp-recipes/` + `.claude/hooks/mcp-recipes-hint.sh` — reference shape for a SessionStart advisory hook.
- `.claude/rules/spec-driven.md` § Acceptance scenarios — Given/When/Then shape for scenarios above.
- Lazarus reasoning: <https://www.darkreading.com/threat-intelligence/lazarus-group-contagious-interview-malicious-npm-packages> — context for why activation stays manual.
- Live evidence: spec 016 just sync'd `.githooks/pre-commit` into pyshrnk / shrnk / rshrnk. Each fork now needs the activation command typed once; the developer has no SessionStart-time reminder that the file is dormant.
