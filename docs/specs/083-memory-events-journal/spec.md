# 083 — memory-events-journal

_Created 2026-05-24._

**Status:** shipped

## Intent

Make `.claude/memory/` event-sourced: every `Write`/`Edit`/`MultiEdit` of a project-memory entry file appends a JSONL event to `.claude/.memory-events.jsonl` AND triggers an automatic projection that regenerates `.claude/memory/MEMORY.md` from the current entries. Raw edits to `MEMORY.md` itself are blocked (PreToolUse gate, override marker supported) — the index is a derived view, not a hand-maintained file.

This is the **MS-2 mechanism** of umbrella 080 — event-sourced memory always-on + raw-edit gate on `MEMORY.md` + projection helper. Depends on 082 (schema validator) for the frontmatter shape that the projection reads; unblocks 085 (cap + query + decay), which consumes `last_accessed` timestamps derivable from the journal.

The current state ships a hand-edited `MEMORY.md` index that drifts the moment a contributor edits an entry without touching the index. Drift is invisible until someone next reads MEMORY.md and finds a description out of sync, or a missing entry, or a stale one. The three load-bearing benefits of this spec: (a) **drift is impossible by construction** — projection runs in the same PostToolUse hook that journals; (b) **edit history is queryable** without `git log --follow` gymnastics over 13+ files — `jq` over a single JSONL; (c) **decay engine (085) has a clean substrate** — `last_accessed` is the most recent `update` event for an `entry_id`, no filesystem-mtime guesswork.

## Acceptance criteria

- [x] `.claude/tools/memory-project.sh` exists, is executable, and regenerates `.claude/memory/MEMORY.md` deterministically from `.claude/memory/*.md` (excluding `MEMORY.md` itself). Reads `name` + `description` frontmatter fields (per 082 schema), sorts by filename slug, writes one bullet per entry in the form `- [Display name](filename.md) — description`.

- [x] `.claude/hooks/memory-events-journal.sh` exists, is executable, and is registered as a `PostToolUse(Write|Edit|MultiEdit)` hook in `.claude/settings.json` with a matcher that targets `.claude/memory/*.md` and excludes `.claude/memory/MEMORY.md`.

- [x] `.claude/hooks/memory-index-gate.sh` exists, is executable, and is registered as a `PreToolUse(Write|Edit|MultiEdit)` hook with a matcher targeting `.claude/memory/MEMORY.md`.

- [x] `.claude/.memory-events.jsonl` is added to `.gitignore` (per-machine cache; not shipped between forks; reconstructable from `git log` of memory files).

- [x] `.claude/rules/memory-placement.md` has a new `## Event journal` section documenting: the JSONL shape, the projection contract, the gate semantics, the `# OVERRIDE: memory-index-edit:` grammar, and the per-machine gitignore decision.

- [x] **Scenario: editing an entry appends one event and regenerates the index**
  - **Given** `.claude/memory/foo.md` exists with valid frontmatter (`name`, `description`, `metadata.type`)
  - **When** the agent edits `.claude/memory/foo.md` (Edit, Write, or MultiEdit)
  - **Then** `.claude/.memory-events.jsonl` gains exactly one new line with `event_type: "update"`, `entry_id: "foo"`, `actor` from `agent_id`/`agent_type` payload (parent or sub-agent slug), `ts` in ISO-8601 UTC, `tool` matching the triggering tool name; AND `.claude/memory/MEMORY.md` is rewritten by the projection so its `foo.md` bullet reflects the new `description`

- [x] **Scenario: creating a new entry emits an `add` event**
  - **Given** `.claude/memory/bar.md` does not exist
  - **When** the agent writes `.claude/memory/bar.md` (Write tool)
  - **Then** the journal gains one line with `event_type: "add"`, `entry_id: "bar"`; AND `MEMORY.md` is regenerated with a new bullet for `bar.md`

- [x] **Scenario: deleting an entry emits a `delete` event on the next edit (out of scope for v1 — see Non-goals)**
  - File deletion is not currently a hook-trigger surface in Claude Code; `delete` event_type is reserved in the journal schema but not auto-emitted in v1. Contributors who remove an entry run `bash .claude/tools/memory-project.sh` manually to regenerate the index — the missing entry drops from MEMORY.md the next time the projection runs.

- [x] **Scenario: raw edit to MEMORY.md is blocked without override**
  - **Given** the agent attempts to `Edit` or `Write` `.claude/memory/MEMORY.md` directly (no override marker)
  - **When** the PreToolUse gate fires
  - **Then** the hook exits 2; stderr contains the canonical template instructing the agent to edit the entry file and re-run `bash .claude/tools/memory-project.sh`; the edit does NOT proceed

- [x] **Scenario: raw edit to MEMORY.md proceeds with override marker**
  - **Given** the agent's tool input or surrounding context contains `# OVERRIDE: memory-index-edit: <reason ≥10 chars>`
  - **When** the PreToolUse gate fires
  - **Then** the hook exits 0; the edit proceeds; the override reason is recorded in `.claude/.memory-events.jsonl` as a `manual-edit` event with the reason as a field (single-line audit trail)

- [x] **Scenario: projection is deterministic and idempotent**
  - **Given** `.claude/memory/*.md` are unchanged
  - **When** `bash .claude/tools/memory-project.sh` runs twice in succession
  - **Then** the second run produces zero diff on `MEMORY.md` (idempotent); two distinct machines running the projection on the same entry set produce byte-identical output (deterministic — sorted by filename slug, no timestamps in output)

- [x] **Scenario: edit by a sub-agent records `actor` as the sub-agent type**
  - **Given** a sub-agent dispatched via the `Agent` tool with `subagent_type: "general-purpose"` edits `.claude/memory/foo.md`
  - **When** the PostToolUse hook fires
  - **Then** the journal line has `actor: "general-purpose"` (NOT `"parent"`); session_id and tool_use_id present for cross-correlation with `.claude/delegation-audit.jsonl`

- [x] **Scenario: rename emits a `rename` event with `prev_entry_id`**
  - **Given** an entry file is renamed (`foo.md` → `foo-clarified.md`) — observable as a `Write` of the new path with content matching the old file's body
  - **When** the contributor manually appends a `rename` event (or runs an optional `memory-rename.sh` helper if provided in v1)
  - **Then** the journal carries `event_type: "rename"`, `entry_id: "foo-clarified"`, `prev_entry_id: "foo"`
  - **Note:** auto-detection of rename is out of scope (no rename-specific tool event; v1 treats rename as manual journal append + projection re-run)

- [x] **Scenario: backfill of 13 existing entries is per-machine and one-shot**
  - **Given** a fresh clone or fresh leader machine with no `.claude/.memory-events.jsonl`
  - **When** the contributor runs `bash .claude/tools/memory-backfill.sh` (optional helper script in v1)
  - **Then** one `add` event is appended per existing `.claude/memory/*.md` (excluding `MEMORY.md`) with `ts` = the file's git-introduction timestamp (`git log --reverse --format=%aI -- <file> | head -1`), `actor: "backfill"`, `tool: null`; second invocation of the script is a no-op (journal already populated)

- [x] **Scenario: gate is bypass-safe under `# OVERRIDE: memory-index-edit:` but reasons <10 chars are rejected**
  - **Given** a brief carrying `# OVERRIDE: memory-index-edit: fix` (4 chars — too short)
  - **When** the PreToolUse gate parses the marker
  - **Then** the gate still blocks (exit 2) and stderr says `override reason too short (need ≥10 chars after prefix)` — matches the discipline of `delegation-gate.sh` / `secrets-scan.sh`

- [x] **Scenario: hook never blocks on its own bug**
  - **Given** the journal file is unwritable, or `jq` is missing, or the projection script errors
  - **When** the PostToolUse hook runs
  - **Then** the hook exits 0 (fail-open); stderr emits a single `memory-journal-advisory: <reason>` line; the edit is NOT reverted; subsequent successful edits resume journaling. (PreToolUse gate is the only blocking part of this spec; the PostToolUse half is signal-only.)

- [x] All 13 existing entries pass through projection unchanged (the regenerated `MEMORY.md` matches what's currently committed within whitespace tolerance); zero new advisories from 082's frontmatter validator fire during the implementation diff.

## Non-goals

- **No auto-emit `delete` event on file removal.** Claude Code has no `FileRemoved` hook event; emulating it via filesystem polling is out of scope. Contributors who remove an entry re-run the projection manually; the entry drops from MEMORY.md and the next manual journal append (or 085's compaction tooling) records the delete. The `delete` event_type IS reserved in the schema so it can be populated later without re-design.

- **No auto-rename detection.** Same reason as delete — no `FileRenamed` hook. v1 treats rename as a manual journal append + projection re-run. An optional `memory-rename.sh` helper may ship as ergonomic sugar but is not load-bearing.

- **No event-replay / state reconstruction tooling.** This spec is "audit log + projection from current entries", not pure event-sourcing. There is no `memory-replay.sh` that reconstructs MEMORY.md by replaying the journal. The journal is for queryability and decay-input (085), not for state derivation.

- **No git-tracked journal.** `.claude/.memory-events.jsonl` is gitignored (per-machine, like `delegation-audit.jsonl` and `.runtime-state/`). This contradicts umbrella 080's OQ-5 ("single commit backfill") — that OQ is hereby overridden by 083 and the umbrella's OQ-5 is updated in the same diff. Rationale: a git-tracked append-only journal produces merge conflicts on every concurrent commit in a multi-contributor fork; the journal is per-machine bookkeeping; entry files themselves (git-tracked) carry the durable history.

- **No `metadata.entry_id` frontmatter field.** Per D1 above: `entry_id = basename(filename, '.md')`. The 082 schema is NOT extended. Renames are explicit `rename` events carrying `prev_entry_id`. This keeps 082's schema closed and avoids a migration sweep.

- **No projection-on-read.** The projection runs on write (PostToolUse hook) and on explicit `bash .claude/tools/memory-project.sh` invocation. Reading MEMORY.md does not trigger regeneration — it's a static derived view, not a live computation. Stale only if a write happened outside the hook surface (e.g. `git pull` brought in entry edits from another machine); contributors run the projection manually in that case.

- **No event-journal CLI / `memory-query.sh`.** Query tooling lives in 085 (MS-5). 083 only writes the journal; consumers come later. Manual inspection via `jq -c .` is sufficient for v1.

- **No effort signal in events.** Journal entries record `actor` (parent vs sub-agent slug) for accountability but not the `effort` payload field (low/medium/high). Effort is interesting for delegation analysis (per `delegation-audit.jsonl`'s richer shape), not for memory edit attribution.

## Open questions

- [x] **OQ-1** Should `memory-backfill.sh` ship in v1, or do contributors hand-write the initial 13 events? Tentative: ship it — backfill is mechanical, one-shot, and the script lowers the friction for forks adopting the capacity later. Cost: ~30 LOC of `git log` + `jq` glue.

- [x] **OQ-2** Should `memory-rename.sh` ship in v1? Tentative: NO — rename is rare (zero observed in 13-entry Agent0 history); manual journal append + projection re-run is acceptable. Re-visit if a contributor reports rename friction.

- [x] **OQ-3** Does the PostToolUse hook run on the parent agent's edits, or only sub-agent edits? Per `post-edit-validate.sh` precedent, the parent is exempt. But for memory journaling, the parent IS the most common author (founder editing notes). Tentative: fire on **both** — same logic as 082's validator (cheap, both benefit). Confirmed in 082, applies equally here.

- [x] **OQ-4** Determinism check: what if two entries have identical filename slugs (impossible on case-sensitive filesystem but possible on macOS case-insensitive)? Tentative: ignore — Agent0 conventions use lowercase kebab-case slugs; collision implies a project hygiene problem the projection helpfully surfaces (both rows would render with the same `entry_id`, easy to spot).

- [x] **OQ-5** What if a contributor commits to MEMORY.md directly through git (bypassing the PreToolUse gate which only sees the Edit/Write tool surface)? The gate cannot intercept `git commit` against an externally-edited file. Tentative: accept — discipline is enforced for the agent's edit path; a human running `vim .claude/memory/MEMORY.md && git commit` is explicitly opting out and is responsible for re-running the projection. The next agent-driven edit to any entry re-converges MEMORY.md anyway. Document in the rule.

## Context / references

- `docs/specs/080-memory-system-scale-ready/spec.md` — umbrella; MS-2 row is this spec; OQ-5 of the umbrella is overridden here (gitignored journal, not git-tracked)
- `docs/specs/082-memory-frontmatter-schema/spec.md` — MS-1 dependency; this spec reads the schema it defined
- `docs/specs/085-*` (future) — MS-5 + MS-7 consumer; reads `last_accessed` from this journal
- `.claude/rules/memory-placement.md` — gains `## Event journal` section in this spec's implementation diff
- `.claude/memory/cc-platform-hooks.md` — PostToolUse / PreToolUse semantics; matcher syntax; payload shape for `agent_id` / `agent_type`
- `.claude/hooks/post-edit-validate.sh` — sibling validator pattern (advisory grammar, exit-zero discipline, actor detection via `agent_id`)
- `.claude/hooks/delegation-gate.sh` — sibling PreToolUse gate pattern (canonical template, `# OVERRIDE:` marker, ≥10-char reason rule)
- `.claude/delegation-audit.jsonl` — JSONL audit log shape this spec mirrors
- `.claude/.runtime-state/` — precedent for per-machine gitignored hook state
- `.claude/memory/feedback_speculative_observability.md` — rule-of-three demand test (relaxed here because umbrella 080 documents the production-fork-at-scale motivator)
- `.claude/memory/anthill-archived.md` — quality benchmark; Anthill ships event-sourced memory; this spec ports the mechanism, not the policy
