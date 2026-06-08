---
meeting: post-launch-maintenance-loop
roster: claude,codex,human
rotation: codex,claude
tier: decision-grade
blind_phase: partial
turn_counter: 2
next_speaker: codex
synthesis: written
---

# 169 - post-launch-maintenance-loop - debate

_Created 2026-06-08._

**Initiating agent:** Codex CLI
**Reviewing agent:** Claude Code
**Initiated by:** Codex CLI session 2026-06-08

Cross-model review of `spec.md`. Claude's Round 1 was run through `claude-exec` read-only, with the prompt built from `spec.md` and local rules only, not from Codex's position. Captured run:

- `.agent0/.runtime-state/claude-exec/20260608T005051Z-spec169-maintenance-loop-review/last-message.md`
- session id `24db416c-3005-4797-8213-f3416d8a451b`

## Round 1 - initiating agent (position)

**Intent.** Agent0 should support a post-launch maintenance loop as part of the continuous-evolution spine, but only as instrumentation: production signal -> work item -> coding-agent delegation -> human review -> validation -> durable learning back into SDD/product vN. The motivating example is Sentry -> Linear -> Codex, but the spec should avoid locking Agent0 to Sentry, Linear, Codex, or `/product`.

**Load-bearing acceptance scenarios.**

1. `/product` may reference the loop as optional post-launch setup, but must not install or require it.
2. Existing Agent0 consumers can adopt standalone guidance without `/product` artifacts.
3. Untrusted incident payload must be separated from trusted agent instructions, with no auto-merge or production authority.

**Open questions before planning.**

1. Exact v1 surface shape.
2. How concrete the Sentry -> Linear -> Codex example should be without becoming the architecture.
3. Where the security checklist belongs.

**Where pushback is most useful.** Challenge product-drift risk, whether evidence is sufficient for any shipped surface, and whether the security criteria are actually verifiable.

## Round 1 - reviewing agent (critique)

Claude's review accepted the instrument-only direction but marked the draft not plan-ready.

**Blocking ambiguities.**

- OQ1 left the v1 surface fully open. Claude argued the spec must state a default because skill vs rule+templates has very different sync and maintenance cost.
- `learning sink` was undefined.
- The draft blurred prose guidance vs actual copyable templates.
- Minor: Claude believed the created date was one day ahead; current system date for this Codex session is 2026-06-08, so Codex does not treat that as an issue.

**Product-drift risks.**

- The spec starts a slice of the deferred `continuous-evolution-spine`; it needs to acknowledge that and keep the scope intentionally narrow.
- Routing maintenance signals back into `/product` vN could turn the loop into product-ops unless human choice is explicit.
- Even a playbook can drift into prescribing consumer operations; Agent0 should describe capability roles and evidence, not own the incident process.

**Security gaps.**

- "Requires mitigations" was not verifiable enough.
- Prompt injection must be modeled as a multi-hop chain, not a single boundary.
- Raw production payloads sent to work hubs or third-party AI vendors need redaction/data-minimization guidance.
- Agent write scope and dependency-install instructions need their own scenario.
- Credential classes should connect to existing Agent0 secret/credential discipline.

**Weak criteria.**

- Several behavior scenarios were really static presence checks.
- No validation/dogfood criterion existed.
- The vendor-alternative criterion required non-Linear and non-Codex options but not non-Sentry signal sources.
- "Current references" needed isolation or a refresh trigger.
- Sync-safety needed a checkable grep-shaped criterion.
- Admission brief was missing evidence, v1 posture, blast radius, and validation.

**Recommendation.** Defer `plan.md` until the spec is revised. If this remains founder-directive evidence only, cap v1 to rule+templates and do not create a skill.

## Round 2 - initiating agent (counter)

Codex accepts the blocking critique and applied revisions before planning:

- **Accept:** default v1 surface is now context rule + copyable Markdown templates; no new skill in v1.
- **Accept:** admission brief now names Layer, Boundary, Evidence, V1 posture, Blast radius, Validation, and Non-goals.
- **Accept:** `learning sink` became `feedback sink`, defined by the acceptance scenario that routes durable follow-up into tests, SDD, memory, reminders/routines, or `/product` vN only by explicit human choice.
- **Accept:** security now has separate scenarios for untrusted payload fencing, multi-hop injection, data minimization, and agent authority.
- **Accept:** provider flexibility now includes non-Sentry signal sources, non-Linear work hubs, and non-Codex agent categories.
- **Accept:** sync-safety is now checkable as absence of configured credentials, real DSNs, API keys, tokens, telemetry payloads, project-specific Linear IDs, GitHub repo names, and vendor-specific local choices in shipped files.
- **Defer:** exact template path and whether vendor references need a recurring routine remain open for `plan.md`.
- **Reject minor:** date remains 2026-06-08 because the current Codex/system date is 2026-06-08.

## Synthesis

**Resolution:** converged

**Proposed spec changes:**

- Update `## Intent` with the default rule+templates v1 surface and no-skill/no-hook/no-daemon posture.
- Expand `## Intent` with the complete scope-admission brief.
- Replace vague mitigation criteria with verifiable adversarial/security scenarios.
- Add non-Sentry, non-Linear, and non-Codex flexibility criteria.
- Tighten sync-safety and validation criteria.
- Narrow open questions to path/split/freshness/future-skill trigger.

**Unresolved disagreements:** none.

**Minority report:** none. Claude's material objections were accepted; remaining questions are plan-phase choices, not convergence blockers.

**Convergence evidence:** changes are anchored in `spec.md` edits, `.agent0/context/rules/scope-admission-governance.md`, `.agent0/context/rules/agent0-governance-doctrine.md`, and Claude's captured read-only critique.

## Applied changes

- `docs/specs/169-post-launch-maintenance-loop/spec.md` `## Intent` - added default v1 surface and full scope-admission brief.
- `docs/specs/169-post-launch-maintenance-loop/spec.md` `## Acceptance criteria` - added adversarial prompt-injection, multi-hop, data-minimization, agent-authority, provider-flexibility, validation, and sync-safety criteria.
- `docs/specs/169-post-launch-maintenance-loop/spec.md` `## Non-goals` - clarified no incident-process ownership and no provider lock-in.
- `docs/specs/169-post-launch-maintenance-loop/spec.md` `## Open questions` - narrowed questions to plan-phase path/split/freshness/future-skill decisions.
