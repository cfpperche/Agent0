# 089 — sdd-debate-artifact — debate

_Created 2026-05-25._

Cross-model review of `spec.md`. Claude (one session) vs another tool-calling CLI agent (separate session — e.g. Codex CLI, Cursor, Aider — that ports its own `/sdd debate` equivalent). Both agents read and write **this file directly**; no copy-paste, no broker.

**Orchestration:** the human alternates which agent is active and decides when the debate ends. Each agent's turn: read this file, find the next empty placeholder belonging to its side (`Claude (position)` / `Claude (counter)` vs `external (critique)`), write it, save. Then the human invokes the other agent.

**Stop criteria:** human-decided. Default suggested cadence is ~3 rounds; the human asks an agent to "synthesize" when the disagreement is exhausted or the value diminishes. If more than 3 rounds are useful, append `## Round 4 — …` headers manually; the round-handling logic in both skills keys on placeholder presence, not round number.

**Audit trail:** this file IS the audit trail. Git-tracked alongside the spec. No separate state file.

---

## Round 1 — Claude (position)

_Pre-populated from `spec.md` key claims at scaffold time. Structure: intent (1 paragraph) → top 3 acceptance scenarios → top 3 open questions → "where I want pushback"._

### Intent

Add a 5th artifact `debate.md` to the SDD pipeline and a `/sdd debate` subcommand that orchestrates a cross-model review of `spec.md` between the live Claude session and an external model (default: GPT-5), with the human acting as the broker (copy-paste loop). The goal is to catch spec ambiguities, hidden assumptions, and weak acceptance criteria that a single model misses — productive disagreement before `plan.md` is locked, when the cost of change is still markdown-cheap.

Posture is **broker-human, zero-infra**: no API key, no MCP server, no script orchestrator. If the discipline proves valuable after ≥3 real debates that produced spec edits, that's the trigger to consider promoting to a direct-API path.

### Top 3 acceptance scenarios

1. **Scaffold debate.md from active spec** — Given a spec dir with filled `spec.md`; When `/sdd debate` is invoked; Then `debate.md` is created with Round 1 (Claude's position) pre-populated from `spec.md` key claims (intent + top 3 acceptance scenarios + top 3 open questions).
2. **Hard cap at 3 rounds** — Given the debate has reached Round 3 with no convergence; When Claude would write Round 4; Then Claude STOPS, writes `## Synthesis` summarizing unresolved disagreements + proposed spec changes, and asks the user to accept / edit / reject.
3. **Refuse mid-debate re-invocation** — Given `debate.md` exists without a `## Synthesis` section; When the user re-invokes `/sdd debate`; Then the skill warns "debate already in flight" and exits without overwriting.

### Top 3 open questions

1. Should Round 1 pre-population be the full `spec.md` body or a structured summary? **Default: structured summary.**
2. Should the synthesis section auto-apply spec edits or always require human confirmation? **Default: always confirm.**
3. Position in pipeline — strictly between `spec` and `plan`, or any time? **Default: any time, recommended between spec and plan.**

### Where I want pushback

- Is the 3-round hard cap the right number, or is 2 enough? A 3-round cap was chosen to match a "position → critique → counter → critique → counter → critique" arc (Claude gets 2 counters, external gets 3 critiques). Two would compress to "critique → counter → critique"; arguably enough if convergence is the goal, but loses one cycle of refinement.
- Is `debate.md` correctly scoped to `spec.md` only, or should it support debating `plan.md` and `tasks.md` too? The non-goal says spec-only for v1; the argument for plan/tasks debate is that those artifacts also benefit from cross-model review of approach and decomposition.
- The "broker-human" posture is friction-heavy. Is the rule-of-three demand-test threshold (3 successful debates → revisit API path) too high, too low, or right?

---

## Round 1 — external (critique)

_User pastes the external model's response verbatim here. Claude does not edit; only appends._

{{round 1 critique — paste verbatim from external model}}

---

## Round 2 — Claude (counter)

_Claude addresses each critique point: accept (will change spec) / reject (with reasoning) / defer (open question)._

{{round 2 counter — Claude fills after pasting critique}}

---

## Round 2 — external (critique)

{{round 2 critique — paste verbatim from external model, OR leave blank if user opted to synthesize}}

---

## Round 3 — Claude (counter)

{{round 3 counter — Claude fills if not yet converged}}

---

## Round 3 — external (critique)

{{round 3 critique — final external round before hard cap}}

---

## Synthesis

_Claude writes this when: (a) convergence reached (no new critique points in latest round), OR (b) Round 3 cap hit. Lists what changes in `spec.md` and why; flags unresolved disagreements._

**Resolution:** {{converged | cap-reached | abandoned}}

**Proposed spec changes:**

- {{spec change 1 — section + delta}}
- {{spec change 2}}

**Unresolved disagreements:** (only if cap-reached)

- {{disagreement 1 — Claude's view + external view + why no resolution}}

---

## Applied changes

_Filled after user confirms the synthesis. List the actual edits made to `spec.md` (or "synthesis rejected — no changes applied")._

- {{applied change 1 — file + section}}
