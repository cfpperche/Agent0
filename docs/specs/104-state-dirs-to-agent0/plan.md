# 104 — state-dirs-to-agent0 — plan

_Drafted from `spec.md` on 2026-05-28._

## Approach

A pure string-relocation across four layers, applied in a dependency-safe order so the migration window for the live session is minimal. (1) `.gitignore` + `git mv` of the two tracked sentinels first, so new runtime state lands in already-ignored paths. (2) sync-harness manifest, so the capacity propagates. (3) load-bearing code paths in the producer/consumer hooks + tools. (4) docs/rules/entrypoints/memory + test fixtures. Then run every affected suite. The change is mechanical because each surface hardcodes `$PROJECT_DIR/.claude/.<x>-state` as a single variable assignment or a literal path; the relocation is a `.claude/` → `.agent0/` swap on three specific dir names, never the broader `.claude/` prefix.

Session-state has no tracked content (the whole dir is gitignored; hooks `mkdir -p` it at runtime), so only the gitignore entry + code paths + fixtures change for it. Runtime-state ships a tracked `README.md`; browser-state ships a tracked `.gitkeep` — both are `git mv`'d and re-pointed in the manifest.

## Files to touch

**git mv (tracked sentinels):**
- `.claude/.runtime-state/README.md` → `.agent0/.runtime-state/README.md`
- `.claude/.browser-state/.gitkeep` → `.agent0/.browser-state/.gitkeep`

**Modify — gitignore + manifest:**
- `.gitignore` — 3 entry rewrites (lines 11-13, 28): `.claude/.runtime-state/*` + `!…/README.md`; `.claude/.session-state/`; `.claude/.browser-state/*.json` → `.agent0/…`
- `.claude/tools/sync-harness.sh` — `COPY_CHECK_FILES` 2 entries (`.agent0/.browser-state/.gitkeep`, `.agent0/.runtime-state/README.md`) + the project-local comment block (lines 164-165)

**Modify — load-bearing code paths:**
- `.agent0/hooks/session-start.sh` (`SESSION_STATE_ROOT`), `session-stop.sh` (`SESSION_STATE_ROOT`), `session-track-edits.sh` (`SESSION_STATE_ROOT` + docstring)
- `.claude/tools/probe.sh` (`STATE_FILE`, `SESSION_STATE_DIR` + docstring comments — but NOT the `bash .claude/tools/probe.sh` self-reference, row 6)
- `.claude/hooks/runtime-capture.sh` (`STATE_DIR` + docstring), `runtime-pre-mark.sh` (`IN_FLIGHT_DIR` + docstring)
- `.claude/tools/bench-hooks.sh` (the `mkdir -p …/.runtime-state/in-flight`)

**Modify — docs/rules/entrypoints/memory:**
- `.claude/rules/`: `session-handoff.md`, `harness-sync.md`, `browser-auth.md`, `runtime-introspect.md`, `runtime-capabilities.md`, `secrets-scan.md`, `memory-placement.md`
- `.claude/skills/skill/references/portability-tiers.md`
- `CLAUDE.md`, `AGENTS.md` (managed-block byte-equality must hold — edit both identically)
- `.agent0/memory/runtime-introspect-maintenance.md`
- moved `README.md` body (self-references to its own path)

**Modify — test fixtures:**
- `.claude/.session-state` → `.agent0/.session-state`: `session-state-isolation/*` (7), `session-edit-attribution/*` (7), `session-handoff/*` (3), `session-handoff-multi-runtime/*` (4), + 1 in `runtime-introspect/`, + 1 in `harness-sync/`
- `.claude/.runtime-state` → `.agent0/.runtime-state`: `runtime-introspect/*` (14), `runtime-capture-php/*` (7), + 3 in `harness-sync/`
- harness-sync manifest/gitignore-merge tests (13/14/15 + any asserting the two COPY_CHECK paths) — verify expected paths, not blind sed

## Alternatives considered

### Three separate child specs (one per state dir)

Rejected. The three dirs share the same `.gitignore` file, the same `probe.sh` (reads session-state + runtime-state), the same sync-harness manifest, and overlapping test fixtures (e.g. `harness-sync/14` references both session-state and runtime-state). Three specs would triple the churn on those shared files and produce three baseline bumps for what is one coherent mechanical move. Bundling is *less* diff, not a mega-diff (no behavior change, all string swaps).

### Defer row 4 (runtime-state) until a Codex runtime-capture port exists

Considered at umbrella disposition time; rejected by founder choice 2026-05-28. probe.sh (the neutral reader) moves in Phase 3, so leaving runtime-state in `.claude/` would re-create the exact reader/state split the umbrella kills. The producer-stays-Claude-only caveat is recorded instead.

## Risks and unknowns

- **Live-session mid-migration window.** This Claude session's `session-start.sh` already wrote state to `.claude/.session-state/<id>/`; after the code edit, the Stop hook reads `.agent0/.session-state/<id>/` and finds no `started-at`/`start-porcelain`, falling to its mtime/porcelain fallback. Harmless (ephemeral, one session); the HANDOFF update + commit satisfy the nag anyway. `CLAUDE_SKIP_SESSION_HOOKS=1` is the escape hatch if it interferes.
- **harness-sync tests are assertion-sensitive.** The gitignore-merge + manifest tests assert exact paths. Blind sed could corrupt an expected-output heredoc. Mitigation: read each affected harness-sync test before editing.
- **CLAUDE.md/AGENTS.md managed-block byte-equality.** `instruction-drift` test 03 asserts the two managed blocks are byte-equal. Any `.claude/.*-state/` mention inside the managed region must be edited identically in both files. Mitigation: run `instruction-drift` suite after.
- **Additive gitignore merge leaves orphan consumer entries.** A previously-synced consumer keeps its stale `.claude/.*-state/` gitignore lines (merge never removes). Benign (ignores an unused dir); documented as a non-goal, matches spec 103.

## Research / citations

- `.claude/rules/harness-sync.md` § Path relocations + § .gitignore merge strategy — read in full this session; confirms capacity-only posture + additive-merge orphan behavior.
- spec 103 (`reminders-routines-to-agent0`) — direct precedent for the same relocation shape, already shipped + verified.
