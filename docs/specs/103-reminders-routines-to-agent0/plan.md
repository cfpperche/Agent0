# 103 — reminders-routines-to-agent0 — plan

_Drafted from `spec.md` on 2026-05-28. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Pure relocation in a fixed order: **move the files first, then rewrite every reference, then update tests, then verify.** Moving first means the new paths exist before any script points at them, so a half-applied state never reads a missing file. Two move kinds: `git mv` for git-tracked data (`reminders.yaml`, `routines/` incl. `.gitkeep` + the 2 routine defs) to preserve `--follow` history; plain `mv` for the gitignored per-machine `.routines-state/` (no history to preserve, but we move it to keep this machine's `cc-platform-audit` completed/ trail rather than orphan it — resolves spec OQ-1).

Reference rewrite is a mechanical search-replace of three path stems across the shipped surface — `.claude/reminders.yaml`→`.agent0/reminders.yaml`, `.claude/routines`→`.agent0/routines`, `.claude/.routines-state`→`.agent0/.routines-state` — touching hooks, the remind helper, both skills + scripts + the routine template, the four cron/sync tools, both capacity rules + cross-ref rules, the skill-meta references, the runtime-state README, both entrypoints, and the readout test fixtures. The sync-harness manifest's one special-file entry (`.claude/routines/.gitkeep`) and `.gitignore`'s one line move with them. No base-dir glob changes (routine *definitions* remain project-local/non-propagated — only the `.gitkeep` scaffold travels, same posture as today). Finally a grep guard proves zero old-path references remain in the shipped surface, the readout suite + a helper smoke confirm behavior, and a sync-harness `--apply --dry-run` confirms the relocated scaffold propagates.

## Files to touch

**Move (git mv — tracked, preserve history):**
- `.claude/reminders.yaml` → `.agent0/reminders.yaml`
- `.claude/routines/` → `.agent0/routines/` (carries `.gitkeep`, `cc-platform-audit.md`, `hook-chain-bench.md`)

**Move (plain mv — gitignored per-machine state):**
- `.claude/.routines-state/` → `.agent0/.routines-state/`

**Modify — hooks:**
- `.agent0/hooks/reminders-readout.sh` — `YAML_FILE` path (L28) + comments (L3, L69)
- `.agent0/hooks/routines-readout.sh` — `ROUTINES_DIR` (L25), `STATE_DIR` (L26) + comment (L6)

**Modify — skills + scripts + template:**
- `.claude/skills/remind/scripts/reminders-helper.py` — `_project_root` return (L48) + docstring (L14)
- `.claude/skills/remind/SKILL.md` — state-file references (L3, L16, L28, L30; bare `reminders.yaml` mentions need no change)
- `.claude/skills/routine/scripts/new.sh` (L24), `list.sh` (L13-14), `validate.sh` (L21)
- `.claude/skills/routine/templates/routine.md.tmpl` (L33)
- `.claude/skills/routine/SKILL.md` — many path references (L3, 16, 34-35, 42, 47-48, 57-59, 64, 66, 70, 91, 109)

**Modify — tools:**
- `.claude/tools/install-routines.sh` (L4, 15, 18, 86)
- `.claude/tools/run-routine.sh` (L9, 24, 57)
- `.claude/tools/uninstall-routines.sh` (L61)
- `.claude/tools/sync-harness.sh` — special-file `.claude/routines/.gitkeep`→`.agent0/routines/.gitkeep` (L200) + manifest comments (L168-169)

**Modify — rules + docs:**
- `.claude/rules/reminders.md`, `.claude/rules/routines.md` — bulk path rewrites
- `.claude/rules/runtime-capabilities.md`, `.claude/rules/image-gen.md` — cross-references
- `.claude/skills/skill/SKILL.md`, `.claude/skills/skill/references/portability-tiers.md` — example path references
- `.claude/.runtime-state/README.md` (L14 — table row + key)
- `AGENTS.md` (L96), `CLAUDE.md` (L116)

**Modify — config:**
- `.gitignore` — L30 `.claude/.routines-state/` → `.agent0/.routines-state/`

**Modify — tests:**
- `.claude/tests/multi-runtime-readouts/01-reminders-fixture.sh` (L15)
- `.claude/tests/multi-runtime-readouts/02-routines-fixture.sh` (L11-14)
- `.claude/tests/multi-runtime-readouts/04-subdir-launch.sh` (L14-15, 20, 28, 30)

**Modify — consumer-migration doc:**
- `.claude/rules/harness-sync.md` — add the capacity-only relocation posture (umbrella 102 acceptance): new forks born under `.agent0/`; existing forks migrate their own `.claude/reminders.yaml` + `.claude/routines/` on next sync.

## Alternatives considered

### Back-compat symlink (`.claude/reminders.yaml` → `.agent0/reminders.yaml`)

Rejected because the project's posture is hard-cutover with no compat shims (precedent: the `.claude/SESSION.md` pointer shim was *removed* in spec 101, not kept). Symlinks are also fragile cross-platform (Windows checkout) and would leave a dangling `.claude/` artifact contradicting the consolidation's whole point. Capacity-only migration means a clean break, not a bridge.

### Move reminders now, routines in a later phase

Rejected because the user scoped both for Phase 1 (data + per-machine state). They are parallel capacities with an identical move shape; splitting them doubles the review/verify overhead and the grep-guard passes for free when done together.

### Leave data in `.claude/`, only document the `.agent0/` intent

Rejected — that is the status quo the umbrella exists to change; documenting intent without moving achieves no consolidation.

## Risks and unknowns

- **Missed reference.** A surviving `.claude/reminders.yaml` / `.claude/routines` literal would silently read the old (now-absent) path. Mitigation: the grep guard (acceptance criterion) is the gate — zero shipped-surface matches required.
- **sync-harness manifest drift.** If the `.gitkeep` special-file entry isn't repointed, fresh consumer clones miss the `.agent0/routines/` scaffold. Mitigation: the `--apply --dry-run` against a fixture consumer is a required check.
- **In-flight Codex dogfood.** The active Codex session validating specs 100/101 uses the readout hooks; rewriting `reminders-readout.sh`/`routines-readout.sh` changes their data path for the *next* session (SessionStart already fired for the current one). Low risk; re-validate after.
- **Consumer forks (mei-saas, codexeng).** Their data stays at `.claude/` until they manually migrate — by design (capacity-only). Risk is a fork author confused by the move; mitigated by the `harness-sync.md` note.
- **`.codex/config.toml*` (OQ-2).** Expected no change — Codex hook blocks point at `.agent0/hooks/*.sh` scripts, which resolve data paths internally. Confirm by inspection during execution (no `.claude/reminders\|routines` literal in the config).

## Research / citations

- Reference surface mapped via `grep -rn` across `.agent0/hooks/`, `.claude/skills/`, `.claude/tools/`, `.claude/rules/`, `.claude/tests/`, `.gitignore`, `AGENTS.md`, `CLAUDE.md`, `.claude/.runtime-state/README.md` (this session, 2026-05-28) — exact line numbers in § Files to touch.
- `docs/specs/102-harness-consolidate-agent0/spec.md` — umbrella principle + capacity-only migration posture.
- `docs/specs/101-session-handoff-multi-runtime/spec.md` § OQ-E + the SESSION.md hard-cutover precedent (informs the no-symlink alternative).
- `.claude/rules/harness-sync.md` + `.claude/tools/sync-harness.sh` manifest (base-dirs vs special-files distinction — routine defs are project-local, only `.gitkeep` propagates).
