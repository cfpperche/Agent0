# 083 — memory-events-journal — plan

_Drafted from `spec.md` on 2026-05-24. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Three new bash artifacts wire together to make `.claude/memory/` self-consistent: a **projection tool** (`memory-project.sh`) that derives `MEMORY.md` from entries, a **PostToolUse hook** (`memory-events-journal.sh`) that appends to `.claude/.memory-events.jsonl` AND re-runs the projection on every entry edit, and a **PreToolUse gate** (`memory-index-gate.sh`) that blocks raw edits to `MEMORY.md` so drift is impossible by construction. An optional one-shot **backfill tool** (`memory-backfill.sh`) seeds the journal for the 13 existing entries on first-leader-machine setup.

Build order is bottom-up: projection first (standalone, dogfoodable against the current 13 entries with byte-equal expected output as the convergence check), then the gate (no dependency, can be validated by attempting a direct MEMORY.md edit), then the journal hook (depends on projection + payload conventions established by `memory-frontmatter-validate.sh` from 082), then the backfill, then the rule docs, then the umbrella OQ-5 update in the same commit. This order means each layer is testable before the next is added, and the final session-bootable verification reduces to a fresh-session edit of any entry and a `jq` check of the journal + a `diff` check against the regenerated `MEMORY.md`.

Shape consistency with the rest of Agent0: bash 3.2-compatible, `jq` as the only hard dep, exit-zero discipline on the PostToolUse half (fail-open with `memory-journal-advisory:` line), exit-2-with-template on the PreToolUse half (matches `delegation-gate.sh` / `secrets-scan.sh` / `supply-chain-scan.sh`). Override marker grammar is the project convention: `# OVERRIDE: memory-index-edit: <reason ≥10 chars>` greppable in the `tool_input` JSON; the gate records the bypass event and lets the edit through; the next projection run wipes the marker from `MEMORY.md` on the natural next entry edit.

## Files to touch

**Create:**

- `.claude/tools/memory-project.sh` (~60 LOC, executable) — iterates `.claude/memory/*.md` excluding `MEMORY.md`; uses the same frontmatter extractor pattern as `memory-frontmatter-validate.sh` (awk between `---` fences) to pull `name` + `description`; sorts by filename slug under `LC_ALL=C` for cross-machine determinism; writes `MEMORY.md` in the canonical bullet shape `- [<name>](<basename>.md) — <description>`. Idempotent: rewriting an unchanged corpus produces byte-identical output.

- `.claude/hooks/memory-events-journal.sh` (~80 LOC, executable) — PostToolUse hook for `Edit|Write|MultiEdit`. Scopes to `.claude/memory/*.md` (excluding `MEMORY.md`) using the same path-match pattern as 082's validator. Extracts `tool_name`, `session_id`, `tool_use_id`, `agent_id`, `agent_type` from stdin JSON. Computes `entry_id = basename(file_path, '.md')`. Determines `event_type`: if the journal already contains an `add` event for this `entry_id`, emit `update`; else emit `add`. Computes `actor`: `agent_type` when present, else `"parent"`. Appends one JSONL line. Then invokes `bash .claude/tools/memory-project.sh` to regenerate `MEMORY.md`. Fail-open on any step (unwritable journal, missing `jq`, projection error) — emit one `memory-journal-advisory: <reason>` to stderr, exit 0.

- `.claude/hooks/memory-index-gate.sh` (~60 LOC, executable) — PreToolUse hook for `Edit|Write|MultiEdit`. Scopes to `.claude/memory/MEMORY.md` only. Greps the full `tool_input` JSON for `# OVERRIDE: memory-index-edit: <reason>` (anchored at start of line per project convention, ≥10 char reason). If marker missing or reason too short → exit 2 with canonical template instructing the agent to edit the entry file and let projection regenerate. If marker valid → append a `manual-edit` event to the journal with the reason as a field, exit 0. Same `set -uo pipefail` discipline + jq-hard-dep + fail-closed-on-jq-missing as `delegation-gate.sh`.

- `.claude/tools/memory-backfill.sh` (~40 LOC, executable) — one-shot idempotent seed for `.claude/.memory-events.jsonl`. For each `.claude/memory/*.md` (excluding `MEMORY.md`): if the journal has no `add` event for that `entry_id`, append one with `ts` from `git log --reverse --format=%aI -- <file> | head -1` (falls back to filesystem mtime if untracked), `actor: "backfill"`, `tool: null`. Second invocation is a no-op. Prints a one-line summary (`backfilled N entries (M already present)`).

**Modify:**

- `.claude/settings.json` — add one entry to `PreToolUse[]` with matcher `Edit|Write|MultiEdit` invoking `memory-index-gate.sh`; add one entry to `PostToolUse[]` with the same matcher invoking `memory-events-journal.sh` (registered AFTER `memory-frontmatter-validate.sh` so any 082-schema advisory fires first, then the journal records the edit).

- `.gitignore` — add `.claude/.memory-events.jsonl` (per-machine cache per spec Non-goal "no git-tracked journal"; sibling to existing `.claude/delegation-audit.jsonl` and `.claude/.runtime-state/*`).

- `.claude/rules/memory-placement.md` — add `## Event journal` section after `## Frontmatter schema`. Documents: the JSONL shape (5 event types: `add` / `update` / `delete` / `rename` / `manual-edit`), the projection contract (`MEMORY.md` is a derived view, not hand-maintained), the gate semantics (`PreToolUse` blocks raw edits with override marker support), the `# OVERRIDE: memory-index-edit:` grammar, and the per-machine gitignore decision with the OQ-5 contradiction note pointing at 083's Non-goals.

- `docs/specs/080-memory-system-scale-ready/spec.md` — update OQ-5 to mark it resolved-and-overridden by 083 (single-line addition citing this spec's Non-goal on git-tracked journal). Keep the original text for audit; append `**RESOLVED 2026-05-24 by 083:** journal is gitignored per-machine; backfill remains one-shot via `memory-backfill.sh` but lives in `.gitignore`-scope, not git history.`

**Delete:**

None. All artifacts are additive.

## Alternatives considered

### Polling-based projection (cron or watcher daemon)

Rejected. A periodic regeneration introduces a drift window — between an entry edit and the next poll, `MEMORY.md` is stale and a reader sees out-of-date descriptions. Also requires per-machine daemon setup (parallel to `.claude/routines/`), adds an opt-in step every fork would need to repeat, and provides no signal at the moment of edit (the agent doesn't learn "your edit was journaled" inline). The PostToolUse-hook approach is synchronous, zero-setup-after-clone, and produces the journal entry at the moment of truth.

### Git pre-commit hook for projection

Rejected. Same drift problem as polling but at commit boundary instead of poll interval: WIP state between an edit and a commit shows stale `MEMORY.md` to any reader (including the agent reading it via CLAUDE.md § Memory). Also requires `git config core.hooksPath .githooks` activation per-fork (already a Agent0 pattern for secrets-scan; layering another one is friction). The PostToolUse hook covers the agent-edit surface; the rare human-direct-git-edit case is explicitly documented as opt-out responsibility in the spec OQ-5.

### Synthesize `MEMORY.md` on read (no file persisted)

Rejected. CLAUDE.md's `## Memory` block currently lazy-references `.claude/memory/MEMORY.md` as a file to read on demand. Replacing it with a synthesized-on-read mechanism would require either (a) loading every entry's frontmatter on every CLAUDE.md load (defeats the lazy-read purpose), or (b) inventing a new "synthesize this" directive Claude Code doesn't natively support. A persisted derived file matches the existing consumer contract and lets `git diff` show the projection delta to humans during review.

### Git-track the journal

Rejected per user decision 2026-05-24 (overriding umbrella 080 OQ-5). Git-tracked append-only JSONL produces merge conflicts on every concurrent commit from any multi-contributor fork — and while individual conflict resolution is trivial (interleave the JSONL lines), the noise-per-commit cost is high enough to discourage the discipline. Entry files themselves are git-tracked and carry the durable record of "what each memory said at time T" via `git log --follow`; the journal's per-machine role is decay-input + audit-of-recent-edits, both of which work fine per-machine.

### Frontmatter-declared `entry_id` field added to 082's schema

Rejected per D1. 082 just shipped (commit `19218f9`); reopening the schema would require a migration sweep of 13 entries plus a 086 follow-up to widen the validator's allowed-key set. `basename(filename, '.md')` is naturally stable, machine-derivable, requires zero schema change, and renames are explicit `rename` events carrying `prev_entry_id`. The 082 `name` field is a *display label* (entries already diverge from filename: `name: "Claude Code platform hooks"` for `cc-platform-hooks.md`), so it can't double as the stable id.

### Full event-replay state reconstruction (pure event-sourcing)

Rejected. Pure event-sourcing assumes the journal is the only source of truth and state is derived by replay. Memory entries are hand-editable files — they ARE a source of truth too. Replay would conflate the two truths and require either (a) auto-generating entry files from the journal on session boot (destroys hand-edit affordance), or (b) a reconciliation pass between replayed state and on-disk entries (complex, lossy). The "audit log + projection from current entries" model is simpler and matches actual usage.

## Risks and unknowns

- **Add-vs-update detection edge case on fresh-clone-without-backfill.** A new leader machine that skips `memory-backfill.sh` sees an empty journal; the first edit to an existing entry would be recorded as `add` (because the journal has no prior `add`), which is semantically wrong (the entry has existed for weeks). Mitigation: the rule § Event journal documents `memory-backfill.sh` as the first-run step; the journal hook emits a one-time `memory-journal-advisory: journal empty; run bash .claude/tools/memory-backfill.sh to seed history` on its first append when the journal file doesn't exist yet. Self-healing for the leader who reads advisories.

- **Override marker location ambiguity.** PreToolUse hooks see `tool_input` JSON; the natural marker location for an Edit/Write/MultiEdit on `MEMORY.md` is inside the edit content itself (HTML comment `<!-- OVERRIDE: memory-index-edit: <reason> -->` or raw `# OVERRIDE: memory-index-edit:` line). The marker would persist in `MEMORY.md` until the next projection run wipes it. Acceptable trade-off — projection runs on the natural next entry edit, restoring cleanliness. Document this as the expected flow.

- **MultiEdit `tool_input` shape variance.** MultiEdit applies multiple edits to ONE file (`tool_input.file_path` is singular). Hook logic is identical to Edit. No special-case needed.

- **Hook firing order in `PostToolUse[]`.** The new journal hook must register AFTER `memory-frontmatter-validate.sh` so any 082-schema advisory fires before the journal record (intuitive read order in stderr). Confirmed against current settings.json shape — new entry simply appended.

- **Locale-dependent sort.** `sort` output depends on `LC_COLLATE`. `memory-project.sh` sets `LC_ALL=C` at script top to ensure cross-machine byte-identical output. Risk: if a contributor's environment escapes that and sorts differently, the next regeneration produces a diff that looks like noise. Mitigation: the `LC_ALL=C` discipline is explicit at script top + the rule documents it.

- **`memory-events.jsonl` corruption from a partial write.** A crashed hook mid-`>>` could leave a truncated final line. Mitigation: the journal hook builds the full JSONL line in memory first, then a single `printf >> "$JOURNAL"` writes atomically (POSIX append-mode `O_APPEND` is one syscall for line-sized writes <PIPE_BUF). Inspection by `jq -c .` would surface a malformed line as a parse error; the journal hook's fail-open posture means subsequent edits still write clean lines.

- **Hooks don't activate mid-session.** Per `compaction-continuity.md` § Gotchas: settings.json changes register on the NEXT session start. Implementation can be committed, but acceptance verification ("scenario: editing an entry appends one event") requires a fresh session boot. This is the same gotcha 082 hit; flag in tasks.md.

- **PostToolUse hook recursion concern (it isn't one).** When `memory-events-journal.sh` calls `bash .claude/tools/memory-project.sh`, the projection writes `MEMORY.md` via shell `>` redirection, NOT via the `Write` tool. So no recursive PostToolUse cycle. Filesystem writes from within a hook script are invisible to Claude Code's tool tracing. Confirmed by analogy with `pre-compact.sh` which writes to `.claude/.compact-history/` without re-triggering itself.

- **macOS case-insensitive filesystem (per spec OQ-4).** Two entries with case-only differences (`Foo.md` vs `foo.md`) would collide on `entry_id`. Documented as project-hygiene problem the projection surfaces (both rows render with same entry_id, easy to spot). v1 does not validate uniqueness.

## Research / citations

- `.claude/memory/cc-platform-hooks.md` — PostToolUse fires only on tool success (exit 0); payload includes `tool_input.file_path` for Edit/Write/MultiEdit; `agent_id` / `agent_type` populate under sub-agent dispatch. Verified via 2026-05-19 cc-platform-audit.
- `.claude/hooks/memory-frontmatter-validate.sh` (spec 082) — sibling memory-scoped hook; path-match pattern, frontmatter extraction via `awk` between `---` fences, MEMORY.md skip rule, fail-open exit-zero discipline.
- `.claude/hooks/delegation-gate.sh` (spec 002) — PreToolUse blocking gate pattern; `# OVERRIDE: <reason ≥10 chars>` marker grammar with `^[[:space:]]*` start-of-line anchor; jq-as-hard-dep fail-closed posture; canonical template + audit-line on bypass.
- `.claude/hooks/post-edit-validate.sh` (spec 002) — `agent_id`-presence-as-actor-detection pattern (parent agents have null `agent_id`; sub-agents always have it).
- `.claude/delegation-audit.jsonl` (live shape) — JSONL audit log conventions Agent0 already uses (`ts`, `session_id`, `tool_use_id`, denormalized fields, `jq -c .` for inspection).
- `.claude/rules/memory-placement.md` § Frontmatter schema — the 082-locked schema the projection reads (`name` + `description` for index bullets).
- `docs/specs/080-memory-system-scale-ready/spec.md` § OQ-5 — umbrella decision being overridden here; cross-reference in the spec edit.
- `.gitignore` (current state) — sibling pattern for per-machine ephemeral state files (`.claude/.runtime-state/*`, `.claude/delegation-audit.jsonl`); new journal entry follows.
