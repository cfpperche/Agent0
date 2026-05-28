# 100 — multi-runtime-session-readouts — notes

_Created 2026-05-27._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

_No additional in-flight design decisions recorded._

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

### 2026-05-27 — Codex CLI — Helper tightened for subdir SessionStart

The plan treated `_memory-hook-lib.sh` as already sufficient for subdirectory Codex launches and runtime-aware `SessionStart` detection. Implementation verified `memory_project_dir` returned stdin `.cwd` literally before trying `git rev-parse`, and `memory_runtime` only classified Codex when `tool_name=apply_patch`. The helper was updated so nested `.cwd` resolves to the git root when possible, and `SessionStart` payloads without `CLAUDE_PROJECT_DIR` classify as Codex. This keeps the three readout hooks thin and makes the subdir acceptance test exercise the shared helper directly.

### 2026-05-27 — Codex CLI — Shipped docs avoid concrete spec backlinks

Task 7 asked for a cross-reference to spec 100 and spec 098 in `.claude/rules/mcp-recipes.md`. That rule is shipped to consumer projects by sync-harness, and Agent0's propagation-hygiene discipline forbids concrete `docs/specs/NNN-*` pointers in shipped rules because consumer projects do not receive Agent0's spec corpus. The implementation kept the runtime-neutral operational wording in the rule and left the lineage in this spec's own artifacts instead.

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

### 2026-05-27 — Codex CLI — Live Codex dogfood limited by non-interactive exec

Tried `codex exec --json --ephemeral --dangerously-bypass-hook-trust` against both a temp fixture with only the three SessionStart readouts enabled and this repo's current local Codex config. Both invocations completed successfully and returned the model response, but neither surfaced SessionStart hook output in the JSON stream (`MEMORY DECAY` was absent in the current-repo probe too). Treating that as a fresh interactive preamble check would be misleading: either `codex exec` does not run interactive SessionStart hooks, or it does not expose their stdout in JSONL. The validation therefore relies on direct synthetic SessionStart fixtures plus the real current-session evidence that interactive Codex SessionStart output reaches the preamble (`=== MEMORY DECAY ===` was visible at this turn's start before the new blocks were enabled).

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._

_No unresolved implementation-time questions._

## Verification notes

### 2026-05-27 — Codex CLI — Fixture and sync evidence

Executed the five new synthetic readout fixtures successfully:
`for t in .claude/tests/multi-runtime-readouts/*.sh; do bash "$t" || { echo "FAIL: $t"; exit 1; }; done`.

The sync-harness dry-run against a temp consumer project showed the three new files in the managed manifest: `.agent0/hooks/mcp-recipes-hint.sh`, `.agent0/hooks/reminders-readout.sh`, and `.agent0/hooks/routines-readout.sh`.

Additional targeted suites passed: `mcp-recipes/run-all.sh`, all four `mcp-recipes-laravel` tests, `monorepo-stack-detect/run-all.sh`, `runtime-capabilities/run-all.sh`, `instruction-drift/run-all.sh`, `codex-mcp-recipes/run-all.sh`, `memory-multi-runtime/run-all.sh`, and selected harness-sync scenarios `01`, `02`, `05`, `07`, `35`.

### 2026-05-28 — Codex CLI — Re-validation after spec 101

Re-ran the remaining spec-100 readout fixtures after spec 101 added `session-start.sh` as an additional Codex `SessionStart` hook:
`01-reminders-fixture.sh`, `02-routines-fixture.sh`, `04-subdir-launch.sh`, and `05-toml-parse.sh` all passed.

Updated `05-toml-parse.sh` to require the three readout commands it owns without assuming they are the only `SessionStart` blocks in `.codex/config.toml.example`; spec 101 legitimately adds a fourth `SessionStart` block for session handoff.

Current-state caveat: commit `25ae1a6` (`chore(harness): decommission mcp-recipes curation + SessionStart hint`) removed `.agent0/hooks/mcp-recipes-hint.sh`, its fixture, and its Codex/Claude registrations after spec 100 shipped. Therefore current validation confirms the active spec-100 hooks (`reminders-readout.sh` and `routines-readout.sh`) plus TOML/subdir behavior, not the decommissioned MCP hint.
