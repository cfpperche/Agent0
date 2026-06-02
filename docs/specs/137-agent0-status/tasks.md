# 137 — agent0-status — tasks

_Generated from `plan.md` on 2026-06-02. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Layer 1 — extract shared composition lib (riskiest first)
- [x] 1. Add a characterization test under `.agent0/tests/agent0-status/` that captures `startup-brief.sh` output against a fixture/this repo BEFORE any refactor (golden snapshot).
- [x] 2. Create `.agent0/hooks/_brief-compose.sh` — move `section_body`, `helper_output`, `summarize_handoff_section`, `summarize_handoff`, `githooks_advisory`, `summarize_reminders`, `summarize_routines`, `summarize_memory_decay`, `context_pointer` out of `startup-brief.sh`. Source `_memory-hook-lib.sh` inside it. Keep functions emit-neutral (no JSON, no truncation).
- [x] 3. Refactor `.agent0/hooks/startup-brief.sh` to source `_brief-compose.sh`; keep `emit_context`, `trim_lines`, `trim_bytes`, `init_session_state`, `build_brief`, `hook_event` local. Re-run the characterization test — output MUST be byte-identical.

### Layer 2 — the two tools
- [x] 4. Create `.agent0/tools/status.sh` — resolve repo root (git rev-parse, BASH_SOURCE fallback), source the lib, print full untruncated handoff + reminders + routines + decay, plus a git-dirty block (`git status --porcelain`) and a heuristic "next commands" block (handoff Next Actions + pending routines + due-reminder count, or "(nothing queued)"). Always exit 0. Clean "(missing)"/"(none)" markers on a partial harness.
- [x] 5. Create `.agent0/tools/doctor.sh` — checks: required harness files exist+executable; hook wiring present in `.claude/settings.json` AND `.codex/hooks.json`; `core.hooksPath` activation; required binaries (`jq`, `python3`) vs optional (`gitleaks`, `osv-scanner`). Tri-state per check (`ok`/`advisory`/`broken`), final rollup line, exit non-zero only on a `broken` check (optional-binary absence = `advisory`, exit 0).

### Layer 3 — surface + register (multi-runtime)
- [x] 6. Create `.agent0/skills/status/SKILL.md` — thin portable skill: invokes `.agent0/tools/status.sh`, relays output, zero composition logic. Frontmatter agentskills.io-compliant (validate with `/skill validate status`).
- [x] 7. Create discovery symlinks `.claude/skills/status` → `../../.agent0/skills/status` and `.agents/skills/status` → `../../.agent0/skills/status`.
- [x] 8. Create `.agent0/context/rules/agent0-status.md` — capability rule: what status/doctor are, when to run, multi-runtime invocation (`/status`, `$status`, `! bash .agent0/tools/<tool>.sh`), anti-drift scope (no daemon/browser/new state).
- [x] 9. Add a `host status / doctor` row to `.agent0/context/rules/runtime-capabilities.md` (Claude `native` / Codex `native-opt-in`, owner files, notes).
- [x] 10. Add a managed-block index entry (`## Status & doctor`) to `CLAUDE.md` and mirror it in `AGENTS.md`.
- [x] 11. Register new tracked files in `.agent0/harness-sync-baseline.json` per the sync mechanism (verify how vuln-audit/video registered theirs; follow that).

## Verification

- [x] V1. `bash .agent0/tools/status.sh` prints full untruncated work state with all sections (maps to spec Scenario "renders full work state on demand").
- [x] V2. Characterization test green: `startup-brief.sh` output byte-identical pre/post refactor (maps to "reuses the brief composition, not a fork").
- [x] V3. `_brief-compose.sh` contains no `emit_context`/`trim_*`/JSON — grep-asserted (maps to "library is runtime-emit-neutral").
- [x] V4. `bash .agent0/tools/doctor.sh` prints tri-state checks + rollup; exits non-zero with a forced `broken`, zero with only advisories (maps to "tri-state verdict" + "exit code reflects severity").
- [x] V5. Partial-harness test: status.sh on a repo with no HANDOFF/reminders prints "(missing)"/"(none)" and exits 0 (maps to "degrade cleanly").
- [x] V6. `/skill validate status` passes; both symlinks resolve to the canonical SKILL.md (maps to "thin, portable skill" + "discoverable from both runtimes").
- [x] V7. Post-edit validator clean (shellcheck/lint advisories addressed) on all new shell.

## Notes

_Populated during execution._
