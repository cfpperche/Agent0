# 101 — session-handoff-multi-runtime — notes

_Created 2026-05-28._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — what was ambiguous, what was decided, why}}

### 2026-05-28 — Codex CLI — Codex hook output contracts

Official Codex hook docs confirm the Phase 0 gate: `SessionStart` accepts plain stdout as extra developer context and also accepts JSON stdout with `hookSpecificOutput.hookEventName = "SessionStart"` plus `additionalContext`. Agent0 will keep Claude's JSON dual-channel output for Claude Code and emit plain framed stdout for Codex, matching the existing Codex readout hooks.

For `Stop`, Codex expects JSON on stdout when exit 0; plain text stdout is invalid. `decision: "block"` does not reject the turn. It continues Codex with a generated continuation prompt using `reason` as the prompt text. `stop_hook_active` means the turn was already continued by `Stop`, so the shared stop hook can exit 0 when it is true and rely on the existing `nagged` marker as the runtime-agnostic backstop.

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

## Verification notes

### 2026-05-28 — Codex CLI — Re-validation with hooks enabled

Confirmed the local `.codex/config.toml` has `hooks = true` and registers the expected shared hooks from `.agent0/hooks/`: `session-start.sh`, `memory-decay-readout.sh`, `reminders-readout.sh`, `routines-readout.sh`, `session-stop.sh`, and `session-track-edits.sh`.

Re-ran the spec-101 synthetic suite: `bash .claude/tests/session-handoff-multi-runtime/run-all.sh` passed all six scenarios (`SessionStart` injection, Stop nag-once, `apply_patch` attribution, subdir resolution, TOML parse, Claude regression). The older `session-handoff/run-all.sh` regression suite also passed all ten scenarios.

Supporting suites passed in the same validation pass: `runtime-capabilities/run-all.sh`, `instruction-drift/run-all.sh`, `codex-mcp-recipes/run-all.sh`, and `memory-multi-runtime/run-all.sh`. `git diff --check` passed, both `.codex/config.toml.example` and the local `.codex/config.toml` parsed with `tomllib`, and `sync-harness.sh --apply --dry-run --agent0-path="$PWD" <temp-consumer>` showed the shared `.agent0/hooks/session-*.sh`, `reminders-readout.sh`, and `routines-readout.sh` files propagating to a consumer fixture.
