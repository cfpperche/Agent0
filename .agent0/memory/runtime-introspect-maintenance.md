---
name: runtime-introspect-maintenance
description: Maintainer discipline for runtime-introspect — detector extension contract + inference heuristics + dogfood archaeology + deep gotchas.
metadata:
  type: project
  created_at: '2026-05-27T00:00:00Z'
  last_accessed: '2026-05-27'
  confirmed_count: 0
---
# Runtime introspect maintenance

Maintainer-binding companion to `.claude/rules/runtime-introspect.md`. The companion rule carries the consumer-facing slice (what fires, the detector table, the probe output shape, escape hatches the agent invokes); this memory carries the upstream-maintainer surface — the env-var extension contract, the per-detector inference heuristics, the state-file design rationale, and the dogfood archaeology / deep gotchas a maintainer extending detectors needs.

## Extension via env var (HUMAN-ONLY, pre-launch)

`CLAUDE_RUNTIME_INTROSPECT_EXTRA_DETECT="<space-separated globs>"` adds custom runners without modifying the hook. Example: `CLAUDE_RUNTIME_INTROSPECT_EXTRA_DETECT="make-test just-check"` accepts `make test` and `just check`. The hook normalises the matched pair to `extra:<glob>` in the `detector` field so audits stay distinguishable from core detections.

**The variable must be exported in the shell BEFORE `claude` launches** — agents cannot set it mid-session via a Bash tool call. Reason: the hook is spawned by the Claude Code harness as a sibling process, inheriting the harness's env, not the Bash tool child shell's env (verified empirically by rshrnk dogfood B3, finding #6 — see § Deep gotchas). When a stack needs a new detector and the human can't pre-launch (or doesn't want to), the path is a follow-up spec extending the native detector list, not the env-var workaround.

The detector list is deliberately small. Strict pair lists with env-var extension beat generous regex fallbacks — the latter consistently leaks false positives (e.g. `cat README | grep test` would match a `*test*` heuristic).

## Inference heuristics

Per-detector pattern tables, run against combined `stdout + stderr` (since some runners emit summaries on stderr). Updated when a real-world runner output surfaces that the table misses.

- **Test runners** (`bun-test`, `npm-test`, `pnpm-test`, `yarn-test`, `*-run-test`): `^[[:space:]]*0 fail[[:space:]]*$` → PASS; `[1-9][0-9]* fail` → FAIL; `failed|✗|error` → FAIL; `pass|✓|ok` → PASS (weak).
- **pytest / unittest** (`pytest`, `python-pytest`, `python-unittest`): `[1-9][0-9]* (failed|error)` → FAIL; `[0-9]+ passed` (no `failed|error`) → PASS; `^FAILED` → FAIL; `^OK` → PASS.
- **Typecheck / build / lint** (`bun-tsc`, `yarn-typecheck|build|lint`, `*-run-typecheck|build|lint`): `error TS[0-9]+` → FAIL; output < 500 chars and no `error|fail` keyword → PASS (clean-output heuristic).
- **Cargo test** (`cargo-test`): `^test result: ok` → PASS; `^test result: FAILED` → FAIL. Canonical test-runner summary line, anchored at start-of-line. Multiple `test result:` lines under `--no-fail-fast` or workspace walks — first FAIL wins (any failure flips overall status).
- **Cargo typecheck / build / lint** (`cargo-check`, `cargo-build`, `cargo-clippy`): `error\[E[0-9]+\]` → FAIL (rustc compiler error code shape); `^error:` → FAIL (clippy `-D warnings` promoted-warning lines + rustc fatal summary "could not compile" lines); `[[:space:]]+Finished` → PASS (cargo's canonical clean-completion line). The Finished-line PASS signal is deliberately preferred over a character-count heuristic because cargo output frequently exceeds 500 chars in multi-crate projects due to per-crate `Compiling ...` lines.

`interrupted=true` trumps any inference → status `INTERRUPTED`.

## State file design rationale

`.agent0/.runtime-state/last-run.json` — single file, gitignored, overwritten on every matched capture. Concurrent matched runs race on `mktemp + mv` semantics; POSIX rename atomicity guarantees no torn writes, and last-writer-wins is the design (snapshot = latest, not history).

In-flight start marks live at `.agent0/.runtime-state/in-flight/<tool_use_id>.t` (touched by the pre-mark hook, removed by the capture hook). Stale marks (older than 1h) are not auto-pruned in v1 — disk impact is negligible (one zero-byte file per Bash invocation) and pruning complexity isn't paying for itself yet.

**Deliberate non-feature: no per-Bash audit JSONL.** This capacity does NOT write one row per Bash call — `last-run.json` is self-sufficient for the "latest evidence" use case the agent has, and adding an audit layer would dilute the signal-to-noise ratio at the same scale. A follow-up spec adds an audit layer if forensic queries become a real need.

## Deep gotchas

- **`tool_response` truncation risk.** PostToolUse(Bash) carries the captured stdout/stderr in `tool_response`, BUT the harness may truncate large outputs before the hook sees them. The hook's tail clamping happens against whatever reached it — if upstream truncation engages, the snapshot reflects the pre-truncated view, not the original. Mitigation: probe with a known-noisy `bun test` invocation before relying on this; live-dogfood verified ~150-byte test output survives end-to-end. Long-term fallback (not in v1): read the last assistant message's `tool_result` block from `transcript_path`.
- **`bun run <script>` keyword filter is heuristic.** Captures only when the script name contains `test` / `build` / `typecheck` / `lint`. `bun run dev` (long-running server) is correctly skipped; `bun run frontend:test` is correctly captured; `bun run preflight` (a build-shaped script with a non-keyword name) is SKIPPED. The miss is acceptable — the human can extend via `CLAUDE_RUNTIME_INTROSPECT_EXTRA_DETECT` pre-launch (NOT settable mid-session by the agent; see gotcha below) or rename the script.
- **Concurrent Bash capture races.** Two parallel matched commands race the state file write. POSIX rename atomicity → no torn writes; last-writer-wins by design. The in-flight directory keeps per-invocation start marks separate so durations stay accurate even under concurrency.
- **Commit-message FP.** A heredoc'd commit body containing literal `bun test` would tokenise as a runner. The tokeniser only collects pair tokens at top-level command segments (after `&&` / `||` / `;` separators, not inside quoted strings). Recursive dogfood (committing the introspect spec itself) was the canonical test of this.
- **No `bun install` / `npm install` capture.** Those are dep mutations, not verifiers — this capacity captures *the act of verifying*, not *the act of installing*. Don't add install verbs to the detector list; the FP cost (any install would dilute the "latest test result" semantics) would erase the value.
- **`bun tsc --noEmit` exit code is verifier signal.** TypeScript's `tsc` returns 0 on clean, non-zero on errors — clean PASS/FAIL maps. Don't conflate this with the lint advisory in the validator (see `.claude/validators/run.sh`); this capacity surfaces the latest run, not the validator's per-edit signal.
- **`CLAUDE_RUNTIME_INTROSPECT_EXTRA_DETECT` glob shape.** Space-separated globs interpreted as `<tool>-<verb>` keys joined by hyphen (e.g. `make-test` → matches `make test`). Glob meta-chars beyond shell word-split are NOT supported in v1 — keep entries flat. If a consumer project needs richer matching, extend the parser; until then, prefer multiple flat entries.
- **`CLAUDE_RUNTIME_INTROSPECT_EXTRA_DETECT` is NOT settable mid-session by the agent (rshrnk dogfood B3 finding #6, 2026-05-12).** Both inline-prefix form (`VAR=val cargo test`) and same-Bash-call `export VAR=val; cargo test` fail to propagate the env to the hook. Root cause: when the agent runs a Bash tool call, the harness spawns a child shell to execute the command; in parallel, the harness spawns the registered `PostToolUse(Bash)` / `PostToolUseFailure(Bash)` hooks as **its own children** (siblings to the bash child, NOT children of it). Sibling processes do not inherit each other's env mutations — the hook reads the harness's env, not the bash child's. `settings.json` has no `env` injection mechanism. Consequence: the env-var extension path is reserved for the **human** — set in the parent shell before launching `claude`. Agents needing a new detector mid-session have no workaround; the correct fix is a follow-up spec extending the native detector pair list (the cargo case was the original trigger — closed by adding native `cargo test|build|check|clippy` detection). A theoretical mid-session injection mechanism (file-based extra-detect under `.agent0/.runtime-state/`) is a candidate spec only if symmetry between human-pre-launch and agent-mid-session becomes a real need for OTHER undetected stacks (gleam, deno, etc.); until then, native-detector extension is the canonical path.
- **Cargo workspaces use the same detector, no special handling.** A workspace with `[workspace.members]` walks all members on `cargo test` / `cargo check` / etc. by default. Each member crate emits its own `test result:` summary line, and cargo emits a single `Finished` line at the workspace level on clean completion. The inference table's first-FAIL-wins behavior is correct: any single `test result: FAILED` flips the overall snapshot to FAIL even if other crates passed. A workspace member that fails compilation surfaces an `error[E0xxx]:` or `^error:` line — same FAIL path. No multi-crate awareness needed in the hook; the monorepo-stack-detect capacity is the right place for multi-stack reasoning if it ever becomes a concrete need.
- **First-consumer friction.** A fresh consumer project that runs `bun test` for the first time will see no probe hint until session start. The capacity activates the moment the hooks are registered and `bun test` matches the allowlist — nothing in the consumer project's setup blocks this. The escape hatch (`CLAUDE_SKIP_RUNTIME_INTROSPECT=1`) is the per-session opt-out, not a permanent disable.
- **ANSI escape sequences in runner output stripped at storage (2026-05-12 dogfood).** Bun's test runner and many other modern verifiers emit colored output (e.g. `\e[32m 0 fail\e[0m`). Pre-fix, the line-anchored regex `^[[:space:]]*0 fail[[:space:]]*$` did NOT match because color codes prefixed the line, forcing inference to fall through to the weak `pass|✓|ok` keyword heuristic. Status was still PASS (correct outcome), but `inference_basis` read `pass/ok keyword (weak heuristic)` instead of the canonical `'0 fail' line` — degrading the auditable signal. Fix: `runtime-capture.sh` strips ANSI sequences (`\x1b\[[0-9;]*[a-zA-Z]`) from `STDOUT_RAW`/`STDERR_RAW` after collection, before storage AND inference. Stored snapshots now have clean text — LLM agents reading probe output don't render colors anyway, so the codes were pure noise. Regression guarded by test 16. The `printf x` sentinel trick is reused in the strip path so trailing newlines survive command substitution (test 04 asserts byte-exact `stdout_head`).

## Cross-references

- `.claude/rules/runtime-introspect.md` — consumer-facing companion (what fires, detector table, probe output shape, escape hatches)
- `.claude/hooks/runtime-capture.sh` / `.claude/hooks/runtime-pre-mark.sh` — implementation
- `.agent0/tools/probe.sh` — probe surface
