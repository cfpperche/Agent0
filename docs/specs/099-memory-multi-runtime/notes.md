# 099 — memory-multi-runtime — notes

_Created 2026-05-27._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-05-27 — Codex CLI — Shared hook helper

The plan left runtime detection as either inline copy-paste or a shared helper. Implementation chose `.agent0/hooks/_memory-hook-lib.sh` so the brittle parts live in one place: project-root discovery, path normalization, patch-header extraction, entry/index path classification, actor attribution, and runtime attribution. The hooks still stay event-specific (`index-gate`, `frontmatter-validate`, `events-journal`, `decay-readout`), but the parser surface is shared.

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

### 2026-05-27 — Codex CLI — Live apply_patch probe replaced by tolerant parser

Task 1 originally called for registering a temporary Codex hook in local `.codex/config.toml`, restarting into a new Codex session, and dumping a live `apply_patch` payload before implementing the parser. This implementation happened inside an already-running Codex session, so hooks could not be reliably reloaded for a live probe without starting a second interactive run.

The implemented compromise is explicit: `memory_patch_body()` treats `tool_input.command` as the primary documented payload field and accepts `tool_input.input`, `tool_input.patch`, `tool_input.content`, or string `tool_input` as defensive fallbacks. `.claude/tests/memory-multi-runtime/03-codex-apply-patch-hooks.sh` covers the `tool_input.command` path with a synthetic patch containing real `*** Update File:` headers. A fresh-session Codex smoke test is still a good review check before downstream rollout, but not a blocker for shell-level validation.

### 2026-05-27 — Codex CLI — Fresh runtime sessions not claimed

The original tasks asked for fresh Claude Code and Codex session restarts. The completed verification is shell-level: synthetic Claude/Codex hook payloads, direct SessionStart hook invocation, TOML/JSON parse checks, and the memory/pre-commit test suites. This is the right evidence for repository behavior in this turn; live runtime restart checks should be done by the reviewing agent after applying the diff or by starting a fresh trusted-project session with the new `.codex/config.toml` hooks uncommented.

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

### 2026-05-27 — Codex CLI — Upstream-only consumer migration scope

The plan originally carried consumer execution pressure for `mei-saas` and `codexeng`. The spec's non-goals make that unsafe for this upstream implementation: Agent0 lands the new runtime-neutral memory shape and ships a manual migration playbook; downstream project migration is a separate operator action after sync. The accepted cost is that known consumers remain on shims until they explicitly migrate.

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._

_None at implementation handoff._
