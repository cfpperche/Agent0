# 108 — secrets-scan-multi-runtime — tasks

_Generated from `plan.md` on 2026-05-28._

## Implementation

- [x] 1. `git mv .claude/hooks/secrets-scan.sh .agent0/hooks/secrets-preflight.sh`
- [x] 2. Edit the hook: header comment; source `_memory-hook-lib.sh`; `PROJECT_DIR=memory_project_dir`; AUDIT_LOG → `.agent0/secrets-audit.jsonl`; add `runtime` field to audit rows; drop `skip-not-commit` audit (silent exit 0 for non-commit); runtime-branched override output (codex → `permissionDecision:"allow"`+updatedInput, claude → updatedInput-only).
- [x] 3. `.claude/settings.json` → repoint to `.agent0/hooks/secrets-preflight.sh` (keep the `if` matcher).
- [x] 4. `.codex/config.toml.example` → add commented `^Bash$` PreToolUse block for secrets-preflight (after governance block).
- [x] 5. `.githooks/pre-commit` → AUDIT_LOG to `.agent0/secrets-audit.jsonl`; add `runtime:"native-git"` to append_audit.
- [x] 6. `.gitignore` → audit path `.claude/` → `.agent0/` (+ `.lock`).
- [x] 7. `.claude/tests/secrets-scan/*.sh` → AGENT0_PREFLIGHT + AUDIT_LOG paths (01-07 + run-all).
- [x] 8. Perf harness: `bench-hooks.sh` HOOK_NAMES, `.perf-baseline.json` key, `hook-chain-latency/01-baseline-exists.sh` → `secrets-preflight.sh`.
- [x] 9. `.claude/tests/harness-sync/13,14,15` → gitignore entry `.claude/secrets-audit.jsonl` → `.agent0/secrets-audit.jsonl`.
- [x] 10. `.claude/rules/secrets-scan.md` → paths frontmatter + body (path/name, runtime-branched output, guardrail wording, dropped skip-not-commit, Codex activation).
- [x] 11. Doc index: `CLAUDE.md`, `AGENTS.md`, `README.md` path refs.
- [x] 12. Comment-only path refs in sibling hooks (`supply-chain-scan.sh`, `runtime-capture.sh`, `governance-gate.sh`, `session-start.sh`).
- [x] 13. Memory refresh: 6 entries with stale `secrets-scan.sh`/audit-path references.

## Verification (acceptance)

- [x] V1. `bash .claude/tests/secrets-scan/run-all.sh` → all 7 PASS (Claude block + override rewrite end-to-end).
- [x] V2. New shape-test: synthetic Codex payload (no `CLAUDE_PROJECT_DIR`, with `cwd`) + override → emitted JSON has `permissionDecision:"allow"`; Claude payload → no `permissionDecision`.
- [x] V3. New: non-commit Bash payload → exit 0, no audit row written.
- [x] V4. New: subdirectory-cwd payload → audit log lands at repo root, not the subdir.
- [x] V5. `bash .claude/tests/hook-chain-latency/01-baseline-exists.sh` → PASS post-rename.
- [x] V6. `grep -rn '.claude/hooks/secrets-scan.sh\|.claude/secrets-audit.jsonl'` → clean (no stale refs outside docs/specs history).
- [x] V7. `bash .claude/tests/harness-sync/run-all.sh` (or the 13/14/15 trio) → PASS.
- [x] V8. Live PreToolUse dogfood on BOTH runtimes. Codex: PASS 2026-05-28 (block + override rewrite reached Bash/native). Claude: PASS 2026-05-28 after fixing a dormant `if`-pipe registration bug (pipe-alternation inside one `Bash(...)` is invalid CC syntax → preflight never fired; dropped the `if`, now bare `"matcher": "Bash"`). Block row `reject-shape`/`compound-and`/`claude-code`; override row `override-pass-through` + native `override`/`finding_count:1`.
