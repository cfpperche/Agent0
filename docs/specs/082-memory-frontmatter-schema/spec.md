# 082 — memory-frontmatter-schema

_Created 2026-05-24._

**Status:** shipped

## Intent

Lock the current `.claude/memory/*.md` frontmatter convention as a formal **schema** (3 required + 3 optional fields) and ship a **PostToolUse advisory validator** that fires on `Write`/`Edit` of any `.claude/memory/*.md` file. Non-blocking, exit-zero, stderr-only — same shape as the existing `tdd-advisory:` / `lint-advisory:` / `typecheck-advisory:` family.

The 13 existing project-memory entries already converge on a shape (`name`, `description`, `metadata.type`) but nothing enforces it — a typo (`metdata:` instead of `metadata:`), a missing `description`, or an unknown nested key currently passes silently. The MEMORY.md index generator (MS-5, spec 085) and the event-sourcing journal (MS-2, spec 083) both depend on field stability: a description that exceeds the index cap can only be detected if the index generator parses frontmatter, and an event journal entry can only refer to a stable identifier if the schema declares one.

This spec is the **foundation row (MS-1)** of umbrella 080. It ships the schema artifact + validator hook only — no event-sourcing, no decay engine, no index regeneration. Those mechanisms read this schema and trust its presence.

The 3 optional fields are forward-compat for MS-7 (decay engine, spec 085): `metadata.created_at`, `metadata.last_accessed`, `metadata.confirmed_count`. They are **optional in 082** so existing entries pass validation without backfill; 085 will provide the helpers that populate them. Declaring them now (rather than at 085) lets the validator advise on *typo'd* optional fields too (`created_on` vs `created_at`) — typo-guard is the load-bearing benefit, not enforcement.

## Acceptance criteria

- [x] `.claude/rules/memory-placement.md` has a new `## Frontmatter schema` section documenting the 3 required fields (`name`, `description`, `metadata.type`) plus the 3 optional fields (`metadata.created_at`, `metadata.last_accessed`, `metadata.confirmed_count`) with semantics, value shapes, and a worked example. Schema lives inside the rule that already governs the bucket — no new file in `.claude/memory/`.

- [x] `.claude/hooks/memory-frontmatter-validate.sh` exists, is executable, and is registered as a `PostToolUse(Write|Edit|MultiEdit)` hook in `.claude/settings.json` with a matcher that targets `.claude/memory/*.md`.

- [x] **Scenario: conforming entry passes silently**
  - **Given** an agent edits `.claude/memory/foo.md` with all 3 required fields present and well-formed YAML frontmatter
  - **When** the post-edit hook fires
  - **Then** stderr is empty, exit code is 0, no `memory-frontmatter-advisory:` line appears

- [x] **Scenario: missing required field emits advisory**
  - **Given** an agent edits `.claude/memory/foo.md` and the frontmatter is missing one of `name` / `description` / `metadata.type`
  - **When** the post-edit hook fires
  - **Then** stderr contains `memory-frontmatter-advisory: <file>: missing required field '<field>'` and exit code is 0 (non-blocking)

- [x] **Scenario: unknown field emits typo-guard advisory**
  - **Given** an agent edits `.claude/memory/foo.md` and the frontmatter has a top-level or `metadata.*` key not in {3 required ∪ 3 optional}
  - **When** the post-edit hook fires
  - **Then** stderr contains `memory-frontmatter-advisory: <file>: unknown field '<field>' (typo guard; allowed: …)` and exit code is 0

- [x] **Scenario: malformed YAML emits parse advisory**
  - **Given** an agent edits `.claude/memory/foo.md` and the frontmatter block is unparseable (mis-indentation, missing `---` close, etc.)
  - **When** the post-edit hook fires
  - **Then** stderr contains `memory-frontmatter-advisory: <file>: frontmatter unparseable: <error>` and exit code is 0

- [x] **Scenario: file without frontmatter emits advisory**
  - **Given** an agent edits `.claude/memory/foo.md` and the file has no `---` frontmatter block at all
  - **When** the post-edit hook fires
  - **Then** stderr contains `memory-frontmatter-advisory: <file>: no frontmatter block (expected '---' at line 1)` and exit code is 0

- [x] **Scenario: edits outside `.claude/memory/` are ignored**
  - **Given** an agent edits `.claude/rules/foo.md` or `docs/specs/NNN/spec.md`
  - **When** the post-edit hook fires
  - **Then** the validator does not run and produces no output (matcher scoping confirmed)

- [x] **Scenario: `MEMORY.md` index is not validated as an entry**
  - **Given** an agent edits `.claude/memory/MEMORY.md`
  - **When** the post-edit hook fires
  - **Then** the validator skips it (MEMORY.md is the index, not an entry; has no frontmatter by design per `.claude/rules/memory-placement.md`)

- [x] **Scenario: all 13 existing entries pass**
  - **Given** the 13 entries currently in `.claude/memory/*.md` (as of 2026-05-24)
  - **When** the validator is run against each in turn
  - **Then** zero advisories fire — if any entry is non-conforming today, fix it in the same diff (one-time migration)

- [x] **Scenario: validator never blocks**
  - **Given** any of the failure modes above (missing field, unknown field, parse error, missing block)
  - **When** the hook returns
  - **Then** exit code is always 0; the harness never aborts the edit; the agent always sees the advisory on its next turn via stderr forwarding

- [x] The validator's advisory messages cite `.claude/rules/memory-placement.md § Frontmatter schema` as the authority, so an agent reading the advisory has a single pointer to the canonical definition.

## Non-goals

- **No `metadata.type` value-set enforcement.** Per umbrella NG-3, the schema requires the *field* but does not constrain its value. A fork may declare `metadata.type: bug-pattern` or `metadata.type: postmortem` and the validator stays silent — drawer taxonomy is policy, not mechanism. Validator only checks presence + shape, never enumerates allowed `type` strings.

- **No blocking gate.** The validator is advisory-only by design (matches `tdd-advisory:` / `lint-advisory:` pattern). A malformed memory entry is a soft signal for the author, not a reason to reject an edit mid-flight. Promoting to a blocking gate is deliberately deferred until the rule-of-three demand test trips (see `.claude/memory/feedback_speculative_observability.md`).

- **No `entry_id` field in 082.** Stable identification is event-sourcing territory (MS-2, spec 083). 083 will decide whether `entry_id` is filename-derived, content-hashed, or frontmatter-declared. Declaring it here would pre-empt that design.

- **No frontmatter-rewrite tooling.** Migration of the 13 existing entries (if needed at all) is a one-shot edit in the implementation diff, not a `memory-migrate.sh` helper. Migration tooling enters scope only if a fork actually needs it.

- **No vendor-tracking of CC's auto-memory frontmatter shape.** The current schema happens to mirror CC's `~/.claude/projects/.../memory/` shape (`name` / `description` / `metadata.type`), which is convenient but coincidental. If Anthropic evolves the auto-memory shape, Agent0's project-memory schema does NOT auto-follow. The two buckets share a *resemblance*, not a contract (per `.claude/rules/memory-placement.md` 3-bucket separation).

## Open questions

- [x] **OQ-1** Should the 3 optional fields live under `metadata.*` (current convention) or be promoted to top-level (`created_at:`, etc.)? Top-level reads cleaner; `metadata.*` matches current convention and CC's shape. Tentative: keep under `metadata.*` for consistency; revisit only if YAML readability complaints surface in dogfood.

- [x] **OQ-2** Validator implementation language — pure bash + `awk`/`grep` (zero dep, matches the `cc-native` portability tier) or `yq`/Python (richer parse, fewer false positives on edge YAML)? Tentative: pure bash with a tolerant frontmatter extractor (lines between first `---` and second `---`) + line-shape checks (`^name:`, `^description:`, `^metadata:`, then `^  type:`). Trade-off: catches the common typo cases at the cost of accepting some malformed YAML that `yq` would reject. Acceptable for an advisory; the goal is signal, not validation rigor.

- [x] **OQ-3** When the validator runs against an Edit that *removed* a required field (rather than a Write that never had it), the advisory message says the same thing. Should it distinguish "lost in this edit" from "never had it" via a git-aware diff lookup? Tentative: no — adds dependency on git state at hook-time, marginal value. The author reading the advisory sees the file in front of them.

- [x] **OQ-4** Does the validator fire on parent-agent edits, sub-agent edits, or both? `post-edit-validate.sh` already gates on `agent_id` (sub-agent only) per `.claude/rules/delegation.md`. Memory edits happen mostly from the parent (the user or main agent saving learnings); a sub-agent rarely edits memory. Tentative: fire on **both** — the actor distinction in `post-edit-validate.sh` exists because the project validator is expensive and only matters for sub-agents; this validator is cheap (one regex on a small file) and the parent benefits equally from typo-guard.

_(OQ-5, on schema-file placement, was resolved during refinement: the schema lives as a section in `.claude/rules/memory-placement.md` rather than a separate file — see acceptance criterion #1.)_

## Context / references

- `docs/specs/080-memory-system-scale-ready/spec.md` — parent umbrella; MS-1 row foundation for MS-2 (083) and MS-5 + MS-7 (085)
- `.claude/rules/memory-placement.md` — 3-bucket model; schema authority for project-memory bucket lives here after this spec ships
- `.claude/hooks/post-edit-validate.sh` — sibling validator pattern (advisory grammar, exit-zero discipline, stderr forwarding)
- `.claude/rules/tdd.md`, `.claude/rules/lint-validator.md`, `.claude/rules/typecheck-advisory.md` — established advisory rules; `memory-frontmatter-advisory:` follows their convention
- `.claude/rules/delegation.md` § *Advisories* — the canonical pattern for non-blocking, signal-only hook output
- `.claude/memory/feedback_speculative_observability.md` — rule-of-three demand test; rationale for advisory-only (not blocking) posture
- `.claude/memory/feedback_no_shipped_stack_opinions.md` — "mechanisms, not policies"; rationale for `metadata.type` value-openness
- `.claude/memory/cc-platform-hooks.md` — PostToolUse semantics; matcher syntax for `.claude/memory/*.md` scoping
- The 13 existing entries in `.claude/memory/*.md` — canonical conformance corpus; validator must pass them all on first run
