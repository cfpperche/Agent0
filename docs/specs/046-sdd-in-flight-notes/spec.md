# 046 — sdd-in-flight-notes

_Created 2026-05-18._

**Status:** shipped

## Intent

Our SDD's three artifacts cover pre-flight (`spec.md` = intent, `plan.md` = approach) and post-flight (commit messages, PR body = synthesis). The gap is **in-flight design memory** — the decisions, deviations, tradeoffs and open questions surfaced *while* the agent (or human) is building. Today this material rots in chat scrollback (lost on `/clear` or compact), fragmented commit messages, or `SESSION.md` (overwritten each handoff). The Travis Fischer "implementation-notes" pattern fills this gap: a running file, scoped to the work unit, where the implementer records what diverged from the spec, what tradeoffs were taken, and what open questions emerged — giving the agent a sanctioned "out" for ambiguity while keeping the human in the loop.

Add a fourth optional artifact `docs/specs/NNN-<slug>/notes.md` to the SDD scaffold with four canonical sections (Design decisions / Deviations / Tradeoffs / Open questions), append-only by convention, scoped per spec so it survives compaction and travels with the spec into git history. Ship v1 as **optional + rule-only** (no hook enforcement) — mirroring spec 035's dogfood-first shape. Promote to mandatory only if the dogfood window proves the artifact is consulted in review/handoff (per `.claude/memory/feedback_speculative_observability.md`'s rule-of-three demand test).

## Acceptance criteria

- [x] **Scenario: scaffold creates notes.md**
  - **Given** the user runs `/sdd new <slug>`
  - **When** the skill scaffolds the spec dir
  - **Then** `docs/specs/NNN-<slug>/notes.md` exists alongside spec/plan/tasks, with the four canonical sections (Design decisions / Deviations / Tradeoffs / Open questions) and placeholder substitutions ({{NNN}}/{{SLUG}}/{{DATE}}) applied identically to the other three files

- [x] **Scenario: in-flight append by implementer**
  - **Given** a sub-agent (or the parent) is executing tasks from `tasks.md` for spec NNN and encounters an ambiguity not covered by `spec.md`/`plan.md`
  - **When** it records the resolution
  - **Then** a dated entry of shape `### YYYY-MM-DD — <author> — <one-line title>` is appended to the appropriate section of `notes.md` (entries are append-only; previous content is not edited)

- [x] **Scenario: delegation brief references notes**
  - **Given** the parent dispatches an `Agent` call where `CONTEXT` references a spec dir (`docs/specs/NNN-*`)
  - **When** the brief is composed
  - **Then** `DELIVERABLE` includes the phrase "append any in-flight decisions/deviations/tradeoffs/open-questions to `docs/specs/NNN-*/notes.md`" (or equivalent verbatim phrasing documented in `.claude/rules/delegation.md`)

- [x] **Scenario: rule documents the artifact**
  - **Given** a contributor reads `.claude/rules/spec-driven.md`
  - **When** they look up the SDD artifacts section
  - **Then** they find `notes.md` listed as the fourth artifact, with its purpose, when to write to it, the four-section structure, the append-only convention, and the entry shape — alongside a cross-reference to `.claude/rules/delegation.md` for the sub-agent integration

- [x] **Scenario: dogfood window opens**
  - **Given** spec 046 is shipped
  - **When** the next 3-5 specs are scaffolded
  - **Then** each has a `notes.md` whose population (or non-population) is reviewed at PR time; a follow-up REMINDERS item tracks promotion decision with `--due 2026-07-01`

- [x] `.claude/skills/sdd/templates/notes.md.tmpl` exists with the four-section skeleton and placeholders `{{NNN}}` / `{{SLUG}}` / `{{DATE}}`
- [x] The `new` subcommand in `.claude/skills/sdd/SKILL.md` lists `cp templates/notes.md.tmpl … notes.md` alongside the other three template copies
- [x] `CLAUDE.md` § *Spec-driven development* mentions the fourth artifact (one-line addition; no full rewrite)
- [x] Spec 046's own `notes.md` is non-empty at ship time (meta-dogfood: this spec's implementation surfaces at least one in-flight decision worth recording)

## Non-goals

- **No hook enforcement in v1.** Rule-only by construction; mirroring spec 035's pattern. A `PostToolUse(Agent)` or `Stop` hook to flag missing notes.md entries is deferred until the dogfood window shows ≥3 missed-notes sessions.
- **No retroactive backfill.** Existing specs (001-045) do not get `notes.md` added. The artifact applies to specs scaffolded *after* this spec ships.
- **Not a replacement for SESSION.md.** Different lifecycle: `SESSION.md` is cross-session WIP handoff (overwritten); `notes.md` is per-spec design memory (append-only, git-tracked, survives the work unit).
- **Not a replacement for commit messages or PR bodies.** Commits remain the audit trail; PR bodies remain the synthesis. `notes.md` is the *source material* the synthesis draws from.
- **Not a structured ADR system.** No frontmatter, no schema, no machine parser. Plain markdown by design — readability and `git diff` are the contract.
- **No automation of "Open questions → Acceptance scenarios" promotion.** Manual curation by the human at review time.

## Open questions

- [x] **File extension: `.md` or `.html`?** Travis Fischer's original prompt used `.html`. We default to `.md` for `git diff` legibility, parity with `spec.md`/`plan.md`/`tasks.md`, and lower friction in CLI workflows. Decision likely locked at `.md` unless someone surfaces a compelling rendering case. — _owner: decided at plan time_
- [x] **Promotion criteria for v1 → v2.** What signal proves dogfood success? Candidates: (a) ≥3 of next 5 PRs cite `notes.md` content in their body; (b) ≥3 specs land with non-empty `notes.md`; (c) qualitative — human review of whether the file changed how review/handoff felt. Lean (a)+(b) combined. — _owner: revisit 2026-07-01 via REMINDERS_
- [x] **Sub-agent enforcement via delegation-gate?** Should `delegation-gate.sh` advise (not block) when a brief's `CONTEXT` names a spec dir but `DELIVERABLE` omits notes.md reference? Initial answer: **no** — pure rule until rule-of-three demand surfaces. Cited explicitly so v2 has a documented landing place. — _owner: blocked on dogfood data_
- [x] **Entry shape: free prose vs. mini-schema?** Options: (1) free-form heading + body (lowest friction); (2) `### YYYY-MM-DD — <author> — <title>` heading + free body (balance — chosen as default); (3) full schema (date / author / category / rationale / refs — heavy). Default (2); revisit if free-form proves too disorderly. — _owner: decided at plan time_
- [x] **Co-location with `docs/specs/NNN-*/artifacts/`.** Some specs (e.g. 045) already have an `artifacts/` subdir for renders, screenshots, tombstones. Does `notes.md` go at the spec root or under `artifacts/`? Lean **spec root** for parity with the other three. — _owner: decided at plan time_

## Context / references

- [@trq212 thread (via unrollnow)](https://unrollnow.com/status/2056415973125796184) — origin of the "implementation-notes" pattern
- `.claude/rules/spec-driven.md` § *The three artifacts* — where the fourth artifact gets documented
- `.claude/rules/delegation.md` § *The 5-field handoff* — `DELIVERABLE` extension point for sub-agent integration
- `.claude/skills/sdd/SKILL.md` § *Subcommand: `new <slug>`* — scaffold flow to extend
- `.claude/skills/sdd/templates/` — where the new `notes.md.tmpl` lands
- `docs/specs/035-user-prompt-framing/` — sister "rule-only, hook deferred" shape; canonical precedent for v1 scope discipline
- `docs/specs/028-sdd-refine-interview/`, `docs/specs/029-sdd-list-in-flight/` — adjacent `/sdd` skill evolution
- `.claude/memory/feedback_speculative_observability.md` — rule-of-three demand test that governs v1 → v2 promotion
- `CLAUDE.md` § *Spec-driven development* — one-line update target
