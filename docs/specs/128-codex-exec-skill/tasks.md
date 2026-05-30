# 128 — codex-exec-skill — tasks

_Generated from `plan.md` on 2026-05-30. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. Scaffold `.agent0/skills/codex-exec/` with `SKILL.md`, `scripts/`, and `agents/`; create `.claude/skills/codex-exec` and `.agents/skills/codex-exec` relative symlinks to the canonical skill.
- [x] 2. Write `scripts/codex-exec.sh` with strict argument parsing, dependency preflight, repo-root resolution, `--cwd` validation, default `--sandbox read-only`, prompt capture, `codex exec` / `codex exec resume` argv construction, output capture, metadata writing, and same-exit-code propagation.
- [x] 3. Write `SKILL.md` so the invoking agent understands when to use the bridge, how to pass parameters, what defaults apply, and when not to use it.
- [x] 4. Write `agents/openai.yaml` with human-facing metadata and `policy.allow_implicit_invocation: true`.
- [x] 5. Add `.agent0/tests/codex-exec-skill/` coverage using fake `codex` binaries for default read-only behavior, parameter mapping, resume behavior, and missing dependency failure.
- [x] 6. Record any plan/spec deviations in `notes.md`.

## Verification

- [x] 7. Run `bash .agent0/tests/codex-exec-skill/run-all.sh`.
- [x] 8. Run `bash .agent0/skills/skill/scripts/validate.sh .agent0/skills/codex-exec`.
- [x] 9. Verify discovery symlinks resolve to `.agent0/skills/codex-exec`.
- [x] 10. Run a lightweight real `codex-exec` probe only if local Codex auth permits it without requiring interactive approval; otherwise document that live dogfood is deferred to Claude with the final prompt.
- [x] 11. Update `spec.md` acceptance checkboxes and status based on evidence.
- [x] 12. Emit a copy-pasteable Claude dogfood prompt that asks Claude to invoke `/codex-exec`, inspect the artifacts, and report whether the bridge behaves as specified.

## Notes

- Keep the unrelated untracked `docs/specs/091-sdd-debate-runner/` directory untouched.
