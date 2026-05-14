# 028 — sdd-refine-interview

_Created 2026-05-14. Status: draft._

## Intent

Add a discovery-interview step to the `/sdd` skill family as a new `refine` subcommand. Today `/sdd new` scaffolds three empty template files and instructs the user to "fill spec.md first, alone" — but `spec-driven.md` explicitly names "a vague request that needs decomposition" as a trigger for SDD, and the skill gives zero help with that decomposition. The hardest, highest-leverage part of spec-driven development — turning a vague idea into well-formed intent — is left to unstructured ad-hoc conversation.

`/sdd refine` closes that gap. It ports the method from anthill's archived `anthill-feature-refiner` skill (`/home/goat/anthill/.claude/skills/anthill-feature-refiner/`): a senior-engineer discovery interview that silently loads project context, then conducts 3-6 adaptive rounds of grounded questioning — challenging assumptions, scoping aggressively for v1, detecting kill signals — before synthesising a user-ratified summary and writing it into our existing `spec.md` template. It is the opt-in front-end that produces the content `/sdd plan` then consumes. The port is method-only: anthill's output paths, 12-section template, ecosystem handoffs, and markdown-writer dependency do not come along.

## Acceptance criteria

_Observable outcomes as Given/When/Then scenarios for behavior, plain checkbox bullets for static facts. If every box can be ticked, the spec is delivered. Each criterion should be verifiable without re-reading the plan. See `.claude/rules/spec-driven.md` § Acceptance scenarios for shape guidance._

- [ ] **Scenario: refine a vague idea from scratch**
  - **Given** the user invokes `/sdd refine "<vague idea>"` with no matching spec dir
  - **When** the interview converges (3-6 rounds, or `--deep` lifts the cap)
  - **Then** a user-ratified synthesis is presented, and on confirmation a new `docs/specs/NNN-<slug>/` is scaffolded with `spec.md` filled across all five template sections (Intent, Acceptance criteria, Non-goals, Open questions, Context)

- [ ] **Scenario: refine without committing to a spec dir**
  - **Given** the user invokes `/sdd refine "<idea>"` but declines to write a spec dir at the synthesis step
  - **When** the interview converges
  - **Then** the synthesis is returned inline only — no `docs/specs/` directory is created (the "just the summary" exit)

- [ ] **Scenario: refine an existing spec**
  - **Given** `docs/specs/NNN-<slug>/spec.md` already exists with content
  - **When** the user invokes `/sdd refine NNN` (or `/sdd refine` with no args, targeting the latest spec dir)
  - **Then** the interview reads the existing `spec.md` first and refines it in place rather than starting fresh

- [ ] **Scenario: interview is grounded and non-sycophantic**
  - **Given** any `/sdd refine` invocation
  - **When** the discovery rounds run
  - **Then** the skill loads project context silently before the first question, references actual repo files/specs/rules in its rounds, states a recommended default per question, and challenges the idea at least twice — never one-shots, never opens with "great idea"

- [ ] `.claude/skills/sdd/SKILL.md` has a `## Subcommand: refine` section, and `refine` is added to the argument-parser subcommand list and the unknown-subcommand usage hint
- [ ] `.claude/skills/sdd/references/question-bank.md` exists — the 56-question / 6-category bank ported from anthill, stripped of anthill-specific product references
- [ ] `.claude/rules/spec-driven.md` § Workflow names `refine` as the optional discovery step that precedes filling `spec.md`
- [ ] The `refine` output fills the existing `spec.md.tmpl` structure unchanged — no new template file is added; Gherkin scenarios surfaced in discovery map to the existing `Scenario: … Given/When/Then` sub-bullet shape

## Non-goals

_What this change explicitly does NOT do. Future scope or adjacent problems that look similar but aren't in this spec._

- **No new templates.** `refine` fills the existing `spec.md.tmpl`; anthill's 12-section feature-spec-template is not ported.
- **No `plan.md` / `tasks.md` generation.** `refine` stops at `spec.md`; `/sdd plan` and `/sdd tasks` remain the next steps, unchanged.
- **No anthill ecosystem.** The handoff manifest collapses to a single pointer to `/sdd plan`. No `anthill-prd`, `anthill-roadmap`, `anthill-markdown-writer`, etc.
- **No enforcement hook.** `refine` is opt-in, like the rest of `/sdd`. Nothing blocks a user from hand-writing `spec.md` or skipping discovery entirely.
- **No standalone skill.** `refine` is a `/sdd` subcommand, not a separate `/refine` skill — spec work stays under one discoverable family.
- **Not ported:** `references/anti-patterns.md` — it is an empty stub in anthill.

## Open questions

_Unknowns to resolve before `plan.md` can be locked. Each should have an owner (who decides) or a path to resolution. Empty if there are none._

- [ ] Quality score + self-review checklist — port anthill's weighted quality-score table and `checklist.md`, or treat them as out of scope for v1 and keep `refine` lean? _(user decides during `/sdd plan`)_
- [ ] "Freedom" annotations (🔒/🔓/🟢 per step) — adopt them in our `SKILL.md` for consistency with the anthill source, or drop as visual noise inconsistent with the rest of our skill docs? _(user decides)_
- [ ] Slug derivation — when `/sdd refine "<idea>"` scaffolds a new dir, does `refine` propose the kebab-case slug (user confirms) or require the user to supply it explicitly as `new` does? _(resolve in plan)_
- [ ] Context-load scope — anthill reads CLAUDE.md, roadmap, ADRs, schema, PRD. Our equivalent set is CLAUDE.md + `.claude/rules/` + `.claude/memory/MEMORY.md` + existing `docs/specs/`. Confirm the exact silent-read list and whether it respects `research-before-proposing.md` (web research in-interview). _(resolve in plan)_
- [ ] Should `refine` operate on a spec dir that already has `plan.md` / `tasks.md` filled? Refining intent after planning has started is a real case but risks desync — block, warn, or allow? _(resolve in plan)_

## Context / references

_Links to related specs, prior art, issues, docs, conversations. Optional but useful._

- Source skill (archived, read-only): `/home/goat/anthill/.claude/skills/anthill-feature-refiner/` — `SKILL.md` + `references/{question-bank,feature-spec-template,checklist,anti-patterns}.md`
- `.claude/rules/spec-driven.md` — the workflow `refine` slots into; § Acceptance scenarios defines the scenario shape `refine` output must match
- `.claude/skills/sdd/SKILL.md` — the skill being extended
- `.claude/skills/sdd/templates/spec.md.tmpl` — the five-section template `refine` fills
- `.claude/memory/anthill-archived.md` — anthill is a one-way port reference; filesystem readable at `/home/goat/anthill/`
