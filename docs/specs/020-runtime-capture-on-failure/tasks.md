# 020 — runtime-capture-on-failure — tasks

_Generated from `plan.md` on 2026-05-11. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Phase 1 — RED tests

Two new scripts under the existing `.claude/tests/runtime-introspect/` directory (no new test dir — this is a fix to spec 011, not a new capacity).

- [x] 1. Write `.claude/tests/runtime-introspect/11-failure-path-capture.sh` — fixture: tmp `$CLAUDE_PROJECT_DIR` with `.claude/.runtime-state/`. Synthesize a JSON payload mirroring the assumed PostToolUseFailure shape: `{tool_name: "Bash", tool_input: {command: "uv run pytest -q"}, tool_response: {stdout: "...", stderr: "1 failed in 0.05s\n", interrupted: false, isImage: false, noOutputExpected: false}, session_id: "spec020-test", tool_use_id: "tool-use-spec020"}`. Pipe to `runtime-capture.sh`. Assert: (a) hook exits 0, (b) `last-run.json` is created, (c) JSON contains `command: "uv run pytest -q"`, `detector: "pytest"`, `inferred_status: "FAIL"`, `inference_basis` matches pytest-failure pattern, (d) `stderr_head` contains the failure summary.
- [x] 2. Write `.claude/tests/runtime-introspect/12-settings-registration.sh` — `jq` parse `$AGENT0_ROOT/.claude/settings.json`, assert: (a) `.hooks.PostToolUseFailure` is present, (b) at least one entry has `matcher == "Bash"`, (c) at least one of those entries' `hooks[].command` references `runtime-capture.sh`. Pure static-fact verification, no hook execution.
- [x] 3. Run `bash .claude/tests/runtime-introspect/run-all.sh` — confirm tests 11 + 12 FAIL (RED state). Tests 01-10 should continue passing (no regression). _Result: tests 01-10 + 11 PASS, 12 FAIL (the synthesized PostToolUse-shape payload exercised the hook directly; only the settings registration check 12 was RED). Test 11 was later updated to use the production-shape PostToolUseFailure payload — re-induced RED for 11 until the hook divergence-branch landed in Phase 3._

### Phase 2 — GREEN: settings.json registration

- [x] 4. Read current `.claude/settings.json`. Inspect the existing `hooks.PostToolUse` array entry for Bash. Mirror its shape (matcher + command) under a new `hooks.PostToolUseFailure` array. Single new entry: `{matcher: "Bash", hooks: [{type: "command", command: "bash $CLAUDE_PROJECT_DIR/.claude/hooks/runtime-capture.sh"}]}`.
- [x] 5. Re-run `bash .claude/tests/runtime-introspect/run-all.sh` — test 12 now PASSES. Test 11 should also PASS (the synthesized payload exercises the hook directly, doesn't require live event registration). If test 11 still fails, the hook is rejecting the synthesized payload — investigate (likely an inference-table miss or stderr-pattern mismatch). _Result: 12/12 GREEN at this point with the original PostToolUse-shape test 11. Then test 11 was updated to use the production PostToolUseFailure-shape payload — see Phase 3._

### Phase 3 — Empirical verification on Agent0

The settings.json change requires a NEW Claude Code session for the registration to take effect (per the `.claude/rules/session-handoff.md` § "SessionStart hook registration is per-session" gotcha pattern). Verify production behavior in this same conversation OR document the verification gap and rely on pyshrnk dogfood pass 2 as the production proof.

- [x] 6. Attempt empirical verification in this session: deliberate failure injection — run a failing pytest-shape command directly via Bash tool, then probe via separate Bash invocation. If `last-run.json` updates with `inferred_status: FAIL`, registration took effect mid-session (depends on whether CC reloads settings on edit). If snapshot is stale, document that registration takes effect next session — rely on pyshrnk dogfood pass 2 for production proof. _Result: mid-session reload WORKS; the hook fired on failing `bun test` immediately. But snapshot landed with `inferred_status: UNKNOWN` and empty `stdout_head`/`stderr_head` — payload-shape divergence (see Phase 3 finding below). Hook updated to handle divergent shape; re-ran → `status: FAIL` with full failure body in stderr._
- [x] 7. Document Phase 3 finding in `tasks.md § Notes`: did the registration take effect mid-session? Did the synthesized payload shape match production? Update `plan.md` § "Risks and unknowns" if any assumption broke. _See § "Phase 3 finding — payload divergence" below; plan.md § Risks updated post-finding._

### Phase 4 — Documentation updates

- [ ] 8. Edit `.claude/rules/runtime-introspect.md`: extend the "Capture — `PostToolUse(Bash)` → `.claude/hooks/runtime-capture.sh`" paragraph (line ~11) to mention the dual registration (PostToolUse + PostToolUseFailure). The existing gotcha bullet about "Claude Code's `tool_response.exit_code` does NOT exist" was extended in spec 019 with a "spec 020 (forthcoming)" note — change "(forthcoming)" to past tense + cite the impl commit SHA.
- [ ] 9. Edit `.claude/memory/cc-platform-hooks.md` § "Meta-lesson — why this memory exists": change "the fix is to additionally register on `PostToolUseFailure(Bash)`" from future tense to past tense, citing spec 020. Update the "Agent0 currently uses 8 of these 29" line to "Agent0 currently uses 9 of these 29" and add `PostToolUseFailure` to the explicit list.

### Phase 5 — Propagation + dogfood pass 2 prep

- [ ] 10. Dry-run sync against pyshrnk: `bash .claude/tools/sync-harness.sh --apply --dry-run --force --force-except='.gitignore' --agent0-path=/home/goat/Agent0 /home/goat/pyshrnk`. Expected decision lines: `~ merged .claude/settings.json` (PostToolUseFailure entry appended via jq dedup), `! overwritten .claude/rules/runtime-introspect.md` (rule update), `+ copied .claude/tests/runtime-introspect/11-*.sh` + `12-*.sh`. NOT expected: any `.claude/memory/` line (cc-platform-hooks.md edit stays Agent0-only per spec 019).
- [ ] 11. Apply sync to all 3 shrnks with `--force --force-except='.gitignore'`. Commit per fork: `chore(harness-sync): adopt Agent0 spec 020 (runtime-capture on failure path)`.
- [ ] 12. Update `~/pyshrnk/docs/dogfood-plan.md`: add a pass-2 checkpoint section describing the failure-path verification — "run `uv run pytest` with a deliberately failing test; immediately probe `bash .claude/tools/probe.sh last-run` in a SEPARATE Bash invocation; assert `status: FAIL`, `inferred_status: FAIL`, stderr visible". Commit in pyshrnk.
- [ ] 13. Verify each fork: `bash .claude/tools/sync-harness.sh --check --agent0-path=/home/goat/Agent0 /home/goat/<fork>` exits 0 (no drift); `jq '.hooks.PostToolUseFailure' <fork>/.claude/settings.json` returns the new entry.

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria._

- [ ] **Scenario 1 — failing pytest captures snapshot** — test 11 PASS; manual: synthesized failing-pytest payload writes `last-run.json` with `inferred_status: FAIL`.
- [ ] **Scenario 2 — failing bun test captures snapshot** — extend test 11 OR add a sibling fixture; covered indirectly when test 11 passes (same code path; bun-test detector is well-tested in tests 01-09).
- [ ] **Scenario 3 — PostToolUse-on-success path still works** — test 01 (existing `bun-test-capture`) continues to PASS; tests 01-10 PASS in `run-all.sh`. No regression.
- [ ] **Scenario 4 — non-verifier failures do not pollute snapshot** — manual: synthesize a payload with `command: "false"` or `cat /nonexistent` (not in detector list); confirm `last-run.json` mtime UNCHANGED. (Could become test 13 if needed; v1 leaves as manual check since the detector logic is shared and well-tested.)
- [ ] **Scenario 5 — cross-reference seeded by spec 019 works** — manual `grep cc-platform-hooks /home/goat/Agent0/.claude/rules/runtime-introspect.md` returns ≥1 line; check that the "(forthcoming)" wording was updated to past tense post-impl.
- [ ] **Scenario 6 — dogfood pass 2 in pyshrnk validates end-to-end** — pyshrnk dogfood-plan.md updated with the pass-2 checkpoint; full execution deferred to a separate dogfood session (not this spec's scope).
- [ ] **Static checks** — `.claude/settings.json` `hooks.PostToolUseFailure` array contains the Bash entry; `runtime-capture.sh` unchanged (sha256 matches pre-impl); `.claude/rules/runtime-introspect.md` updated; `.claude/memory/cc-platform-hooks.md` updated; tests 11 + 12 exist.
- [ ] **Full driver green** — `bash .claude/tests/runtime-introspect/run-all.sh` exits 0 (12/12 PASS post-impl).
- [ ] **All three shrnks synced + committed** — pyshrnk, shrnk, rshrnk each have a sync commit; `--check` exits 0 in each.

## Notes

- ~~This spec deliberately ships **no code change** to `runtime-capture.sh`.~~ **Updated post-Phase 3:** the "no code change" assumption broke when empirical verification surfaced a payload-shape divergence between `PostToolUse` and `PostToolUseFailure`. The hook now carries a small (~15 line) PostToolUseFailure branch keyed on `hook_event_name`; see § "Phase 3 finding — payload divergence" below.
- The "fix" framing emphasizes that this completes spec 011's intent rather than introducing new capacity. Spec 011's foundational assumption was incomplete; spec 020 closes the gap. Together they constitute the full runtime-introspect capacity.
- After spec 020 lands, pyshrnk dogfood pass 2 becomes the canonical "did spec 011 actually work in production end-to-end" test. Yield-decay graduation requires two consecutive 0-finding passes; pass 1 surfaced this finding, pass 2 (post-fix) is the first candidate clean pass.

### Phase 3 finding — payload divergence (2026-05-11)

Empirical Phase 3 (this session): a dump-probe hook captured the actual `PostToolUseFailure(Bash)` stdin payload from a deliberately-failing `bun test` invocation. Findings:

1. **Mid-session settings reload works.** Edits to `.claude/settings.json` are picked up by the harness within the same conversation — the freshly-registered `PostToolUseFailure(Bash) → runtime-capture.sh` entry fired on the next failing Bash call. No need to wait for the next session to verify.
2. **`PostToolUseFailure` payload shape DIVERGES from `PostToolUse`.** Specifically:
   - `tool_response` is **absent** entirely
   - Failure output is at top-level `.error` as a single string (combined stdout+stderr the harness already merged)
   - `is_interrupt` (boolean) replaces `tool_response.interrupted`
   - `hook_event_name: "PostToolUseFailure"` IS in the payload (disambiguates from PostToolUse for shared hook scripts)
   - `session_id`, `transcript_path`, `cwd`, `tool_name`, `tool_input`, `tool_use_id`, `duration_ms` carry over unchanged

3. **Hook adjustment (~15 lines).** `runtime-capture.sh` now reads `hook_event_name`; when it's `"PostToolUseFailure"`, the hook reads `.error` (routes it to `STDERR_RAW` so the existing inference table and tail-clamp logic process it as the failure body), `.is_interrupt` (replaces `tool_response.interrupted`), and `STDOUT_RAW=""` (no stdout under PostToolUseFailure). The else-branch preserves the original PostToolUse logic byte-for-byte — zero risk of regressing existing tests 01-10.

4. **Inference safety net.** When `hook_event_name == "PostToolUseFailure"` AND the per-detector inference table still ends `UNKNOWN` (e.g. failure body shape unfamiliar to the pattern set), inferred_status is defaulted to `FAIL` — the event itself is authoritative signal that the verifier failed. `inference_basis` records `"PostToolUseFailure event (pattern table missed)"` so the override is auditable.

5. **Test 11 updated** to use the production-verified PostToolUseFailure-shape payload (`hook_event_name`, `error`, `is_interrupt`) — serves as a regression guard against future divergence or harness changes.

6. **Empirical proof end-to-end:** ran `bun test /tmp/spec020-empirical/fail.test.ts` (exit 1, no pipe); probed via separate Bash invocation; got `status: FAIL`, `inferred_status: FAIL`, `inference_basis: bun-test: 'N fail' with N>0`, full failure body in the `--- stderr ---` block. Pyshrnk dogfood pass 2 still scheduled, but the production loop is closed in Agent0 already.
