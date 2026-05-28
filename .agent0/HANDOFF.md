# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects and enforces this file through hooks; Codex can do the same after the `.codex/config.toml.example` Agent0 hook blocks are enabled.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Spec 107 (`governance-gate-refinement`) is SHIPPED + dogfooded (2026-05-28).** Decided via a converged Claude↔Codex `/sdd debate`. Refined `governance-gate.sh` (rm separate-flag fix, git clean -f/broad, whole-tree checkout/restore, fast-path drift-guard + corrected comment, thin "speed-bump not sandbox" header) AND bundled the multi-runtime port: hook moved `.claude/hooks/` → `.agent0/hooks/`, `settings.json` repointed, `.codex/config.toml.example` gained a commented `[[hooks.PreToolUse]]` Bash block. New suite `.claude/tests/governance-gate/` 8/8 PASS; **live-dogfooded on BOTH runtimes** (Claude: block+allow+self-commit-block; Codex 2026-05-28: PreToolUse(Bash) at `.agent0/` path → block/allow/override all PASS — zero runtime asymmetry). Cascade fixed: `bench-hooks.sh` now resolves `.agent0/hooks/` then `.claude/hooks/` (future-proofs the next ports); hook-chain-latency 01+03 green; harness-sync 05 green; tdd.md doc-ref repointed. RESISTED (deliberate, documented): override-audit jsonl + shell-primitive families. Next portable Bash gates (secrets-scan, supply-chain-scan) are a later batch. **Uncommitted: the 107 line.**

**Spec 106 (`delegation-hooks-multi-runtime`) is SHIPPED — implemented + validated (2026-05-28), committed `e8908cf` + pushed.** Decided via a 3-round Claude↔Codex `/sdd debate`, then built. Two-layer architecture:
- **Discipline (5-field handoff):** Claude `delegation-gate.sh` blocks (unchanged). Codex = **convention-only** (`delegation.md` § Codex: convention-only; no hook can block a spawn — verified across SubagentStart/PreToolUse/PermissionRequest).
- **Observability:** new `.agent0/hooks/delegation-start-audit.sh` (Codex SubagentStart, non-blocking) + `.agent0/hooks/delegation-stop.sh` (moved from `.claude/`, shared multi-runner, branches Claude vs Codex `agent_id-direct`). One canonical `.agent0/delegation-audit.jsonl` (hard cutover — old `.claude/` log + all refs purged). Rows carry `schema_version`/`runtime`/`event`.
- `.claude/.delegation-state/` stays Claude-only (loop-budget producer deferred for Codex).

Validation: `bash .claude/tests/061-delegation-stop/run-all.sh` = 10/10 PASS (incl. new `10-codex-branch.sh`); `bash -n` clean on all 3 hooks; gate still blocks (exit 2) + writes only `.agent0/`; harness-sync gitignore tests green.

**Codex live dogfood completed after restart.** Local `.codex/config.toml` has `[features] hooks = true` plus active `SubagentStart`/`SubagentStop` delegation blocks. One Codex subagent (`019e700f-c249-7681-abde-b6aa1320f22b`) was spawned with the 5-field convention-only brief and completed read-only. Audit log grew from 4 to 6 lines with matched `codex-cli` `subagent-start` + `subagent-stop` rows.

Umbrella 102 remains CLOSED. Uncommitted: all of spec 106 line (hooks, settings.json, .codex example, rules, .gitignore, tests, docs/specs/106/*) + `.agent0/memory/codex-cli-hooks.md` edit.

## Active Work

_None active._

## Next Actions

1. **Review + commit the spec 106 line** after successful Codex live dogfood (nothing committed this session). Notable: `delegation-stop.sh` moved `.claude/`→`.agent0/` (git shows delete+add); the live `.claude/delegation-audit.jsonl` (gitignored) was deleted.
2. Resume the alphabetical hook walkthrough if desired: `governance-gate.sh` is next portable Bash-surface gate. Other portable hooks remain scoped out of 106.
3. Still unpushed: `main` ahead of `origin/main`; push not authorized.

## Decisions & Gotchas

- **Hard cutover (user decision) over the debate's freeze-legacy synthesis:** `.claude/delegation-audit.jsonl` removed entirely, no legacy-read, `absence⇒v1` rule dropped. Aligns with `forks-ephemeral-dogfood.md`.
- **Dispatch rows now carry `event:"dispatch"`** — this broke the old `(.event // "") == ""` "dispatch = no event" convention. Fixed everywhere: `delegation-stop.sh` correlation queries + `delegation.md` example queries now use `.event == "dispatch"`. Any future query MUST use explicit `event` values, not absence.
- **Codex facts (verified 2026-05-28, in `.agent0/memory/codex-cli-hooks.md`):** SubagentStart carries NO brief text → `brief_observable:false`/`formatted:null` always; no hook can block a spawn; `SubagentStop` symmetric, correlates by `agent_id`.
- **Both `.agent0/` delegation hooks source `_memory-hook-lib.sh`** for `memory_project_dir` (Codex cwd-from-payload support); runtime detected by `CLAUDE_PROJECT_DIR` set/unset.
- **Live Codex dogfood result (2026-05-28):** baseline audit log `4` lines; after one subagent, `6` lines. Start row: `schema_version:1`, `runtime:"codex-cli"`, `event:"subagent-start"`, `brief_observable:false`, `formatted:null`, `agent_id:"019e700f-c249-7681-abde-b6aa1320f22b"`. Stop row: same `agent_id`, `event:"subagent-stop"`, `correlation:"agent_id-direct"`, `exit:null`, `edit_count:null`, numeric `duration_ms:14000`.
- **Local Codex config gotcha:** `.codex/config.toml` is gitignored and session-loaded. Delegation blocks must exist before Codex starts; otherwise stop may log `correlation:"unmatched"` because the start hook never wrote.
