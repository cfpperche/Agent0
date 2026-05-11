# 007 — secrets-scan-timing

_Created 2026-05-10. Status: draft._

## Intent

The secrets-scan capacity from spec 006 has a fundamental timing issue: the `PreToolUse(Bash)` hook fires *before* the bash command executes, so any compound `git add ... && git commit ...` invocation defeats the gate — `gitleaks protect --staged` scans an empty index because `git add` has not run yet. Discovered during the very first real-use commits of spec 006: both commits in this session audited as `decision: "allow"` with `finding_count: 0`, despite the staged diff containing pattern-valid AWS-key shapes (later confirmed via `gitleaks detect --log-opts="b2047ee^..b2047ee"` on the merged commit: 4 findings present in content the gate had reported as clean). The fix is whatever delivers correct timing: the scan must happen at the moment between `git add` completing and `git commit` recording the snapshot, not before. The direction is intentionally open in this spec — `plan.md` decides after researching native git `pre-commit` hooks (the architecturally-correct moment, dominant industry pattern, but adds a per-fork install step), command-shape gating that forces separated `git add` / `git commit` (works within existing harness, adds UX friction), and modern alternatives such as `core.hooksPath` pointing at a versioned dir or third-party orchestrators like `lefthook`. The scope is narrow: reuse the existing override grammar, audit-log shape, allowlist mechanics, and PostToolUse advisory — change only *when* the scan fires.

## Acceptance criteria

- [ ] **Scenario: compound `git add && git commit` is gated correctly**
  - **Given** a file containing an AWS-pattern-valid key (e.g. `AKIA1234567890ABCDEF`) is about to be staged
  - **When** the agent runs `git add <file> && git commit -m "..."` as a single Bash invocation
  - **Then** the gate detects the finding and blocks the commit (exit 2 with detector class + `file:line` on stderr), and `git log` does NOT contain the new commit

- [ ] **Scenario: separate `git add` then `git commit` still works**
  - **Given** the agent runs `git add <file>` (with the same AWS-shaped key) in one Bash call, then `git commit -m "..."` in a *separate* Bash call
  - **When** the gate fires on the second invocation
  - **Then** the finding is detected and the commit is blocked, matching spec 006's V1 contract verbatim

- [ ] **Scenario: `git commit -a` (auto-stage tracked) is gated**
  - **Given** a tracked file is modified in-place to add an AWS-shaped key (no explicit `git add`)
  - **When** the agent runs `git commit -a -m "..."` via Bash
  - **Then** the gate detects the finding and blocks — `-a` auto-staging must not bypass the scan

- [ ] **Scenario: override marker preserves spec 006 semantics**
  - **Given** the compound scenario above, written across two lines of the Bash command string so that line 2 holds the marker on its own: line 1 is `git add <file> && git commit -m "..."`, line 2 is `# OVERRIDE: documentation test vector for spec 007` (bash treats line 2 as a no-op comment; the preflight matches the marker via the start-of-line anchor — same regex spec 002 fix shipped, no inline-trailing fallback)
  - **When** the gate fires
  - **Then** the preflight emits `decision: "override-pass-through"` with the reason populated, rewrites the command to prepend `CLAUDE_SECRETS_OVERRIDE_REASON='<reason>' `, and the native hook audits `decision: "override"` with the same reason — commit is allowed

- [ ] **Scenario: fail-open behavior is preserved when gitleaks is absent**
  - **Given** `gitleaks` is not on `PATH`
  - **When** any commit invocation is attempted (compound, separated, or `-a`)
  - **Then** the gate degrades open with one stderr warning and `decision: "skip-no-engine"` in the audit — same shape as spec 006's V4

- [ ] **Scenario: audit log distinguishes incomplete-scan from real-allow**
  - **Given** the new mechanism could in principle scan a real empty diff (e.g. `git commit --allow-empty`) or fall through on some unforeseen edge case
  - **When** the gate runs and gitleaks reports 0 findings
  - **Then** the audit entry includes enough context (an explicit `scan_mode` field, or a `staged_files_count`, or equivalent) for a reviewer to tell "no secrets found in real staged diff" apart from "scan ran against empty/incomplete state" — the spec-006 silent-failure mode must not be possible to reproduce

- [ ] **Scenario: fix is template-portable**
  - **Given** Agent0 is cloned fresh into a new project
  - **When** the fork follows the documented setup steps in `README.md` § *Per-fork checklist*
  - **Then** the secrets-scan gate is operative — no additional manual hook configuration beyond steps already listed (or, if a new step is added, it is exactly one new step in the checklist with a one-line description)

- [ ] `docs/specs/007-secrets-scan-timing/{spec,plan,tasks}.md` all exist and are filled (no `{{` placeholders remain)
- [ ] `docs/specs/006-secrets-scan/tasks.md` § *Notes* (or the analogous section) is amended with a pointer to 007 so future readers find the timing fix from the original spec
- [ ] `.claude/rules/secrets-scan.md` is updated to reflect the mechanism `plan.md` selects (trigger description, install steps if any, gotchas)
- [ ] `CLAUDE.md` § *Secrets scan* is updated if the user-facing escape hatch, install model, or hook script path changes

## Non-goals

- A general-purpose rule about "any PreToolUse(Bash) gate that depends on external state has this timing issue". The lesson is implicit in 007 existing — adding a separate rule file would be rule fatigue. Future capacity authors will see 007 in `git log` and learn from it.
- A rewrite of the secrets-scan implementation. Override grammar, audit-log shape, allowlist mechanics, `.gitleaks.toml` starter, and the `secrets-advise.sh` PostToolUse advisory all remain as-is unless the chosen mechanism makes one of them structurally impossible.
- Server-side / pre-receive scanning. Still out of scope per spec 006's non-goals.
- An inline-bash regex fallback for missing gitleaks. Fail-open remains the contract.
- Retroactive scanning of commit `b2047ee` (the empirical example). The strings in that commit are documentation test vectors — pattern-valid but clearly fabricated (`AKIA1234567890ABCDEF`). No actual credential exposure. Treating the example commit as something to amend would mean rewriting history for a benign event.

## Open questions

To resolve in `plan.md`, not here:

- [ ] **Fix mechanism.** Native git `pre-commit` hook installed per-fork; command-shape gating inside the existing PreToolUse(Bash) hook (e.g. reject compound `git add ... && git commit ...`, require separated invocations); both layered; or a modern alternative such as `core.hooksPath = .githooks/` pointing at a versioned directory checked into the template; or a third-party orchestrator like `lefthook` / `pre-commit.com`.
- [ ] **Per-fork install model.** If a native git hook is the chosen mechanism: is the install step documented-only (`cp .claude/git-hooks/* .git/hooks/` after `git init`, manual), or scripted (`bootstrap.sh` at repo root, fork runs once), or driven by `git config core.hooksPath .githooks` checked into the repo (zero-step, but the developer's local `.git/` config is in scope)?
- [ ] **Relationship to the existing `secrets-advise.sh` PostToolUse hook.** If the new mechanism scans on commit anyway, does the on-edit advisory remain valuable as an early signal? Or does the new gate's correct timing make it redundant and we delete it?
- [ ] **Audit log location.** If the gate moves to a native git hook (running in git's process, not Claude Code's hook process), it can still write to `.claude/secrets-audit.jsonl` directly — but does it still have access to `$CLAUDE_PROJECT_DIR` / `session_id` from stdin? Likely no. Either drop those fields, or accept that the audit log loses a small amount of context for the gain of correct timing.
- [ ] **Coexistence with the spec-006 PreToolUse hook.** During the transition, both can fire. Is the spec-006 hook deleted in 007, kept as a redundant second layer, or repurposed (e.g., to do the on-edit-style soft advisory only)?

## Context / references

- `docs/specs/006-secrets-scan/` — the spec being fixed. Particularly `plan.md` § *Risks and unknowns* (matcher granularity was already flagged as fragile in the original plan; the timing issue is the deeper, more general version of that risk).
- Commit `b2047ee` — the empirical example. 12 files staged including pattern-valid `AKIA1234567890ABCDEF` in `docs/specs/006-secrets-scan/tasks.md` and `.claude/SESSION.md`. The gate audited as `decision: "allow", finding_count: 0`. Post-hoc `gitleaks detect --log-opts="b2047ee^..b2047ee"` produces 4 findings. Reproduction with `gitleaks protect --staged` against a fresh probe-repo containing the same strings produces 2 findings, ruling out detector configuration and confirming the timing hypothesis.
- `.claude/secrets-audit.jsonl` — 5 consecutive `allow 0 findings` entries from this session, including the two commits where findings should have appeared.
- `.claude/rules/spec-driven.md` § *When SDD applies* — this fix touches one capacity but its decision space (native hook vs command-shape gating vs orchestrator) reaches into per-fork bootstrap UX, so SDD applies.
- `.claude/rules/research-before-proposing.md` — `plan.md` is required to cite primary sources for the mechanism comparison.
- Industry references for the eventual research phase (informational only, not pre-decided): git `core.hooksPath` documentation, `pre-commit.com`, `evilmartians/lefthook`, `typicode/husky`, `gitleaks` README on its recommended pre-commit integration shape.
