# 108 — secrets-scan-multi-runtime — plan

_Drafted from `spec.md` on 2026-05-28._

## Approach

Move + rename `.claude/hooks/secrets-scan.sh` → `.agent0/hooks/secrets-preflight.sh`, refactor it to be runtime-neutral (source `_memory-hook-lib.sh` for root + runtime detection), make the override output runtime-aware, drop the `skip-not-commit` audit row, and move the audit log to `.agent0/secrets-audit.jsonl` with a `runtime` provenance field. Then cascade every reference (settings, codex example, native pre-commit, gitignore, tests, perf harness, rule, doc index, memory).

## Key decisions

- **Override output is runtime-branched, not unified.** Codex → `{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","updatedInput":{"command":...}}}`; Claude → `updatedInput`-only (current shape). Conservative resolution of Q1's sub-question: emitting `permissionDecision:"allow"` unconditionally on Claude could auto-approve a tool call and skip a permission prompt, a silent UX change. Branching via `memory_runtime "$INPUT"` avoids that risk and keeps test 04 (Claude payload → updatedInput-only) green.
- **Root resolution via `memory_project_dir "$INPUT"`** replaces `PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"` — fixes the Codex subdirectory-cwd case.
- **Non-commit Bash exits silently, no audit row.** Reverses the current "audit skip-not-commit" behavior; required because Codex's `^Bash$` matcher would otherwise flood the log. No test asserts `skip-not-commit` (verified), so the removal is safe.
- **Audit log hard-cutover** to `.agent0/secrets-audit.jsonl` (no legacy-read), `runtime` field added to preflight rows (`claude-code`/`codex-cli`) and the native row (`native-git`). Decision values unchanged.
- **Rename file only**, keep slug/test-dir/audit-filename `secrets-scan`/`secrets-audit`.

## Files to touch

- `.agent0/hooks/secrets-preflight.sh` (git mv + edits)
- `.claude/settings.json` (repoint, keep the `if Bash(git commit ...)` matcher)
- `.codex/config.toml.example` (new commented `^Bash$` PreToolUse block, after governance)
- `.githooks/pre-commit` (AUDIT_LOG path + `runtime:"native-git"` field)
- `.gitignore` (audit path)
- `.claude/tests/secrets-scan/*.sh` (AGENT0_PREFLIGHT + AUDIT_LOG paths, all 7 + run-all)
- `.agent0/tools/bench-hooks.sh`, `.claude/.perf-baseline.json`, `.claude/tests/hook-chain-latency/01-baseline-exists.sh` (rename key)
- `.claude/tests/harness-sync/13,14,15` (gitignore entry assertion)
- `.claude/rules/secrets-scan.md` (paths frontmatter + body)
- `CLAUDE.md`, `AGENTS.md`, `README.md` (path index)
- comment-only path refs: `supply-chain-scan.sh`, `runtime-capture.sh`, `governance-gate.sh`, `session-start.sh`
- memory refresh: `capacity-spec-index.md`, `cc-platform-hooks.md`, `hook-chain-latency.md`, `hook-chain-maintenance.md`, `rule-load-debug.md`, `user-global-hooks-shadow.md`

## Alternatives considered

- **Unified output shape (`permissionDecision:"allow"` on both).** Rejected: risks a silent Claude permission-prompt bypass; the runtime branch is strictly safer and `memory_runtime` already exists.
- **Keep audit log at `.claude/`.** Rejected: both writers are runtime-neutral after the port; delegation (106) set the `.agent0/` hard-cutover precedent.
- **Bundle supply-chain here.** Rejected (debate Q4): separate pass that reuses these lessons.

## Risks / unknowns

- **Codex live dogfood is human-dependent** — requires editing local `.codex/config.toml`, restarting Codex, running a real commit-shape + a rewrite. I validate everything else (Claude block, per-runtime override shape via synthetic payloads, all tests, grep-clean, perf baseline). The Codex live step is flagged as a handoff item, not silently claimed.
- **Runtime detection** — `memory_runtime` keys on `CLAUDE_PROJECT_DIR` unset → codex. Tests export `CLAUDE_PROJECT_DIR` → resolve to `claude-code` (correct for the Claude-shape assertion). A synthetic Codex payload (no `CLAUDE_PROJECT_DIR`, with `cwd`) drives the codex branch for the new shape test.
