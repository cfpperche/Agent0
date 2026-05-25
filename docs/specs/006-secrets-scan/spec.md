# 006 — secrets-scan

_Created 2026-05-10._

**Status:** shipped

## Intent

Add a secrets-scan capacity to the Agent0 harness: a `PreToolUse(Bash)` hook that intercepts `git commit` invocations, runs [gitleaks](https://github.com/gitleaks/gitleaks) over the staged diff, and blocks the commit when a credential, key, or other high-confidence secret is detected. The block honors the established `# OVERRIDE: <reason ≥10 chars>` marker so legitimate fixtures or test data can still land with an audit-logged justification. The governance-gate already closes the destructive-ops and hook-bypass attack surface; the secrets vector is the next-largest blast-radius gap a generic template can credibly cover, because the cost of leaking an AWS key or signing cert is materially asymmetric to the cost of typing a 10-character override reason. The hook degrades open when gitleaks is absent — the template stays stack-agnostic and the fork chooses whether to install the binary.

## Acceptance criteria

- [ ] **Scenario: commit with a detected secret is blocked**
  - **Given** a staged file contains a string matching a gitleaks high-confidence detector (e.g. an AWS access key `AKIA...`)
  - **When** the agent invokes `git commit -m "..."` via the Bash tool
  - **Then** the hook exits 2, the commit is aborted, and stderr names the detector class and the `file:line` of the finding

- [ ] **Scenario: override marker on the commit invocation bypasses the block**
  - **Given** the same staged secret as above
  - **When** the Bash command is `git commit -m "..."  # OVERRIDE: fixture for auth integration test`
  - **Then** the hook allows the commit and records the override reason in the audit log

- [ ] **Scenario: override reason shorter than 10 chars is rejected**
  - **Given** a staged secret and a command containing `# OVERRIDE: skip`
  - **When** the commit is invoked
  - **Then** the hook blocks and stderr explains the reason is too short

- [ ] **Scenario: gitleaks binary missing degrades open**
  - **Given** `gitleaks` is not on `PATH`
  - **When** any `git commit` is invoked
  - **Then** the hook prints a single warning to stderr (`secrets-scan: gitleaks not found, scan skipped`), exits 0, and the commit proceeds

- [ ] **Scenario: inline `gitleaks:allow` suppresses a single-line finding**
  - **Given** a file contains a high-entropy string with `# gitleaks:allow` (or the language-appropriate comment form) on the same line
  - **When** the commit is invoked
  - **Then** gitleaks reports no finding and the hook allows the commit

- [ ] **Scenario: `.gitleaks.toml` path allowlist honored**
  - **Given** a `.gitleaks.toml` at repo root allowlists `tests/fixtures/**/*` and a fixture there contains a deliberately fake-shaped key
  - **When** the commit is invoked
  - **Then** the hook allows the commit (no finding in the allowlisted path)

- [ ] **Scenario: on-edit advisory mode emits soft warning, never blocks**
  - **Given** the env var `CLAUDE_SECRETS_ADVISE_ON_EDIT=1` is set, and a delegated sub-agent writes a file containing an AWS key via `Edit`/`Write`/`MultiEdit`
  - **When** the `PostToolUse` hook runs against that edit
  - **Then** stderr shows a single line `secrets-advisory: <detector> at <file>:<line>` and exit code is 0; the edit is not reverted, and parent-agent edits are exempt (mirroring the delegation-gate actor split)

- [ ] **Scenario: every scan invocation appends one audit-log line**
  - **Given** any commit attempt (blocked, allowed, or fail-open)
  - **When** the hook finishes
  - **Then** `.claude/secrets-audit.jsonl` gains exactly one JSON line with fields `ts`, `session_id`, `decision` (`block`|`allow`|`override`|`skip-no-engine`), `finding_count`, `override_reason` (or null)

- [ ] `.claude/hooks/secrets-scan.sh` exists, is executable, and has no syntax errors (`bash -n` clean)
- [ ] `.claude/settings.json` registers the hook on `PreToolUse(Bash)` with a matcher that fires on `git commit` invocations
- [ ] `.claude/rules/secrets-scan.md` documents the discipline (when it fires, override grammar, allowlist mechanics, gotchas)
- [ ] `.claude/secrets-audit.jsonl` is listed in `.gitignore` (audit log is local state, not project memory)
- [ ] `CLAUDE.md` gains a brief `## Secrets scan` section pointing at the rule

## Non-goals

- Server-side / pre-receive scanning. That is CI/forge territory; the hook is a client-side gate.
- Live API verification of detected credentials (the trufflehog `--results=verified` model). Out of scope: it needs network egress and provider API keys, which conflict with the template's offline-friendly posture.
- Historical scanning of `git log`. The hook gates *new* commits; cleaning history is a separate, project-specific operation.
- A `.secrets.baseline` file (detect-secrets pattern). Agent0 is a *new-repo template* — there is no legacy to freeze, and shipping a baseline would mean importing whichever fake-secrets-shaped strings happen to exist today as permanently-allowed.
- Custom detector rules. v1 uses gitleaks' built-in detector set; project-specific detectors are added by the fork in its own `.gitleaks.toml`.
- Auto-remediation (truncating, redacting, or rotating detected secrets). The hook *blocks*; the human decides what to do.

## Open questions

- [ ] **Ship a starter `.gitleaks.toml` or not?** Option A: ship a minimal file with `[extend].useDefault = true` and an empty `[[allowlists]]` block, so the fork has a discoverable place to add exemptions. Option B: ship nothing and let gitleaks use its built-in config, instructing the fork to create the file only when an allowlist is actually needed. Lean A (discoverability > minimalism), confirm in plan.
- [ ] **Scan scope: staged diff vs. whole working tree at commit time?** Staged diff is faster and matches "what is being committed". Whole tree catches secrets present in files that happen to be staged but not modified. gitleaks supports both modes (`gitleaks protect --staged` vs `gitleaks detect`). Lean staged-only, confirm in plan.
- [ ] **On-edit advisory: diff vs. whole-file scan?** Diff-only is cheaper and semantically "what the agent just wrote". Whole-file catches pre-existing secrets exposed by the edit. Lean diff-only for v1; promote to whole-file only if false negatives observed.
- [ ] **Where is the audit log read from?** The delegation audit log at `.claude/delegation-audit.jsonl` is `jq`/`tail`-only by convention. Secrets-audit should follow the same shape, unaggregated. Confirm no need for a summary command in v1.

## Context / references

- `docs/specs/001-governance-gate/` — sibling capacity, same `PreToolUse(Bash)` hook shape and override-marker grammar this spec reuses
- `docs/specs/002-delegation/` — audit-log JSONL pattern and parent-vs-sub-agent actor split (relevant for on-edit advisory mode)
- `.claude/rules/spec-driven.md` § *Acceptance scenarios* — BDD shape this spec follows
- gitleaks repo and docs: https://github.com/gitleaks/gitleaks
- gitleaks config (allowlists / `targetRules`): https://github.com/gitleaks/gitleaks/blob/master/config/allowlist.go
- Setu et al., "A Comparative Study of Software Secrets Reporting by Secret Detection Tools" (arXiv 2307.00714), the precision/recall benchmark cited in research: https://ar5iv.labs.arxiv.org/html/2307.00714
- pre-commit.com convention (hard-block-on-nonzero-exit): https://pre-commit.com/
