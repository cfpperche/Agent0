# 175 - project-core-local-renderer - plan

_Drafted from `spec.md` on 2026-06-08. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Extract the project-core mirror operation into a first-class local tool: `.agent0/tools/project-core-sync.sh`. The tool reads only the current checkout, treats `.agent0/project-core.md` as source, and rewrites the `AGENT0:PROJECT` regions in `CLAUDE.md` and `AGENTS.md` as derived output. It has `--check` and `--apply` modes, defaulting to check, and it does not require or accept an Agent0 upstream path.

Register the local renderer as a PostToolUse edit hook for Claude and Codex so ordinary agent edits to `.agent0/project-core.md` are followed by mirror refresh. Keep it quiet on no-op to avoid hook noise.

Change `sync-harness.sh` to call the local renderer after upstream-managed entrypoint sync instead of carrying independent project-core merge logic. Sync remains an upstream operation, but project-core rendering is local behavior. Update doctor/status/bootstrap/drift docs and tests to point at the local renderer.

## Files to touch

**Create:**
- `.agent0/tools/project-core-sync.sh` - local source-to-entrypoint renderer.
- `.agent0/tests/project-core-sync/run-all.sh` - focused local renderer and hook-registration tests.

**Modify:**
- `.claude/settings.json` - add PostToolUse renderer hook for Edit/Write/MultiEdit.
- `.codex/hooks.json` - add PostToolUse renderer hook for apply_patch.
- `.agent0/tools/sync-harness.sh` - delegate project-core rendering to the local tool.
- `.agent0/tools/check-instruction-drift.sh` - point remediation at the local renderer.
- `.agent0/tools/doctor.sh` - validate renderer presence and mirror drift.
- `.agent0/hooks/_brief-compose.sh` - bootstrap text points to local renderer.
- `.agent0/context/rules/{harness-sync,language,agent0-status,runtime-capabilities}.md` - document the local renderer and hook behavior.
- `.agent0/tests/harness-sync/37-project-core-mirror.sh` - update expectations from baseline-owned region merge to derived local render.
- `.agent0/tests/bootstrap-advisory/run-all.sh` - update advisory text and fixture core files.
- `.agent0/HANDOFF.md` - record the design correction.

**Delete:**
- None.

## Alternatives considered

### Keep rendering inside `sync-harness.sh`

Rejected. It keeps a consumer-local derived output coupled to an upstream sync command and requires `--agent0-path` for a same-repo source edit.

### Use only `check-instruction-drift.sh`

Rejected. It detects the problem but still leaves agents or operators to remember the right repair command. The mirror is derived output and should be regenerated automatically when hooks can do so.

### Add a filesystem watcher

Rejected. A daemon is too much operational surface for a two-file mirror. Post-edit hooks plus an explicit local tool cover the normal agent workflow without long-running state.

## Risks and unknowns

- Runtime entrypoint instructions may be loaded before a SessionStart hook runs, so this does not guarantee same-session instruction reload after a manual out-of-band edit. It does keep the repo files correct for subsequent turns/sessions and for hook-mediated agent edits.
- Bash or external editor writes are not intercepted by the edit PostToolUse hook. `project-core-sync.sh --check` and `doctor.sh` expose drift, and the explicit `--apply` command repairs it.
- Sync local-only mode must not write tracked entrypoints through the delegated renderer.

## Research / citations

- `.agent0/tools/sync-harness.sh` - current project-core mirror implementation.
- `.agent0/tools/lib/managed-block.sh` - marker detection/extraction helpers.
- `.claude/settings.json` / `.codex/hooks.json` - existing PostToolUse edit hook patterns.
- `.agent0/context/rules/harness-sync.md` - current source/mirror contract.
