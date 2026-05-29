# 116 — remove-runtime-introspect

_Created 2026-05-29._

**Status:** shipped

## Outcome

Shipped 2026-05-29. `runtime-introspect` removed in full: hook pair + `probe.sh` + rule + maintainer memory + both test suites (`runtime-introspect/` 17, `runtime-capture-php/` 7) `git rm`'d; `.agent0/.runtime-state/` snapshot deleted (README kept); 3 settings.json registrations removed (`PostToolUseFailure` event now absent; JSON parses); `MEMORY.md` regenerated (21 entries). `.claude/hooks/` now holds only `delegation-gate.sh`. Rewired: CLAUDE.md/AGENTS.md section, session-start readout, delegation.md `/goal` verifier, runtime-capabilities matrix row + `check-instruction-drift.sh` required-row list, php-laravel-support § 2 (renumbered) + gotchas, cc-platform-hooks inventory + dead pointers, capacity-spec-index row, runtime-state README row, bench-hooks `HOOK_NAMES` + perf-baseline cell, hook-chain memory current-chain claims, user-global-hooks-shadow cross-ref, validators/run.sh comment, site capacities card + lifecycle-pipeline marketing copy (en/pt/es — rode-along fix also dropped already-removed post-edit-validator/PreCompact mentions). Historical-narrative mentions KEPT per the spec-115 test (see `notes.md`). Site rebuilt — `dist/` clean. Test suites touched by this change all PASS (hook-chain-latency, runtime-capabilities, instruction-drift, harness-sync, session-state-isolation, lint-validator, validator-php). One unrelated pre-existing failure (`typecheck-advisory/08`, Node-compile-cache test-isolation pollution — not a regression; see `notes.md`).

## Intent

Remove the `runtime-introspect` capacity entirely — the `runtime-capture.sh` / `runtime-pre-mark.sh` hook pair, the `probe.sh` read-back tool, the `runtime-introspect.md` rule, the maintainer memory, both test suites (`runtime-introspect/`, `runtime-capture-php/`), the `.agent0/.runtime-state/` snapshot, and every live cross-reference. The capacity (specs 011/020/022) passively captured the last test/build/typecheck/lint Bash run to `last-run.json` so the agent could read it back via `probe.sh last-run`. It is now low-value and largely subsumed: (1) the `SubagentStop` validator (`delegation-verify.sh` → `validators/run.sh`, spec 111) **actively runs** the suite and gates delegated work — the enforcement path; (2) the parent agent already sees Bash stdout inline in the same turn, so the "read it back later" niche is thin and shrinking as LLM context management improves; (3) the capture side stamps state on **every** Bash call while the read side has no evidence of real use — logging-on-every-tool-call is overengineering for a payoff that rarely lands. With `rule-loads` already removed (spec 115), `last-run` is `probe.sh`'s only remaining subcommand, so removing this capacity empties and deletes the whole tool. Same skeptical-pruning discipline as specs 114/115 (`feedback_speculative_observability`).

## Acceptance criteria

- [x] **Scenario: hook pair, tool, rule, and maintainer memory are gone**
  - **Given** the repo after this spec ships
  - **When** `ls .claude/hooks/runtime-capture.sh .claude/hooks/runtime-pre-mark.sh .agent0/tools/probe.sh .claude/rules/runtime-introspect.md .agent0/memory/runtime-introspect-maintenance.md` runs
  - **Then** every path reports "No such file or directory"

- [x] **Scenario: both test suites removed**
  - **Given** the repo after this spec ships
  - **When** `ls .claude/tests/runtime-introspect .claude/tests/runtime-capture-php` runs
  - **Then** both directories are gone

- [x] **Scenario: settings.json registrations removed and JSON still valid**
  - **Given** `.claude/settings.json`
  - **When** parsed with `jq .`
  - **Then** it parses cleanly AND no `runtime-capture`/`runtime-pre-mark` command string remains AND the now-empty `PostToolUseFailure` event key is absent (its only hook was runtime-capture)

- [x] **Scenario: full test suite still green after removal**
  - **Given** the remaining `.claude/tests/`
  - **When** the aggregate test runner is invoked
  - **Then** it passes — no test references a deleted path or fixture (harness-sync, hook-chain-latency, runtime-capabilities, session-state-isolation suites included)

- [x] **Scenario: MEMORY.md index regenerated; maintainer entry gone**
  - **Given** the deleted `runtime-introspect-maintenance.md`
  - **When** `bash .agent0/tools/memory-project.sh` runs
  - **Then** `MEMORY.md` has no `runtime-introspect` line and the projection runs clean

- [x] No live (non-`docs/specs/`) reference to the deleted capacity survives that implies it still exists: a repo-wide grep for `runtime-introspect|runtime-capture|runtime-pre-mark|probe\.sh|RUNTIME_INTROSPECT|last-run` outside `docs/specs/` returns only KEEP-listed lines (frozen historical narrative + the retained `.runtime-state/README.md` for sibling state dirs — see § Decisions / `notes.md`).
- [x] `CLAUDE.md` and `AGENTS.md` no longer carry the `## Runtime introspect` managed-block section.
- [x] `.agent0/hooks/session-start.sh` no longer emits the `=== runtime-introspect ===` SessionStart readout.
- [x] `.claude/rules/delegation.md` § "Why DONE_WHEN exists" no longer cites `probe.sh last-run` as the verifier — the validator (`delegation-verify.sh`) is named as the sole verifier path.
- [x] `.claude/rules/runtime-capabilities.md` matrix no longer lists a `runtime-introspect`/local-test-capture capability row as a present Agent0 feature.
- [x] `site/src/i18n/capacities.ts` has no runtime-introspect card; the site build succeeds.
- [x] `.agent0/tools/sync-harness.sh` manifest no longer lists the deleted paths.
- [x] `bench-hooks.sh` still runs; `.perf-baseline.json` no longer asserts the removed hooks (regenerated or pruned), and `.claude/tests/hook-chain-latency/` passes.

## Non-goals

- **Not removing the validator.** `delegation-verify.sh` + `validators/run.sh` (the active suite-runner at `SubagentStop`) stay — they are the enforcement path this removal leans on, not part of runtime-introspect.
- **Not removing `bench-hooks.sh` / the hook-chain-latency capacity** (spec 094). It benchmarks whatever hooks exist; it loses two of its benched hooks but the tool and discipline remain.
- **Not deleting `.agent0/.runtime-state/README.md`.** That README is the catalog for ALL `.agent0/.*-state/` + `.claude/.*-state/` dirs (browser, delegation, routines) — only the runtime-introspect row is removed. The dir survives as the README's home.
- **Not rewriting `docs/specs/*` history** (011/020/022 and every later mention) — frozen audit trail per `.claude/rules/spec-driven.md`.
- **Not re-implementing a replacement.** If passive run-capture is ever wanted again, it can be re-specced; rebuilding now would re-trip the rule-of-three demand test.

## Open questions

- [x] None blocking. Per-file keep-vs-rewire calls for the historical-narrative memory mentions (`harness-home.md`, `hook-chain-*.md`, `propagation-hygiene.md`, `user-global-hooks-shadow.md`, `visibility-intent.md`) resolved by the spec-115 test: *describes a past event still true → keep; describes live wiring of the deleted capacity → rewire*. Recorded per-file in `notes.md`.

## Context / references

- `.claude/rules/runtime-introspect.md` — the rule being deleted (full capacity description)
- `docs/specs/{011-runtime-introspect,020-runtime-capture-on-failure,022-runtime-introspect-cargo,047-php-laravel-support}/` — origin + extension specs
- `docs/specs/111-delegation-verify-subagent-stop/` — the `SubagentStop` validator that subsumes the enforcement role
- `docs/specs/115-remove-rule-load-debug/` + `docs/specs/114-remove-compaction-continuity/` — immediate precedents (same removal shape + KEEP-history discipline); 115 already emptied `probe.sh` of its other subcommand
- `feedback_speculative_observability` (user auto-memory) — the rule-of-three demand test this applies
