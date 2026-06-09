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

- **Follow-up — RESOLVED at doc level (commit `eb1f43e`, 2026-06-09).** The Codex `apply_patch` matcher-aliasing claim was verified by **two independent primary-source reads** (WebFetch + Codex self-probe via codex-exec), both quoting the same doc text: an `Edit`/`Write` *matcher* fires on apply_patch, but the payload still reports `tool_name: "apply_patch"` (and `MultiEdit` is not an alias). `codex-cli-hooks.md` § tool-name surface was corrected accordingly. **Residual (optional):** a live `/hooks` matcher test would confirm the doc-stated behavior empirically — not run here because it would require touching the tracked `.codex/hooks.json` while a parallel Codex session is active.
- Dry-run did not re-fetch Claude hooks/skills (audited earlier today via the final cc-platform-audit run; no further drift).
