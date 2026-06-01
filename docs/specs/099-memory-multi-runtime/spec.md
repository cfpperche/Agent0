# 099 — memory-multi-runtime

_Created 2026-05-27._

**Status:** shipped

## Intent

Port Agent0's project-memory bucket from a Claude Code-centered capacity into a structurally symmetric multi-runtime capacity that both Claude Code and Codex CLI consume via their native lifecycle-hook primitives. The canonical corpus moves from `.claude/memory/` to `.agent0/memory/`; the four memory-specific shared hook implementations move from `.claude/hooks/memory-*.sh` to `.agent0/hooks/memory-*.sh`; memory-specific tooling moves from `.claude/tools/memory-*` to `.agent0/tools/memory-*`. v1 ports the four Claude-side memory hooks to Codex CLI via repo-local hook configuration (extending the existing `.codex/config.toml.example` opt-in template from spec 098) so both runtimes intercept memory edits and `SessionStart` through their native lifecycle primitives. A `memory-maintain.sh finalize` command remains as an opt-out fallback for users running with `[features] hooks = false`, untrusted project hooks, or pre-hook-surface Codex versions. A non-mutating `.githooks/pre-commit` projection check stays as the universal drift backstop. The goal is mechanically identical memory behavior across runtimes for the `apply_patch` / `Edit|Write|MultiEdit` edit surfaces, not full lifecycle-hook parity for every Agent0 capacity.

## Acceptance criteria

- [ ] **Scenario: Codex discovers project memory through its own entrypoint**
  - **Given** a Codex CLI session starts in Agent0 and reads root `AGENTS.md`
  - **When** work touches `.claude/rules/`, `.claude/hooks/`, `.claude/skills/`, `.claude/tools/sync-harness.sh`, `.claude/rules/runtime-capabilities.md`, `.agent0/memory/` tooling, project architecture, or any spec involving a first-party capacity
  - **Then** `AGENTS.md § Memory` directs Codex to read `.agent0/memory/MEMORY.md` itself on each trigger (trigger-driven read, no in-context primer), follow only entries relevant to the task, and treat `.claude/rules/memory-placement.md` as the bucket contract

- [ ] **Scenario: both runtimes read the same project-memory source**
  - **Given** a memory entry exists under `.agent0/memory/<topic>.md` and appears in `.agent0/memory/MEMORY.md`
  - **When** Claude Code follows the `CLAUDE.md` memory block and Codex follows the `AGENTS.md` memory block
  - **Then** both runtimes are pointed at the same entry files and the same derived index; no Codex-only mirror, Claude-only source, or generated duplicate memory tree is introduced

- [ ] **Scenario: Codex `PreToolUse(apply_patch)` raw-index gate**
  - **Given** Codex CLI with hooks activated via `.codex/config.toml`
  - **When** Codex attempts an `apply_patch` whose parsed `*** Update File:` / `*** Add File:` / `*** Delete File:` / `*** Move to:` target is `.agent0/memory/MEMORY.md`
  - **Then** the Codex `PreToolUse` hook blocks with exit-2 + the same corrective template + the same `# OVERRIDE: memory-index-edit: <reason ≥10 chars>` grammar Claude Code's `memory-index-gate.sh` uses

- [ ] **Scenario: Codex `PostToolUse(apply_patch)` frontmatter validate + project + journal**
  - **Given** Codex CLI with hooks activated
  - **When** Codex successfully `apply_patch` edits an entry under `.agent0/memory/<topic>.md`
  - **Then** the Codex `PostToolUse` hook (a) validates frontmatter via the shared `memory-maintain.sh validate` primitive, emitting `memory-frontmatter-advisory:` on violations with identical text to Claude's hook; (b) regenerates `.agent0/memory/MEMORY.md` via `memory-project.sh`; (c) appends a JSONL event to `.agent0/.memory-events.jsonl` with `actor: "Codex CLI"`, the Codex `session_id`, `tool_use_id`, and the resolved entry path parsed from the patch header

- [ ] **Scenario: Codex SessionStart decay readout**
  - **Given** a fresh Codex CLI session in Agent0 with hooks activated
  - **When** the session starts and `.agent0/memory/` contains stale entries
  - **Then** Codex emits the same `=== MEMORY DECAY ===` framed block Claude Code emits, including the `(no stale entries)` empty case — sourced by invoking the shared `memory-query.sh decay --readout` command from a Codex `SessionStart` hook

- [ ] **Scenario: shared `apply_patch` path discovery**
  - **Given** any Codex `PreToolUse` / `PostToolUse` hook script processing the stdin `tool_input` payload
  - **When** the payload's `tool_name` is `apply_patch` and `tool_input.command` carries a patch body
  - **Then** the script extracts affected paths by parsing patch headers (`*** Add File:`, `*** Update File:`, `*** Delete File:`, `*** Move to:`) and filters for `.agent0/memory/*.md` — no `git status` fallback, no Bash-write attribution required

- [ ] **Scenario: shared hook scripts live under `.agent0/hooks/`**
  - **Given** the four memory-specific hook scripts that both runtimes invoke (`memory-events-journal.sh`, `memory-index-gate.sh`, `memory-frontmatter-validate.sh`, `memory-decay-readout.sh`)
  - **When** a contributor inspects the repo
  - **Then** the scripts live under `.agent0/hooks/memory-*.sh` (runtime-neutral location matching the namespace move); `.claude/settings.json` references them at `.agent0/hooks/memory-*.sh`; `.codex/config.toml.example` (extended `[hooks]` block) references them at `.agent0/hooks/memory-*.sh`. Other Claude hooks (delegation, secrets-scan, supply-chain, propagation, runtime-introspect, etc.) remain under `.claude/hooks/` — the move scope is narrow

- [ ] **Scenario: `.codex/config.toml.example` extension**
  - **Given** the existing Codex opt-in template shipped by spec 098
  - **When** a Codex user copies the template to `.codex/config.toml` and starts a session
  - **Then** a commented `[hooks]` block is present alongside the MCP recipes, with `PreToolUse` / `PostToolUse` / `SessionStart` registrations pointing at the `.agent0/hooks/memory-*.sh` scripts; the user uncomments to activate (same posture as MCP recipes)

- [ ] **Scenario: finalizer fallback for hook-disabled sessions**
  - **Given** a Codex session running with `[features] hooks = false`, with project hooks untrusted, or on a pre-hook-surface Codex version
  - **When** the user edits a memory entry
  - **Then** the documented fallback in `AGENTS.md § Memory` instructs the user to run `bash .agent0/tools/memory-maintain.sh finalize <entry-path>` before session end (or rely on the `.githooks/pre-commit` backstop at commit time); the finalizer is the documented degraded-mode path, not the primary mechanism

- [ ] **Scenario: shared frontmatter validation primitive**
  - **Given** a runtime-agnostic shell-invocable frontmatter validation primitive at `.agent0/tools/memory-maintain.sh validate <entry>`
  - **When** the Claude Code hook `.agent0/hooks/memory-frontmatter-validate.sh` fires on `PostToolUse(Edit|Write|MultiEdit)`, OR the Codex hook fires on `PostToolUse(apply_patch)`, OR a user invokes the finalizer fallback
  - **Then** all three callers invoke the same shared primitive and emit identical `memory-frontmatter-advisory:` output for the same malformed entry

- [ ] **Scenario: capability matrix reflects the new direction**
  - **Given** `.claude/rules/runtime-capabilities.md` is read after implementation
  - **When** the reader checks the `memory` row
  - **Then** Claude Code stays `native`; Codex CLI promotes from `convention` to `native-opt-in`; the Notes column states "Codex hooks port the four memory implementations via `.codex/config.toml.example`; `apply_patch` is the v1 hook-coverage surface; `Bash` writes are out of strict parity and caught by `.githooks/pre-commit` backstop; finalizer fallback for hook-disabled sessions"

- [ ] **Scenario: non-mutating pre-commit drift backstop**
  - **Given** `.githooks/pre-commit` is active (`git config core.hooksPath .githooks`) and a contributor stages memory-entry edits without re-running projection
  - **When** they invoke `git commit`
  - **Then** the hook computes the projected `MEMORY.md` into a temp file, diffs vs the staged index, and on drift blocks the commit with a corrective message instructing the user to run `bash .agent0/tools/memory-maintain.sh finalize` and re-stage; the hook never rewrites or auto-stages files; when `.githooks` is not activated, drift surfaces at the next Claude Code or Codex `SessionStart` hook firing (documented skew window)

- [ ] **Scenario: AGENTS.md Memory block budget enforced**
  - **Given** a contributor edits `AGENTS.md`
  - **When** the `## Memory` block exceeds 12 non-blank lines
  - **Then** the verification script `.claude/tests/agents-memory-block-budget.sh` fails with a corrective message pointing at `.claude/rules/memory-placement.md § Multi-runtime usage` as the canonical detailed protocol location

- [ ] `AGENTS.md § ## Memory` covers, within ≤12 non-blank lines: trigger list, `.agent0/memory/MEMORY.md` trigger-driven read direction, hook activation pointer (`.codex/config.toml.example`), finalizer fallback command, `memory-query.sh decay --readout` invocation for hook-disabled sessions, the "do not raw-edit `MEMORY.md`" rule, and a pointer to `.claude/rules/memory-placement.md § Multi-runtime usage`.

- [ ] `CLAUDE.md` and `AGENTS.md` continue to point at the same project-memory bucket (`.agent0/memory/`) and do not fork the conceptual model.

- [ ] `.claude/rules/memory-placement.md` gains a `## Multi-runtime usage` section documenting (a) the operational trigger list verbatim, (b) hook activation flow for both runtimes, (c) the Bash-write non-coverage gap, (d) the `PostToolUseFailure` Claude-only event divergence, (e) double-fire framing (sequential runtimes emit distinct events keyed by runtime / `session_id` / `tool_use_id`), (f) the `.githooks/pre-commit` activation requirement, (g) the AGENTS.md 12-line budget convention.

- [ ] Runtime-agnostic memory tools remain shell-invocable from the project root with no Claude Code tool-surface dependency: `.agent0/tools/memory-project.sh`, `.agent0/tools/memory-query.sh`, `.agent0/tools/memory-query-helper.py`, the new `.agent0/tools/memory-maintain.sh` (validate + finalize subcommands), and any helper introduced by this spec.

- [ ] Tests or verification scripts cover at the shell level: frontmatter validation advisory parity across runtimes, projection idempotence after an entry edit, decay readout command output, the AGENTS.md 12-line budget, and the `.githooks/pre-commit` projection drift check.

- [ ] **Scenario: consumer-project manual migration playbook exists**
  - **Given** Agent0 upstream has landed the spec 099 implementation (new paths under `.agent0/memory/` + `.agent0/hooks/memory-*.sh` + `.agent0/tools/memory-*`)
  - **When** a downstream consumer operator (`mei-saas`, `codexeng`, or any future fork) needs to migrate their project to the new layout
  - **Then** a playbook at `docs/specs/099-memory-multi-runtime/migration-playbook.md` (or equivalent in-spec location) lists the ordered steps: pull the synced new files; `git mv` the consumer's `.claude/memory/` content to `.agent0/memory/`; update consumer's `.claude/settings.json` hook registrations to point at `.agent0/hooks/memory-*.sh`; remove the old `.claude/hooks/memory-*.sh` and `.claude/tools/memory-*` files (or wait for the upstream shim-removal window); verify with `bash .agent0/tools/memory-project.sh` and the existing `.claude/tests/harness-sync/*` suite

## Non-goals

- **No Codex lifecycle hook parity beyond the four memory hooks.** Other Claude capacities (delegation gate, runtime introspect, secrets scan, propagation advisory, supply-chain scan, post-edit validator, etc.) remain Claude-only by mechanism in v1. A broader audit follow-up may promote them per `.claude/rules/runtime-capabilities.md` § Re-audit pending.
- **No guaranteed hook coverage for arbitrary Bash writes.** Codex hook parity is guaranteed for the `apply_patch` edit surface only. `Bash` writes that touch memory paths fall outside strict hook parity in v1 because path attribution from arbitrary shell commands is unreliable — those edits are caught by the `.githooks/pre-commit` projection check as the universal backstop, not by the `PostToolUse` hook. If a future spec demonstrates safe Bash path discovery without false positives, the matrix can extend.
- **No second memory store.** Do not create a Codex-only memory directory, duplicate index, generated mirror, database, daemon, or broker process.
- **No automatic memory-content propagation to consumer projects.** Project-memory content remains project-local; sync-harness ships only the new scaffolding additively (`.agent0/memory/.gitkeep`, the new `.agent0/hooks/memory-*.sh` shared implementations, the `.agent0/tools/memory-*` tooling).
- **No automatic consumer-project migration from `.claude/memory/` → `.agent0/memory/`.** Agent0 upstream cuts over to the new layout; downstream consumer projects (`mei-saas`, `codexeng`, and any future fork) execute their own manual migration AFTER the upstream spec lands. Sync-harness does NOT (a) auto-edit consumer `.claude/settings.json` to repoint hook registrations at the new paths, (b) move consumer `.claude/memory/` content to `.agent0/memory/`, or (c) remove consumer `.claude/hooks/memory-*.sh` / `.claude/tools/memory-*` paths during sync. Each consumer operator runs the documented migration playbook by hand. Transitional-state shape (compat shims left in upstream during the window vs hard cutover) is a plan-phase decision.
- **No per-user Claude Code memory port.** Bucket 1 (`~/.claude/projects/<path>/memory/`) remains Claude Code-specific user preference storage and is not made Codex-readable.
- **No read-tracking bump on ordinary file reads.** Reading or grepping a memory entry does not mutate `last_accessed`; `memory-query.sh confirm` remains the explicit validation signal unless a later spec changes that.
- **No auto-archive, auto-delete, or staleness mutation.** Decay remains observation only.
- **No hard prevention of raw Codex edits to `MEMORY.md`.** The Codex `PreToolUse(apply_patch)` hook covers patch-based raw edits; arbitrary `Bash` writes (e.g. `echo > MEMORY.md`) remain bypassable. The `.githooks/pre-commit` projection check is the v1 backstop when `.githooks/pre-commit` is activated; when it is not, drift surfaces at the next Claude Code or Codex `SessionStart` hook firing.
- **No broad `.claude/` namespace migration outside the memory bucket and its shared hooks / tools.** Other Claude-specific paths (`.claude/rules/`, `.claude/skills/`, non-memory `.claude/tools/*`, non-memory `.claude/hooks/*`, `.claude/settings.json`) stay under `.claude/`. The move scope is restricted to (a) `.claude/memory/` → `.agent0/memory/`, (b) the four memory-specific shared hooks `.claude/hooks/memory-*.sh` → `.agent0/hooks/memory-*.sh`, (c) memory-specific tooling `.claude/tools/memory-*` → `.agent0/tools/memory-*`.

## Open questions

All resolved during cross-model debate; see `debate.md § Synthesis (revised after Round 4)` for the canonical resolution table. Brief summary for spec readers who do not also read `debate.md`:

- **OQ-1 (namespace):** CLOSED — `.agent0/memory/` (user-ratified Scenario B). Plan-phase enumeration task remains as work, not decision.
- **OQ-2 (Codex journaling):** CLOSED — YES via Codex `PostToolUse` hook with runtime attribution.
- **OQ-3 (Codex command surface):** CLOSED — hook-primary + `memory-maintain.sh finalize` fallback.
- **OQ-4 (capability matrix `memory` cell):** CLOSED — `native-opt-in` (hook primitive native; activation opt-in via `.codex/config.toml.example`).
- **OQ-5 (decay readout cadence):** CLOSED — `SessionStart` hook on Codex (parity with Claude's always-fire posture).
- **OQ-6 (hook-script home):** CLOSED — `.agent0/hooks/` for the four memory-specific shared scripts; runtime-specific config invokes them.
- **OQ-7 (path discovery in Codex `apply_patch` hook):** CLOSED — parse patch headers in-script; no `git status` fallback; Bash out of scope.
- **OQ-8 (Codex hook config layout):** CLOSED — extend `.codex/config.toml.example` (spec 098 precedent); no new `.codex/hooks.json.example`.
- **OQ-9 (double-fire risk):** CLOSED — documentation only in `memory-placement.md § Multi-runtime usage`.
- **OQ-10 (`PostToolUseFailure` divergence):** CLOSED — known gap, not blocker; documented in `runtime-capabilities-maintenance.md`.

## Context / references

- `.claude/rules/runtime-capabilities.md` — current matrix: `memory` is `native` for Claude Code and `native-opt-in` for Codex CLI after this spec; `lifecycle hooks` is `native` for both as of 2026-05-27.
- `.claude/rules/memory-placement.md` — canonical three-bucket model, frontmatter schema, event journal, index projection, cap/query/decay; gains `## Multi-runtime usage` section per this spec.
- `.claude/rules/session-handoff.md` and `docs/specs/092-multi-runtime-handoff/` — precedent for one runtime-neutral artifact under `.agent0/` with Claude hooks and Codex convention as asymmetric mechanisms; precedent for the namespace move.
- `docs/specs/019-project-memory/` — introduced the project-memory bucket and lazy-read index.
- `docs/specs/082-memory-frontmatter-schema/` — frontmatter schema and Claude Code advisory validator (becomes thin caller of shared primitive per this spec).
- `docs/specs/083-memory-events-journal/` — event journal, raw-index gate, and derived-index projection.
- `docs/specs/086-memory-cap-query-decay/` — `memory-query.sh`, confirm semantics, decay readout, and the known `confirm` journaling gap (preserved as documented baseline).
- `docs/specs/098-codex-mcp-recipes-parity/` — established the `.codex/config.toml.example` opt-in template pattern this spec extends with the `[hooks]` block.
- `.claude/tools/memory-project.sh` — deterministic index projection and cap advisory; moves to `.agent0/tools/memory-project.sh`.
- `.claude/tools/memory-query.sh` / `.claude/tools/memory-query-helper.py` — runtime-agnostic query, confirm, and decay command surface; move to `.agent0/tools/`.
- `.claude/hooks/memory-events-journal.sh`, `.claude/hooks/memory-index-gate.sh`, `.claude/hooks/memory-frontmatter-validate.sh`, `.claude/hooks/memory-decay-readout.sh` — Claude Code-native memory hooks moving to `.agent0/hooks/memory-*.sh` and gaining runtime-detection branching per this spec.
- `.agent0/memory/codex-cli-hooks.md` — canonical Codex hook surface (events, payload shape, tool-name asymmetry, config layout); foundation for the port direction.
- <https://developers.openai.com/codex/hooks> — official Codex CLI hooks docs (verified 2026-05-27).
- `.codex/config.toml.example` — opt-in template shipped by spec 098; extended in this spec with a `[hooks]` block.
- `.agent0/hooks/` — new directory housing the four memory-specific shared hook implementations (scripts ship as content; `.gitkeep` ensures presence on fresh clones).
- `.agent0/tools/memory-maintain.sh` — new runtime-agnostic finalizer + shared validate primitive; called by both hook ports and by the fallback command.
- `.githooks/pre-commit` and `.claude/rules/secrets-scan.md` — precedent for adding a non-mutating check to the existing gitleaks hook with `git config core.hooksPath .githooks` activation pattern.
- `.agent0/HANDOFF.md` § *Size discipline* — precedent for budget-discipline-with-mechanical-check (cautionary tale: cap documented but unenforced and routinely violated, motivating the AGENTS.md mechanical check).
- `AGENTS.md` — Codex entrypoint to expand within the 12-line cap with the trigger list + hook activation pointer + finalizer fallback.
- `CLAUDE.md` — Claude Code entrypoint; `## Memory` block updated to point at `.agent0/memory/`.
- `mei-saas` (`github.com:cfpperche/mei-saas.git`) and `codexeng` (`github.com:cfpperche/codexeng.git`) — first known downstream consumers (precedent: spec 098 dogfood landed in both). Each receives the manual migration after Agent0 upstream lands spec 099; the migration playbook (new acceptance criterion above) is authored against these two projects' specific shapes.
