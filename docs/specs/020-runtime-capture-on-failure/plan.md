# 020 — runtime-capture-on-failure — plan

_Drafted from `spec.md` on 2026-05-11. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Smallest viable patch: add ONE entry to `.claude/settings.json` registering `runtime-capture.sh` on `PostToolUseFailure(Bash)` (mirror shape of the existing PostToolUse entry). The hook script itself **does not change** — its inference logic already handles non-zero exits, the `inferred_status` field already takes `FAIL`, and Claude Code's hook payload shape for PostToolUseFailure is consistent with PostToolUse (same `tool_input` / `tool_response` / `tool_use_id` / `session_id` / `transcript_path` / `duration_ms` keys per the canonical event lifecycle).

**Empirical verification under uncertainty.** The canonical docs page truncates the PostToolUseFailure-specific JSON schema; we know the event exists, fires on tool failure, and stderr-on-exit-2 is shown to Claude. Open: exact payload shape, `tool_use_id` correlation with the corresponding PreToolUse. Plan: assume identical shape (the design is consistent — there's no documented reason the failure-side event would invent a different schema), then verify empirically during Phase 2 impl by intentional failure injection. If the assumption breaks (e.g. `tool_response` field renamed, `tool_use_id` not propagated), the inference branch surfaces it as `UNKNOWN` and we adjust the hook then.

Three orthogonal pieces:

1. **`.claude/settings.json` entry** — one new array element under `hooks.PostToolUseFailure` mirroring the matcher + command shape of the existing `PostToolUse` entry. Single source-of-truth change for the registration.

2. **Test scenario** — extend `.claude/tests/runtime-introspect/` with `11-failure-path-capture.sh`. Builds a tmp project, invokes `runtime-capture.sh` directly with a synthesized PostToolUseFailure-shaped payload (failing pytest), asserts snapshot was written with `inferred_status: FAIL`. Direct hook invocation (rather than full Claude Code session) keeps the test self-contained and reproducible. The settings.json registration is verified separately via `jq` parsing — no live-session dependency.

3. **Documentation updates** — `.claude/rules/runtime-introspect.md` extends the existing "Capture" paragraph + the gotcha bullet about exit-zero-only behavior gets a "FIXED in spec 020" annotation. `.claude/memory/cc-platform-hooks.md` § "Meta-lesson" updates from "spec 020 will register" to "spec 020 registered" past tense, citing the commit.

Plus: re-sync 3 shrnks; pyshrnk dogfood pass 2 closes the empirical loop. Pyshrnk's dogfood-plan.md is updated to add the failure-path verification as an explicit pass-2 checkpoint.

## Files to touch

**Create:**
- `.claude/tests/runtime-introspect/11-failure-path-capture.sh` — synthesizes a PostToolUseFailure-shaped JSON payload (failing pytest, exit 1, stderr with `1 failed` summary), pipes to `runtime-capture.sh`, asserts `last-run.json` is created with `inferred_status: FAIL`, `inference_basis` matches pytest-failure pattern, `command` field preserved.
- `.claude/tests/runtime-introspect/12-settings-registration.sh` — `jq` parses `.claude/settings.json`, asserts `hooks.PostToolUseFailure` contains a Bash matcher invoking `runtime-capture.sh`. Static-fact verification, no hook execution.

**Modify:**
- `.claude/settings.json` — add `hooks.PostToolUseFailure` array (or extend if exists) with one entry: `{matcher: "Bash", hooks: [{type: "command", command: "bash $CLAUDE_PROJECT_DIR/.claude/hooks/runtime-capture.sh"}]}`. Same shape as the existing PostToolUse(Bash) entry.
- `.claude/rules/runtime-introspect.md` — extend the "Capture — `PostToolUse(Bash)` → ..." paragraph to mention the dual registration; update the existing "FIXED in spec 020" sentence in the gotcha (already added by spec 019) to remove "(forthcoming)" once the impl lands.
- `.claude/memory/cc-platform-hooks.md` — update § "Meta-lesson": change "the fix is to additionally register on `PostToolUseFailure(Bash)`" from future tense to past tense + cite the commit SHA. Update § "Agent0 currently uses 8 of these 29" to "9 of these 29" (PostToolUseFailure now used).
- `~/pyshrnk/docs/dogfood-plan.md` — add a pass-2 checkpoint section: "verify failure-path capture by running `uv run pytest` against a deliberately failing test; immediately probe via separate Bash invocation; assert `status: FAIL` with stderr visible".

**Delete:**
- None.

## Alternatives considered

### Modify `runtime-capture.sh` to add a dedicated failure branch

Rejected because the inference logic already handles non-zero exits — adding a code branch keyed on event-name (PostToolUse vs PostToolUseFailure) duplicates what `inferred_status` already does cleanly. The hook reads `tool_response` and emits a snapshot regardless of which event delivered the payload. Single-source inference is the right shape.

### Wrapper convention `.claude/tools/run-verifier.sh <cmd>` that always exits 0 + writes the captured payload directly

Rejected (carried over from spec.md) because it adds a parallel API the agent must remember to use ("run via the wrapper, not directly"). Native dual-event registration solves the same problem without new conventions or new commands. Wrappers are a fallback for harnesses that don't have failure-event hooks; CC has them, so use them.

### File an upstream issue against Claude Code asking PostToolUse to fire on all exits

Rejected (carried over). Pre-research suggested this; post-research it's moot. PostToolUse on success-only is documented and intentional. The fix is using the right event, not changing CC behavior.

### Capture all PostToolUseFailure events for all tools (not just Bash)

Rejected for v1 because it expands scope beyond runtime-introspect's mission. Other PostToolUseFailure consumers (Edit failures, Write failures) are separate concerns. Mirroring exactly the PostToolUse(Bash) shape keeps the change minimal and predictable. Future specs can add other tool matchers as separate registrations if useful.

### Combined matcher (single registration on `PostToolUse|PostToolUseFailure`)

Rejected because Claude Code's settings.json schema treats events as separate top-level keys under `hooks.<event>`. There's no syntax for combining events. Two entries (one per event) is the canonical shape. The documentation/CLAUDE.md cost is identical; the settings.json is just one extra array entry.

## Risks and unknowns

- **PostToolUseFailure payload shape might diverge from PostToolUse.** Docs are truncated for this event's schema. Mitigation: assume identical shape (consistent design); verify empirically during Phase 2 by intentional failure injection. If `tool_response.stdout`/`stderr` is renamed or absent under PostToolUseFailure, the snapshot lands with empty body fields and inference falls to UNKNOWN — not silent failure, observable signal. We adjust the hook then.
- **`tool_use_id` correlation with the corresponding PreToolUse may not hold under PostToolUseFailure.** Same mitigation: empirical verification. If correlation breaks, `runtime-pre-mark.sh`'s in-flight stamp doesn't get matched and `duration_ms` falls back to either harness-provided (top-level `duration_ms`) or `null`. Acceptable degradation; not a blocker.
- **Test 11's synthetic payload may not match production CC behavior.** The synthesized JSON in the test mirrors what we ASSUME CC sends on PostToolUseFailure. If production diverges, test 11 passes but pyshrnk dogfood pass 2 fails. Mitigation: the test has documentation-only value once the live dogfood passes; if test passes but live fails, we know the synthesized shape is wrong — fix the test to match production observation.
- **Settings.json merge surface.** Spec 016 sync-harness uses jq dedup keyed on `(matcher, hooks[].command)`. The new PostToolUseFailure entry's command is identical to the existing PostToolUse entry's command, but the matcher is at a DIFFERENT event key (`PostToolUseFailure` vs `PostToolUse`), so dedup is per-event-array and doesn't conflate them. Confirmed by reading sync-harness.sh § merge_settings_json.
- **Pyshrnk dogfood pass 2 timing.** Pass 2 requires Agent0 to ship spec 020 first, then sync the fork, then re-execute the failing pytest. Sequencing matters: don't run pyshrnk pass 2 against a stale (pre-020) sync state. The dogfood-plan.md update names the prerequisite explicitly.
- **First-fork sync surprise.** Forks with their own `.claude/settings.json` customizations may already have a `PostToolUseFailure` array entry (unlikely — none of the 3 shrnks do today). The sync-harness merge handles this — fork's existing entries are preserved, Agent0's new entry is appended; if the dedup key matches (same command, same matcher), no duplication. Verified by re-reading the merge logic.
- **Spec 011 vs spec 020 narrative coherence.** Spec 011's `tasks.md` has the "FIXED in spec 020" line; spec 020 closes that loop. If spec 011 is ever re-issued (theoretical), spec 020 becomes part of its impl rather than a follow-up. Not a blocker, just a documentation note for future readers.

## Research / citations

- Codebase: `.claude/hooks/runtime-capture.sh` — verified the inference branch handles non-zero exits via `inferred_status` field; no exit-code-specific gating in the hook code.
- Codebase: `.claude/settings.json` — current `PostToolUse(Bash)` entry shape verified for mirror-replication; jq merge semantics in sync-harness.sh § merge_settings_json verified.
- Codebase: `.claude/memory/cc-platform-hooks.md` (created in spec 019) — documents the canonical 29-event surface including PostToolUseFailure semantics.
- Codebase: `.claude/rules/runtime-introspect.md` — already references the spec 020 fix (seeded by spec 019); plan extends that reference, doesn't introduce it.
- Live evidence: pyshrnk dogfood pass 1 (`docs/specs/011-runtime-introspect/tasks.md` § "Dogfood pass-1 findings (`/home/goat/pyshrnk`)") — empirical reproduction of the PostToolUse-on-success-only behavior with `false`, `sh -c 'echo HELLO; exit 7'`, and failing pytest.
- Empirical verification this conversation: `python3 -m pytest test_fail.py` (exit 1, no pipe) — `last-run.json` mtime unchanged before and after; same command piped with `2>&1 | tail -3` (pipeline exit 0) — snapshot updated. Confirms exit-code gating before any external research.
- External docs: <https://code.claude.com/docs/en/hooks> — verified PostToolUseFailure exists, fires on tool failure, cannot block (tool already failed), exit-2 stderr shown to Claude. PostToolUseFailure-specific JSON schema truncated in docs page; payload-shape verification deferred to impl-phase empirical test.
- External issue: <https://github.com/anthropics/claude-code/issues/6371> — closed "not planned" per claude-code-guide research; confirms intentional design that PostToolUse fires on success only.
