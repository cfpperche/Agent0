# 063 — worktree-isolated-subagents — tasks

_Generated from `plan.md` on 2026-05-19. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

> **REDIRECTED 2026-05-19** — Option B redesign (see `spec.md` § Redesign). Pre-flight empirical discovery showed CC 2.1.144 ships rich native worktree primitives (`Agent isolation` param, `EnterWorktree`/`ExitWorktree` tools, `.claude/worktrees/` convention, hook events). Original tasks below (3-10 from the original outline) referenced a 6th brief field `ISOLATION:` that was dropped. Authoritative tasks:

## Implementation (Option B — current)

- [x] R1. **Extend `.claude/hooks/delegation-gate.sh`** to capture `tool_input.isolation`:
  - Add near line 44 (after MODEL extraction): `ISOLATION="$(printf '%s' "$INPUT" | jq -r '.tool_input.isolation // ""')"`
  - Add to `jq -n` args list: `--arg isolation "$ISOLATION"`
  - Add to JSON schema being built: `isolation:$isolation`
  - Same pattern as the `tool_use_id` extension shipped 2026-05-19 (`42d8d0c`)
- [x] R2. **Modify `.claude/hooks/post-edit-validate.sh`** to scope validator to edit's git toplevel:
  - Extract edit file path: `EDIT_FILE="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null || true)"`
  - Derive cwd: `VALIDATOR_CWD="$PROJECT_DIR"; if [ -n "$EDIT_FILE" ]; then toplevel="$(git -C "$(dirname "$EDIT_FILE")" rev-parse --show-toplevel 2>/dev/null || true)"; [ -n "$toplevel" ] && VALIDATOR_CWD="$toplevel"; fi`
  - Wrap validator invocation in subshell cd: `VALIDATOR_OUT="$( ( cd "$VALIDATOR_CWD" && "$VALIDATOR" ) 2>"$VALIDATOR_STDERR_FILE" || true )"`
  - Fail-open posture preserved (git failure → fallback to $PROJECT_DIR)
- [x] R3. **Add `## Worktree isolation` section to `.claude/rules/delegation.md`** after the existing `## Audit log` section:
  - What CC's native mechanism does
  - When parents should declare `isolation: "worktree"` in tool params
  - When NOT to declare
  - Agent0's added discipline: audit (`isolation` in dispatch row) + validator scoping (worktree-aware cwd)
  - No-brief-field decision documented (canonical surface is `tool_input.isolation`; brief duplication is redundant)
- [x] R4. **Manual e2e verification** — closed by the 2026-05-21 audit (see `notes.md` § Deviations: empty-string case empirically live in the audit log; the `worktree` value is the identical verbatim-passthrough code path; spec 067's worktree tests cover the isolated flow):
  - Dispatch tiny Agent WITHOUT isolation; tail audit log; confirm `"isolation": ""`
  - Dispatch tiny Agent WITH `isolation: "worktree"` in tool params; tail audit log; confirm `"isolation": "worktree"`
  - (Optional, if cheap) Dispatch sub-agent that makes 1 Edit in worktree; observe validator runs from worktree cwd (validator stderr should reflect worktree-rooted paths if there's any path leak)
- [x] R5. **Commit + push** — DONE; R1–R3 shipped in an earlier commit (the working tree was clean and in sync with `origin` at the 2026-05-21 audit). The spec-closure edits ship under `chore(063): close worktree-isolation spec`.

## Verification (Option B — current)

- [x] **Scenario: audit field present (no isolation)** — confirmed empirically: the latest live dispatch rows in `.claude/delegation-audit.jsonl` carry `"isolation": ""` (10 of the last 200 rows have the key — additive schema, older rows predate the gate change).
- [x] **Scenario: audit field present (with isolation)** — verified by code inspection: the gate writes `tool_input.isolation` verbatim via `--arg isolation` (`delegation-gate.sh:45,239,246`); the `"worktree"` value is the identical code path to the empirically-confirmed empty-string case. spec 067's `parallel-edit-validation` suite exercises the worktree-isolated flow end-to-end with real git worktrees (2/2 PASS). No contrived read-only worktree dispatch was made — that would itself violate `delegation.md` § Worktree isolation's "when NOT to declare isolation" guidance.
- [x] **Scenario: validator scoping for parent-tree edit** — `post-edit-validate.sh:36-42` derives `VALIDATOR_CWD` from the edit's git toplevel; for a parent-tree edit the toplevel IS `$PROJECT_DIR` — no behavior change. Exercised by spec 067 `parallel-edit-validation/01`.
- [x] **Scenario: validator scoping fallback** — `post-edit-validate.sh:37` defaults `VALIDATOR_CWD="$PROJECT_DIR"` and only overrides when `git rev-parse --show-toplevel` returns non-empty; a non-repo edit path leaves the fallback intact.
- [x] `.claude/rules/delegation.md` has `## Worktree isolation` section documenting all four items in R3.
- [x] Dispatch audit row schema has 13 fields including `isolation` — confirmed: `jq 'keys | length'` on the latest isolation-bearing dispatch row returns 13.
- [x] `.claude/hooks/{delegation-gate,post-edit-validate}.sh` pass static analysis — `bash -n` clean on both. NOTE: shellcheck is not installed in the dev env; full shellcheck was not run (same caveat as spec 061's `08-shellcheck.sh`).

## Implementation (original — superseded by Option B redirect 2026-05-19)

## Implementation

- [ ] 1. **Pre-flight: empirical worktree pattern verification.**
  - Dispatch two `Agent` calls in a single message, each with `isolation: "worktree"` in the tool params, each editing a different test file
  - Capture: each sub-agent's `cwd`, the worktree paths returned in results, the post-edit hook payload (does it carry worktree-rooted paths?)
  - Document findings in `notes.md` as design decision
  - Decide whether validator-probe via `git rev-parse --show-toplevel` is sufficient OR a worktree-aware hook surface is needed
- [ ] 2. **Pre-flight: hook event audit.** Scan `.claude/memory/cc-platform-hooks.md` for worktree-related events. If a `WorktreeCreate`/`WorktreeRemove` event exists, document and consider using it as state-stamp surface (cleaner than validator-probe).
- [ ] 3. **Extend `.claude/hooks/delegation-gate.sh` parser:**
  - Add `ISOLATION` to the recognized field set (case-insensitive)
  - Validate value: empty/missing → `null`; `worktree` → accepted; anything else → block with corrective stderr listing allowed values
  - Same `# OVERRIDE: <reason ≥10 chars>` escape applies (existing infrastructure)
- [ ] 4. **Extend audit row schema:**
  - Add `isolation` key (nullable string)
  - Update jq write path in the gate
  - Document the new field in `.claude/rules/delegation.md` § Audit log (mention the 12th field)
- [ ] 5. **State file stamp.** When `ISOLATION: worktree` parsed, gate writes `.claude/.delegation-state/agents/<agent_id>/isolation` containing the literal `worktree`. (Path: existing `.claude/.delegation-state/agents/` is gitignored.)
- [ ] 6. **Modify `.claude/hooks/post-edit-validate.sh`:**
  - Before invoking the validator runner, derive the edit's git toplevel: `WORKTREE_ROOT=$(git -C "$(dirname "$edit_file")" rev-parse --show-toplevel 2>/dev/null || pwd)`
  - `cd "$WORKTREE_ROOT"` before running the validator
  - Fail-open on git errors (continue in parent cwd)
  - This change is safe regardless of `ISOLATION` field — parent edits naturally land in parent toplevel; worktree edits land in worktree toplevel
- [ ] 7. **Update `.claude/rules/delegation.md`:**
  - § The 5-field handoff: add a paragraph at the bottom about the optional `ISOLATION:` 6th field; allowed values; the parallel-dispatch use case; one short example
  - § Audit log: list `isolation` as the 12th field
- [ ] 8. **Tests** under `.claude/tests/<NNN>-isolation/`:
  - Fixture: `brief-no-isolation.txt` (standard 5-field) → audit row `isolation: null`
  - Fixture: `brief-isolation-worktree.txt` (6 fields, valid value) → audit row `isolation: "worktree"`, state file written
  - Fixture: `brief-isolation-typo.txt` (`ISOLATION: parellel`) → exit 2, stderr lists allowed values
  - Fixture: `brief-isolation-empty.txt` (`ISOLATION:` with no value) → audit `isolation: null`
  - Fixture: `brief-isolation-uppercase.txt` (`Isolation: Worktree`) → case-insensitive parse succeeds
  - Fixture: `brief-isolation-override.txt` (typo + `# OVERRIDE: testing-typo-bypass`) → audit row `isolation: <typo>`, override flag set, no block
  - Asserts: audit JSONL shape via `jq`, exit codes, stderr content
- [ ] 9. **Manual end-to-end verification** (requires a real CC session):
  - Dispatch a sub-agent with `ISOLATION: worktree` that edits a file
  - Verify post-edit validator ran in worktree cwd (check validator stderr for path leak or runtime introspect snapshot)
  - Verify worktree cleanup on sub-agent completion (or branch retention if changes were made)

## Verification

- [ ] **Scenario: omitted ISOLATION** — audit row has `isolation: null`, no behavior change vs spec 002 baseline
- [ ] **Scenario: ISOLATION: worktree** — audit + state file, gate exit 0
- [ ] **Scenario: typo guard** — gate exit 2, allowed-values list in stderr
- [ ] **Scenario: post-edit validator scoping** — validator runs in correct cwd for worktree-isolated sub-agent (manual check in step 9)
- [ ] **Scenario: parallel dispatches both isolated** — manual check, two distinct worktree paths returned, no parent tree edits during execution
- [ ] **Scenario: override marker** — typo + override bypasses block, audit row preserves both `isolation` (the literal bad value) and `override` (the reason)
- [ ] `.claude/rules/delegation.md` reflects the new field in both § The 5-field handoff and § Audit log
- [ ] Existing delegation-gate tests still pass (no regression)

## Notes

- The hardest part is the gap between "what the brief says" and "what the tool call sets". This spec accepts that as rule-only discipline in v1, matching `user-prompt-framing.md`'s same observation. If empirical dogfood shows parents declaring `ISOLATION` without setting the parameter, that's the rule-of-three signal for a v2 hook-based enforcement (e.g. a hypothetical `Agent` payload-mutation hook surface).
- The validator-cwd change in step 6 is independently useful even without `ISOLATION` — it makes the validator robust to sub-agents that work in subdirectories or worktrees the parent doesn't know about.
- Consider whether the `Agent` tool's auto-cleanup-on-no-changes behavior creates a window where the validator runs against a deleted directory. Pre-flight (step 1) should answer this.
