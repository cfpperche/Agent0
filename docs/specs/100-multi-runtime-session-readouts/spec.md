# 100 — multi-runtime-session-readouts

_Created 2026-05-27._

**Status:** shipped

## Intent

Port the three runtime-neutral `SessionStart` readout hooks (`reminders-readout.sh`, `routines-readout.sh`, `mcp-recipes-hint.sh`) from `.claude/hooks/` to `.agent0/hooks/` so Codex CLI sessions receive the same framed context blocks Claude Code sessions receive today. This is the Tier 1 follow-up to spec 099 (memory-multi-runtime), continuing the per-capacity port pattern: shared canonical script in `.agent0/hooks/`, both runtimes register via their native lifecycle-hook surface (Claude via `.claude/settings.json`; Codex via `.codex/config.toml.example` opt-in block).

Two of the three (`reminders-readout.sh`, `routines-readout.sh`) are pure readout-parity work: same block frame on both runtimes, allowing runtime-specific wording for install pointers and YAML-fallback degradation. The third — `mcp-recipes-hint.sh` — overturns spec 098's explicit decision that "Codex does not receive the Claude `SessionStart` MCP hint". The reversal is incidental, not substantive: spec 098 was scoped to MCP recipe activation and predated the spec 099 multi-runtime hook mechanism; with that mechanism now in place, the only mcp-recipes-specific delta is runtime-aware (or neutral) wording for install pointers in the emitted block. All three hooks ship in this one spec; splitting `mcp-recipes-hint.sh` was considered and rejected because the port mechanism is identical and the wording delta is ~10 LOC, not a separate spec's worth of concerns. The `SessionStart` event itself is identical-surface in both runtimes, but Codex-specific runtime concerns (project-dir resolution from subdir launch, optional Python+PyYAML, trust-review posture, env-var naming) require explicit handling encoded as acceptance scenarios below.

## Acceptance criteria

- [x] **Scenario: Codex reminders readout fires at SessionStart**
  - **Given** a project with `.claude/reminders.yaml` containing at least one pending entry AND Codex hooks enabled in `.codex/config.toml`
  - **When** a fresh Codex CLI session starts (`source ∈ {startup, resume, clear, compact}`)
  - **Then** the session preamble contains the `=== REMINDERS ===` framed block with the same surfaceable reminder set Claude Code emits for the same project, allowing YAML-fallback degradation as advised when PyYAML and yq are absent (see degraded-fallback scenario below)

- [x] **Scenario: Codex routines readout fires at SessionStart**
  - **Given** a project with pending queue entries in `.claude/.routines-state/<slug>/queue/` AND Codex hooks enabled
  - **When** a fresh Codex CLI session starts
  - **Then** the session preamble contains the `=== ROUTINES ===` framed block with the same queue entries Claude emits, dispatch instructions matching the same format

- [x] **Scenario: Codex MCP-recipes hint fires at SessionStart**
  - **Given** a project whose stack signals match one or more recipe rows (e.g. Next.js, Laravel, image-gen) AND Codex hooks enabled
  - **When** a fresh Codex CLI session starts
  - **Then** the session preamble contains the `=== mcp-recipes ===` framed block with the same recipe list Claude emits, with install-pointer wording adapted to point at `.codex/config.toml.example` instead of `.mcp.json.example` (or neutral wording naming both)

- [x] **Scenario: hook-disabled or pending-trust Codex session does not emit readouts**
  - **Given** a project with Codex hooks disabled (`[features].hooks = false`, block commented out, OR repo-local hooks not yet trusted in Codex)
  - **When** Codex CLI starts
  - **Then** no readout blocks appear AND no error is raised; if the pending-trust path applies, a one-line advisory directs the user to the Codex trust-review path

- [x] **Scenario: existing Claude Code behavior is preserved post-port**
  - **Given** Agent0 upstream after the port + Claude Code session in any project
  - **When** the session starts
  - **Then** Claude continues to emit the three blocks identically to pre-port behavior (settings.json `SessionStart` entries now reference `.agent0/hooks/`)

- [x] **Scenario: Codex SessionStart fired from subdirectory launch**
  - **Given** Codex started with `-C <repo>/apps/web` (or hook command resolved at depth-N from the git root)
  - **When** `SessionStart` hooks fire
  - **Then** all three readouts resolve the git root and operate against root-relative state files (`.claude/reminders.yaml`, `.claude/.routines-state/`, root-detected stack signals)

- [x] **Scenario: Codex reminders readout without PyYAML and without yq**
  - **Given** the environment lacks both Python+PyYAML and yq
  - **When** the readout fires
  - **Then** it emits raw-YAML content framed by `=== REMINDERS ===` AND a `reminders-degraded-advisory:` line on stderr; non-surfaceable entries (snoozed-in-future, done) MAY appear in the block

- [x] `.agent0/hooks/reminders-readout.sh`, `.agent0/hooks/routines-readout.sh`, `.agent0/hooks/mcp-recipes-hint.sh` exist, are executable, and are behaviorally-equivalent to the prior `.claude/hooks/` versions
- [x] Zero literal `$CLAUDE_PROJECT_DIR` references in the moved scripts; project-dir resolution uses the `_memory-hook-lib.sh` precedence chain (`AGENT0_PROJECT_DIR` → `CLAUDE_PROJECT_DIR` → stdin `.cwd` → `git rev-parse --show-toplevel` → `pwd`)
- [x] `.claude/settings.json` `SessionStart` entries reference `.agent0/hooks/<name>.sh` for the three migrated hooks (zero references to the old `.claude/hooks/<name>.sh` paths in settings.json)
- [x] `.codex/config.toml.example` contains commented-out `[[hooks.SessionStart]]` blocks for all three hooks, paralleling the existing `memory-decay-readout` block
- [x] The three `[[hooks.SessionStart]]` blocks in `.codex/config.toml.example`, when uncommented, parse successfully via `python3 -c 'import tomllib; tomllib.loads(...)'` or equivalent — mechanical guard against TOML shape errors
- [x] `.claude/rules/runtime-capabilities.md` updates: `reminders`, `routines`, and `mcp recipes` rows (or equivalent capability lines) reflect Codex moving from `convention` to `native-opt-in`
- [x] `.claude/rules/mcp-recipes.md` revises the explicit "only Claude receives the SessionStart stack hint" line
- [x] Sync-harness manifest carries the three new `.agent0/hooks/` paths (via existing globs or explicit entry); a dry-run on a fixture project shows the files propagate
- [x] A synthetic `SessionStart` fixture (stdin payload + temp project dir) drives each of the three hooks and produces the expected framed block on stdout — no live Codex required for acceptance

## Non-goals

- Tier 2-5 hook ports (post-edit advisories, Bash gates, runtime introspect, session handoff lifecycle, delegation/subagents). These carry semantic decisions (matcher divergence, sub-agent absence in Codex, `PostToolUseFailure` gap) and ship in follow-up specs.
- Hooks that don't apply to Codex by design (`rule-load-debug.sh` — `InstructionsLoaded` is Claude-only; `delegation-gate.sh` / `delegation-stop.sh` — Codex has no Agent tool).
- Migration of `.claude/tools/*` runtime-neutral scripts (`probe.sh`, `sync-harness.sh`, `install-routines.sh`, `lib/`, etc.) to `.agent0/tools/`. Cosmetic re-namespacing, not multi-runtime parity; tracked separately.
- Auto-migrating consumer projects. Spec 099 established the pattern (consumers manually pull + opt in); this spec follows the same pattern.
- No move of `.claude/reminders.yaml`, `.claude/routines/`, `.claude/.routines-state/`, or `.claude/rules/mcp-recipes.md` to `.agent0/`. Only the three hook scripts move; the data and rules they read stay under `.claude/`.
- Readout parity does NOT prevent multiple sessions (Claude + Codex on the same machine, or two parallel sessions of either) from seeing the same routines queue. Dispatch consumption happens in `/routine run <slug>`; idempotency there is a separate concern owned by routines, not this spec.

## Open questions

- [x] ~~**Compat shim or hard cutover?**~~ → **Resolved 2026-05-27:** hard cutover, no shims. Three hooks is below the threshold where transitional shims pay for themselves, and spec 099's same-day shim removal showed the follow-up cost is effectively zero.
- [x] ~~**`mcp-recipes-hint.sh` Claude-only design reversal AND bundle-vs-split decision.**~~ → **Resolved 2026-05-27:** (a) the reversal is **incidental**, not substantive — spec 098 left `mcp-recipes-hint.sh` Claude-only because that spec was scoped to MCP recipe activation and predated the spec 099 multi-runtime hook mechanism; the resolved OQ in spec 098 explicitly says "leave runtime hints unchanged" because there was no Codex hook surface to port them to at the time. Codex CLI as reviewing agent (debate.md Round 1) confirmed "I do not see a Codex runtime reason to keep the stack-detector Claude-only" — the only adaptation needed is install-pointer wording in the emitted block. (b) **Keep all three bundled** in spec 100. Splitting was rejected because the port mechanism is identical across the three hooks and the mcp-recipes-specific delta (~10 LOC of runtime-aware or neutral wording) does not justify separate plan + tasks overhead. Auditability of the spec 098 reversal is preserved via the explicit § Intent paragraph and this resolved-OQ entry.
- [x] ~~**Shared library extraction for the three readouts.**~~ → **Resolved 2026-05-27:** no new `_readout-hook-lib.sh`. The three scripts source `_memory-hook-lib.sh` for project-dir and runtime helpers; readout framing stays inlined until a fourth readout creates real extraction pressure.
- [x] ~~**Env var naming: `CLAUDE_*` vs `AGENT0_*` canonical names.**~~ → **Resolved 2026-05-27:** retain `CLAUDE_*` as the canonical public contract and honor `AGENT0_*` aliases in shared hooks. A broader canonical-name flip is deferred to a cross-cutting follow-up.

## Context / references

- `docs/specs/099-memory-multi-runtime/` — direct precedent (spec, plan, migration playbook, debate). Same shape: shared canonical script in `.agent0/hooks/`, both runtimes register via native lifecycle-hook surface, `.codex/config.toml.example` carries commented-out blocks.
- `.claude/rules/runtime-capabilities.md` § *Capability matrix* line 34 — Codex `lifecycle hooks` is `native`; SessionStart event is identical-surface across both runtimes.
- `.claude/rules/runtime-capabilities.md` line 43 — re-audit pending note explicitly flags this kind of port; this spec executes a partial slice of that re-audit.
- `.claude/rules/mcp-recipes.md` — current design choice "only Claude receives the SessionStart stack hint"; spec 100 proposes revising it (see Open Question 2).
- `.claude/rules/reminders.md` / `.claude/rules/routines.md` — capacity docs; both already framed as project-shared with no Claude-specific semantics in the readouts.
- `.claude/hooks/reminders-readout.sh` / `routines-readout.sh` / `mcp-recipes-hint.sh` — source files to move.
- `.codex/config.toml.example` — destination for new commented-out `[[hooks.SessionStart]]` blocks (one per readout).
- `.agent0/HANDOFF.md` § Decisions & Gotchas — "Re-audit pending in `runtime-capabilities.md`" entry; this spec begins consuming that backlog.
