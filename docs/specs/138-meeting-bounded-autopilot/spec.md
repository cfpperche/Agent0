# 138 — meeting-bounded-autopilot

_Created 2026-06-02._

**Status:** draft — **shelved pending a demand test** (see § Demand test). This is a captured, sharpened design record, not a near-term build. The v1 *measurement* in § Acceptance / Near-term **shipped 2026-06-02** (`meeting.sh friction` + `state` friction lines + rule docs); the autopilot build itself stays deferred until three qualifying meetings.

## Intent

Capture the design for a future **opt-in "bounded loop runner"** mode of the `/meeting` skill (spec 136), in which one runtime drives up to N model turns by round-robin *without* a human dispatching each turn, then halts at a mandatory checkpoint. This is the "LLM-as-orchestrator" mode spec 136 deferred. Two deliberate framings, both products of a cross-model review (see Context):

- **It is not built now.** A flag that exists gets used *because it exists*, which would contaminate the very demand test that justifies it. So the build is gated behind a rule-of-three demand test (§ Demand test); the only thing that ships near-term is the **friction measurement** that makes that demand test evaluable from real v1 artifacts.
- **v1 autopilot is a "bounded loop runner," not an "orchestrator."** It has no LLM speaker-selection authority — it round-robins. Calling it an orchestrator oversells it. (Context-driven speaker selection is a later, separate question.)

It remains additive (v1 human-orchestrated stays the default and is untouched) and runtime-neutral *at the script/protocol layer* (see the dual-runtime acceptance below) — not "any runtime" in the loose sense: each runtime port must implement the same `meeting run` loop and bridge contracts.

## Demand test (gate before any build)

No `plan.md` and no implementation until the demand is shown. A **qualifying meeting** is a real v1 meeting where BOTH hold:

1. The human dispatched **≥4 consecutive model turns** without taking a turn or redirecting (measured mechanically — see Near-term acceptance), AND
2. The human explicitly recorded that they wanted it to continue **unattended** (a human turn or note saying so).

**Three qualifying meetings** reopen planning. Until then, this spec stays a draft design record.

## Acceptance criteria

### Near-term (ships now — the measurement only)

- [x] **Scenario: v1 records autopilot-friction signal**
  - **Given** a v1 human-orchestrated meeting
  - **When** the human dispatches several model turns in a row without intervening
  - **Then** `meeting.sh state` surfaces a **"N consecutive model turns without human intervention"** signal computed from the transcript, so a qualifying meeting (§ Demand test) can be identified from the artifact rather than memory _(shipped: `meeting.sh friction` + `model_turns`/`max_consecutive_model_turns`/`current_model_streak` in `state`; tests in `.agent0/tests/meeting/07-friction.sh`)_
- [x] The § Demand test definition is documented in `.agent0/context/rules/meeting.md` so contributors know what evidence reopens this spec _(§ Autopilot demand test)_

### Deferred (the build — only after the demand test passes; sharpened here so it's ready)

- [ ] **Scenario: Bounded loop runner with a real budget guard** — `/meeting run --turns N --confirm-cost-usd X` refuses to start without the cost ceiling; before each peer subprocess it **refuses the next turn when remaining budget < a conservative worst-case estimate** (the ceiling is real, not a consent label); `cost-spent` increments after each turn, and subprocess failure / unknown spend are represented explicitly (not silently zero)
- [ ] **Scenario: Mechanical-only scope-jump gate** — explicit operations hard-stop for human approval regardless of turn count: `--add-participant`, `--web`, `--objective`, and any roster/header mutation. Semantic objective drift is a **post-hoc advisory**, never a guaranteed gate (intent is not observable in a transcript)
- [ ] **Scenario: Cap + cumulative ceiling** — a run halts at the cap (default 4) with a runtime-neutral 3-action gate (synthesize / continue-with-new-explicit-cap / abandon), no auto grace turn; a per-run hard ceiling (8) AND a **per-meeting cumulative autopilot ceiling** both apply; continuing past the cumulative ceiling requires a **new objective + a fresh human-written rationale** (so "continue-with-new-cap" can't become a ritual bypass)
- [ ] **Scenario: Dual-direction runtime neutrality (observable)** — Claude Code orchestrates Codex turns via `codex-exec` AND Codex CLI orchestrates Claude turns via `claude-exec`; in both directions peers run read-only and only the active runtime appends. Proven both ways, not asserted
- [ ] v1 human-orchestrated flow is unchanged; autopilot is additive and opt-in

## Non-goals

- **Not built until the demand test passes.** This spec ships only the measurement; the loop runner waits for three qualifying meetings.
- **No LLM speaker-selection in v1 autopilot.** Round-robin only — it is a bounded loop runner, not a context-driven orchestrator. AutoPattern-style selection is a separate, later question.
- **Not the default mode**, and **no unbounded looping** (per-run cap + per-run ceiling + per-meeting cumulative ceiling + human checkpoints).
- **No removal/change of v1.** The v1 turn loop, transcript core, and state/content split are untouched.
- **Not "any runtime" portability in the loose sense** — neutrality is at the script/protocol layer once each port implements the same loop.

### In-scope protocol surface (acknowledged, not hidden under "no new infra")

These are durable `meeting.md` header fields the build adds (no daemon/broker — but real new protocol surface): `mode`, `cap`, `hard_ceiling`, `cumulative_ceiling`, `orchestrator`, `cost_spent`, checkpoint outcomes, and recorded scope-jump approvals.

## Open questions

- [x] **Prototype timing — RESOLVED (rule-of-three before prototype).** Do not build the prototype until three qualifying meetings (§ Demand test) prove manual alternation is the bottleneck. Resolved in the debate on the contamination argument: a flag that exists gets used because it exists, poisoning the demand signal.
- [ ] **Worst-case per-turn cost estimate.** What conservative bound does the budget guard use to decide "remaining budget can't cover the next turn"? (Depends on model + transcript length + tool use; resolve at plan time, post-demand-test.)
- [ ] **Cumulative-ceiling number.** What is the per-meeting cumulative autopilot-turn ceiling (vs the per-run hard ceiling of 8)? (Owner: founder, at plan time.)

## Context / references

- **Design source:** the cross-model `/meeting` deliberation `.agent0/meetings/v2-meeting-llm-orchestrator-mode-20260602T160554Z/meeting.md` (Claude Code + Codex CLI; synthesis accepted, graduated here) — the first real dogfood of `/meeting`.
- **Cross-model review of THIS spec:** `docs/specs/138-meeting-bounded-autopilot/debate.md` (initiating: Claude Code; reviewing: Codex CLI; resolution: converged — "don't build now + sharpen", all 8 points accepted).
- **Parent capacity:** spec 136 (`docs/specs/136-meeting/`) — the v1 `/meeting` skill + its `debate.md`.
- **Prior art:** [AutoGen/AG2 Group Chat `max_round` bounding](https://docs.ag2.ai/latest/docs/user-guide/advanced-concepts/groupchat/groupchat/); [Du et al., multi-agent debate (arXiv:2305.14325)](https://arxiv.org/abs/2305.14325).
- **Rules:** `.agent0/context/rules/meeting.md`, `.agent0/context/rules/runtime-capabilities.md`.
