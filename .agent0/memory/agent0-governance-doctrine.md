---
name: agent0-governance-doctrine
description: Scope boundary for expanding Agent0 — layered model, own/instrument/ignore,
  admission checklist, grandfathering. Read BEFORE proposing or building any new
  first-party capacity, governance lane, runtime surface, or shipped sync surface.
metadata:
  type: project
  created_at: '2026-06-07T00:00:00-03:00'
---

# Agent0 governance doctrine

_Relocated from `.agent0/context/rules/` 2026-06-09 under the [[rule-corpus-discipline]] audience test: this binds the Agent0 maintainer (whoever expands Agent0), not consumer-project agents — as a shipped rule it was inert-to-confusing downstream. Originally adopted via spec 166._

Read this before proposing or implementing a new first-party Agent0 capacity, governance lane, runtime surface, shipped sync surface, or product-like interface. This is the scope boundary for expanding Agent0 after spec 166.

## Core decision

Agent0 remains a stack-neutral **template/governance harness** for software projects. It is not a product by default, and it should not grow product surfaces until a recurring user pain and maintenance model make that necessary.

The near-term direction is to strengthen the template/governance layer: better context, better evidence, better quality/security discipline, better replication, and better limits on what gets admitted into the harness.

## Layered model

Do not classify Agent0 governance as a flat feature list. Use these layers:

1. **Continuous-evolution spine** - software work is recurring, not a one-way pipeline. Agent0 supports discovery, spec, implementation, validation, release evidence, maintenance, refactor, and renewed discovery as a loop.
2. **Governance domains** - quality and security are first-class domains applied along the spine.
3. **Governance substrate** - context and replication are the machinery that make the domains reliable across sessions and consumer projects.
4. **Transversal constraints** - multi-runtime support, stack neutrality, sync safety, cost honesty, and evidence discipline apply to every domain; they are not side buckets.
5. **Scope-admission meta-governance** - rule-of-three, reopen triggers, deferred rows, and explicit non-goals decide whether a proposed capacity belongs in Agent0 at all. The detailed operating discipline is [[scope-admission-governance]].

## Own, instrument, ignore

For every proposed expansion, classify the lifecycle surface before designing the mechanism:

- **Own** - Agent0 owns harness authorship and meta-evolution: specs, rules, hooks, tools, skills, sync behavior, context loading, handoff, memory, and validation primitives.
- **Instrument** - Agent0 can provide evidence, prompts, checks, or reusable harness mechanisms that help consumer projects run their own software lifecycle.
- **Ignore** - Agent0 should not own consumer product operation, deployment, runtime observability, business workflows, dashboards, or release authority unless a future spec explicitly proves the boundary should move.

This boundary is load-bearing. If Agent0 owns consumer operation/release, it drifts from template/governance into product/platform scope.

## Security is not just quality

Security overlaps with quality but is not a child of quality. Treat it as first-class when a proposal touches secrets, vulnerable dependencies, permissions, sensitive data, exposed surfaces, authentication, authorization, untrusted input, or adversarial behavior.

The reason is failure economics, not taxonomy aesthetics:

- Quality failures are usually self-inflicted regressions with continuous evidence such as tests, lint, typecheck, and visual contracts.
- Security failures include adversaries, asymmetric cost, delayed discovery, and evidence that is often absence-of-finding rather than proof of safety.

That difference justifies separate triggers, controls, language, and acceptance criteria.

## Admission checklist

Before adding a new Agent0 capacity or expanding an existing one, answer these questions in the spec or plan:

- Which layer does this affect: spine, domain, substrate, transversal constraint, or scope-admission?
- Does Agent0 **own**, **instrument**, or **ignore** the lifecycle surface?
- What repeated evidence exists: rule-of-three demand, reopen trigger, consumer pain, dogfood failure, or concrete drift?
- Why is an existing rule, prompt, context shape, or advisory insufficient?
- What runtime assumptions exist for Claude Code, Codex CLI, and future runtimes?
- What consumer sync surface changes, if any?
- Is the v1 advisory/report-only, or does it block? If it blocks, what evidence justifies a hard gate now?
- What is the validation evidence and how will future maintainers know the capacity still works?
- What product/platform drift could this introduce, and how is it bounded?

If these questions cannot be answered concretely, keep the idea in brainstorm, meeting, reminder, routine, or spec open questions instead of building it.

For admitted capacity specs, use [[scope-admission-governance]] for the full admission outcomes, evidence ladder, hardening bar, and deferred-work recording discipline.

## Grandfathering of pre-doctrine capacities

Capacities admitted to Agent0 before this doctrine was adopted (2026-06-07) are grandfathered. They remain first-class harness capacities and are not retroactively re-litigated against the admission checklist above. The doctrine and its scope-admission discipline apply prospectively: to new capacities and to material expansions of existing ones.

A material expansion of a grandfathered capacity — new modes, new paid lanes, new shipped sync surface — triggers the admission checklist the same as any new capacity. Ordinary maintenance — bug fixes, documentation corrections, port-parity work — does not.

## Gate-algebra lens

Existing Agent0 controls already resemble a common shape:

1. trigger
2. check
3. verdict
4. advisory, report, rewrite, or block
5. evidence artifact

Use this as a design lens when comparing governance mechanisms. Do not refactor existing gates into a shared framework just because the shape is visible; a separate spec must prove that unification removes real duplication or confusion.

## Candidate follow-ups

The doctrine preserves these possible future specs without starting them:

- `gate-algebra`
- `security-governance-lane`
- `continuous-evolution-spine`

Do not promote any of them automatically. Each needs its own evidence and scope decision.

Spec 169 (`post-launch-maintenance-loop`) is a narrow, instrument-only slice of the continuous-evolution spine: it ships guidance/templates for production-signal -> work-item -> agent-review maintenance, but it does not graduate the broader `continuous-evolution-spine` follow-up and does not move Agent0 into consumer operations.
