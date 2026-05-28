# 104 — state-dirs-to-agent0

_Created 2026-05-28._

**Status:** shipped

## Intent

Phase 2 of umbrella spec 102 (`harness-consolidate-agent0`). Relocate the three shared, runtime-neutral state directories from `.claude/` to `.agent0/`, finishing the ownership split that umbrella 102 defines: `.agent0/` holds everything the harness defines as runtime-neutral; `.claude/` keeps only what is exclusive to Claude Code. The three surfaces are gap-matrix rows 3-5:

- **`.claude/.session-state/` → `.agent0/.session-state/`** (row 3, reverses 101 OQ-E) — the per-session 4-file contract (`started-at` / `nagged` / `edited-files.txt` / `start-porcelain.txt`) is written by *both* runtimes' session lifecycle hooks, which already live in `.agent0/hooks/`. By the § Classification principle the state belongs there too.
- **`.claude/.runtime-state/` → `.agent0/.runtime-state/`** (row 4) — the runtime-introspect snapshot (`last-run.json` + `in-flight/`). Its neutral reader (`probe.sh`) moves in Phase 3; moving the state now keeps reader and state co-located under `.agent0/`. Caveat: the *producer* hooks (`runtime-capture.sh` / `runtime-pre-mark.sh`) stay Claude-only — only the state-dir path moves.
- **`.claude/.browser-state/` → `.agent0/.browser-state/`** (row 5) — saved Playwright auth state, read by either runtime headless, written by a human headed session.

This is a pure relocation + reference rewrite. No capacity changes behavior; the contract of each surface is unchanged. Migration is **capacity-only** per umbrella 102 § Acceptance and `.claude/rules/harness-sync.md` § Path relocations — existing forks migrate their own data on next sync (the spec 103 precedent).

## Acceptance criteria

- [x] **Scenario: session hooks read/write the new path**
  - **Given** a session whose hooks resolve `PROJECT_DIR`
  - **When** `session-start.sh` / `session-stop.sh` / `session-track-edits.sh` run
  - **Then** they create/read the 4-file contract under `$PROJECT_DIR/.agent0/.session-state/<session_id>/`, not `.claude/.session-state/`

- [x] **Scenario: runtime-introspect capture writes the new path**
  - **Given** a recognised verifier command runs under the capture hook
  - **When** `runtime-capture.sh` writes its snapshot (and `runtime-pre-mark.sh` its in-flight marker)
  - **Then** the snapshot lands at `$PROJECT_DIR/.agent0/.runtime-state/last-run.json` and `probe.sh last-run` reads it from there

- [x] **Scenario: probe reads both relocated state dirs**
  - **Given** the relocation is applied
  - **When** `probe.sh last-run` runs
  - **Then** it reads `last-run.json` from `.agent0/.runtime-state/` and computes the stale boundary from `.agent0/.session-state/*/started-at`

- [x] **Scenario: sync-harness propagates the new-location capacity (not content)**
  - **Given** a consumer project runs `sync-harness.sh --apply`
  - **When** the manifest is walked
  - **Then** `.agent0/.runtime-state/README.md` and `.agent0/.browser-state/.gitkeep` are copied, the consumer `.gitignore` gains the `.agent0/.*-state/` entries via additive merge, and no consumer `.claude/` data is moved or deleted

- [x] `.gitignore` ignores `.agent0/.session-state/`, `.agent0/.runtime-state/*` (keeping `!.agent0/.runtime-state/README.md`), and `.agent0/.browser-state/*.json`
- [x] `.claude/.runtime-state/README.md` and `.claude/.browser-state/.gitkeep` are `git mv`'d to `.agent0/`; no tracked file remains under the three old `.claude/.*-state/` paths
- [x] No `.claude/.session-state`, `.claude/.runtime-state`, or `.claude/.browser-state` reference remains in shipped code, rules, entrypoints, or memory (verified by grep)
- [x] All affected test suites pass: `session-state-isolation`, `session-edit-attribution`, `session-handoff`, `session-handoff-multi-runtime`, `runtime-introspect`, `runtime-capture-php`, `harness-sync`
- [x] `git diff --check` clean; umbrella 102 § Gap matrix rows 3/4/5 status flipped to `shipped`

## Non-goals

- Moving `probe.sh` or any other `.claude/tools/*.sh` — that is row 6 / Phase 3 (`105-shared-tools-to-agent0`). This spec leaves probe's *invocation path* at `.claude/tools/probe.sh`; only the state paths it *reads* move.
- Re-homing the runtime-capture producer hooks (`runtime-capture.sh` / `runtime-pre-mark.sh`) out of `.claude/hooks/` — they stay Claude-only until a Codex runtime-capture port exists (umbrella 102 row 4 caveat).
- Auto-migrating consumer-project data. Forks move their own `.claude/.*-state/` content; the stale consumer `.gitignore` entries from a prior sync are benign orphans (additive merge never removes), same posture as spec 103.
- Touching `.claude/.compact-history/` (umbrella row 12, `stays` provisional) or any runtime-exclusive surface.

## Open questions

_None — all resolved at umbrella 102 disposition time (2026-05-28). Row 4's producer-stays-Claude-only caveat is a recorded decision, not an open question._

## Context / references

- `docs/specs/102-harness-consolidate-agent0/spec.md` § Gap matrix rows 3-5 + § Classification principle — the parent umbrella; this spec is its Phase 2.
- `docs/specs/103-reminders-routines-to-agent0/` — Phase 1 precedent (same capacity-only relocation shape).
- `docs/specs/101-session-handoff-multi-runtime/spec.md` § OQ-E — the prior "keep `.claude/.session-state/`" decision this spec reverses.
- `.claude/rules/harness-sync.md` § Path relocations (capacity-only) — the consumer-migration posture this spec follows.
- `.claude/rules/session-handoff.md` § State files / § Cross-capacity dependency — documents the 4-file contract + probe.sh coupling being moved.
