# 019 — project-memory — plan

_Drafted from `spec.md` on 2026-05-11. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Pure-additive. No new code (no hooks, no tools, no scripts) — the whole capacity is a directory convention plus an instruction layer. The agent consumes it via standard file reads driven by CLAUDE.md guidance and cross-references from existing rule docs. Scaling is bounded by disk only, not by context budget — discovery is on-demand.

**Post-implementation amendment (2026-05-11):** the empty scaffold (`.claude/memory/.gitkeep`) IS shipped to forks via the sync-harness manifest, while memory CONTENT (`MEMORY.md` + `<topic>.md` files) stays project-local. The capacity is universal — every project that adopts Agent0 also gains its own project-memory bucket. The content is one-source per project, never cross-pollinated. Without the scaffold shipping, fork users would read the `## Memory` block in CLAUDE.md, find the rule, and then face an empty directory hunt — friction we can eliminate with one manifest entry.

Four moving parts:

1. **New directory `.claude/memory/`** at repo root. Contains one markdown file per memory topic + a hand-maintained `MEMORY.md` index. Files use the same frontmatter shape as Claude Code's per-user memory (`name`, `description`, `metadata.type`) so the mental model is identical — only the storage location differs. Type values are the same vocabulary the CC per-user system uses (`project`, `feedback`, `reference`, `user`) since the dimensions are stable, but project memory will skew toward `project` and `reference` (preferences stay per-user).

2. **`.claude/memory/MEMORY.md` index** — plain markdown, one bullet per entry of the form `- [Title](file.md) — one-line description`. Mirrors the CC per-user index exactly. Lazy-read by the agent when the CLAUDE.md `## Memory` block instructs (or when a cross-reference points at a specific file directly). No frontmatter on the index itself.

3. **CLAUDE.md gains a `## Memory` block** between `## Harness sync` and `## Compact Instructions`. Five-ish lines explaining: project memory lives in `.claude/memory/`, read `MEMORY.md` (index) when starting work that may benefit from prior decisions / gotchas / platform constraints, files are factual reference (NOT behavioral mandates — those are in `.claude/rules/`). Emphasizes "lazy-read" so the agent doesn't reflexively try to load everything.

4. **`.claude/rules/memory-placement.md` full rewrite** — current 2-bucket model (project-shared rules + per-user) is wrong, not incomplete. New 3-bucket model:
   - **`~/.claude/projects/<path>/memory/`** — CC per-user memory, **preferences ONLY** (language, terseness, style). Loses on machine switch by design; if it's worth carrying across developers, it doesn't belong here.
   - **`.claude/memory/<topic>.md`** — project factual knowledge. Git-tracked, propagates via PR/clone, **NOT shipped to forks** (no entry in sync-harness manifest). Discovered via CLAUDE.md instruction + rule-doc cross-references.
   - **`.claude/rules/<topic>.md`** — project behavioral rules + capacity operational docs. Git-tracked, **SHIPPED to forks** via sync-harness. The agent SHOULD comply; bugs ride with the capacity.

Migration as part of this spec: two of three existing per-user memories (substantive project knowledge) move to `.claude/memory/`; one (preference) stays. First seeded memory beyond the migration is `cc-platform-hooks.md` capturing the 29-event discovery — both because the lesson is real and pressing, AND because it serves as the canonical example referenced by `.claude/rules/runtime-introspect.md` (proves the cross-reference pattern works on day one).

Cross-reference seeding: `runtime-introspect.md` § Gotchas gains one sentence at the end of the "Claude Code's `tool_response.exit_code` does NOT exist" bullet pointing at `.claude/memory/cc-platform-hooks.md`. That's the entry point for spec 020.

## Files to touch

**Create:**
- `.claude/memory/` (directory) with `.gitkeep` so empty-directory case is git-trackable until first content lands.
- `.claude/memory/MEMORY.md` — hand-maintained index; initial state lists 3 entries (the 2 migrated + cc-platform-hooks).
- `.claude/memory/agent0-purpose.md` — migrated from per-user `project_agent0_purpose.md`. Trim `originSessionId` field (no value cross-machine) but keep `name`/`description`/`type`/body.
- `.claude/memory/visibility-intent.md` — migrated from per-user `project_visibility_intent.md`. Same trim.
- `.claude/memory/cc-platform-hooks.md` — NEW. Captures the 29-event canonical list with one-line description per event, payload-shape notes for the 3 we touch today (`PreToolUse`, `PostToolUse`, `PostToolUseFailure`), explicit "exit-zero vs non-zero" sentence, link to canonical docs at <https://code.claude.com/docs/en/hooks>.
- `.claude/tests/project-memory/01-files-are-git-tracked.sh` — RED scenario 1: tmp fork fixture, assert `.claude/memory/` exists in Agent0 and `git ls-files` shows the migrated files.
- `.claude/tests/project-memory/02-no-fork-propagation.sh` — RED scenario 2: tmp fork target, run sync-harness `--apply`, assert no file from Agent0's `.claude/memory/` lands in the fork.
- `.claude/tests/project-memory/03-claude-md-has-memory-block.sh` — RED scenario 3: grep CLAUDE.md for `^## Memory` and a sentence containing `.claude/memory/MEMORY.md`.
- `.claude/tests/project-memory/04-sessionstart-no-memory-block.sh` — RED scenario 4: invoke session-start.sh with a fixture that has 5+ memory files; assert stdout contains NO `project-memory` block string AND no memory file content.
- `.claude/tests/project-memory/05-rule-cross-reference.sh` — RED scenario 5: grep `.claude/rules/runtime-introspect.md` for a literal reference to `.claude/memory/cc-platform-hooks.md`.
- `.claude/tests/project-memory/06-migration-shape.sh` — RED scenario 6: assert `.claude/memory/agent0-purpose.md` and `.claude/memory/visibility-intent.md` exist with correct frontmatter fields (`name`, `description`, `type`), and `user_language.md` still exists in CC per-user.
- `.claude/tests/project-memory/07-memory-placement-3-buckets.sh` — RED scenario 7: grep `.claude/rules/memory-placement.md` for explicit mention of all three bucket paths.
- `.claude/tests/project-memory/run-all.sh` — driver mirroring previous specs' shape.
- `.claude/tests/project-memory/README.md` — one-line numbering convention note.

**Modify:**
- `CLAUDE.md` — insert `## Memory` block immediately before `## Compact Instructions`, after `## Harness sync`. ~5-7 lines.
- `.claude/rules/memory-placement.md` — full rewrite. Documents the 3 buckets with concrete examples drawn from the migration (`project_agent0_purpose` → project, `user_language` → per-user, `delegation.md` → rule).
- `.claude/rules/runtime-introspect.md` — extend the existing "Claude Code's `tool_response.exit_code` does NOT exist" gotcha with one sentence: "See `.claude/memory/cc-platform-hooks.md` for the canonical event surface and the PostToolUse-on-success-only behavior."
- `~/.claude/projects/-home-goat-Agent0/memory/MEMORY.md` (the CC per-user index) — remove the two entries that migrated; leave `user_language` entry intact.

**Delete:**
- `~/.claude/projects/-home-goat-Agent0/memory/project_agent0_purpose.md` (migrated).
- `~/.claude/projects/-home-goat-Agent0/memory/project_visibility_intent.md` (migrated).

## Alternatives considered

### SessionStart hook auto-loads `MEMORY.md` index

Rejected because doesn't scale. Already documented gotcha in `.claude/rules/session-handoff.md`: SESSION.md auto-injection has a ~2KB preview budget. Replicating that with a memory index hits the same wall when memories grow — and unlike SESSION.md (which is naturally short-lived and replaced), memory grows monotonically. CC's per-user memory uses auto-load with a 200-line truncation cap; that's the wrong default for a system intended to grow into the hundreds or thousands of entries. Pure-instruction lazy-read scales without further design.

### `.claude/memory/` lives under sync-harness manifest and ships to forks

Rejected because most memories are Agent0-internal design knowledge that's noise for fork consumers (e.g. "29 CC hook events" reference matters when extending the harness, but pyshrnk doesn't extend, it consumes). Specific memories that ARE broadly useful can be promoted to rule docs or shipped reference files on a case-by-case basis. Default-not-ship keeps fork payloads clean; case-by-case promotion handles edge cases without inverting the default.

### Store memory in `docs/memory/` instead of `.claude/memory/`

Rejected for adjacency reasons. Every other "harness-relevant" artifact lives under `.claude/` (rules, hooks, tools, validators, skills, tests, agents). Putting memory in `docs/` would force a mental-model split where the agent has to remember "memory is the one Agent0 artifact NOT under `.claude/`". The sync-harness manifest is explicit enough that `.claude/memory/` not shipping is governable from one location without needing geographic separation.

### Grouped-dimension memory files (one file per dimension: `platform.md`, `decisions.md`, `gotchas.md`)

Rejected because dimensions overlap and the boundary moves. The 29-event discovery is BOTH platform knowledge AND a decision-influencing fact AND a gotcha. Forcing it into one bucket loses retrieval cues; duplicating across buckets corrupts the "one source of truth" property. One file per topic + index lets each memory have a discrete identity that resists category-creep. Same reasoning Claude Code's per-user memory uses today; no need to invent a different convention.

### Tag-based auto-load (memories with `metadata.always_load: true` get inlined at SessionStart)

Rejected for v1 — reintroduces the scaling problem with extra mechanism (now we have BOTH an index AND a tag system). If real evidence shows lazy-read leaves the agent under-informed on some specific high-value memory, that memory's content can be cross-referenced from a more-loaded location (CLAUDE.md itself, a relevant rule doc), or promoted to a rule. Defer tag-based auto-load until a concrete memory demonstrates the need.

## Risks and unknowns

- **CLAUDE.md `## Memory` block crowding.** Adding another `## <Title>` section grows the auto-loaded context. Mitigation: keep the block to ≤ 7 lines (smaller than `## Harness sync`'s footprint); the marginal cost is bounded.
- **Cross-reference rot.** Rule docs that point at memory files become stale if memory files are renamed/deleted. Mitigation: same risk as any markdown cross-reference; `grep -r ".claude/memory/"` finds orphans for periodic audit. No automated guard in v1.
- **Migration completeness.** Forgetting to delete migrated per-user files leaves duplicate sources of truth. The migration task list (Phase 3) deletes explicitly with `rm` named per file. Verified by scenario 6 test.
- **Frontmatter drift between project memory and CC per-user memory.** If CC's per-user memory frontmatter shape evolves (Anthropic adds a field), project memory may diverge. Mitigation: documented in `memory-placement.md` that the shapes are mirrored "for v1; resync if the upstream shape changes". Low frequency, low impact.
- **Agent forgets to consult memory.** A pure-instruction system relies on the agent reading CLAUDE.md and following the guidance. If the agent skips it on a session, memory provides no value. Mitigation: the CLAUDE.md block is concise enough to be read every session; specific rule docs that benefit from memory cross-reference it (so the prompt is restated when working in that area). If real failure surfaces, candidate v2 is a SessionStart line emitting just the index path (not content), but that's reactive.
- **First-fork sync surprise.** Forks that already adopted sync-harness will see `.claude/memory/` in Agent0 but NOT in their tree — and the sync tool will silently skip it (not in manifest). Documented in `.claude/rules/harness-sync.md` § Manifest scope as the implicit out-of-scope category. No code change needed; verifying the docs make the absence obvious.
- **`MEMORY.md` index drift.** The index is hand-maintained — adding a memory file without updating the index leaves it undiscoverable. Mitigation: discipline + occasional `ls .claude/memory/ | wc -l` vs index line count. v2 could ship a `lint` that compares directory listing vs index entries; not needed for v1.

## Research / citations

- Codebase: `.claude/rules/memory-placement.md` — the 2-bucket rule doc this spec rewrites.
- Codebase: `~/.claude/projects/-home-goat-Agent0/memory/MEMORY.md` + 3 entry files — the per-user system whose substantive memories migrate.
- Codebase: `.claude/tools/sync-harness.sh` manifest constants — verifies that `.claude/memory/` is implicitly out-of-scope (not in `COPY_CHECK_RECURSIVE` / `COPY_CHECK_GLOBS` / `COPY_CHECK_FILES`).
- Codebase: `.claude/rules/session-handoff.md` § "~2KB preview budget" — the precedent for rejecting auto-load at scale.
- Codebase: `.claude/rules/spec-driven.md` § "When SDD applies" — confirms this multi-file + new-convention change qualifies.
- External: <https://code.claude.com/docs/en/hooks> — the canonical event surface that motivates the seed `cc-platform-hooks.md` content. Verified this session via WebFetch.
- Live evidence: spec 011 (`docs/specs/011-runtime-introspect/`) — the capacity built on incomplete CC platform knowledge; first concrete consumer of `cc-platform-hooks.md` via cross-reference from `runtime-introspect.md`. Spec 020 (next) will leverage this cross-reference.
- Conversation 2026-05-11: user pushback against `.claude/rules/` placement (rules ship to forks) and against auto-load (doesn't scale to 10k memories). Both drove the final shape.
