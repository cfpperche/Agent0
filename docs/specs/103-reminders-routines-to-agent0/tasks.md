# 103 — reminders-routines-to-agent0 — tasks

_Generated from `plan.md` on 2026-05-28. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Phase A — move the files (new paths must exist before references repoint)

- [x] 1. `git mv .claude/reminders.yaml .agent0/reminders.yaml`. **Done when** `git status` shows the rename staged and `git log --follow .agent0/reminders.yaml` reaches the original history.
- [x] 2. `git mv .claude/routines .agent0/routines` (carries `.gitkeep` + `cc-platform-audit.md` + `hook-chain-bench.md`). **Done when** `.agent0/routines/` exists with all three files and `.claude/routines/` is gone.
- [x] 3. `mv .claude/.routines-state .agent0/.routines-state` (gitignored — plain mv). **Done when** `.agent0/.routines-state/` holds the prior `cc-platform-audit/completed/*` and `.claude/.routines-state/` is gone.

### Phase B — repoint hooks (the read path for both runtimes)

- [x] 4. `.agent0/hooks/reminders-readout.sh` — `YAML_FILE` (L28) → `.agent0/reminders.yaml`; fix the two comments (L3, L69). **Done when** `bash -n` parses and no `.claude/reminders.yaml` literal remains.
- [x] 5. `.agent0/hooks/routines-readout.sh` — `ROUTINES_DIR` (L25) + `STATE_DIR` (L26) → `.agent0/...`; fix comment (L6). **Done when** `bash -n` parses and no `.claude/routines`/`.claude/.routines-state` literal remains.

### Phase C — repoint skills + scripts + template

- [x] 6. `.claude/skills/remind/scripts/reminders-helper.py` — `_project_root` return (L48) → `.agent0/reminders.yaml`; docstring (L14). **Done when** `python3 -c 'import ast; ast.parse(open("...").read())'` parses and a temp `add` writes to `.agent0/reminders.yaml`.
- [x] 7. `.claude/skills/remind/SKILL.md` — state-file refs (L3, 16, 28, 30) → `.agent0/reminders.yaml`.
- [x] 8. `.claude/skills/routine/scripts/{new,list,validate}.sh` — `ROUTINES_DIR`/`STATE_DIR`/`FILE` constants → `.agent0/...`. **Done when** all three `bash -n` parse.
- [x] 9. `.claude/skills/routine/templates/routine.md.tmpl` (L33) + `.claude/skills/routine/SKILL.md` (all `.claude/routines`/`.claude/.routines-state` refs) → `.agent0/...`.

### Phase D — repoint cron + sync tools

- [x] 10. `.claude/tools/install-routines.sh` (L4, 15, 18, 86), `run-routine.sh` (L9, 24, 57), `uninstall-routines.sh` (L61) → `.agent0/...`. **Done when** the three `bash -n` parse.
- [x] 11. `.claude/tools/sync-harness.sh` — special-file `.claude/routines/.gitkeep` → `.agent0/routines/.gitkeep` (L200) + manifest comments (L168-169). **Done when** `bash -n` parses and the COPY_CHECK_FILES entry reads `.agent0/routines/.gitkeep`.

### Phase E — repoint rules, docs, gitignore

- [x] 12. `.claude/rules/reminders.md` + `.claude/rules/routines.md` — bulk rewrite all three path stems.
- [x] 13. `.claude/rules/runtime-capabilities.md`, `.claude/rules/image-gen.md`, `.claude/skills/skill/SKILL.md`, `.claude/skills/skill/references/portability-tiers.md`, `.claude/.runtime-state/README.md`, `AGENTS.md`, `CLAUDE.md` — cross-reference rewrites.
- [x] 14. `.gitignore` — L30 `.claude/.routines-state/` → `.agent0/.routines-state/`. **Done when** `git check-ignore .agent0/.routines-state/x` matches and `.claude/.routines-state` is no longer listed.
- [x] 15. `.claude/rules/harness-sync.md` — add the capacity-only relocation posture (new forks born under `.agent0/`; existing forks migrate own data on next sync).

### Phase F — tests

- [x] 16. `.claude/tests/multi-runtime-readouts/{01-reminders-fixture,02-routines-fixture,04-subdir-launch}.sh` — create fixtures at `.agent0/` paths instead of `.claude/`.

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria._

- [x] 17. **Grep guard** — zero matches for `.claude/reminders.yaml` / `.claude/routines` / `.claude/.routines-state` across `.agent0/hooks/`, `.claude/skills/`, `.claude/tools/`, `.claude/rules/`, `.claude/tests/`, `AGENTS.md`, `CLAUDE.md` (excludes `docs/specs/`, `.claude/.session-state/*`). → spec criterion "zero references".
- [x] 18. **Readout fixtures** — run each `.claude/tests/multi-runtime-readouts/{01,02,04,05}-*.sh` (no `run-all.sh` in that dir); all PASS → reminders/routines readout + subdir scenarios.
- [x] 19. **Helper smoke** — `/remind` helper `add`+`list` writes/reads `.agent0/reminders.yaml`; `routine/scripts/list.sh` + `validate.sh` resolve `.agent0/routines/` → spec scenarios 2-3.
- [x] 20. **sync-harness dry-run** — `bash .claude/tools/sync-harness.sh --apply --dry-run --agent0-path=$(pwd) <tmp-consumer>` shows `.agent0/routines/.gitkeep` propagating, no dangling `.claude/routines/.gitkeep` → spec criterion "manifest updated".
- [x] 21. **Config check + git hygiene** — confirm no `.claude/reminders\|routines` literal in `.codex/config.toml*` (OQ-2 resolved); `git mv` history intact (`git log --follow`); `git diff --check` clean.
- [x] 22. **Routine/remind tests (if any beyond readouts)** — run any `.claude/tests/*remind*` / `*routine*` suites green.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._
