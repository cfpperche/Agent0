# 154 — squad-hardening — tasks

_Generated from `plan.md` on 2026-06-05. Work top-to-bottom._

## Implementation

### Fix #1 — anchored secrets pattern
- [ ] 1. `squad.json.example`: replace `"secrets"` with `"(^|/)secrets?/"` + `"\\.secrets?(\\.[^/]+)?$"` in `forbidden_paths`.
- [ ] 2. Test `NN-secrets-pattern.sh`: the example's patterns DON'T match `secrets-scan.md`; DO match `secrets/foo.json` + `app.secrets`.

### Fix #2 — bridges suppress the handoff Stop-nag
- [ ] 3. `codex-exec.sh`: export `CLAUDE_SKIP_SESSION_HOOKS=1` into the `codex exec` child env.
- [ ] 4. `claude-exec.sh`: export `CLAUDE_SKIP_SESSION_HOOKS=1` into the `claude` child env.
- [ ] 5. Test `NN-bridge-suppresses-handoff-nag.sh`: (a) grep both bridges export the var; (b) behavioral — `CLAUDE_SKIP_SESSION_HOOKS=1 session-stop.sh` against a dirty tree + stale handoff exits 0 with no `block`.

### Fix #3 — non-destructive resume
- [ ] 6. `squad.sh`: add `cmd_resume()` — re-baseline `boundary` to current `_fingerprint`, set `status=running` / `turn_open=false`; refuse (unless `--force`) if the current changed-set hits a `forbidden_paths` pattern. Add the `resume)` dispatch case + usage string.
- [ ] 7. Test `NN-resume-recovers.sh`: aborted run + benign change → `resume` → running + tree intact + guard clean; genuine forbidden change → `resume` refuses w/o `--force`, succeeds with `--force`.

### Docs
- [ ] 8. `squad-contract.md`: document anchored-`secrets` guidance + `resume` (recovery) vs `rollback` (destructive).
- [ ] 9. `rules/squad.md`: note bridge-suppresses-handoff-nag + `resume`.

## Verification
- [ ] 10. New squad tests pass (`bash .agent0/tests/squad/run-all.sh` or per-file); existing suites stay green (`agent-browser`, `harness-sync`).
- [ ] 11. Spec acceptance walk: every `spec.md` AC box ticked; `notes.md` records any deviation.
