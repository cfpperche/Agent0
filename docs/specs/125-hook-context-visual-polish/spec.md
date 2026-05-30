# 125 — hook-context-visual-polish

_Created 2026-05-30._

**Status:** shipped

## Intent

Spec 124 collapsed five model-visible `SessionStart` readouts into one bounded `startup-brief.sh` and switched prompt-turn injection to bounded capsules — it fixed the **volume** of injected hook context. It did not address how that context **renders for the human** in the live Claude Code UI: the `hook context` block (both the SessionStart brief and the per-turn `AGENT0_CONTEXT_INJECTION` capsules) is flattened into long, hard-to-scan lines because the runtime's renderer collapses the newlines that the hook scripts emit. The model-visible payload is correct; this is a purely human-facing legibility problem. The intent is to make the startup brief and prompt capsules scannable for the human reviewer without changing what the model receives — minimizing further, restructuring the emitted text so it survives flattening, or hiding the block from the human while preserving the model channel, whichever the runtime actually permits. If official CC docs plus live dogfood show no supported render or model-only control AND text reduction would cost useful signal, the spec is satisfied by a documented infeasibility/kill note in `notes.md` with no hook change — a research-only close is a valid success outcome here, not a failure, consistent with the optional/cosmetic framing.

## Acceptance criteria

_Observable outcomes. The model-visible contract from spec 124 must not regress. Success is objective: every box ticks against a named artifact, not a subjective impression. The line-length / delimiter-scheme detail behind the "boundary marker" criteria is deferred to `plan.md`, contingent on the feasibility finding below._

- [x] **Scenario: Startup brief is objectively delimited in the live CC UI**
  - **Given** a fresh Claude Code session in this repo
  - **When** the `SessionStart` `startup-brief.sh` hook fires
  - **Then** each of `handoff` / `reminders` / `context` carries a recognizable section label that survives the renderer's flattening

- [x] **Scenario: Per-turn capsules carry a boundary marker**
  - **Given** an interactive prompt turn
  - **When** `context-inject.sh` emits the `AGENT0_CONTEXT_INJECTION` capsule block
  - **Then** each selected-rule capsule has exactly one visible boundary marker in the flattened view, so capsules are countable and separable

- [x] **Scenario: Model-visible contract does not regress (semantic + per-runtime)**
  - **Given** the spec-124 model-visible payload (one startup brief, one prompt-capsule block when rules are selected, no full rule bodies, all facts/instructions preserved)
  - **When** this change ships
  - **Then** the same semantic content is delivered AND each runtime's envelope still parses — CC `hookSpecificOutput.additionalContext` JSON; Codex raw stdout — verified by the existing context-injection / readout-parse suites passing unchanged

- [x] **Scenario: Codex consumption does not regress**
  - **Given** the shared hook scripts after this change
  - **When** run under `memory_runtime=codex-cli`
  - **Then** the Codex startup/prompt output remains as machine-consumable and as readable as before — no CC-tuned delimiter or truncation degrades it

- [x] **Scenario: Live proof artifacts captured (manual dogfood, not an automated gate)**
  - **Given** the change is implemented
  - **When** verifying delivery
  - **Then** (a) a fresh CC session transcript/screenshot shows the improved render AND (b) a Codex hook-output probe (`bash .agent0/hooks/startup-brief.sh` under `memory_runtime=codex-cli`) confirms the shared script stays consumable

- [ ] **Terminal research/kill path is a valid satisfaction.** If official CC docs + live dogfood show no supported render/model-only control AND text reduction would remove useful signal, the spec is delivered by a documented infeasibility/kill note in `notes.md` with no hook change — `abandoned` counts as the spec satisfied, not failed.
- [x] The fix is implemented in the runtime-neutral hook scripts (`startup-brief.sh` / `context-inject.sh`) and/or tracked project config, never by deleting model-visible content
- [x] Any behavior asserted about how Claude Code renders `additionalContext` is verified against official CC docs before being relied on (per `feedback_verify_runtime_capabilities`)

## Non-goals

- Reducing the **amount** of injected context — that was spec 124's job; this spec is legibility only, not volume.
- Reintroducing `.claude/rules/*.md` or full rule bodies into the prompt — capsules-as-pointers stays.
- Changing the Codex CLI rendering path beyond keeping the shared hook output consumable by it (Codex must not break, but its UI polish is out of scope unless the fix is free there).
- Building any new observability/diagnostic surface for hook output — `AGENT0_CONTEXT_DIAGNOSTIC=1` already exists and is sufficient.
- Any fix that lives only in founder-local UI/runtime state (e.g. `~/.claude/settings.json`) and would not propagate to a fresh fork via sync-harness — a shipped fix must live in tracked `.agent0/hooks/*` or tracked project config (named in `plan.md`).

## Open questions

- [ ] **Does Claude Code expose any control over how `additionalContext` is rendered to the human?** If the renderer unconditionally flattens newlines and offers no "model-only" channel, options (a) preserve-newlines and (b) hide-from-human are both infeasible and the spec collapses to (c) reduce-text. Owner: verify against CC hooks docs before planning — this is the load-bearing unknown. (This is exactly the runtime-capability-claim class that `feedback_verify_runtime_capabilities` governs.)
- [ ] **Is this worth doing at all?** The HANDOFF marks spec 125 as optional/cosmetic. If the only feasible lever is "emit even less text," does the marginal legibility gain justify shrinking already-useful startup signal? Owner: user decides at synthesis.
- [ ] **Does flattening actually hurt the human, or only look ugly?** No reported instance of the flattened block causing a missed reminder or handoff item. Without a concrete pain instance this risks being speculative polish (cf. `feedback_speculative_observability` rule-of-three). Owner: user confirms a real pain instance or downgrades scope.

## Context / references

- `docs/specs/124-hook-context-noise-control/` — predecessor; solved volume, explicitly deferred this UI cosmetics follow-up.
- `.agent0/hooks/startup-brief.sh` — `emit_context()` wraps output as `{hookSpecificOutput:{additionalContext}}` for Claude Code; newlines are real in the string, flattening happens downstream in the renderer.
- `.agent0/hooks/context-inject.sh` — per-turn capsule emitter (`prompt-capsules` mode).
- `.agent0/context/rules/runtime-capabilities.md` — provider-neutral capability matrix; consult before asserting CC render behavior.
- `.agent0/HANDOFF.md` § Next Actions #1 + § Decisions & Gotchas ("Spec 124 solved volume, not UI cosmetics").
- Memory: `feedback_verify_runtime_capabilities`, `feedback_speculative_observability`.
