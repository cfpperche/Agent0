# 022 — runtime-introspect-cargo — tasks

_Generated from `plan.md` on 2026-05-12. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Phase 1 — RED tests

Three new scripts under the existing `.claude/tests/runtime-introspect/` directory. Phase 1 lands them BEFORE the hook edit so the test outputs explicitly mark the missing capability.

- [ ] 1. Write `.claude/tests/runtime-introspect/13-cargo-test-capture.sh` — exercises Scenarios A + B. Sub-case A: synthesized PostToolUse payload, `command="cargo test"`, `stdout="\nrunning 4 tests\ntest tests::shorten_resolve_roundtrip ... ok\ntest tests::idempotent_shorten ... ok\n... \n\ntest result: ok. 4 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s\n"`, `stderr` containing `   Compiling rshrnk v0.1.0 (...)\n    Finished `test` profile [unoptimized + debuginfo] target(s) in 0.12s\n`. Assert: `detector == "cargo-test"`, `inferred_status == "PASS"`, `inference_basis` contains `'test result: ok'`. Sub-case B: synthesized PostToolUseFailure payload (mirror test 11's shape — `hook_event_name: "PostToolUseFailure"`, `error: "<failing body>"`, `is_interrupt: false`), `command="cargo test --test spec022_dogfood"`, `error` containing `failures:\n\n---- tests::deliberate_failure stdout ----\n... \n\ntest result: FAILED. 0 passed; 1 failed; ...`. Assert: `detector == "cargo-test"`, `inferred_status == "FAIL"`, `inference_basis` contains `'test result: FAILED'`, `stderr_head` contains `1 failed`.
- [ ] 2. Write `.claude/tests/runtime-introspect/14-cargo-check-build-clippy.sh` — exercises Scenarios C, D, E, F, G via the `run_case` helper. Five sub-cases:
  - C: `command="cargo check"`, stdout/stderr `"   Compiling rshrnk v0.1.0 (...)\n    Finished `dev` profile [unoptimized + debuginfo] target(s) in 0.42s\n"`. Assert `detector == "cargo-check"`, `inferred_status == "PASS"`, basis contains `Finished`.
  - D: `command="cargo check"`, stderr contains `error[E0425]: cannot find value 'foo' in this scope\n  --> src/lib.rs:10:5\n... \n\nerror: could not compile `rshrnk` (lib) due to 1 previous error\n`. Assert `inferred_status == "FAIL"`, basis contains `error[E`.
  - E: `command="cargo clippy --all-targets -- -D warnings"`, output `"   Compiling rshrnk v0.1.0 (...)\n    Checking rshrnk v0.1.0 (...)\n    Finished `dev` profile [unoptimized + debuginfo] target(s) in 0.50s\n"`. Assert `detector == "cargo-clippy"`, `inferred_status == "PASS"`.
  - F: same command as E but output starts with `error: this function has too many arguments (8/7)\n  --> src/lib.rs:5:1\n... \n\nerror: could not compile `rshrnk` (lib) due to 1 previous error\n`. Assert `inferred_status == "FAIL"`, basis contains `^error:`.
  - G: `command="cargo build"`, output with `Finished` line. Assert `detector == "cargo-build"`, `inferred_status == "PASS"`.
- [ ] 3. Write `.claude/tests/runtime-introspect/15-cargo-skip-non-detect.sh` — exercises Scenario H. Mirror test 03's `run_skip_case` pattern. Subjects: `cargo run`, `cargo doc`, `cargo publish`, `cargo bench`, `cargo fmt`, `cargo update`, `cargo install ripgrep`. Each must NOT write `last-run.json` and the hook must exit 0.
- [ ] 4. Run `bash .claude/tests/runtime-introspect/run-all.sh` — confirm tests 13 + 14 + 15 FAIL (RED state). Tests 01-12 should continue passing (no regression introduced by the new files themselves).

### Phase 2 — GREEN: hook extension

- [ ] 5. Edit `.claude/hooks/runtime-capture.sh` Phase 2 detector match: add 4 cargo pair entries to the `case "$current $next" in` block immediately after the `yarn lint` entry (alphabetically convenient: `cargo` < `npm` < `pnpm` < `yarn`, but additions go after the existing entries to keep the diff small): `"cargo test")    detector="cargo-test"; break ;;`, `"cargo build")   detector="cargo-build"; break ;;`, `"cargo check")   detector="cargo-check"; break ;;`, `"cargo clippy")  detector="cargo-clippy"; break ;;`.
- [ ] 6. Edit `.claude/hooks/runtime-capture.sh` `infer_status()` function: add two new branches immediately after the existing `bun-tsc|yarn-typecheck|yarn-build|yarn-lint|*-run-typecheck|*-run-build|*-run-lint)` branch:
  - `cargo-test)` branch: `^test result: ok` → PASS (`inference_basis="$det: 'test result: ok' line"`); `^test result: FAILED` → FAIL (`inference_basis="$det: 'test result: FAILED' line"`).
  - `cargo-check|cargo-build|cargo-clippy)` branch: `error\[E[0-9]+\]` → FAIL (`inference_basis="$det: 'error[E...]' line"`); `^error:` → FAIL (`inference_basis="$det: '^error:' line"`); `[[:space:]]+Finished` → PASS (`inference_basis="$det: 'Finished' line, no errors"`).
- [ ] 7. Re-run `bash .claude/tests/runtime-introspect/run-all.sh` — confirm 15/15 GREEN.

### Phase 3 — Empirical verification

The hook in this session's CLAUDE_PROJECT_DIR is the fork's (rshrnk) copy, which the spec 022 edits have NOT touched yet — empirical "live event" verification requires either (a) syncing the new hook to rshrnk mid-session OR (b) invoking the updated Agent0 hook directly with synthesized payloads carrying real rshrnk cargo output.

- [ ] 8. Execute path (b): capture real rshrnk cargo output via separate Bash invocations (`cd /home/goat/rshrnk && cargo test 2>&1`, `cargo check 2>&1`, `cargo clippy --all-targets -- -D warnings 2>&1`). For each, synthesize a PostToolUse-shape JSON payload, pipe to `/home/goat/Agent0/.claude/hooks/runtime-capture.sh` with `CLAUDE_PROJECT_DIR` set to a tmp dir, verify `last-run.json` shape.
- [ ] 9. Document Phase 3 outcome in this file under § "Phase 3 verification (2026-05-12)" — which scenarios were exercised, what the snapshots looked like, any divergence from the test fixtures.

### Phase 4 — Documentation updates

- [ ] 10. Edit `.claude/rules/runtime-introspect.md` § "Detector pair list (v1)" — add a cargo row block to the table: `cargo test → cargo-test`, `cargo build → cargo-build`, `cargo check → cargo-check`, `cargo clippy → cargo-clippy`. Update the section name from "(v1)" since this is the v2 detector list, OR keep "(v1)" and add a note (decision: keep v1 — spec 022 extends the same baseline list, the version label refers to the design generation not the row count).
- [ ] 11. Edit `.claude/rules/runtime-introspect.md` § "Inference heuristics" — add a Rust paragraph documenting both new branches: `cargo-test` uses the canonical test-runner result line; `cargo-{check,build,clippy}` uses rustc compiler error patterns + cargo's `Finished` line as positive PASS signal.
- [ ] 12. Add a § Gotchas bullet noting that cargo workspaces use the same detector (no special handling; `cargo test` walks the workspace by default and emits one `test result:` line per workspace crate — first FAIL wins, all-PASS = PASS).
- [ ] 13. Cross-reference § Escape hatches `CLAUDE_RUNTIME_INTROSPECT_EXTRA_DETECT` paragraph: cargo is now natively detected, so the env-var workaround documented for the human-only constraint is less relevant for Rust forks. Other stacks (gleam, deno, etc.) still need the workaround.

### Phase 5 — Propagation + commit

- [ ] 14. Dry-run sync against all 3 forks: `bash .claude/tools/sync-harness.sh --apply --dry-run --force --force-except='.gitignore' --agent0-path=/home/goat/Agent0 /home/goat/pyshrnk` (then repeat for shrnk, rshrnk). Expected: `! overwritten .claude/hooks/runtime-capture.sh`, `! overwritten .claude/rules/runtime-introspect.md`, `+ copied .claude/tests/runtime-introspect/13-*.sh`, `14-*.sh`, `15-*.sh`. NOT expected: `docs/specs/` lines (specs stay Agent0-only), `.claude/memory/` lines.
- [ ] 15. Apply sync to all 3 forks with `--force --force-except='.gitignore'`. Commit per fork with message `chore(harness-sync): adopt Agent0 spec 022 (cargo detector + Rust inference)`.
- [ ] 16. Commit in Agent0: `feat(runtime-introspect): spec 022 — cargo detector + Rust inference (closes rshrnk B3 findings #1-5)`. Stage: hook + 3 tests + rule doc + spec 022 dir.
- [ ] 17. Update Agent0 `.claude/SESSION.md`: Current state mentions spec 022 delivered; Next steps mentions rshrnk B3.2 unblocked; Parallel WIP block for spec 010 (paused) left unchanged.

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria._

- [ ] **Scenarios A-H from spec.md** — covered by tests 13 (A+B), 14 (C+D+E+F+G), 15 (H); all GREEN in `run-all.sh`.
- [ ] **Static checks** — `runtime-capture.sh` carries 4 new cargo pair tokens; `infer_status()` carries 2 new branches; rule doc carries cargo row in pair list table + Rust inference paragraph; tests 13/14/15 exist + executable.
- [ ] **Full driver green** — `bash .claude/tests/runtime-introspect/run-all.sh` exits 0 (15/15 PASS post-impl).
- [ ] **All three shrnks synced + committed** — pyshrnk, shrnk, rshrnk each have a sync commit; `--check` exits 0 in each post-sync.
- [ ] **Empirical proof end-to-end (Phase 3)** — at least one real cargo invocation against rshrnk routed through the updated hook produces a correct snapshot; outcome documented in § Phase 3 verification below.

## Notes

- Spec 022's edit is genuinely small (4 pair tokens + 2 inference branches). Most of the file count is tests + docs, which is the expected ratio for a runtime-introspect extension (precedent: spec 020 was also a tiny code change wrapped in tests + docs + sync).
- The yield-decay rule: rshrnk B3 surfaced 8 findings → after this spec lands, B3.2 is the first candidate 0-finding pass → B3.3 is the second consecutive (graduation). Estimated 1-2h for spec 022 + ~30min B3.2 + ~20min B3.3 = ~2.5h total. Both dogfood passes happen in separate sessions, post-merge.

### Phase 3 verification (2026-05-12)

Empirically verified the updated Agent0 hook against four real rshrnk cargo invocations. Approach: ran the canonical verifiers in rshrnk, captured stdout/stderr verbatim, synthesized PostToolUse / PostToolUseFailure payloads with the real output, piped to `/home/goat/Agent0/.claude/hooks/runtime-capture.sh` with `CLAUDE_PROJECT_DIR` set to a tmp dir, asserted snapshot contents. This isolates the new hook code from the still-stale rshrnk-side copy (the live hook running in the rshrnk session is the pre-sync copy until Phase 5 propagates the update).

Results:

| Invocation | Path | detector | inferred_status | inference_basis |
| --- | --- | --- | --- | --- |
| `cargo test --color=never` (passing, 4 tests across 2 binaries) | PostToolUse | `cargo-test` | `PASS` | `cargo-test: 'test result: ok' line` |
| `cargo check --color=never` (clean) | PostToolUse | `cargo-check` | `PASS` | `cargo-check: 'Finished' line, no errors` |
| `cargo clippy --all-targets --color=never -- -D warnings` (clean) | PostToolUse | `cargo-clippy` | `PASS` | `cargo-clippy: 'Finished' line, no errors` |
| `cargo check --bin nonexistent_xyz` (real `error: no bin target ...`) | PostToolUseFailure | `cargo-check` | `FAIL` | `cargo-check: '^error:' line` |

Confirmations:

1. **Tokenizer handles `--color=never` and other flags correctly.** `cargo test --color=never` tokenizes as `[cargo, test, --color=never]`; the `cargo test` pair matches at i=0 before any flag inspection.
2. **Real rshrnk `test result: ok` line is anchored at start-of-line.** The leading whitespace from cargo's compile messages is on prior lines; the `test result:` summary itself is start-of-line, satisfying the `^test result: ok` regex.
3. **Cargo's `Finished` line has leading whitespace** (`    Finished `dev` profile ...`), matched by `[[:space:]]+Finished`. Both `cargo check` and `cargo clippy` clean output is identical in shape — one line, ~80 chars, no errors. The Finished-line heuristic is more robust than the 500-char short-output heuristic the bun-tsc branch uses (cargo can easily exceed 500 chars in multi-crate projects, but the Finished line is invariant).
4. **Composition with spec 020 (PostToolUseFailure) works.** The `cargo check --bin nonexistent_xyz` failure routes `.error` → `stderr_head` correctly via spec 020's branch, then spec 022's `^error:` pattern matches in `combined_for_inference` and assigns FAIL with the specific basis. The spec 020 FAIL-default safety net (event-authoritative) is not needed for this case because pattern inference succeeds — but its presence guarantees correctness for any future cargo error shape we haven't pattern-matched yet.

No divergence from the test fixtures. No bugs in the hook surface. Phase 3 closes cleanly.

A FAIL `cargo test` case was NOT exercised empirically in Phase 3 because creating a deliberately-failing test would have polluted rshrnk's `tests/` directory; the equivalent end-to-end shape is covered by test 13 sub-case B with a spec-realistic synthesized failure body. Acceptable trade-off.
