# Agent0 Positioning Proof

_Last updated: 2026-06-09._

Agent0's current product claim is deliberately narrow:

> Agent0 is a portable governance and evidence harness for existing coding-agent runtimes.

It is not a standalone coding agent, hosted service, IDE, application framework, telemetry product, or proof of broad market adoption.

## What Is Proven Today

### Repo-backed mechanism

- Agent0 has runtime-specific entrypoints: `CLAUDE.md` for Claude Code and `AGENTS.md` for Codex.
- Shared first-party rules live under `.agent0/context/rules/`.
- Shared first-party tools live under `.agent0/tools/`.
- Runtime capability status is tracked explicitly in `.agent0/context/rules/runtime-capabilities.md`.
- Session continuity is represented by `.agent0/HANDOFF.md` and the session-handoff rule.

This proves Agent0 is more than a prose convention. The harness has repo-local files, runtime hooks, tools, and documented ownership boundaries.

### Work-loop evidence

- Non-trivial Agent0 changes are recorded under `docs/specs/NNN-<slug>/`.
- The workflow separates `spec.md`, `plan.md`, `tasks.md`, and `notes.md`.
- Validators, proof commands, visual-contract rules, and closeout advisories are used to attach evidence to shipped work.
- The current product-positioning reset itself is tracked as `docs/specs/182-product-positioning-reset/`.

This proves the discipline is practiced on the harness itself.

### Multi-runtime evidence

- Claude Code and Codex have separate first-contact files and hook surfaces.
- Shared Agent0-owned mechanisms are tracked in `.agent0/` rather than buried in a single runtime's private directory.
- The runtime-capabilities matrix distinguishes `native`, `native-opt-in`, `convention`, `planned`, and `unsupported` instead of pretending parity where it does not exist.

This proves the portability claim is bounded and falsifiable.

### Local dogfood evidence

- Agent0 has been used to synchronize harness updates into local consumer projects.
- Some local projects are intentionally demos or dogfood fixtures.
- Local dogfood is useful evidence for operational friction, sync safety, and workflow quality.

This proves internal utility, not market traction.

## What Is Not Proven Yet

- External adoption by independent users.
- Willingness to pay.
- Team-scale onboarding outside the maintainer's own projects.
- Long-term retention across independent organizations.
- That every existing surface deserves to remain in the public narrative.
- That local consumer sync state is a meaningful product metric at this stage.

## Current North Star

Agent0 should optimize for:

> Time from new project to first validated, reviewable commit in any supported coding-agent runtime.

Near-term product evidence should answer:

- Can a new project start from Agent0 without custom harness setup?
- Can the agent make a non-trivial change with clear intent, proof, and handoff?
- Can another runtime resume from the repo state without relying on hidden session memory?
- Can harness updates propagate without touching product code?

## Near-Term Product Discipline

- Do not sell capacity count as value.
- Do not claim adoption from local demos.
- Do not add dashboards, telemetry, or dogfood-health tooling until repeated external or team-scale pain justifies it.
- Prefer smaller public narrative and stronger proof over a broader catalog.
- Keep provider/runtime choice separate from Agent0's value: Agent0 should make Claude Code, Codex, and future runtimes more governable, not replace them.

## Evidence To Add Later

Only after there are real users or repeated team use:

- First-run walkthrough timing from clone to validated commit.
- Independent user onboarding notes.
- Consumer sync retention across non-demo projects.
- Concrete examples where Agent0 prevented a bad commit, recovered a session, or made a runtime switch possible.
- A short case study with before/after workflow evidence.
