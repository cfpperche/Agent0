# 184 — codex-exec-run-bounds — plan

_Generated from `spec.md` on 2026-06-09._

## Approach

Port the proven run-bound mechanics from `claude-exec` into `codex-exec` while keeping Codex-specific behavior intact. The helper should still build argv arrays for `.agent0/tools/codex-local-env.sh ... codex exec`, write prompts through stdin, capture `stdout.txt` or `events.jsonl`, and rely on Codex's `--output-last-message` for `last-message.md`.

The implementation adds two caller-facing controls:

- `--timeout <seconds>` with default `600`, validated as a positive integer.
- `--progress-interval <seconds>` with default `30`, validated as a non-negative integer, where `0` disables heartbeats.

The helper records `timeout_seconds`, `progress_interval_seconds`, `timed_out`, and `elapsed_seconds` in both per-run metadata and the aggregate run log. Timeout status remains the standard GNU `timeout` status `124`.

## Design Notes

- Use the platform `timeout` command instead of hand-written process killing. It is already used by `claude-exec` and gives a clear timeout exit code.
- Preserve all existing output files even when the child exits non-zero or times out.
- Emit progress to helper stderr only; do not mix heartbeat lines into Codex stdout artifacts.
- Keep `--timeout 0` invalid. The bridge is documented as bounded, and an unbounded escape hatch would recreate the failure class.
- Do not add budget flags. Current `codex exec` help does not expose a native spend guard, so docs should be explicit that scoped prompts and timeout are the available controls.

## Validation

Run:

```bash
bash .agent0/tests/codex-exec-skill/run-all.sh
bash -n .agent0/skills/codex-exec/scripts/codex-exec.sh
bash .agent0/skills/skill/scripts/validate.sh .agent0/skills/codex-exec
bash .agent0/skills/skill/scripts/check-rubric.sh .agent0/skills/codex-exec
bash .agent0/tools/spec-verify.sh docs/specs/184-codex-exec-run-bounds
bash .agent0/tools/sdd-close.sh docs/specs/184-codex-exec-run-bounds --json
```

If local Codex auth is usable, also run one tiny live smoke with explicit `--timeout` and `--progress-interval`, using a prompt that does not inspect files or run tools.

## Rollout

No consumer sync in this spec. These changes land in Agent0 only and propagate later through the normal explicit `sync-harness` workflow if requested.
