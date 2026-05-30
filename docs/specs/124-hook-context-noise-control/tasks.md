# 124 — hook-context-noise-control — tasks

_Generated from `plan.md` on 2026-05-30. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. Create `.agent0/hooks/startup-brief.sh` with session-state side effects, compact handoff, due/top-N reminders, actionable routines, non-empty memory decay, githooks advisory, and final byte/line caps.
- [x] 2. Replace the five model-visible `SessionStart` registrations in `.codex/hooks.json` and `.claude/settings.json` with one `startup-brief.sh` registration while keeping `UserPromptSubmit` on `context-inject.sh`.
- [x] 3. Refactor `.agent0/hooks/context-inject.sh` so prompt-time output uses capsules/pointers, caps selected fragments, supports explicit diagnostic index mode, and sanitizes pasted/generated blocks before matching.
- [x] 4. Update direct context-injection tests for the new startup pointer/diagnostic mode and lightweight prompt capsules.
- [x] 5. Add regression tests for aggregate startup budget, pasted hook output sanitization, and diagnostic full-index mode.
- [x] 6. Update hook-registration and harness-sync tests that currently expect separate startup readout registrations.
- [x] 7. Update relevant context-rule docs to describe `startup-brief.sh` as the registered startup surface and the older scripts as helpers.
- [x] 8. Correct `.agent0/skills/vuln-audit/SKILL.md` metadata to `agentskills-portable`.
- [x] 9. Update this spec's `spec.md`, `tasks.md`, and `notes.md` with implementation decisions, completed acceptance criteria, and validation evidence.

## Verification

- [x] V1. `bash .agent0/tests/context-injection/run-all.sh`
- [x] V2. `bash .agent0/tests/multi-runtime-readouts/05-hooks-json-parse.sh`
- [x] V3. `bash .agent0/tests/session-handoff-multi-runtime/run-all.sh`
- [x] V4. `bash .agent0/tests/harness-sync/35-codex-config-example-untouched.sh`
- [x] V5. `jq empty .codex/hooks.json .claude/settings.json`
- [x] V6. Synthetic startup probe proves `.agent0/hooks/startup-brief.sh` emits one block under 6,000 bytes and 80 lines.
- [x] V7. Synthetic prompt probe proves broad/pasted hook output stays capped and does not select every context fragment.
- [x] V8. Symlink views show `vuln-audit` metadata corrected in `.agent0/skills/`, `.claude/skills/`, and `.agents/skills/`.
- [x] V9. Final response includes copy-pasteable Claude and Codex validation instructions for live runtime dogfood.

## Notes

Validation evidence is recorded in `spec.md` and implementation decisions are recorded in `notes.md`.
