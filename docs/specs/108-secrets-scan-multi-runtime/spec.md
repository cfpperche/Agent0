# 108 — secrets-scan-multi-runtime

_Created 2026-05-28._

**Status:** shipped — all acceptance green; live PreToolUse dogfood passed on BOTH runtimes (Codex 2026-05-28; Claude 2026-05-28 after fixing a dormant `if`-pipe registration bug, see `notes.md`)

## Intent

Port the secrets-scan preflight hook (`.claude/hooks/secrets-scan.sh`) from the Claude-only `.claude/hooks/` location into the runtime-neutral `.agent0/hooks/` surface so both Claude Code and Codex CLI run the same commit-shape gate — continuing the hook-by-hook multi-runtime migration (specs 106 delegation, 107 governance). The hook is a `PreToolUse(Bash)` shape-gate: it reads `tool_input.command`, short-circuits unless the command is a real `git commit`, and `exit 2`-blocks four dangerous shapes (`&& git commit`, `; git commit`, `git commit -a`/`-am`/`-ma`, `--no-verify`) unless a `# OVERRIDE:` marker is present. Crucially it does **not** run gitleaks — the actual scan lives in the runtime-neutral native `.githooks/pre-commit`. This spec also re-examines the hook's name, since "secrets-scan" overstates what the preflight layer actually does (it scans no secrets; it gates commit *shape* and bridges the override env-var to the native scanner).

Unlike the governance port (107), this is **not a pure move**: the override pass-through requires **runtime-aware output**. The cross-model debate (`debate.md`, converged 2026-05-28) verified against the official Codex hooks docs that Codex's `PreToolUse` rewrite needs `permissionDecision:"allow"` alongside `updatedInput`, whereas Claude today emits `updatedInput`-only — making the port a genuine multi-runtime design change, not a transcription.

## Acceptance criteria

- [x] **Scenario: hook runs from `.agent0/` on Claude**
  - **Given** the hook has been moved+renamed to `.agent0/hooks/secrets-preflight.sh` and `settings.json` repointed
  - **When** a Claude Code session issues `git commit --no-verify` with no override marker
  - **Then** the call is blocked with exit 2 and the verbatim corrected stderr template, identical to pre-move behavior

- [x] **Scenario: hook fires on Codex via the Bash gate**
  - **Given** `.codex/config.toml` has the new `[[hooks.PreToolUse]] matcher = "^Bash$"` block enabled and Codex restarted
  - **When** a Codex session issues a dangerous commit shape with no override
  - **Then** the commit is blocked equivalently (exit 2, corrected template) — `tool_input.command` extraction is shared, no Codex-specific branch needed for the block path

- [x] **Scenario: override pass-through emits runtime-aware rewrite**
  - **Given** a `git commit` carrying a valid `# OVERRIDE: <reason ≥10 chars>` marker
  - **When** the preflight accepts it
  - **Then** on Codex the emitted JSON includes `permissionDecision:"allow"` alongside `updatedInput` (required for Codex to honor the rewrite); on Claude the runtime-appropriate shape is emitted (resolved per Q1's Claude-UX sub-question) — in both cases the command is rewritten to prepend `export CLAUDE_SECRETS_OVERRIDE_REASON='<reason>';` so the native `.githooks/pre-commit` inherits and audits `override`

- [x] **Scenario: live Codex dogfood proves the rewrite reached Bash**
  - **Given** the Codex block is enabled and a command the hook rewrites
  - **When** the rewritten command actually executes
  - **Then** the executed command observed `CLAUDE_SECRETS_OVERRIDE_REASON` in its environment — verified live, not merely "the hook printed JSON" (107 proved block semantics; rewrite semantics are the new risk). *Verified live 2026-05-28: preflight `override-pass-through` + native `override` (`finding_count:1`).*

- [x] **Scenario: live Claude PreToolUse dogfood fires (block + override)**
  - **Given** a cold-started Claude session with the bare-`Bash`-matcher registration loaded (the prior `if: "Bash(git commit *|…)"` pipe-alternation filter was invalid CC syntax → dormant; see `notes.md` 2026-05-28)
  - **When** the session issues a compound `git add … && git commit` (no override), then a compound commit of a fake-key fixture with a two-line `# OVERRIDE:` marker
  - **Then** the first is blocked (exit 2, corrected template; Agent0 audit `runtime:"claude-code"`/`decision:"reject-shape"`/`cmd_shape:"compound-and"`) and the second lands (Agent0 audit `override-pass-through`; scratch native audit `decision:"override"`/`finding_count:1`) — proving the env-var bridge reaches the native gitleaks layer on Claude

- [x] **Scenario: non-commit Bash is silent under the broad matcher**
  - **Given** the hook registered under Codex's `^Bash$` matcher (no command-string `if` layer)
  - **When** an arbitrary non-`git commit` Bash command runs
  - **Then** the hook exits silently with **no audit row** (no `skip-not-commit` spam) — a deliberate reversal of the current Claude behavior, documented in the rule

- [x] Audit log is `.agent0/secrets-audit.jsonl` (hard cutover, no legacy-read) with an added `runtime` field (`claude-code`/`codex-cli`/`native-git`) + retained `scan_mode`; decision values unchanged; native `.githooks/pre-commit` repointed to the new path
- [x] Project-root resolution sources `.agent0/hooks/_memory-hook-lib.sh` (`memory_project_dir()`), not `PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"`; a subdirectory-cwd fixture proves the log lands at repo root
- [x] All 7 scenario tests in `.claude/tests/secrets-scan/` pass against the moved hook (path + audit refs updated; dir name stays `secrets-scan`)
- [x] No stale `.claude/hooks/secrets-scan.sh` references remain anywhere (`grep -rn` clean across tests, rules, docs, settings)
- [x] Perf/latency harness updated for the rename: `.agent0/tools/bench-hooks.sh` (`HOOK_NAMES`), `.claude/.perf-baseline.json` (filename-keyed baseline), and `.claude/tests/hook-chain-latency/01-baseline-exists.sh` all reference `secrets-preflight.sh`; `bash .claude/tests/hook-chain-latency/01-baseline-exists.sh` passes
- [x] `.claude/rules/secrets-scan.md` updated: new path + name, Codex activation note, runtime-branched output shape, the guardrail-not-shell-boundary wording, and the dropped `skip-not-commit` signal documented as a deliberate decision

## Non-goals

- Porting the `secrets-advise.sh` PostToolUse advisory — it needs `apply_patch` path-extraction for Codex and is a separate, later unit.
- Touching the native `.githooks/pre-commit` gitleaks layer — already runtime-neutral (git-level, no runtime payload).
- Changing `.gitleaks.toml`, the allowlist mechanics, or any detection behavior.
- Renaming the audit-log decision values or the `.githooks/pre-commit` contract.

## Open questions

- [x] **Q1 — Codex `updatedInput` support. RESOLVED (debate, verified vs official Codex docs).** Codex's `PreToolUse` supports command rewriting, but requires `permissionDecision:"allow"` alongside `updatedInput` — the current `updatedInput`-only shape is silently ignored on Codex, which would break the env-var bridge. The hook must emit the combined shape on Codex. **Remaining plan-time sub-question (not a blocker):** on Claude, `permissionDecision:"allow"` *auto-approves the tool call and bypasses the normal permission prompt*; emitting it unconditionally could silently skip a prompt the user would otherwise see. Resolution at plan time: branch the emitted JSON by runtime via `memory_runtime()` (Codex → `allow`+`updatedInput`; Claude → `updatedInput`-only) unless a quick check shows Claude tolerates `"allow"` here without a UX change, in which case one shape serves both.
- [x] **Q2 — Rename the hook. RESOLVED (debate).** Rename the file only: `.claude/hooks/secrets-scan.sh` → `.agent0/hooks/secrets-preflight.sh` ("scan" is materially false for the preflight). Keep the rule/capacity slug (`secrets-scan`), the test directory (`.claude/tests/secrets-scan/`), and the audit filename (`secrets-audit.jsonl`) to bound the cascade. NB the rename also ripples into the perf/latency harness (filename-keyed) — captured in Acceptance criteria.
- [x] **Q3 — Audit-log location. RESOLVED (debate).** Move to `.agent0/secrets-audit.jsonl` (hard cutover per 106, no legacy-read) with an additive `runtime` provenance field; decision values unchanged. The native `.githooks/pre-commit` writer is repointed to the new path and tagged `runtime:"native-git"`.
- [x] **Q4 — Debate-or-not / scope. RESOLVED.** A debate WAS warranted — real refinement surfaced (permissionDecision requirement, audit-spam under broad matcher, provenance fields, root resolution, rename). Kept as a **single spec**, not bundled with supply-chain (next, separate pass that reuses these lessons) or `secrets-advise` (edit-surface port needing `apply_patch` extraction).

## Context / references

- `.claude/hooks/secrets-scan.sh` — the preflight being moved
- `.claude/rules/secrets-scan.md` — full two-layer discipline + override grammar
- `.githooks/pre-commit` — the native gitleaks layer (runtime-neutral, not moved)
- `.claude/tests/secrets-scan/` — 7 scenario tests + run-all
- `docs/specs/106-delegation-hooks-multi-runtime/`, `docs/specs/107-governance-gate-refinement/` — the migration precedents
- `.agent0/memory/codex-cli-hooks.md` — verified Codex hook-surface facts
- `.agent0/HANDOFF.md` § Next Actions — the migration batch plan
- `.agent0/hooks/_memory-hook-lib.sh` — `memory_project_dir()` + `memory_runtime()` the ported hook will source
- `.githooks/pre-commit` — native layer; co-writer of the audit log (repointed to `.agent0/`) and reader of the override env-var bridge
- Official Codex hooks docs (verified 2026-05-28): <https://developers.openai.com/codex/hooks> — `permissionDecision:"allow"` + `updatedInput` rewrite shape; `^Bash$` matcher (no command-string `if` layer); exit-2 block
- **Memory entries to refresh post-port:** `capacity-spec-index.md`, `cc-platform-hooks.md`, `hook-chain-latency.md`, `hook-chain-maintenance.md`, `rule-load-debug.md`, `user-global-hooks-shadow.md`
- **Next port inherits this as template:** `supply-chain-scan.sh` copies these primitives (override grammar, `skip-not-*` discipline, matcher breadth) — 108's decisions become 109's starting point
