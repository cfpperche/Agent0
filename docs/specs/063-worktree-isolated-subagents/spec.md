# 063 — worktree-isolated-subagents

_Created 2026-05-19._

**Status:** in-progress

## Redesign (2026-05-19)

Pre-flight empirical discovery (same rigor that closed spec 062) revealed CC 2.1.144 ships **rich native worktree primitives** that change the design:

- `Agent` tool already accepts `isolation: "worktree"` in tool params (set by parent at dispatch)
- `EnterWorktree` / `ExitWorktree` are native tools (sub-agent invokes EnterWorktree as first action when isolation declared)
- `.claude/worktrees/<name>/` is the standard convention path
- `WorktreeCreate` / `WorktreeRemove` exist as hook events (per `.claude/memory/cc-platform-hooks.md`)
- CC injects the sub-agent's system prompt with worktree instructions automatically when `isolation: "worktree"` is set
- `--worktree [name]` is a CLI flag for whole-session worktree (with `--tmux` integration)
- `settings.json.worktree` block configures `bgIsolation`, `baseRef`, `sparsePaths`, `symlinkDirectories`

**Original design premise was wrong.** We assumed the gate needed to mutate the `Agent` tool call payload to set `isolation`. The empirical finding shows: parent sets `isolation` directly via tool params, CC's harness handles the rest. The gate cannot (and does not need to) mutate the tool call.

**The brief field `ISOLATION:` is dropped.** Declaring isolation in the 5-field handoff would duplicate the canonical `tool_input.isolation` field without enforcement value — the gate cannot bridge brief → tool param. Per spec 062 closure rationale: Agent0's frame is **discipline ON TOP of CC**, not replication of canonical primitives.

### What remains in scope (Option B redirect)

Three minimal-viable additions, all "discipline ON TOP of CC" pattern:

1. **Audit** `tool_input.isolation` in the dispatch row (delegation-gate.sh records 13th field `isolation`). Forensic value: post-hoc analysis can answer "did this dispatch isolate, given the signals?"
2. **§ Worktree isolation** section in `.claude/rules/delegation.md` documenting (a) what CC's native mechanism does, (b) when parents should declare isolation, (c) when NOT to, (d) why no brief field.
3. **Validator scoping fix** in `.claude/hooks/post-edit-validate.sh`: cd to git toplevel of the edit's file path before invoking the validator. Safe regardless of isolation declaration (parent edits → parent toplevel, worktree edits → worktree toplevel). Independent gain that mitigates cross-cwd validator issues in any sub-agent edit.

### What's dropped from the original design

- 6th optional `ISOLATION:` field in the 5-field handoff (replaced by reading `tool_input.isolation` directly)
- Gate validation of `ISOLATION:` value enum (CC's harness handles invalid values)
- State stamp file `.claude/.delegation-state/agents/<agent_id>/isolation` (audit row already records it)
- Advisory when `ISOLATION:` is missing under complexity signals (deferred — rule-of-three: ship audit first, add advisory only if observed drift demands it)

The historical original-design sections below (Acceptance criteria scenarios, Non-goals, Open questions) are preserved as design memory but most acceptance scenarios become obsolete. **Authoritative acceptance criteria** moved to the next section.

## Acceptance criteria (Option B redirect)

- [ ] **Scenario: dispatch with isolation declared**
  - **Given** parent makes an `Agent` call with `isolation: "worktree"` in tool params
  - **When** `delegation-gate.sh` runs
  - **Then** dispatch audit row contains `"isolation": "worktree"`

- [ ] **Scenario: dispatch without isolation**
  - **Given** parent makes an `Agent` call without isolation in tool params
  - **When** `delegation-gate.sh` runs
  - **Then** dispatch audit row contains `"isolation": ""` (empty string, not null — matches existing convention for missing fields like `model: ""`)

- [ ] **Scenario: validator scoping for parent-tree edit**
  - **Given** sub-agent edits `src/foo.ts` in the parent's working tree
  - **When** `post-edit-validate.sh` runs
  - **Then** validator runs from `git rev-parse --show-toplevel` of `src/foo.ts` (= parent project dir; no behavior change vs today)

- [ ] **Scenario: validator scoping for worktree-isolated edit**
  - **Given** sub-agent dispatched with `isolation: "worktree"` invoked `EnterWorktree` and edited `.claude/worktrees/foo/src/bar.ts`
  - **When** `post-edit-validate.sh` fires
  - **Then** validator runs from `.claude/worktrees/foo/` (= the worktree's git toplevel), validating against the isolated tree state, not stale parent

- [ ] **Scenario: validator scoping fail-safe when git rev-parse fails**
  - **Given** an edit happens outside any git repo (theoretical — scratch dir)
  - **When** `post-edit-validate.sh` derives the cwd
  - **Then** falls back to `$PROJECT_DIR` (no behavior change vs today)

- [ ] `.claude/rules/delegation.md` has new section `## Worktree isolation` documenting native CC behavior, when to use, when not to, and the no-brief-field decision

- [ ] `.claude/hooks/delegation-gate.sh` extracts `tool_input.isolation` and includes it in dispatch row jq build (13th field)

- [ ] Audit log dispatch rows after deploy include `isolation` key; pre-deploy rows do not (schema is additive, no migration needed)

## Intent

_Historical — original intent before 2026-05-19 redesign. Preserved for design memory; superseded by § Redesign above._


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
