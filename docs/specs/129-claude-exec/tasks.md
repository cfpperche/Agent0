# 129 — claude-exec — tasks

_Generated from `plan.md` on 2026-05-30. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. Create skill dir `.agent0/skills/claude-exec/{scripts,agents}/`.
- [x] 2. Write `scripts/claude-exec.sh` — arg parser (shared flags + Claude-idiomatic flags), `set -euo pipefail`, argv arrays, `die()`; prompt sources `--task`/`--task-file`/stdin/`--`.
- [x] 3. In the helper: require `--permission-mode` (fail-closed, no default) and validate it against the native set; reject unknown flags.
- [x] 4. In the helper: dependency checks (`claude` on PATH, `jq` on PATH) before any run dir is created.
- [x] 5. In the helper: run-dir/slug/timestamp + `--output` `realpath -m` containment guard (inherit spec-128 hardened behavior); `--add-dir` repo-root containment guard.
- [x] 6. In the helper: build `claude -p` argv (permission-mode, allowlists, model, add-dir, bare, resume); `--output-format json` default vs `stream-json --verbose` when `--json`.
- [x] 7. In the helper: capture stdout/stderr/exit; extract `last-message.md` + `session_id` via `jq` (result object / final result event); write `metadata.json` + append `runs.jsonl`; print summary; exit child code.
- [x] 8. `chmod +x scripts/claude-exec.sh`; `bash -n` clean.
- [x] 9. Write `SKILL.md` with agentskills.io frontmatter (name, description precise per implicit-invocation, argument-hint, compatibility, portability tier) + bridge docs framing it as subprocess orchestration, not native delegation.
- [x] 10. Write `agents/openai.yaml` with `policy.allow_implicit_invocation: true` + interface block.
- [x] 11. Create discovery symlinks `.claude/skills/claude-exec` and `.agents/skills/claude-exec` → `../../.agent0/skills/claude-exec`.
- [x] 12. Write test harness `_lib.sh` (stub `claude` + `jq` on a temp PATH, `CLAUDE_EXEC_STATE_DIR` to a temp dir) + 4 tests (required-permission-mode, parameter-mapping, resume, missing-dependency) + `run-all.sh`.

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria._

- [x] 13. `bash .agent0/tests/claude-exec-skill/run-all.sh` — all scenarios pass (maps to acceptance: fail-closed permission, parameter mapping, resume, missing-dependency, `--output` guard).
- [x] 14. `bash .agent0/skills/skill/scripts/validate.sh .agent0/skills/claude-exec` and `check-rubric.sh` pass (maps to "skill validation and discovery pass").
- [x] 15. Symlinks resolve to the one canonical source; `.gitignore` covers run outputs (maps to discovery + auditable/gitignored).
- [x] 16. Live smoke: real `claude -p` read-only probe returns a substantive answer, `exit_code=0`, `last-message.md` non-empty, `session_id` captured (maps to read-only probe + JSON extraction). Pin the `jq` filter to the observed `stream-json` shape.
- [x] 17. Emit the Codex-side dogfood prompt (the goal deliverable): a ready-to-paste `/codex-exec` invocation that has Codex drive `claude-exec` to validate the bridge end-to-end.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._

- The `stream-json` final-event shape must be confirmed against the live `claude` version (task 16) before the `jq` filter in task 7 is considered final.
