# 125 — hook-context-visual-polish — tasks

_Generated from `plan.md` on 2026-05-30. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. `startup-brief.sh` — change `summarize_handoff_section()` header line `- $heading:` → `▸ $heading:`.
- [x] 2. `context-inject.sh` — change `append_capsule()` separator `\n---\n` → `\n▸ ---\n` in both the normal branch and the byte-cap `omitted` branch.
- [x] 3. Add `.agent0/tests/context-injection/12-flatten-safe-markers.sh` asserting: `▸ ` sub-section markers present in the startup brief handoff block; `▸ ---` present in a capsule block; and all pinned substrings (`=== handoff ===`, `^source:`, `mode: prompt-capsules`) still co-exist.

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria. Each maps to a checklist item there._

- [x] 4. Run `.agent0/tests/context-injection/run-all.sh` — existing suite passes **unchanged** + new test 12 green (spec scenarios 1, 2, 3). → 12/12 PASS.
- [x] 5. Run `.agent0/tests/session-handoff/run-all.sh` and `.agent0/tests/session-handoff-multi-runtime/run-all.sh` — no regression. → both suites All PASS.
- [x] 6. Codex regression probe: `startup-brief.sh` under codex-cli runtime → raw stdout, no JSON envelope, `▸ Current State:` present. PASS.
- [x] 7. Model-visible contract intact: CC JSON envelope parses (`jq`), `additionalContext` carries `=== handoff ===` + `▸ Current State:` + `=== context ===` + `END_AGENT0_STARTUP_BRIEF`. PASS.
- [ ] 8. **Manual gate (human):** run the live-dogfood prompts below (CC + Codex sections) in a fresh session and capture the scenario-5a/5b artifacts. Left for the human — not auto-checkable.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._

- Tasks 1–2 are one-line glyph additions; the bulk of the risk is in not regressing pinned test strings (task 4) and the manual dogfood gate (task 8).
