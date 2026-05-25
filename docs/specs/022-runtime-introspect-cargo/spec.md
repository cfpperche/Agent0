# 022 — runtime-introspect-cargo

_Created 2026-05-12._

**Status:** shipped

## Intent

Spec 011 (runtime-introspect) ships a v1 detector pair list covering Bun, npm, pnpm, yarn, pytest, and unittest. The list deliberately omits cargo — Rust was out of scope for the initial spec because no Agent0 fork was Rust-native at the time. Rshrnk (the third sibling fork, Rust + cargo) added itself to the picture on 2026-05-12; its first dogfood pass (commit f400bfc, mirrored in `docs/specs/011-runtime-introspect/tasks.md` § "Dogfood pass-1 findings (`/home/goat/rshrnk`, 2026-05-12)") empirically confirmed five gap findings (#1-5):

1. `cargo test` (passing) → `probe.sh last-run` returns `status: no-snapshot`.
2. `cargo test` (failing, exit 101) → `no-snapshot`. PostToolUseFailure event registration (spec 020) is correctly synced in rshrnk's `.claude/settings.json`, but the skip-not-detect short-circuit runs BEFORE the event-specific FAIL-default branch is reached — the detector mismatch happens first. Spec 020 is orthogonal but inert when the runner isn't detected at all.
3. `cargo build` (clean) → `no-snapshot`.
4. `cargo check` (clean) → `no-snapshot`.
5. `cargo clippy --all-targets -- -D warnings` (clean) → `no-snapshot`.

Spec 022 closes the gap with a surgical extension to `.claude/hooks/runtime-capture.sh`: add four cargo pairs (`cargo test|build|check|clippy`) to the detector match in Phase 2, plus two new branches in `infer_status()` that recognise cargo's canonical output patterns (`test result: ok` / `FAILED` for cargo-test; `error[E\d+]:` / `^error:` / `Finished` line for cargo-{check,build,clippy}). Same shape as the existing Bun and Python branches — mechanical extension, zero new infrastructure.

Spec 022 does NOT solve the related but orthogonal gap surfaced in rshrnk finding #6 (`CLAUDE_RUNTIME_INTROSPECT_EXTRA_DETECT` is human-pre-launch-only, not mid-session-writable by agents). Adding cargo natively absorbs the immediate need; the mid-session-injection capability is deferred to a separate follow-up spec (proposed `spec 0YY runtime-introspect-extra-detect-injection`).

## Acceptance criteria

- [ ] **Scenario A: `cargo test` (passing) captures snapshot**
  - **Given** `.claude/hooks/runtime-capture.sh` carries the cargo detector pair list and Rust inference branches
  - **When** the hook receives a PostToolUse payload with `tool_input.command = "cargo test"` and `tool_response.stdout` containing `test result: ok. N passed; 0 failed`
  - **Then** `.claude/.runtime-state/last-run.json` is written with `detector: "cargo-test"`, `inferred_status: "PASS"`, `inference_basis: "cargo-test: 'test result: ok' line"`

- [ ] **Scenario B: `cargo test` (failing) captures snapshot via PostToolUseFailure**
  - **Given** spec 020's PostToolUseFailure registration is in place AND spec 022's cargo detector is in place
  - **When** the hook receives a PostToolUseFailure payload with `tool_input.command = "cargo test"` and `.error` containing `test result: FAILED. N passed; M failed` (e.g. exit 101)
  - **Then** snapshot is written with `detector: "cargo-test"`, `inferred_status: "FAIL"`, `inference_basis: "cargo-test: 'test result: FAILED' line"`, failure body in `stderr_head`

- [ ] **Scenario C: `cargo check` (clean) captures snapshot**
  - **Given** same hook state
  - **When** payload has `command = "cargo check"` and combined stdout+stderr contains the cargo `Finished` line with no `error[E...]:` or `^error:` lines
  - **Then** snapshot is written with `detector: "cargo-check"`, `inferred_status: "PASS"`, `inference_basis: "cargo-check: 'Finished' line, no errors"`

- [ ] **Scenario D: `cargo check` (errors) captures snapshot**
  - **Given** same hook state
  - **When** payload has `command = "cargo check"` and combined output contains `error[E0xxx]:` lines (rustc compiler error shape)
  - **Then** snapshot with `detector: "cargo-check"`, `inferred_status: "FAIL"`, `inference_basis: "cargo-check: 'error[E...]' line"`

- [ ] **Scenario E: `cargo clippy -- -D warnings` (clean) captures snapshot**
  - **Given** same hook state
  - **When** payload has `command = "cargo clippy --all-targets -- -D warnings"` and combined output contains `Finished` line with no errors
  - **Then** snapshot with `detector: "cargo-clippy"`, `inferred_status: "PASS"`, `inference_basis: "cargo-clippy: 'Finished' line, no errors"`

- [ ] **Scenario F: `cargo clippy -- -D warnings` (warnings as errors) captures snapshot**
  - **Given** same hook state
  - **When** payload has `command = "cargo clippy --all-targets -- -D warnings"` and combined output contains `^error:` lines (warnings promoted to errors)
  - **Then** snapshot with `detector: "cargo-clippy"`, `inferred_status: "FAIL"`, `inference_basis: "cargo-clippy: '^error:' line"`

- [ ] **Scenario G: `cargo build` (clean) captures snapshot**
  - **Given** same hook state
  - **When** payload has `command = "cargo build"` with `Finished` line, no errors
  - **Then** snapshot with `detector: "cargo-build"`, `inferred_status: "PASS"` (same inference branch as cargo-check)

- [ ] **Scenario H: non-verifier cargo verbs skip silently**
  - **Given** same hook state
  - **When** payload has `command` matching `cargo run`, `cargo doc`, `cargo publish`, `cargo bench`, `cargo update`, `cargo install <x>`, or `cargo fmt`
  - **Then** the hook exits 0, NO snapshot is written, NO state file mutation occurs

- [ ] `.claude/hooks/runtime-capture.sh` carries 4 new pair tokens (`cargo test|build|check|clippy`) in the Phase 2 detector match.
- [ ] `.claude/hooks/runtime-capture.sh` carries 2 new branches in `infer_status()`: `cargo-test` (test result line) and `cargo-check|cargo-build|cargo-clippy` (error patterns + Finished-line PASS).
- [ ] `.claude/tests/runtime-introspect/` extended with 3 new tests (13-cargo-test-capture, 14-cargo-check-build-clippy, 15-cargo-skip-non-detect) — all GREEN; tests 01-12 continue GREEN.
- [ ] `.claude/rules/runtime-introspect.md` updated: § Detector pair list adds cargo rows; § Inference heuristics adds Rust branch documentation.
- [ ] Synced to all 3 forks (pyshrnk, shrnk, rshrnk); rshrnk dogfood B3.2 candidate-graduation pass scheduled separately.

## Non-goals

- **Spec 0YY runtime-introspect-extra-detect-injection.** Mid-session-writable EXTRA_DETECT path (rshrnk finding #6) is a separate concern. Spec 022 reduces the immediate need by absorbing cargo natively but does NOT change the env-var-only constraint for OTHER undetected stacks.
- **`cargo bench` detection.** Low usage in practice; runners that exercise benchmarks are rarely the agent's verification path. Defer to a follow-up spec if real fork demand surfaces.
- **`cargo run` / `cargo doc` / `cargo publish` / `cargo fmt` detection.** These are not verifiers — `cargo run` is a process launcher (analog of `bun run dev`), `cargo doc` generates documentation, `cargo publish` is a release action, `cargo fmt` is a formatter (becomes a verifier only with `--check`, low priority). Treat as out-of-scope same way `bun run dev` is.
- **`cargo update` / `cargo install` detection.** These mutate dependencies — supply-chain capacity's territory (spec 008/009), not runtime-introspect's. The supply-chain hook already gates them; runtime-introspect adding them would double-capture and dilute the "latest verification" semantics.
- **Cargo workspace multi-crate awareness.** A workspace with `[workspace.members]` doesn't change the verifier's invocation shape (`cargo test` walks the workspace by default). The detector matches identically regardless. Multi-crate inference cleanliness is a property of cargo's output, not of spec 022. Spec 015 (monorepo-stack-detect) is the right place for multi-stack reasoning if it ever becomes a concrete need.
- **Cargo.toml signal in mcp-recipes.** Rshrnk finding #8 (separate from #1-5) proposed adding Rust-stack signals to the mcp-recipes hint hook (spec 012). That is a separate concern; spec 022 is scoped to runtime-introspect (spec 011) only.
- **Auto-graduating rshrnk dogfood passes.** Rshrnk needs two consecutive 0-finding passes (B3.2 + B3.3) to graduate. Spec 022 delivery enables B3.2 to be the first candidate; graduation is downstream of this spec.

## Open questions

- [ ] **`Finished` line heuristic for clean PASS.** Cargo's default output emits `    Finished `dev` profile [unoptimized + debuginfo] target(s) in N.NNs` on clean completion. The check-build-clippy branch uses presence-of-Finished as the positive PASS signal (no error patterns AND Finished present → PASS). Edge case: a cached build where cargo skips compilation may still emit Finished — same result, PASS, correct. A build that ERRORS may also emit Finished before the error in some output orderings — but the error patterns (`error[E...]` / `^error:`) are checked FIRST, so the error path wins. Verified in tests 14.
- [ ] **`cargo test --quiet` vs default verbosity.** `--quiet` produces minimal output; `test result: ok` line is still emitted. Default verbosity includes individual test names. Both shapes match the `^test result:` anchor. Verified in tests 13.
- [ ] **`cargo test --no-fail-fast` behavior.** Multiple test binaries each emit their own `test result:` line. The FAIL match wins on first occurrence (any single `test result: FAILED` triggers FAIL). Acceptable — the agent should fix any failing test binary regardless of others passing.

## Context / references

- `docs/specs/011-runtime-introspect/` — the v1 spec this extends. Spec 011's v1 detector pair list omits cargo; spec 022 closes that omission.
- `docs/specs/011-runtime-introspect/tasks.md` § "Dogfood pass-1 findings (`/home/goat/rshrnk`, 2026-05-12)" — empirical evidence motivating this spec (findings #1-5).
- `docs/specs/020-runtime-capture-on-failure/` — the PostToolUseFailure registration spec; spec 022's failing-cargo Scenario B depends on its FAIL-default branch composing with the new detector.
- `.claude/rules/runtime-introspect.md` § Detector pair list (v1) + § Inference heuristics — the doc that gains the cargo rows.
- `.claude/hooks/runtime-capture.sh` — the hook being extended; Phase 2 detector match + `infer_status()` are the only edit sites.
- `.claude/tests/runtime-introspect/09-status-inference.sh` — template for the new inference tests.
- `.claude/tests/runtime-introspect/11-failure-path-capture.sh` — template for the new PostToolUseFailure scenario in test 13.
- `.claude/tests/runtime-introspect/03-skip-non-detect.sh` — template for test 15 (skip-not-detect scenario).
- Rustc / cargo output reference: <https://doc.rust-lang.org/cargo/commands/cargo-test.html> for test runner output shape; <https://doc.rust-lang.org/error-index.html> for `error[E0xxx]:` compiler error shape.
