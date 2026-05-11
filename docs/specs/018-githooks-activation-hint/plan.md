# 018 — githooks-activation-hint — plan

_Drafted from `spec.md` on 2026-05-11. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Extend the existing `.claude/hooks/session-start.sh` with one small block appended after the runtime-introspect block (which is currently the last capacity hint). The block does three cheap checks in sequence:

1. **Capacity present** — does `.githooks/` directory exist under `$PROJECT_DIR`? If no, exit silently (no capacity → no nag — same posture as the runtime-introspect block, which only fires when `.claude/tools/probe.sh` exists).
2. **Opt-out honored** — is `CLAUDE_SKIP_GITHOOKS_HINT=1` set? If yes, exit silently.
3. **Activation state** — does `git -C "$PROJECT_DIR" config --get core.hooksPath` return `.githooks`? If yes, exit silently (already activated). Otherwise, emit the advisory block.

The advisory text is a single `=== githooks-activation ===` block (matching `=== runtime-introspect ===` / `=== mcp-recipes ===` / `=== REMINDERS ===` shape) naming the consequence and the one-command fix verbatim — same issue-#24327 reasoning as elsewhere: the stderr-ingested text IS the agent-facing UX, so the activation command must be copy-pasteable.

Total new code in session-start.sh: ~12 lines. No new hook file, no new audit log, no new env var beyond the opt-out. The mechanism is pure recommendation — `git config` is not invoked by the hook itself, only printed for the human/agent to run.

## Files to touch

**Create:**
- `.claude/tests/githooks-activation/01-advisory-fires-when-inactive.sh` — RED scenario 1: `.githooks/` exists + config absent → advisory in stdout.
- `.claude/tests/githooks-activation/02-silent-when-activated.sh` — RED scenario 2: `.githooks/` exists + config = `.githooks` → no advisory.
- `.claude/tests/githooks-activation/03-silent-when-no-githooks-dir.sh` — RED scenario 3: no `.githooks/` → no advisory.
- `.claude/tests/githooks-activation/04-skip-env-var.sh` — RED scenario 4: `CLAUDE_SKIP_GITHOOKS_HINT=1` → no advisory regardless of config state.
- `.claude/tests/githooks-activation/run-all.sh` — driver, same shape as `.claude/tests/runtime-introspect/run-all.sh`.
- `.claude/tests/githooks-activation/README.md` — one-line numbering convention note.

**Modify:**
- `.claude/hooks/session-start.sh` — append the ~12-line githooks-activation block after the runtime-introspect block (line ~60). The block guards on `.githooks/` existence (silent capacity-not-installed) and on `CLAUDE_SKIP_GITHOOKS_HINT=1` (silent opt-out).
- `.claude/rules/secrets-scan.md` § Gotchas — one-sentence cross-reference to the new SessionStart hint. The existing "MANUAL by design" gotcha gains an end-line: "A SessionStart hint (spec 018, `.claude/hooks/session-start.sh` § githooks-activation) surfaces the activation command when `.githooks/` exists but `core.hooksPath` is not set, so the dormant state is discoverable without reading this gotcha cold."

**Delete:**
- None. Pure additive change.

## Alternatives considered

### A separate dedicated hook file `.claude/hooks/githooks-activation-hint.sh`

Rejected because the existing `session-start.sh` is already the single SessionStart consumer and adding a second SessionStart hook would (a) require a `.claude/settings.json` entry registering it (more sync surface for spec 016), (b) duplicate the stdin-parsing boilerplate (`session_id` sanitization, source-detection), and (c) split the capacity-hint logic across two files. The mcp-recipes-hint is a counter-example — it IS a separate hook — but it has 80+ lines of stack-signal detection logic that justifies its own file. This advisory is 12 lines.

### Block fires when `gitleaks` binary is also missing from PATH

Rejected because the existing `.githooks/pre-commit` already fails open with `secrets-scan: gitleaks not found, scan skipped` on stderr when gitleaks is absent (audit `skip-no-engine` — per `.claude/rules/secrets-scan.md` § Audit log). Duplicating that detection in the SessionStart hint adds noise: the developer who hasn't installed gitleaks would see two nags (SessionStart + commit-time), neither cleanly fixable from the hint. v1 fires purely on `core.hooksPath` state — gitleaks-presence is a separate concern handled where it matters.

### Auto-activation behind a confirmation prompt

Rejected because the prompt would have to be answered EVERY session for every fork until the developer clicked "yes" — annoying. And the underlying Lazarus reasoning (`.claude/rules/secrets-scan.md` § Gotchas) is specifically about avoiding "silent automation of hook activation": even a prompt is borderline (the developer learns to click-through), and one-click activation is one keystroke away from auto-activation. The passive-advisory shape forces the developer to type the command in their own terminal, which is the deliberate friction we want.

### Detect `core.hooksPath` set to a non-`.githooks` path and warn differently

Rejected because the only "correct" value Agent0 ships is `.githooks`. Any other value (a fork that uses `.husky/` or `.git/hooks` or some custom path) is fork-specific deliberate configuration and the advisory should treat it the same as unset — fire the same line. The developer reading the hint can choose to keep their custom config and dismiss via `CLAUDE_SKIP_GITHOOKS_HINT=1`. Adding a "your hooks path is wrong, did you mean `.githooks`?" branch would moralize about fork config beyond this spec's scope.

## Risks and unknowns

- **Non-git directory.** If `$PROJECT_DIR` is not a git repo, `git -C "$PROJECT_DIR" config --get core.hooksPath` exits non-zero. The block must treat exit-non-zero as "no advisory" (silent), not as "advisory fires because config is absent". Mitigation: redirect stderr with `2>/dev/null` and default to empty string; the equality check `[ "$current" != ".githooks" ]` then doesn't fire when `.githooks/` itself is missing (the capacity-present guard catches non-git dirs because no `.githooks/` exists in a non-Agent0-template tree).
- **Global `core.hooksPath` shadowing.** A developer with a global `core.hooksPath = ~/.global-hooks` may have it shadowing the repo-local config. The hint cares only about the **effective** value `git config --get core.hooksPath` returns. If the global value happens to be `.githooks`, the hint stays silent (false-negative — global hooks may not be the Agent0 ones). v1 accepts this: documented in the rule doc as a gotcha. Same false-negative shape as `.claude/rules/secrets-scan.md` § Gotchas already documents for the native hook itself.
- **First-session noise after spec 016 sync.** Every fork that just adopted `.githooks/pre-commit` via sync-harness will see the advisory on the very next session start. That's exactly the desired signal — but if a developer ignores it across many sessions, the line becomes background noise. Accepted: it's one block of three lines, smaller than the SESSION.md handoff. If real complaint surfaces, a "you've been advised N times" suppression heuristic is v2.
- **Subagents inherit SessionStart context.** When the parent dispatches a sub-agent (via `Agent` tool), the sub-agent receives a fresh session_id and runs SessionStart. The advisory fires for sub-agents too, polluting their first-turn context. Possible mitigation: detect sub-agent context (no clear stdin signal in v1) and skip. v1 accepts the pollution — one extra block per sub-agent is bounded; revisit if it becomes noisy.
- **`CLAUDE_PROJECT_DIR` empty in unusual launch paths.** Falls back to `$PWD` per the existing hook. If both are empty (shouldn't happen in normal Claude Code invocations), the advisory's `.githooks/` check fails silently. Acceptable.

## Research / citations

- Codebase: `.claude/hooks/session-start.sh` — existing hook shape; this spec extends, not replaces.
- Codebase: `.claude/hooks/mcp-recipes-hint.sh` — reference for SessionStart advisory shape with stack-signal detection (richer than what 018 needs, but same `=== block === / === end block ===` framing).
- Codebase: `.claude/rules/secrets-scan.md` § Gotchas — current documentation of the manual-activation requirement.
- Codebase: `docs/specs/006-secrets-scan/`, `docs/specs/007-secrets-scan-timing/` — origin of `.githooks/pre-commit` and the Lazarus reasoning that frames the non-auto-activation choice.
- Git docs: <https://git-scm.com/docs/githooks#_overview> — `core.hooksPath` config option, repo-local vs global precedence.
- External: <https://www.darkreading.com/threat-intelligence/lazarus-group-contagious-interview> — 2025 Lazarus "Contagious Interview" campaign, the named threat model for why auto-activation is refused.
- Live evidence: spec 016 commit `373ece9` (Agent0) and the three shrnks (`92c7013` / `c10927a` / `a1a14e8`) now have `.githooks/pre-commit` synced but `core.hooksPath` unset — they are the immediate beneficiaries of this spec.
