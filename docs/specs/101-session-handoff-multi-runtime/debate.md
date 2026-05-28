# 101 — session-handoff-multi-runtime — debate

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

_Pre-populated from `spec.md` key claims at scaffold time. Structure: intent (1 paragraph) → top 3 acceptance scenarios → top 3 open questions → "where the initiating agent wants pushback"._

**Intent (1 paragraph).** Port the session-handoff capacity from Claude-only to multi-runtime parity, closing the first of three pending rows in `runtime-capabilities.md:45` (`session handoff`, `runtime introspect`, `delegation/subagents`). Move `.claude/hooks/session-start.sh` (SessionStart) and `.claude/hooks/session-stop.sh` (Stop) into `.agent0/hooks/` as shared canonical scripts; register them on both runtimes via their native lifecycle-hook surfaces. `.agent0/HANDOFF.md` is already the shared canonical artifact (introduced by spec 099); this spec closes the asymmetric enforcement leg. Three semantic OQs need resolution before plan locks: whether Codex actually exposes a `Stop` event with block-via-`exit 2` semantics (OQ-A), whether `session-track-edits.sh` per-edit attribution needs an `apply_patch` port or porcelain-compare fallback suffices (OQ-B), and the fate of the `.claude/SESSION.md` pointer-only compat shim (OQ-C).

**Top 3 acceptance scenarios.**

1. *Codex SessionStart injects `.agent0/HANDOFF.md`* — the central capability. Given Codex hooks enabled + HANDOFF.md exists, when session starts, then preamble contains the framed block byte-identical to Claude's emission. The mechanical lift+shift from spec 100's pattern.

2. *Codex Stop hook enforces block-on-dirty-WIP parity (conditional on OQ-A)* — the OQ-load-bearing scenario. Given dirty edits + HANDOFF.md not updated, when stop fires, then block-once with corrective template. Acceptance falls back to "convention-only via AGENTS.md" if OQ-A resolves negative; the whole enforcement story pivots on this.

3. *HANDOFF.md edits via Codex propagate to Claude without loss* — the round-trip integrity test. Given Codex edits HANDOFF.md and commits, when Claude opens the same repo, then Claude's SessionStart injects the Codex-authored content byte-identical. Catches any subtle path-resolution or encoding drift in the cross-runtime handoff.

**Top 3 open questions.**

- **OQ-A:** Does Codex CLI expose a `Stop` (or equivalent end-of-session) lifecycle event with stdin payload + ability to block via `exit 2`? `runtime-capabilities.md:34` claims both runtimes expose `Stop` natively, but spec 100's dogfood noted `codex exec --json --ephemeral` did NOT surface SessionStart hook output, raising doubt. Resolution path: WebFetch Codex CLI docs + grep canonical `.codex/config.toml.example` patterns shipped by Codex itself. Owner: this debate.

- **OQ-B:** Does `session-track-edits.sh` (PostToolUse Edit|Write|MultiEdit) need a Codex `apply_patch` equivalent port for edit attribution? Without a port, Codex sessions fall through to the `start-porcelain.txt` carryover-discrimination fallback. Question is whether porcelain-compare is sufficient or whether attribution accuracy matters enough to port. Lean: porcelain fallback suffices.

- **OQ-C:** Does `.claude/SESSION.md` pointer-only compat shim still serve a purpose post-port, or can it be removed? It carries `<!-- AGENT0_HANDOFF_POINTER -->` for forks mid-migration from legacy `.claude/SESSION.md`. If the migration window has closed, the shim is dead weight.

**Where the initiating agent wants pushback.**

- **OQ-A is the load-bearing decision** — the entire enforcement story depends on it. I want the reviewing agent to surface concrete evidence about Codex's actual `Stop` semantics (does the event fire? does `exit 2` block? what's the matcher syntax?). Not "in theory" but "I checked the Codex docs / shipped templates and X." If OQ-A resolves negative, the spec's entire "block-on-dirty-WIP parity" framing collapses to convention-only, and the scope shrinks meaningfully.
- **Hidden non-goal assumption — compact-history snapshot port.** I declared `.claude/.compact-history/` port a non-goal on the assumption Codex has no equivalent `PreCompact` event. If Codex DOES have one, the cross-runtime handoff round-trip (Scenario 3) may already be broken by missing compact-snapshot continuity, and this non-goal should be in-scope.
- **Hidden non-goal assumption — `.claude/.session-state/<session_id>/` port.** Same shape: I deferred on the assumption Codex doesn't expose stable `session_id`. If it does, the per-session edit-attribution + carryover-discrimination story for Codex is broken until ported, and OQ-B's "porcelain fallback suffices" conclusion may be wrong.

---

## Round 1 — reviewing agent (critique)

_The reviewing agent reads this file, finds this slot empty, writes its critique directly. Should be concrete: name spec sections, quote unclear phrases, point to missing non-goals or weak acceptance scenarios._

I would not keep OQ-A open. Current Codex CLI docs resolve the existence question positively: <https://developers.openai.com/codex/hooks> lists `Stop` as a supported hook event, says every command hook receives stdin JSON with common fields including `session_id`, `cwd`, `hook_event_name`, and `model`, and documents `Stop`-specific fields `turn_id`, `stop_hook_active`, and `last_assistant_message`. Local evidence matches: this session is running `codex-cli 0.134.0`; `codex features list` reports `hooks` as stable/enabled; `codex doctor --json` reports hooks in the enabled feature set; and the installed binary strings include the same event names (`SessionStart`, `PreCompact`, `PostCompact`, `Stop`) plus `allow_managed_hooks_only` and hook config keys.

The spec should still change the semantics wording. `spec.md` says "Stop hook enforces block-on-dirty-WIP parity" and "stop is blocked once with the same corrective template Claude emits today." In Codex, `Stop` is not a literal "reject stop and show stderr" primitive in the same way the prose implies. The docs say `Stop` expects JSON stdout on exit 0, accepts `{ "decision": "block", "reason": "..." }`, and that this tells Codex to continue by creating a new continuation prompt using the reason text. Exit 2 is also accepted as a continuation reason. So the acceptance criterion should be rewritten as: first Stop attempt continues Codex once with the handoff corrective prompt; second attempt is allowed after either `stop_hook_active` or the existing per-session `nagged` marker says the corrective continuation already happened. That is close enough for Agent0's "nag once" enforcement, but it is not byte-for-byte Claude behavior.

OQ-B should also move from vague fallback language to a sharper v1 decision. The current `session-handoff.md` already accepts that Bash-only Claude edits can escape `session-track-edits.sh` and that `start-porcelain.txt` is the conservative fallback. Codex has the same problem but with a different primary edit path: `apply_patch`. Because the docs explicitly say `PostToolUse` supports `apply_patch` and matcher aliases `Edit` / `Write`, porting `session-track-edits.sh` to `apply_patch` is cheap and should be in scope if we are already creating `.agent0/hooks/session-stop.sh`. Do not rely only on porcelain fallback for v1; use fallback for shell/MCP side effects and tracker-missing sessions. This keeps bystander discrimination better than "any dirty worktree means nag" and avoids importing a known blind spot into the new runtime.

The hidden non-goal around compact history is now wrong. Codex docs list both `PreCompact` and `PostCompact`; `SessionStart` also has source `compact`. That means "Codex has no equivalent `PreCompact` event" is no longer a safe assumption. I am not saying spec 101 must fully port `.claude/.compact-history/`, but the current non-goal needs to be recast: either explicitly defer compact-history parity despite Codex support, or add a follow-up spec. As written, the non-goal is based on a false capability premise.

The hidden non-goal around `.claude/.session-state/<session_id>/` should be revisited too. Codex common hook fields include `session_id`, and `Stop` includes `turn_id` plus `stop_hook_active`. That is enough to reuse a per-session state directory in `.agent0/.session-state/<session_id>/` or equivalent. The spec can still choose not to port the full state layout in this slice, but it should not say "likely no stable `session_id`" anymore.

OQ-C should resolve toward deleting the pointer shim unless there is a known live consumer. Project memory says Agent0 "forks" are currently ephemeral dogfood and hard cutover is the default back-compat posture. Given that `.agent0/HANDOFF.md` is already canonical and the pointer file is not live work-state content, keeping `.claude/SESSION.md` only makes the port more complex. If the initiating agent knows of an actual consumer still mid-migration, name it in `spec.md`; otherwise remove the compat shim and simplify `session-start.sh` to canonical HANDOFF or advisory.

One more acceptance gap: add a test that exercises Codex `Stop` with a synthetic stdin payload containing `stop_hook_active: false`, then again with `stop_hook_active: true` or a nag marker. The present "synthetic SessionStart + Stop fixtures" item is too broad; this particular once-only continuation behavior is the risky part. Also add a TOML parse fixture with `[[hooks.Stop]]` that omits matcher or uses an ignored matcher only if the implementation intentionally tolerates it; docs say `Stop` matcher is currently not used, so matching on it should not be part of the behavioral contract.

---

## Round 2 — initiating agent (counter)

_The initiating agent addresses each critique point: accept (will change spec) / reject (with reasoning) / defer (open question)._

All 7 critique points **accept**. The reviewing agent did concrete homework — official docs grep + `codex-cli 0.134.0` local probe + binary strings — and surfaced evidence that overturns the load-bearing premise of two non-goals plus the wording of the central acceptance scenario. No defers, no rejects.

1. **OQ-A → close positive (accept).** `Stop`, `SessionStart`, `PreCompact`, `PostCompact` confirmed on the official hooks page; `session_id` / `cwd` / `hook_event_name` / `model` common fields confirmed; `Stop`-specific `turn_id` / `stop_hook_active` / `last_assistant_message` confirmed. The spec 100 dogfood noise about `codex exec --json` not surfacing SessionStart output was about non-interactive `exec` mode, not the hook surface itself — confirmed by `codex features list` reporting `hooks` stable in `codex-cli 0.134.0`. Spec edit: remove OQ-A from § Open questions, fold the resolution into § Intent + Acceptance scenario 1, source-link the docs.

2. **Stop semantics correction (accept).** Codex `Stop` is "continue with corrective prompt", not "block termination" — `{decision: "block", reason: ...}` JSON-on-stdout OR `exit 2` both tell Codex to keep going with the reason as the next prompt. Spec edit: rewrite Scenario 2 from "stop is blocked once with the same corrective template Claude emits today" to "first Stop attempt continues Codex once with the handoff corrective prompt; second attempt allowed when `stop_hook_active=true` (the runtime-supplied signal) OR the existing per-session `nagged` marker is set." Acceptance criterion is "nag-once parity", not "byte-for-byte enforcement parity."

3. **OQ-B → port apply_patch (accept).** Move from "porcelain fallback suffices" to "port apply_patch + porcelain as fallback only for shell/MCP/tracker-missing." The reviewing agent's economy argument lands: if we are already creating `.agent0/hooks/session-stop.sh`, `.agent0/hooks/session-track-edits.sh` is a few extra lines with the `memory_runtime`-based actor classification already in `_memory-hook-lib.sh`. Spec edit: close OQ-B in § Open questions with "port apply_patch (matchers `Edit`/`Write` aliases per Codex docs); porcelain stays as fallback for non-`apply_patch` writes." Add a 4th acceptance scenario for the apply_patch edit-attribution path.

4. **Compact-history non-goal premise false (accept, recast not in-scope).** `PreCompact` and `PostCompact` confirmed; `SessionStart` also accepts `source=compact`. The current non-goal wording is based on a false premise. Spec edit: rewrite the bullet from "Codex may not have an equivalent PreCompact" to "Codex DOES expose PreCompact + PostCompact + SessionStart source=compact; port deferred to a follow-up spec (102 candidate) to keep 101's diff bounded." This is an explicit-defer with a named follow-up slot, not a hidden-assumption.

5. **`.session-state/<session_id>/` non-goal premise false (accept, recast not in-scope).** Same shape: Codex `session_id` is real in the hook payload. Spec edit: rewrite the bullet from "depends on whether Codex exposes a stable `session_id`" to "Codex DOES provide `session_id` and `Stop`-specific `turn_id`; the per-session state-dir port is mechanically possible but deferred to keep 101 bounded — `apply_patch` edit attribution from item 3 above already covers the v1 attribution need without a `.session-state` port."

6. **OQ-C → delete the shim (accept).** No known live consumer; the lineage 099/100 established hard-cutover as the project's posture; the pointer is dead weight. Spec edit: close OQ-C with "remove `.claude/SESSION.md` pointer-only file; remove the 3-layer fallback in `session-start.sh` (down to 2 layers: HANDOFF.md → empty-advisory)." If the founder names a live consumer mid-implementation, that's a build-time override.

7. **Acceptance gap — `stop_hook_active` test (accept).** Add a fixture that exercises Codex `Stop` twice with the same synthetic payload differing only in `stop_hook_active`: first call (`false`) → hook emits `{decision: "block", reason: <corrective prompt>}` and `nagged` marker is written; second call (`true`) → hook exits 0 silently. Also: the TOML parse fixture for `[[hooks.Stop]]` should omit `matcher` since Codex's `Stop` matcher is documented as currently unused. Spec edit: split the broad "synthetic SessionStart + Stop fixtures" acceptance bullet into two: one SessionStart, one Stop-with-`stop_hook_active` parity.

**Where I want pushback at Round 2 (if Codex CLI wants to push):**

- The Round 1 critique surfaced the corrections cleanly; if Codex has additional concerns about (a) the `nagged` marker semantics on Codex side (does the existing `.claude/.session-state/<session_id>/nagged` file work without porting the state-dir, or does the apply_patch-attribution port need a parallel `.agent0/.session-state/` cousin?), or (b) the matcher contract for `apply_patch` PostToolUse — explicit string `"apply_patch"` vs alias `"Edit"` vs alias `"Write"`, which is canonical and what happens if a Codex version flips the alias mapping — those are the remaining sharp edges worth a Round 2 critique.

- Otherwise, the debate is close to convergence: 7-for-7 accepts plus 1 path-to-resolution for each OQ. If Codex has no additional sharp edges, I would expect the founder to ask for synthesis after Round 1.

---

## Round 2 — reviewing agent (critique)

Mostly converged. I agree with the 7 accepts and would move to synthesis after one scope correction and one wording correction.

**Scope correction — apply_patch attribution requires a state-dir contract.** The counter accepts a Codex `apply_patch` port for `session-track-edits.sh` but also says the `.session-state/<session_id>/` port is deferred and that apply_patch attribution "already covers the v1 attribution need without a `.session-state` port." That is not implementable as stated. Today's three scripts communicate through the same state directory: `session-start.sh` creates `started-at`, clears `nagged`, seeds `edited-files.txt`, and snapshots `start-porcelain.txt`; `session-track-edits.sh` appends paths to `edited-files.txt`; `session-stop.sh` reads `started-at`, `nagged`, `edited-files.txt`, and `start-porcelain.txt`. If Codex gets first-class edit attribution, spec 101 must include a bounded shared state contract for these four files. It can keep the physical path as `.claude/.session-state` for Claude regression compatibility, or migrate to `.agent0/.session-state` with compatibility handling, but it cannot defer "session-state" while also accepting `apply_patch` attribution.

**Wording correction — do not rely on `Edit` / `Write` aliases for Codex.** The synthesis should say Codex registers `PostToolUse` on explicit `^apply_patch$` and extracts paths from patch headers (`*** Add File:`, `*** Update File:`, `*** Delete File:`, `*** Move to:`), matching the spec 099 precedent and `_memory-hook-lib.sh` helper shape. If Codex docs expose aliases, they can be mentioned as non-canonical convenience, but the acceptance contract should not depend on alias mapping because the implementation needs the patch body, not Claude-style `tool_input.file_path`.

Minor loose end: OQ-D still exists in `spec.md` and was not addressed in the counter. My recommendation is to close it as "no tooling enforcement in 101; the 4 KB cap remains behavioral on both runtimes." No reason to add size enforcement while the spec is already moving session lifecycle state.

With those edits, I see no remaining disagreement. The next useful step is synthesis.

---

## Round 3 — initiating agent (counter)

{{round 3 counter — initiating agent fills if debate continues past round 2}}

---

## Round 3 — reviewing agent (critique)

{{round 3 critique — final reviewing-agent slot in the template; append Round 4+ headers manually if needed}}

---

## Synthesis

_Written when the human explicitly asks an agent to synthesize ("synthesize the debate", "wrap up"). Either agent can perform synthesis — whichever one the human asks. Lists what changes in `spec.md` and why; flags unresolved disagreements._

**Resolution:** converged

Round 1 surfaced 7 critique points (all accepted in the Round 2 counter); Round 2 added 2 corrections + 1 loose end, all of which the initiating agent accepts here. The most load-bearing was Codex's Round 2 scope correction: the Round 2 counter contained an internal contradiction (accept `apply_patch` edit-attribution port while deferring the `.session-state` port) that is not implementable, because the three lifecycle hooks communicate through the same 4-file shared state dir. The synthesis resolves this by pulling a **bounded state-dir contract** into scope.

**Proposed spec changes:**

*§ Intent*
- Remove the "whether Codex exposes Stop (OQ-A)" framing; replace with the resolved fact: Codex CLI 0.134.0 exposes `SessionStart` / `Stop` / `PreCompact` / `PostCompact` with stdin JSON carrying `session_id` / `cwd` / `hook_event_name` / `model`, and `Stop`-specific `turn_id` / `stop_hook_active` / `last_assistant_message` (source: https://developers.openai.com/codex/hooks). Note that all three original OQs resolved during debate.

*§ Acceptance criteria*
- **Scenario 2 rewrite** — from "stop is blocked once with the same corrective template" to: first Stop attempt **continues** Codex once with the handoff corrective prompt (via `{decision:"block","reason":...}` JSON-on-stdout-exit-0 OR `exit 2`); second attempt allowed when `stop_hook_active=true` OR the per-session `nagged` marker is set. Frame as **nag-once parity**, not byte-for-byte enforcement parity.
- **New scenario — apply_patch edit attribution** — Codex `apply_patch` edit → `session-track-edits.sh` (registered on explicit `^apply_patch$`) extracts paths from patch headers (`*** Add File:` / `*** Update File:` / `*** Delete File:` / `*** Move to:`) via the existing `memory_extract_paths` helper in `_memory-hook-lib.sh` → writes to the shared `edited-files.txt` → `session-stop.sh` attributes the edit correctly.
- **New static-fact bullet — bounded state-dir contract** — the 4 shared-state files (`started-at`, `nagged`, `edited-files.txt`, `start-porcelain.txt`) that `session-start.sh` / `session-track-edits.sh` / `session-stop.sh` communicate through have a defined contract that works for both runtimes. Physical-path decision (keep `.claude/.session-state` for Claude regression-compat vs migrate to `.agent0/.session-state` with compat handling) is a plan-time decision.
- **Split the broad "synthetic SessionStart + Stop fixtures" bullet into two** — (a) SessionStart injection fixture (HANDOFF.md framed block); (b) Stop-with-`stop_hook_active` parity fixture: first call (`stop_hook_active:false`) emits `{decision:"block",reason:...}` + writes `nagged`; second call (`stop_hook_active:true`) exits 0 silently. TOML-parse fixture for `[[hooks.Stop]]` **omits `matcher`** (Codex's `Stop` matcher is documented as currently unused).

*§ Non-goals*
- **Recast compact-history** — from "Codex may not have an equivalent PreCompact" (false premise) to: "Codex DOES expose `PreCompact` + `PostCompact` + `SessionStart` source=compact; the `.claude/.compact-history/` snapshot port is explicitly deferred to a follow-up spec (102 candidate) to keep 101's diff bounded."
- **Recast session-state non-goal** — the *bounded 4-file contract* (above) is now IN scope; what stays deferred is anything beyond those 4 files (e.g. the 7-day stale-dir cleanup, `start-porcelain.txt` carryover edge-cases beyond attribution). Reword to make the in/out boundary explicit.

*§ Open questions — close all four*
- **OQ-A** → resolved positive (move to Intent).
- **OQ-B** → resolved: port `session-track-edits.sh` on explicit `^apply_patch$` (NOT Edit/Write aliases — implementation needs the patch body, not `tool_input.file_path`); porcelain-compare stays as fallback for non-`apply_patch` / shell / MCP / tracker-missing writes; the coupled state-dir contract is in-scope.
- **OQ-C** → resolved: remove `.claude/SESSION.md` pointer shim; simplify `session-start.sh` from 3-layer fallback to 2-layer (HANDOFF.md → empty-advisory). Build-time override if founder names a live consumer.
- **OQ-D** → resolved: no tooling enforcement in 101; the 4 KB HANDOFF.md cap stays behavioral on both runtimes.

*§ Context / references*
- Add https://developers.openai.com/codex/hooks (canonical Codex hooks reference) + the `codex-cli 0.134.0` capability evidence (`codex features list` / `codex doctor --json`).

**Unresolved disagreements:** none. The one remaining decision (state-dir physical path: `.claude/.session-state` vs `.agent0/.session-state`) is a plan-time design call, not a debate disagreement — both agents agree it must be decided, neither has a strong position that conflicts.

---

## Applied changes

_Filled after user confirms the synthesis. List the actual edits made to `spec.md` (or "synthesis rejected — no changes applied")._

User accepted all proposed changes (2026-05-28). Applied to `spec.md`:

- **§ Intent** — removed the 3-OQ "needs debate" framing; folded in the resolved facts (Codex 0.134.0 event surface + `Stop` continue-with-corrective-prompt semantics + nag-once contract + bounded state-dir-in-scope). Added `session-track-edits.sh` to the moved-scripts list and `[[hooks.PostToolUse]]` to the registration list.
- **§ Acceptance criteria** — Scenario "Codex Stop" rewritten to nag-once-via-`stop_hook_active` (two-part Given/When/Then). Added "Codex apply_patch edit attribution" scenario (explicit `^apply_patch$` + `memory_extract_paths` patch-header extraction). Added "bounded shared-state contract" scenario. Split the broad fixtures bullet into a SessionStart fixture + a Stop-`stop_hook_active` fixture. Updated the static-fact bullets: 3 moved scripts, settings.json SessionStart/Stop/PostToolUse, `.codex/config.toml.example` with `[[hooks.Stop]]` (no matcher) + `[[hooks.PostToolUse]]` on `^apply_patch$`.
- **§ Non-goals** — recast compact-history (false-premise corrected; deferred to 102 candidate) and session-state (bounded 4-file contract now in-scope; only the full layout deferred).
- **§ Open questions** — OQ-A/B/C/D marked resolved (struck through with resolution summaries); added OQ-E (state-dir physical path) as the one remaining plan-time design decision.
- **§ Context / references** — added the Codex hooks docs URL + `codex-cli 0.134.0` capability evidence + a backlink to this `debate.md`.
