# 006 — secrets-scan — plan

_Drafted from `spec.md` on 2026-05-10. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Build a `PreToolUse(Bash)` hook (`.claude/hooks/secrets-scan.sh`) that intercepts `git commit` invocations, runs `gitleaks protect --staged` against the staged diff, and either blocks the commit (exit 2 with detector class + `file:line` on stderr) or allows it. The hook reuses the established 001-governance-gate / 002-delegation pattern: stdin JSON payload → bash parsing → conditional `exit 2` block → append-only audit JSONL. The `# OVERRIDE: <reason ≥10 chars>` marker grammar is anchored to start-of-line (matches the 002 fix; see the dogfood-discovered false-positive note in SESSION.md). A second, opt-in `PostToolUse(Edit|Write|MultiEdit)` hook (`.claude/hooks/secrets-advise.sh`) emits `secrets-advisory:` lines on stderr when `CLAUDE_SECRETS_ADVISE_ON_EDIT=1` and is exempt for parent-agent edits via the `agent_id` payload field — same actor split as the post-edit validator.

Order of implementation is incremental so the wiring is proven before the detector lands: (1) stub `secrets-scan.sh` that audit-logs every commit and passes; (2) add gitleaks invocation + JSON parse + block path; (3) add override-marker logic; (4) add fail-open + warn-once when binary missing; (5) ship `secrets-advise.sh` for the on-edit advisory; (6) wire the two hooks in `.claude/settings.json`; (7) write `.claude/rules/secrets-scan.md` + CLAUDE.md pointer; (8) ship starter `.gitleaks.toml` + gitignore the audit log. This shape lets each step be independently verified — the stub proves the harness routing, then each subsequent step adds one observable behavior.

Open questions from `spec.md` resolved here:
- **Starter `.gitleaks.toml`** → ship it (Option A). Empty `[[allowlists]]` block with `[extend].useDefault = true` and a comment pointing at the rule doc. Discoverability wins over minimalism: a fork that needs an exemption shouldn't have to learn the config schema cold.
- **Scan scope** → `gitleaks protect --staged` only. The commit-time gate's contract is "what is about to be committed", not "what is in the working tree". Whole-tree scanning catches a different class of problem (pre-existing leaks) that belongs to a separate audit operation, not the commit gate.
- **On-edit advisory: diff vs whole-file** → diff-only for v1. Cheaper, semantically "what the agent just wrote". Promote to whole-file only if dogfood reveals false negatives.
- **Audit consumption** → `jq`/`tail` only, no summary command. Same convention as `delegation-audit.jsonl`. Aggregation can be a follow-up if real usage demands it.

## Files to touch

**Create:**
- `.claude/hooks/secrets-scan.sh` — `PreToolUse(Bash)` gate. Parses stdin JSON, short-circuits unless the command is `git commit`, runs gitleaks, blocks-or-allows, audit-logs every invocation.
- `.claude/hooks/secrets-advise.sh` — `PostToolUse(Edit|Write|MultiEdit)` advisory. Opt-in via `CLAUDE_SECRETS_ADVISE_ON_EDIT=1`. Parent-agent exempt (`agent_id` absent). Never blocks.
- `.claude/rules/secrets-scan.md` — discipline doc: when it fires, override grammar, allowlist mechanics, gotchas, escape via `CLAUDE_SKIP_SECRETS_SCAN=1`.
- `.gitleaks.toml` — starter config: `[extend].useDefault = true`, empty `[[allowlists]]`, comment pointing at the rule.

**Modify:**
- `.claude/settings.json` — register the two hooks.
- `.gitignore` — add `.claude/secrets-audit.jsonl`.
- `CLAUDE.md` — add `## Secrets scan` section (≤5 lines, points at the rule).
- `.claude/SESSION.md` — bumped at end of session per the session-handoff rule (not a planned content change, but it will be touched).

**Delete:** none.

## Alternatives considered

### Inline pure-bash regex detector instead of wrapping gitleaks
Rejected. Independent benchmark (Setu et al., arXiv 2307.00714) measured gitleaks F1=0.60 with a curated ruleset; rolling our own would ship a smaller detector set with worse FP/FN tuning *and* take on permanent maintenance. The fail-open-when-missing path lets us depend on gitleaks without breaking forks that don't install it, which is the only real reason to avoid an external binary.

### trufflehog v3 instead of gitleaks
Rejected on three axes. (a) AGPL-3.0 license is redistribution friction for a public template; gitleaks is MIT. (b) Its strongest mode (`--results=verified`) requires network egress to provider APIs, which violates the template's offline-friendly posture and adds an opaque latency tax to every commit. (c) Raw F1 without verification was 0.23 in the same benchmark — materially worse than gitleaks at the only mode that works without network.

### Wrap pre-commit framework (https://pre-commit.com) instead of a native hook
Rejected. Adds a Python+pip dependency, a `.pre-commit-config.yaml`, and a `pre-commit install` setup step. The Agent0 harness already has `PreToolUse(Bash)` plumbing; running two parallel hook systems for the same lifecycle event is strictly worse than one. Forks that already use pre-commit can layer it on top — the gitleaks binary is the same either way.

### Hard block on edit, not just commit
Rejected. Agents write partial fixtures and half-typed strings constantly mid-thought; blocking the edit would fight the workflow without preventing a leak (the commit hook catches it anyway). On-edit becomes a soft advisory the agent can opt into when the project is sensitive enough to want the earlier signal.

### Ship a `.secrets.baseline` (detect-secrets pattern)
Rejected (also a non-goal in spec). Baselines are for legacy repos with pre-existing secret-shaped strings you can't realistically remove; a template repo has no legacy. Shipping one would mean importing whatever shapes happen to exist today as permanently-allowed, which is the opposite of the discipline.

## Risks and unknowns

- **`PreToolUse(Bash)` matcher granularity.** Claude Code's matcher is glob-like. Reliably catching every `git commit` shape (`git commit`, `git  commit`, `git -C /path commit`, `cd /path && git commit`, `git commit --amend`) via the matcher alone is fragile. Plan: matcher fires on any command containing `git`, and the script itself short-circuits unless its parsing identifies a real commit. False-fire cost is one fast gitleaks call (cheap); missed-fire cost is an unscanned commit (bad) — bias toward over-firing.
- **`# OVERRIDE: ...` after `git commit -m "..."`.** Shell comment syntax is stripped before `git` sees it, but the hook receives the raw command string from the JSON payload, so the marker is intact upstream. Confirm experimentally before relying on it.
- **Audit log append race.** Multiple hooks could fire concurrently. JSONL one-line-append is generally safe on Linux for writes ≤ PIPE_BUF, but `flock` is the explicit guarantee. The delegation-gate already does this — copy its pattern.
- **gitleaks version skew across forks.** Detector set + flags evolve. Plan: document a minimum version in the rule (current latest v8.x) but don't gate on it; let `gitleaks --version` parse fail silently. The fail-open path already covers the absent case.
- **gitleaks JSON output stability.** v8.x has been stable but field renames have happened. Parse defensively (`jq` with `// empty` fallbacks where appropriate, but mind the `false`-vs-missing gotcha from delegation rules); surface the raw output to stderr when parse fails so the agent can still see what happened.
- **gitleaks stopword suppression on AWS detector.** Discovered during implementation (Brief 2 + Brief 3, both independently): gitleaks 8.21.2 filters AWS-access-key matches that contain the substring `EXAMPLE`, so `AKIAIOSFODNN7EXAMPLE` (the AWS-documented canonical test key) is suppressed at the detector level — it's a *stopword*, not a *test vector*. This bit the V1 verification step (now patched in `tasks.md` to use `AKIA1234567890ABCDEF`). Other detectors likely have analogous stopword lists; documentation tests in spec verifications should use pattern-valid shapes that don't contain detector-specific noise tokens.
- **On-edit advisory FP noise.** Sub-agents writing realistic test fixtures will trip detectors. Mitigation is already documented: `gitleaks:allow` inline, env-var opt-in, and the soft `secrets-advisory:` prefix keeps the signal distinguishable from blocks.
- **Validator is inert in this base repo — secrets-scan is NOT.** Unlike the TDD warning, this hook fires the moment a fork copies the template, regardless of stack. That is the point, but it means a fork's first commit may surprise the user if they hadn't read CLAUDE.md. Solution: the CLAUDE.md pointer is short and the rule doc explains the escape (`CLAUDE_SKIP_SECRETS_SCAN=1` for the throwaway case).

## Research / citations

Comparative research conducted on 2026-05-10 (general-purpose agent dispatch, ~30 min web research budget). Primary sources informing the four core decisions:

- **gitleaks** repo, README, and config docs — https://github.com/gitleaks/gitleaks
- **gitleaks allowlist source** (`[[allowlists]]` schema, `targetRules`) — https://github.com/gitleaks/gitleaks/blob/master/config/allowlist.go
- **trufflesecurity/trufflehog** (rejected engine, license + verification mode reference) — https://github.com/trufflesecurity/trufflehog
- **Yelp/detect-secrets** (informed allowlist + baseline thinking) — https://github.com/Yelp/detect-secrets
- **Setu et al.**, "A Comparative Study of Software Secrets Reporting by Secret Detection Tools" (arXiv 2307.00714), F1 benchmark cited — https://ar5iv.labs.arxiv.org/html/2307.00714
- **pre-commit.com** convention (hard-block-on-nonzero-exit, dominant industry pattern) — https://pre-commit.com/
- **GitGuardian** git-hooks glossary — https://www.gitguardian.com/glossary/git-hooks
- **Soteri** SDLC secrets-scanning placement — https://soteri.io/blog/secret-scanning-tools-for-the-sdlc

Internal sibling specs whose patterns this plan reuses:
- `docs/specs/001-governance-gate/` — `PreToolUse(Bash)` hook shape, override-marker grammar
- `docs/specs/002-delegation/` — audit JSONL append pattern, parent-vs-sub-agent actor split via `agent_id`, `bash -n` clean discipline, the two bash gotchas (`jq '// empty'` collapse + sticky stderr redirect)
