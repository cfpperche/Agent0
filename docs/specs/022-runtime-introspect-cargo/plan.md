# 022 — runtime-introspect-cargo — plan

_Drafted from `spec.md` on 2026-05-12. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Surgical extension of `.claude/hooks/runtime-capture.sh`. Two edit sites:

1. **Phase 2 detector match** — add 4 cargo pairs to the existing `case "$current $next" in` block (mechanical, mirrors the existing `bun test|tsc`, `npm test`, `yarn build|typecheck|lint` pattern).
2. **`infer_status()` function** — add 2 new `case "$det" in` branches: `cargo-test` (test result line patterns) and `cargo-check|cargo-build|cargo-clippy` (compiler-error patterns + Finished-line PASS).

The else-branch of every existing pattern is preserved byte-for-byte. Tests 01-12 are untouched and must remain GREEN. The new tests 13-15 exercise the three new scenarios.

No settings.json change (the existing PostToolUse + PostToolUseFailure registrations from specs 011 + 020 already route cargo invocations to the hook; the only gap is the hook's internal detector match). No new env vars. No new state files. No new hooks. The whole surface is two small additions inside one existing file.

## Files to touch

**Create:**
- `.claude/tests/runtime-introspect/13-cargo-test-capture.sh` — exercises Scenarios A + B: synthesized PostToolUse payload with `cargo test` + passing `test result: ok` output → assert `detector: cargo-test`, `inferred_status: PASS`; synthesized PostToolUseFailure payload with `cargo test` + failing `test result: FAILED` body → assert `detector: cargo-test`, `inferred_status: FAIL`.
- `.claude/tests/runtime-introspect/14-cargo-check-build-clippy.sh` — exercises Scenarios C, D, E, F, G: clean check (PASS via Finished), check with `error[E0xxx]:` (FAIL via compiler error), clean clippy `-D warnings` (PASS via Finished), clippy with promoted-warning `^error:` line (FAIL), clean build (PASS via Finished). Each via the `run_case` helper pattern from test 09.
- `.claude/tests/runtime-introspect/15-cargo-skip-non-detect.sh` — exercises Scenario H: `cargo run`, `cargo doc`, `cargo publish`, `cargo bench`, `cargo fmt`, `cargo update`, `cargo install ripgrep` all skip silently (no state file written). Mirrors test 03's skip-not-detect pattern.

**Modify:**
- `.claude/hooks/runtime-capture.sh` — two surgical additions:
  - In the Phase 2 `case "$current $next" in` block, after the existing `yarn lint` entry, add: `"cargo test")  detector="cargo-test"; break ;;`, `"cargo build")  detector="cargo-build"; break ;;`, `"cargo check")  detector="cargo-check"; break ;;`, `"cargo clippy")  detector="cargo-clippy"; break ;;`.
  - In the `infer_status()` function, add two new case branches after the existing `bun-tsc|yarn-typecheck|...` branch. `cargo-test` matches `^test result: ok` → PASS and `^test result: FAILED` → FAIL (test runner result line is canonical, anchored to start-of-line). `cargo-check|cargo-build|cargo-clippy` matches `error\[E[0-9]+\]:` → FAIL (rustc compiler error shape), `^error:` → FAIL (clippy promoted-warning shape + rustc fatal errors), and a positive `[[:space:]]+Finished` line as the PASS signal (more robust than bun-tsc's `<500 chars` heuristic — cargo output frequently exceeds 500 chars in real projects due to per-crate `Compiling ...` lines).
- `.claude/rules/runtime-introspect.md` — extend § Detector pair list (v1) with a cargo row block (`cargo test → cargo-test`, etc.); extend § Inference heuristics with a Rust branch documenting both case-arms; add a gotcha bullet noting that cargo workspaces use the same detector with no special handling (multi-crate is a property of cargo's output, not of the hook).

**Delete:**
- None.

## Alternatives considered

### Match all cargo verbs generically (`cargo *`)

Rejected — exact mirror of spec 011's "strict pair list beats generous regex" lesson. A generic match would capture `cargo doc`, `cargo run`, `cargo publish` etc., diluting the "latest verifier evidence" semantics. The strict allowlist is the right shape and matches the precedent set for `bun run` keyword filtering.

### Add `cargo run` detection with a keyword filter (analogous to `bun run <script-with-test-keyword>`)

Rejected for v1 because cargo doesn't have a script-name convention like bun's package.json scripts. `cargo run --bin foo` runs a binary, not a verifier — there's no "test"-named binary convention in the ecosystem. If a project does name a verifier binary, the operator can use `CLAUDE_RUNTIME_INTROSPECT_EXTRA_DETECT="cargo-run"` pre-launch as a workaround.

### Use the bun-tsc `<500 chars and no error/fail` heuristic for cargo-check/build/clippy

Rejected because cargo's default output (per-crate `Compiling` lines) easily exceeds 500 chars in a multi-crate project. The 500-char limit was chosen for `tsc --noEmit` clean output, which is genuinely empty when clean. For cargo, the `Finished` line is the canonical positive signal — anchoring on that is more robust and matches cargo's actual output structure. The short-output fallback could still help in `cargo check --message-format=short` cases but is not required for the canonical scenarios; including it as a fallback after the Finished-line check is acceptable but not load-bearing.

### Add an audit log of detector matches

Rejected — same posture as spec 011 v1. The state file (`last-run.json`) is self-sufficient; no audit log was added in 011 and there's no new forensic question spec 022 introduces that would change that calculus.

### Solve the EXTRA_DETECT mid-session inaccessibility (rshrnk finding #6) in this spec

Rejected — separate concern, separate spec (proposed 0YY). Adding cargo natively absorbs the immediate need; the env-var-only constraint remains for OTHER undetected stacks (gleam, deno, hatch, bazel, etc.). Spec 022 stays scoped to detector list extension to keep the diff surgical.

## Risks and unknowns

- **`Finished` line variability.** Cargo's clean-completion line includes the profile name (`dev` / `release` / `test`) and target description, which varies by invocation. The match regex (`[[:space:]]+Finished`) anchors on the leading whitespace + literal `Finished` — robust to profile/target variation. Verified empirically by running `cargo check`, `cargo test`, `cargo build` against rshrnk: all emit the same prefix shape.
- **`error[E\d+]:` vs `^error:` ordering.** A failing rustc emits BOTH shapes — `error[E0xxx]:` lines for individual errors AND a `^error: could not compile ...` summary line. Either matches FAIL; the first match wins (the `error[E...]` check runs first). Both basis strings are valid; the `error[E...]` basis is more specific.
- **`cargo test --quiet` minimal output.** The `^test result: ok` line is still emitted in `--quiet` mode (`cargo` docs verified). Tests 13's `run_case "cargo test --quiet"` exercise validates the anchor.
- **Composition with spec 020 (PostToolUseFailure).** Scenario B relies on spec 020's `HOOK_EVENT_NAME == "PostToolUseFailure"` branch correctly routing `.error` → `STDERR_RAW`. Spec 022's inference patterns match against `combined_for_inference = STDOUT_RAW + STDERR_RAW`, so the cargo failure body lands in the inference stream regardless of which event carried it. Verified in test 13's PostToolUseFailure case.
- **First-fork sync.** Spec 022 syncs to 3 forks via sync-harness. The hook file is one of the hash-compared files; forks that have customized `runtime-capture.sh` will refuse without `--force`. None of the 3 forks have customized it (verified by `sha256sum` parity in spec 020's sync pass). `--force --force-except='.gitignore'` is the canonical apply shape, matching every other spec.
- **Rshrnk graduation timing.** Spec 022 enables but does NOT execute B3.2 / B3.3. After merge, rshrnk runs B3.2 (first candidate 0-finding pass post-fix) and B3.3 (second consecutive) in separate sessions. Out of scope for this spec.

## Research / citations

- Codebase: `.claude/hooks/runtime-capture.sh` — verified Phase 2 detector match shape + `infer_status()` switch shape; both are extension-friendly with mechanical additions.
- Codebase: `.claude/tests/runtime-introspect/09-status-inference.sh` — verified the `run_case` helper pattern + synthesized payload shape for inference tests.
- Codebase: `.claude/tests/runtime-introspect/11-failure-path-capture.sh` — verified the PostToolUseFailure-shape payload synthesis for Scenario B (test 13's second case).
- Codebase: `.claude/tests/runtime-introspect/03-skip-non-detect.sh` — verified the skip-not-detect pattern for Scenario H (test 15).
- Empirical: rshrnk's actual cargo output for `cargo test` (pass), `cargo check`, `cargo clippy --all-targets -- -D warnings` (pass) — captured during rshrnk B3 dogfood (commit f400bfc); referenced verbatim for test fixtures.
- Live evidence: rshrnk dogfood B3 findings #1-5 in `docs/specs/011-runtime-introspect/tasks.md` — empirical reproduction of the detector gap.
- External docs: <https://doc.rust-lang.org/cargo/commands/cargo-test.html> — `test result:` line shape (canonical, stable since cargo's earliest releases).
- External docs: <https://doc.rust-lang.org/error-index.html> — `error[E0xxx]:` compiler error code shape (stable since rustc 1.0).
