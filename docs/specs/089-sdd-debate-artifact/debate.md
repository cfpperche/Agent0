# 089 — sdd-debate-artifact — debate

_Created 2026-05-26._

**Initiating agent:** Claude Code
**Reviewing agent:** {{reviewing agent name}}
**Initiated by:** Claude Code session 2026-05-26

Cross-model review of `spec.md` between two tool-calling CLI agents in separate sessions, each running its own port of `/sdd debate`. Both agents read and write **this file directly**; no copy-paste, no broker.

**Roles:** the agent that scaffolded this file is the `initiating agent` (named above); the other runtime, when first invoked against this file, becomes the `reviewing agent` and fills its identity into the metadata block. Each agent's port determines its role on every invocation by comparing the `**Initiating agent:**` metadata to its own runtime-identity literal.

**Orchestration:** the human alternates which runtime is active and decides when the debate ends. Each agent's turn: read this file, find the next empty placeholder belonging to its role (`initiating agent (position)` / `initiating agent (counter)` for the initiator; `reviewing agent (critique)` for the reviewer), write it, save. Then the human invokes the other runtime.

**Stop criteria:** human-decided. Default suggested cadence is ~3 rounds; the human asks either agent to "synthesize" when the disagreement is exhausted or the value diminishes. If more than 3 rounds are useful, append `## Round 4 — …` headers manually; the round-handling logic in both skills keys on placeholder presence, not round number.

**Audit trail:** this file IS the audit trail. Git-tracked alongside the spec. No separate state file.

---

## Round 1 — initiating agent (position)

_Pre-populated from `spec.md` key claims at scaffold time. Structure: intent (1 paragraph) → top 3 acceptance scenarios → top 3 open questions → "where the initiating agent wants pushback"._

### Intent

Add a 5th artifact `debate.md` to the SDD pipeline and a `/sdd debate` subcommand that orchestrates a cross-model review of `spec.md` between two tool-calling CLI agents in separate sessions, each running its own port of the skill. The agent that invokes `/sdd debate` first becomes the `initiating agent`; the other runtime, when first invoked against the same file, becomes the `reviewing agent`. Both agents read and write `debate.md` directly. The file carries identity metadata so each port can detect its role on every invocation.

### Top 3 acceptance scenarios

1. **This runtime initiates** — Given a filled `spec.md` and no prior `debate.md`; When `/sdd debate` is invoked; Then the file is scaffolded with metadata block filled (`**Initiating agent:** Claude Code`, `**Reviewing agent:**` placeholder, `**Initiated by:**` runtime + session label) and Round 1 — initiating agent (position) pre-populated.
2. **Re-invocation by initiating agent writes counter** — Given `**Initiating agent:**` matches this port's identity, the latest critique slot is filled and the next counter slot is empty; When the user re-invokes `/sdd debate`; Then the skill detects the initiator role, classifies each critique point accept/reject/defer, fills the counter placeholder.
3. **Re-invocation by reviewing agent writes critique** — Given `**Initiating agent:**` is some other runtime's identity, the latest counter slot is filled and the next critique slot is empty; When the user invokes `/sdd debate`; Then the skill detects the reviewer role, writes a concrete critique into the placeholder, and on first reviewer write replaces `**Reviewing agent:**` with this port's identity.

### Top 3 open questions

1. Should Round 1 pre-population be the full `spec.md` body or a structured summary? **Default: structured summary** (intent + top scenarios + top open questions + pushback hint).
2. Should the synthesis section auto-apply spec edits or always require human confirmation? **Default: always confirm.**
3. Position in pipeline — strictly between `spec` and `plan`, or any time? **Default: any time, recommended between spec and plan.**

### Where the initiating agent wants pushback

- Is the runtime-identity literal (`Claude Code`) the right grain, or should it parametrize a tighter identifier (model version, session ID)? Today's design is "human-readable port name"; precision is gained only if collisions surface.
- The role detection is monotonic per invocation — read metadata, compute role, write. No handshake, no negotiation. Edge case: if a port mis-identifies itself (e.g. a Codex port copy-pasted the Claude port code without updating the identity literal), debates could fail silently. Should the metadata block carry a self-test contract a port can run to verify its identity is correct?
- The template ships with 3 round slots; the Step 6 rule allows manual extension. Should a future `/sdd debate --extend` flag automate Round-N+1 header append, or is manual append fine?

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
