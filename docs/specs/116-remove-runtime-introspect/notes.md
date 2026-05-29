# 116 — remove-runtime-introspect — notes

_Created 2026-05-29._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-05-29 — parent — per-file keep-vs-rewire calls (spec-115 test applied)

Test: *describes a past event still true → KEEP; describes live wiring of the deleted capacity → REWIRE.*

**KEPT (historical narrative / accurate-at-the-time):**
- `cc-platform-hooks.md:18` — the spec-011-gap / spec-020-fix narrative. Frozen account of a genuine CC platform fact (PostToolUse fires only on exit 0); the fact outlives the hook. Dead doc-pointers within the file (to `runtime-introspect-maintenance.md` + `runtime-capture.sh`) were severed; the narrative kept.
- `harness-home.md:29,33` — spec-104/105 consolidation history ("state moves with its producer"; runtime-state in the `move`-shipped list). The moves happened; `.runtime-state/` dir still exists (README home).
- `propagation-hygiene.md:66` — frozen spec-070 cleanup record listing `runtime-introspect` among 6 rule files (accurate at 2026-05-21).
- `memory-placement.md:248` — spec-097 disposition history listing `runtime-introspect.md` as one of 3 split-dispositioned rules (true). The *actionable* precedent-pair on that line was swapped to `propagation-advisory.md` ↔ `-maintenance.md` (still-existing pair).
- `hook-chain-latency.md` dated baseline figures (2026-05-26 "165 ms" derivation) — explicitly timestamped measurements of the 3-hook era; in-scope list updated to the current 2 hooks with a "removed in spec 116" note.
- `visibility-intent.md:17` — thesis history ("spec 011 realized this intent"); added a "(later removed in spec 116…)" parenthetical so it doesn't read as live.
- `.claude/tests/harness-sync/05,06` — synthetic merge-test fixtures using `runtime-pre-mark`/`runtime-introspect` as sample data to exercise the merge algorithm, not claims of real existence. Suite passes; swapping risks the carefully-counted assertions.

**REWIRED (live wiring of the deleted capacity):** settings.json registrations, CLAUDE.md/AGENTS.md section, session-start readout, delegation.md `/goal` verifier citation, runtime-capabilities.md matrix row + required-row list in `check-instruction-drift.sh`, php-laravel-support.md § 2 (+ renumber) + gotchas, cc-platform-hooks inventory + dead pointers, capacity-spec-index row, runtime-state README row, bench-hooks `HOOK_NAMES` + perf-baseline cell, hook-chain-maintenance current-chain claims, user-global-hooks-shadow dead cross-ref, validators/run.sh dead comment.

### 2026-05-29 — parent — rode-along fix of adjacent stale marketing copy

`site/src/i18n/strings.ts` lifecycle-pipeline sentence (en/pt/es) enumerated `runtime introspect` (my scope) **alongside** `post-edit validator` (removed spec 111) and "PreCompact for raw-signal preservation" (removed spec 114). Removing only runtime-introspect would have left two demonstrably-false capability claims in shipped marketing copy. Rewrote the sentence to current surviving capacities (PreToolUse / SessionStart / SubagentStop; delegation gate + secrets scan + stop-time validator). Out of strict scope but irresponsible to leave false; documented as a rode-along (precedent: spec 115's documented site-rebuild dropping 114's card).

### 2026-05-29 — parent — pre-existing unrelated test failure (NOT a regression)

`typecheck-advisory/08-globs-nested-workspace.sh` FAILS, but the cause is environmental and pre-dates this spec: Node 24's on-by-default compile cache writes `node-compile-cache/` (101 files) into the test's isolated TMPDIR git workspace, polluting its `git diff --name-only` so the validator's TDD-warning lists 102 prod files instead of 1. Confirmed not mine: `git status` shows no changes under `.claude/tests/typecheck-advisory/` or `.claude/validators/run.sh`; the failure reproduces independent of spec 116. The 5 suites this spec actually touched (hook-chain-latency, runtime-capabilities, instruction-drift, harness-sync, session-state-isolation) plus lint-validator and validator-php all PASS. Left for a separate test-isolation fix.

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — what the plan said, what was done instead, why}}

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — options considered in-flight, chosen path, accepted cost}}

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — the question, why it surfaced, what's blocked on it, who can decide}}
