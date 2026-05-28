# 105 — shared-tools-to-agent0

_Created 2026-05-28._

**Status:** shipped

## Intent

Phase 3 (final `move`) of umbrella spec 102 (`harness-consolidate-agent0`), gap-matrix row 6. Relocate the shared, runtime-neutral shell tools from `.claude/tools/` to `.agent0/tools/`, closing the residual ownership split the umbrella defines: `.agent0/` holds everything the harness defines as runtime-neutral; `.claude/` keeps only what is exclusive to Claude Code.

`.agent0/tools/` already exists — the memory tools (`memory-*.sh`, `memory-query-helper.py`) moved there in the spec 103 lineage. This spec moves the remaining eight scripts plus the `lib/` subdir:

- `sync-harness.sh` — the harness propagation tool (largest blast radius; ~200 refs). Self-referential: its `_self_rebootstrap` pre-flight hardcodes its own path, its `MANAGED_BLOCK_LIB` fallback points at `lib/managed-block.sh`, and its own propagation manifest (`COPY_CHECK_GLOBS`) lists `.claude/tools/*.sh`.
- `probe.sh` — the runtime-introspect reader. 104 deliberately left every `bash .claude/tools/probe.sh` invocation untouched; **this spec owns all of them.**
- `check-instruction-drift.sh`, `bench-hooks.sh` — harness maintenance tools.
- `run-routine.sh`, `install-routines.sh`, `uninstall-routines.sh` — routines machinery.
- `codex-local-env.sh` — a **Codex-facing** tool currently sitting under `.claude/`, the most clear-cut misplacement this row resolves.
- `lib/managed-block.sh` — shared library sourced by `sync-harness.sh`.

This is a pure relocation + reference rewrite. No capacity changes behavior; the contract of each tool is unchanged.

**Migration is capacity-only** per umbrella 102 § Acceptance and `.claude/rules/harness-sync.md` § Path relocations. Unlike Phases 1-2 (which moved *data* the manifest never carries), tools are **shipped content** — so the move propagates to consumers cleanly through the existing manifest + deletion pass: on the next `--apply`, the old `.claude/tools/*.sh` (recorded in the consumer's baseline, absent from the new manifest) are removed as orphans, and the new `.agent0/tools/*.sh` are copied. No manual consumer migration of script content is required (the one transitional cost is the self-rebootstrap crash documented in § Open questions).

## Acceptance criteria

- [x] **Scenario: each relocated tool runs from its new path**
  - **Given** the relocation is applied
  - **When** `bash .agent0/tools/probe.sh last-run` and `bash .agent0/tools/sync-harness.sh --agent0-path=. --check .` run from repo root
  - **Then** each executes correctly from `.agent0/tools/` (probe reads `.agent0/.runtime-state/`; sync-harness loads its `lib/managed-block.sh` and reports drift), with no "file not found" on any tool path

- [x] **Scenario: sync-harness self-rebootstrap targets the new path**
  - **Given** a consumer `--apply` where the consumer's `sync-harness.sh` will be overwritten
  - **When** `_self_rebootstrap` computes the in-place-overwrite guard
  - **Then** it inspects `.agent0/tools/sync-harness.sh` (not `.claude/tools/sync-harness.sh`) as the running-file path

- [x] **Scenario: manifest propagates the new tool location and removes the old**
  - **Given** a consumer project whose baseline records the old `.claude/tools/*.sh` set, running `sync-harness.sh --apply`
  - **When** the manifest is walked and the deletion pass runs
  - **Then** `.agent0/tools/*.sh` + `.agent0/tools/lib/managed-block.sh` are copied, the consumer's stale `.claude/tools/*.sh` are removed as orphans (or refused if customized), and no consumer product code is touched

- [x] **Scenario: MANAGED_BLOCK_LIB resolves from the new path**
  - **Given** the relocation is applied
  - **When** `sync-harness.sh` resolves `MANAGED_BLOCK_LIB`
  - **Then** the fallback path is `.agent0/tools/lib/managed-block.sh` and the managed-block merge functions load

- [x] All eight `.sh` tools + `lib/managed-block.sh` are `git mv`'d to `.agent0/tools/`; no tracked file remains under `.claude/tools/`, and the now-empty `.claude/tools/` directory is gone
- [x] `sync-harness.sh` `COPY_CHECK_GLOBS` no longer contains `.claude/tools|*.sh` (replaced by `.agent0/tools|*.sh`, retaining `.agent0/tools|memory-*` for `memory-query-helper.py`); `COPY_CHECK_FILES` lib entry is `.agent0/tools/lib/managed-block.sh`; `_self_rebootstrap` `rel` and the `MANAGED_BLOCK_LIB` fallback are repointed
- [x] No **live** `.claude/tools/` reference remains in shipped code, rules, entrypoints (`CLAUDE.md`/`AGENTS.md`), hooks, tests, `.agent0/HANDOFF.md`, or `.agent0/memory/` (verified by grep). **Frozen** historical mentions in `docs/specs/NNN-*/` are intentionally retained — they document what was true at the time
- [x] All affected test suites pass: `harness-sync`, `instruction-drift`, `runtime-introspect`, `runtime-capture-php`, `githooks-activation`, plus any suite asserting a tool path
- [x] `git diff --check` clean; umbrella 102 § Gap matrix row 6 status flipped to `shipped`

## Non-goals

- **Moving the consumer-side baseline file.** `<consumer>/.claude/harness-sync-baseline.json` stays where it is — it is a consumer-side runtime artifact, not a tool, and relocating it would break every existing consumer's reconciliation. Out of scope for this row; a candidate for a later refactor pass.
- **Rewriting frozen historical references.** `docs/specs/NNN-*/` are design memory; their `.claude/tools/` mentions are correct-as-of-their-date and must not be sed'd.
- **Moving the deferred rows** (7-9: rules / skills / validators) or `.claude/tests/` — those stay until their own triggers fire (umbrella 102 § Gap matrix). This spec only rewrites tests' *references* to the moved tools, not the test files' location.
- **Re-homing the runtime-capture producer hooks** (`runtime-capture.sh` / `runtime-pre-mark.sh`) — they stay Claude-only (umbrella row 4 caveat, row 13 `stays`). Only `probe.sh` (the neutral reader) moves.
- **Changing any tool's behavior.** Pure relocation + reference rewrite.

## Open questions

- [x] ~~**Self-rebootstrap transitional crash on the migrating `--apply`.**~~ → **Resolved 2026-05-28: accept as a recorded transitional cost, no mitigation code.** A consumer whose stale `.claude/tools/sync-harness.sh` runs the migrating `--apply` has that file deleted (orphan) while bash is still reading it, and the old script's `_self_rebootstrap` guards `.claude/tools/sync-harness.sh`, not the new path. Same one-time transitional crash already documented in `.claude/rules/harness-sync.md` § Gotchas — the crashed run has already written the new `.agent0/tools/sync-harness.sh`, so re-running `--apply` completes cleanly. A one-line note was added to that gotcha naming the spec-105 relocation instance; no operator-facing advisory is warranted (the existing gotcha + the re-run-completes property are sufficient, matching the no-baseline-first-sync precedent).

## Context / references

- `docs/specs/102-harness-consolidate-agent0/spec.md` § Gap matrix row 6 + § Classification principle — the parent umbrella; this spec is its Phase 3 and the row that closes it.
- `docs/specs/104-state-dirs-to-agent0/` — Phase 2 precedent (same relocation shape); 104 deliberately left every `bash .claude/tools/probe.sh` self-reference for this spec.
- `docs/specs/103-reminders-routines-to-agent0/` — Phase 1 precedent (capacity-only relocation).
- `.claude/rules/harness-sync.md` § Manifest scope / § Self-rebootstrap / § Path relocations — the manifest, the self-overwrite guard, and the consumer-migration posture this spec touches. This rule is itself the heaviest live-reference surface (it documents `.claude/tools/sync-harness.sh` throughout).
- `.claude/rules/runtime-introspect.md` + `CLAUDE.md` § Runtime introspect + `.agent0/HANDOFF.md` — the live `bash .claude/tools/probe.sh last-run` invocation sites.
- `.claude/rules/routines.md` § Files — references `install-routines.sh` / `uninstall-routines.sh` / `run-routine.sh`.
