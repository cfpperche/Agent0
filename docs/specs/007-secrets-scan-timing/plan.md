# 007 — secrets-scan-timing — plan

_Drafted from `spec.md` on 2026-05-10. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

**Layered defense: a versioned `.githooks/pre-commit` script activated by `core.hooksPath` (primary), with the existing `.claude/hooks/secrets-scan.sh` retained and extended to do command-shape gating + override-marker handling (secondary).** The primary layer runs in `git commit`'s own process *after* staging is finalized, so `gitleaks git --pre-commit --staged` sees the real index regardless of compound `git add ... && git commit ...` or `-a`. The secondary layer remains where the original spec-006 hook lives and keeps three responsibilities that cannot move down the stack: parsing the `# OVERRIDE: <reason ≥10 chars>` marker from the Bash command string, rejecting `git commit --no-verify` (which would silently bypass the native hook), and preserving `session_id` / `agent_id` in the audit log (those fields are unavailable inside a native git hook).

Cross-layer communication for the override path uses Claude Code's PreToolUse `updatedInput` mechanism: when the secondary layer detects a valid override marker, it rewrites the Bash command to prepend `CLAUDE_SECRETS_OVERRIDE_REASON='<reason>'`, which then flows naturally into the bash subprocess → git's environment → the native hook's environment. The native hook reads the env var, still runs gitleaks, still audits, but skips the block. The original behavior of "override always runs the scan, only suppresses the block" is preserved byte-for-byte from spec 006.

Implementation order, dependency-respecting: (1) ship `.githooks/pre-commit` shell script that runs `gitleaks git --pre-commit --staged`, writes audit entries with `scan_mode: "native-pre-commit"`, honours `CLAUDE_SECRETS_OVERRIDE_REASON` env var; (2) update `secrets-scan.sh` to (a) migrate to current gitleaks invocation, (b) add command-shape gating that rejects compound `git add && git commit` and `git commit -a` and `--no-verify` unless override marker present, (c) implement override → `updatedInput` env-var injection, (d) tag audit entries with `scan_mode: "preflight"`; (3) update `README.md` § *Per-fork checklist* with one new line: `git config core.hooksPath .githooks` after `git init`; (4) update `.claude/rules/secrets-scan.md` and `CLAUDE.md` § *Secrets scan* to reflect the layered model; (5) write test scripts under `tests/secrets-scan/` that exercise all seven scenarios from `spec.md`; (6) amend `docs/specs/006-secrets-scan/tasks.md` § *Notes* with a pointer to 007.

The chosen model deliberately accepts one new per-fork install step (the `core.hooksPath` config line). Spec 007 § *Acceptance criteria* (last scenario) explicitly budgets for this: "no additional manual hook configuration beyond steps already listed, OR exactly one new step in the checklist with a one-line description". One line, one command, no scripting — the minimum viable shape.

## Files to touch

**Create:**
- `.githooks/pre-commit` — the native git pre-commit hook. Executable shell script. Runs `gitleaks git --pre-commit --staged --no-banner --report-format=json --report-path=<tmp>`, reads `CLAUDE_SECRETS_OVERRIDE_REASON` env var, appends to `.claude/secrets-audit.jsonl` with `scan_mode: "native-pre-commit"`. Mirrors the audit-line shape from spec 006 minus `session_id` / `agent_id` (set to `null`).
- `tests/secrets-scan/` — directory of shell scripts, one per spec.md scenario. Each script creates a throwaway git repo under `/tmp/`, exercises a scenario, asserts the expected outcome (exit code + audit line + `git log` state), cleans up. Run by `tests/secrets-scan/run-all.sh`. No language runtime needed — pure shell + `jq`.

**Modify:**
- `.claude/hooks/secrets-scan.sh` — extend with (a) command-shape gating (reject compound + `-a` + `--no-verify` unless override), (b) override → `updatedInput` env-var injection, (c) migrate `gitleaks protect --staged` to `gitleaks git --pre-commit --staged`, (d) audit entries gain `scan_mode: "preflight"` field. The existing scan-the-index code path is *removed* — preflight scanning was the bug. The preflight hook becomes a pure gatekeeper: shape-check, override-handle, audit, then either pass through (rewriting input if override) or reject.
- `README.md` § *Per-fork checklist* — add one line under the gitleaks step: `git config core.hooksPath .githooks` (one-time, after `git init`). Layout tree gains `.githooks/` entry.
- `.claude/rules/secrets-scan.md` — full rewrite of § *What fires* (now describes the two layers and their responsibilities); § *Override grammar* explains the env-var bridge; § *Gotchas* gains five new entries from research (Lazarus `core.hooksPath` vector, `--no-verify` bypass discipline, global `core.hooksPath` shadowing, `git commit -a` requires explicit cmd-shape rejection, exit-2 stderr ingestion bug #24327).
- `CLAUDE.md` § *Secrets scan* — update the one-paragraph pointer to mention the layered model and the install step.
- `.gitignore` — add `tests/secrets-scan/.tmp/` (or wherever the test repos are scratchpad'd).
- `docs/specs/006-secrets-scan/tasks.md` § *Notes* — pointer entry: "Timing fix delivered in spec 007; pre-commit scan moved to native `.githooks/pre-commit`. This original `PreToolUse(Bash)` implementation was preflight-only and missed compound `git add && git commit`."

**Delete:** none. The spec-006 hook stays — extended, not replaced.

## Alternatives considered

### 1a — Native `.git/hooks/pre-commit` (uncommitted, copied per clone)
Rejected. `.git/` is not version-controlled, so every fork must copy the hook script in by hand or via a bootstrap script. That bootstrap script either lives at repo root (then it has to be remembered) or runs on `git clone` (the documented Lazarus Group attack vector — `core.hooksPath` poisoning was via this exact pattern). Versioning the script via `.githooks/` + `core.hooksPath` is the same mechanism but with the script tracked in git history, reviewable in PRs, and consciously activated rather than silently injected.[^1]

### 1b — Command-shape gating alone (no native hook)
Rejected as primary; retained as secondary. Cmd-shape gating works in isolation but is brittle: it depends on the agent obeying the corrected separated `git add` then `git commit` shape on the retry. Claude Code issue #24327 documents PreToolUse exit-2 stderr ingestion being intermittent — the agent does not always loop back into the corrected form, so the rejection can produce a stuck turn rather than a corrected one.[^2] As a secondary defense it is invaluable (preserves `session_id`/`agent_id`, blocks `--no-verify`, parses the override marker), but trusting it as the only line of defense puts correctness behind a flaky agent-feedback loop.

### 1d — Third-party orchestrator (lefthook / pre-commit.com / husky)
Rejected on the stack-agnostic constraint. **pre-commit.com** requires Python; **husky** requires Node + a `package.json` (assumes JS project). **lefthook** is the closest fit — Go binary, no runtime once installed, MIT — but still requires the fork to install a Go binary out-of-band beyond gitleaks and run `lefthook install`. Agent0's existing dependency story is "you need gitleaks if you want secrets-scan active, otherwise it fails open"; adding a second tool with its own version-skew and install ceremony doubles that surface area for no architectural gain. If a fork already standardizes on lefthook for its own reasons, layering Agent0's `.githooks/pre-commit` over it is straightforward (lefthook can be configured to run external scripts) — but the template should not assume it.[^3][^4][^5]

### 2 — Move the entire scan into the native hook and delete `secrets-scan.sh`
Rejected. Three responsibilities cannot live in a native git hook process: (a) parsing the `# OVERRIDE:` marker, which exists only in the Bash command string that the agent's harness sees; (b) writing `session_id` and `agent_id` into the audit log, which only Claude Code's hook payload carries; (c) rejecting `--no-verify`, because by the time the native hook fires for a `--no-verify` commit, the commit has already bypassed it. Each one of these requires the preflight layer.

### 3 — Inline gitleaks regex fallback in pure bash
Rejected (already a non-goal carried from spec 006). The benchmark + maintenance arguments still hold.

## Risks and unknowns

- **`core.hooksPath` is the Lazarus Group's documented attack vector.** A poisoned `.git/config` in a cloned repo can hijack hook execution. Mitigation: the install step in `README.md` is manual (`git config core.hooksPath .githooks`), never auto-applied by a post-clone script. Document this in `.claude/rules/secrets-scan.md`.[^1]
- **`session_id` and `agent_id` are unavailable inside the native git hook.** Native-hook audit entries will carry `null` for those fields, and only the preflight-layer audit line will have them. Audit consumers must `jq`-filter accordingly; the `scan_mode` field exists to make this explicit. Acceptable: the lost context is a small ergonomic cost for the gain of correct timing.
- **`git commit --no-verify` silently bypasses the native hook.** The preflight layer MUST reject `--no-verify` on `git commit` unless an `# OVERRIDE:` marker is present. The governance-gate already blocks `--no-verify` more broadly, but spec 007's preflight layer should not assume the governance-gate ordering — it does its own check and audits separately.
- **PreToolUse exit-2 stderr ingestion is intermittently buggy.** Claude Code issue #24327 documents the agent occasionally stopping instead of acting on stderr. Mitigation: stderr message template is short, scannable, and ends with the exact corrected command shape so the agent can pattern-match without semantic reasoning.[^2]
- **Override marker grammar lives only in the preflight layer.** If a future contributor deletes or significantly rewrites the preflight hook, the override mechanism vanishes — the native hook only knows about the env var. Encode this dependency in `.claude/rules/secrets-scan.md` § *Gotchas* and reference it from `.githooks/pre-commit`'s comment header.
- **Global `core.hooksPath` setting shadows repo-local.** A defensively configured `git config --global core.hooksPath ~/empty` deactivates Agent0's hook entirely. The preflight layer is the backstop for this configuration; document in `secrets-scan.md` that *both* layers exist precisely so that misconfiguring one does not silently disable secrets scanning.[^1]
- **`git commit -a` is the new silent-failure shape.** Inside the preflight layer it appears as a single (non-compound) command, so the cmd-shape gate must *explicitly* reject `git commit -a` (without override). The native hook handles `-a` correctly by itself, but the preflight audit-line / `session_id` discipline depends on the preflight rejection.
- **`gitleaks protect --staged` was deprecated in 2025** in favor of `gitleaks git --pre-commit --staged` per the official `.pre-commit-hooks.yaml` entry.[^4] Spec 007 migrates both the native hook and the preflight layer to the current invocation. Forks on older gitleaks (<8.20) may not have the new subcommand; document the minimum version in the rule doc.
- **Test plan must be hermetic.** Test scripts under `tests/secrets-scan/` create throwaway git repos in `/tmp/`, never operate on the Agent0 repo itself. A test that staged real `AKIA1234567890ABCDEF` in the Agent0 working tree could be caught by the hook itself, producing a confusing failure mode. Guard with explicit `cd /tmp/test-<scenario>-<pid>` at the top of every script.
- **Empty index `git commit --allow-empty` is a real path.** The native hook should treat this as `decision: "allow", finding_count: 0, scan_mode: "native-pre-commit", staged_files_count: 0` — distinguishable from the buggy spec-006 path which produced the same `decision/finding_count` but with `scan_mode: "preflight"` and a non-zero true `staged_files_count`. The audit-log structure intentionally makes the silent-failure mode unreproducible.

## Research / citations

Comparative research conducted on 2026-05-10 by a delegated research agent (~30 min web research). Mechanism choice resolved to `core.hooksPath` + versioned `.githooks/` as primary, with command-shape gating retained as secondary.

Primary sources informing the four-way comparison:

- **Git githooks documentation** — pre-commit firing semantics, exit codes, `--no-verify` bypass, no stdin/params: https://git-scm.com/docs/githooks
- **`core.hooksPath` introduced in git 2.9** (June 2016, mature in 2.21+): cross-referenced via `pivotal-cf/git-hooks-core` https://github.com/pivotal-cf/git-hooks-core
- **`typicode/husky`** — confirms `core.hooksPath` is the production-grade mechanism (husky itself uses it internally), MIT, ~2 kB: https://github.com/typicode/husky
- **`evilmartians/lefthook`** — Go binary, MIT, current v2.1.6 (April 2026), install via many channels: https://github.com/evilmartians/lefthook
- **`pre-commit.com`** — Python runtime required, `.pre-commit-config.yaml`: https://pre-commit.com/
- **`gitleaks` README** — primary recommendation: pre-commit.com integration; lefthook explicitly named for team-shared hooks; example `pre-commit.py` for native: https://github.com/gitleaks/gitleaks
- **`gitleaks/.pre-commit-hooks.yaml`** — the current canonical pre-commit invocation `gitleaks git --pre-commit --redact --staged --verbose` (deprecates `gitleaks protect --staged`): https://github.com/gitleaks/gitleaks/blob/master/.pre-commit-hooks.yaml
- **Claude Code hooks reference** — PreToolUse `updatedInput`, exit-2 stderr feedback: https://code.claude.com/docs/en/hooks
- **Claude Code issue #24327** — PreToolUse hook exit code 2 sometimes causes Claude to stop instead of acting on stderr: https://github.com/anthropics/claude-code/issues/24327

Security context:

- **Lazarus Group "Contagious Interview" 2025 campaign** — malware delivered via poisoned `core.hooksPath` in cloned repos: https://www.msbiro.net/posts/lazarus-group-git-hooks-malware-developers/

Industry comparison sources:

- **pkgpulse husky-vs-lefthook-vs-lint-staged-vs-pre-commit (2026)** — adoption numbers, runtime tradeoffs: https://www.pkgpulse.com/blog/husky-vs-lefthook-vs-lint-staged-git-hooks-nodejs-2026
- **Andy Madge — Git Hook Frameworks Comparison 2026** — recommendations by repo type: https://www.andymadge.com/2026/03/10/git-hooks-comparison/

Internal sibling specs whose patterns this plan reuses:

- `docs/specs/001-governance-gate/` — `PreToolUse(Bash)` hook shape; `--no-verify` rejection precedent
- `docs/specs/002-delegation/` — audit JSONL append pattern with `flock`, parent-vs-sub-agent split via `agent_id`
- `docs/specs/006-secrets-scan/` — the spec being fixed; all override-marker grammar, allowlist mechanics, advisory hook, and starter `.gitleaks.toml` are inherited verbatim

[^1]: https://www.msbiro.net/posts/lazarus-group-git-hooks-malware-developers/
[^2]: https://github.com/anthropics/claude-code/issues/24327
[^3]: https://github.com/evilmartians/lefthook
[^4]: https://github.com/gitleaks/gitleaks/blob/master/.pre-commit-hooks.yaml
[^5]: https://pre-commit.com/
