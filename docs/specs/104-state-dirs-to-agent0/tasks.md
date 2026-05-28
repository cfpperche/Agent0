# 104 — state-dirs-to-agent0 — tasks

_Generated from `plan.md` on 2026-05-28. Work top-to-bottom._

## Implementation

- [x] 1. Rewrite the 3 `.gitignore` entries (`.runtime-state/*` + `!README.md`, `.session-state/`, `.browser-state/*.json`) from `.claude/` to `.agent0/`.
- [x] 2. `git mv .claude/.runtime-state/README.md .agent0/.runtime-state/README.md` and `git mv .claude/.browser-state/.gitkeep .agent0/.browser-state/.gitkeep`; confirm old dirs hold no tracked files.
- [x] 3. Update `sync-harness.sh` `COPY_CHECK_FILES` (2 entries) + project-local comment block to `.agent0/` paths.
- [x] 4. Update session hooks: `SESSION_STATE_ROOT` in `session-start.sh` / `session-stop.sh` / `session-track-edits.sh` (+ docstring in the latter).
- [x] 5. Update `probe.sh` `STATE_FILE` + `SESSION_STATE_DIR` + docstring path comments (leave the `bash .claude/tools/probe.sh` self-references — row 6).
- [x] 6. Update `runtime-capture.sh` `STATE_DIR`, `runtime-pre-mark.sh` `IN_FLIGHT_DIR`, `bench-hooks.sh` mkdir (+ docstrings).
- [x] 7. Update the moved `README.md` body self-references.
- [x] 8. Update rules + portability-tiers + memory references (`.claude/rules/{session-handoff,harness-sync,browser-auth,runtime-introspect,runtime-capabilities,secrets-scan,memory-placement}.md`, `portability-tiers.md`, `runtime-introspect-maintenance.md`).
- [x] 9. Update `CLAUDE.md` + `AGENTS.md` identically (managed-block byte-equality).
- [x] 10. Update test fixtures: sed session-state suites + runtime suites; hand-verify the ~4 harness-sync tests.

## Verification

- [x] 11. Run suites green: `session-state-isolation`, `session-edit-attribution`, `session-handoff`, `session-handoff-multi-runtime`, `runtime-introspect`, `runtime-capture-php`, `harness-sync`, `instruction-drift`.
- [x] 12. `grep -r '\.claude/\.\(session\|runtime\|browser\)-state'` across shipped surface returns only intentional historical mentions (specs); `git diff --check` clean.
- [x] 13. `sync-harness.sh --apply --dry-run` against a scratch consumer shows the `.agent0/.*-state/` manifest + gitignore additions.
- [x] 14. Flip umbrella 102 § Gap matrix rows 3/4/5 status to `shipped`; append notes.md decision entry; update HANDOFF.

## Notes

_Populated during execution._
