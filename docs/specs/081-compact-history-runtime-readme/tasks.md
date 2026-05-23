# 081 — compact-history-runtime-readme — tasks

_Generated from `plan.md` on 2026-05-23. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### MS-6 — Runtime-state README (additive, lower-risk; ship first)

- [x] 1. **Create `.claude/.runtime-state/README.md`** — title + 1-paragraph framing (gitignored siblings, per-machine ephemeral state, README is the git-tracked exception); 6-row table `| Path | Owner | Purpose |` covering `.claude/.runtime-state/` (runtime-introspect last-run snapshot), `.claude/.browser-state/` (mcp-recipes Playwright auth state), `.claude/.delegation-state/` (delegation per-agent loop-budget counters), `.claude/.routines-state/` (routines queue + completed renders), `.claude/.rule-load-debug.jsonl` (rule-load-debug opt-in instrumentation), `.claude/.compact-history/` (compaction-continuity per-event snapshots, added by spec 081); each Owner cell links to the rule under `.claude/rules/`; footer paragraph declares the discipline: future state subsystems update this README in the same commit that ships them.

- [x] 2. **Update `.gitignore` to add the README exception** — under the existing `.claude/.runtime-state/` line, add `!.claude/.runtime-state/README.md` on the next line (exception must follow the dir-ignore line per git semantics).

- [x] 3. **Add the README path to `.claude/tools/sync-harness.sh` `COPY_CHECK_FILES` array** — insert `".claude/.runtime-state/README.md"` alongside the existing `.gitkeep` literals (around line 181-183); preserve alphabetical / grouped ordering convention.

### MS-3 — Per-compaction snapshot history (behavioral)

- [x] 4. **Modify `.claude/hooks/pre-compact.sh`** — replace the constant `NOTES_FILE` with a per-call path under `.claude/.compact-history/`:
  - Compute filename: `printf -v RAND_PAD '%05d' $RANDOM; TS="$(date -u +%Y-%m-%dT%H-%M-%SZ)-$$-$RAND_PAD"; NOTES_FILE="$PROJECT_DIR/.claude/.compact-history/$TS.md"`
  - `mkdir -p` the parent before write
  - After the existing snapshot write block, add retention pass: `KEEP_LAST="$(jq -r '.compactHistory.keepLast // 20' "$PROJECT_DIR/.claude/settings.json" 2>/dev/null || echo 20)"; ls -1t "$PROJECT_DIR/.claude/.compact-history"/*.md 2>/dev/null | tail -n +$((KEEP_LAST + 1)) | xargs -r rm -f`
  - Keep everything else (transcript parsing, git-status capture, exit 0 always) unchanged.

- [x] 5. **Modify `.claude/hooks/session-start.sh`** — on `source=compact`, swap the single-file read for the lex-greatest snapshot:
  - Remove the `NOTES_FILE=…COMPACT_NOTES.md` line (no longer the snapshot location)
  - Replace the `if [[ "$SOURCE" == "compact" && -f "$NOTES_FILE" ]]; then … cat "$NOTES_FILE" …` branch with a block that reads `LATEST="$(ls -1 "$PROJECT_DIR/.claude/.compact-history"/*.md 2>/dev/null | tail -1)"` and `cat`s it inside `=== compact-history === / === end compact-history ===` banners when `LATEST` is non-empty and exists.
  - Graceful no-op when dir missing or empty (no banner, no error) — matches the current behavior of the missing-file branch.

- [x] 6. **Update `.gitignore` for the new snapshot dir** — add `.claude/.compact-history/` to the ephemeral-state block (alongside `.claude/.runtime-state/`, `.claude/.session-state/`, etc.); remove the now-obsolete `.claude/COMPACT_NOTES.md` entry (the file is no longer written by any hook).

### Rule update + local cleanup

- [x] 7. **Update `.claude/rules/compaction-continuity.md`** — § *Flow*: replace references to `COMPACT_NOTES.md` with the per-event path under `.claude/.compact-history/`; § *Files*: list `.claude/.compact-history/<ISO>-<pid>-<rand>.md` instead of the single file; § *Gotchas*: remove the "snapshot file is overwritten" entry, add a one-line note that the single-file model was retired by 081; add a short note in § *Files* documenting `compactHistory.keepLast` in `.claude/settings.json` (default 20, fork-overridable).

- [x] 8. **Remove stale local `COMPACT_NOTES.md`** — `rm -f .claude/COMPACT_NOTES.md` in the working tree. One-shot manual cleanup, not in the hook (a hook running one-time side-effects is a footgun). Verify via `ls .claude/COMPACT_NOTES.md` returning no-such-file afterward.

### Tests

- [x] 9. **Add `.claude/tests/compaction-continuity/` test script** — a deterministic bash test exercising:
  - `pre-compact.sh` with a synthesized stdin payload + a tmp transcript JSONL creates a file matching `.claude/.compact-history/<timestamp>-<pid>-<rand>.md` (scenario 1 in spec.md)
  - Two invocations in sequence produce two distinct files (scenario 2)
  - With `compactHistory.keepLast: 3` in a tmp settings.json, running 5 invocations leaves exactly 3 files (scenario 4)
  - `session-start.sh` with `source=compact` and 3 files in the dir reads the lex-greatest (scenario 3)
  - `session-start.sh` with `source=compact` and an empty/missing dir exits silently (no banner, no error)
  - Convention mirrors `.claude/tests/session-handoff/` and `.claude/tests/runtime-introspect/` — single executable bash script that sets up a tmp `PROJECT_DIR`, runs each assertion with `set -e`, exits 0 on green / non-zero on red.

## Verification

_Maps directly to acceptance criteria in `spec.md`._

- [x] 10. **MS-3 acceptance — observable scenarios** — drive the test script from task 9 to green:
  - Scenarios 1-4 (file creation, second-compact preservation, lex-greatest read, retention cap) — pass via the test script
  - Static-fact checks: `git check-ignore -v .claude/.compact-history/foo.md` returns ignored; `bash -n .claude/hooks/pre-compact.sh && bash -n .claude/hooks/session-start.sh` returns 0
  - § *Gotchas* in `compaction-continuity.md` no longer carries the "snapshot file is overwritten" line

- [x] 11. **MS-6 acceptance — observable scenarios** — inspection-only:
  - `git check-ignore -v .claude/.runtime-state/README.md` returns NON-ZERO (file is NOT ignored — exception works)
  - `git ls-files .claude/.runtime-state/README.md` lists the file (it IS tracked)
  - `grep -c '.claude/.runtime-state/README.md' .claude/tools/sync-harness.sh` returns 1 (entry added to `COPY_CHECK_FILES`)
  - README enumerates all 6 subsystems with Owner column pointing at a rule
  - README's footer declares the "future additions update this README in the same commit" discipline

- [x] 12. **Spec status flip** — once tasks 1-11 are green, edit `docs/specs/081-compact-history-runtime-readme/spec.md`: change `**Status:** draft` → `**Status:** shipped`; tick all acceptance-criteria checkboxes; tick the OQ checkboxes (locked per plan); ensure `notes.md` carries any deviations from plan that surfaced during implementation.

## Notes

- The plan locks all four OQs from `spec.md` — task execution must NOT re-open them silently. If a task reveals a locked decision was wrong, surface it in `notes.md` under `### YYYY-MM-DD — parent — <title>` and update `plan.md` before continuing.
- Task 9 (tests) is new scope relative to the plan; TDD discipline (per `.claude/rules/tdd.md`) applies because hook changes are behavioral production-code edits. The plan's risks section mentioned `printf -v RAND_PAD` width-stability — that's the highest-value test assertion (lex order across seconds).
- Recommended commit shape: one commit per MS arm + one for the rule update + one for tests, OR a single squashed commit titled `feat(081): compact-history dir + runtime-state README`. Either works; user preference.
