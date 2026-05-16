# 030 — session-edit-attribution — tasks

_Generated from `plan.md` on 2026-05-16. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [ ] 1. **Create test directory scaffold** — `mkdir -p .claude/tests/session-edit-attribution/` and add `run-all.sh` (copy shape from `.claude/tests/session-handoff/run-all.sh`). This anchors the TDD loop before any hook code exists.

- [ ] 2. **Create `.claude/hooks/session-track-edits.sh`** with the following contract:
  - `set -euo pipefail`; honour `CLAUDE_SKIP_SESSION_HOOKS=1` → `exit 0` immediately (same escape hatch as siblings).
  - Read stdin JSON; if absent or `jq` missing → `exit 0` (fail-open).
  - Extract `session_id` via `jq -r '.session_id // empty'` and sanitize against `^[a-zA-Z0-9_-]+$`; reject → `SESSION_ID=unknown`.
  - Extract `tool_input.file_path` via `jq -r '.tool_input.file_path // empty'`; if empty → `exit 0` (some Edit payloads might lack a path in malformed cases).
  - Normalize to project-relative path: prefer `realpath --relative-to="$CLAUDE_PROJECT_DIR"` when both available; otherwise log literal.
  - Append (deduped) to `$CLAUDE_PROJECT_DIR/.claude/.session-state/$SESSION_ID/edited-files.txt`, guarded by `flock` on the file descriptor. Use `mkdir -p` for the state dir.
  - Final `exit 0`. The hook must NEVER block — return non-zero only on `set -e` faults during the guarded block (acceptable since failure is invisible to the tool call).
  - Make executable with `chmod +x`.

- [ ] 3. **Smoke-test the new hook in isolation** — write `.claude/tests/session-edit-attribution/01-tracker-appends.sh`:
  - Set up temp `CLAUDE_PROJECT_DIR`, create `.claude/.session-state/test-sid/`, pipe a fake PostToolUse payload (`{"session_id":"test-sid","tool_input":{"file_path":"foo.ts"}}`) into the hook.
  - Assert `edited-files.txt` exists and contains `foo.ts`.
  - Pipe the same payload again; assert no duplicate line (dedup invariant).
  - Pipe a malformed payload (empty stdin); assert exit 0 and no crash.
  - Run: `bash .claude/tests/session-edit-attribution/01-tracker-appends.sh` → expect PASS.

- [ ] 4. **Register the new hook in `.claude/settings.json`** — add a third `command` entry under the existing `PostToolUse` block whose matcher is `Edit|Write|MultiEdit`: `bash "$CLAUDE_PROJECT_DIR"/.claude/hooks/session-track-edits.sh`. Validate JSON parses: `python3 -m json.tool .claude/settings.json >/dev/null`.

- [ ] 5. **Extend `.claude/hooks/session-stop.sh` with the primary-step check.** Insert between the "no uncommitted changes → exit 0" guard (current line 50) and the spec-023 porcelain-compare (current lines 58-63). New block reads `$STATE_DIR/edited-files.txt`:
  - If file does NOT exist → fall through to spec-023 path unchanged (legacy session).
  - If file exists and is empty → `exit 0` silently (this session edited nothing).
  - If file exists and non-empty → for each listed path, check whether it still appears as dirty in `$CURRENT_PORCELAIN` (substring match on the `<status> <path>` lines). If at least one tracked path is still dirty → set `OWN_DIRTY_WIP=1` and skip the spec-023 compare (already decided to potentially block). If all are clean (committed/reverted) → `exit 0`.
  - The spec-023 compare and subsequent SESSION.md mtime check only run on the legacy-or-fallback branch; the new branch handles its own short-circuits.

- [ ] 6. **Write scenario test `02-bystander.sh`** — session A has zero edited-files entries, sibling session B (simulated via direct file modification) modifies a tracked file during A's lifetime. Assert: A's Stop hook returns no block decision. Run → expect PASS.

- [ ] 7. **Write scenario test `03-own-edits-uncommitted.sh`** — session calls the tracker hook with a payload for `foo.ts`, then modifies `foo.ts` in the working tree (without committing), runs Stop. Assert: block decision is emitted (since SESSION.md not updated). Run → expect PASS.

- [ ] 8. **Write scenario test `04-own-edits-committed.sh`** — session tracks an edit to `foo.ts`, then commits it, runs Stop. Assert: no block (path no longer dirty). Run → expect PASS.

- [ ] 9. **Write scenario test `05-own-edits-reverted.sh`** — session tracks an edit to `foo.ts`, then `git restore foo.ts`, runs Stop. Assert: no block. Run → expect PASS.

- [ ] 10. **Write scenario test `06-bash-driven-fallback.sh`** — no tracker entries (simulating a Bash-only edit), porcelain shows a dirty file, runs Stop. Assert: block fires via spec-023 fallback. Run → expect PASS.

- [ ] 11. **Write scenario test `07-legacy-session.sh`** — no `edited-files.txt` file in state dir, dirty porcelain mismatched from start-porcelain, runs Stop. Assert: behavior identical to spec 023 (block fires). Run → expect PASS.

- [ ] 12. **Write scenario test `08-block-once-invariant.sh`** — session triggers a block once (own-dirty + no SESSION.md), then runs Stop a second time without resolution. Assert: second Stop does NOT re-emit a block (existing `nagged` marker short-circuit honoured). Run → expect PASS.

- [ ] 13. **Update `.claude/rules/session-handoff.md`**:
  - § *State files* — add `edited-files.txt` to the per-session subdir list with one-line description (line-per-path, deduped, 7-day cleanup, gitignored).
  - § *Carryover discrimination* — rewrite to name `edited-files.txt`-attribution as the primary signal and demote `start-porcelain.txt`-compare to fallback. Cross-reference spec 030.
  - Add new § *Edit attribution* (short, ~10 lines): the contract (Edit/Write/MultiEdit → tracker primary; Bash/IDE/external → spec-023 fallback), the rationale (per-`session_id` payload attribution beats worktree-delta inference), known limitation (Bash-driven edits unattributed).
  - Confirm spec 023 stays `shipped` (NOT marked superseded). Its mechanism stays live as fallback.

- [ ] 14. **Create `run-all.sh`** under `.claude/tests/session-edit-attribution/` that iterates `01-*.sh … 08-*.sh` and reports pass/fail counts (copy structure from `.claude/tests/session-handoff/run-all.sh`).

- [ ] 15. **Performance sanity check** — `time bash .claude/hooks/session-track-edits.sh < /dev/null` (≤ 5 ms target) and `time` a full edit-then-stop cycle. Document the measured number in a comment near the hook's header. If > 10 ms, investigate before declaring done.

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria. Each one maps to a checklist item there._

- [ ] **Run full new suite** — `bash .claude/tests/session-edit-attribution/run-all.sh` → all 8 scenarios PASS.

- [ ] **Run existing session suites** to confirm no regression — `bash .claude/tests/session-handoff/run-all.sh` and `bash .claude/tests/session-state-isolation/run-all.sh` → all green.

- [ ] **Hand-verify the canonical bystander case** — open two terminals: terminal 1 runs `bash .claude/hooks/session-start.sh <<< '{"source":"startup","session_id":"manual-A"}'`. Terminal 2 modifies a tracked file. Terminal 1 then runs `bash .claude/hooks/session-stop.sh <<< '{"session_id":"manual-A"}'` and asserts no `"decision":"block"` in the output.

- [ ] **Inspect `.claude/.session-state/<sid>/edited-files.txt`** after a real Claude Code session that did one Edit — the file should exist, contain the edited path (project-relative), and have no duplicates after repeated edits to the same file.

- [ ] **Verify rule doc cross-references** — `grep -n "spec 030" .claude/rules/session-handoff.md` returns ≥ 1 hit; `grep -n "edited-files.txt" .claude/rules/session-handoff.md` returns ≥ 1 hit. Spec 023 cross-reference still present and labelled as fallback, not superseded.

- [ ] **Spec 030 status flip** — once the above all green, edit `docs/specs/030-session-edit-attribution/spec.md` `**Status:** draft` → `**Status:** shipped`. The spec dir survives as the historical record.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._
