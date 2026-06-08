# 171 - context-injection-reformulation - tasks

_Generated from `plan.md` on 2026-06-08. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. Capture Claude critique for the draft spec and record the result in `notes.md`.
- [x] 2. Decide implementation shape for v1: extend `.agent0/hooks/context-inject.sh`, do not create a new router unless implementation proves separation is necessary.
- [ ] 3. Add `.agent0/context/rules/context-injection-reformulation.md` with the event matrix, runtime guarantees, read-before-acting guidance, and coverage labels.
- [ ] 4. Implement prompt-time URL/article/gated-host routing, preserving existing prompt behavior.
- [ ] 5. Implement the smallest hookable post-tool router slice for auth-wall signals, preserving honest unsupported-path reporting.
- [ ] 6. Register post-tool routing in `.codex/hooks.json` and `.claude/settings.json` only for supported/mapped tool events.
- [ ] 7. Add deterministic fixtures under `.agent0/tests/context-routing/`.
- [ ] 8. Update browser/delegation/runtime-capability rules with cross-references and explicit limitations.
- [ ] 9. Refresh `.agent0/HANDOFF.md` with shipped or in-flight status.

## Verification

- [ ] Fixture: prompt without browser/auth keywords does not falsely claim browser routing is complete.
- [ ] Fixture: URL/article/X prompt selects browser primitive/auth context before any fetch result exists.
- [ ] Fixture: supported post-tool auth-wall output emits browser primitive/auth context.
- [ ] Fixture: unsupported/non-hookable web surfaces produce an honest limitation marker, not a PASS.
- [ ] Fixture/report: motivating incident path is labelled covered/uncovered/rule-only per `(runtime, tool)`.
- [ ] Fixture: subagent start/stop context behavior is documented separately for Claude and Codex.
- [ ] Regression: `bash .agent0/tests/context-injection/run-all.sh`.
- [ ] Regression: `bash .agent0/tests/context-retrieval/run-all.sh`.
- [ ] New suite: `bash .agent0/tests/context-routing/run-all.sh`.
- [ ] Static check: `git diff --check`.

## Notes

- Claude critique has been incorporated. Implementation remains pending review of the draft spec and the live web-fetch observability question.
