# 169 - post-launch-maintenance-loop - plan

_Drafted from `spec.md` on 2026-06-08. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Ship the smallest surface that satisfies the revised spec: one provider-neutral context rule plus copyable templates under `.agent0/context/templates/post-launch-maintenance-loop/`. This keeps the loop available to both `/product`-originated projects and existing Agent0 consumers, while avoiding a new skill, daemon, hook, validator, or sync manifest change. `.agent0/context/**` already propagates through `sync-harness.sh`, so placing templates there avoids expanding the shipped-file manifest just to carry docs.

The context rule will explain the lifecycle posture and trust boundary: signal source -> work hub -> agent delegate -> review gate -> feedback sink. It will explicitly frame Sentry -> Linear -> Codex as an example recipe, not the architecture. The templates will be practical, copyable Markdown artifacts a consumer can fill in their own repo: provider mapping, issue/agent prompt boundary, review checklist, and a Sentry/Linear/Codex fixture. `/product` will only point to this optional loop from the terminal handoff and relevant reference docs; it will not run or install anything.

## Files to touch

**Create:**

- `.agent0/context/rules/post-launch-maintenance-loop.md` - provider-neutral rule for when and how Agent0 agents should advise on post-launch maintenance loops.
- `.agent0/context/templates/post-launch-maintenance-loop/provider-map.md` - consumer-filled map of signal source, work hub, agent delegate, repo boundary, review gate, feedback sink, token classes, and data classes.
- `.agent0/context/templates/post-launch-maintenance-loop/agent-issue-template.md` - copyable work item / agent prompt template that separates trusted instructions from untrusted incident payload.
- `.agent0/context/templates/post-launch-maintenance-loop/review-checklist.md` - human review gate checklist for agent-produced fixes.
- `.agent0/context/templates/post-launch-maintenance-loop/examples/sentry-linear-codex.md` - concrete example recipe and dry-run fixture for the motivating workflow, with placeholders only.
- `.agent0/tests/post-launch-maintenance-loop/01-surface-and-placeholders.sh` - verifies required files/sections exist and no template contains configured secrets or concrete consumer IDs.
- `.agent0/tests/post-launch-maintenance-loop/02-provider-neutrality.sh` - verifies provider-neutral files are usable without Sentry, Linear, or Codex lock-in and the concrete vendor recipe is isolated to the example.
- `.agent0/tests/post-launch-maintenance-loop/run-all.sh` - runs the focused acceptance checks.

**Modify:**

- `.claude/skills/product/SKILL.md` - add a short optional post-launch maintenance pointer in the terminal handoff area, without making it a phase or runtime step.
- `.claude/skills/product/references/pipeline-coverage.md` - clarify that post-launch review/maintenance remains sibling infrastructure and link to the new rule.
- `.agent0/context/rules/agent0-governance-doctrine.md` - add a cross-reference note that this spec is a narrow instrument-only slice, not the full `continuous-evolution-spine` follow-up.
- `docs/specs/169-post-launch-maintenance-loop/tasks.md` - generate concrete task checklist after plan review.
- `docs/specs/169-post-launch-maintenance-loop/notes.md` - append implementation decisions if the plan shifts.

**Delete:**

- None.

## Alternatives considered

### New `/maintenance-loop` or `/post-launch` portable skill

Rejected for v1 because the evidence is only founder directive plus one external pattern, not rule-of-three demand or dogfood failure. A skill would add a discovery surface, compliance burden, runtime invocation semantics, and likely a consumer support expectation. The revised spec intentionally caps v1 at rule+templates and records a future-skill trigger.

### Provider-specific integration tool or webhook receiver

Rejected because it crosses the product-drift boundary. Agent0 should not own production telemetry ingestion, webhook auth, issue creation, agent assignment, incident closure, or release authority. Provider-specific automation belongs in the consumer's chosen stack.

### New top-level `.agent0/templates/` sync surface

Rejected for v1 because `.agent0/context/**` already propagates and this loop is context/rule-adjacent guidance. A new sync root would require manifest changes and tests before we know the pattern needs broad template taxonomy support.

### Only mention the loop in `/product`

Rejected because the user explicitly wants projects that did not originate from `/product` to adopt the workflow. The standalone rule+templates are the primary surface; `/product` only links to them.

## Risks and unknowns

- **Prompt-capsule bloat:** a long rule could increase context noise. Mitigation: keep the rule concise and put long copyable material in templates.
- **Provider docs drift:** Sentry/Linear/Codex/GitHub details change. Mitigation: isolate vendor-specific instructions to the example template and cite current docs there; decide during implementation whether a reminder/routine is justified.
- **False sense of security:** templates can encourage automation even though v1 is advisory. Mitigation: dry-run/manual-intake language and no-auto-merge/no-auto-delegation statements appear in rule and checklist.
- **Credential examples:** realistic examples may trip secrets scans or teach unsafe patterns. Mitigation: use obvious placeholders, never real-looking DSNs/tokens/team IDs, and test for suspicious patterns.
- **`/product` overreach:** adding the pointer in the wrong place could imply `/product` owns post-launch operation. Mitigation: wording says "optional after release" and "standalone for any consumer".

## Research / citations

- `.agent0/context/rules/agent0-governance-doctrine.md` - own/instrument/ignore boundary and continuous-evolution spine.
- `.agent0/context/rules/scope-admission-governance.md` - instrument-only outcome, evidence ladder, product-drift boundary, hardening bar.
- `.agent0/context/rules/spec-driven.md` - debate/acceptance shape.
- `.agent0/context/rules/secrets-scan.md` - credential-class and gitleaks discipline.
- `.agent0/tools/sync-harness.sh` - `.agent0/context/**` already ships via `COPY_CHECK_RECURSIVE`.
- Linear Sentry docs: https://linear.app/docs/sentry
- Linear Agents docs: https://linear.app/docs/agents-in-linear
- Sentry issue alert rule docs: https://docs.sentry.io/api/alerts/create-an-issue-alert-rule-for-a-project/
- OpenAI Codex in Linear docs: https://developers.openai.com/codex/integrations/linear
- GitHub Issues docs: https://docs.github.com/en/issues/tracking-your-work-with-issues/learning-about-issues/about-issues
- Claude review captured at `.agent0/.runtime-state/claude-exec/20260608T005051Z-spec169-maintenance-loop-review/last-message.md`.
