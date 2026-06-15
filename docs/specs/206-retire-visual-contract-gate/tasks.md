# 206 — retire-visual-contract-gate — tasks

_Generated from `plan.md` on 2026-06-14. Work top-to-bottom._

**Verify:** `bash .agent0/tests/ui-acceptance/run-all.sh`

## Implementation

### Behavioral core
- [x] 1. Create `.agent0/tools/ui-runner-detect.sh` (declarable signals + `.agent0/ui-test.json` override; exit 0/1; `--json`).
- [x] 2. Reword `.agent0/tools/ui-impact-detect.sh` header (drop spec-155/visual-contract framing; now feeds the runner advisory). Logic unchanged.
- [x] 3. Rewrite the validator advisory block in `.agent0/validators/run.sh`: `visual-contract-advisory:` → `ui-runner-advisory:` (fires iff UI surface changed AND no runner detected; never for backend/docs/tests).
- [x] 4. Strip `visual_contract_*` functions + the `report.json .overall==pass` check from `.agent0/hooks/delegation-verify.sh`.
- [x] 5. Delete `verify_contract()` + the `verify-contract` dispatch + usage/help line from `.agent0/tools/agent-browser.sh`.

### Canonical rule + entrypoints
- [x] 6. Create `.agent0/context/rules/ui-acceptance.md`; delete `.agent0/context/rules/visual-contract.md`.
- [x] 7. Re-frame `.agent0/context/rules/browser-primitive.md` (drop `verify-contract` line + visual-contract framing).
- [x] 8. Update `CLAUDE.md` + `AGENTS.md` managed index block ("Visual contract acceptance" → "UI acceptance").

### Doc/reference repoints
- [x] 9. `.agent0/context/rules/delegation.md` — UI brief `DONE_WHEN` = green UI-test command.
- [x] 10. `.agent0/context/rules/spec-driven.md` + `.agent0/skills/sdd/templates/spec.md.tmpl` — `UI impact` tiers → `none | ui`; repoint to `ui-acceptance.md`.
- [x] 11. frontend-designer (SKILL.md, done-proof.md, frontend-designer.sh, templates, imagery.md) — done-proof = green project UI test; preserve native/motion honesty paths.
- [x] 12. `/product` references — design-time contract is test-writing input, never implementation proof.
- [x] 13. `post-launch-maintenance-loop.md` + its review-checklist template — bundle → green UI test.

### Closure + memory
- [x] 14. Rewrite tests → `.agent0/tests/ui-acceptance/` (detect, advisory fire/no-fire, gaming cases); delete `.agent0/tests/visual-contract/` + `.agent0/tests/agent-browser/10-dogfood-visual.sh`.
- [x] 15. Mark spec 155 `superseded by 206-retire-visual-contract-gate`; confirm 157 abandoned (no change needed).
- [x] 16. Update `.agent0/memory/*` visual-contract doctrine entries; `memory-maintain.sh finalize`.

## Verification

_Acceptance checks tied to `spec.md`._

- [x] `bash .agent0/tests/ui-acceptance/run-all.sh` passes (advisory fire/no-fire + 5 gaming cases).
- [x] No live harness references to `verify-contract`/visual-contract gate remain (excluding `.runtime-state`, `meetings`, `docs/specs`, `memory` history).
- [x] `bash .agent0/validators/run.sh` exits ok; UI-surface-change-no-runner fires `ui-runner-advisory:`, backend-only change does not.
- [x] No template placeholders left in spec/plan/tasks; spec.md open questions all resolved (in plan.md § Decisions).

## Notes
