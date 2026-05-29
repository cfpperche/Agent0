# 109 — supply-chain-scan-multi-runtime

_Created 2026-05-28._

**Status:** shipped — in-session/synthetic coverage is green (19/19 tests, synthetic block on both runtime tags, grep-clean, registration fixed) and both live-fire dogfoods are recorded in `notes.md`: Claude Code task 22 (`cargo add tokio` block + override) and Codex CLI task 23 (`pip install requests` block + override). The 108 lesson is preserved: tests passing was not treated as enough until real PreToolUse fires produced audit rows.

## Intent

Port the supply-chain dep-install preflight hook (`.claude/hooks/supply-chain-scan.sh`) from the Claude-only `.claude/hooks/` location into the runtime-neutral `.agent0/hooks/` surface so both Claude Code and Codex CLI run the same dependency-mutation gate — continuing the hook-by-hook multi-runtime migration (106 delegation, 107 governance, 108 secrets-preflight). The hook is a `PreToolUse(Bash)` gate: it tokenises `tool_input.command`, detects `(manager, verb, packages)` triples across 11 package managers (npm/pnpm/yarn/bun/pip/uv/poetry/pdm/cargo/go/composer), and `exit 2`-blocks dep-installs in block mode (default) unless a `# OVERRIDE: <reason ≥10 chars>` marker is present; advisory mode (`CLAUDE_SUPPLY_CHAIN_BLOCK=0`) downgrades to a non-blocking stderr advisory.

This port carries a **latent-bug fix as its motivating discovery**: the current Claude registration filters with `if: "Bash(npm *|pnpm *|yarn *|...)"`, and CC's `if` field uses permission-rule syntax that **has no pipe-alternation or list combinator** (verified against the official hooks docs 2026-05-28: _"There is no `&&`, `||`, or list syntax for combining rules; to apply multiple conditions, define a separate hook handler for each"_). The `|` makes the pattern never match, so **the supply-chain Bash preflight is firing on nothing today** — the same dormant-registration class that 108's live dogfood caught for secrets. The port replaces the invalid `if` with a bare `matcher: "Bash"` + the in-script keyword filter the hook already performs, mirroring the 108 fix and giving one consistent behavior across both runtimes.

Unlike 108, this is **not a rewrite hook** — it only blocks (exit 2) or advises (exit 0 + stderr); there is no command-mutation path and no env-var bridge to a downstream layer. So it needs **no runtime-aware output** (107 already proved exit-2 block is runtime-neutral). That makes 109 closer to a pure move than 108 was, with the registration fix, the audit relocation, and the broad-matcher audit-spam decision as the substantive deltas.

## Acceptance criteria

- [x] **Scenario: hook runs from `.agent0/` on Claude under a bare Bash matcher**
  - **Given** the hook moved to `.agent0/hooks/supply-chain-preflight.sh`, `settings.json` repointed, and the invalid `if: "Bash(npm *|…)"` replaced with a bare `"matcher": "Bash"`
  - **When** a cold-started Claude session issues a dep-install (`cargo add tokio` in the live dogfood) with no override marker (block mode default)
  - **Then** the call is blocked with exit 2 and the verbatim corrective stderr template, identical to the pre-move block behavior — proving the registration now actually fires (it was dormant under the pipe-alternation `if`)

- [x] **Scenario: live Claude PreToolUse dogfood fires (block + override)**
  - **Given** a cold-restarted Claude session with the bare-`Bash`-matcher registration loaded
  - **When** the session issues `cargo add tokio` (no override), then the same install with a two-line `# OVERRIDE: <reason ≥10 chars>` marker
  - **Then** the first is blocked (exit 2, corrective template; Agent0 audit `runtime:"claude-code"`/`decision:"block"`) and the second passes silently (audit `decision:"block-override"`, `override_reason` populated) — verified live, not merely via direct script invocation (108's lesson: tests pass while a registration is dormant)

- [x] **Scenario: hook fires on Codex via the Bash gate**
  - **Given** `.codex/config.toml.example` carries a new enabled-by-uncomment `[[hooks.PreToolUse]] matcher = "^Bash$"` block pointing at the moved hook, and Codex restarted
  - **When** a cold-started Codex session issues `pip install requests` with no override, then the same install with a two-line `# OVERRIDE: <reason ≥10 chars>` marker
  - **Then** the first is blocked equivalently (exit 2, corrective template; audit `runtime:"codex-cli"`/`decision:"block"`) and the second passes through with audit `decision:"block-override"` and `override_reason` populated; Codex's local-shell launcher form (`/bin/bash -lc '<command>'`) is unwrapped before shared tokenization

- [x] **Scenario: non-install Bash is silent with no audit row under the broad matcher**
  - **Given** the hook registered under a bare `Bash` matcher (Claude) / `^Bash$` (Codex), with no command-string `if` layer
  - **When** an arbitrary non-dep-install Bash command runs (`ls`, `git status`, `cat foo`)
  - **Then** the hook exits silently with **no audit row** — the `skip-not-install` forensic row is dropped under the broad matcher (a deliberate reversal of current behavior, mirroring 108's `skip-not-commit` drop; documented in the rule), because firing on every Bash would make `skip-not-install` pure spam

- [x] **Scenario: bare-install + dirty-manifest advisory survives the move**
  - **Given** the working tree has an uncommitted `package.json` and block mode is active
  - **When** a session runs bare `bun install` (no packages)
  - **Then** the `advisory-bare-install` stderr line + audit row still fire (the dirty-manifest git probe now anchors at `memory_project_dir()`, not `${CLAUDE_PROJECT_DIR:-$PWD}`), proving the lockfile-resolve coverage path is preserved across the move and root-resolution change

- [x] Audit log is `.agent0/supply-chain-audit.jsonl` (hard cutover, no legacy-read) with an added `runtime` field (`claude-code`/`codex-cli`); all existing decision values (`block`, `block-override`, `advisory`, `advisory-override`, `advisory-bare-install`, `advisory-bare-install-override`) retained; the `skip-not-install` value is retired from the Bash preflight path
- [x] Project-root + git-probe resolution sources `.agent0/hooks/_memory-hook-lib.sh` (`memory_project_dir()`), not `PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"`; a subdirectory-cwd fixture proves both the audit log and the dirty-manifest probe land at repo root
- [x] `runtime` field sourced from `memory_runtime()`; no command-rewrite path is added (confirming no `permissionDecision`/`updatedInput` shape is needed — the 108 rewrite-output complexity does not apply here)
- [x] All scenario tests in `.claude/tests/supply-chain/` + `.claude/tests/supply-chain-composer/` pass against the moved hook (path + audit refs updated; dir names stay `supply-chain*`); the `02-skip-not-install.sh` test is updated to assert silent-no-audit instead of a `skip-not-install` row
- [x] No stale `.claude/hooks/supply-chain-scan.sh` references remain anywhere (`grep -rn` clean across tests, rules, docs, settings, perf harness)
- [x] Perf/latency harness updated for the rename: `.agent0/tools/bench-hooks.sh` (`HOOK_NAMES`), `.claude/.perf-baseline.json` (filename-keyed baseline), and `.claude/tests/hook-chain-latency/01-baseline-exists.sh` all reference `supply-chain-preflight.sh`; the baseline-exists test passes
- [x] `.claude/rules/supply-chain.md` updated: new path + name, `paths:` frontmatter glob, Codex activation note, the dropped `skip-not-install` signal documented as a deliberate decision, and the bare-matcher-not-`if`-filter rationale recorded as a gotcha

## Non-goals

- Porting `supply-chain-advise.sh` (the PostToolUse Edit/Write manifest-edit advisory) — it needs `apply_patch` path-extraction for Codex and is a separate, later unit, exactly as 108 deferred `secrets-advise.sh`. 109 is the Bash preflight only.
- Changing the manager detection table, verb whitelists, tokeniser terminators, or value-taking-flag allowlist — detection behavior is preserved verbatim across the move.
- Changing the block-vs-advisory mode semantics, the override grammar, or the 10-char reason floor.
- Adding Codex loop-budget / `permissionDecision` rewrite support (no rewrite path exists for this hook).
- Renaming the rule/capacity slug (`supply-chain`), the test directories, or the audit-log decision values.

## Open questions

- [ ] **Q1 — Registration shape under a bare matcher. RECOMMENDED: bare `"matcher": "Bash"` + in-script filter.** The official docs confirm a *valid* Claude-only alternative exists: 11 separate `if` handlers (`if: "Bash(npm *)"`, `if: "Bash(pnpm *)"`, …), one per manager, which would avoid the process-spawn on non-PM Bash commands and keep `skip-not-install` meaningful. **Rejected** because (a) Codex has no `if`-equivalent (it matches on the tool-name regex `^Bash$`), so the script must self-filter for Codex regardless — 11 Claude handlers would create a two-mechanism runtime divergence; (b) it's 11 settings.json entries to maintain vs one; (c) 108 already set the bare-matcher precedent and accepted the per-Bash spawn latency. Confirm at plan time that the per-Bash spawn cost is acceptable here (the script is heavier than secrets-preflight — tokeniser loop + a `git status --porcelain` probe on bare-install), or revisit the 11-handler perf option.
- [x] **Q2 — Drop `skip-not-install` under the broad matcher. RESOLVED (user, 2026-05-28): drop (mirror 108).** Under the bare matcher the hook runs on every Bash; keeping the `skip-not-install` forensic row would write a JSONL line for every `ls`/`cat`/`git status` (the "audit-log volume is HIGH" gotcha, now unbounded). 108 made the identical call for `skip-not-commit`. Decision: silent + no audit when no `(manager, verb)` pair matches. Audit rows remain for real detections (block/advisory/bare-install). Edits `02-skip-not-install.sh` + the rule.
- [x] **Q3 — Rename the hook file. RESOLVED (user, 2026-05-28): `supply-chain-scan.sh` → `supply-chain-preflight.sh`.** Parallel to 108's `secrets-scan.sh → secrets-preflight.sh` rename rationale ("scan" overstates the layer — it scans no dependency contents; it gates dep-install *command shapes*). Keep the rule slug, test dirs, and audit filename to bound the cascade. Accepts the perf-harness ripple (filename-keyed baseline).
- [x] **Q4 — Runtime-aware output / rewrite shape needed? RESOLVED: no.** The hook has no command-rewrite path and no downstream env-var bridge (the rule states explicitly: _"There is no env-var bridge for this hook… No downstream layer needs to read it"_). Block is exit-2 + stderr, which 107 proved runtime-neutral. So the 108 `permissionDecision:"allow"` + `updatedInput` complexity does **not** apply — `memory_runtime()` is used only to tag the audit `runtime` field.
- [x] **Q5 — Debate-or-not. RESOLVED: no debate.** The one design ambiguity (valid `if` shape) was resolved by 60-second doc research, not cross-model dialectic; every other decision inherits directly from 108/107 precedent. A mechanical port with no open design space does not warrant two agent sessions (per `.claude/rules/spec-driven.md` § 1.5 skip guidance).

## Context / references

- `.claude/hooks/supply-chain-scan.sh` — the Bash preflight being moved (~470 lines; tokeniser + block/advisory modes + bare-install sub-path)
- `.claude/hooks/supply-chain-advise.sh` — the PostToolUse companion (NOT moved; see Non-goals)
- `.claude/rules/supply-chain.md` — full two-layer discipline, manager table, override grammar, audit shape, gotchas
- `.claude/tests/supply-chain/` (13 scenarios) + `.claude/tests/supply-chain-composer/` (4 scenarios) — the test corpus to repoint
- `docs/specs/108-secrets-scan-multi-runtime/` — the direct template (rename, audit relocation, broad-matcher audit-spam drop, `memory_project_dir`/`memory_runtime` sourcing, Codex activation block, live-dogfood requirement); `docs/specs/106`/`107` — earlier migration precedents
- `.agent0/hooks/_memory-hook-lib.sh` — `memory_project_dir()` + `memory_runtime()` the ported hook will source
- `.agent0/hooks/secrets-preflight.sh` — sibling preflight; the shape to mirror for root resolution + audit `runtime` tagging
- `.codex/config.toml.example` — where the Codex `[[hooks.PreToolUse]] matcher = "^Bash$"` activation block lands
- `settings.json:75-84` — the dormant `if: "Bash(npm *|…)"` registration to replace with a bare `Bash` matcher
- Official Codex hooks docs (verified 2026-05-28): <https://developers.openai.com/codex/hooks> — `^Bash$` matcher, exit-2 block
- Official Claude Code hooks docs (verified 2026-05-28): <https://code.claude.com/docs/en/hooks> — `if` field uses permission-rule syntax, no pipe/list combinator; "define a separate hook handler for each" condition
- **Memory entries to refresh post-port:** `capacity-spec-index.md`, `cc-platform-hooks.md`, `hook-chain-latency.md`, `hook-chain-maintenance.md`, `rule-load-debug.md`, `runtime-introspect-maintenance.md`
