# 139 — status-doctor-reconciliation — tasks

_Generated from `plan.md` on 2026-06-02. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### B — doctor jq wiring validation (lower risk, first)
- [x] 1. Replace `wired_check` in `.agent0/tools/doctor.sh` with jq contract validation: read `.hooks.SessionStart[].hooks[].command` from the config; require a command referencing `startup-brief.sh` AND `$PROJECT_DIR/.agent0/hooks/startup-brief.sh` present+executable. Config absent → `advisory`; present-but-unwired → `broken`; bound+valid → `ok`. `jq` absent → degrade to substring as `advisory`, never crash.
- [x] 2. Verify the real repo still rolls up `OK` exit 0 (both runtimes are correctly wired here).

### A — status reconciliation + in-flight inference
- [x] 3. Add `reconcile_block()` to `.agent0/tools/status.sh`, emitted right after the `AGENT0_STATUS` header. Fire a `⚠ RESUME WARNING …` banner only when `git status --porcelain` is non-empty AND the handoff Active Work / Current State matches a clean/idle signal (`none` / `working tree clean` / `nothing in flight`, case-insensitive). Count the dirty paths in the message. Stays exit 0.
- [x] 4. Add probable-in-flight inference: from `git status --porcelain`, extract distinct `docs/specs/NNN-<slug>/` roots; emit `probable active work: NNN-<slug>` line(s). Place in `reconcile_block` (or just below it). Empty when no spec paths are dirty.

### Tests + docs
- [x] 5. Extend `.agent0/tests/agent0-status/test.sh`: V10 banner fires on contradiction fixture; V11 no banner when clean OR when handoff already names the work; V12 in-flight hint derived from a dirty `docs/specs/NNN-*` fixture; V13 doctor jq-wiring → `broken` on a present-but-unwired config fixture, `ok` on the real repo. Keep V1–V9 green.
- [x] 6. Update `.agent0/context/rules/agent0-status.md` if the reconciliation/wiring behavior changes the capability contract description (keep anti-drift scope intact).

## Verification

- [x] V-A. `bash .agent0/tools/status.sh` on this repo (handoff likely says "nothing actionable" while tree is dirty) shows the RESUME WARNING + probable-in-flight line (maps to spec Scenarios 1 & 3).
- [x] V-B. Fixture with clean tree OR handoff-names-work → no banner (maps to Scenario 2, no false alarm).
- [x] V-C. `bash .agent0/tools/doctor.sh` on a present-but-unwired `.claude/settings.json` fixture → `broken`, exit 1 (maps to Scenarios "validates contract" + "can fail on unwired").
- [x] V-D. Real repo doctor still `OK` exit 0; jq-absent path degrades to advisory without crashing.
- [x] V-E. Full suite green (V1–V13); `startup-brief.sh` still byte-identical (status.sh edits must not touch the shared lib's emit path).

## Notes

_Populated during execution._
