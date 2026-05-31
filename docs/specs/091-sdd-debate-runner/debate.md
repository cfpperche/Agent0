# 091 — sdd-debate-runner — debate

_Created 2026-05-26._

**Initiating agent:** Codex CLI
**Reviewing agent:** {{reviewing agent name}}
**Initiated by:** Codex CLI session 2026-05-26

Cross-model review of `spec.md` between two tool-calling CLI agents in separate sessions, each running its own port of `/sdd debate`. Both agents read and write **this file directly**; no copy-paste, no broker.

**Roles:** the agent that scaffolded this file is the `initiating agent` (named above); the other runtime, when first invoked against this file, becomes the `reviewing agent` and fills its identity into the metadata block. Each agent's port determines its role on every invocation by comparing the `**Initiating agent:**` metadata to its own runtime-identity literal.

**Orchestration:** the human alternates which runtime is active and decides when the debate ends. Each agent's turn: read this file, find the next empty placeholder belonging to its role (`initiating agent (position)` / `initiating agent (counter)` for the initiator; `reviewing agent (critique)` for the reviewer), write it, save. Then the human invokes the other runtime.

**Stop criteria:** human-decided. Default suggested cadence is ~3 rounds; the human asks either agent to "synthesize" when the disagreement is exhausted or the value diminishes. If more than 3 rounds are useful, append `## Round 4 — ...` headers manually; the round-handling logic in both skills keys on placeholder presence, not round number.

**Audit trail:** this file IS the audit trail. Git-tracked alongside the spec. No separate state file.

---

## Round 1 — initiating agent (position)

### Intent

Agent0 should automate the already-designed `debate.md` workflow without replacing its core safety property: the markdown artifact remains the shared state and audit trail. The proposed v1 is a local sequential runner that invokes Claude Code and Codex headlessly, validates each turn, and stops at human decision points. It deliberately avoids a daemon, broker API, direct model API calls, or parallel agent writes.

### Top 3 acceptance scenarios

1. **Automated debate starts from a filled spec** — given a valid `spec.md` and no `debate.md`, the runner scaffolds debate metadata, invokes the initiating runtime for Round 1 position, invokes the reviewing runtime for Round 1 critique, and requires no manual prompt copy-paste.
2. **In-flight debate resumes the next correct turn** — given a partially filled `debate.md`, the runner detects the next empty slot, calls only the owning runtime, and passes a generated prompt naming the exact header to fill.
3. **Turn validation catches unsafe edits** — if a runtime edits the wrong slot, changes `spec.md`, or mutates files outside the allowed debate surface, the runner stops with a concrete diagnostic and does not continue to the next runtime.

### Top 3 open questions

1. Should a new debate require an explicit `--initiator`, or should the runner have a default runtime?
2. Should synthesis be a separate subcommand or a flag on the same command?
3. Should the implementation be shell for low dependency cost, or Python for safer markdown parsing, subprocess handling, and validation?

### Where the initiating agent wants pushback

- The v1 scope may still be too broad if starting, resuming, validating, and synthesizing all land in one implementation; push back if start/resume should ship first and synthesis automation should wait.
- The spec assumes local CLI subprocesses are the right first adapter layer; push back if Claude Agent SDK or a Codex SDK wrapper should be the initial abstraction instead.
- The validation contract is load-bearing: too strict and useful agent behavior fails; too loose and the runner loses trust. Push on the exact mutation surface.

---

## Round 1 — reviewing agent (critique)

_The reviewing agent reads this file, finds this slot empty, writes its critique directly. Should be concrete: name spec sections, quote unclear phrases, point to missing non-goals or weak acceptance scenarios._

{{round 1 critique — reviewing agent writes directly}}

---

## Round 2 — initiating agent (counter)

_The initiating agent addresses each critique point: accept (will change spec) / reject (with reasoning) / defer (open question)._

{{round 2 counter — initiating agent fills after reviewing agent writes critique}}

---

## Round 2 — reviewing agent (critique)

{{round 2 critique — reviewing agent writes directly, OR leave blank if user opted to synthesize}}

---

## Round 3 — initiating agent (counter)

{{round 3 counter — initiating agent fills if debate continues past round 2}}

---

## Round 3 — reviewing agent (critique)

{{round 3 critique — final reviewing-agent slot in the template; append Round 4+ headers manually if needed}}

---

## Synthesis

_Written when the human explicitly asks an agent to synthesize ("synthesize the debate", "wrap up"). Either agent can perform synthesis — whichever one the human asks. Lists what changes in `spec.md` and why; flags unresolved disagreements._

**Resolution:** {{converged | cap-reached | abandoned}}

**Proposed spec changes:**

- {{spec change 1 — section + delta}}
- {{spec change 2}}

**Unresolved disagreements:** (only if cap-reached or abandoned)

- {{disagreement 1 — initiating agent's view + reviewing agent's view + why no resolution}}

---

## Applied changes

_Filled after user confirms the synthesis. List the actual edits made to `spec.md` (or "synthesis rejected — no changes applied")._

- {{applied change 1 — file + section}}
