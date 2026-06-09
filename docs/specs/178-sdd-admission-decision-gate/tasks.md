# 178 — sdd-admission-decision-gate — tasks

_Generated from `plan.md` on 2026-06-08. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. Rewrite `spec-driven.md` § *When SDD applies*: remove the "Touches 3+ files" trigger; install the 5-question test (questions 2 and 4 carry the inline high-cost surfaces) + the boundary-crossing example sentence.
- [x] 2. Rewrite `spec-driven.md` § *When to skip*: make wide-but-trivial cases explicit (mechanical multi-file rename; obvious-cause bugfix with test/doc churn; small UI tweak), add the "skipping never waives proof" clause naming the three recipients, and replace the "when in doubt, write a spec" closer with the five-questions version.
- [x] 3. Reword `visual-contract.md` opening framing sentence (line 3): UI-proof obligation is independent of a spec/task; name the non-spec recipient (PR body / `report.json` / handoff). Mechanism (detector/advisory) untouched.

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria. Each one should map to a checklist item there._

- [x] No file-count trigger remains in § *When SDD applies*; breadth appears only as boundary-crossing evidence (acceptance scenarios 1 + bullet 5).
- [x] § *When to skip* lists mechanical multi-file renames and obvious-cause bugfixes as skip cases (acceptance bullet 6).
- [x] `visual-contract.md` states UI proof is owed with or without a spec and names the recipient (acceptance scenario 4 + bullet 7).
- [x] The gate stays tight — questions-primary, no enumerated surface catalog (acceptance bullet 8).
- [x] Human read-through: apply the revised gate to the 4 acceptance scenarios → each yields the correct skip/spec verdict.
- [x] `bash .agent0/tools/doctor.sh` stays green (no mechanism touched).

**Verify:** `bash .agent0/tools/doctor.sh`

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._
