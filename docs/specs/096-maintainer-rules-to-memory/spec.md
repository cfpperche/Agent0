# 096 — maintainer-rules-to-memory

_Created 2026-05-27._

**Status:** shipped

## Intent

Three rules in `.claude/rules/` document capacities that only the upstream maintainer ever extends — `hook-chain-latency.md` (budget + bench tooling for adding new `PreToolUse(Bash)` hooks), `compaction-continuity.md` (internal mechanism of the PreCompact/SessionStart snapshot pair), and `rule-load-debug.md` (opt-in observability for `InstructionsLoaded` events, off by default). Per `memory-placement.md`'s 3-bucket model, content that binds the maintainer rather than the consumer-side agent belongs in `.claude/memory/` (project-local, not propagated by `sync-harness.sh`). This spec reclassifies the three files, rewires every reference to them, prunes the managed-block sections in `CLAUDE.md` + `AGENTS.md` that pointed downstream, and updates `memory-placement.md` to make the criterion explicit so future drift gets caught at write time. Executable tooling (`bench-hooks.sh`, `.perf-baseline.json`, the test suites, the `probe.sh rule-loads` invocation) stays in place — only the descriptive prose moves.

## Acceptance criteria

- [x] **Scenario: consumer sync after move sees no rule drift for the three files**
  - **Given** a fresh consumer at `/home/goat/mei-saas` previously synced with the upstream that still carried the three rules under `.claude/rules/`
  - **When** the maintainer runs `bash .claude/tools/sync-harness.sh --check --agent0-path=/home/goat/Agent0 /home/goat/mei-saas` after this spec lands
  - **Then** the three files appear under `- removed` (orphan deletion, baseline-driven) and no entry under `! customized` references them, and the summary shows `0 customized-refused` for the three paths

- [x] **Scenario: consumer session loads no managed-block pointer to the moved capacities**
  - **Given** a consumer that has applied the post-move sync
  - **When** Claude Code loads `CLAUDE.md` at session start
  - **Then** the managed block contains no `## Hook chain latency`, `## Compaction continuity`, or `## Rule load debug` section, and the same is true for `AGENTS.md`

- [x] **Scenario: maintainer reads moved content via memory index**
  - **Given** the maintainer is working in `/home/goat/Agent0` and opens `.claude/memory/MEMORY.md`
  - **When** they scan the index
  - **Then** three new lines link to `hook-chain-latency.md`, `compaction-continuity.md`, and `rule-load-debug.md` under `.claude/memory/`, with the same one-line description style as the existing entries

- [x] `.claude/memory/hook-chain-latency.md`, `.claude/memory/compaction-continuity.md`, `.claude/memory/rule-load-debug.md` exist and pass the frontmatter validator (`name`, `description`, `metadata.type` all present per `memory-placement.md` § Frontmatter schema)

- [x] `.claude/rules/hook-chain-latency.md`, `.claude/rules/compaction-continuity.md`, `.claude/rules/rule-load-debug.md` no longer exist

- [x] Every cross-reference under `.claude/{hooks,tools,rules,skills,tests}/` that previously pointed to `.claude/rules/<moved-slug>.md` now points to `.claude/memory/<moved-slug>.md` — or has the pointer removed when the reference was purely a "see also" with no behavioral dependency

- [x] `CLAUDE.md` managed block no longer contains the three sections (`## Hook chain latency`, `## Compaction continuity`, `## Rule load debug`); `AGENTS.md` mirrors the same removal

- [x] `.claude/rules/memory-placement.md` § *Routing decision tree* is updated to make the maintainer-binding-vs-consumer-binding criterion explicit (a paragraph or table entry that names "capacity operational docs the consumer-side agent never acts on" as a memory case, not a rule case), so a future capacity authored against the wrong bucket gets caught at review time

- [x] `bash .claude/tools/sync-harness.sh --check --agent0-path=/home/goat/Agent0 .` against the upstream itself runs clean post-change (no spurious customized-refused or unparseable-frontmatter advisory)

- [x] `.claude/tests/hook-chain-latency/`, `.claude/tests/compaction-continuity/` test suites still pass after the rewire (they validate executable behavior, not doc location, so they should be unaffected; the AC is the empirical check)

## Non-goals

- **Splitting the two borderline rules** (`propagation-advisory.md`, `runtime-introspect.md`). Both were flagged in the audit as candidates for split (user-facing override grammar in rules, maintainer extension mechanism in memory) but the splits are non-trivial and orthogonal to the three clear-cut moves. Defer to a follow-up spec if signal warrants.
- **Moving the executable tools** (`bench-hooks.sh`, `bench-hooks.sh --check`, `probe.sh rule-loads`, the `.perf-baseline.json` baseline, the test suites under `.claude/tests/`). They ship as harness capacity; only the descriptive prose changes location.
- **Touching consumer-side baselines** (`.claude/.perf-baseline.json` in mei-saas / codexeng). Those regenerate on the next consumer `--apply`; this spec is upstream-only.
- **Re-auditing the remaining 22 rules** beyond the three confirmed moves. The audit's KEEP list (20 rules) is accepted as-is in v1; revisit if a similar trigger surfaces.
- **Migrating moved memory files to use the cap/decay frontmatter fields** (`created_at`, `last_accessed`, `confirmed_count`). The required fields are sufficient for the move; optional decay metadata can backfill later via `memory-backfill-metadata.sh` once the entries exist.

## Open questions

- [x] Should the moved files retain their full content verbatim, or trim wording that explicitly framed them as "rule-shaped" (e.g. "this rule documents…" headers, § *Override marker* sections that don't apply to a memory file)? **Recommendation: minimal touch in v1** — rename headings only where literally inaccurate, leave structural content; trimming is scope-creep risk and the decay engine will surface stale phrasings naturally over time.
- [x] Should the three moved files keep their cross-reference sections pointing back to project rules (`.claude/rules/delegation.md` § *Advisories*, etc.)? **Recommendation: yes, keep them** — the maintainer reads memory entries when working on the capacity itself, and cross-refs to the live rule surface remain accurate.
- [x] Are there OTHER files outside the search scope (`docs/specs/**`, `.agent0/HANDOFF.md`, `.claude/memory/*.md`) that reference the three moved rules and should be updated for path-correctness? **Recommendation: leave historical mentions in `docs/specs/**` intact** (spec history is point-in-time and rotting refs are acceptable per propagation-hygiene gotchas); update only the currently-loaded surfaces. **Resolved during implementation:** updated `.claude/memory/{hook-chain-maintenance,cc-platform-hooks,capacity-spec-index}.md` (live memory cross-refs), `.claude/.runtime-state/README.md` (synced — ships to consumers), and `site/src/i18n/capacities.ts` (Agent0 marketing site). Left untouched: `docs/specs/**` historical mentions, `.claude/memory/propagation-hygiene.md` documentary prose at line 66.

## Context / references

- `.claude/rules/memory-placement.md` § *The 3 buckets* + § *Routing decision tree* — the canonical criterion this spec enforces
- `.claude/rules/harness-sync.md` § *Manifest* — confirms `.claude/memory/` ships scaffold-only (`.gitkeep`), not content, so the move automatically stops propagating these three to consumers
- `.claude/memory/MEMORY.md` — the index where the three moved entries register
- This session's audit conversation (2026-05-27): 25-rule classification surfaced the three clear-cut moves + two borderline cases. The user's original trigger was `hook-chain-latency.md` appearing in consumer context with no consumer use-case.
- `MEMORY.md` user-memory entry [Agent0 changes ship via rules, not memory](feedback_agent0_changes_ship_via_rules_not_memory.md) — the symmetric direction (mandates → rules); this spec covers the inverse (maintainer-only capacity docs → memory)
