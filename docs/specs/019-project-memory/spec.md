# 019 — project-memory

_Created 2026-05-11._

**Status:** shipped

## Intent

Today the Agent0 memory model has two buckets: `.claude/rules/<topic>.md` (git-tracked, behavioral mandates that **ship to forks** via sync-harness manifest) and `~/.claude/projects/<path>/memory/` (the Claude Code per-user system — **not git-tracked, machine-local**). The gap between them is real and was just hit empirically: factual cross-cutting knowledge about the project (e.g. "Claude Code exposes 29 hook events, not 9 — always consult canonical docs before designing hook-based capacities") has nowhere correct to live. Per-user memory loses it on machine switch and doesn't propagate to other developers. Rules conflate factual reference with behavioral mandate — and shipping CC-platform reference data to every fork is noise.

Introduce `.claude/memory/<topic>.md` as the third bucket: factual project knowledge that's git-tracked (travels between developers via PR/clone) but NOT in the sync-harness manifest (does not propagate to forks). Companion `.claude/memory/MEMORY.md` is a hand-maintained lazy-read index — agent consults it when starting work that may benefit from prior decisions / gotchas / platform constraints. No SessionStart auto-load (would hit the same ~2KB-budget scaling problem SESSION.md documents). Discovery is via CLAUDE.md instruction + cross-references from specific rule docs ("see `.claude/memory/cc-platform-hooks.md`"). Migration moves 2 existing per-user memories (`project_agent0_purpose`, `project_visibility_intent`) to the new bucket; `user_language` (genuine preference) stays per-user. `.claude/rules/memory-placement.md` is rewritten to document the 3-bucket model.

## Acceptance criteria

- [ ] **Scenario: factual project memory is git-tracked**
  - **Given** a developer writes a project-knowledge memory file (e.g. `cc-platform-hooks.md`)
  - **When** they save it under `.claude/memory/<topic>.md`
  - **Then** the file is tracked by git, visible in `git status` after creation, and shared with any contributor who clones the repo

- [ ] **Scenario: project memory does NOT propagate to forks**
  - **Given** a fork at `~/some-fork` and Agent0 at `~/Agent0` with several files under `.claude/memory/`
  - **When** the developer runs `bash .claude/tools/sync-harness.sh --apply --agent0-path=~/Agent0 ~/some-fork` from Agent0 root
  - **Then** no file from `.claude/memory/` is copied or merged into the fork; `~/some-fork/.claude/memory/` either stays empty or contains only the fork's own memories

- [ ] **Scenario: agent discovers project memory via CLAUDE.md**
  - **Given** an agent starts a fresh session in Agent0 with the new `## Memory` section present in CLAUDE.md
  - **When** the agent reads CLAUDE.md as part of session start
  - **Then** the agent encounters an explicit instruction pointing at `.claude/memory/MEMORY.md` as the index of project knowledge, naming it as the lazy-read entry point

- [ ] **Scenario: SessionStart does NOT auto-load memory**
  - **Given** `.claude/memory/` contains 10+ memory files totaling 100+ KB
  - **When** a new Claude Code session starts
  - **Then** the SessionStart hook output (additional-context block) contains NO memory content — no `=== project-memory ===` block, no inlined memory body — only the existing SESSION.md / REMINDERS / runtime-introspect / githooks-activation blocks

- [ ] **Scenario: cross-reference from rule docs works**
  - **Given** an agent is reading `.claude/rules/runtime-introspect.md` (or any rule doc that has gained a memory cross-reference)
  - **When** the rule doc text includes a sentence like "See `.claude/memory/cc-platform-hooks.md` for the canonical Claude Code hook event surface"
  - **Then** the agent can follow the reference by reading that specific memory file, without needing to walk the full index first

- [ ] **Scenario: migration moves substantive memories**
  - **Given** the current state of `~/.claude/projects/-home-goat-Agent0/memory/` containing `project_agent0_purpose.md`, `project_visibility_intent.md`, and `user_language.md`
  - **When** the migration step of this spec completes
  - **Then** `.claude/memory/agent0-purpose.md` and `.claude/memory/visibility-intent.md` exist in Agent0 (git-tracked), and the original per-user copies are deleted; `user_language.md` (preference) remains untouched in per-user memory

- [ ] **Scenario: `memory-placement.md` documents 3 buckets**
  - **Given** the rewritten `.claude/rules/memory-placement.md`
  - **When** read by an agent or developer
  - **Then** the file explicitly describes 3 buckets — (a) CC per-user (preferences ONLY, examples: language, terseness), (b) `.claude/memory/<topic>.md` (project factual knowledge, git-tracked, NOT shipped), (c) `.claude/rules/<topic>.md` (project behavioral rules, git-tracked, SHIPPED to forks via sync-harness) — with explicit guidance on which bucket fits which content

- [ ] `.claude/memory/` directory exists and is git-tracked.
- [ ] `.claude/memory/MEMORY.md` exists as a hand-maintained index file with frontmatter-less, one-line-per-entry shape.
- [ ] CLAUDE.md gains a `## Memory` block pointing at the index, with explicit "lazy-read" framing.
- [ ] At least one cross-reference exists from `.claude/rules/<topic>.md` to a specific `.claude/memory/<topic>.md` file (proves the cross-reference pattern works on day one).
- [ ] No SessionStart hook reads or injects from `.claude/memory/`.
- [ ] `.claude/tools/sync-harness.sh` manifest is NOT modified — `.claude/memory/` is implicitly out-of-scope by exclusion.
- [ ] Tests under `.claude/tests/project-memory/` cover the scenarios above using tmp-dir fixtures.

## Non-goals

- **Auto-loading the MEMORY.md index into context.** Would replay the same scaling failure SESSION.md's "~2KB preview budget" gotcha already documents. The agent reads on demand.
- **Tagging memories for selective auto-load.** A "tag = always-load" subset is tempting but reintroduces the same scaling problem with extra mechanism. Defer until real evidence shows lazy-read is insufficient.
- **Migrating to a different storage format** (sqlite, JSON, custom DSL). Plain markdown files match every other Agent0 artifact and stay diffable in `git log`.
- **Versioning / archiving old memories.** `git log` IS the audit trail. A memory that becomes wrong gets edited or deleted in a normal commit.
- **Searching memories.** `grep -r .claude/memory/` is fine for v1. Search-tool overhead unjustified until corpus grows.
- **Replacing CC per-user memory entirely.** Genuine per-user preferences (language, response terseness) still belong there. This spec adds a third bucket, doesn't kill the second.
- **Auto-promotion from per-user to project.** Detecting "this memory should be project-shared" requires judgment — automation would FP heavily. Manual move via this spec's migration step; future memories the developer places consciously.
- **Shipping memories to forks.** The whole point of `.claude/memory/` (vs `.claude/rules/`) is that forks don't get Agent0-internal design knowledge. Some specific memories MAY later promote to rules or shipped docs if proven broadly useful — that's a per-memory decision, not a default.

## Open questions

- [ ] **Memory file frontmatter shape** — proposal: mirror the CC per-user memory frontmatter (`name`, `description`, `metadata.type`) for consistency. Same fields, same semantics, just a different storage location. Alternative: simpler frontmatter or none (filename + first-line description in MEMORY.md). Lean toward mirror for migration-path simplicity.
- [ ] **MEMORY.md shape** — proposal: plain markdown, no frontmatter on the index itself, one line per entry of the form `- [Title](file.md) — one-line description`. Same shape CC per-user's `MEMORY.md` uses today. Alternative: free-form table or grouped sections. Lean toward mirror.
- [ ] **`memory-placement.md` rewrite scope** — proposal: full rewrite (current 2-bucket model is wrong, not just incomplete). Document the 3 buckets, when each fits, with concrete examples. Alternative: minimal patch adding the third bucket. Lean toward full rewrite for clarity.
- [ ] **Initial memory content** — beyond the 2 migrated files, do we seed `.claude/memory/cc-platform-hooks.md` as part of THIS spec, or defer to spec 020 (runtime-capture-on-failure) where the lesson is concretely actionable? Lean toward seeding it here as the canonical example and FIRST entry, so the system isn't shipped empty; 020 then references it from runtime-introspect.md.

## Context / references

- The drift that motivated this spec: prior conversation discovered Claude Code has 29 hook events, not 9 — the basis for spec 011's foundational assumption was incomplete. Verified via canonical docs <https://code.claude.com/docs/en/hooks>. Lesson belongs in project memory; per-user memory wouldn't propagate to other Agent0 contributors; rules would noisily ship to every fork.
- `.claude/rules/memory-placement.md` — the rule doc this spec rewrites. Current 2-bucket model treats "per-user memory" and "project-shared rules" as the only options, missing the factual-reference middle.
- `.claude/rules/session-handoff.md` § "auto-injection has a ~2KB preview budget" — the documented gotcha that this spec respects by NOT auto-loading memory content into SessionStart context.
- `.claude/tools/sync-harness.sh` § manifest arrays — `.claude/memory/` is implicitly out-of-scope by exclusion (no new entry needed). Confirms the "doesn't ship to forks" design.
- Existing per-user memories under `~/.claude/projects/-home-goat-Agent0/memory/`:
  - `project_agent0_purpose.md` — substantive project knowledge, candidate for migration.
  - `project_visibility_intent.md` — substantive project decision, candidate for migration.
  - `user_language.md` — genuine per-user preference, stays.
- Spec 020 (next, `runtime-capture-on-failure`) — will be the first consumer of `.claude/memory/cc-platform-hooks.md` via a cross-reference from `.claude/rules/runtime-introspect.md`.
- Claude Code canonical event reference: <https://code.claude.com/docs/en/hooks> (verified via WebFetch this session — 29 events including `PostToolUseFailure`, `PostToolBatch`, `Setup`, etc.).
