# 020 — runtime-capture-on-failure

_Created 2026-05-11. Status: draft._

## Intent

Spec 011 (runtime-introspect) registers `runtime-capture.sh` on `PostToolUse(Bash)` to snapshot the most recent test/build/lint command into `.claude/.runtime-state/last-run.json`. Pyshrnk dogfood pass 1 (2026-05-11) discovered empirically — and verified against canonical Claude Code docs — that **`PostToolUse` fires only when the underlying tool succeeds (exit 0).** Failing Bash commands route to a separate event, `PostToolUseFailure`, which spec 011 does NOT register on. Result: the very FAIL evidence the agent most needs (test failures, type errors, lint errors) is silently dropped — the agent runs `uv run pytest`, sees red on the tool-call output, queries `probe.sh last-run` and gets the PRIOR snapshot (PASS) or `no-snapshot`. The shrnk dogfood passes 1-3 missed this gap because they only exercised PASS scenarios.

The fix is small and clean: register `runtime-capture.sh` ALSO on `PostToolUseFailure(Bash)` in `.claude/settings.json`. The hook itself needs no code change — its inference logic already handles non-zero exits via the `inferred_status` field; the `tool_response` payload shape under `PostToolUseFailure` carries the same `stdout`/`stderr` fields the hook already reads. One settings entry + one RED test that exercises a failing verifier and asserts the snapshot was written. The cross-reference from `.claude/rules/runtime-introspect.md` to `.claude/memory/cc-platform-hooks.md` (seeded by spec 019) becomes the canonical "how this works" pointer.

## Acceptance criteria

- [ ] **Scenario: failing pytest captures snapshot**
  - **Given** `.claude/settings.json` registers `runtime-capture.sh` on both `PostToolUse(Bash)` AND `PostToolUseFailure(Bash)`
  - **When** the agent runs a failing pytest invocation in a Bash tool call (`pytest` matches the detector, exit code is non-zero, stderr contains failure indicators)
  - **Then** `.claude/.runtime-state/last-run.json` is overwritten with a fresh snapshot whose `command` matches the failing invocation, `inferred_status` is `FAIL`, `inference_basis` names the matched pattern, and the `stderr` field contains the failure output

- [ ] **Scenario: failing bun test captures snapshot**
  - **Given** the same registration as scenario 1
  - **When** the agent runs a failing `bun test` invocation (matches detector, non-zero exit)
  - **Then** snapshot is written; `inferred_status: FAIL`; `inference_basis` matches the bun-test failure pattern (e.g. `[1-9][0-9]* fail`); `stdout`/`stderr` retained

- [ ] **Scenario: PostToolUse-on-success path still works**
  - **Given** the same registration
  - **When** the agent runs a passing verifier (`bun test` exits 0)
  - **Then** snapshot is written via the existing `PostToolUse` path; `inferred_status: PASS`; existing behavior unchanged

- [ ] **Scenario: non-verifier failures do not pollute snapshot**
  - **Given** the same registration
  - **When** the agent runs a failing Bash command that is NOT in the detector list (e.g. `false`, `cat /nonexistent`, `git diff` against a deleted file)
  - **Then** the hook fires (now registered on PostToolUseFailure) but takes the same `skip-not-detect` path it takes on PostToolUse; `last-run.json` is NOT overwritten

- [ ] **Scenario: cross-reference seeded by spec 019 works**
  - **Given** `.claude/rules/runtime-introspect.md` already points at `.claude/memory/cc-platform-hooks.md` (seeded in spec 019)
  - **When** an agent or developer reads runtime-introspect.md
  - **Then** the cross-reference text exists, with the spec 020 fix mentioned in the right place (the existing gotcha bullet about `PostToolUse` exit-zero-only behavior)

- [ ] **Scenario: dogfood pass 2 in pyshrnk validates end-to-end**
  - **Given** spec 020 is shipped to pyshrnk via sync-harness
  - **When** the dogfood agent runs a failing pytest in pyshrnk and immediately probes via a separate Bash invocation
  - **Then** `bash .claude/tools/probe.sh last-run` returns `status: FAIL` with the failing pytest output visible in the `--- stderr ---` block

- [ ] `.claude/settings.json` `hooks.PostToolUseFailure` array contains a Bash matcher invoking `.claude/hooks/runtime-capture.sh`.
- [ ] `.claude/hooks/runtime-capture.sh` carries a small (~15-line) PostToolUseFailure branch keyed on `hook_event_name`. Empirically required: Phase 3 dump-probe surfaced that PostToolUseFailure(Bash) payload diverges from PostToolUse(Bash) — no `tool_response`; failure body at top-level `.error`; `is_interrupt` replaces `tool_response.interrupted`. Else-branch preserves PostToolUse logic byte-for-byte. Also: inferred_status defaults to `FAIL` when `hook_event_name == "PostToolUseFailure"` AND pattern table missed — event itself is authoritative signal of verifier failure. See `plan.md § Risks` and `tasks.md § Phase 3 finding`.
- [ ] `.claude/rules/runtime-introspect.md` updated: existing "Capture — PostToolUse(Bash)" paragraph extended to mention PostToolUseFailure; the gotcha bullet about exit-zero-only behavior gets a "FIXED in spec 020" sentence.
- [ ] `.claude/memory/cc-platform-hooks.md` § "Meta-lesson" updated: the lesson now cites spec 020 as the resolution, not just a future fix.
- [ ] Tests under `.claude/tests/runtime-introspect/` extended with a failure-path scenario (or new directory `.claude/tests/runtime-capture-on-failure/` if the existing tests fixture doesn't fit).
- [ ] Synced to all 3 shrnks; pyshrnk dogfood pass 2 verifies the fix in production.

## Non-goals

- **Filing an upstream Claude Code issue.** Pre-research suggested this; post-research it's moot — `PostToolUseFailure` is documented and intentional. The "fix" is using the right event, not changing CC behavior.
- **Wrapper convention `.claude/tools/run-verifier.sh <cmd>` that always exits 0.** Pre-research alternative; rejected because it adds a parallel API ("use the wrapper, not the command") that agents will forget. Native dual-event registration is the canonical fix.
- **Capturing failures from non-verifier commands.** The detector list (pytest / bun test / npm test / cargo test if extended in a future spec / etc.) deliberately stops the noise floor. A failing `false` or `git status` is not "verifier evidence" the agent needs persisted; the same `skip-not-detect` path that works for PostToolUse works for PostToolUseFailure.
- **Capturing PostToolUseFailure for tools other than Bash.** v1 mirrors the PostToolUse(Bash) registration shape exactly. Other PostToolUseFailure consumers (Edit failures, etc.) are separate concerns for different specs if needed.
- **Schema versioning of `last-run.json`.** No schema change. The `inferred_status` field already takes `FAIL`; nothing in the JSON shape signals "this came from PostToolUseFailure vs PostToolUse" — and we don't need that distinction. The agent reads the snapshot the same way regardless of which event triggered the capture.
- **Auto-graduating spec 011 dogfood passes.** The yield-decay rule says two consecutive 0-finding passes graduate. Pyshrnk pass 1 surfaced this finding (so passes 2+3 needed); the fix in spec 020 + pass 2 + pass 3 is the path forward. This spec's job is the fix; graduation is downstream.
- **Documentation of all 29 CC events in this spec.** That's `.claude/memory/cc-platform-hooks.md`'s job (already shipped via spec 019). This spec only references it.

## Open questions

- [ ] **Test directory location** — proposal: extend `.claude/tests/runtime-introspect/` with a new `11-failure-path-capture.sh` script rather than create a new `.claude/tests/runtime-capture-on-failure/` directory. This is a fix to spec 011, not a new capacity. Lean toward extending the existing dir.
- [ ] **Test payload shape under PostToolUseFailure** — the docs confirm the event exists and fires on tool failure, but the exact `tool_response` JSON shape it delivers needs empirical verification. Plan-phase WebFetch should confirm whether `tool_response.stdout`/`stderr` fields are populated identically to PostToolUse, or if any field is renamed/missing. If different, the hook may need a tiny adjustment.
- [ ] **Validation pass on Agent0 itself** — Agent0's own test infrastructure rarely produces failing Bash invocations (most tests pass). To confirm spec 020 works locally, deliberate failure-injection is needed during impl. Plan-phase decides: add a self-test fixture, or rely on pyshrnk dogfood pass 2 as the empirical proof?
- [ ] **`tool_use_id` correlation** — `runtime-pre-mark.sh` (PreToolUse) stamps a start mark indexed by `tool_use_id`. Does `PostToolUseFailure` carry the SAME `tool_use_id` as the corresponding PreToolUse for the failing call? If yes, duration computation works unchanged. If no, the hook needs to handle missing in-flight marks for failures (already does — `null` fallback). Empirical question for plan phase.

## Context / references

- `docs/specs/011-runtime-introspect/` — the spec this fix completes. Spec 011's foundational assumption ("PostToolUse fires on every Bash") is wrong; spec 020 closes the gap without rewriting 011.
- `docs/specs/019-project-memory/` — created `.claude/memory/cc-platform-hooks.md` which documents the 29-event canonical surface and the meta-lesson behind why spec 011 missed this. Spec 020 is the concrete realization of the lesson.
- `.claude/memory/cc-platform-hooks.md` — canonical reference for CC hook event semantics; primary source for understanding the PostToolUse / PostToolUseFailure split.
- `.claude/rules/runtime-introspect.md` — rule doc that gains the "FIXED in spec 020" annotation on the existing gotcha bullet about exit-zero-only behavior.
- `.claude/hooks/runtime-capture.sh` — the hook script that gets a second registration but no code change. Inference logic already handles non-zero exits.
- Pyshrnk dogfood pass 1 findings — recorded in `docs/specs/011-runtime-introspect/tasks.md` § "Dogfood pass-1 findings (`/home/goat/pyshrnk`)". The empirical reproduction (`false`, `sh -c 'echo HELLO; exit 7'`, failing pytest) that motivated this spec.
- Pyshrnk's own SESSION.md — also captured the finding from the fork side; references the workaround (pipe to absorb exit code).
- Canonical Claude Code docs: <https://code.claude.com/docs/en/hooks> — verified via WebFetch this conversation; confirms `PostToolUseFailure` exists, fires on tool failure, cannot block (the tool already failed), exit-2 stderr is shown to Claude.
