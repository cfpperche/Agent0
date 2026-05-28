# 101 — session-handoff-multi-runtime — plan

_Drafted from `spec.md` on 2026-05-28. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Mirror the spec 099/100 per-capacity port shape: move the three session-lifecycle hooks from `.claude/hooks/` to `.agent0/hooks/`, source `_memory-hook-lib.sh` for project-dir resolution + runtime classification, repoint Claude's `.claude/settings.json` registrations, and add commented Codex blocks to `.codex/config.toml.example`. Three scripts move: `session-start.sh` (SessionStart), `session-stop.sh` (Stop), `session-track-edits.sh` (PostToolUse edit attribution). The debate (`debate.md`) resolved all four pre-flight OQs; this plan resolves the one remaining design decision (OQ-E) and sequences the work.

**OQ-E resolution — keep `.claude/.session-state/`, do NOT migrate to `.agent0/.session-state/`.** The established precedent from spec 099/100 is "the hook scripts move to `.agent0/hooks/`; the state/data they read stays under `.claude/`" (spec 100 § Non-goals: "No move of `.claude/reminders.yaml`, `.claude/routines/`, `.claude/.routines-state/` to `.agent0/`. Only the three hook scripts move"). Two concrete forces make keep the right call: (1) `.claude/tools/probe.sh` reads `.claude/.session-state/*/started-at` as its session-boundary signal (documented cross-capacity dependency in `session-handoff.md`); migrating would silently break the probe unless `probe.sh` is also edited — scope creep into a Tier-mixed change. (2) `.runtime-state/README.md` documents `.claude/.session-state/` as a project-local state dir. Keeping the path means zero migration risk for in-flight Claude sessions and zero collateral edits. The 4-file shared-state contract (`started-at` / `nagged` / `edited-files.txt` / `start-porcelain.txt`) lives at `.claude/.session-state/<session_id>/` for both runtimes.

The three hooks differ in how much real adaptation each needs:

- **`session-stop.sh` — smallest delta.** It already emits `{"decision":"block","reason":...}` JSON, which IS the Codex Stop continue-with-corrective-prompt contract. The only behavioral addition is honoring the runtime-supplied `stop_hook_active` field (read from the Stop payload) alongside the existing `nagged` file-mtime check, per the spec's nag-once scenario.
- **`session-track-edits.sh` — medium delta.** It reads Claude-only `tool_input.file_path`. Replace that extraction with the existing `memory_extract_paths` helper from `_memory-hook-lib.sh`, which already parses BOTH `tool_input.file_path` (Claude Edit/Write) AND `apply_patch` patch headers (`*** Add File:` / `*** Update File:` / `*** Delete File:` / `*** Move to:`) — so one substitution covers both runtimes. Register on `^apply_patch$` for Codex; keep `Edit|Write|MultiEdit` for Claude.
- **`session-start.sh` — largest delta (output envelope).** It emits a Claude-specific dual-channel JSON object (`hookSpecificOutput.additionalContext` + `systemMessage`). The Codex SessionStart additionalContext contract is the top open risk (see § Risks). Approach: runtime-branch the final emit — keep the JSON dual-channel for Claude (zero regression), emit the plain framed banner to stdout for Codex (matching the spec 100 readout hooks that already work on Codex). Also drop the legacy `.claude/SESSION.md` branch (OQ-C), shrinking the 3-layer fallback to 2-layer (HANDOFF.md → empty-advisory).

Sequencing runs in six phases, each verifiable before the next: A `session-stop.sh` (smallest, proves the pattern), B `session-track-edits.sh` (helper substitution), C `session-start.sh` (output-envelope branch + SESSION.md removal), D registrations + old-path deletion + SESSION.md file removal, E docs, F tests + validation. Each phase keeps the hooks functional at the commit boundary.

## Files to touch

**Create:**
- `.agent0/hooks/session-start.sh` — port of `.claude/hooks/session-start.sh`; `memory_project_dir` substitution; runtime-branched output envelope (JSON for Claude, plain framed text for Codex); legacy SESSION.md branch removed (2-layer fallback).
- `.agent0/hooks/session-stop.sh` — port; `memory_project_dir` substitution; honor `stop_hook_active` payload field alongside `nagged` marker.
- `.agent0/hooks/session-track-edits.sh` — port; `memory_project_dir` substitution; `memory_extract_paths` replaces the `tool_input.file_path`-only extraction (covers `apply_patch`).
- `.claude/tests/session-handoff-multi-runtime/01-sessionstart-injection.sh` — synthetic Codex SessionStart fixture asserts the `=== HANDOFF.md (canonical handoff) ===` framed block.
- `.claude/tests/session-handoff-multi-runtime/02-stop-nag-once.sh` — two Stop payloads differing only in `stop_hook_active`; first emits `{"decision":"block",...}` + writes `nagged`, second exits 0 silently.
- `.claude/tests/session-handoff-multi-runtime/03-apply-patch-attribution.sh` — synthetic `apply_patch` PostToolUse payload; asserts edited paths land in `edited-files.txt`.
- `.claude/tests/session-handoff-multi-runtime/04-subdir-resolution.sh` — SessionStart payload with `.cwd` in a subdir; asserts git-root resolution.
- `.claude/tests/session-handoff-multi-runtime/05-toml-parse.sh` — uncomment the new `[[hooks.SessionStart]]` / `[[hooks.Stop]]` / `[[hooks.PostToolUse]]` blocks; assert `tomllib` parses.
- `.claude/tests/session-handoff-multi-runtime/06-claude-regression.sh` — Claude-shape payloads still produce the JSON dual-channel output + nag behavior.
- `.claude/tests/session-handoff-multi-runtime/run-all.sh` — lex-order runner (mirror `codex-mcp-recipes/run-all.sh`).

**Modify:**
- `.claude/settings.json` — repoint SessionStart `session-start.sh`, Stop `session-stop.sh`, PostToolUse `session-track-edits.sh` from `.claude/hooks/` to `.agent0/hooks/`.
- `.codex/config.toml.example` — add commented `[[hooks.SessionStart]]`, `[[hooks.Stop]]` (no `matcher`), `[[hooks.PostToolUse]]` (matcher `^apply_patch$`) blocks for the three hooks.
- `.claude/rules/session-handoff.md` — § *Asymmetric enforcement* rewritten to the nag-once-parity multi-runtime shape; § *SessionStart fallback* shrinks 3-layer → 2-layer; remove `.claude/SESSION.md` references; document `stop_hook_active`.
- `.claude/rules/runtime-capabilities.md` — `session handoff` row Codex `convention` → `native-opt-in`; owner files updated to `.agent0/hooks/session-*.sh`; shorten the line-45 re-audit note (remove `session handoff`).
- `.agent0/HANDOFF.md` — refreshed at session end per the size-discipline rule.

**Delete:**
- `.claude/hooks/session-start.sh`, `.claude/hooks/session-stop.sh`, `.claude/hooks/session-track-edits.sh` — moved to `.agent0/hooks/`.
- `.claude/SESSION.md` — pointer-only compat shim (OQ-C resolved: remove). Verify it is pointer-only (first non-blank line is the `<!-- AGENT0_HANDOFF_POINTER -->` marker) before deleting; if it carries live content, STOP and surface to the user.

## Alternatives considered

### OQ-E alternative — migrate state dir to `.agent0/.session-state/`

Rejected because it forces collateral edits to `.claude/tools/probe.sh` (reads `.claude/.session-state/*/started-at`) and `.runtime-state/README.md`, plus a compat-handling path for in-flight Claude sessions whose SessionStart already wrote markers under the old path. The spec 099/100 precedent ("hooks move, state stays under `.claude/`") is established and consistent; migrating would be a gratuitous namespace change with real regression surface and no functional gain — both runtimes read the same path either way.

### Output envelope — always emit plain framed text (drop the JSON dual-channel)

Rejected because Claude's `systemMessage` channel is what renders the handoff as a user-visible banner at session boot (CC v2.1.0+ silently drops plain SessionStart stdout from the user-visible surface — documented in the current hook's comments). Dropping the JSON envelope would regress the Claude user-visible banner. The runtime-branch keeps both behaviors correct.

### Bundle compact-history port into this spec

Rejected (already a spec Non-goal): Codex exposes `PreCompact`/`PostCompact`, so it's technically possible, but `pre-compact.sh` + the `.claude/.compact-history/` snapshot machinery is a separable concern with its own semantic surface. Bundling would balloon 101's diff. The session-start.sh compact-history injection block is left intact and is a harmless no-op on Codex (graceful when the dir is absent). Deferred to a 102 candidate.

## Risks and unknowns

- **TOP RISK — Codex SessionStart output contract.** The Claude hook emits `{hookSpecificOutput:{hookEventName,additionalContext}, systemMessage}`. Whether Codex SessionStart consumes that JSON envelope, expects plain stdout, or uses a different additionalContext shape is unverified. Mitigation: WebFetch the Codex hooks docs (https://developers.openai.com/codex/hooks) for the SessionStart output contract BEFORE writing the emit branch; cross-check against how `.agent0/hooks/memory-decay-readout.sh` (works on Codex per spec 099) emits. If the contract is plain-stdout, the Codex branch emits the framed banner directly; if JSON, mirror the Claude shape with Codex's field names. This is the one task that must do research-first.
- **`stop_hook_active` semantics.** The spec assumes `stop_hook_active=true` on the second Stop invocation means "already nagged this turn". Need to confirm from the docs that Codex sets it the way Claude does (Claude's `stop_hook_active` indicates a Stop hook is already in the continuation loop). If Codex semantics differ, fall back to the `nagged` file-mtime check alone (which already works runtime-agnostically).
- **`memory_extract_paths` path normalization.** The current tracker normalizes absolute → project-relative via `realpath --relative-to`. `memory_extract_paths` returns paths relative to the project already (via `memory_relpath`). Verify the tracker's dedup/append logic still matches what `session-stop.sh`'s ` <path>` porcelain suffix-grep expects — a path-shape mismatch between writer and reader would silently break attribution.
- **Existing session-hook tests.** There may be a `.claude/tests/` suite already exercising `session-start.sh` / `session-stop.sh` (the handoff capacity predates this spec). Must locate and repoint/preserve them in Phase F, not just add new fixtures. Check before Phase D deletion.
- **`.claude/SESSION.md` live-content guard.** The delete assumes pointer-only. If a stray consumer (or this repo) left real content there, deletion loses it. Phase D task gates on the first-non-blank-line marker check.

## Research / citations

- https://developers.openai.com/codex/hooks — canonical Codex hooks reference; resolved the event surface + `Stop` continue-with-corrective-prompt semantics + common stdin fields in `debate.md`. Re-consult for the SessionStart output contract (top risk).
- `docs/specs/099-memory-multi-runtime/` + `docs/specs/100-multi-runtime-session-readouts/` — the per-capacity port precedent (shared `.agent0/hooks/` script, `.codex/config.toml.example` commented blocks, "state stays under `.claude/`" convention).
- `docs/specs/101-session-handoff-multi-runtime/debate.md` — cross-model review resolving OQ-A/B/C/D + the `apply_patch`/state-dir coupling correction.
- `.agent0/hooks/_memory-hook-lib.sh` — `memory_project_dir`, `memory_runtime`, `memory_extract_paths` helpers reused without modification.
- `.claude/hooks/session-{start,stop,track-edits}.sh` — source files (read for the port; behavior preserved except the documented deltas).
