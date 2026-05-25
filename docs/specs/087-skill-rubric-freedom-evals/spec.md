# 087 — skill-rubric-freedom-evals

_Created 2026-05-24._

**Status:** shipped

## Intent

Skills with multi-step pipelines (`/sdd`, `/product`, `/skill`) face the same drift the 5-field handoff (`.claude/rules/delegation.md`) was built to mitigate — except one level deeper. The 5-field handoff disciplines the **parent→sub** boundary; this spec extends the discipline to the **skill→LLM-executor** boundary, which today is informal. The LLM reading `SKILL.md` has to infer per step whether the instruction is literal-template (improvise nothing) or adaptive-shape (improvise content within guardrails) — and empirically over-improvises on the former.

Adopt two writing conventions observed in the wild at ≥80% adoption across a 144-skill corpus (anthill `.claude/skills/`):

1. **Freedom annotations** — per-step header carries `🔒 Low freedom: <claim>` (exact template / sequence / parsing) or `🔓 Medium freedom: <claim>` (adapts to detected state). Communicates affordance the way a UI control communicates draggable-vs-fixed. No `High freedom` tier — skills are imperative by definition.

2. **`## Eval Scenarios`** section — 3 scenarios (happy / minimal / adversarial) with **Input** (verbatim user prompt), **Expected** (observable sequence + output shape), **Failure indicators** (2-4 concrete anti-signals). Functions as a DONE_WHEN contract for the skill as a whole — the LLM re-reads as rubric before declaring done.

Apply to the three skills with ≥4 steps (`/sdd`, `/product`, `/skill`); exempt the mechanical skills (`/remind`, `/routine`, `/image`, `/brainstorm`) where the per-step cardinality is too low to benefit. Extend `/skill validate` to emit a non-blocking `skill-rubric-advisory:` line when a skill above the threshold lacks either convention — mirrors the existing `tdd-advisory:` / `lint-advisory:` family (`.claude/rules/delegation.md` § *Advisories*).

The eval scenarios layer is the **skill-level sibling** of the spec-level `## Acceptance criteria` Given/When/Then convention (`.claude/rules/spec-driven.md` § *Acceptance scenarios*). Same contract-not-promise filosofia, different unit of work.

## Acceptance criteria

- [x] **Scenario: compliant skill passes validator**
  - **Given** a skill SKILL.md with ≥4 `##` step headers, every step carrying a `🔒` or `🔓` freedom-annotation marker on its header line, AND an `## Eval Scenarios` section containing ≥2 scenario blocks
  - **When** `bash .claude/skills/skill/scripts/validate.sh <slug>` runs
  - **Then** no `skill-rubric-advisory:` line is emitted; the validator's existing frontmatter-spec checks continue to fire as before; exit code stays 0

- [x] **Scenario: missing freedom annotations triggers advisory**
  - **Given** a SKILL.md with ≥4 `##` step headers, zero of which carry a freedom-annotation marker
  - **When** the validator runs
  - **Then** stderr receives a `skill-rubric-advisory: <slug> has N steps but no freedom annotations — add 🔒/🔓 markers per step (see .claude/skills/skill/references/skill-rubric.md)` line; exit code stays 0 (advisory, not blocking)

- [x] **Scenario: missing eval scenarios triggers advisory**
  - **Given** a SKILL.md with ≥4 `##` step headers and freedom annotations present, but no `## Eval Scenarios` section
  - **When** the validator runs
  - **Then** stderr receives a `skill-rubric-advisory: <slug> has N steps but no ## Eval Scenarios — add 2-3 scenarios per references/skill-rubric.md` line; exit code stays 0

- [x] **Scenario: sub-threshold skill is exempt**
  - **Given** a SKILL.md with <4 qualifying `##` step headers (e.g. `/image` — single-flow skill with no qualifying subcommand sections)
  - **When** `check-rubric.sh` runs
  - **Then** no `skill-rubric-advisory:` line is emitted regardless of whether annotations or eval scenarios exist; the threshold is the only gate for this advisory.
  - **Note:** `/remind`, `/routine`, `/brainstorm` were initially assumed sub-threshold but empirically have 5-8 qualifying headers (subcommand dispatchers); they carry the `<!-- SKILL-RUBRIC-EXEMPT: -->` override marker instead — see `notes.md` design-decision 2026-05-25 + Scenario "rubric override marker" below.

- [x] **Scenario: rubric override marker silences a deliberate exemption**
  - **Given** a SKILL.md above the step threshold whose frontmatter (or a first-line HTML comment) carries `<!-- SKILL-RUBRIC-EXEMPT: <reason ≥10 chars> -->`
  - **When** the validator runs
  - **Then** no advisory is emitted regardless of compliance state; the validator's other checks (agentskills frontmatter spec) still apply; the reason is the audit trail and is mandatory at the ≥10-char floor (mirrors the project's `# OVERRIDE:` grammar in `.claude/rules/delegation.md`)

- [x] `/sdd` SKILL.md has a `🔒` or `🔓` annotation on every `##` step header AND an `## Eval Scenarios` section with ≥2 scenarios (happy + at least one edge)
- [x] `/product` SKILL.md has freedom annotations on every step header AND `## Eval Scenarios` with ≥2 scenarios; the 8 phase headers drive the calibration (Phase 1-4 content steps = 🔓 Medium; Phase 0/0.5/quality-judge/Phase 5 = 🔒 Low)
- [x] `/skill` SKILL.md has freedom annotations on every subcommand-section header AND `## Eval Scenarios` with ≥2 scenarios
- [x] `.claude/skills/skill/scripts/check-rubric.sh` exists and emits `skill-rubric-advisory:` per the scenarios above; invoked by `/skill audit` per the wiring in `.claude/skills/skill/SKILL.md` § *Subcommand: audit*; `validate.sh` left untouched (frontmatter compliance stays scoped to the agentskills.io upstream spec — host correction documented in `plan.md` § *Approach*)
- [x] `.claude/skills/skill/references/skill-rubric.md` exists and documents: the two conventions, the grammar (which markers count as `🔒` / `🔓`), the eval scenario shape, the step-threshold + override marker
- [x] `.claude/rules/spec-driven.md` § *Acceptance scenarios* gains a one-line cross-reference to `.claude/skills/skill/references/skill-rubric.md` (eval scenarios as skill-level sibling)
- [x] `bash .claude/skills/skill/scripts/check-rubric.sh` against `/sdd` / `/product` / `/skill` all emit zero `skill-rubric-advisory:` lines after rollout (verified V6)

## Non-goals

- **NG-1: No blocking gate.** `skill-rubric-advisory:` is always exit 0, advisory only. Mirrors `tdd-advisory:` / `lint-advisory:` posture in `.claude/rules/delegation.md` § *Advisories*. Promotion to blocking is deferred per the rule-of-three demand test in `.claude/memory/feedback_speculative_observability.md`.

- **NG-2: No new hook.** The check lives inside the existing `/skill validate` script, fired by the user explicitly invoking the slash command (or by `/skill audit --all`). No `PostToolUse` hook on SKILL.md edits — that would be redundant noise during authoring.

- **NG-3: No new state file or audit log.** Findings live in stderr of the validator run. If empirical drift surfaces ≥3 times per week (the project's standard promotion threshold), the next step is a periodic `/routine` that runs `/skill audit --all` and reports — not a JSONL log file.

- **NG-4: No retroactive auto-edit of the three target skills.** Author writes the annotations + eval scenarios manually for each of `/sdd`, `/product`, `/skill`. Auto-generation would produce stub-shaped freedom annotations (`🔒 Low freedom: <empty>`) that hide the writing discipline the convention exists to enforce. Same posture as `.claude/rules/artifact-budgets.md` § *Anti-stub floor*.

- **NG-5: No IC-persona sub-agents.** Anthill's codebase-review skill dispatches to `staff-engineer` / `appsec` / `qa-engineer` / `sre` personas. Agent0 explicitly rejects persona-shaped delegation per `.claude/memory/feedback_no_persona_role_prompting.md` — sub-agents stay `general-purpose` with task-shaped briefs. This spec ports the *writing conventions*, not the agent topology.

- **NG-6: No agentskills.io frontmatter promotion.** The conventions live in the body of `SKILL.md`, not the YAML frontmatter. `disable-model-invocation: true` is already part of the agentskills.io spec snapshot at `.claude/skills/skill/references/spec-snapshot.md`; this spec doesn't touch frontmatter shape.

- **NG-7: No port of the `<!-- ANSWER: -->` async human-in-loop pattern.** That's a separate, higher-cost capacity (the bifasic insight from the same anthill skill). Deferred until a real frustration with synchronous `AskUserQuestion` surfaces.

## Open questions

- [x] **OQ-1** Step-threshold value. Working draft says **≥4 `##` step headers**. `/sdd` has 5 subcommands → counts. `/product` has 15 steps → counts. `/skill` has 5 subcommands → counts. `/remind`, `/routine` have 4-5 subcommand sections each — would they count? **Tentative resolution:** the threshold counts steps inside a pipeline, not subcommand dispatchers. Operationalize as: count `^##` headers that are NOT `## Notes` / `## Gotchas` / `## Cross-references` / `## Reference Files` (frame headers). If that count ≥4, the skill is in scope. Confirm during plan.

- [x] **OQ-2** Emoji set canonical or text-only? Anthill uses 🔒 / 🔓. Pros of emoji: 1-char visual scan, no parser ambiguity. Cons: emoji-render variation in non-mono terminals, harder for grep. **Tentative resolution:** keep emoji as canonical (match anthill, low cost, visual benefit dominates); the validator's regex accepts BOTH the emoji form AND a text-fallback (`Low freedom:` / `Medium freedom:` at start of step header). Authors writing in emoji-hostile environments use the text form; readers see whichever was written.

- [x] **OQ-3** Fixed count or range for eval scenarios? Anthill targets 3 (happy / minimal / adversarial) but doesn't enforce. **Tentative resolution:** validator requires ≥2 (allows skipping the adversarial case for skills where it doesn't apply); the reference doc names 3 as the recommended target. Floor 2 keeps the advisory tractable without ossifying.

- [x] **OQ-4** Eval scenario format strict or loose? Anthill uses `### Eval N: <title>` followed by **Input** / **Expected** / **Failure indicators** as bold inline labels — but other anthill skills use a table or a flat bullet list. **Tentative resolution:** validator checks only for the section header `## Eval Scenarios` AND ≥2 `### Eval ` sub-headers underneath. Body shape is convention, not enforced — same posture as `## Acceptance criteria` in spec.md (the rule documents the shape; the validator doesn't parse it).

- [x] **OQ-5** Rollout order: documentation first or validator first? **Tentative resolution:** documentation first (write `skill-rubric.md` reference, annotate the 3 target skills, hand-verify they self-consistent), then extend the validator. Reverse order would make the validator fire `skill-rubric-advisory:` on all 3 target skills during a stretch where they're not yet compliant — noise without value. Settle in plan.

- [x] **OQ-6** Does the convention apply to **rules** files (`.claude/rules/*.md`) too? Rules are also LLM-facing prose with multi-section structure. **Tentative resolution:** no, rules are by definition fully literal ("the whole content is binding"). Freedom annotations would be cargo-culted. Eval scenarios don't fit either — rules describe constraints, not procedures. Scope this spec to `.claude/skills/*/SKILL.md` only.

## Context / references

- `.claude/skills/skill/` — meta-skill the validator extension lives in; references go under `references/skill-rubric.md`
- `.claude/skills/skill/scripts/validate.sh` — existing validator (agentskills.io frontmatter spec compliance); the rubric advisory hooks on after that runs
- `.claude/skills/skill/references/spec-snapshot.md` — frozen agentskills.io spec; confirms the conventions live in SKILL.md body, not frontmatter
- `.claude/skills/skill/references/portability-tiers.md` — three tiers (cc-native / agentskills-portable / runtime-agnostic); the rubric is convention-only and therefore tier-agnostic
- `.claude/rules/delegation.md` § *Advisories* — `skill-rubric-advisory:` follows this grammar
- `.claude/rules/delegation.md` § *The 5-field handoff* — the parent→sub discipline this spec extends one level deeper (skill→LLM-executor)
- `.claude/rules/spec-driven.md` § *Acceptance scenarios* — the spec-level sibling of the eval-scenarios layer; cross-references go both ways
- `.claude/rules/artifact-budgets.md` § *Anti-stub floor* — same disciplina that motivates NG-4 (no auto-stub generation)
- `.claude/memory/feedback_speculative_observability.md` — rule-of-three demand test motivating the advisory-only posture (NG-1, NG-3)
- `.claude/memory/feedback_no_persona_role_prompting.md` — motivates NG-5 (no IC-persona sub-agents adopted from anthill)
- `/home/goat/anthill/.claude/skills/anthill-codebase-review/SKILL.md` — primary reference; 10 freedom annotations, 3 eval scenarios with failure indicators
- `/home/goat/anthill/.claude/skills/anthill-agent-creator/SKILL.md` — second example (8 freedom annotations, 2 eval scenarios — minimal eval format)
- Density audit: 118/144 anthill skills (82%) use freedom annotations; 123/144 (85%) use eval scenarios. Conducted 2026-05-24 in the session that produced this spec.
