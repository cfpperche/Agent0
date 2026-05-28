# 101 — session-handoff-multi-runtime

_Created 2026-05-28._

**Status:** shipped

## Intent

Port the session-handoff capacity from Claude-only to multi-runtime parity, continuing the spec 099 (memory) → spec 100 (SessionStart readouts) lineage. Move `.claude/hooks/session-start.sh` (SessionStart), `.claude/hooks/session-stop.sh` (Stop), and `.claude/hooks/session-track-edits.sh` (edit attribution) into `.agent0/hooks/` as shared canonical scripts; register them on both runtimes via their native lifecycle-hook surfaces (Claude through `.claude/settings.json`, Codex through commented `[[hooks.SessionStart]]` / `[[hooks.Stop]]` / `[[hooks.PostToolUse]]` blocks in `.codex/config.toml.example`). `.agent0/HANDOFF.md` is already the shared canonical artifact; this spec closes the last leg of asymmetric enforcement called out in `runtime-capabilities.md:45` ("session handoff" still framed as `convention` for Codex).

The cross-model debate (see `debate.md`) resolved all four pre-flight open questions. Codex CLI 0.134.0 exposes `SessionStart` / `Stop` / `PreCompact` / `PostCompact` hook events, with stdin JSON carrying common fields `session_id` / `cwd` / `hook_event_name` / `model` and `Stop`-specific fields `turn_id` / `stop_hook_active` / `last_assistant_message` (source: https://developers.openai.com/codex/hooks; confirmed locally via `codex features list` reporting `hooks` stable + `codex doctor --json`). Critically, Codex `Stop` is a **continue-with-corrective-prompt** primitive, not a block-termination one: a hook emits `{"decision":"block","reason":...}` JSON on stdout (exit 0) or `exit 2`, and Codex continues the session using the reason text as a new prompt. The enforcement contract is therefore **nag-once parity**, not byte-for-byte. Because edit attribution requires the three lifecycle hooks to share state, this spec also pulls a bounded 4-file state-dir contract into scope (see § Acceptance criteria).

## Acceptance criteria

- [x] **Scenario: Codex SessionStart injects `.agent0/HANDOFF.md`**
  - **Given** a Codex session with hooks enabled (`.codex/config.toml` uncommented from template) AND `.agent0/HANDOFF.md` exists with content
  - **When** the session starts (`startup` / `resume` / `clear` / `compact`)
  - **Then** the preamble contains the HANDOFF.md body inside the canonical `=== HANDOFF.md (canonical handoff) ===` framed block, byte-identical to what Claude Code emits for the same project state

- [x] **Scenario: Codex SessionStart from subdirectory resolves git root**
  - **Given** Codex started with `-C <repo>/apps/web` AND repo-root `.agent0/HANDOFF.md` exists
  - **When** the SessionStart hook fires
  - **Then** the hook reads `.agent0/HANDOFF.md` from the git toplevel (using the `memory_project_dir` chain from `_memory-hook-lib.sh` already established by spec 099/100)

- [x] **Scenario: Codex Stop hook nags once on dirty WIP (continue-with-corrective-prompt parity)**
  - **Given** a Codex session that edited files AND `.agent0/HANDOFF.md` was NOT updated after session start AND `stop_hook_active` is `false`
  - **When** the session attempts to stop
  - **Then** the hook emits `{"decision":"block","reason":<corrective prompt>}` (exit 0) OR `exit 2`, Codex continues once with the corrective prompt, AND the per-session `nagged` marker is written
  - **And Given** the same session attempts to stop a second time with `stop_hook_active` `true` OR the `nagged` marker set
  - **Then** the hook exits 0 silently (nag-once parity — not byte-for-byte block enforcement)

- [x] **Scenario: Codex apply_patch edit is attributed to the session**
  - **Given** a Codex session makes an edit via `apply_patch` AND `session-track-edits.sh` is registered on `^apply_patch$`
  - **When** the PostToolUse hook fires
  - **Then** it extracts the edited paths from the patch headers (`*** Add File:` / `*** Update File:` / `*** Delete File:` / `*** Move to:`) via the `memory_extract_paths` helper in `_memory-hook-lib.sh` and appends them to the shared `edited-files.txt`, so `session-stop.sh` attributes the edit correctly (not via Claude-style `tool_input.file_path`, which Codex does not provide)

- [x] **Scenario: HANDOFF.md edits via Codex propagate to Claude without loss**
  - **Given** a Codex session edits `.agent0/HANDOFF.md` and commits
  - **When** a Claude session opens the same repo
  - **Then** Claude's SessionStart injects the Codex-authored content byte-identical, no encoding or path-resolution drift

- [x] **Scenario: existing Claude SessionStart + Stop behavior preserved post-port**
  - **Given** Agent0 upstream after Phase A-D land
  - **When** a Claude Code session starts and later stops
  - **Then** HANDOFF injection, compact-history snapshot pairing, Stop-nag, `.claude/.session-state/<session_id>/` lifecycle, and `start-porcelain.txt` carryover discrimination all behave identically to pre-port (zero behavior regression)

- [x] **Scenario: synthetic SessionStart fixture validates HANDOFF injection without live Codex**
  - **Given** a temp project with `.agent0/HANDOFF.md` AND a synthetic Codex SessionStart stdin payload
  - **When** the ported `session-start.sh` runs against the payload
  - **Then** stdout contains the `=== HANDOFF.md (canonical handoff) ===` framed block AND subdir-launch resolution walks to the git root — no interactive Codex process required

- [x] **Scenario: synthetic Stop fixture validates nag-once via `stop_hook_active`**
  - **Given** a temp project with dirty WIP, no post-start HANDOFF update, AND two synthetic Codex Stop payloads differing only in `stop_hook_active` (`false` then `true`)
  - **When** the ported `session-stop.sh` runs against each
  - **Then** the first (`false`) emits `{"decision":"block",...}` + writes `nagged`; the second (`true`) exits 0 silently

- [x] **Scenario: bounded shared-state contract works for both runtimes**
  - **Given** the four shared-state files `started-at` / `nagged` / `edited-files.txt` / `start-porcelain.txt` that `session-start.sh` / `session-track-edits.sh` / `session-stop.sh` communicate through
  - **When** a Codex session and a Claude session each run the lifecycle
  - **Then** both read/write the same contract without one runtime's state corrupting the other's attribution (physical path — `.claude/.session-state` vs `.agent0/.session-state` — is a plan-time decision; see § Open questions)

- [x] `.agent0/hooks/session-start.sh`, `.agent0/hooks/session-stop.sh`, and `.agent0/hooks/session-track-edits.sh` exist, are executable, and source `_memory-hook-lib.sh` for project-dir resolution
- [x] Zero literal `${CLAUDE_PROJECT_DIR:-$PWD}` patterns in the moved scripts; resolution uses `memory_project_dir`
- [x] `.claude/settings.json` SessionStart / Stop / PostToolUse entries reference `.agent0/hooks/<name>.sh` (zero references to the old `.claude/hooks/session-*.sh` paths in settings)
- [x] `.codex/config.toml.example` contains commented `[[hooks.SessionStart]]`, `[[hooks.Stop]]` (omitting `matcher` — Codex's `Stop` matcher is documented as currently unused), and `[[hooks.PostToolUse]]` on `^apply_patch$` blocks paralleling the existing memory/readout blocks; an uncommented copy parses successfully via `python3 -c 'import tomllib; tomllib.loads(...)'`
- [x] `.claude/rules/runtime-capabilities.md` `session handoff` row updates from `convention` to `native-opt-in` for Codex CLI, with owner files reflecting the new `.agent0/hooks/` paths
- [x] `.claude/rules/session-handoff.md` § *Asymmetric enforcement* updates to describe the new (nag-once-parity) shape; the `.claude/SESSION.md` 3-layer fallback shrinks to a 2-layer (HANDOFF.md → empty-advisory)
- [x] Sync-harness `--apply --dry-run` against a fixture consumer dir shows the three `.agent0/hooks/session-*.sh` files propagate

## Non-goals

- Delegation/subagents Codex port — Codex has no Agent tool surface; remains `unsupported` in runtime-capabilities.
- Runtime-introspect Codex port — separate spec, different matcher decisions (`apply_patch` vs `Bash`).
- HANDOFF.md schema changes — 4-section shape (Current State / Active Work / Next Actions / Decisions & Gotchas) stays as canonical.
- Auto-migrating consumer projects — follows the spec 099/100 pattern: consumers manually `cp .codex/config.toml.example .codex/config.toml` + uncomment + update their own `.claude/settings.json`.
- Compact-history snapshot mechanism (`.claude/.compact-history/`) port to Codex — explicitly deferred to a follow-up spec (102 candidate) to keep 101's diff bounded. Note: Codex DOES expose `PreCompact` + `PostCompact` + `SessionStart` source=compact (the original "Codex may not have PreCompact" premise was false), so this is a scope-boundary decision, not a capability gap.
- Full `.claude/.session-state/<session_id>/` layout port — the **bounded 4-file contract** (`started-at` / `nagged` / `edited-files.txt` / `start-porcelain.txt`) is IN scope (it's coupled to the `apply_patch` edit-attribution port — see § Acceptance criteria). What stays deferred is everything beyond those four files: the 7-day stale-dir cleanup, and any `start-porcelain.txt` carryover edge-cases beyond basic attribution.

## Open questions

_All four pre-flight OQs were resolved in `debate.md` (Round 1 + Round 2, cross-model review with Codex CLI). One plan-time design decision remains._

- [x] ~~**OQ-A: Does Codex expose a `Stop` event?**~~ → **Resolved: yes.** Codex CLI 0.134.0 exposes `Stop` (+ `SessionStart` / `PreCompact` / `PostCompact`). `Stop` is a continue-with-corrective-prompt primitive (`{"decision":"block","reason":...}` or `exit 2`), not block-termination. Enforcement contract = nag-once parity. Folded into § Intent + the Stop scenario.
- [x] ~~**OQ-B: Does `session-track-edits.sh` need an `apply_patch` port?**~~ → **Resolved: yes, port it.** Register on explicit `^apply_patch$` (NOT Edit/Write aliases — the implementation needs the patch body, not `tool_input.file_path`); extract paths via the existing `memory_extract_paths` helper. Porcelain-compare stays as fallback for non-`apply_patch` / shell / MCP / tracker-missing writes. The coupled 4-file state-dir contract is therefore in-scope.
- [x] ~~**OQ-C: Keep or remove `.claude/SESSION.md` pointer shim?**~~ → **Resolved: remove.** No known live consumer; hard-cutover is the project's posture. Drop the shim; simplify `session-start.sh` from a 3-layer fallback to 2-layer (HANDOFF.md → empty-advisory). Build-time override if a live consumer surfaces.
- [x] ~~**OQ-D: 4 KB HANDOFF.md cap enforcement on Codex?**~~ → **Resolved: no tooling enforcement.** The cap stays behavioral on both runtimes; no Stop-side size check.

- [x] ~~**OQ-E (plan-time design decision): state-dir physical path — keep `.claude/.session-state/` or migrate to `.agent0/.session-state/`?**~~ → **Resolved: keep `.claude/.session-state/`.** The 4-file shared-state contract (`started-at` / `nagged` / `edited-files.txt` / `start-porcelain.txt`) remains at `.claude/.session-state/<session_id>/` for both runtimes. This preserves Claude regression compatibility, keeps `.claude/tools/probe.sh` working, and follows the spec 099/100 precedent that hooks move to `.agent0/hooks/` while established project-local state stays under `.claude/`.

## Context / references

- `docs/specs/099-memory-multi-runtime/` — direct precedent (memory hooks port; same shape: shared canonical script in `.agent0/hooks/`, both runtimes register via native lifecycle-hook surface, `.codex/config.toml.example` carries commented blocks).
- `docs/specs/100-multi-runtime-session-readouts/` — second precedent (SessionStart readouts port; established the `memory_project_dir` subdir-launch resolution and `memory_runtime` classification helpers).
- `.claude/rules/runtime-capabilities.md` § *Capability matrix* line 31 (`session handoff` row) and line 45 (re-audit pending note) — this spec closes the first of the three pending rows.
- `.claude/rules/session-handoff.md` — current canonical rule with `## Asymmetric enforcement` section describing the Claude-native / Codex-convention split this spec aims to symmetrize (subject to OQ-A).
- `.claude/hooks/session-start.sh` / `.claude/hooks/session-stop.sh` — source files to move into `.agent0/hooks/`.
- `.claude/hooks/session-track-edits.sh` — adjacent hook; port decision in OQ-B.
- `.agent0/HANDOFF.md` — the shared canonical artifact; content stays project-local, schema stays unchanged.
- `.agent0/hooks/_memory-hook-lib.sh` — provides `memory_project_dir` (subdir → git root) and `memory_runtime` (apply_patch + SessionStart → Codex classification) helpers; reused without modification.
- `.codex/config.toml.example` — destination for new commented `[[hooks.SessionStart]]` (and conditional `[[hooks.Stop]]`) blocks.
- `.agent0/HANDOFF.md` § *Decisions & Gotchas* — spec 100 noted `codex exec --json` did not surface SessionStart output; the debate clarified that was about non-interactive `exec` mode, not the hook surface itself.
- https://developers.openai.com/codex/hooks — canonical Codex CLI hooks reference; resolved OQ-A (event list, common stdin fields, `Stop` continue-with-corrective-prompt semantics, `Stop` matcher currently unused). Local capability evidence: `codex features list` (hooks stable) + `codex doctor --json` on `codex-cli 0.134.0`.
- `docs/specs/101-session-handoff-multi-runtime/debate.md` — cross-model review with Codex CLI that resolved all four pre-flight OQs and surfaced the `apply_patch`/state-dir coupling correction.
