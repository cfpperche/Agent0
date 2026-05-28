# 108 — secrets-scan-multi-runtime — tasks

_Generated from `plan.md` on 2026-05-28._

## Implementation

- [ ] 1. `git mv .claude/hooks/secrets-scan.sh .agent0/hooks/secrets-preflight.sh`
- [ ] 2. Edit the hook: header comment; source `_memory-hook-lib.sh`; `PROJECT_DIR=memory_project_dir`; AUDIT_LOG → `.agent0/secrets-audit.jsonl`; add `runtime` field to audit rows; drop `skip-not-commit` audit (silent exit 0 for non-commit); runtime-branched override output (codex → `permissionDecision:"allow"`+updatedInput, claude → updatedInput-only).
- [ ] 3. `.claude/settings.json` → repoint to `.agent0/hooks/secrets-preflight.sh` (keep the `if` matcher).
- [ ] 4. `.codex/config.toml.example` → add commented `^Bash$` PreToolUse block for secrets-preflight (after governance block).
- [ ] 5. `.githooks/pre-commit` → AUDIT_LOG to `.agent0/secrets-audit.jsonl`; add `runtime:"native-git"` to append_audit.
- [ ] 6. `.gitignore` → audit path `.claude/` → `.agent0/` (+ `.lock`).
- [ ] 7. `.claude/tests/secrets-scan/*.sh` → AGENT0_PREFLIGHT + AUDIT_LOG paths (01-07 + run-all).
- [ ] 8. Perf harness: `bench-hooks.sh` HOOK_NAMES, `.perf-baseline.json` key, `hook-chain-latency/01-baseline-exists.sh` → `secrets-preflight.sh`.
- [ ] 9. `.claude/tests/harness-sync/13,14,15` → gitignore entry `.claude/secrets-audit.jsonl` → `.agent0/secrets-audit.jsonl`.
- [ ] 10. `.claude/rules/secrets-scan.md` → paths frontmatter + body (path/name, runtime-branched output, guardrail wording, dropped skip-not-commit, Codex activation).
- [ ] 11. Doc index: `CLAUDE.md`, `AGENTS.md`, `README.md` path refs.
- [ ] 12. Comment-only path refs in sibling hooks (`supply-chain-scan.sh`, `runtime-capture.sh`, `governance-gate.sh`, `session-start.sh`).
- [ ] 13. Memory refresh: 6 entries with stale `secrets-scan.sh`/audit-path references.

## Verification (acceptance)

- [ ] V1. `bash .claude/tests/secrets-scan/run-all.sh` → all 7 PASS (Claude block + override rewrite end-to-end).
- [ ] V2. New shape-test: synthetic Codex payload (no `CLAUDE_PROJECT_DIR`, with `cwd`) + override → emitted JSON has `permissionDecision:"allow"`; Claude payload → no `permissionDecision`.
- [ ] V3. New: non-commit Bash payload → exit 0, no audit row written.
- [ ] V4. New: subdirectory-cwd payload → audit log lands at repo root, not the subdir.
- [ ] V5. `bash .claude/tests/hook-chain-latency/01-baseline-exists.sh` → PASS post-rename.
- [ ] V6. `grep -rn '.claude/hooks/secrets-scan.sh\|.claude/secrets-audit.jsonl'` → clean (no stale refs outside docs/specs history).
- [ ] V7. `bash .claude/tests/harness-sync/run-all.sh` (or the 13/14/15 trio) → PASS.
- [ ] V8. Flag the Codex live dogfood (config edit + restart + real commit/rewrite) as a human handoff item.
