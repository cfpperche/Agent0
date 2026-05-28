# 101 — session-handoff-multi-runtime — tasks

_Generated from `plan.md` on 2026-05-28. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Phase 0 — research-first (gates Phase C)

- [ ] 1. **Confirm the Codex SessionStart output contract + `stop_hook_active` semantics.** WebFetch https://developers.openai.com/codex/hooks; determine whether SessionStart additionalContext injection expects plain stdout or a JSON envelope, and confirm `stop_hook_active` is set on the 2nd-invocation continuation the way Claude sets it. Cross-check against `.agent0/hooks/memory-decay-readout.sh` (works on Codex per spec 099). Record the finding in `notes.md` § Design decisions. **Done when** the SessionStart Codex emit shape is decided and written into notes.md (this unblocks task 6).

### Phase A — port session-stop.sh (smallest delta)

- [ ] 2. **Port `session-stop.sh` to `.agent0/hooks/`.** Copy `.claude/hooks/session-stop.sh`; source `_memory-hook-lib.sh`; replace `PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"` with `PROJECT_DIR="$(memory_project_dir "$INPUT")"` (read `$INPUT` before the substitution); add a `stop_hook_active` read from the payload and treat `true` as equivalent to the `nagged` marker being set (early exit 0). Keep the existing `{"decision":"block","reason":...}` output verbatim. `chmod +x`. **Done when** `bash -n` parses clean AND `grep 'CLAUDE_PROJECT_DIR:-$PWD' .agent0/hooks/session-stop.sh` returns zero matches.

### Phase B — port session-track-edits.sh

- [ ] 3. **Port `session-track-edits.sh` to `.agent0/hooks/`.** Copy the source; source `_memory-hook-lib.sh`; `memory_project_dir` substitution; replace the `tool_input.file_path`-only extraction + `realpath` normalization with a loop over `memory_extract_paths "$INPUT" "$PROJECT_DIR"` (handles Claude `file_path` AND Codex `apply_patch` patch headers, already project-relative). Preserve the flock dedup-append into `edited-files.txt`. `chmod +x`. **Done when** `bash -n` parses AND a synthetic `apply_patch` payload produces the expected path line(s) in a temp `edited-files.txt`.
- [ ] 4. **Verify writer/reader path-shape match.** Confirm the path shape `memory_extract_paths` writes matches what `session-stop.sh`'s ` <path>` porcelain suffix-grep expects (plan § Risks). Hand-run: stage a tracked path, write it via the new tracker, run the ported stop hook, assert it detects own-WIP. **Done when** the round-trip attribution works for both a Claude `file_path` payload and a Codex `apply_patch` payload.

### Phase C — port session-start.sh (output-envelope branch + SESSION.md removal)

- [ ] 5. **Port `session-start.sh` to `.agent0/hooks/` — mechanical parts.** Copy source; source `_memory-hook-lib.sh`; `memory_project_dir` substitution; remove the legacy `.claude/SESSION.md` branch + `is_handoff_pointer_file` / `LEGACY_SESSION_FILE` / `HANDOFF_POINTER_MARKER` machinery, shrinking the fallback to 2-layer (HANDOFF.md → empty-advisory). Keep compact-history / runtime-introspect / githooks-activation blocks + the 7-day cleanup intact. `chmod +x`. **Done when** `bash -n` parses AND `grep -c 'LEGACY_SESSION_FILE\|AGENT0_HANDOFF_POINTER' .agent0/hooks/session-start.sh` returns 0.
- [ ] 6. **Add the runtime-branched output envelope** (depends on task 1). Branch the final emit on `memory_runtime "$INPUT"`: `claude-code` → existing JSON dual-channel (`hookSpecificOutput.additionalContext` + `systemMessage`); `codex-cli` → the shape decided in task 1 (plain framed stdout, or Codex JSON envelope). **Done when** a Claude-shape payload still produces the dual-channel JSON AND a Codex-shape payload produces the task-1 shape.

### Phase D — registrations + deletions

- [ ] 7. **Repoint `.claude/settings.json`** — SessionStart `session-start.sh`, Stop `session-stop.sh`, PostToolUse(Edit|Write|MultiEdit) `session-track-edits.sh` from `.claude/hooks/` to `.agent0/hooks/`. **Done when** `grep '.claude/hooks/session-start\|.claude/hooks/session-stop\|.claude/hooks/session-track-edits' .claude/settings.json` returns zero matches AND the JSON round-trips through `jq .`.
- [ ] 8. **Add three commented blocks to `.codex/config.toml.example`** — `[[hooks.SessionStart]]` (matcher `startup|resume|clear|compact`), `[[hooks.Stop]]` (NO `matcher` — Codex Stop matcher is unused), `[[hooks.PostToolUse]]` (matcher `^apply_patch$`), each resolving via `git rev-parse --show-toplevel`, paralleling the existing memory/readout blocks. **Done when** an uncommented temp copy parses via `python3 -c 'import tomllib; tomllib.loads(...)'`.
- [ ] 9. **Guard-check then delete `.claude/SESSION.md`.** Confirm its first non-blank line is `<!-- AGENT0_HANDOFF_POINTER -->` (pointer-only); if it carries live content, STOP and surface to the user. Otherwise `git rm` it. **Done when** the file is gone AND no remaining shipped file references `.claude/SESSION.md` except historical spec docs.
- [ ] 10. **Delete the three old hooks** — `git rm .claude/hooks/session-start.sh .claude/hooks/session-stop.sh .claude/hooks/session-track-edits.sh`. **Done when** the three paths no longer exist.

### Phase E — docs

- [ ] 11. **Update `.claude/rules/session-handoff.md`.** Rewrite § *Asymmetric enforcement* to the nag-once-parity multi-runtime shape (both runtimes nag via `{decision:block}` / continue-with-corrective-prompt; document `stop_hook_active`); shrink § *SessionStart fallback* from 3-layer to 2-layer; remove all `.claude/SESSION.md` references; update hook paths to `.agent0/hooks/`. **Done when** `grep -c 'SESSION.md\|3-layer' .claude/rules/session-handoff.md` returns 0 (or only intentional historical mentions).
- [ ] 12. **Update `.claude/rules/runtime-capabilities.md`.** `session handoff` row: Codex `convention` → `native-opt-in`; owner files → `.agent0/hooks/session-{start,stop,track-edits}.sh` + `.codex/config.toml.example`; update the Notes cell to the nag-once-parity framing. Shorten the line-45 re-audit note by removing `session handoff` (leaving `runtime introspect`, `delegation/subagents`). **Done when** the row shows `native-opt-in` in both columns AND the re-audit note no longer lists session handoff.

### Phase F — tests + validation

- [ ] 13. **Locate + preserve any existing session-hook tests.** Search `.claude/tests/` for suites exercising `session-start.sh` / `session-stop.sh` / `session-track-edits.sh`; repoint their `HOOK=` paths to `.agent0/hooks/`. **Done when** any pre-existing session-hook test passes against the new paths (or it's confirmed none exist).
- [ ] 14. **Create the 7 fixtures + runner** under `.claude/tests/session-handoff-multi-runtime/` per plan § Files to touch (01 SessionStart injection, 02 Stop nag-once via `stop_hook_active`, 03 apply_patch attribution, 04 subdir resolution, 05 TOML parse, 06 Claude regression, run-all.sh). `chmod +x`. **Done when** `bash .claude/tests/session-handoff-multi-runtime/run-all.sh` reports all PASS.
- [ ] 15. **Run the broader regression suites + sync-harness dry-run.** Execute `runtime-capabilities/run-all.sh`, `instruction-drift/run-all.sh`, `codex-mcp-recipes/run-all.sh`, `memory-multi-runtime/run-all.sh`, and `bash .claude/tools/sync-harness.sh --apply --dry-run` against a fixture consumer dir; `git diff --check`. **Done when** all pass AND the dry-run shows the three `.agent0/hooks/session-*.sh` files propagate.

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria._

- [ ] **Codex SessionStart injects HANDOFF.md** → fixture 01 (task 14)
- [ ] **Codex SessionStart from subdirectory resolves git root** → fixture 04 (task 14)
- [ ] **Codex Stop nags once via `stop_hook_active`** → fixture 02 (task 14) + task 2
- [ ] **Codex apply_patch edit attributed** → fixture 03 (task 14) + tasks 3-4
- [ ] **HANDOFF.md edits via Codex propagate to Claude** → byte-identical injection covered by fixtures 01 + 06
- [ ] **Existing Claude behavior preserved** → fixture 06 regression (task 14) + task 6
- [ ] **synthetic SessionStart + Stop fixtures pass without live Codex** → run-all.sh (task 14)
- [ ] **bounded shared-state contract works for both runtimes** → tasks 4 + 6 + fixtures 02/03
- [ ] **3 scripts exist/executable/source the lib; zero `CLAUDE_PROJECT_DIR:-$PWD`** → tasks 2/3/5 done-when greps
- [ ] **settings.json repointed; `.codex/config.toml.example` 3 blocks parse** → tasks 7 + 8
- [ ] **runtime-capabilities + session-handoff rules updated** → tasks 11 + 12
- [ ] **sync-harness propagates the three hooks** → task 15

## Notes

_Populate during execution: deviations, decisions surfaced, items deferred. Author each entry with runtime label + date (per `.claude/rules/spec-driven.md` § The four artifacts)._
