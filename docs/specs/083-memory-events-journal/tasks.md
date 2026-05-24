# 083 — memory-events-journal — tasks

_Generated from `plan.md` on 2026-05-24. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Phase A — projection tool (no dependencies; standalone-testable)

- [x] 1. Create `.claude/tools/memory-project.sh` with `set -uo pipefail` + `LC_ALL=C` at top; reuse 082's `awk`-between-`---` frontmatter extractor pattern. Reads each `.claude/memory/*.md` excluding `MEMORY.md`, pulls `name` + `description`, emits one bullet per entry sorted by filename slug. `chmod +x`.

- [x] 2. Dogfood the projection against current 13 entries: run `bash .claude/tools/memory-project.sh` and `diff` the result against the currently-committed `.claude/memory/MEMORY.md`. Expected: zero diff (within whitespace tolerance). If diff is non-trivial, the projection's bullet shape doesn't match the hand-maintained file — either fix the script to match, or accept a one-line `MEMORY.md` re-formatting in the implementation commit (note the choice in `notes.md`).

- [x] 3. Verify determinism: run the projection twice in succession against the unchanged corpus — `diff` between the two outputs MUST be empty.

### Phase B — raw-edit gate (PreToolUse)

- [x] 4. Create `.claude/hooks/memory-index-gate.sh` modeled on `delegation-gate.sh`: `set -uo pipefail`, jq-as-hard-dep (fail-closed exit 2 with install hint), extract `tool_input.file_path` from stdin. Scope: only fire when path is `.claude/memory/MEMORY.md`. Grep the full `tool_input` JSON serialization for `^[[:space:]]*# OVERRIDE: memory-index-edit: ` (start-of-line anchor + the `memory-index-edit:` prefix). If marker missing → exit 2 with canonical template instructing edit-the-entry-instead. If marker present and reason ≥10 chars → append a `manual-edit` event to `.claude/.memory-events.jsonl` (carries the reason), exit 0. If reason <10 chars → exit 2 with too-short hint matching `delegation-gate.sh`. `chmod +x`.

- [x] 5. Register the gate in `.claude/settings.json` `PreToolUse[]` with matcher `Edit|Write|MultiEdit` invoking `memory-index-gate.sh`. Place as the last entry of the array (after `delegation-gate.sh` Agent matcher) — order doesn't matter for non-overlapping matchers but appended-at-end is the convention.

### Phase C — event journal (PostToolUse)

- [x] 6. Create `.claude/hooks/memory-events-journal.sh` modeled on `memory-frontmatter-validate.sh` (same path-scoping + skip-MEMORY.md logic). Extract `tool_name`, `session_id`, `tool_use_id`, `agent_id`, `agent_type`, `tool_input.file_path` from stdin. Compute `entry_id = basename(file_path, '.md')`. Determine `event_type`: search journal with `jq -c 'select(.entry_id == "<id>" and .event_type == "add")'` — if any hit → `update`, else → `add`. Compute `actor`: `agent_type` if present, else `"parent"`. Build JSONL line via `jq -c -n` (matches `delegation-gate.sh` pattern), append to `.claude/.memory-events.jsonl`. Then invoke `bash .claude/tools/memory-project.sh` to regenerate `MEMORY.md`. Fail-open on any step — emit one `memory-journal-advisory: <reason>` to stderr, exit 0. `chmod +x`.

- [x] 7. Add one-time "journal empty; run backfill" advisory: at the top of `memory-events-journal.sh`, if `.claude/.memory-events.jsonl` doesn't exist yet, emit `memory-journal-advisory: journal empty; run bash .claude/tools/memory-backfill.sh to seed history` to stderr BEFORE writing the first line. Self-mitigates the add-vs-update edge case named in `plan.md` § Risks.

- [x] 8. Register the journal hook in `.claude/settings.json` `PostToolUse[]` with matcher `Edit|Write|MultiEdit`, placed AFTER `memory-frontmatter-validate.sh` (so any 082-schema advisory fires first in stderr order).

### Phase D — backfill (optional but ship per OQ-1)

- [x] 9. Create `.claude/tools/memory-backfill.sh`: iterate `.claude/memory/*.md` excluding `MEMORY.md`. For each, check if journal contains an `add` event for that `entry_id`; if yes, skip. Else append one `add` event with `ts` from `git log --reverse --format=%aI -- <file> | head -1` (fallback to `stat`-based mtime if file is untracked), `actor: "backfill"`, `tool: null`. Print one-line summary at end. `chmod +x`. Verify idempotency by running it twice — second invocation reports `backfilled 0 entries (13 already present)`.

### Phase E — gitignore + rule docs

- [x] 10. Add `.claude/.memory-events.jsonl` to `.gitignore` (alphabetize within its section; sibling to existing `.claude/delegation-audit.jsonl` and `.claude/.runtime-state/`).

- [x] 11. Update `.claude/rules/memory-placement.md`: add `## Event journal` section after `## Frontmatter schema`. Document: the 5 event types (`add` / `update` / `delete` / `rename` / `manual-edit`) and shape; the projection contract (MEMORY.md is derived, not hand-maintained); the gate semantics + canonical template; the `# OVERRIDE: memory-index-edit: <reason ≥10 chars>` grammar with the HTML-comment / inline-line marker location convention; the per-machine gitignore decision; the git-direct-edit opt-out documented in spec OQ-5; cross-reference to `cc-platform-hooks.md` (hook event semantics) and `delegation-audit.jsonl` shape (audit log conventions mirrored).

### Phase F — umbrella consistency

- [x] 12. Update `docs/specs/080-memory-system-scale-ready/spec.md` OQ-5: keep original text intact, append a one-line `**RESOLVED 2026-05-24 by 083:** journal is gitignored per-machine; backfill lives in `memory-backfill.sh` (per-machine one-shot), not a git history commit. See docs/specs/083-memory-events-journal/spec.md § Non-goals.`

## Verification

_Each line maps to one or more scenarios in `spec.md` § Acceptance criteria._

- [x] V1. **Scenario "editing an entry appends one event and regenerates the index"** — in a fresh session (so the new hooks register), edit one existing `.claude/memory/*.md` (e.g. tweak a description); verify `.claude/.memory-events.jsonl` gained exactly one new line with `event_type: "update"`, correct `entry_id`, `actor: "parent"`, ISO-8601 `ts`, `tool: "Edit"`; verify `MEMORY.md` reflects the new description.

- [x] V2. **Scenario "creating a new entry emits an add event"** — `Write` a throwaway `.claude/memory/_test-add.md` with valid frontmatter; verify the journal line carries `event_type: "add"`, `entry_id: "_test-add"`; verify the bullet appears in `MEMORY.md`. Clean up by deleting the file and running `bash .claude/tools/memory-project.sh` manually (delete is out of scope for v1 per spec Non-goal — the manual reproject is the expected flow).

- [x] V3. **Scenario "raw edit to MEMORY.md is blocked without override"** — attempt an `Edit` directly on `.claude/memory/MEMORY.md` with no override marker in the tool input; verify the hook exits 2 with the canonical template; verify the edit does NOT proceed (file content unchanged on disk).

- [x] V4. **Scenario "raw edit to MEMORY.md proceeds with override marker"** — repeat V3 with `# OVERRIDE: memory-index-edit: manual cleanup pass` in the edit content; verify the hook exits 0; verify the edit proceeds; verify the journal gained a `manual-edit` event carrying the reason.

- [x] V5. **Scenario "edit by a sub-agent records actor as the sub-agent type"** — dispatch a minimal `Agent` call (e.g. `general-purpose`) that edits one memory file via its DELIVERABLE; verify the journal line for that edit has `actor: "general-purpose"` (NOT `"parent"`); verify `session_id` and `tool_use_id` are populated for cross-correlation with `delegation-audit.jsonl`.

- [x] V6. **Scenario "projection is deterministic and idempotent"** — run `bash .claude/tools/memory-project.sh` twice in succession; `diff` between the two runs MUST be empty. Optional second-machine check: clone fresh + re-run, compare to leader output byte-for-byte (deferred unless dogfood actually has a second machine).

- [x] V7. **Scenario "backfill is per-machine and one-shot"** — delete `.claude/.memory-events.jsonl`, run `bash .claude/tools/memory-backfill.sh`, verify 13 `add` events appear with `actor: "backfill"`. Run a second time, verify `backfilled 0 entries (13 already present)`.

- [x] V8. **Scenario "hook never blocks on its own bug"** — temporarily make `.claude/.memory-events.jsonl` unwritable (`chmod -w`), edit any memory file, verify the hook emits `memory-journal-advisory:` to stderr but exits 0 (the edit is NOT reverted). Restore writability after.

- [x] V9. **Static check** — all 13 existing entries continue to pass 082's `memory-frontmatter-validate.sh` (no new advisories fire during the implementation diff).

- [x] V10. **Static check** — `.gitignore` carries the new line; `git status` shows `.claude/.memory-events.jsonl` as untracked-and-ignored (does NOT appear in `git status`).

- [x] V11. **Static check** — `.claude/rules/memory-placement.md` has `## Event journal` section; the section explicitly mentions the OQ-5 override decision and points at this spec.

- [x] V12. **Static check** — `docs/specs/080-memory-system-scale-ready/spec.md` OQ-5 carries the `**RESOLVED 2026-05-24 by 083:**` annotation.

## Notes

- **Mid-session activation gotcha** — per `compaction-continuity.md` § Gotchas: settings.json changes register on the NEXT session start. End-to-end V1/V3/V4/V5 verification requires committing the change and opening a fresh session. Implementation can complete and pass V2/V6/V7/V8/V9/V10/V11/V12 in-session (those don't depend on the hooks firing); V1/V3/V4/V5 are documented as "needs fresh session boot" and either deferred to next session OR verified by Carlos manually after commit. Same gotcha 082 hit; behavior identical.

- **Override marker location convention** — document in the rule that the marker lives as either `<!-- OVERRIDE: memory-index-edit: <reason> -->` HTML comment inside `MEMORY.md` content, or as a `# OVERRIDE: memory-index-edit:` line that the agent removes in a follow-up edit. The marker persists only until next projection run wipes the file clean.

- **Hook re-registration of memory-frontmatter-validate.sh order** — current settings.json has `memory-frontmatter-validate.sh` as the 5th PostToolUse(Edit|Write|MultiEdit) entry. New journal hook appended as the 6th. Stderr order: schema advisory → journal record → next agent turn sees both. If readability suggests swapping order, decide in implementation and note here.
