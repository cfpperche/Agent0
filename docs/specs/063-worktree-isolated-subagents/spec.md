# 063 — worktree-isolated-subagents

_Created 2026-05-19._

**Status:** draft

## Intent

The `Agent` tool surfaced by Claude Code accepts an optional `isolation: "worktree"` parameter that creates a temporary git worktree so the sub-agent operates on an isolated copy of the repo (per the `Agent` tool description in the system prompt: "With `isolation: 'worktree'`, the worktree is automatically cleaned up if the agent makes no changes; otherwise the path and branch are returned in the result"). Today, Agent0's delegation gate (`.claude/hooks/delegation-gate.sh`) does NOT parse, validate, or audit this choice — sub-agent isolation is invisible to the discipline pipeline.

Practical consequence: when the parent dispatches 2+ `Agent` calls in parallel (single-message multiple tool_use blocks, common pattern for cross-cutting refactors), and those sub-agents touch overlapping files, edits collide in the parent's working tree. The post-edit validator runs in the parent cwd regardless of where the sub-agent operated; a worktree-isolated sub-agent's edits aren't validated against the worktree's state.

This spec adds a 6th optional field — `ISOLATION:` — to the 5-field handoff at the main→sub boundary. Allowed value in v1: `worktree`. The delegation gate parses the field, propagates the `isolation` parameter into the `Agent` tool invocation if the orchestration layer supports it (TBD — see Open Question #1), and records it in the audit log. The post-edit validator detects the worktree path from the `Agent` tool return and runs validation scoped to it.

Parent of the umbrella spec 060 (A2, top pick #3 by ROI).

## Acceptance criteria

- [ ] **Scenario: brief omits ISOLATION (default behavior preserved)**
  - **Given** an `Agent` brief with the canonical 5 fields and no `ISOLATION:` line
  - **When** the delegation gate parses it
  - **Then** the gate accepts the brief, audit row records `isolation: null`, no behavior change vs today

- [ ] **Scenario: brief sets `ISOLATION: worktree`**
  - **Given** the brief contains a line `ISOLATION: worktree` (case-insensitive)
  - **When** the gate parses
  - **Then** audit row records `isolation: "worktree"` AND the `Agent` tool invocation receives `isolation: "worktree"` parameter (mechanism TBD per Open Question #1)

- [ ] **Scenario: 2 parallel dispatches with overlapping file targets, both isolated**
  - **Given** the parent makes two `Agent` calls in a single message, both with `ISOLATION: worktree`, both targeting (e.g.) `src/foo.ts`
  - **When** both run in parallel
  - **Then** each sub-agent operates on its own worktree copy; the parent's main worktree sees no in-progress edits during sub-agent execution; the parent reviews diffs via the path + branch returned in each Agent's result

- [ ] **Scenario: parallel dispatches with overlapping file targets, NOT isolated**
  - **Given** two parallel `Agent` calls touching `src/foo.ts`, neither sets `ISOLATION:`
  - **When** both run
  - **Then** behavior unchanged (status quo collision risk); audit log allows post-hoc analysis to flag the missing-isolation pattern

- [ ] **Scenario: post-edit validator scoping**
  - **Given** a sub-agent with `ISOLATION: worktree` makes an edit
  - **When** `.claude/hooks/post-edit-validate.sh` fires
  - **Then** the validator runs `cd <worktree_path>` before executing the test/lint pipeline (so it validates against the worktree's state, not the parent's stale view)

- [ ] **Scenario: unknown ISOLATION value (typo guard)**
  - **Given** the brief has `ISOLATION: parallel` (or any value other than `worktree`)
  - **When** the gate parses
  - **Then** the gate blocks with exit 2 + corrective stderr listing allowed values (`worktree`); same `# OVERRIDE:` escape applies

- [ ] **Scenario: ISOLATION field present but empty**
  - **Given** brief has `ISOLATION:` (no value or whitespace-only)
  - **When** the gate parses
  - **Then** treated as omitted; audit `isolation: null`; no block

- [ ] `.claude/rules/delegation.md` § The 5-field handoff updated to document the optional `ISOLATION:` 6th field, allowed values, and the parallel-dispatch use case

- [ ] `.claude/hooks/delegation-gate.sh` parses the field with same case-insensitive convention as TASK/CONTEXT/etc, validates against allowed values, records in audit row

- [ ] `.claude/hooks/post-edit-validate.sh` reads worktree path (mechanism: from `Agent` tool result captured in state, or from a per-`agent_id` state file populated by the gate) and `cd`s appropriately

- [ ] Audit log schema extended with `isolation` field (nullable string); `.claude/rules/delegation.md` § Audit log lists the new field

- [ ] Tests in `.claude/tests/<NNN>-isolation/` cover the seven scenarios above

## Non-goals

- Multiple isolation modes beyond `worktree` (e.g. `docker`, `process`) — v1 ships single value; reserve `ISOLATION:` namespace for future
- Conflict-resolution UI / auto-merge of parallel worktrees — user/parent resolves manually via standard git workflows
- Auto-worktree all parallel `Agent` calls — opt-in only; parent decides per-dispatch
- Worktree cleanup beyond what the `Agent` tool already does (auto-cleanup when no changes)
- Worktree-aware sub-agents reading sibling worktrees' changes (cross-worktree communication is out of scope)
- Modifying the underlying `Agent` tool itself (we layer on top of its existing `isolation:` parameter)

## Open questions

- [ ] **Mechanism for propagating `ISOLATION:` from the brief text into the `Agent` tool invocation.** The brief is a prompt string; the `Agent` tool call's `isolation` parameter is a separate JSON field set by the parent agent (the assistant model) when constructing the tool call. The hook can read/validate the brief, but cannot rewrite the tool call payload. Options: (a) advisory-only — gate parses + audits, agent reads the same brief and is *expected* to set `isolation: "worktree"` in the tool call (rule-only discipline, mirrors `user-prompt-framing.md`); (b) gate emits stderr instructing the parent to retry with the parameter set if missing; (c) future Claude Code hook surface that allows tool-call mutation pre-dispatch. Lean (a) for v1 with clear rule documentation.
- [ ] **Per-agent state file for worktree path.** Where does the post-edit validator read the worktree path from? The `Agent` tool returns the path in its result, but that result reaches the parent after dispatch — the hook firing during sub-agent edits needs the path earlier. Proposed: gate writes `.claude/.delegation-state/agents/<agent_id>/worktree` (empty file initially) when `ISOLATION: worktree` is seen; the `Agent` tool's post-creation step (or a hook on worktree creation if Claude Code exposes one) writes the actual path. Resolution requires reading the Claude Code hook surface for worktree events.
- [ ] **Default behavior on missing ISOLATION when multiple parallel Agent calls are detected.** Should the gate emit an advisory ("you dispatched 2+ Agent calls without ISOLATION — consider worktree") when it sees N>1 dispatches in quick succession? Spec 060 §B advisories pattern. Proposed: NO advisory in v1 — wait for rule-of-three evidence the parent actually causes collisions. Re-evaluate after dogfood.
- [ ] **Tests need an actual git repo** to exercise worktree creation. Existing test pattern uses isolated repo fixtures — verify the test runner supports git worktree operations in CI.

## Context / references

- Parent umbrella: `docs/specs/060-harness-gaps-2026/spec.md` § Gap matrix row A2
- `Agent` tool description in system prompt — declares `isolation: "worktree"` parameter and cleanup behavior
- `.claude/rules/delegation.md` § The 5-field handoff — the discipline being extended
- `.claude/hooks/delegation-gate.sh` — the parser to extend
- `.claude/hooks/post-edit-validate.sh` — validator scoping change
- Claude Code worktrees doc: https://code.claude.com/docs/en/worktrees
- Related spec history: `docs/specs/002-delegation/` (original gate design), `docs/specs/014-delegation-gate-hardening/` (gate parser improvements)
