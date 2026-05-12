# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state

**Spec 022 (runtime-introspect-cargo) delivered.** Closes rshrnk B3 findings #1-5 (cargo test/build/check/clippy all returning `no-snapshot`). Hook now detects the 4 verifier cargo verbs and infers PASS/FAIL via canonical cargo output patterns (`test result: ok/FAILED` for cargo-test; `error[E\d+]:` / `^error:` / `Finished` line for cargo-check/build/clippy). Empirically verified end-to-end against rshrnk's real cargo output — Phase 3 findings in `docs/specs/022-runtime-introspect-cargo/tasks.md`. 15/15 runtime-introspect tests GREEN; synced to all 3 forks with `--force --force-except='.gitignore'`.

Commits this cycle:
- Agent0: `8e92c97 feat(runtime-introspect): spec 022 — cargo detector + Rust inference (closes rshrnk B3 findings #1-5)`
- rshrnk: `fb05ccc chore(harness-sync): adopt Agent0 spec 022 (cargo detector + Rust inference)`
- pyshrnk: `46eff1b chore(harness-sync): adopt Agent0 spec 022 (cargo detector + Rust inference)`
- shrnk: `ac13ea8 chore(harness-sync): adopt Agent0 spec 022 (cargo detector + Rust inference)`

Prior context: spec 013 dogfooded in pyshrnk + shrnk (commits `f2d002c` + `542d55c`); spec 021 delivered + 2 dogfoods (Agent0 host); spec 020 delivered + 3 dogfood passes (pyshrnk graduated, shrnk B2.2 graduated, rshrnk in progress now unblocked by 022); spec 019 scaffold in all forks.

## WIP

Nothing in flight. Spec 022 closed: design → impl → tests → docs → sync → 4 commits.

## Next steps

1. **rshrnk dogfood B3.2 (separate session in rshrnk).** First candidate 0-finding pass post-fix. Expected: cargo invocations now capture correctly, no detector gaps. ~30min.
2. **rshrnk dogfood B3.3 (separate session in rshrnk).** Second consecutive 0-finding pass → yield-decay graduation. ~20min.
3. **Spec 0YY runtime-introspect-extra-detect-injection (deferred).** Rshrnk finding #6 (EXTRA_DETECT mid-session inaccessibility) was the original trigger for proposing this spec — but spec 022 absorbed the immediate need (cargo) by extending the native detector list. 0YY still useful for the NEXT undetected stack (gleam, deno, hatch, bazel) but not blocking until a concrete real-world fork demand surfaces. Leave queued.
4. **Spec 021 in-fork dogfood** (LinkedIn/X dogfood was Agent0 host; in-fork pending). Low priority.
5. **Pyshrnk CLAUDE.md reconciliation** (carryover from prior session) — Starlette adoption was documented with spec-009 OVERRIDE marker but the "no frameworks" rule still says the opposite. Amend rule or revert Starlette.
6. **rshrnk Cargo.{lock,toml} carryover** (from prior session) — verified clean post-spec-022 sync; carryover resolved naturally.
7. **Specs 014 + 015** still in queue.

## Parallel WIP

- **paused (since 2026-05-11) — spec 010 audit-forensics scaffolded but never committed.** Paths: `docs/specs/010-audit-forensics/` (`spec.md` + `plan.md` + `tasks.md` stub). Owner-session ended in joint abandonment ("demanda real é zero — speculative observability, não 'preciso responder X e não consigo'"). Left untracked pending decision. **Other sessions: leave untouched.** Revisit only if a concrete forensic question against `.claude/*-audit.jsonl` surfaces; otherwise the next cleanup pass can delete the scaffold.

## Decisions & gotchas

- **Spec 022 design: native detector extension beats EXTRA_DETECT workaround.** Rshrnk finding #6 exposed that EXTRA_DETECT can only be set by the human pre-launch (harness spawns hooks as siblings to the bash child, env doesn't propagate). The canonical fix is extending the native pair list. Spec 022 does this cleanly for cargo; spec 0YY remains an option for future stacks but is no longer urgent.
- **Cargo PASS heuristic: `Finished` line, NOT 500-char cap.** Cargo output frequently exceeds 500 chars in multi-crate projects due to per-crate `Compiling ...` lines. The `[[:space:]]+Finished` anchor is more robust than the bun-tsc-style character count.
- **Spec 022 composes with spec 020.** Failing `cargo test` (exit 101) routes through PostToolUseFailure; spec 020's branch reads `.error` → `stderr_head`, then spec 022's `test result: FAILED` pattern matches in `combined_for_inference`. Composition verified empirically (Phase 3 case 4 — `cargo check --bin nonexistent_xyz`).
- **Tokenizer handles `--color=never` and other trailing flags correctly.** `cargo test --color=never` tokenizes as `[cargo, test, --color=never]`; the `cargo test` pair matches at i=0 before any flag inspection. Same for `cargo clippy --all-targets -- -D warnings`.
- **Spec 013 dogfood finding F1 — uv auto-sync collapses state-b.** Under `<py_prefix> = "uv run python"`, the probe `uv run python -m ruff --version` triggers uv's auto-resolve before invoking python. Adding ruff to `[dependency-groups]` causes uv to install transparently on the next run, bypassing the state-b advisory. Desirable ergonomics for uv-managed projects. Advisory still fires in poetry/pdm/pip-only/PATH-isolated CI.
- **Spec 013 dogfood finding F4 — `.claude/` must be linter-ignored.** Biome scan default includes `.claude/`; `biome check --write` reformats harness files that sync-harness later flags as customized hash drift. Forks adopting biome must ship a `biome.json` ignoring `.claude/**`. Documented in rule doc with snippet ready.
- **Spec 013 dogfood finding F5 — biome defaults are opinionated (tabs).** First `biome check --write` reformatted 11 files in shrnk. Forks should configure `formatter.indentStyle` in `biome.json` if they want to preserve conventions.
- **`browser_storage_state` / `browser_set_storage_state` do NOT exist in `@playwright/mcp@latest`** (carryover from spec 021). Save path: `browser_run_code_unsafe` calling `await page.context().storageState({ path })`. Reuse: `--storage-state=<file>` startup flag.
- **Playwright MCP sandbox blocks `require('fs')` / `await import('fs/promises')`** with `ERR_VM_DYNAMIC_IMPORT_CALLBACK_MISSING`. `--storage-state` startup is the canonical path.
- **`core.hooksPath` activation remains MANUAL by design** (Lazarus 2025). Spec 018 SessionStart hint surfaces the command passively.
- **SESSION.md ~2KB preview budget** — replace stale; `git log` is the audit trail.
