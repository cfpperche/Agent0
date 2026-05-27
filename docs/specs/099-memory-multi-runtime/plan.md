# 099 — memory-multi-runtime — plan

_Drafted from `spec.md` on 2026-05-27. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Implement the namespace move and Codex hook port in **five sequential phases**, each independently shippable and verifiable before the next starts. The sequencing is chosen to keep memory functional at every commit boundary — no flag-day cutover, no half-migrated state. Phase A creates the new shared primitive (`memory-maintain.sh`) at the new tools location additively. Phase B builds the cross-runtime detection logic inside the 4 hook scripts and moves them from `.claude/hooks/memory-*.sh` to `.agent0/hooks/memory-*.sh` — with **compat shims left at the old paths** for the duration of the consumer-migration window. Phase C executes the `.claude/memory/` → `.agent0/memory/` content move via `git mv` and updates every internal reference. Phase D adds the new defensive layers (`.githooks/pre-commit` projection check, AGENTS.md budget test) and the user-facing documentation surface (AGENTS.md `## Memory` block within 12 lines, `memory-placement.md § Multi-runtime usage`, `.codex/config.toml.example` `[hooks]` block, `CLAUDE.md` path update). Phase E authors the consumer migration playbook against `mei-saas` and `codexeng` shapes and executes the manual migrations after Agent0 upstream lands the prior phases.

The **transitional-state shape** (synthesis-deferred plan-phase decision) is **Option A: compat shims**. Agent0 ships both `.claude/hooks/memory-*.sh` (as ~3-line `exec` shims to the canonical scripts) and `.agent0/hooks/memory-*.sh` (canonical implementations with cross-runtime detection). Sync-harness propagates both. Existing consumers (`mei-saas`, `codexeng`) keep working unchanged after their next sync because their `.claude/settings.json` still references `.claude/hooks/memory-*.sh` which now delegate to the canonical scripts. Manual migration in each consumer is a discrete `git mv` + `settings.json` path update + shim-file removal. After both known consumers migrate, a follow-up commit removes the shims from Agent0 upstream (separate spec or a `chore(099-followup)` commit). This trades a small amount of duplicated path surface for zero breakage of existing consumers — the right side of the trade given the user's explicit "manual migration" constraint.

## Files to touch

**Create:**

- `.agent0/hooks/memory-events-journal.sh` — canonical cross-runtime journal+project hook; consumes `tool_input.file_path` (Claude `Edit|Write|MultiEdit`) OR parses `tool_input.command` patch headers (Codex `apply_patch`); appends JSONL with `actor` derived from `tool_name`
- `.agent0/hooks/memory-index-gate.sh` — canonical cross-runtime PreToolUse gate; same path-extraction branching; same override grammar (`# OVERRIDE: memory-index-edit: <reason ≥10 chars>`)
- `.agent0/hooks/memory-frontmatter-validate.sh` — canonical thin caller of `.agent0/tools/memory-maintain.sh validate`; same path-extraction branching
- `.agent0/hooks/memory-decay-readout.sh` — canonical SessionStart hook; invokes shared `memory-query.sh decay --readout`; identical output framing
- `.agent0/tools/memory-maintain.sh` — new runtime-agnostic shell-invocable primitive; subcommands `validate <entry>` (frontmatter schema check, shared by both hook ports + fallback) and `finalize <entry-path>` (validate + project; idempotent; opt-out fallback for hook-disabled sessions)
- `.agent0/memory/.gitkeep` — empty sentinel so the new bucket exists in fresh clones
- `.codex/config.toml.example` `[hooks]` block (extension to existing file, not new file) — commented `PreToolUse(apply_patch)`, `PostToolUse(apply_patch)`, `SessionStart` registrations pointing at `.agent0/hooks/memory-*.sh`
- `.claude/tests/agents-memory-block-budget.sh` — verification script: greps the `## Memory` section of `AGENTS.md`, counts non-blank lines, exits 1 if > 12 with corrective message pointing at `memory-placement.md § Multi-runtime usage`
- `docs/specs/099-memory-multi-runtime/migration-playbook.md` — ordered manual-migration steps for downstream consumers (pull synced files; `git mv .claude/memory → .agent0/memory`; update `.claude/settings.json` hook paths; remove `.claude/hooks/memory-*.sh` shims + `.claude/tools/memory-*`; verify with `memory-project.sh` + `harness-sync/*` tests); written against `mei-saas` + `codexeng` shapes specifically

**Modify:**

- `.claude/hooks/memory-events-journal.sh` → replace contents with `exec bash "$(dirname "$0")/../../.agent0/hooks/memory-events-journal.sh" "$@"` (compat shim)
- `.claude/hooks/memory-index-gate.sh` → shim, same pattern
- `.claude/hooks/memory-frontmatter-validate.sh` → shim, same pattern
- `.claude/hooks/memory-decay-readout.sh` → shim, same pattern
- `.claude/settings.json` → 4 hook registrations updated from `.claude/hooks/memory-*.sh` → `.agent0/hooks/memory-*.sh` (line 29, 117, 164, 173 per current state)
- `.claude/tools/memory-project.sh` → move to `.agent0/tools/memory-project.sh` via `git mv`; update any internal references
- `.claude/tools/memory-query.sh` → move to `.agent0/tools/memory-query.sh` via `git mv`
- `.claude/tools/memory-query-helper.py` → move to `.agent0/tools/memory-query-helper.py` via `git mv`
- `.claude/tools/memory-backfill.sh` → move to `.agent0/tools/memory-backfill.sh` via `git mv`
- `.claude/tools/memory-backfill-metadata.sh` → move to `.agent0/tools/memory-backfill-metadata.sh` via `git mv`
- `.claude/memory/*` (22 entries + MEMORY.md) → move to `.agent0/memory/*` via `git mv -k` (or per-file `git mv` to preserve history)
- `.claude/memory.config.json` → leave at current path (not in move scope per spec's narrow-migration discipline), OR move to `.agent0/memory.config.json` for consistency — **plan decision: move**, since the file IS memory-specific; one more reference to update
- `.claude/.memory-events.jsonl` (gitignored) → path moves to `.agent0/.memory-events.jsonl`; update gitignore entry; update writer logic in `memory-events-journal.sh`
- `.githooks/pre-commit` → append non-mutating projection-drift check: detect if any staged file is under `.agent0/memory/*.md`, compute projection into temp, diff vs staged `MEMORY.md`, block (exit 1) with corrective template if drift; skip silently if no memory files staged (fast-path)
- `AGENTS.md` → replace `## Memory` block (≤12 non-blank lines): trigger list, `.agent0/memory/MEMORY.md` trigger-driven read direction, hook activation pointer (`.codex/config.toml.example`), `memory-maintain.sh finalize` fallback command, `memory-query.sh decay --readout` invocation for hook-disabled, "do not raw-edit `MEMORY.md`" rule, pointer to `memory-placement.md § Multi-runtime usage`
- `CLAUDE.md` → `## Memory` block updated to point at `.agent0/memory/`
- `.claude/rules/memory-placement.md` → add `## Multi-runtime usage` section (operational trigger list verbatim, hook activation flow for both runtimes, Bash-write non-coverage gap, `PostToolUseFailure` Claude-only divergence, double-fire framing, `.githooks/pre-commit` activation requirement, AGENTS.md 12-line budget convention)
- `.claude/rules/runtime-capabilities.md` → `memory` row Codex column: `convention` → `native-opt-in`; Notes column updated per spec acceptance scenario (`apply_patch` is v1 surface, `Bash` out of strict parity, finalizer fallback)
- `.claude/tools/sync-harness.sh` → ensure manifest globs cover `.agent0/hooks/*.sh`, `.agent0/tools/memory-*`, `.agent0/memory/.gitkeep` (verify against current `harness-sync-baseline.json` shape; extend if needed)
- `.claude/harness-sync-baseline.json` → regenerate after move so consumer sync sees the new manifest as authoritative
- `.gitignore` → update `.claude/.memory-events.jsonl` entry to `.agent0/.memory-events.jsonl`

**Delete:** _(none in this spec — the shim approach preserves all old paths during the consumer-migration window; deletion is a follow-up spec or commit after consumers migrate)_

## Alternatives considered

### Option B — hard cutover (no compat shims)

`git mv` everything cleanly; remove `.claude/hooks/memory-*.sh` entirely; update Agent0's `settings.json` to new paths; sync-harness propagates the deletion to consumers.

**Rejected because** the 3-way baseline reconciliation in `sync-harness.sh` would detect the file-removed-from-upstream condition and delete the consumer's `.claude/hooks/memory-*.sh` files. But the consumer's `.claude/settings.json` (refused as customized) still references those paths → broken hooks until the operator manually migrates. The user explicitly required manual consumer migration; "broken until you migrate" is hostile UX. The shim approach makes the consumer's pre-migration state functionally identical to the pre-spec state.

### Option C — sync-manifest exemption for memory hooks during transition

Curate the sync-harness manifest to exclude `.claude/hooks/memory-*.sh` and `.claude/tools/memory-*` during the migration window, so sync propagates new paths additively but never deletes the old ones.

**Rejected because** it requires per-file manifest curation logic that doesn't currently exist in `sync-harness.sh`; building it just for the migration window is more code than the shim approach, and the new logic would itself need to be removed after migration completes. Shims are mechanical (4 × 3-line files) and need no harness changes.

### Option E — rewrite memory hooks from scratch with a single dispatching entry-point

Instead of porting the 4 existing hooks one-by-one, write one new `memory-hook-dispatcher.sh` that all 4 events route to; it then internally dispatches to validate/project/journal/decay logic based on `hook_event_name`.

**Rejected because** the existing 4-script-per-event shape is already mechanically working in Claude Code, well-tested, and matches the natural `PostToolUse` / `PreToolUse` / `SessionStart` distinction. Collapsing to one dispatcher adds a layer of indirection that obscures which event triggers which behavior — the kind of cleverness that increases incident-debugging cost without reducing maintenance cost. The 4-script status quo + per-script runtime detection is the minimal change.

## Risks and unknowns

- **Codex `apply_patch` `tool_input` shape may carry the patch differently than the docs suggest.** The Codex docs indicate `tool_input.command` carries the patch body, but it could also be `tool_input.input` or a structured `tool_input.patch` field. Mitigation: dump-probe in implementation Phase A (write a no-op Codex `PostToolUse(apply_patch)` hook that logs the full `tool_input` shape to a temp file; verify against docs; only THEN write the real parser). Same lesson as `cc-platform-hooks.md` § Meta-lesson (PostToolUseFailure shape divergence in spec 020).
- **`apply_patch` patch-header parsing edge cases.** Multi-file patches, `*** Move to:` renames, paths with spaces, paths with special characters all need handling. Mitigation: write the parser against sample patches from real Codex sessions, not against docs alone; tests cover each header type.
- **`actor` field detection for `Bash` writes.** A Codex session running a Bash command that writes to a memory file (e.g. `echo '---' >> .agent0/memory/foo.md`) won't trigger the `apply_patch` hook. It also won't be reliably attributable to "Codex CLI" if the hook never fires. Mitigation: spec explicitly puts arbitrary Bash writes out of strict parity scope (see Non-goals); `.githooks/pre-commit` catches at commit time; no attribution loss in v1 because the journal entry simply doesn't exist for Bash writes.
- **`.githooks/pre-commit` projection check performance.** Adding a step to every commit risks user-perceived latency. Mitigation: short-circuit immediately if no `.agent0/memory/*.md` files are in the staged diff (likely the common case); when staged memory files exist, projection runs in <100ms on the current 22-entry bucket (verified via `time bash .claude/tools/memory-project.sh`).
- **AGENTS.md 12-line budget is tight.** Trigger list + hook activation pointer + finalizer fallback + decay readout + raw-edit rule + cross-reference may not fit. Mitigation: prioritize the action items (trigger + activation + fallback) inline; detailed protocol moves to `memory-placement.md § Multi-runtime usage`; budget script fails loudly if author exceeds the cap, forcing prose discipline rather than silent creep.
- **Sync-harness manifest extension.** `sync-harness.sh` currently ships `.claude/*` paths; whether it auto-includes `.agent0/*.sh` and `.agent0/tools/*` without code changes is unverified. Mitigation: inspect manifest globs in Phase A; extend if needed; verify via dogfood sync to `mei-saas` after Phase D.
- **Consumer customization conflicts.** If `mei-saas` or `codexeng` customized `.claude/settings.json` or any `memory-*` hook before this spec lands, the sync may refuse those files and the migration playbook needs a "resolve customization first" branch. Mitigation: pre-flight grep both consumers' git logs for memory-hook customizations; if any found, document the resolution in the playbook before executing migration.
- **`memory.config.json` location decision.** The plan moves it to `.agent0/memory.config.json` for consistency; if any tool hardcodes the old path, migration breaks it. Mitigation: grep for `memory.config.json` across `.claude/tools/memory-*` + `.claude/hooks/memory-*` before moving; update all references in the same commit as the move.
- **`PostToolUseFailure` divergence as future-spec scope creep.** Memory hooks don't need this event today, but a future Agent0 hook that DOES need it on Codex won't have it. Spec 099 documents the gap; risk is that future authors don't read the gap doc and re-discover it. Mitigation: surface in `runtime-capabilities-maintenance.md` as a known asymmetry; cross-reference from `codex-cli-hooks.md`.
- **Unknown: whether new consumers (post-spec-099) need any of the compat shims.** New forks of Agent0 after the spec lands get the new paths in `.agent0/`. They never had `.claude/hooks/memory-*.sh`. The shims are dead-code from day one for them. Cost: ~20 lines of shim across 4 files. Acceptable; cheaper than building shim-elision logic into sync-harness.

## Research / citations

- <https://developers.openai.com/codex/hooks> — canonical Codex CLI lifecycle hooks docs; 10-event surface, stdin payload schema, exit-code semantics, config-file discovery precedence. Verified 2026-05-27 via WebFetch.
- <https://developers.openai.com/codex/config-reference> — TOML schema for `[hooks]` block in `.codex/config.toml`; alternative `.codex/hooks.json` shape (same schema). Foundation for Phase D `.codex/config.toml.example` extension.
- `.claude/memory/codex-cli-hooks.md` — distilled compatibility profile: payload-shape table (nearly identical to Claude), tool-name asymmetry (apply_patch / Bash vs Edit / Write / MultiEdit), matcher syntax (regex, same), exit-code semantics (0/2, same), 5-layer config discovery, escape hatches (`[features] hooks = false`). Saved in commit `bb23dcf`.
- `docs/specs/099-memory-multi-runtime/debate.md § Synthesis (revised after Round 4)` — converged decisions on namespace lock, hook port direction, scope narrowing, `apply_patch` as v1 surface, finalizer demotion to fallback.
- `docs/specs/098-codex-mcp-recipes-parity/` — precedent for `.codex/config.toml.example` opt-in template pattern; sync-harness propagation tested empirically in spec 098 dogfood (mei-saas + codexeng both received byte-identical 17-file delta).
- `docs/specs/082-memory-frontmatter-schema/`, `083-memory-events-journal/`, `086-memory-cap-query-decay/` — existing memory hook implementations being ported; baseline behavior preserved.
- `.claude/rules/secrets-scan.md` § Native hook — `.githooks/pre-commit` activation pattern (`git config core.hooksPath .githooks`), precedent for adding a second non-mutating check to the existing gitleaks hook.
- `.claude/rules/harness-sync.md` — 3-way baseline reconciliation behavior; informs the compat-shim decision (consumer-customized files refuse without `--force`; sync deletes files removed upstream unless preserved in manifest).
- `.claude/rules/memory-placement.md` — frontmatter schema, event journal, cap/query/decay; baseline rule body that gains the new `## Multi-runtime usage` section in Phase D.
- `.claude/rules/runtime-capabilities.md` (updated 2026-05-27 per commit `bb23dcf`) — matrix row `lifecycle hooks` already promoted Codex `unsupported` → `native`; `memory` row promotion from `convention` → `native-opt-in` happens in Phase D.
- `developers.openai.com/codex/changelog` (May 2026) — confirms richer hook context shipped (conversation history for extension tools, subagent identity in hook inputs); informs the JSONL `actor` attribution direction.
