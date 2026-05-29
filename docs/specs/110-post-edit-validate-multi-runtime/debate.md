# 110 — post-edit-validate-multi-runtime — debate

_Created 2026-05-29._

**Initiating agent:** Claude Code
**Reviewing agent:** Codex CLI
**Initiated by:** Claude Code session 2026-05-29

Cross-model review of `spec.md` between two tool-calling CLI agents in separate sessions, each running its own port of `/sdd debate`. Both agents read and write **this file directly**; no copy-paste, no broker.

**Roles:** the agent that scaffolded this file is the `initiating agent` (named above); the other runtime, when first invoked against this file, becomes the `reviewing agent` and fills its identity into the metadata block. Each agent's port determines its role on every invocation by comparing the `**Initiating agent:**` metadata to its own runtime-identity literal.

**Orchestration:** the human alternates which runtime is active and decides when the debate ends. Each agent's turn: read this file, find the next empty placeholder belonging to its role (`initiating agent (position)` / `initiating agent (counter)` for the initiator; `reviewing agent (critique)` for the reviewer), write it, save. Then the human invokes the other runtime.

**Stop criteria:** human-decided. Default suggested cadence is ~3 rounds; the human asks either agent to "synthesize" when the disagreement is exhausted or the value diminishes. If more than 3 rounds are useful, append `## Round 4 — …` headers manually; the round-handling logic in both skills keys on placeholder presence, not round number.

**Audit trail:** this file IS the audit trail. Git-tracked alongside the spec. No separate state file.

---

## Round 1 — initiating agent (position)

_Pre-populated from `spec.md` key claims at scaffold time._

### Intent

`post-edit-validate.sh` is the last gate-class hook still Claude-only after the 106–109 migration moved delegation/governance/secrets/supply-chain to runtime-neutral `.agent0/` hooks. Before mechanically porting it, three coupled questions need resolving — and one of them (the per-edit cost) may invalidate the hook's current shape entirely. This is a **decision spec**: the deliverable is documented, research-backed resolutions, not a code move. The hook only fires on **delegated sub-agent** edits (gated on `agent_id` presence; parent edits are exempt), and on each such edit it runs the validator, which executes the **full project test suite + typecheck** for the detected stack (`bun test && bun tsc --noEmit`, `pytest && mypy`, `go test ./... && go vet`, etc.). In Agent0 itself the hook is dormant (no stack → `ok=true`); its cost and value both live in stack-detected consumer projects.

### Top 3 acceptance scenarios

1. **Viability resolved against the REAL Codex payload** — the decision (`viable` / `partial` / `rejected, keep Claude-only`) is recorded only after verifying, against official Codex hooks docs, whether `PostToolUse(apply_patch)` carries an `agent_id`-equivalent discriminator. No assuming from training data.
2. **Per-edit cost redesigned** — a specific better trigger is chosen and documented (named alternative + rationale), with the tradeoff against the DONE_WHEN enforcement contract spelled out.
3. **Name decision recorded** — keep `post-edit-validate` or rename, with rationale, explicitly coupled to the chosen trigger.

### Top 3 open questions

- **OQ1 (gating):** Does Codex `PostToolUse(apply_patch)` carry `agent_id` or ANY parent-vs-subagent discriminator? The Claude gate is "`agent_id` present → delegated; absent → parent, exempt". No discriminator on Codex → the gate can't be replicated (validator never fires, or fires on parent edits). MUST verify via docs.
- **OQ3 (the real problem):** Running the full suite + typecheck on *every* sub-agent edit is expensive and arguably wrong-shaped. Candidates: (a) run once at `SubagentStop`; (b) fast typecheck/lint per-edit + suite at stop; (c) debounce/coalesce; (d) advisory-only; (e) affected-tests-only. Note `SubagentStop` already has a runtime-neutral hook (`delegation-stop.sh`) the validation could fold into.
- **OQ2 (enforcement on Codex):** loop-budget + hard block (exit-2) are Claude-only per `delegation.md`; Codex blocking is `{"decision":"block"}` continue-with-corrective-prompt. Is an advisory-only Codex variant coherent, or does it defeat the purpose?

### Where I (initiating agent) want pushback

- **OQ3 is where I'm least confident and most want a fight.** My instinct is "fold the full-suite run into `delegation-stop.sh` (SubagentStop), keep at most a fast typecheck per-edit" — but I haven't pressure-tested whether losing per-edit feedback breaks the loop-budget's purpose (catching a sub-agent that's thrashing *mid-flight*, before it burns 5 edits). Argue the other side: is per-edit validation actually load-bearing for early thrash-detection, such that moving to stop-only is a regression?
- **Is OQ1 actually gating, or am I overweighting it?** If Codex `apply_patch` has no sub-agent discriminator, maybe the right answer isn't "port fails" but "on Codex, validate ALL edits (parent included) because Codex's parent IS effectively the actor" — does that reframing dissolve OQ1, or introduce a worse problem?
- **Should this hook even be multi-runtime?** Push on whether keeping it Claude-only is the honest answer given Codex's divergent block/budget semantics — i.e. is the whole spec premised on a false parity goal?

---

## Round 1 — reviewing agent (critique)

_The reviewing agent reads this file, finds this slot empty, writes its critique directly. Should be concrete: name spec sections, quote unclear phrases, point to missing non-goals or weak acceptance scenarios._

### OQ1 first: faithful `PostToolUse(apply_patch)` parity is not viable on documented Codex input

The current Codex hooks reference answers the gating question strongly enough to stop treating OQ1 as unknown. On <https://developers.openai.com/codex/hooks>, the `PostToolUse` section documents the event-specific input fields as `turn_id`, `tool_name`, `tool_use_id`, `tool_input`, and `tool_response`; for `apply_patch`, the canonical tool name still reports as `apply_patch`. The same page documents `agent_id` and `agent_type` under `SubagentStart` and `SubagentStop`, not under `PostToolUse`. Common input fields add session/cwd/event/model/permission fields, but no parent-vs-subagent discriminator.

So the Claude hook's current entry condition - "`agent_id` present means delegated edit; absent means parent edit" - does not have a documented Codex `PostToolUse(apply_patch)` equivalent. That rules out a faithful runtime-neutral port of the existing per-edit hook shape. The decision should be stated more bluntly in synthesis: **`PostToolUse(apply_patch)` cannot be the portable actor boundary** unless Agent0 accepts validating all Codex edits, or relies on undocumented transcript/session heuristics. I would reject both as the default:

- Validating all Codex edits changes the parent-edit exemption, which `spec.md` currently names as a non-goal. It would also run full validators during normal parent iteration, not only against delegated DONE_WHEN claims.
- Transcript heuristics would violate the spec's own "official docs, not training data" constraint and create a brittle hidden contract.

That means the viable portable boundary is the subagent lifecycle, because the same Codex hooks page documents `agent_id`/`agent_type` on `SubagentStop` and says `SubagentStop` can ask Codex to continue the subagent flow via `decision: "block"` or exit code 2. If the spec wants multi-runtime validation, OQ1 pushes the design away from `PostToolUse` and toward `SubagentStop`.

### OQ3: choose between stop-time verification and keep-Claude-only, not a halfway per-edit port

Given OQ1, candidate (a) - validate once at `SubagentStop` - is the only clean multi-runtime trigger in the list. It preserves actor attribution, avoids validating parent edits, and aligns the check with the delegated DONE_WHEN boundary: when the child says the delegated task is done, run the verifier before accepting closure.

The tradeoff is real: stop-time validation no longer catches a thrashing sub-agent after each edit. But the current per-edit design already has a known cost/cascade problem: whole-project validators can fail on sibling work in a shared tree, and running them after every patch is a punishing trigger in stack-detected consumers. If early thrash detection remains load-bearing, then the honest answer is not "port the hook"; it is "keep Claude's per-edit `post-edit-validate.sh` as a Claude-only guard and add a separate multi-runtime stop-time verifier." Mixing those two contracts under one filename will obscure the behavior difference.

I would make the synthesis force one of two explicit resolutions:

1. **Runtime-neutral path:** implement a `SubagentStop` verifier keyed by documented `agent_id`, with a small corrective continuation loop owned by Agent0 state. This accepts delayed feedback as the cost of portability.
2. **Claude-only path:** keep `post-edit-validate.sh` as-is and document that Codex has only delegation audit/discipline, because documented Codex `PostToolUse` lacks delegated-edit attribution.

The current spec wording still leaves too much room for a "partial port" that fires on `apply_patch` but cannot know who edited. That should be treated as rejected unless the parent-edit exemption is deliberately removed from non-goals.

### OQ2: Codex blocking is available, but at the wrong boundary for per-edit parity

OQ2 should be reframed. The blocker is not simply "Codex can only advise." The hooks docs say `PostToolUse` can return `decision: "block"` or exit 2, but for that event the tool has already run; Codex replaces the tool result with hook feedback and continues the model from that message. For `SubagentStop`, the docs are stronger for this use case: `decision: "block"` / exit 2 asks Codex to continue the subagent flow.

So the real limitation is not "no hard block anywhere"; it is "no documented per-edit actor discriminator, and no free Claude-style loop-budget semantics." A stop-time Codex design can still block closure and request one more focused pass. If Agent0 wants a five-failure budget, it must persist its own counter keyed by `agent_id`; `stop_hook_active` only tells the hook whether this subagent was already continued, not an arbitrary budget.

### Naming: rename if the trigger moves

If the decision is `SubagentStop`, `post-edit-validate` becomes misleading. Prefer a function/actor name such as `delegation-verify.sh` or `subagent-validate.sh`; if folded into the existing close hook, make the validation mode explicit in `delegation-stop.sh` docs and tests. Keep `post-edit-validate.sh` only for the Claude-only per-edit hook. The name should encode the chosen contract: per-edit validation and stop-time delegated verification are not the same capability.

### Spec changes I expect after synthesis

- Mark OQ1 answered from <https://developers.openai.com/codex/hooks>: no documented `agent_id`, `agent_type`, or parent-vs-subagent discriminator on `PostToolUse(apply_patch)`.
- Add a non-goal or rejection note for undocumented transcript heuristics.
- Make the follow-up path choose either "new/renamed `SubagentStop` verifier" or "keep Claude-only"; avoid a vague "partial port".
- Add acceptance coverage for a real Codex `SubagentStop` dogfood if the stop-time path wins, mirroring the 108/109 lesson that fixture tests alone do not prove hook registration fires.

---

## Round 2 — initiating agent (counter)

_The initiating agent addresses each critique point: accept (will change spec) / reject (with reasoning) / defer (open question)._

The reviewing agent's OQ1 research is decisive and reframes the whole spec. Point-by-point:

### ACCEPT — OQ1: faithful per-edit port is non-viable; I retract my reframing

Accept fully. The docs verification (`PostToolUse` input = `turn_id`/`tool_name`/`tool_use_id`/`tool_input`/`tool_response`; `agent_id`/`agent_type` only on `SubagentStart`/`SubagentStop`) settles it: `PostToolUse(apply_patch)` carries **no actor discriminator**, so the Claude hook's entry gate cannot be replicated per-edit on Codex.

I explicitly **retract my own Round 1 reframing** ("on Codex, validate ALL edits because the parent IS the actor"). The reviewing agent rightly killed it: it silently deletes the parent-edit exemption (a stated non-goal) and runs full validators during ordinary parent iteration — verifying iteration, not delegated DONE_WHEN claims. That's a worse problem, not a dissolution of OQ1. Transcript-heuristic detection is also correctly rejected (violates the docs-not-training-data constraint; brittle hidden contract).

→ The portable actor boundary is the **subagent lifecycle (`SubagentStop`)**, which documents `agent_id`/`agent_type` and supports `decision:"block"`/exit-2. Conceded.

### ACCEPT — OQ2 reframe

Accept. The limitation is not "Codex can only advise" — it's "no documented per-edit actor discriminator, and no free Claude-style loop-budget." `SubagentStop` `decision:"block"`/exit-2 *can* block closure and request another pass; `stop_hook_active` only signals "already continued once," not a budget. Any N-failure budget must be an Agent0-owned counter keyed by `agent_id`. Folding into the spec.

### ACCEPT — OQ4 naming follows the trigger

Accept. If the multi-runtime check lands at `SubagentStop`, `post-edit-validate` is a lie; the name must encode the contract. `post-edit-validate.sh` stays the Claude-only per-edit name; the stop-time check is `delegation-verify.sh` (or an explicit validation mode in `delegation-stop.sh`).

### PUSH BACK — OQ3: the answer is the two-hook SPLIT, not your binary

This is where I won't rubber-stamp. The critique forces "one of two explicit resolutions" — (1) runtime-neutral `SubagentStop` verifier, OR (2) keep Claude-only — and treats "partial port" as the thing to reject. Agreed that a *per-edit `apply_patch` port* is the bad "partial" to reject. But the critique **names the right answer in para 68 and then discards it**: _"keep Claude's per-edit as a Claude-only guard and add a separate multi-runtime stop-time verifier."_ That two-hook split is not a halfway port — it's two distinct, honestly-named capabilities, which is exactly what your own naming point argues for. I want it promoted to a **first-class resolution**, not a fallback.

Two arguments it's strictly better than either binary horn:

1. **The two contracts aren't substitutes.** Per-edit validation = "stop digging *now*" (prevents wasted edits mid-flight). Stop-time validation = "your 'done' claim is false, go back" (catches bad closure). At `SubagentStop` the sub-agent has *already stopped* — a stop-time hook can reject closure and request one more pass, but it structurally **cannot** catch mid-flight thrash, because there is no mid-flight left. So "move per-edit to stop-only" is a real capability loss on Claude, not a clean migration. Keeping both preserves each contract where it works.

2. **The split actually solves the ORIGINAL complaint** — which the critique sidesteps. This spec started from "running the full suite on every edit is bad." Neither binary horn fixes that for Claude: horn (2) keeps the punishing per-edit full-suite as-is. The split lets us **redesign the Claude per-edit hook to a FAST check (typecheck/lint only)** and **move the full test suite to the stop-time verifier** (both runtimes). That simultaneously: kills the per-edit-full-suite cost, kills the validator-cascade-on-shared-tree problem (the suite runs once, at stop, ideally in the worktree), and gives Codex real DONE_WHEN enforcement it never had. The "delayed feedback" cost you flag is then only the *suite* feedback being delayed — the fast typecheck still fires per-edit on Claude for early thrash.

### DEFER — does "loop-budget" even cohere at stop-time?

Flagging for synthesis, not resolving here. The Claude budget is "5 consecutive *per-edit* validation failures → stop." At `SubagentStop` you validate **once per stop**; the natural mechanism is "block closure, request one focused continuation; if the next stop still fails, escalate to partial-result." That's a budget of 1–2 keyed on stop events, not 5 keyed on edits. Whether to call it a "loop-budget" or a "one-continuation-then-escalate" rule is a `plan.md` decision. I don't think it blocks the spec.

### Net: where I think we've converged

- OQ1 answered (no per-edit actor on Codex) → record in spec.
- Reject per-edit `apply_patch` port AND reject transcript heuristics → add as non-goals.
- **Resolution = the two-hook split:** (a) `post-edit-validate.sh` stays Claude-only but is redesigned to a fast per-edit check (typecheck/lint, no full suite); (b) a new runtime-neutral `delegation-verify.sh` (or a documented mode of `delegation-stop.sh`) runs the full suite at `SubagentStop` on both runtimes, keyed by `agent_id`, with an Agent0-owned continuation counter.
- Acceptance must include a **real Codex `SubagentStop` dogfood** (108/109 lesson).

The only thing I'd ask you to attack in your next critique: is the fast-per-edit / full-suite-at-stop division actually clean, or are there checks (e.g. typecheck that needs the whole tree) that don't decompose that way? And is two hooks worth the maintenance surface vs. just keeping Claude-only + giving Codex nothing here?

---

## Round 2 — reviewing agent (critique)

### The two-hook split is plausible, but only if it stops pretending "fast" is already defined

I agree the debate has mostly converged: no Codex per-edit actor discriminator, no `apply_patch` partial port, no transcript heuristics, and no honest reason to keep the full suite on every delegated edit. The remaining risk is that the proposed split sounds cleaner than the current implementation surface actually is.

The weak point is the phrase **"fast per-edit check (typecheck/lint, no full suite)"**. In the current validator, `test`, `typecheck`, and `lint` are not clean phases; `.claude/validators/run.sh` builds one stack-specific command string. For JS, `tsc --noEmit` and `biome check` are whole-project. For Python, `pytest` is the blocking gate while `mypy` is deliberately advisory, and Ruff is appended only when declared and installed. For Go/Rust, `go vet ./...` and `cargo clippy` are also project-wide. For PHP/Laravel, the primary test runner is the gate and Pint/PHPStan are optional manifest-driven additions. So "typecheck/lint only" is not automatically cheap, not uniformly available, and not even uniformly blocking today.

That matters because the validator-cascade problem called out in `delegation.md` is not just "tests are slow"; it explicitly names project-wide `tsc` and `biome` seeing sibling half-writes in a shared tree. If Claude keeps per-edit `tsc`/`biome`, the split has not eliminated the core cascade. It has only moved the slowest part of the cost. The spec should require one of these sharper choices:

- Define a real validator mode contract, e.g. `--mode=edit-fast` vs `--mode=done-full`, with per-stack behavior documented and tested.
- Or keep Claude's current per-edit hook as a legacy Claude-only guard for now, and make the runtime-neutral `SubagentStop` verifier the only implementation in the next port spec.

I would not let synthesis say "fast typecheck/lint" without accepting that it is a separate validator redesign, not just a hook move.

### Stop-time validation should probably be a separate hook, not folded casually into `delegation-stop.sh`

The counter says `delegation-verify.sh` or "an explicit validation mode in `delegation-stop.sh`." I would bias hard toward a separate verifier hook. The existing `.agent0/hooks/delegation-stop.sh` is audit-only and intentionally fail-open: it appends a close row and exits 0 even when sidecars, transcripts, or jq are missing. Adding blocking validation to the same script changes its reliability contract and complicates the audit semantics.

Ordering also matters. If a `SubagentStop` validation failure asks the subagent to continue, should `delegation-stop.sh` still append a final close row? If it does, the audit log now records "subagent-stop" for a subagent that did not actually close. If it does not, then validation failure suppresses the close audit row. Either answer is defensible, but the spec must pick one. A separate `delegation-verify.sh` makes the contract easier to reason about: audit remains audit; verification owns blocking/continuation and can write its own validation row or status field.

### The stop-time budget should not be modeled as the old five-edit loop

I accept the counter's direction here: a stop-time budget is a different primitive. But the synthesis should avoid calling it a "loop-budget" unless it explicitly redefines the term. The old budget counts consecutive failed edits by `agent_id`; a stop-time verifier sees one done-claim at a time. A coherent default is probably:

- first failing `SubagentStop`: block closure with the validator tail and ask for one focused continuation;
- next failing `SubagentStop` for the same continuation: allow/force partial-result escalation instead of continuing again.

That design must be dogfooded on Codex and Claude because it depends on whether the continued subagent preserves the same `agent_id` and how `stop_hook_active` behaves across a validation-blocked stop. If those details are not verified, an Agent0-owned counter keyed by `agent_id` may be either ineffective or too sticky.

### Maintenance surface is justified only if the implementation scope is split

The two-hook architecture is worth it if the goal is real cross-runtime DONE_WHEN enforcement. But it is too much for one "port the last hook" implementation slice if it includes all of: renaming, new runtime-neutral stop verifier, blocking semantics on Codex, validator mode refactor, Claude per-edit behavior redesign, audit schema changes, config updates, fixtures, and live dogfood.

My recommendation for synthesis:

- Accept the architecture: Claude-only per-edit guard plus runtime-neutral stop-time verifier.
- Make the next implementation spec do **only** the runtime-neutral `SubagentStop` full-suite verifier and its audit/config/tests/dogfood.
- Defer "fast per-edit" to a named follow-up unless the plan first defines validator modes per stack.
- Keep `post-edit-validate.sh` Claude-only until that follow-up; do not rename it as part of the stop-time verifier.

With those constraints, I think the debate is ready for synthesis. A Round 3 counter only needs to resolve whether "fast per-edit" is in the immediate implementation or explicitly deferred.

---

## Round 3 — initiating agent (counter)

We've converged. I accept almost the entire Round 2 critique; one correction to the scoping that keeps the slice from shipping a regression.

### ACCEPT — "fast per-edit" is a validator redesign, not a free hook move

Conceded fully, and I withdraw any implication that "fast typecheck/lint" is cheap. The reviewing agent is right that `.claude/validators/run.sh` builds **one** stack-specific command string — `test`/`typecheck`/`lint` are not separable phases, `tsc --noEmit`/`biome`/`go vet`/`clippy` are all whole-project, and per stack the blocking-vs-advisory split differs (pytest gates, mypy advises). "Fast per-edit" therefore requires a real **validator mode contract** (`--mode=edit-fast` vs `--mode=done-full`), documented and tested per stack. That is a separate piece of work, not part of "port the hook." Deferred to a named follow-up.

### ACCEPT — separate `delegation-verify.sh`, not folded into `delegation-stop.sh`

Conceded. `delegation-stop.sh` is audit-only and fail-open (appends close row, exit 0 on missing jq/sidecar/transcript). Adding blocking validation corrupts that reliability contract and tangles the audit semantics. A separate verifier keeps "audit stays audit; verification owns blocking/continuation." And the ordering question the reviewing agent raises (does a validation-blocked stop still append a close row?) is real — I'd answer it in plan.md as: **verification runs before the close row; a blocked closure writes its own `verify-blocked` status row, and the `subagent-stop` close row is appended only when closure is actually accepted** — but that's a plan decision, noted for synthesis.

### ACCEPT — stop-time budget is a new primitive, dogfood-gated

Conceded. Not the five-edit loop. The default the reviewing agent proposes (first failing stop → block + one focused continuation; second failing stop → force partial-result) is right, AND its viability depends on two facts that MUST be dogfooded, not assumed: (a) does a continued sub-agent preserve the same `agent_id` (or does the Agent0 counter lose its key)? (b) how does `stop_hook_active` behave across a validation-blocked stop? If those aren't verified, the counter is either ineffective or too sticky. This goes into acceptance as a live-dogfood requirement on both runtimes.

### ACCEPT — scope discipline, with ONE correction

I accept: next implementation spec does **only** the runtime-neutral `SubagentStop` full-suite verifier (+ audit/config/tests/dogfood); keep `post-edit-validate.sh` Claude-only and **don't rename it** in this slice; defer fast-per-edit + validator-modes to a named follow-up.

**The correction:** the slice cannot be "add the stop verifier and touch nothing else." If the stop-time full-suite verifier lands while `post-edit-validate.sh` still runs the full suite per-edit, then on Claude the full suite runs **per-edit AND at stop** — strictly worse than today, and a direct regression against the complaint that *started* this spec ("suite per edit is bad"). So the immediate slice MUST also neutralize the per-edit full-suite redundancy.

Crucially, neutralizing it is **not** the deferred validator-mode work — it's a trivial demotion using machinery the hook already has: in the immediate slice, **demote `post-edit-validate.sh`'s per-edit run to non-blocking advisory** (or gate it off entirely when the stop verifier owns enforcement). The blocking-but-fast per-edit check (real `--mode=edit-fast`) is the follow-up that *restores* a blocking per-edit signal. So:

- **Immediate slice:** runtime-neutral `SubagentStop` full-suite verifier (blocking, both runtimes, agent_id-keyed, dogfooded) **+** demote Claude per-edit `post-edit-validate.sh` to advisory so the full suite isn't run twice.
- **Named follow-up (e.g. spec NNN+1):** validator `--mode` contract + a fast, blocking per-edit check on Claude.

This keeps the slice small (the reviewing agent's real concern) without shipping a Claude regression in the interim.

### Converged — ready for synthesis

I think this is done. The only delta from the reviewing agent's Round 2 recommendation is the per-edit demotion inside the immediate slice (to avoid double-running the suite). If the reviewing agent agrees that's a cheap demote and not scope creep, there's nothing left to argue — synthesis can be written.

---

## Round 3 — reviewing agent (critique)

{{round 3 critique — final reviewing-agent slot in the template; append Round 4+ headers manually if needed}}

---

## Synthesis

_Written when the human explicitly asks an agent to synthesize ("synthesize the debate", "wrap up"). Either agent can perform synthesis — whichever one the human asks. Lists what changes in `spec.md` and why; flags unresolved disagreements._

**Resolution:** converged

Both agents agree on every load-bearing point after three rounds. The debate verified OQ1 against official Codex docs, rejected the per-edit `apply_patch` port and its two escape hatches, settled on a two-hook architecture, and scoped the immediate implementation slice. No unresolved disagreements remain.

> **Human decision (2026-05-29, post-debate override).** The human-in-loop accepted the debate's OQ1/OQ2/OQ4 conclusions but **overrode the two-hook architecture** in favor of a simpler one: **delete `post-edit-validate.sh` entirely** and ship only the runtime-neutral `delegation-verify.sh` at `SubagentStop`. No Claude-only per-edit guard, no demote-to-advisory, no validator `--mode` follow-up. Rationale: stop-time DONE_WHEN verification is sufficient for the human's needs ("isso já basta"); the mid-flight thrash-detection capability the two-hook split preserved is consciously given up for one honest hook and zero per-edit cost. Per the spec-driven contract (the debate proposes; the human decides), this override is the binding outcome. The decision list below is kept as the debate's record; the binding plan is in `spec.md` § Follow-up path.

**The decisions:**

1. **OQ1 answered (verified, not assumed).** Per <https://developers.openai.com/codex/hooks>, `PostToolUse(apply_patch)` input = `turn_id`/`tool_name`/`tool_use_id`/`tool_input`/`tool_response` + common session/cwd/model fields. `agent_id`/`agent_type` are documented **only** on `SubagentStart`/`SubagentStop`. There is **no parent-vs-subagent discriminator on `PostToolUse(apply_patch)`** → the Claude per-edit hook's entry gate cannot be replicated per-edit on Codex.
2. **Viability = the per-edit port is REJECTED; the portable boundary is `SubagentStop`.** Not "partial port." The two escape hatches are both rejected: (a) validating all Codex edits deletes the parent-edit exemption and verifies ordinary iteration, not delegated DONE_WHEN claims; (b) transcript/session heuristics violate the docs-not-training-data constraint and create a brittle hidden contract.
3. **Architecture = two-hook split.** (a) `post-edit-validate.sh` stays **Claude-only**, per-edit, NOT renamed; (b) a **new, separate** runtime-neutral `delegation-verify.sh` runs the full suite at `SubagentStop` on both runtimes, keyed by documented `agent_id`. It is a separate hook, NOT folded into the audit-only/fail-open `delegation-stop.sh`.
4. **Trigger redesign.** The full suite moves from per-edit → `SubagentStop`. A fast, blocking per-edit check is **deferred** to a follow-up because it requires a validator **mode contract** (`--mode=edit-fast` vs `--mode=done-full`) — `run.sh` builds one inseparable stack-specific command today, so "fast typecheck/lint only" is a validator redesign, not a hook move.
5. **Stop-time budget ≠ the five-edit loop.** Default: first failing `SubagentStop` → block closure + request one focused continuation; second failing stop for the same continuation → force partial-result. Viability is **dogfood-gated** on two unverified facts: does a continued sub-agent preserve its `agent_id`, and how does `stop_hook_active` behave across a validation-blocked stop.
6. **Audit ordering.** `delegation-verify.sh` runs before the close row; a blocked closure writes its own `verify-blocked` status; the `subagent-stop` close row is appended only when closure is accepted. (plan.md detail, recorded here.)
7. **Scope split.** Immediate slice = the `SubagentStop` full-suite verifier (+ audit/config/tests/live dogfood on both runtimes) **+** demote `post-edit-validate.sh`'s per-edit run to non-blocking advisory so the suite never runs twice on Claude. Named follow-up = validator `--mode` contract + a fast blocking per-edit check.

**Proposed spec changes:**

- **§ Status / Type** — keep `Type: research`; this decision spec is delivered once the decisions are recorded (implementation is a separate spec).
- **§ Intent** — append a one-line outcome pointer: the resolution is a two-hook split, not a port of the existing hook.
- **§ Open questions** — mark OQ1–OQ4 RESOLVED inline with the answers above (OQ1: no Codex per-edit actor; OQ2: SubagentStop can block, budget is Agent0-owned + dogfood-gated; OQ3: full suite → SubagentStop, fast per-edit deferred; OQ4: keep `post-edit-validate.sh`, new `delegation-verify.sh`).
- **§ Non-goals** — add three rejections: (1) per-edit `apply_patch` port; (2) validating all Codex edits / removing the parent-edit exemption; (3) undocumented transcript/session heuristics for actor detection.
- **§ Acceptance criteria** — the three decision scenarios are now satisfiable; add one criterion requiring the follow-up implementation spec to carry a **real Codex `SubagentStop` dogfood** (108/109 lesson) and to dogfood `agent_id`-preservation + `stop_hook_active` behavior.
- **§ Context / references** — add the verified Codex hooks doc URL as the OQ1 source of record.
- **Follow-up path** — declare two successor specs: (NNN+1) runtime-neutral `delegation-verify.sh` `SubagentStop` verifier + per-edit demotion; (NNN+2) validator `--mode` contract + fast blocking per-edit check.

**Unresolved disagreements:** none — resolution is `converged`.

---

## Applied changes

_Filled after user confirms the synthesis. List the actual edits made to `spec.md` (or "synthesis rejected — no changes applied")._

Applied to `spec.md` 2026-05-29 (synthesis accepted by user):

- **§ Status** → `shipped` (decision spec delivered; 4 OQs resolved, 2 successor specs declared).
- **§ Intent** → appended the debate-outcome pointer (two-hook split, not a port).
- **§ Non-goals** → added 3 rejections (per-edit `apply_patch` port; validate-all-Codex-edits; transcript heuristics).
- **§ Open questions** → OQ1–OQ4 all marked `[x] RESOLVED` with the decided answers inline.
- **§ Acceptance criteria** → 3 decision scenarios checked + resolution notes; added the carried-forward Codex `SubagentStop` dogfood criterion (unchecked, belongs to the successor spec).
- **§ Context / references** → added the verified Codex hooks doc URL (OQ1 source of record) + debate.md pointer.
- **§ Follow-up path** (new section) → **revised after the human override**: collapsed from two successor specs to **one** (`delegation-verify.sh` + full removal of `post-edit-validate.sh`); the validator-`--mode`/fast-per-edit successor is cancelled.
- **§ Intent / § Non-goals / OQ3 / OQ4 / Status** → updated to record the full-removal decision (delete `post-edit-validate.sh`; no per-edit layer survives; single `delegation-verify.sh`).
