# 155 — visual-contract-acceptance-gate

_Created 2026-06-05._

**Status:** shipped

**UI impact:** none

## Intent

When a spec or a delegated task produces UI, "done" is currently provable only by static code review — an agent can claim a screen works without ever loading it. This change makes a **visual contract** a first-class acceptance artifact in both SDD and the delegation gate: a UI-producing spec carries machine-checkable visual acceptance (authored at `plan`/`tasks` time, like fixtures), and a UI-producing delegated task names an `agent-browser.sh verify-contract`/`audit` pass as its `DONE_WHEN` proof. Crucially — per the spec-152 follow-up that motivated this — the contract is an **interaction trace**, not a screenshot/pixel diff: it must assert navigation (the screen is reachable), interactive exploration (named controls respond), and flow traversal (a named user flow runs end-to-end), in addition to static render. The hard problem this spec resolves is scoping the "UI-producing" trigger so it gates real UI work without over-gating backend/CLI/docs work, and doing it in a way that earns trust rather than getting rubber-stamped. This is the spec-152 follow-up #2; it builds on the now-consolidated, fail-closed `agent-browser` primitive (spec 152/153) and reuses the existing 5-field delegation gate.

## Acceptance criteria

_Observable outcomes as Given/When/Then scenarios for behavior, plain checkbox bullets for static facts._

- [ ] **Scenario: A UI change is declared and the heuristic agrees**
  - **Given** a spec/task whose author sets `UI impact: render|interaction|flow` and changes a rendered browser surface
  - **When** the validator runs
  - **Then** it expects visual-contract evidence for that depth and, if absent, emits a non-blocking `visual-contract-advisory` (it does not block the commit/turn in v1)

- [ ] **Scenario: A backend/CLI/docs change does not get gated**
  - **Given** a change that touches only backend, CLI, docs, tests, specs, migrations, or harness plumbing (no rendered browser surface) and is declared `UI impact: none`
  - **When** the validator runs
  - **Then** no visual-contract advisory or requirement fires (no over-gating)

- [ ] **Scenario: Likely-omitted UI declaration is flagged**
  - **Given** a change that touches a rendered browser surface (route/page/layout/component/template/CSS/token/nav/form/modal/focus) but is declared (or defaults to) `UI impact: none`
  - **When** the detection heuristic runs over the diff
  - **Then** it flags the likely omission as an advisory prompting the author to re-declare — it never silently sets the gate itself

- [ ] **Scenario: A delegated UI task must prove it drove the UI**
  - **Given** a sub-agent task whose brief declares UI work
  - **When** the delegation handoff is built and the task closes at `SubagentStop`
  - **Then** the 5 fields carry the proof — `DONE_WHEN` names the exact `agent-browser.sh verify-contract`/`audit`/flow command, `DELIVERABLE` names the evidence bundle path — and the close-out verifier checks for that evidence (no 6th field is added)

- [ ] **Scenario: Browser primitive unavailable is not a silent pass**
  - **Given** a UI-producing task whose contract requires `agent-browser` but the binary/Chrome is absent
  - **When** verification runs
  - **Then** the result is an explicit `unavailable` with risk noted (fail-closed per spec 152/153), never a green pass

- [ ] The visual contract asserts **semantic** conditions (DOM roles/names, a11y, console budget, route/URL, state) — screenshots are review artifacts, not a pixel-diff bar
- [ ] The three depth tiers are defined and cumulative: `render` (mount + required roles/names + console budget + responsive overflow) ⊂ `interaction` (+ named-control exercise, state changes, validation/focus) ⊂ `flow` (+ ordered traversal from a start route under a fixture/auth precondition, per-step URL/state assertions, terminal assertion, per-step evidence)
- [ ] `/product`'s design-time visual contract is reconciled (referenced as source material), not duplicated — SDD visual acceptance is the implementation-evidence counterpart
- [ ] The capability ships as `.agent0/` rules/hooks/tools (runtime-neutral, propagated by sync-harness), not as project-local memory

## Non-goals

- **Pixel-perfect / screenshot-diff comparison against mockups.** Screenshots are review artifacts only; the gate is semantic.
- **A hard blocking gate in v1.** v1 is advisory (matching `tdd-advisory`/`lint-advisory`/`typecheck-advisory`); hardening to a blocking gate is a separate future, dogfood-evidence-gated spec — explicitly NOT part of 155 (so 155 ships with no open follow-up).
- **A new 6th delegation field.** UI proof maps into the existing TASK/CONTEXT/CONSTRAINTS/DELIVERABLE/DONE_WHEN.
- **Re-running/owning app startup or fixture infrastructure.** The spec names where the app is served and how fixture/auth state is created; it does not build a generic dev-server/fixture framework.
- **Auto-authoring the interaction trace.** Who/what authors the contract is in scope to *decide*, but generating it automatically from the running app is not a v1 deliverable.

## Open questions

_All pre-flight questions resolved before locking `plan.md` — this spec is delivered with no deferred follow-ups (decisions + rationale in `plan.md` § Decisions). None remain open._

- [x] **Advisory→hard trajectory.** RESOLVED: v1 ships **advisory-only**, matching the `tdd/lint/typecheck` precedent. Hardening to a blocking gate is **explicitly out of scope** for 155 (a future, dogfood-evidence-gated spec) — not a deferred follow-up *of* 155. The rule doc records `UI impact: flow` as the pre-identified first hard-gate candidate (Codex's minority report) so the future spec inherits the reasoning.
- [x] **Detection glob set.** RESOLVED → `plan.md` § Decisions D2: concrete pattern set in `.agent0/tools/ui-impact-detect.sh`; declaration is a `**UI impact:**` line in `spec.md` (optional per task).
- [x] **Contract / fixture file format.** RESOLVED → reuse + extend the **existing** `agent-browser.sh verify-contract` fixture-spec (`{ required:[{role,name}], max_console_errors }`) with optional `interactions` and `flow` arrays for the deeper tiers; no parallel format invented (§ Decisions D3).
- [x] **`SubagentStop` evidence location.** RESOLVED → § Decisions D4: declared-UI tasks name the proof command in `DONE_WHEN`; `delegation-verify.sh` surfaces the advisory (already propagates validator stderr) and checks the evidence bundle's `report.json` for `.overall == "pass"`.
- [x] **Field name & placement.** RESOLVED → adopt `UI impact: none | render | interaction | flow`; lives in `spec.md` (default `none`), optional per task (§ Decisions D1).
- [x] **Interactive-verification flakiness.** RESOLVED → v1 advisory is non-blocking so flakiness cannot break a build; `flow`/`interaction` steps may carry `"flaky": true` to downgrade a step to advisory, plus documented timeout/retry guidance (§ Decisions D5).

## Context / references

- **Source deliberation:** `.agent0/meetings/visual-contracts-sdd-delegation-gate-2026-06-05T21-29-24Z/meeting.md` — decision-grade `/meeting` (blind commit/reveal, anchored ledger, minority report). Claude + Codex converged independently on the design synthesized here.
- `docs/specs/152-browser-primitive-consolidation/spec.md` — the spec this is follow-up #2 to; `agent-browser` as the primary browser primitive.
- `docs/specs/153-decouple-harness-from-playwright/spec.md` — fail-closed routing (no MCP fallback); why `unavailable` ≠ pass.
- `.agent0/tools/agent-browser.sh` — `verify-contract` / `audit` mechanism the contract runs on.
- `.agent0/context/rules/delegation.md` + `.agent0/hooks/delegation-gate.sh` + `.agent0/hooks/delegation-verify.sh` — the 5-field gate and `SubagentStop` verifier this extends.
- `.agent0/context/rules/spec-driven.md` — where `spec`/`plan`/`tasks` visual acceptance attaches.
- `.agent0/context/rules/tdd.md` (+ `lint-validator.md`, `typecheck-advisory.md`) — the non-blocking-advisory precedent v1 follows.
- `.claude/skills/product/` — the design-time visual contract (screen-atlas, fixture-spec) to reconcile with, not duplicate.
