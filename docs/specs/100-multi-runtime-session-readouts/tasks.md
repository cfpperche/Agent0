# 100 — multi-runtime-session-readouts — tasks

_Generated from `plan.md` on 2026-05-27. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Phase A — pure-readout ports (reminders + routines)

- [x] 1. **Port `reminders-readout.sh` to `.agent0/hooks/`.** Copy `.claude/hooks/reminders-readout.sh` → `.agent0/hooks/reminders-readout.sh`; source `_memory-hook-lib.sh`; replace `PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"` with `PROJECT_DIR="$(memory_project_dir "$INPUT")"`; honor both `CLAUDE_SKIP_REMINDERS_READOUT` and `AGENT0_SKIP_REMINDERS_READOUT`; export `AGENT0_PROJECT_DIR` alongside `CLAUDE_PROJECT_DIR` on the helper call; emit `reminders-degraded-advisory:` to stderr when the PyYAML/yq tier ladder falls through to raw-YAML. `chmod +x`. **Done when** `grep '\${CLAUDE_PROJECT_DIR:-$PWD}' .agent0/hooks/reminders-readout.sh` returns zero matches AND `bash -n .agent0/hooks/reminders-readout.sh` parses clean.

- [x] 2. **Port `routines-readout.sh` to `.agent0/hooks/`.** Same shape as task 1 — source `_memory-hook-lib.sh`, `memory_project_dir` substitution, dual env vars (`CLAUDE_SKIP_ROUTINES_READOUT` + `AGENT0_SKIP_ROUTINES_READOUT`). No advisory line needed (no PyYAML dependency). `chmod +x`. **Done when** the new file passes `bash -n` AND `grep CLAUDE_PROJECT_DIR.*PWD` returns zero matches.

### Phase B — `mcp-recipes-hint.sh` port with runtime-aware wording

- [x] 3. **Port `mcp-recipes-hint.sh` to `.agent0/hooks/`.** Same substitutions as tasks 1-2: source `_memory-hook-lib.sh`, `memory_project_dir`, dual env vars (`CLAUDE_SKIP_MCP_RECIPES` + `AGENT0_SKIP_MCP_RECIPES`; `CLAUDE_MCP_RECIPES_WORKSPACE_DIRS` + `AGENT0_MCP_RECIPES_WORKSPACE_DIRS`). **One material change:** call `memory_runtime "$INPUT"` to detect runtime; if value is `codex-cli`, emit `Suggested MCP recipes (copy + uncomment from .codex/config.toml.example):` instead of `.mcp.json.example`. `chmod +x`. **Done when** the new file passes `bash -n`, contains both pointer strings (in conditional branches), AND `grep CLAUDE_PROJECT_DIR.*PWD` returns zero matches.

### Phase C — registrations + deletion of old paths

- [x] 4. **Update `.claude/settings.json`** — three `SessionStart.hooks[].command` entries repointed from `.claude/hooks/reminders-readout.sh` / `routines-readout.sh` / `mcp-recipes-hint.sh` to `.agent0/hooks/<same>.sh`. **Done when** `grep '.claude/hooks/reminders-readout\|.claude/hooks/routines-readout\|.claude/hooks/mcp-recipes-hint' .claude/settings.json` returns zero matches.

- [x] 5. **Add three commented `[[hooks.SessionStart]]` blocks to `.codex/config.toml.example`.** Match the shape of the existing `memory-decay-readout` block: `matcher = "startup|resume|clear|compact"`, `command = 'bash "$(git rev-parse --show-toplevel)/.agent0/hooks/<name>.sh"'`, `statusMessage = "<one-liner>"`. All three start commented (leading `#`). **Done when** the file has 4 distinct `[[hooks.SessionStart]]` matcher entries (1 existing + 3 new) AND a temp uncommented copy parses as valid TOML via `python3 -c "import tomllib; tomllib.loads(...)"`.

- [x] 6. **Delete the three old hook files at `.claude/hooks/`.** Remove `.claude/hooks/reminders-readout.sh`, `.claude/hooks/routines-readout.sh`, `.claude/hooks/mcp-recipes-hint.sh`. **Done when** `ls .claude/hooks/reminders-readout.sh .claude/hooks/routines-readout.sh .claude/hooks/mcp-recipes-hint.sh` fails with "No such file or directory" on all three.

### Phase D — documentation updates

- [x] 7. **Update `.claude/rules/mcp-recipes.md`.** § *How it works* — the bullet describing `mcp-recipes-hint.sh` as "Claude-only" becomes runtime-neutral wording ("fires on both Claude Code via `.claude/settings.json` and Codex CLI via `.codex/config.toml`"). § *Hint output shape* example block updates to show the runtime-aware install-pointer line. Keep the spec-lineage explanation in `notes.md` rather than shipping concrete Agent0 spec backlinks to consumer projects. **Done when** `grep -i 'only Claude receives\|Claude-only hint' .claude/rules/mcp-recipes.md` returns zero matches.

- [x] 8. **Update `.claude/rules/runtime-capabilities.md`.** Promote `mcp recipes` row to `native-opt-in` in the Codex column (with `.codex/config.toml.example` named in owner files). Add (or update) `reminders` and `routines` rows to `native-opt-in` for Codex. Shorten the re-audit-pending note on line 43 by removing the three closed rows from its scope (`session handoff`, `delegation/subagents`, `runtime introspect` remain). **Done when** the matrix rows for these three capacities show `native-opt-in` (or `native`) in both Claude and Codex columns AND the re-audit note no longer mentions them.

### Phase E — tests + dogfood

- [x] 9. **Create `.claude/tests/multi-runtime-readouts/01-reminders-fixture.sh`.** Synthetic SessionStart fixture: build a temp project dir with `.claude/reminders.yaml` containing ≥1 pending entry, pipe a JSON stdin payload (`{"hook_event_name":"SessionStart","source":"startup","cwd":"<temp>"}`) into `.agent0/hooks/reminders-readout.sh`, assert stdout contains `=== REMINDERS ===` and `=== end REMINDERS ===`; also mock no PyYAML/yq to assert the degraded advisory. `chmod +x`. **Done when** the script exits 0 against the fixture.

- [x] 10. **Create `.claude/tests/multi-runtime-readouts/02-routines-fixture.sh`.** Same shape: temp project with `.claude/.routines-state/<slug>/queue/<ts>.md`, drive the hook, assert `=== ROUTINES ===` framing. **Done when** the script exits 0.

- [x] 11. **Create `.claude/tests/multi-runtime-readouts/03-mcp-recipes-fixture.sh`.** Temp project with stack signal (e.g. `next.config.js` touched). Run the hook twice: once with Claude-style payload (`{"hook_event_name":"SessionStart","source":"startup","cwd":"<temp>"}` + `CLAUDE_PROJECT_DIR` env set), once with Codex-style SessionStart payload and `CLAUDE_PROJECT_DIR` unset. Assert: first run's output contains `.mcp.json.example`; second run's output contains `.codex/config.toml.example`. **Done when** the script exits 0 covering both runtimes.

- [x] 12. **Create `.claude/tests/multi-runtime-readouts/04-subdir-launch.sh`.** Temp project with `.claude/reminders.yaml`, `.claude/.routines-state/`, and `next.config.js` at root. Drive each of the three hooks with stdin payload `{"cwd": "<temp>/apps/web"}` (a nested subdir). Assert each emits its framed block, proving project-dir resolution walked back to the git root. **Done when** the script exits 0 for all three hooks.

- [x] 13. **Create `.claude/tests/multi-runtime-readouts/05-toml-parse.sh`.** Copy `.codex/config.toml.example` to a temp file; sed-strip leading `# ` from the four `[[hooks.SessionStart]]` blocks (memory-decay + 3 new); run `python3 -c "import tomllib; tomllib.loads(open('<temp>').read())"` and assert exit 0. **Done when** the script exits 0.

- [x] 14. **Run all 5 fixture tests locally and verify pass.** Execute `for t in .claude/tests/multi-runtime-readouts/*.sh; do bash "$t" || echo "FAIL: $t"; done`. **Done when** no `FAIL:` lines appear in stdout.

- [x] 15. **Dogfood: fresh Codex CLI session in this repo with hooks uncommented.** Copy `.codex/config.toml.example` → `.codex/config.toml`, uncomment the 3 new SessionStart blocks, start a fresh Codex session, verify the 3 framed blocks (`=== REMINDERS ===`, `=== ROUTINES ===`, `=== mcp-recipes ===`) appear in the preamble alongside `=== MEMORY DECAY ===`. Record outcome in `notes.md`. **Done when** the 3 blocks are observed in Codex preamble OR the missing block + reason is recorded in `notes.md`.

## Verification

_Maps each `spec.md` acceptance criterion to verifying tasks above._

- [x] **Scenario: Codex reminders readout fires at SessionStart** → verified by tasks 9 (fixture) + 15 (live dogfood)
- [x] **Scenario: Codex routines readout fires at SessionStart** → verified by tasks 10 + 15
- [x] **Scenario: Codex MCP-recipes hint fires at SessionStart** → verified by tasks 11 + 15
- [x] **Scenario: hook-disabled or pending-trust Codex session does not emit readouts** → verified by inspection: `.codex/config.toml.example` ships with blocks commented (task 5 done-when) AND no readout fires in a fresh session that hasn't copied to `.codex/config.toml`
- [x] **Scenario: existing Claude Code behavior is preserved post-port** → verified by Claude CC session starting normally after task 4 lands AND tasks 9-12 implicitly cover Claude-side invocation
- [x] **Scenario: Codex SessionStart fired from subdirectory launch** → verified by task 12
- [x] **Scenario: Codex reminders readout without PyYAML and without yq** → verified manually by invoking task 9's fixture in an env without PyYAML+yq (or by augmenting the fixture to mock-uninstall); assert `reminders-degraded-advisory:` appears on stderr AND raw-YAML content in stdout
- [x] **`.agent0/hooks/...` exist, executable, behaviorally-equivalent** → tasks 1-3 + tasks 9-11 + task 14
- [x] **Zero literal `$CLAUDE_PROJECT_DIR` references in moved scripts** → grep assertions inside tasks 1-3 done-when conditions
- [x] **`.claude/settings.json` SessionStart entries reference `.agent0/hooks/`** → task 4 done-when
- [x] **`.codex/config.toml.example` contains 3 commented SessionStart blocks** → task 5 done-when
- [x] **TOML parse validation** → task 13
- [x] **`.claude/rules/runtime-capabilities.md` updates** → task 8
- [x] **`.claude/rules/mcp-recipes.md` revises Claude-only line** → task 7
- [x] **Sync-harness propagates the 3 new paths via existing globs OR explicit entry; dry-run on fixture project** → verified by running `bash .claude/tools/sync-harness.sh --dry-run` against a fixture consumer dir after Phase A-D land; record observation in `notes.md`
- [x] **Synthetic SessionStart fixture produces expected framed block per hook** → tasks 9-12

## Notes

_Populate during execution: deviations from plan, unexpected outcomes, decisions that surfaced, items deferred to follow-up specs. Author each entry with the runtime label and date (per `.claude/rules/spec-driven.md` § *The four artifacts*)._
