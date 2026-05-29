# 111 — delegation-verify-subagent-stop — tasks

_Generated from `plan.md` on 2026-05-29. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Status (2026-05-29)

**Implementation + in-session validation COMPLETE. One step is cold-restart-gated.**

- ✅ Tasks 1–5, 7–15 done: `delegation-verify.sh` built; 8-scenario test suite green; registered on `SubagentStop`; `post-edit-validate.sh` + its registration deleted; spec-067 cascade tests removed; `delegation.md` rewritten; advisory family + all path refs swept; Codex config block added.
- ✅ Task 6 (chain-semantics spike) — resolved by DOCS **and confirmed LIVE**: Claude SubagentStop hooks run in parallel (empirically proven — `subagent-stop` + `subagent-verify` rows at the same ts for one stop), exit-2 blocks-and-continues, `agent_id` present, `stop_hook_active` delivered. This invalidated the sentinel design → counter-contract (see `notes.md`). My initial "cold-restart-gated" assumption was **wrong** — the registration fired in-session.
- ✅ **Live Claude dogfood (pass path) DONE** — real `Agent` dispatch `acb46fdc0a91cab59` → `SubagentStop` fired `delegation-verify.sh` → `decision:pass` row. Scenarios 2/3 (block/exhausted) stay synthetic (`02`/`03` tests) — a live fire needs a failing stack, which Agent0 lacks; the block path reuses the now-proven fire mechanism.
- ✅ **Codex dogfood DONE** (scenario 4, Codex TUI 0.135.0, 2026-05-29) — live `block` + `exhausted` rows recorded; **both OQs resolved by live evidence** (agent_id preserved; stop_hook_active false→true → exhausted, no loop). Spec `shipped`, fully dogfooded on BOTH runtimes. Nothing open.

## Implementation

### Build the new hook (skeleton → green in isolation)

- [ ] 1. Create `.agent0/hooks/delegation-verify.sh` skeleton: `set -uo pipefail`, stdin capture, `jq` guard (fail-open exit 0), source `_memory-hook-lib.sh`; resolve `agent_id` (exit 0 if absent — non-delegated stop), `PROJECT_DIR=memory_project_dir`, `RUNTIME=memory_runtime`. `bash -n` clean.
- [ ] 2. Validator resolution + cwd: reuse `post-edit-validate.sh`'s chain (`CLAUDE_DELEGATION_VALIDATOR` → `.claude/validators/run.sh` → fail-open exit 0). Derive validator cwd from the sub-agent's `cwd` (worktree-isolated stops close in their worktree); fail-open to `$PROJECT_DIR` on `git rev-parse` failure.
- [ ] 3. `ok=true` branch: run validator once; on pass, surface the **advisory family** — echo validator stderr (`lint-advisory:` / `typecheck-advisory:`) AND `warnings[]` as `tdd-advisory:` to stderr (relocated verbatim from `post-edit-validate.sh`); exit 0.
- [ ] 4. `ok=false` branch v1 (block only, no coordination yet): exit 2 with the validator command/exit + stdout/stderr tail surfaced. Direct-invoke with a synthetic Claude-shape `SubagentStop` payload (`ok=false`) → exit 2; synthetic `ok=true` → exit 0 + advisories. Both green before wiring.

### Wire + dogfood the chain semantics (GATING — design depends on the result)

- [ ] 5. Register `delegation-verify.sh` in `.claude/settings.json` `SubagentStop` array **before** `delegation-stop.sh`.
- [ ] 6. **Spike dogfood (cold restart required).** Dispatch a delegated Claude sub-agent whose tree fails the validator. Observe and record in `notes.md`: (a) does `delegation-verify.sh` exit-2 actually block + continue the sub-agent? (b) **does `delegation-stop.sh` still run after the exit-2** (→ sentinel needed to suppress the close row) or is the chain short-circuited (→ no sentinel needed)? (c) **OQ1** — does the continued sub-agent preserve its `agent_id`? (d) **OQ2** — `stop_hook_active` value across the blocked stop. This result drives tasks 7–8.
- [ ] 7. Finalize close-row coordination per task 6: IF `delegation-stop.sh` runs after verify's exit-2 → add a per-stop `verify-blocked` sentinel under `.agent0/.delegation-state/` written by `delegation-verify.sh`, and a sentinel-read-and-skip (+ clear) in `delegation-stop.sh` so no `subagent-stop` close row is written for a blocked stop. ELSE → document in `plan.md` that exit-2 short-circuits the chain and no sentinel is needed. Either way, write a `verify-blocked` status row to `.agent0/delegation-audit.jsonl`.
- [ ] 8. Stop-keyed budget: counter at `.claude/.delegation-state/agents/<agent_id>` — first failing stop → block + one continuation; second consecutive failing stop (guarded by `stop_hook_active`/counter per task 6) → force partial-result (accept closure, stop continuing). Update `delegation-stop.sh`'s read of that counter so the close-row `exit` field reflects stop-keyed verify-failures, not per-edit.

### Codex side + tests

- [ ] 9. Add a commented `[[hooks.SubagentStop]]` block for `delegation-verify.sh` to `.codex/config.toml.example`, **before** the existing `delegation-stop.sh` block; comment notes block-via-`decision:"block"` + the cold-restart/trust step.
- [ ] 10. Write `.claude/tests/delegation-verify/` scenarios (+ run-all if the suite convention uses one): pass→exit0+advisories; fail→exit2; second-fail→partial-result; advisory-family surfaced on pass; fail-open on missing/non-exec/unparseable validator; Codex-shape payload (no `CLAUDE_PROJECT_DIR`, `cwd` only) keyed by `agent_id` audits `runtime:"codex-cli"`.

### Remove the old hook + cascade

- [ ] 11. Delete `.claude/hooks/post-edit-validate.sh` AND remove its `PostToolUse` `matcher:"Edit|Write|MultiEdit"` registration from `.claude/settings.json`.
- [ ] 12. Remove `.claude/tests/parallel-edit-validation/01-*.sh` + `02-*.sh` (per-edit validator-cascade is structurally impossible at stop-time); note the dropped spec-067 guard in the commit message.
- [ ] 13. Rewrite `.claude/rules/delegation.md` § *Post-edit validator loop* → stop-time *delegated-verification* (trigger, sentinel/close-row ordering per task 7, stop-keyed budget, both-runtime); update § *Audit log* with the `verify-blocked` row shape + close-row-suppressed-on-block rule.
- [ ] 14. Repoint advisory-surfacing references in `.claude/rules/tdd.md`, `lint-validator.md`, `typecheck-advisory.md` from `post-edit-validate.sh` → `delegation-verify.sh`; note advisories now fire once at stop.
- [ ] 15. Sweep remaining refs: `.claude/rules/{harness-sync,image-gen,runtime-capabilities}.md` (incl. the matrix cell → both-runtime stop-time), `CLAUDE.md`, `AGENTS.md`, `.agent0/memory/{cc-platform-hooks,codex-cli-hooks}.md`, `.agent0/hooks/session-track-edits.sh`, `.claude/hooks/secrets-advise.sh`. `grep -rn 'post-edit-validate'` returns nothing outside `docs/specs/`.

## Verification

_Acceptance checks tied to `spec.md` § Acceptance criteria._

- [ ] **Claude pass scenario** — delegated sub-agent closes with a passing validator → `delegation-verify.sh` runs once, close row appended, closure accepted (exit 0). (spec scenario 1)
- [ ] **Claude fail scenario** — failing validator → block (exit 2) + validator tail + `verify-blocked` row + NO `subagent-stop` close row. (spec scenario 2)
- [ ] **Second-fail escalation** — continued-then-still-failing stop forces partial-result, no infinite loop. (spec scenario 3)
- [ ] **Codex live dogfood** — `.codex/config.toml` `SubagentStop` verify block enabled + cold restart/trust; a failing Codex sub-agent close blocks via `decision:"block"` + `runtime:"codex-cli"` `verify-blocked` row; recorded in `notes.md` (fixtures NOT sufficient — 108/109 lesson). (spec scenario 4)
- [ ] `post-edit-validate.sh` deleted + registration removed; `grep -rn 'post-edit-validate'` clean outside `docs/specs/`.
- [ ] Advisory family (`lint-` / `typecheck-` / `tdd-advisory:`) still reaches the agent via `delegation-verify.sh` (surfaced once at stop).
- [ ] `delegation.md` rewritten; the existing `.claude/tests/061-delegation-stop` suite + the new `delegation-verify` suite both pass.
- [ ] **OQ1 + OQ2 resolved and recorded in `notes.md`** (`agent_id` preservation across a continued stop; `stop_hook_active` behavior) — the budget/sentinel design (tasks 7–8) reflects the dogfooded answers, not assumptions.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._

- Implementation order is deliberate: tasks 1–4 build the hook in isolation; task 6 (the spike dogfood) is the GATE — its result decides whether tasks 7–8 need the sentinel mechanism at all. Do NOT finalize the close-row coordination or budget before task 6 is recorded.
- Build-new-then-delete-old (tasks 1–10 before 11) keeps the migration from having a window with neither hook live. In Agent0 the validator is dormant (no stack), so the brief overlap where both could run costs nothing here; in a stack consumer it would double-run the suite for one PR — acceptable and transient.
