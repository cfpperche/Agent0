---
name: secrets-scan-maintenance
description: Design-memory for secrets-scan — version-skew history, dropped-signal archaeology, matcher-fix rationale, env-var bug lineage, and per-release empirical findings.
metadata:
  type: project
  created_at: '2026-06-10T00:00:00-03:00'
---
# Secrets-scan maintenance

Maintainer-binding companion to `.agent0/context/rules/secrets-scan.md`. The companion rule carries operative semantics (layer architecture, blocked shapes, override grammar, env vars, activation command); this memory carries version-skew history, dropped-signal archaeology, design rationales, and empirical findings the maintainer needs when extending or debugging the hook.

## Preflight matcher history

The Claude Code registration originally tried to narrow the hook scope with an `if: "Bash(git commit *|git commit|...)"` filter. **Pipe-alternation inside a single `Bash(...)` is not valid CC permission-rule syntax** — `|` is a shell command separator there, not an alternation operator, so the pattern matched nothing and the preflight stayed dormant on every commit until the bare-matcher fix on 2026-05-28; verified vs the official permissions docs. Multi-prefix narrowing would need one `if` entry per glob, which the body-level short-circuit makes unnecessary. The final design (bare `Bash` matcher on both runtimes, short-circuit in the script body) was chosen because false fires are cheap to short-circuit and missed fires would be unscanned commits.

## Dropped `skip-not-commit` signal

The preflight previously wrote one `skip-not-commit` row per non-commit Bash invocation as proof-the-hook-ran. That was viable only under a narrow command-shape matcher; once the hook runs under a broad `Bash` matcher on both runtimes (Claude `"matcher": "Bash"`, Codex `^Bash$` — the narrow `if`-filter attempt was invalid pipe-alternation, see § *Preflight matcher history* above), a per-non-commit row would turn the log into a shell-activity firehose. The row was removed: non-commit Bash now exits silently with no audit entry. This is a deliberate decision, not a regression — the audit log records commit-shaped invocations only.

## Override grammar: delegation-gate lineage

The start-of-line anchor (`^[[:space:]]*# OVERRIDE: <reason>`) was copied from the delegation-gate fix (spec 002) that closed a `# OVERRIDE:` -inside-quoted-string false-positive. Inline-trailing markers on a single line are NOT accepted — they re-open that regression. Maintainers extending the marker syntax must preserve the start-of-line anchor.

## Runtime-aware rewrite output: discovery history

The `hookSpecificOutput` shape divergence between Claude Code and Codex CLI was discovered empirically in 2026-05-28 by verifying against the official Codex hooks docs. Key findings:

- **Codex CLI** requires `permissionDecision:"allow"` *alongside* `updatedInput` — without it the rewrite is silently ignored, the env var never propagates, and the native scanner blocks despite a valid override.
- **Claude Code** must NOT receive `permissionDecision:"allow"` — on Claude that value auto-approves the tool call and bypasses the normal permission prompt — a silent UX change that was rejected. The narrower `updatedInput`-only shape preserves the usual permission flow.

## Env-var inline-prefix bug (latent, fixed in `4b47a42`)

The injection MUST be `export VAR='...'; cmd` (standalone statement + `;`), NOT the inline prefix `VAR=val cmd`. The prefix form scopes the assignment to its single command — on `VAR=val git add foo && git commit -m "..."` the var reaches `git add` but NOT the chained commit, so the native hook blocks. This was a latent bug fixed in `4b47a42`. V4 test (`.agent0/tests/secrets-scan/04-override-allows.sh`) asserts the rewriting starts with `export CLAUDE_SECRETS_OVERRIDE_REASON=` as a regression guard against re-introducing the prefix form.

## Audit log path move

`.agent0/secrets-audit.jsonl` was moved from `.claude/` in the multi-runtime port; hard cutover — no legacy-read of the old path. Any consumer project that had rows at `.claude/secrets-audit.jsonl` before the port has a silent gap in history; the new path is canonical.

## Allowlist singular vs plural table: empirical confirmation

`[allowlist]` (singular) vs `[[allowlists]]` (plural array-of-tables) was empirically verified on 2026-05-19 against gitleaks 8.21.2: the plural form parses without error but no exemption ever applies — findings still surface as if the table were absent. Always use the singular form.

## Stopword dogfood failure (Tier-2 regression)

Empirically confirmed 2026-05-13: a Tier-2 dogfood committed `AKIAIOSFODNN7EXAMPLE` expecting a block; preflight wrote `passthrough` and native wrote `allow` (zero findings) — gate worked exactly as designed, the test input was the bug. Reverted in `f2ae87f`. Gitleaks' default ruleset includes a stopword list that explicitly exempts canonical AWS documentation examples (`AKIAIOSFODNN7EXAMPLE`, `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`, and similar). Synthetic non-stopword fakes to use for block-path validation: `AKIAJZTRFAKEKEYABCDE` or `AKIAQQ7777FAKEKEY999`. Symmetric trap exists for GitHub PATs (`ghp_0000000000000000000000000000000000` and other zero-runs) and Slack/Stripe tokens. Reference: <https://github.com/gitleaks/gitleaks/blob/master/config/gitleaks.toml> (search `keywords`/`stopwords` on the AWS rule). <!-- gitleaks:allow — documented scanner test vectors, not credentials -->

## Audit-log atomicity: sticky redirect trap

Both hooks follow the delegation-gate pattern for `flock`. The delegation-gate's § *Gotchas (for hook maintainers)* documents the **sticky `exec 9>file 2>/dev/null` redirect** trap that bit this codebase before — a redirect that stays open across invocations can interleave append writes. Any future refactor of the flock pattern in either hook must re-verify against that trap.

## Claude Code stderr ingestion: issue context

The "stderr ingestion on exit-2 blocks" behavior referenced in the rule (where Claude Code ingests hook exit-2 stderr into agent context) was tracked as Claude Code issue #24327. The shape-rejection templates end with the EXACT corrected form so agents can pattern-match without semantic reasoning; this is a contract, not friendly UI text. If the templates drift in wording, the correction loop degrades to prose inference.

## Cross-references

- `.agent0/context/rules/secrets-scan.md` — operative companion (two-layer architecture, blocked shapes, override grammar, escape hatch, activation command)
- `.agent0/hooks/secrets-preflight.sh` — preflight implementation
- `.githooks/pre-commit` — native pre-commit implementation
- `.agent0/tests/secrets-scan/` — scenario test suite (11 scenarios)
- `.agent0/context/rules/delegation.md` § *Gotchas (for hook maintainers)* — sticky flock redirect trap documentation
