# 180 — debate-tier-source-of-truth — tasks

_Generated from `plan.md` on 2026-06-09. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

**Verify:** `bash .agent0/tools/doctor.sh`

## Implementation

- [x] 1. Edit `.agent0/context/rules/spec-driven.md` line 42: SDD owns the policy ("a `/sdd debate`, when run, is always decision-grade"); reference `meeting.md` § De-biased deliberation for the *mechanics* (don't restate); add the degraded-mode clause — position-first only after an attempted `meeting.sh` *actually fails*, emits `debate-degraded:`, and a degraded debate cannot be cited as the decision-grade convergence gate (`/squad`).
- [x] 2. Edit `.agent0/context/rules/meeting.md` line 87: state this rule defines "the mechanics of the decision-grade tier"; point the *mandate* that `/sdd debate` always uses that tier to `spec-driven.md` § debate; do NOT assert the SDD mandate here. Keep `light` tier as meeting-only.
- [x] 3. Edit `.claude/skills/sdd/SKILL.md` Step 4 (heading + body + the anti-confirmation-bias paragraph, ≈159-170): blind commit/reveal is the **required** Round 1 for a normal debate (not "preferred"); position-first demoted to a degraded fallback gated on attempted-and-failed `meeting.sh`; on fallback emit `debate-degraded: <reason>` and mark synthesis not full-confidence; defer the policy to `spec-driven.md`. Keep the text runtime-neutral (symlink-shared).

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria._

- [x] 4. `grep` the three files: `spec-driven.md` is the only place asserting the *policy*; `meeting.md` defers the mandate; `SKILL.md` says "required" not "preferred" and has no discretionary "when the blind flow isn't run" phrasing — maps to acceptance scenarios 1-3 + the no-shared-surface-contradiction criterion.
- [x] 5. `grep` confirms no `--tier light` (or equivalent) was introduced for `/sdd debate`; `light` stays meeting-only — maps to "no new lighter SDD tier".
- [x] 6. `bash .agent0/tools/doctor.sh` reports 0 broken — maps to the doctor acceptance criterion.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._

- The spec itself was refined by a dogfooded decision-grade `/sdd debate` (see `debate.md`) — the mechanism this spec hardens proved itself: blind commit/reveal + ledger gate (4/4 supported) + preserved minority report.
- Post-ship (not acceptance): sync to the 3 active consumers as harness-only; `SKILL.md` is symlink-shared so consumers inherit the skill edit automatically, but the two rules propagate via sync-harness.
