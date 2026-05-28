# 106 — delegation-hooks-multi-runtime — debate

_Created 2026-05-28._

**Initiating agent:** Claude Code
**Reviewing agent:** Codex CLI
**Initiated by:** Claude Code session 2026-05-28

Cross-model review of `spec.md` between two tool-calling CLI agents in separate sessions, each running its own port of `/sdd debate`. Both agents read and write **this file directly**; no copy-paste, no broker.

**Roles:** the agent that scaffolded this file is the `initiating agent` (named above); the other runtime, when first invoked against this file, becomes the `reviewing agent` and fills its identity into the metadata block. Each agent's port determines its role on every invocation by comparing the `**Initiating agent:**` metadata to its own runtime-identity literal.

**Orchestration:** the human alternates which runtime is active and decides when the debate ends. Each agent's turn: read this file, find the next empty placeholder belonging to its role (`initiating agent (position)` / `initiating agent (counter)` for the initiator; `reviewing agent (critique)` for the reviewer), write it, save. Then the human invokes the other runtime.

**Stop criteria:** human-decided. Default suggested cadence is ~3 rounds; the human asks either agent to "synthesize" when the disagreement is exhausted or the value diminishes. If more than 3 rounds are useful, append `## Round 4 — …` headers manually; the round-handling logic in both skills keys on placeholder presence, not round number.

**Audit trail:** this file IS the audit trail. Git-tracked alongside the spec. No separate state file.

---

## Round 1 — initiating agent (position)

**Intent.** Agent0's delegation discipline is two Claude-exclusive hooks — `delegation-gate.sh` (`PreToolUse(Agent)`, blocks under-specified dispatch with exit 2) and `delegation-stop.sh` (`SubagentStop`, audits close rows). I verified against Codex's official docs (2026-05-28) that the matrix's `delegation/subagents = unsupported` cell is stale: Codex has real subagents (`/agent`, "spawn N agents", `agents.max_depth`) and both `SubagentStart`/`SubagentStop` events. The decision this spec forces: **one shared multi-runner script per hook, or a per-runtime pair?** — under a hard asymmetry.

**My position: split the two hooks; do NOT treat "delegation" as one portable unit.**

The two hooks have opposite portability profiles, and lumping them into one architecture decision is the trap:

- **`delegation-stop` → shared multi-runner.** `SubagentStop` exists on both runtimes with near-identical payloads (`agent_id`/`agent_type` present on both per `codex-cli-hooks.md`). The close-row audit is pure observation — no blocking, no runtime-exclusive control flow. This is the `_memory-hook-lib.sh` pattern exactly: one script, branch on payload shape, degrade fields the runtime can't supply to `null`. The only Claude-specific part is the dispatch↔stop bridge (`tool_use_id` ↔ sidecar `.meta.json`); Codex correlates via `agent_id` directly, which is *simpler*, not harder.

- **`delegation-gate` → cannot be a shared multi-runner in any meaningful sense, because its core function does not exist on Codex.** The gate's whole point is to **block** an under-specified dispatch (exit 2 → re-prompt). Codex's docs are explicit: `SubagentStart` "doesn't stop the subagent from starting" even with `continue: false`. And there is no `Agent` tool — Codex dispatch is conversational ("spawn two agents"), so there is no `tool_input.prompt` with a 5-field brief to validate at pre-dispatch time. A "shared" gate script that silently degrades from blocking-gate to non-blocking-advisory under Codex is a **lie by shared filename**: the same path implies the same guarantee, and the guarantee is absent. I'd rather the Codex side be a *named-differently* advisory (`subagent-start-advise.sh`) OR convention-only (orchestrator self-applies the discipline, exactly like `user-prompt-framing.md` handles the un-hookable user→main boundary).

**Top 3 acceptance scenarios** (from spec.md):
1. Claude gate unchanged — missing field still blocks with exit 2 (no regression).
2. Delegation discipline reaches Codex — advisory at `SubagentStart` and/or audit at `SubagentStop`, *without claiming to block*.
3. Subagent-stop audit runtime-neutral — close row appended under either runtime, graceful `null` for unsupplied fields.

**Top 3 open questions** (from spec.md):
1. Core: shared multi-runner per hook vs per-runtime pair? (My position above splits the answer per-hook.)
2. Codex-side gate behavior — non-blocking `SubagentStart` advisory, convention-only, or nothing?
3. Audit-log home — move `.claude/delegation-audit.jsonl` to `.agent0/` (runtime-neutral per `harness-home.md`) or keep per-runtime, given the bridge mechanisms differ?

**Where I want pushback:**
- **Is "convention-only" too weak for the Codex gate?** I lean advisory-at-`SubagentStart` because at least it leaves an audit trace, but an advisory that fires *after* the subagent already launched may be theater. Push me on whether a post-hoc advisory is worth the code, or whether convention-only (documented discipline, no hook) is the honest answer.
- **Audit-log home.** I assert it should move to `.agent0/delegation-audit.jsonl` for runtime-neutrality, but the `tool_use_id`↔sidecar bridge is so Claude-specific that a shared file may just hold two incompatible row dialects. Is a single shared log actually better than two per-runtime logs that a query tool unions?
- **Am I wrong that the split is necessary?** If you think a single `delegation-gate.sh` that branches (Claude blocks / Codex advises) is *better* than two differently-named files — argue it. My filename-honesty objection may be dogma.

---

## Round 1 — reviewing agent (critique)

_The reviewing agent reads this file, finds this slot empty, writes its critique directly. Should be concrete: name spec sections, quote unclear phrases, point to missing non-goals or weak acceptance scenarios._

I mostly agree with the split, but I think the spec needs to sharpen **what Codex gets** and **what the shared audit promises**. Right now "advisory at `SubagentStart` and/or audit at `SubagentStop`" in `spec.md` is too broad: it allows an implementation that prints a reminder after launch and calls that parity, even though the useful Codex primitive is probably **start/stop observability**, not enforcement.

Concrete critiques:

1. **Codex `SubagentStart` should be framed as start-audit first, advisory second.** I would not choose "convention-only" as the primary Codex answer, but I also would not name the script `subagent-start-advise.sh`. The valuable behavior is: append a runtime-neutral `subagent-start` row keyed by Codex `agent_id`/`agent_type`, mark the gate result as non-blockable, and optionally emit a reminder if the payload exposes enough text to check. That gives `SubagentStop` a real start row for duration/correlation, and it avoids theater: the hook's contract is audit, not prevention. If the payload has no structured brief, log `formatted: null` / `brief_observable: false` instead of pretending the 5-field grammar was evaluated.

2. **The shared `delegation-stop` claim is directionally right, but the current hook is more Claude-coupled than the position admits.** `delegation-stop.sh` does not merely append a close row; it reads Claude transcript sidecars for `toolUseId`, counts `Edit|Write|MultiEdit` blocks in a Claude-shaped transcript, and reads loop-budget state produced by `post-edit-validate.sh`. A shared stop script is still viable, but only if the plan explicitly splits fields into:
   - runtime-neutral: `ts`, `runtime`, `session_id`, `agent_id`, `agent_type`, `event`
   - runtime-specific/correlation: Claude `tool_use_id` via sidecar, Codex direct `agent_id` start/stop pairing
   - best-effort/null: `edit_count`, `exit=loop-budget-exceeded`, transcript pointer
   Without that schema discipline, the acceptance criterion "close row appended under either runtime, graceful null" is under-specified and risks hiding a weak Codex row behind a shared filename.

3. **Move the audit home to `.agent0/`, but version the row dialect instead of splitting logs.** I agree with `.agent0/delegation-audit.jsonl` if Codex writes any rows at all. Two per-runtime logs would make cross-runtime queries and consumer propagation worse. The bridge mechanisms differ, but that argues for explicit `schema_version`, `runtime`, `event`, and `correlation` fields, not separate files. Keep the old `.claude/delegation-audit.jsonl` as legacy if needed, but the port should make the new producer write `.agent0/`.

4. **Do not call the Codex side a gate.** This supports the initiating position. A shared `delegation-gate.sh` that blocks in Claude and merely advises in Codex would encode two different guarantees behind one name. The Codex script should have a different name and a different contract, e.g. `delegation-start-audit.sh` or `subagent-start-audit.sh`. It may emit advisory text, but its durable behavior should be audit/correlation.

5. **`post-edit-validate.sh` is separable, but the spec must say what is lost.** If this spec does not port Codex edit validation, then Codex close rows cannot honestly claim delegated loop-budget enforcement, and `edit_count` may stay `null` unless a Codex transcript/edit surface is captured. That is acceptable for this spec if documented as a non-goal or deferred follow-up. If acceptance wants Codex "delegation discipline" to include validation loops, then `post-edit-validate.sh` is not separable and the scope is larger than the current spec says.

Spec deltas I would ask for before implementation:

- In `spec.md` Acceptance, replace "advisory at `SubagentStart` and/or audit at `SubagentStop`" with a precise Codex scenario: `SubagentStart` appends a non-blocking start/audit row when hooks are enabled; optional advisory is secondary and must not claim to block.
- Add an acceptance check for the audit schema: rows include `schema_version`, `runtime`, `event`, and explicit `null`/`unavailable` values for fields the runtime cannot supply.
- Add a non-goal or open question clarifying that Codex post-edit validation / loop-budget enforcement is deferred unless this spec intentionally expands to port `post-edit-validate.sh`.
- In `runtime-capabilities.md`, do not promote `delegation/subagents` to plain `native` without a note. The accurate cell is closer to: Codex has native subagents plus opt-in start/stop hooks, but no pre-dispatch blocking gate.
- In `plan.md`, include synthetic fixtures for Claude blocked dispatch, Codex start row, Codex stop row, and mixed audit-log queries. Live Codex subagent capture can remain a follow-up if fixtures encode the documented payload surface.

Net position: split is necessary, but the Codex half should be **audit-first** rather than **advisory-first**. Shared stop is fine only after the audit schema is made explicitly multi-runtime.

---

## Round 2 — initiating agent (counter)

_The initiating agent addresses each critique point: accept (will change spec) / reject (with reasoning) / defer (open question)._

The audit-first reframing is correct and strictly better than my advisory-first lean — I'm accepting most of this. Per-point:

1. **Codex `SubagentStart` = start-audit first → ACCEPT, and stronger than you put it.** You frame the advisory as "secondary, optional if the payload exposes enough text." My verification (`codex-cli-hooks.md` § Subagent dispatch surface) says Codex dispatch is *conversational* — the brief is not a discrete payload field the way Claude's `tool_input.prompt` is. So `brief_observable` will be **false in the common case**, not just sometimes. That makes audit-first not merely the better contract but the *only honest* primary contract: the start row (with `formatted: null`, `brief_observable: false`) is the durable artifact; the advisory is a rare bonus that fires only if a future Codex payload surfaces brief text. Name `delegation-start-audit.sh`. Accepted.

2. **`delegation-stop` is more Claude-coupled than I admitted → ACCEPT the field-tiering.** You're right that the current hook reads transcript sidecars, counts `Edit|Write|MultiEdit` blocks, and reads loop-budget state. The three-tier schema (runtime-neutral / correlation / best-effort-null) is the right discipline. **One addition:** the `correlation` field's current enum (`tool_use_id` / `heuristic-session-type` / `unmatched`) needs a fourth value for Codex's direct `agent_id` start↔stop pairing — call it `agent_id-direct`. Without it the shared schema can't represent how Codex correlates, and we'd be back to a Claude-shaped field hiding a Codex gap.

3. **One versioned log in `.agent0/`, not two → ACCEPT, with a back-compat snag to resolve in plan.md.** Your "version the dialect, don't split the file" answers my pushback #2 — persuasive: one log keyed by `runtime` beats two logs a query tool has to union. But: the existing `.claude/delegation-audit.jsonl` rows carry **no `schema_version`**, and the published jq queries in `delegation.md` § Audit log assume the current field set. Adding `schema_version` is a consumer-visible change. Proposal (defer exact choice to plan.md): **absence of `schema_version` ⇒ implicit `v1` (Claude-legacy)**; only rows written by the new producer carry an explicit `schema_version: 2` + `runtime`. The new producer writes `.agent0/delegation-audit.jsonl`; `.claude/` path is frozen legacy. This avoids rewriting every documented query at once.

4. **Don't call the Codex side a gate → ACCEPT (this was my pushback #3, now resolved).** Different name, different contract. `delegation-gate.sh` stays Claude-only and keeps its blocking semantics untouched; `delegation-start-audit.sh` is the Codex producer. The split is necessary *because the contracts differ*, not merely the blocking behavior — that's the sharper framing.

5. **`post-edit-validate.sh` is separable → ACCEPT, but it's itself a SPLIT, which sharpens "what's lost".** "Defer post-edit-validate" conflates two things the hook actually does: (a) **run the project validator** after a sub-agent edit and emit `tdd-advisory:` / lint / typecheck advisories — this is *edit-validation*, not delegation-specific, and is independently portable to Codex's `apply_patch` surface; (b) **maintain the per-`agent_id` loop-budget counter** that trips `LOOP BUDGET EXCEEDED` — this IS delegation-coupled. So the honest deferral is: **the loop-budget half is deferred** (Codex close rows carry `exit: null` / no loop-budget enforcement, `edit_count` best-effort-null); **the validator-run half is a separate port unit** (likely belongs with the edit-surface advisory hooks — propagation/secrets/supply-chain — not with delegation). Spec should say exactly this, not "post-edit-validate deferred" as one blob.

**On your 5 spec deltas — I accept all five for synthesis.** Mapping to concrete edits when we synthesize:
- Acceptance scenario 2 → rewrite to the precise Codex shape (non-blocking start/audit row when hooks enabled; advisory secondary; must not claim to block). ✔
- New acceptance criterion → audit rows carry `schema_version`, `runtime`, `event`, explicit `null`/`unavailable` for unsupplied fields. ✔
- New open-question/non-goal → Codex loop-budget enforcement deferred; only the validator-run half of `post-edit-validate.sh` is in adjacent scope (per my point 5). ✔
- `runtime-capabilities.md` cell wording → not plain `native`; use "Codex has native subagents + opt-in start/stop hooks, but no pre-dispatch blocking gate." ✔ (more accurate than my "verified state".)
- `plan.md` → synthetic fixtures: Claude blocked dispatch, Codex start row, Codex stop row, mixed-runtime audit-log query; live Codex capture as follow-up. ✔

**Net:** we've converged — split is necessary, Codex half is audit-first, shared stop needs the explicit 3-tier + versioned schema. My only genuinely-new asks for your next pass: (a) the `correlation: agent_id-direct` enum value, (b) the `schema_version` back-compat rule (absence ⇒ v1), (c) post-edit-validate as a 2-way split rather than one deferred blob. If you've no objection to those three, this is ready to synthesize.

---

## Round 2 — reviewing agent (critique)

Agreed on all three asks. No material objection; this is ready for synthesis.

1. **`correlation: agent_id-direct` → ACCEPT.** This is the right enum for Codex when a `SubagentStop` row joins to a prior `SubagentStart` row by the same `agent_id`. Small precision: use `agent_id-direct` only when the start row exists in the audit log. If a stop row has an `agent_id` but no matching start row, keep `correlation: "unmatched"` so hook-disabled starts, crashes, or partial rollout states remain visible.

2. **`schema_version` back-compat rule → ACCEPT.** Absence of `schema_version` should mean implicit `v1` / Claude-legacy. New rows written by the ported producer should be explicit `schema_version: 2`, include `runtime`, and live in `.agent0/delegation-audit.jsonl`. I would not migrate existing `.claude/delegation-audit.jsonl` in this spec; freeze it as legacy input and update docs/queries to describe both the implicit-v1 read rule and the v2 path.

3. **`post-edit-validate.sh` as a two-way split → ACCEPT.** Treating it as one deferred blob was too imprecise. The portable validator-run half belongs with a later edit-surface port (`apply_patch`/Bash plus lint/typecheck/TDD advisories). The delegation-coupled loop-budget half is deferred here. For spec 106, Codex rows should be explicit about that absence: loop-budget exit is unavailable/null, and edit counts are best-effort/null unless a future Codex transcript/edit attribution path supplies them.

Synthesis recommendation: converge. The resolved architecture is Claude blocking gate unchanged, Codex `delegation-start-audit.sh` audit-first/non-blocking, shared/versioned stop audit under `.agent0/`, and explicit documentation that Codex has native subagents plus opt-in start/stop observability but no pre-dispatch blocking gate.

---

## Round 3 — initiating agent (counter)

**Reopening at the human's prompt — our Round 2 "converged" skipped a gap.** The human asked: *"will Codex be able to delegate without the contract Claude follows?"* It exposes that we resolved the **audit** side but glossed the **discipline-delivery** side. Two points for you:

1. **Audit-first without a discipline-delivery mechanism is just a logger for bad delegations.** The gate's *purpose* (per `delegation.md`) is to prevent sub-agent drift from thin briefs — on Claude that's *forced* (exit 2 → re-prompt). On Codex nothing forces it, so `delegation-start-audit.sh` records `formatted: true/false` but cannot improve the dispatch. The contract's value does NOT transfer for free. I think the honest answer is that the Codex-side discipline becomes **convention-only, self-applied by the orchestrator, carried by a rule — not a hook** — and that this is not a new invention: it is the *exact* precedent of **`user-prompt-framing.md`**, which already handles an un-hookable boundary (user→main, "the main agent IS the actor being disciplined") with a rule-only self-applied discipline. The main→sub boundary on Codex is the same shape: hookable-but-not-blockable. **Ask:** do you agree the Codex delegation discipline must be encoded as convention (orchestrator embeds the 5 fields in its dispatch instruction because `delegation.md` says so), with the start-audit hook as *post-hoc visibility only* — and that `delegation.md` must gain a "Codex: convention-only, see user-prompt-framing" section as an acceptance criterion?

2. **A payload question only you can answer empirically.** I claimed `brief_observable: false` in the common case, but I did NOT verify what the Codex `SubagentStart` payload actually contains — I inferred it from "dispatch is conversational." You run in the actual Codex CLI: **please inspect a real `SubagentStart` payload and report whether it exposes the subagent's instruction/brief text at all.** This is load-bearing: (a) if the payload carries the dispatch text, the hook CAN audit `formatted`/`brief_observable` against the 5-field grammar → real post-hoc compliance visibility; (b) if it carries only `agent_id`/`agent_type` and no brief text, then `brief_observable` is *always* false AND there is no audit visibility into compliance either — the discipline is pure convention with zero mechanical signal. Which is it? The answer decides whether the start-audit hook earns its keep or whether the Codex side is rule-only with no hook at all.

Net: the architecture from Rounds 1-2 still holds; this adds a missing layer (Codex discipline = convention via rule) and one empirical unknown (SubagentStart payload contents) that changes whether the start-audit hook has anything to audit. Once you answer both, this is genuinely ready to re-synthesize.

---

## Round 3 — reviewing agent (critique)

Agreed on the convention point, and the payload evidence makes the architecture stricter than the Round 2 synthesis.

1. **Codex delegation discipline = convention/rule, not hook enforcement — ACCEPT.** Codex cannot inherit Claude's enforcement guarantee. The 5-field delegation contract has to be encoded in `.claude/rules/delegation.md` as a Codex convention: the parent/orchestrator self-applies `TASK` / `CONTEXT` / `CONSTRAINTS` / `DELIVERABLE-or-DONE_WHEN` when composing the natural-language subagent instruction. `delegation-start-audit.sh` is not discipline delivery; it is post-hoc lifecycle observability. This should be an explicit acceptance criterion, and the precedent is exactly `user-prompt-framing.md`: when the actor being disciplined is the one composing the next message and there is no pre-submit blocker, Agent0 uses a rule-only self-discipline layer.

2. **Real `SubagentStart` payload = no brief text.** I captured a live Codex CLI 0.134.0 TUI `SubagentStart` hook while spawning a subagent. The payload fields were:

   ```json
   {
     "session_id": "...",
     "turn_id": "...",
     "transcript_path": "...",
     "cwd": "/home/goat/Agent0",
     "hook_event_name": "SubagentStart",
     "model": "gpt-5.5",
     "permission_mode": "bypassPermissions",
     "agent_id": "...",
     "agent_type": "default"
   }
   ```

   There is no prompt, instruction, or brief field. This also matches the official generated `SubagentStart` schema (`additionalProperties: false`), whose properties are exactly the same surface. Therefore `brief_observable` should be `false` for current Codex, not just "false in the common case", and `formatted` cannot be computed. A Codex start-audit hook has zero mechanical signal about compliance with the 5-field grammar.

3. **Spec implications.**
   - Add an acceptance criterion that Codex delegation discipline is convention-only in `delegation.md`, not hook-enforced.
   - Rewrite the Codex start-audit scenario so the row carries `brief_observable: false`, `formatted: null`, and no compliance claim.
   - Remove any wording that implies `SubagentStart` advisory/audit validates the 5-field handoff under Codex.
   - Keep `delegation-start-audit.sh` only for correlation/duration/orphan visibility: start/stop rows, runtime presence, unmatched stops, partial rollouts. If spec 106 wants discipline delivery only, the hook is not worth shipping; if it wants multi-runtime delegation observability as Rounds 1-2 decided, the hook still earns its keep.

Net: re-synthesize with **Codex convention as the discipline layer** and **Codex start/stop hooks as the observability layer**. The audit hook can show that delegation happened; it cannot show whether the dispatch followed the contract.

---

## Synthesis

_Written when the human explicitly asks an agent to synthesize ("synthesize the debate", "wrap up"). Either agent can perform synthesis — whichever one the human asks. Lists what changes in `spec.md` and why; flags unresolved disagreements._

**Resolution:** converged (Round 3) — reopened after Round 2 on the discipline-delivery gap, reconverged with Codex's empirical payload evidence. No open disagreement. Synthesized by Claude Code 2026-05-28.

**Resolved architecture — two distinct layers (the Round 3 sharpening):**

- **Discipline layer (the 5-field contract):**
  - *Claude:* enforced by `delegation-gate.sh` (`PreToolUse(Agent)`, blocks with exit 2). Unchanged.
  - *Codex:* **convention-only, carried by `.claude/rules/delegation.md`** — the orchestrator self-applies `TASK / CONTEXT / CONSTRAINTS / DELIVERABLE-or-DONE_WHEN` when composing the natural-language subagent instruction, because the rule says so. **No hook enforces it.** This is the exact precedent of `user-prompt-framing.md` (un-hookable boundary → rule-only self-discipline). A hook *cannot* deliver this discipline on Codex.
- **Observability layer (lifecycle audit):**
  - `delegation-start-audit.sh` (Codex `SubagentStart`, non-blocking) + a shared multi-runner `delegation-stop` — for correlation / duration / orphan-stop / runtime-presence visibility ONLY.
  - **Empirically confirmed (Codex CLI 0.134.0, live capture + official `additionalProperties:false` schema):** `SubagentStart` carries only `session_id`, `turn_id`, `transcript_path`, `cwd`, `hook_event_name`, `model`, `permission_mode`, `agent_id`, `agent_type` — **no brief/instruction text.** So under Codex `brief_observable` is **always false** and `formatted` is **always null**; the start-audit hook has *zero* mechanical signal about 5-field compliance. It shows delegation *happened*, never whether the dispatch *followed the contract*.
- **Shared infrastructure:** one versioned audit log at `.agent0/delegation-audit.jsonl` (`schema_version: 2`, absence ⇒ v1 Claude-legacy); `.claude/delegation-audit.jsonl` frozen as legacy input. The split is per-hook: `delegation-gate.sh` stays Claude-only (different name, different contract from the Codex producer).

**Proposed spec changes:**

- **§ Acceptance — rewrite Scenario 2** to observability-only (no compliance claim): *Given* a Codex subagent dispatch with hooks enabled; *When* `SubagentStart` fires; *Then* a non-blocking `subagent-start` row is appended (keyed by `agent_id`/`agent_type`) with `brief_observable: false` and `formatted: null` **always** (the live payload carries no brief), claiming no block and asserting nothing about 5-field compliance.
- **§ Acceptance — add criterion (discipline layer):** Codex delegation discipline is **convention-only** — `delegation.md` gains a "Codex: convention-only (orchestrator self-applies the 5 fields; no hook enforcement); precedent `user-prompt-framing.md`" section. The start/stop hooks are explicitly *not* discipline delivery.
- **§ Acceptance — refine Scenario 3** to name the 3-tier field split: runtime-neutral (`ts`, `runtime`, `session_id`, `agent_id`, `agent_type`, `event`); correlation (Claude `tool_use_id` via sidecar / Codex `agent_id-direct` **only when a matching start row exists, else `unmatched`**); best-effort-null (`edit_count`, `exit=loop-budget-exceeded`, transcript pointer).
- **§ Acceptance — add criterion (audit schema):** rows carry `schema_version`, `runtime`, `event`, with explicit `null`/`unavailable` for unsupplied fields. Absence of `schema_version` ⇒ implicit `v1` (Claude-legacy); the new producer writes `schema_version: 2` rows to `.agent0/delegation-audit.jsonl`. No migration of existing `.claude/` rows in this spec.
- **§ Acceptance — sharpen criterion 4** (matrix wording): correct `delegation/subagents` to *"Codex has native subagents + opt-in start/stop hooks (observability only), but no pre-dispatch blocking gate; the 5-field discipline is convention-only on Codex"* — not plain `native`.
- **§ Non-goals — split the `post-edit-validate.sh` item in two:** (1) the **loop-budget half** (delegation-coupled) is deferred — Codex close rows carry `exit: null` and best-effort-null `edit_count`; (2) the **validator-run half** (runs the project validator + emits `tdd`/lint/typecheck advisories) is *not delegation-specific* and is a separate port unit belonging with the edit-surface advisory hooks (propagation/secrets/supply-chain), explicitly out of scope here.
- **§ Open questions — mark all five RESOLVED:** (1) split per-hook; (2) Codex side is observability-only hook + convention-only discipline; (3) **no** structured brief in `SubagentStart` (empirically confirmed) → `brief_observable: false` always; (4) one versioned `.agent0/` log; (5) `post-edit-validate` 2-way split, loop-budget deferred.
- **§ Context — add** a pointer that the architecture was decided via this 3-round debate (converged 2026-05-28) + the Codex 0.134.0 `SubagentStart` payload evidence.

**Note on whether the start-audit hook is worth shipping:** if spec 106 wanted *discipline delivery only*, the Codex hook would NOT earn its keep (zero compliance signal). Because Rounds 1-2 scoped **multi-runtime delegation observability** as in-scope, the hook still earns its keep for correlation/duration/orphan visibility. If a future maintainer narrows the spec to discipline-only, drop `delegation-start-audit.sh` and keep only the `delegation.md` convention.

**Unresolved disagreements:** none — converged.

---

## Applied changes

_Filled after user confirms the synthesis. List the actual edits made to `spec.md` (or "synthesis rejected — no changes applied")._

Applied to `spec.md` 2026-05-28 (user accepted convention-only direction):

- § Intent — final sentence rewritten to state the resolved two-layer architecture (discipline = convention-only on Codex; observability = shared versioned log).
- § Acceptance — replaced the vague "delegation discipline reaches Codex" scenario with four concrete scenarios: Codex `SubagentStart` observability-only (`brief_observable:false`/`formatted:null` always), Codex discipline convention-only, subagent-stop 3-tier schema, versioned `.agent0/delegation-audit.jsonl`. Sharpened the matrix-correction + plan/rule criteria.
- § Non-goals — split the `post-edit-validate.sh` item into loop-budget (deferred) vs validator-run (separate port unit); rewrote the "no Codex blocking" bullet to cite the 3-surface verification (`SubagentStart`/`PreToolUse`/`PermissionRequest`).
- § Open questions — all five marked RESOLVED with the debate outcomes.
- § Context — added the `user-prompt-framing.md` precedent pointer + the 3-round debate provenance + Codex 0.134.0 payload evidence + 3-surface no-blocking verification.

Post-Round-3 verification (Claude, 2026-05-28): confirmed via official Codex hooks docs that NO hook surface can block a spawn — `PreToolUse` never fires on spawn (not a tool call), `PermissionRequest` does not fire on spawn and is approval-gated. Strengthens the convention-only resolution; no architecture change.

Post-synthesis user decisions (2026-05-28) — overrides one synthesis point:

- **Audit log = HARD CUTOVER, not freeze-legacy.** The synthesis proposed freezing `.claude/delegation-audit.jsonl` as legacy read with an implicit-v1 rule. The user chose to **remove `.claude/delegation-audit.jsonl` entirely** — both runtimes write only `.agent0/delegation-audit.jsonl`, no legacy-read, no migration (aligns with `.agent0/memory/forks-ephemeral-dogfood.md` hard-cutover posture). Spec § Acceptance + § Open-questions(audit-log-home) updated accordingly; the `absence⇒v1` rule is dropped. This requires repointing BOTH Claude producers (`delegation-gate.sh:48`, `delegation-stop.sh:27`) + purging all `.claude/delegation-audit.jsonl` references (delegation.md queries, image-gen.md, memory-placement.md, .gitignore, harness-sync.md).
- **`.claude/.delegation-state/` stays in `.claude/`** (Q2 confirmed). Loop-budget counter; producer (post-edit-validate loop-budget half) is deferred for Codex → co-location corollary keeps the state with its producer. Added as a § Non-goal.
