# Secrets scan

A two-hook capacity that keeps credentials out of the repo. The hard gate runs at commit time; the soft advisory runs at edit time and is opt-in. The discipline is anchored on the same primitives as the governance and delegation gates — stdin JSON payload, `# OVERRIDE:` escape, JSONL audit log — so a reader who already knows those two gates can read this one in 30 seconds. Spec: `docs/specs/006-secrets-scan/`.

## What fires, what advises

**Hard gate — `PreToolUse(Bash)` → `.claude/hooks/secrets-scan.sh`.** Registered with a broad matcher that fires on any Bash command containing `git`; the script itself parses `tool_input.command` and short-circuits unless the command is a real `git commit` invocation (covers `git commit`, `git  commit` with double space, `git -C <path> commit`, `git commit --amend`, and `cd <path> && git commit`). When the command qualifies, the script runs `gitleaks protect --staged --no-banner --report-format=json` over the staged diff. On any finding it blocks (`exit 2`) with the detector class and `file:line` on stderr; on a clean scan it allows (`exit 0`). The matcher-is-broad / script-is-precise split is deliberate: false fires are one fast gitleaks call (cheap), missed fires are an unscanned commit (bad), so the bias is toward over-firing. Plan rationale: `docs/specs/006-secrets-scan/plan.md` § *Risks and unknowns*.

**Soft advisory — `PostToolUse(Edit|Write|MultiEdit)` → `.claude/hooks/secrets-advise.sh`.** Opt-in via `CLAUDE_SECRETS_ADVISE_ON_EDIT=1`; unset means the hook exits 0 silently. Even when enabled, the advisory is *sub-agent only* — the script reads `agent_id` from the stdin payload and exits 0 when absent (parent edits), mirroring the actor split used by the post-edit validator (see `.claude/rules/delegation.md` § *Post-edit validator loop*). On a delegated edit, gitleaks runs against the new content in a temp dir; each finding becomes one `secrets-advisory: <detector> at <file>:<line>` line on stderr. The hook always exits 0 — advisories never block, never revert the edit, and never enter the commit audit log. The soft-signal precedent is the same as the TDD `tdd-advisory:` prefix documented in `.claude/rules/tdd.md` § *Reading the validator advisory*.

## Override grammar

A single line in the `tool_input.command` string matching `^[[:space:]]*# OVERRIDE: <reason>` skips the block. The anchor matters: the regex is **start-of-line** (with optional leading whitespace), copied verbatim from the 002-delegation fix that closed a false-positive where `# OVERRIDE:` inside a quoted string elsewhere on the line was matching. Multi-line commands work; the marker just has to be at the start of its own line.

The reason is the trimmed substring after `# OVERRIDE: ` up to end-of-line. Length is measured after trim. **`<reason>` must be at least 10 characters** — anything shorter (`# OVERRIDE: skip`, `# OVERRIDE: n/a`) is rejected with `secrets-scan: override reason must be ≥10 characters, got "<reason>"` on stderr and the commit still blocks. The 10-char floor is the same as the governance and delegation gates; it forces the operator to type something a future maintainer can grep for in the audit log.

Override semantics are surgical: the marker skips ONLY the block. The gitleaks scan still runs, the audit-log line is still appended, and the `decision` field is recorded as `"override"` with `override_reason` populated from the marker text. There is no silent bypass. Example:

```bash
git commit -m "land auth-test fixture" # OVERRIDE: AWS key is the canonical AKIAIOSFODNN7EXAMPLE test vector
```

## Allowlist mechanics

Two complementary suppression mechanisms, both honored by gitleaks at scan time:

**`.gitleaks.toml` at repo root.** The shipped starter uses `[extend].useDefault = true` to inherit gitleaks' built-in detector set, then a `[[allowlists]]` block exposes the three suppression dimensions:

- `paths = ["tests/fixtures/**/*", "examples/secrets-demo.md"]` — glob patterns. Anything matching is skipped wholesale.
- `regexes = ['''AKIA[0-9A-Z]{16}''', '''ghp_[A-Za-z0-9]{36}''']` — TOML triple-quoted regex strings; matches in any file are suppressed.
- `commits = ["abc123def456..."]` — full SHAs. Useful when a historical commit is known-clean and the scan keeps re-flagging it via amend or rebase.

Add as many `[[allowlists]]` blocks as needed; each one is a logical OR. Schema reference: <https://github.com/gitleaks/gitleaks/blob/master/config/allowlist.go>. The starter ships with `paths = []` as a placeholder — replace with real exemptions or delete the block. Do **not** ship a `.secrets.baseline` (the detect-secrets pattern); that is a non-goal in `spec.md` because Agent0 is a new-repo template with no legacy to freeze.

**Inline `gitleaks:allow`.** A comment containing `gitleaks:allow` on the same line as a high-entropy string suppresses that single finding without modifying `.gitleaks.toml`. The comment form is language-appropriate — `# gitleaks:allow` in shell/Python/TOML, `// gitleaks:allow` in JS/TS/Rust, `<!-- gitleaks:allow -->` in Markdown/HTML. Prefer inline `gitleaks:allow` for one-off lines (a fixture string in a test file); prefer `.gitleaks.toml` paths for whole directories of fixtures.

## Escape hatch

`CLAUDE_SKIP_SECRETS_SCAN=1` in the environment makes the PreToolUse hook exit 0 silently — no scan, no audit entry. Use it for throwaway scratch repos or local Q&A sessions where no commit is intended to land in shared history. Setting the variable in a long-lived shell config is the wrong escape — that disables the gate permanently and silently, which is exactly the failure mode the gate exists to prevent. The override marker is the right tool for "this one commit needs to land despite the finding"; the env var is the right tool for "this whole session is throwaway".

The advisory side has its own env var with the inverse polarity: `CLAUDE_SECRETS_ADVISE_ON_EDIT=1` turns the on-edit advisory **on**. Default is off so the advisory does not surprise users who haven't read this doc — the hard gate is the discipline, the advisory is the optional extra signal.

When gitleaks itself is missing from `PATH`, the hook fails open: one stderr line `secrets-scan: gitleaks not found, scan skipped`, audit-log `decision: "skip-no-engine"`, exit 0. The template is stack-agnostic and the fork chooses whether to install the binary; a broken or absent engine must never permanently lock the agent out of committing.

## Audit log

`.claude/secrets-audit.jsonl`, gitignored, append-only. Every invocation of the commit hook writes exactly one line with fields `ts`, `session_id`, `decision` (one of `block` / `allow` / `override` / `skip-no-engine`), `finding_count`, `override_reason` (or null). The advisory hook does **not** write here — advisories are a stderr stream, not an audit stream. Read with `jq -c .` or `tail -f`, same convention as `.claude/delegation-audit.jsonl`; there is no summary command in v1, and aggregation is a follow-up only if real usage demands it.

## Gotchas

- **Matcher granularity is intentionally loose.** The settings.json matcher fires on any command containing `git`, not just `git commit`. This means `git status`, `git diff`, and `git log` all invoke `secrets-scan.sh` — which short-circuits cheap (no gitleaks call, no audit line) but does pay one bash startup. The alternative — a tight matcher — would miss `cd /path && git commit`, `git -C /path commit`, `git commit --amend`, and any other shape an agent invents. Cheap false fires beat missed real commits.
- **`# OVERRIDE: ...` survives the JSON payload.** Shell strips `# ...` comments before invoking the underlying binary, but the hook receives the raw command string from `tool_input.command` in the stdin JSON payload — the shell hasn't run yet. The marker is intact at the hook level even though `git` itself would never see it. This is the same upstream-of-shell mechanic the governance and delegation gates rely on; verify experimentally if the payload shape changes in a future Claude Code release.
- **Parse gitleaks JSON defensively.** v8.x has been stable but field renames have happened in the past. `jq` with `// empty` fallbacks helps, but mind the `false`-vs-missing collapse documented in `.claude/rules/delegation.md` § *Gotchas (for hook maintainers)* — `jq '.field // empty'` returns the same empty string for a literal `false` and for a missing field, which silently masks real failures. When parsing the `findings` array length, use the `if type=="object" and has("Findings") then ...` shape the delegation gate uses for `ok`, and surface the raw gitleaks output to stderr on parse failure so the agent can still see what happened.
- **FP noise on test fixtures.** Sub-agents writing realistic auth/payments fixtures will trip the detectors. The mitigations are layered: inline `gitleaks:allow` for one-off lines, `.gitleaks.toml` paths for whole fixture dirs, the override marker for a single commit, the env var for throwaway sessions. Pick the narrowest tool that fits — broad escapes accumulate as silent debt.
- **gitleaks version skew across forks.** Detector set and flag names evolve. The rule documents v8.x as the current floor but the hook does not gate on a version check; `gitleaks --version` parse can fail silently and the fail-open path still works. If a fork wants a stricter floor, that is a project-local decision documented in their own CLAUDE.md, not a template concern.
- **Audit-log append atomicity uses `flock`.** Multiple hooks can fire concurrently — a `PostToolUse` advisory running in parallel with a `PreToolUse` gate, for example. JSONL one-line appends are generally safe on Linux for writes ≤ `PIPE_BUF` (typically 4096 bytes), but `flock` is the explicit guarantee against partial-line interleaving. The delegation-gate already does this; copy its pattern (and read its § *Gotchas (for hook maintainers)* for the **sticky `exec 9>file 2>/dev/null` redirect** trap that has bitten this codebase before).
- **The gate is hot on first fork.** Unlike the TDD validator (inert until a stack is detected), the secrets-scan gate fires the moment a fork clones the template, regardless of language stack. A first-time user surprised by a block on a fixture should read this doc top-to-bottom, not just disable the hook in `settings.json`. The escape hatch and override marker are designed for exactly this case.
