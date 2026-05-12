# 023 — session-stop-noop-aware — tasks

_Generated from `plan.md` on 2026-05-12. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [ ] 1. Resolve open questions Q1–Q4 in `spec.md` (defaults proposed; confirm or override before code lands).
- [ ] 2. Amend `.claude/hooks/session-start.sh`: after `touch "$STATE_DIR/started-at"`, add a guarded porcelain snapshot write. Shape:
  ```bash
  if git -C "$PROJECT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    git -C "$PROJECT_DIR" status --porcelain > "$STATE_DIR/start-porcelain.txt" 2>/dev/null || true
  fi
  ```
  Best-effort; failure silent; never propagates.
- [ ] 3. Amend `.claude/hooks/session-stop.sh`: between the porcelain non-empty check (current line 49) and the SESSION.md mtime check (current line 54), insert porcelain comparison early-exit. Shape:
  ```bash
  if [[ -f "$STATE_DIR/start-porcelain.txt" ]]; then
    current_porcelain="$(git -C "$PROJECT_DIR" status --porcelain 2>/dev/null || true)"
    if [[ "$current_porcelain" == "$(cat "$STATE_DIR/start-porcelain.txt")" ]]; then
      exit 0
    fi
  fi
  ```
  (Using string equality rather than `cmp -s` to avoid a second process spawn and a temp-file dance — porcelain output is typically <10 KB.)
- [ ] 4. Update `.claude/rules/session-handoff.md` § State files: name the snapshot file, describe the carryover-discrimination semantic, note the fallback behavior when snapshot is missing, document the `/compact` and `/resume` snapshot overwrite behavior.
- [ ] 5. Create `.claude/tests/session-handoff/` and write the 5 scenario fixtures listed in `plan.md` § Files to touch.
- [ ] 6. Run the test suite locally; confirm all 5 scenarios behave as the spec acceptance criteria describe.
- [ ] 7. Dogfood pass: start a fresh session in this repo with carryover present (e.g. the current `.gitignore` + `docs/specs/010-audit-forensics/` state), perform a no-op exchange, end turn. Confirm Stop hook does NOT block.
- [ ] 8. Dogfood pass: start a fresh session, edit one tracked file (no SESSION.md update), end turn. Confirm Stop hook DOES block once with the existing reminder.
- [ ] 9. Commit the change with message referencing this spec dir. Single commit covers hook changes + rule doc + tests.

## Verification

_Each entry maps to a `spec.md` acceptance criterion._

- [ ] Scenario 1 (no-op with carryover) — covered by task 7 dogfood + test `01-noop-with-carryover.sh`.
- [ ] Scenario 2 (edits without SESSION.md update) — covered by task 8 dogfood + test `02-edits-without-session-update.sh`.
- [ ] Scenario 3 (edit then revert) — covered by test `03-edit-then-revert.sh`.
- [ ] Scenario 4 (new untracked file) — covered by test `04-new-untracked-file.sh`.
- [ ] Scenario 5 (mid-session commit) — covered by test `02-edits-without-session-update.sh` (the existing flow handles this; porcelain shrinks but doesn't return to start unless commit covers exactly the same fileset).
- [ ] Scenario 6 (snapshot missing fallback) — covered by test `05-snapshot-missing-fallback.sh`.
- [ ] Static fact: `.claude/.session-state/<session_id>/start-porcelain.txt` is written on every fresh session — verified by inspecting the dir after task 7.
- [ ] Static fact: snapshot is gitignored — verified by `git status` post-task-7 showing no surprise tracked file.
- [ ] Static fact: rule doc updated — verified by `grep -n "start-porcelain" .claude/rules/session-handoff.md` returning the new section.

## Notes

- The spec is small enough that tasks 2-4 can land in a single edit-write session. Tests are the larger piece — budget for that.
- This spec coordinates with neither 014 nor 015; touches only session-state code, no overlap with `detect_at` or mcp-recipes.
- Capacity inheritance: this fix lands in Agent0 and propagates to forks via `sync-harness.sh` on their next adoption pass (both hooks are in the COPY_CHECK_GLOBS manifest).
- No SESSION.md update needed at delivery — this conversation will commit the spec scaffold, and the implementation belongs to a separate session that will naturally update SESSION.md as work progresses.
