# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state

**B-series complete — pyshrnk + shrnk + rshrnk all graduated under yield-decay rule.** rshrnk closed today via B3.2 (`86797b5`, 0 findings) + B3.3 (`ced0389`, 0 findings) post spec 022. End-to-end empirical proof of spec 011/020/022 stack across Python (pytest), JS/TS (bun test), and Rust (cargo test/check/clippy).

This cycle's deliveries:
- **Spec 022 (runtime-introspect-cargo)** — Agent0 `8e92c97` + sync triplet `fb05ccc`/`46eff1b`/`ac13ea8`. Hook detects 4 cargo verifiers; Rust inference via `test result: ok/FAILED` and `[[:space:]]+Finished` anchor. 15/15 runtime-introspect tests GREEN.
- **Doc fix: EXTRA_DETECT human-only-pre-launch** (`44ebdb2` + sync `7d4f3c4`/`e57864e`/`1a5e9d3`) — clarifies the env var doesn't propagate to mid-session hooks (hooks are harness-siblings, not Bash children).
- **Parallel WIP convention** (`f0be6b3`) — registered as `.claude/rules/session-handoff.md § Parallel WIP coordination`. Validated empirically during this session (spec 021 + 3 dogfoods running in parallel, zero collision).
- **Spec 010 paused in Parallel WIP block** (`5e513d1`) — audit-forensics scaffold abandoned 2026-05-11, registered with defer instruction.

Prior context: spec 013 dogfooded in pyshrnk + shrnk; spec 021 delivered + 2 dogfoods (Agent0 host); spec 020 delivered; spec 019 scaffold in all forks.

## WIP

Nothing in flight. B-series closed.

## Next steps

1. **Spec 0YY runtime-introspect-extra-detect-injection (deferred).** Finding #6 from rshrnk B3 (EXTRA_DETECT mid-session inaccessibility) remains. Not blocking — spec 022 absorbed the immediate cargo need. Revisit when a NEW undetected stack appears (gleam, deno, hatch, bazel).
2. **Spec 021 in-fork dogfood** (LinkedIn/X dogfood was Agent0 host; in-fork pending). Low priority.
3. **Pyshrnk CLAUDE.md reconciliation** — Starlette adoption documented with spec-009 OVERRIDE; rule "no frameworks" still says opposite. Amend rule or revert Starlette.
4. **Specs 014 + 015** still in queue (mcp-recipes-extras + monorepo-stack-detect).
5. **Spec 010 (paused in Parallel WIP)** — decide eventually: delete scaffold or revive on real demand.

End-of-session carryover: unstaged `.gitignore` addition (`prototypes/` ignore) — not from this session's work; left for owner-session to commit or revert.

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
