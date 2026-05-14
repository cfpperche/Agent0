# 028 — sdd-refine-interview — tasks

_Generated from `plan.md` on 2026-05-14. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. Create `.claude/skills/sdd/references/question-bank.md` — port anthill's 56-question / 6-category bank (problem validation, scope & boundaries, architecture & data, external integrations, UX, tradeoffs & risks, business impact). Strip every anthill-specific product reference (ConsultaHub, Stripe Connect, etc.); keep questions generic. Re-point any "PRD"/"ADR-file" phrasing at Agent0 artifacts (`docs/specs/`, `.claude/rules/`).
- [x] 2. Create `.claude/skills/sdd/references/checklist.md` — port anthill's self-review checklist. Keep the Context / Discovery quality / Synthesis / Output quality / Integrity groupings. Drop rows referencing anthill-only artifacts; re-point "output follows the template" at `.claude/skills/sdd/templates/spec.md.tmpl`; replace the `anthill-markdown-writer` row with nothing (no equivalent in Agent0).
- [x] 3. Add `## Subcommand: refine` to `.claude/skills/sdd/SKILL.md`, placed between `## Subcommand: new` and `## Subcommand: plan`. Include: the five-step process (0 context load, 1 opening, 2 discovery, 3 synthesis, 4 output, 5 close) with 🔒/🔓/🟢 freedom annotations per step; the three entry shapes (`refine "<idea>"`, `refine NNN`, `refine` no-arg); the resumability check; slug-proposal behavior (Q3); the silent context-load list (Q4); the `plan.md`/`tasks.md`-already-exists warning (Q5); the "just the summary" inline exit; the inline weighted quality-score table in Step 5; and references to `references/question-bank.md` + `references/checklist.md`.
- [x] 4. Update `.claude/skills/sdd/SKILL.md` plumbing — add `refine` to the argument-parser subcommand enumeration, add `refine` to the unknown-subcommand usage hint (`/sdd <new <slug> | refine [...] | plan | tasks | list>`), and update the `argument-hint` frontmatter line.
- [x] 5. Update `.claude/rules/spec-driven.md` § Workflow — insert `refine` as an optional Step 0 ("discovery") that precedes filling `spec.md`; cross-reference the "vague request" trigger already in § When SDD applies. Keep it brief — the rule documents *when*, the skill documents *how*.

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria._

- [x] `.claude/skills/sdd/references/question-bank.md` and `.claude/skills/sdd/references/checklist.md` exist; `grep -ri 'consultahub\|stripe connect\|anthill' .claude/skills/sdd/references/` returns nothing — confirms the port is stripped of anthill-specific references (spec.md AC: question-bank exists, stripped).
- [x] `.claude/skills/sdd/SKILL.md` contains a `## Subcommand: refine` section, and `refine` appears in both the argument-parser subcommand list and the unknown-subcommand usage hint (spec.md AC: SKILL.md plumbing).
- [x] `.claude/rules/spec-driven.md` § Workflow names `refine` as the optional discovery step (spec.md AC: rule update).
- [x] No new file under `.claude/skills/sdd/templates/`; the `refine` section in `SKILL.md` instructs filling the existing `spec.md.tmpl` five sections, and maps discovery Gherkin onto the existing `Scenario: … Given/When/Then` sub-bullet shape (spec.md AC: no new template).
- [x] Walk the four `spec.md` scenarios against the written `## Subcommand: refine` text — each scenario (fresh refine, summary-only exit, refine existing, grounded/non-sycophantic) has a corresponding instruction path in the skill. Confirm by reading, not execution (no runnable stack).

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._

- Source of the port: `/home/goat/anthill/.claude/skills/anthill-feature-refiner/` (archived, read-only).
- No code, no hooks, no validators — documentation-only change. The repo validator is inert here (no language stack).
- `refine` ships to forks automatically: `.claude/skills/` and `.claude/rules/` are both in the sync-harness manifest.
