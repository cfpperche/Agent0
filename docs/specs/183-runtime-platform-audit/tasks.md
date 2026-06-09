# 183 — runtime-platform-audit — tasks

_Generated from `plan.md` on 2026-06-09. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

**Verify:** `bash .agent0/skills/routine/scripts/validate.sh runtime-platform-audit`

## Implementation

- [x] 1. Create `.agent0/routines/runtime-platform-audit.md` — generalized prompt with an audit-unit table (Claude hooks → cc-platform-hooks.md; Codex hooks → codex-cli-hooks.md; agentskills.io → spec-snapshot.md), a matrix cell-value audit step, the agentskills.io-not-CC discipline note, unreachable-continue clause, and the leave-diff-uncommitted contract. `29-event` reference corrected to count-agnostic / `30`.
- [x] 2. Delete `.agent0/routines/cc-platform-audit.md` (superseded; git history preserves).
- [x] 3. Re-run `.agent0/tools/install-routines.sh` to regenerate the crontab block (drops cc-platform-audit, registers runtime-platform-audit).

## Verification

- [x] 4. `bash .agent0/skills/routine/scripts/validate.sh runtime-platform-audit` → OK; `routine list` shows only the new routine, leader=yes.
- [x] 5. Crontab block points at `runtime-platform-audit` (confirmed via `crontab -l`).
- [x] 6. `bash .agent0/tools/doctor.sh` 0 broken; `check-instruction-drift.sh` anchors pass after the matrix edit.
- [x] 7. Dry-run of the new surface: Codex hooks audited (10/10 events match upstream, no drift); matrix `~29 events`→`~30 events` cell-drift caught and fixed — proving the cell-value audit works.

## Notes

- **Follow-up — FULLY RESOLVED (empirically confirmed 2026-06-09).** The Codex `apply_patch` matcher-aliasing claim was first verified by two independent primary-source reads, then **empirically confirmed** via a human-driven interactive Codex session: a TEMP `^Edit$` PreToolUse hook in the already-trusted `.codex/hooks.json` **fired** on an `apply_patch` edit, payload `tool_name: "apply_patch"`, `/hooks` showed the matcher Active. TEMP hook reverted (no diff). `codex-cli-hooks.md` § tool-name surface updated to CONFIRMED. Bonus finding recorded there: `codex exec` (headless) does NOT fire lifecycle hooks — validate Codex hooks interactively only. (Process lesson captured in user memory: guide the human for interactive-runtime checks instead of headless brute-forcing.)
- Dry-run did not re-fetch Claude hooks/skills (audited earlier today via the final cc-platform-audit run; no further drift).
