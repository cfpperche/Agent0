# 169 - post-launch-maintenance-loop - tasks

_Generated from `plan.md` on 2026-06-08. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. Create `.agent0/context/rules/post-launch-maintenance-loop.md` with provider-neutral roles, v1 posture, trust boundaries, no-auto-merge/operation constraints, and feedback-sink routing.
- [x] 2. Create `.agent0/context/templates/post-launch-maintenance-loop/provider-map.md` with fillable sections for signal source, work hub, agent delegate, repo permission boundary, review gate, feedback sink, credential classes, data classes, filters, rate limits, and dry-run mode.
- [x] 3. Create `.agent0/context/templates/post-launch-maintenance-loop/agent-issue-template.md` with separate trusted-instructions and untrusted-incident-payload sections plus an adversarial payload example.
- [x] 4. Create `.agent0/context/templates/post-launch-maintenance-loop/review-checklist.md` covering human review, validation evidence, dependency-install scrutiny, prompt-injection review, data minimization, and follow-up routing.
- [x] 5. Create `.agent0/context/templates/post-launch-maintenance-loop/examples/sentry-linear-codex.md` as an example-only recipe with current citations, placeholders only, dry-run first, and clear "not required architecture" language.
- [x] 6. Add a narrow `/product` pointer in `.claude/skills/product/SKILL.md` terminal handoff guidance without making the loop a product phase.
- [x] 7. Update `.claude/skills/product/references/pipeline-coverage.md` to preserve post-launch maintenance as sibling infrastructure and link the new rule.
- [x] 8. Add a concise cross-reference in `.agent0/context/rules/agent0-governance-doctrine.md` that spec 169 is a narrow instrument-only slice, not the full `continuous-evolution-spine` follow-up.
- [x] 9. Add focused tests under `.agent0/tests/post-launch-maintenance-loop/` for required sections, provider-neutrality, isolated vendor recipe, placeholder-only examples, and no configured credentials/IDs.

## Verification

- [x] 10. Run `bash .agent0/tests/post-launch-maintenance-loop/run-all.sh`.
- [x] 11. Run `rg -n "SENTRY_DSN=|auth_token|lin_[A-Za-z0-9]|ghp_|sk-[A-Za-z0-9]|xox[baprs]-|team_[A-Za-z0-9]|Linear team ID|github.com/.+/.+" .agent0/context/rules/post-launch-maintenance-loop.md .agent0/context/templates/post-launch-maintenance-loop .claude/skills/product/SKILL.md .claude/skills/product/references/pipeline-coverage.md` and confirm there are no configured credentials or concrete consumer IDs.
- [x] 12. Run `bash .agent0/tools/sync-harness.sh --agent0-path="$PWD" --apply --dry-run "$(mktemp -d)"` or an equivalent temporary-consumer dry run to confirm the new `.agent0/context/**` files are in the propagated surface.
- [x] 13. Run `git diff --check`.
- [x] 14. Re-read `docs/specs/169-post-launch-maintenance-loop/spec.md` acceptance criteria and confirm every criterion is satisfied or explicitly deferred in notes.

## Notes

- Do not run or configure real Sentry, Linear, GitHub, Codex, Claude, Cursor, or Devin integrations for this spec.
- Do not add a skill, hook, validator, daemon, scheduler, provider API client, or sync manifest root unless `plan.md` is updated first.
