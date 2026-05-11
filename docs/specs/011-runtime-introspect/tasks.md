# 011 — runtime-introspect — tasks

_Generated from `plan.md` on 2026-05-11. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Phase 1 — Documented contract

- [x] 1. Draft `.claude/rules/runtime-introspect.md`. Sections: capacity intent (one paragraph mirroring `spec.md` § Intent), detector pair table (v1 list), `last-run.json` schema (one example object verbatim), probe output shape (PASS/FAIL/UNKNOWN + tail markers + stale flag), env vars (`CLAUDE_SKIP_RUNTIME_INTROSPECT`, `CLAUDE_RUNTIME_INTROSPECT_DEBUG`, `CLAUDE_RUNTIME_INTROSPECT_EXTRA_DETECT`), explicit non-goals (mirror `spec.md`), cross-references to `.claude/rules/supply-chain.md` (tokeniser-twin gotcha) and `.claude/rules/tdd.md` (loop reinforcement).

### Phase 2 — RED test suite (no implementation yet)

- [x] 2. Create `.claude/tests/runtime-introspect/` and copy the driver pattern from `.claude/tests/supply-chain/run-all.sh` into `.claude/tests/runtime-introspect/run-all.sh`. Driver runs every `NN-*.sh` in lex order, prints `PASS`/`FAIL`/`SKIP`, returns non-zero on any failure.
- [x] 3. Write `01-bun-test-capture.sh`. Feeds the capture hook a fixture `tool_input.command="bun test"` PostToolUse JSON with `tool_response.exit_code=0` and tiny stdout. Asserts `.claude/.runtime-state/last-run.json` is created, parses as JSON, and contains `command`, `exit`, `detector="bun-test"`, plus a non-empty `started_at`.
- [x] 4. Write `02-pytest-capture.sh`. Same shape, `pytest` command, asserts `detector="pytest"`.
- [x] 5. Write `03-skip-non-detect.sh`. Feeds `ls -la` payload. Asserts no `last-run.json` write and no audit file appended (the capacity writes no audit log by design).
- [x] 6. Write `04-tail-size-cap.sh`. Synthesises a 64 KB stdout blob in `tool_response`. Asserts captured `stdout_head` is exactly 4096 bytes, `stdout_tail` is exactly 4096 bytes, and a truncation marker field (`stdout_truncated: true`) is set.
- [x] 7. Write `05-stale-flag.sh`. Writes a `last-run.json` whose `started_at` precedes `.claude/.session-state/started-at`. Runs `bash .claude/tools/probe.sh last-run`, asserts output contains `stale: true`.
- [x] 8. Write `06-never-block.sh`. Makes `.claude/.runtime-state/` read-only (or points the hook at a non-writeable path via env override) and invokes the hook. Asserts exit 0, no stdout pollution, no stderr unless `CLAUDE_RUNTIME_INTROSPECT_DEBUG=1`.
- [x] 9. Write `07-probe-missing-state.sh`. Removes any pre-existing `last-run.json`. Runs `bash .claude/tools/probe.sh last-run`. Asserts exit 0 and a friendly empty-state message that names an example invocation (so the agent learns the loop).
- [x] 10. Write `08-env-extra-detect.sh`. With `CLAUDE_RUNTIME_INTROSPECT_EXTRA_DETECT="make test"`, feeds the hook a `make test` payload. Asserts capture happens and `detector="extra:make-test"` (or similar prefix that distinguishes it from the core allowlist).
- [x] 11. Run `bash .claude/tests/runtime-introspect/run-all.sh`. Confirmed 0/8 PASS — all RED (driver loop ran, every fixture returned FAIL via missing-hook / missing-probe path). Record exact failure shapes; this is the contract the implementation must satisfy.

### Phase 3 — Implementation

- [x] 12. Implement `.claude/hooks/runtime-pre-mark.sh` (PreToolUse(Bash)). Reads stdin JSON, extracts `tool_use_id`, writes `<id>.t` with current UTC ISO-8601 timestamp into `.claude/.runtime-state/in-flight/`. Skip silently if `tool_use_id` is empty. Always exit 0.
- [x] 13. Implement `.claude/hooks/runtime-capture.sh` (PostToolUse(Bash)). Phases (in order): escape hatch (`CLAUDE_SKIP_RUNTIME_INTROSPECT=1` → exit 0); stdin capture + jq availability; tokenise `tool_input.command` with the supply-chain-twin tokeniser (chain/pipe/redirect terminators, value-taking flag skip); match against the v1 detector pair list + `CLAUDE_RUNTIME_INTROSPECT_EXTRA_DETECT` globs; on no match → exit 0 silently; on match → read `tool_response.exit_code`, `tool_response.stdout`, `tool_response.stderr`; compute duration from the in-flight start mark (best-effort, `null` if missing); clamp each stream (4 KB head + 4 KB tail; set `*_truncated: true` when clamping engaged); write `.claude/.runtime-state/last-run.json` via `mktemp + mv`; remove the in-flight mark file. Diagnostic to stderr only when `CLAUDE_RUNTIME_INTROSPECT_DEBUG=1`. Always exit 0.
- [x] 14. Implement `.claude/tools/probe.sh`. Single `last-run` subcommand for v1. Reads `last-run.json` via jq, computes status (`PASS` exit==0, `FAIL` exit!=0, `UNKNOWN` exit missing/non-numeric), computes age from `started_at` vs now, computes `stale` by comparing `started_at` against `.claude/.session-state/started-at`. Emits structured plain-text block: header line with status/command/exit/age/stale, then explicit `--- stdout (head) ---` / `--- stdout (tail) ---` / `--- stderr ---` markers. Missing state → friendly empty-state message + example invocation; exit 0. Other subcommands → exit 2 with a one-line usage hint.
- [x] 15. Extend `.claude/hooks/session-start.sh` to append one hint line to its stdout block when `.claude/tools/probe.sh` exists: `Probe runtime evidence with: bash .claude/tools/probe.sh last-run`. Place it AFTER the existing SESSION.md / COMPACT_NOTES.md block. Guard the addition with a file-exists check so the existing capacity behaviour is unaffected when `probe.sh` is absent.
- [x] 16. Wire `.claude/settings.json`. Register `runtime-pre-mark.sh` on `PreToolUse` (matcher: `Bash`) and `runtime-capture.sh` on `PostToolUse` (matcher: `Bash`). Keep existing supply-chain hook entries above the new ones in the array — order doesn't matter for correctness, just for human scanability.
- [x] 17. Add `.claude/.runtime-state/` to `.gitignore`. (Sibling pattern to `.claude/.session-state/` and `.claude/.delegation-state/`.)
- [x] 18. Add new **Runtime introspect** § block to `CLAUDE.md` after the existing capacity blocks. One paragraph naming what fires, what's captured, how the agent queries, and the escape-hatch env var. Cross-link to `.claude/rules/runtime-introspect.md`.
- [x] 19. Run `bash .claude/tests/runtime-introspect/run-all.sh`. Confirmed 8/8 PASS — GREEN. Two test bugs surfaced during GREEN-ing (trailing-newline strip in bash command-sub; `set -e` aborting after non-zero subshell assignment) — fixed in tests 04 + 07; one impl fix (jq -j + printf-x sentinel preserving trailing newlines in STDOUT_RAW/STDERR_RAW round-trip).

### Phase 4 — Live dogfood on `/home/goat/shrnk`

- [x] 20. Dogfood pass 1. From `/home/goat/shrnk`, exercise: `bun test` (expect FAIL or PASS, doesn't matter — capture must work), then `bash /home/goat/Agent0/.claude/tools/probe.sh last-run` to read it back. Repeat for `bun tsc --noEmit` (typecheck shape). Repeat for `bun run typecheck` (script-name keyword path). Record findings in pass-1 notes (FP/FN, ergonomics gaps, tail-size right-sizing, hint discoverability).
- [x] 21. Pass 1 surfaced 4 findings → fixed in-place; added test 09 covering status inference. Re-ran suite → 9/9 GREEN. Findings: write a RED test for each (extends the suite), fix the implementation, re-run the full suite to GREEN. Commit fixes separately from the initial impl commit so dogfood deltas are auditable. Skip if pass 1 was 0-finding.
- [x] 22. Dogfood pass 2 + 3 (yield-decay graduation). Pass 2 (post-fix bun test): 0 findings, status PASS via inference. Pass 3 (variant bun test + bun tsc + bun run typecheck): 0 findings across all three, statuses PASS via routed inference branches. Two consecutive 0-finding passes → spec graduates per yield-decay rule. Same shrnk exercise, ideally on a sibling fork or after a `bun upgrade`. Apply yield-decay rule: two consecutive 0-finding passes → graduate. If non-zero findings → goto task 21.

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria. Each one maps to a checklist item there._

- [ ] V1. Scenario "test-runner output captured" — task 19 PASS for `01-bun-test-capture.sh` + manual confirmation that a real `bun test` from any project produces a valid `last-run.json`.
- [ ] V2. Scenario "Python test capture" — task 19 PASS for `02-pytest-capture.sh`.
- [ ] V3. Scenario "probe surfaces last failure" — task 19 PASS plus a manual `probe.sh last-run` invocation against a failing-test snapshot shows clear status + tail.
- [ ] V4. Scenario "probe flags stale snapshot" — task 19 PASS for `05-stale-flag.sh` + visual confirmation that the probe header line includes `stale: true` text.
- [ ] V5. Scenario "capture never blocks the underlying command" — task 19 PASS for `06-never-block.sh` + manual sanity that an intentionally noisy `bun test` doesn't change the Bash exit code reaching the agent.
- [ ] V6. Scenario "SessionStart hint injected" — start a fresh session, confirm the additional-context block includes the probe hint line.
- [ ] V7. Scenario "out-of-scope commands ignored" — task 19 PASS for `03-skip-non-detect.sh` + manual confirmation that `git status` / `ls` produce no state writes (`stat .claude/.runtime-state/last-run.json` mtime unchanged).
- [ ] V8. Static facts — `.claude/hooks/runtime-capture.sh`, `.claude/hooks/runtime-pre-mark.sh`, `.claude/tools/probe.sh`, `.claude/.runtime-state/` (in `.gitignore`), `.claude/rules/runtime-introspect.md`, `.claude/settings.json` entries, CLAUDE.md § block — all present and consistent with the spec.
- [ ] V9. Yield-decay graduation — two consecutive 0-finding dogfood passes on `/home/goat/shrnk` recorded in this file's Notes section.
- [ ] V10. SESSION.md refresh — final commit's SESSION.md reflects 011 delivered, graduation status, and the deferred Playwright/DevTools `.mcp.json.example` follow-up.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._

### Commit cadence

Suggested commit phases (one per natural rollback boundary):

1. `docs(011): runtime-introspect rule doc` — after task 1
2. `tests(011): RED — runtime-introspect capture + probe` — after task 11 (with 0/9 PASS confirmed in commit body)
3. `feat(011): runtime-introspect capture hook + probe tool` — after task 19 (with 9/9 PASS confirmed)
4. `fix(011): live-dogfood pass 1 adjustments` (if any) — after task 21
5. `chore: SESSION refresh — spec 011 delivered + yield-decay graduation` — after task 22

### Dogfood pass-1 findings (`/home/goat/shrnk`, 2026-05-11)

Real capture surfaced four mismatches between the test fixtures and Claude Code's actual payload:

1. **`tool_response.exit_code` does not exist.** Claude Code's Bash payload carries `{stdout, stderr, interrupted, isImage, noOutputExpected}`. Tests passed `exit_code` and assumed it; production runs always got `exit: null` → `status: UNKNOWN`. **Fix:** added `interrupted` read + per-detector output-pattern inference (`inferred_status` + `inference_basis`); probe uses inference when exit is null. Test 09 covers all branches.
2. **Top-level `duration_ms` IS in the payload** (real wall-clock ms). Hook was computing it from second-resolution date diffs (off by ~10x for sub-second runs). **Fix:** read `.duration_ms` from payload first; fall back to date-diff only when absent.
3. **`bun run <script>` detector was too coarse** — emitted just `bun-run`, inference table couldn't route to test/typecheck/build/lint branches, so `bun run typecheck` got `UNKNOWN`. **Fix:** sub-detector suffix (`bun-run-test`, `bun-run-typecheck`, etc.) routed to the matching inference case.
4. **tsc clean-output threshold was 200 bytes**, but `bun run typecheck` adds a `"$ bun tsc --noEmit"` prefix line (~25 bytes) so total exceeded threshold in the "no error keywords" branch fell through. **Fix:** raised to 500 bytes; still tight enough to avoid false PASS on large failing builds.

Documented in `.claude/rules/runtime-introspect.md` § Gotchas.

### Dogfood pass-2 findings (`/home/goat/shrnk`, 2026-05-11)

0 findings. Re-ran `bun test` post-fix: status PASS, inference "bun-test: '0 fail' line", duration 114 ms from harness, no schema or runtime surprises.

### Dogfood pass-3 findings (`/home/goat/shrnk`, 2026-05-11)

0 findings. Variant pass: `bun test` (PASS via '0 fail' line, 118 ms), `bun tsc --noEmit` (PASS via "clean: no error TS", 528 ms), `bun run typecheck` (PASS via "bun-run-typecheck clean", 553 ms). All three detector branches exercised, all inferences correct, no schema drift.

### Dogfood pass-1 findings (`/home/goat/pyshrnk`, 2026-05-11)

First pyshrnk-side dogfood pass — exercised the Python detector branch (`pytest`, `python -m pytest`) for the first time outside synthetic JSON fixtures. Surfaced ONE critical finding plus two operator-awareness observations:

1. **PostToolUse(Bash) does NOT fire when the underlying Bash command exits non-zero** — the foundational assumption of spec 011 (capture FAIL runs so the agent learns what failed) is violated by Claude Code's harness behavior. **Symptom:** running `uv run pytest -q` against a suite with failing tests (exit 1) produces NO `last-run.json` snapshot — the probe returns `status: no-snapshot`. Same behavior reproduced with `false` (exit 1, no output), `sh -c 'echo HELLO; exit 7'` (exit 7 with output), and a single failing pytest case (`uv run pytest -q tests/test_web.py::failing_test --tb=no`, exit 1, ~5 lines output). Output size is NOT the cause — exit code alone is. Verified via instrumented hook (logged stdin payload to `/tmp`): exit-0 commands ALL fire PostToolUse and reach the hook with full `tool_response`; exit-non-zero commands NEVER reach the hook (no log entry, no in-flight mark cleanup, no snapshot write). **Impact:** the workflow described in spec.md scenario "test-runner output captured" / "non-zero `exit` when the suite fails" doesn't work end-to-end on Claude Code today. Workaround the agent can apply: pipe through anything that swallows the exit code (`uv run pytest -q 2>&1 | tail -5`, `cmd | cat`, `cmd | tee /tmp/x`) — pipe makes the pipeline exit 0 and PostToolUse fires. **Proposed fix shape:** (a) document the limitation prominently in `.claude/rules/runtime-introspect.md` § Gotchas + the SessionStart hint line so agents know to pipe failing-likely commands; (b) consider a wrapper convention (`.claude/tools/run-verifier.sh <cmd>`) that always exits 0 + writes the captured payload directly, sidestepping the harness limitation; (c) upstream — file an issue against Claude Code asking PostToolUse(Bash) to fire on all exits (would also benefit other PostToolUse consumers like supply-chain-advise that may miss failing edits). The shrnk-side dogfood passes 1-3 did NOT surface this because every exercised invocation (`bun test` against a passing suite, `bun tsc --noEmit` clean, `bun run typecheck` clean) exited 0 — the entire validation surface was PASS-only. This finding is the strongest argument for ALWAYS exercising at least one FAIL case in any future fork dogfood pass.
2. **`uv run pytest` correctly tokenises and matches the `pytest` detector.** Even though `uv` and `run` precede the `pytest` token, the substring tokeniser (twin to supply-chain-scan) finds `pytest` as a token and proceeds. Confirmed: detector resolves to `pytest`, inference branch routes to the pytest table, both PASS (`'N passed' without failed`) and FAIL (`'N failed/error' in summary`) inferences fire correctly when the hook actually runs (i.e. exit 0). No detector-table changes needed for `uv run` invocations — flag this in case a future doc pass asserts otherwise.
3. **Synthetic-payload self-pollution gotcha (operator-side).** Manually invoking `bash .claude/hooks/runtime-capture.sh <<EOF ... pytest ... EOF` to test the hook in-place tokenises the heredoc body, matches `pytest`, and writes a snapshot whose `command` field is the entire test invocation (including the heredoc). Acceptable in isolation but easy to confuse with a "real" capture during debugging. Not a code fix — operator awareness only. Mention in any future "how to debug spec 011" runbook if one is written.

Inferences (when the hook fires) all routed correctly: `pytest` PASS via "'N passed' without failed", `pytest` FAIL via "'N failed/error' in summary", `pytest` UNKNOWN when output is just a number (e.g. `... | wc -l → "381"`). Harness `duration_ms` is populated (282 ms for a 16-test pass run, vs sub-second runs that would have rounded to 1000 ms via the date-diff fallback — same observation as shrnk pass 1). No schema drift, no detector-table gaps for the Python branch beyond finding #1's harness limitation.
