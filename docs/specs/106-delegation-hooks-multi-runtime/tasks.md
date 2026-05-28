# 106 — delegation-hooks-multi-runtime — tasks

_Generated from `plan.md` on 2026-05-28. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. **`delegation.md` § Codex: convention-only** — add a section stating the Codex orchestrator self-applies the 5-field handoff (no hook enforces; verified no blocking surface), precedent `user-prompt-framing.md`.
- [x] 2. **`delegation.md` § Audit log** — update path `.claude/` → `.agent0/delegation-audit.jsonl`; document the new `schema_version`/`runtime`/`event` fields, the Codex `subagent-start` row shape (`brief_observable:false`/`formatted:null`), the `agent_id-direct` correlation value; repoint the 4 jq query examples.
- [x] 3. **`delegation-gate.sh`** — `AUDIT_LOG` → `.agent0/delegation-audit.jsonl`; dispatch row gains `schema_version:1`, `runtime:"claude-code"`, `event:"dispatch"`. `bash -n`.
- [x] 4. **Move `delegation-stop.sh` → `.agent0/hooks/`** as a shared multi-runner: branch Claude (existing sidecar/transcript/loop-budget logic) vs Codex (`agent_id-direct` correlation to the start row, `exit:null`, `edit_count:null`, no sidecar). Add `schema_version`/`runtime`/`event:"subagent-stop"`. Write `.agent0/delegation-audit.jsonl`. `bash -n`. Delete old `.claude/hooks/delegation-stop.sh`.
- [x] 5. **Create `.agent0/hooks/delegation-start-audit.sh`** (Codex `SubagentStart`) — non-blocking; append a `subagent-start` row keyed by `agent_id`/`agent_type` with `brief_observable:false`, `formatted:null`, `runtime:"codex-cli"`, `event:"subagent-start"`, `schema_version:1`. Fail-open everywhere. `chmod +x`. `bash -n`.
- [x] 6. **Register hooks** — `settings.json` SubagentStop → `.agent0/hooks/delegation-stop.sh`; `.codex/config.toml.example` add commented `[[hooks.SubagentStart]]`→`delegation-start-audit.sh` and `[[hooks.SubagentStop]]`→`delegation-stop.sh`. Validate `settings.json` round-trips through `jq`.
- [x] 7. **Hard-cutover purge** — repoint every `.claude/delegation-audit.jsonl` reference to `.agent0/`: `image-gen.md`, `memory-placement.md` (×2), `harness-sync.md`, `.gitignore` (+`.lock`). Delete the live `.claude/delegation-audit.jsonl` + `.lock`.
- [x] 8. **`runtime-capabilities.md`** — `delegation/subagents` Codex cell `unsupported` → `native-opt-in`; rewrite Notes to the agreed wording; update owner files (add `.agent0/hooks/delegation-start-audit.sh`, `.agent0/hooks/delegation-stop.sh`, `.agent0/delegation-audit.jsonl`; drop `.claude/delegation-audit.jsonl`); trim the re-audit note's `delegation/subagents` clause.
- [x] 9. **Tests** — repoint audit path in `061-delegation-stop/0{1..7}-*.sh` to `$TMP/.agent0/`; update `08-shellcheck.sh` STOP_HOOK path + add `delegation-start-audit.sh`; add `10-codex-branch.sh` (Codex SubagentStop close row → `agent_id-direct`/`exit:null` + start-audit row shape).

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria._

- [x] **Scenario: Claude gate unchanged** — feed `delegation-gate.sh` a prompt missing a field → exit 2 + canonical template (no regression).
- [x] **Scenario: single canonical audit log** — `delegation-gate.sh` + `delegation-stop.sh` write only `$TMP/.agent0/delegation-audit.jsonl`; rows carry `runtime`+`event`+`schema_version`.
- [x] **Scenario: Codex SubagentStart observability-only** — `delegation-start-audit.sh` on a Codex payload appends a row with `brief_observable:false`, `formatted:null`, `runtime:"codex-cli"`.
- [x] **Scenario: subagent-stop runtime-neutral (3-tier)** — Codex SubagentStop close row uses `agent_id-direct` correlation when a start row exists, else `unmatched`; `edit_count:null`, `exit:null`.
- [x] **`.claude/delegation-audit.jsonl` removed** — `grep -rn '\.claude/delegation-audit\.jsonl'` over the repo returns zero hits (excluding spec/debate/git history); the live file is gone.
- [x] **Suite green** — `bash .claude/tests/061-delegation-stop/run-all.sh` passes; `bash -n` clean on all three delegation hooks.
- [x] **`runtime-capabilities.md`** matrix `delegation/subagents` Codex cell no longer `unsupported`.

## Notes

- `.claude/.delegation-state/` intentionally NOT moved (loop-budget producer deferred for Codex; co-location corollary). The moved `delegation-stop.sh` reads it via the absolute `$PROJECT_DIR/.claude/.delegation-state/...` path on the Claude branch — unchanged.
- **Claude side LIVE-DOGFOODED (2026-05-28):** a real `Agent` (Explore/haiku) dispatch produced a correlated pair in `.agent0/delegation-audit.jsonl` — dispatch row (`event:"dispatch"`, `tool_use_id`, `formatted:true`) + close row (same `tool_use_id`, `correlation:"tool_use_id"`, `exit:"ok"`, `edit_count:0`, `duration_ms:5000`), both `schema_version:1`/`runtime:"claude-code"`. The close row carries the new schema → written by the moved `.agent0/hooks/delegation-stop.sh`. Finding: CC re-reads the `settings.json` SubagentStop registration mid-session (the moved hook fired without a restart — the "registration cached at session start" assumption was wrong for SubagentStop). Orphan path also exercised live (pre-cutover dispatches → `correlation:"unmatched"`).
- **Codex side LIVE-DOGFOODED (2026-05-28, independently verified):** a real Codex CLI session (`.codex/config.toml` with `[features] hooks=true` + active SubagentStart/SubagentStop delegation blocks) spawned one subagent (`agent_id 019e700f-c249-7681-abde-b6aa1320f22b`) with the 5-field convention-only brief. Audit log grew 4→6 lines with a matched `codex-cli` pair: start row (`schema_version:1`, `event:"subagent-start"`, `brief_observable:false`, `formatted:null`) + stop row (same `agent_id`, `correlation:"agent_id-direct"`, `exit:null`, `edit_count:null`, `duration_ms:14000`). Transcript path on the stop row exists (62 KB). `agent_id-direct` correlation proves the start hook fired pre-spawn (else `unmatched`). Both runtimes now dogfooded end-to-end (Claude via `tool_use_id`, Codex via `agent_id-direct`).
- **Codex config gotcha:** `.codex/config.toml` is gitignored + session-loaded — the delegation blocks must exist BEFORE Codex starts, else the start hook never writes and the stop row logs `correlation:"unmatched"`.
