# 102 — harness-consolidate-agent0

_Created 2026-05-28._

**Status:** in-progress
**Type:** umbrella

## Intent

Consolidate the Agent0 harness into a single canonical home: `.agent0/`. Today the harness is split — runtime-neutral capacities (memory, session-handoff hooks, HANDOFF.md) already live under `.agent0/`, while other runtime-neutral state and data (reminders, routines, session/runtime/browser state, shared shell tools) still live under `.claude/` for historical reasons. `.claude/` is Claude Code's *conventional home*, not a runtime-neutral one; keeping shared harness state there forces every multi-runtime port to reason about "is this Claude-owned or shared?" on a path-by-path basis.

The target end-state is a clean ownership split: **`.agent0/` holds everything the Agent0 harness defines as runtime-neutral** (shared hooks, shared tools, shared state/data, canonical artifacts); **`.claude/` and `.codex/` hold only what is exclusive to that runtime** (Claude `settings.json` + Claude-only hooks like delegation; Codex `config.toml` + Codex-only wiring). This makes the multi-runtime story mechanical: a new runtime registers the `.agent0/` capacities through its own native surface, and the only runtime-specific files are the registration manifests. This umbrella tracks the per-surface relocation; it ships no code itself — acceptance is the closure of every row in § Gap matrix.

## Classification principle

A surface belongs under `.agent0/` if **both** runtimes (or a future runtime) would read/write it through the harness. A surface stays under `.claude/` / `.codex/` only if it is **genuinely exclusive** to that runtime's mechanism (e.g. Claude's `settings.json` hook format, the Claude-only `Agent` delegation tool and its audit log, Claude's PreCompact snapshot pair).

The "shared" test: _in a Codex-only consumer project that never opens Claude Code, would this file still be read or written?_ If yes → `.agent0/`. If it is dead weight without Claude → `.claude/`.

## Acceptance criteria

_Umbrella acceptance = every § Gap matrix row reaches a terminal disposition (`shipped` move, or `stays` with recorded reasoning). No code ships from this spec; child specs do the work._

- [ ] Every `move` row in § Gap matrix has its child spec shipped (path relocated, all references updated, tests green, sync-harness manifest updated).
- [ ] Every `stays` row has a one-line reasoning recorded in the matrix (why it is runtime-exclusive).
- [x] Every `undecided` row is resolved to `move`, `stays`, or `deferred` before this umbrella closes. A `deferred` row must name its revisit trigger (e.g. "when Codex needs rules") — deferral is a recorded decision, not an open ambiguity. _(Done 2026-05-28: rows 3/4/5/6 → `move`; rows 7-9 + 14 `deferred` with named triggers; rows 10-13 `stays`. No `undecided` row remains. Row 14 (brainstorm-state) added 2026-05-28 tied to row 8.)_
- [x] The § Classification principle is encoded durably where future contributors find it, so the split survives this umbrella as a convention. _(Done 2026-05-28: encoded as project memory `.agent0/memory/harness-home.md`, NOT a shipped rule. The principle binds the upstream maintainer relocating a surface; a consumer-side agent in a consume-only fork never reads it, so by the rule-vs-memory criterion in `.claude/rules/memory-placement.md` § Routing decision tree it routes to `.agent0/memory/` rather than `.claude/rules/`. The AC's original "a rule under `.claude/rules/`" framing was superseded by that routing analysis.)_
- [x] Consumer-migration posture is documented once in `.claude/rules/harness-sync.md`: relocations are **capacity-only** (new consumer projects are born under `.agent0/`; existing consumer projects migrate their own data manually on next sync) — no upstream auto-migration of consumer content. _(Done 2026-05-28: § Path relocations (capacity-only) generalized from the spec-103 example to all of umbrella 102's relocations + "fork"→"consumer project" terminology aligned with the rule's own glossary.)_

## Gap matrix

Disposition: `move` → relocate to `.agent0/`; `stays` → runtime-exclusive, keep where it is; `undecided` → needs its own research/decision before assignment.

| # | Surface | Current path | Disposition | Phase / child spec | Status |
|---|---|---|---|---|---|
| 1 | reminders data + capacity wiring | `.claude/reminders.yaml` → `.agent0/reminders.yaml` | `move` | Phase 1 — `103-reminders-routines-to-agent0` | shipped |
| 2 | routines data + per-machine state | `.claude/routines/` → `.agent0/routines/`, `.claude/.routines-state/` → `.agent0/.routines-state/` | `move` | Phase 1 — `103-reminders-routines-to-agent0` | shipped |
| 3 | session-state (shared by both runtimes) | `.claude/.session-state/` → `.agent0/.session-state/` | `move` | Phase 2 — `104-state-dirs-to-agent0` (shipped) | **shipped** (104, 2026-05-28); reverses 101 OQ-E. The shared 4-file contract is written by **both** runtimes' session hooks, which already live in `.agent0/hooks/` — by the § Classification principle the state belongs there too. Child updates the `probe.sh` boundary + test fixtures; Claude-regression covered by the existing `session-state-isolation` suite |
| 4 | runtime-introspect state | `.claude/.runtime-state/` → `.agent0/.runtime-state/` | `move` | Phase 2 — `104-state-dirs-to-agent0` (shipped) | **shipped** (104, 2026-05-28). The neutral reader `probe.sh` moves (row 6), so its state moves with it rather than re-creating the split. **Caveat:** the producer (`runtime-capture.sh` / `runtime-pre-mark.sh`) stays Claude-only — only the state-dir *path* moves; re-home the producer if/when a Codex runtime-capture port lands |
| 5 | browser-auth state | `.claude/.browser-state/` → `.agent0/.browser-state/` | `move` | Phase 2 — `104-state-dirs-to-agent0` (shipped) | **shipped** (104, 2026-05-28); both runtimes via Playwright MCP + human headed write. Smallest blast radius (~8 refs); credential-class gitignore (`*.json` ignored, `.gitkeep` tracked) carries over |
| 6 | shared shell tools | `.claude/tools/*.sh` (sync-harness, probe, lib, routines, instruction-drift, `codex-local-env`) → `.agent0/tools/` | `move` | Phase 3 — `105-shared-tools-to-agent0` (shipped) | **shipped** (105, 2026-05-28). All 8 scripts + `lib/managed-block.sh` relocated; `.claude/tools/` removed. Closed the four delicate spots: sync-harness's manifest glob + lib-source + `_self_rebootstrap` self-ref + `MANAGED_BLOCK_LIB` fallback, and the three path-scoped rule `paths:` triggers (`harness-sync`/`runtime-capabilities`/`runtime-introspect`). Live refs rewritten, frozen `docs/specs/` + one historical memory narrative (`cc-platform-hooks.md:138`) left. 87 affected-suite tests green; capacity-only migration confirmed (dry-run: old `.claude/tools/*.sh` orphan-removed, new `.agent0/tools/*.sh` copied) |
| 7 | rules (behavioral mandates, ship to consumers) | `.claude/rules/` | `deferred` | when Codex needs rules | revisit when Codex consumes rules; decide share-vs-per-runtime then. `CLAUDE.md` AND `AGENTS.md` both point at `.claude/rules/` |
| 8 | skills | `.claude/skills/` | `deferred` | when Codex needs skills | revisit when Codex needs the skills; decide share-vs-per-runtime then. Invoked via CC Skill tool (cc-native) today |
| 9 | validators | `.claude/validators/` | `deferred` | with rows 7-8 | tied to the rules/skills decision; consumed by Claude `post-edit-validate.sh` today |
| 10 | Claude hook registrations | `.claude/settings.json` | `stays` | — | Claude-specific hook-config format; the runtime-exclusive manifest by definition |
| 11 | delegation state + audit | `.claude/.delegation-state/`, `.claude/delegation-audit.jsonl` | `stays` | — | Claude `Agent` tool is Claude-exclusive (Codex has no subagent surface) |
| 12 | compact-history snapshots | `.claude/.compact-history/` | `stays` (provisional) | — | produced by Claude `PreCompact`; Codex compaction port deferred (101 non-goal) |
| 13 | Claude-only hooks | `.claude/hooks/*.sh` (delegation, governance, secrets, supply-chain, runtime-capture, pre-compact, propagation-advise, rule-load-debug) | `stays` | — | registered only via Claude `settings.json`; no Codex analogue wired |
| 14 | brainstorm session state | `.claude/.brainstorm-state/` → `.agent0/.brainstorm-state/` | `deferred` | tied to row 8 (skills) | Added 2026-05-28 (closes a classification lacuna — was invisible to this matrix, like `.claude/tests/`). Gitignored, **zero tracked content** (not even a `.gitkeep`); not in the sync-harness manifest. Its **sole** producer/consumer is `.claude/skills/brainstorm/SKILL.md` (10 hardcoded `.claude/.brainstorm-state/` paths). By the co-location-with-producer pattern (104: state moves *with* its producer — runtime-state followed probe.sh, session-state followed its `.agent0/hooks/`), this state must NOT move ahead of its skill. Revisit trigger = row 8's (when a Codex brainstorm port lands / skills get their shared-vs-per-runtime decision); the state relocates in the same diff as the skill, rewriting the 10 hardcoded paths then. Moving it now would re-create the exact state/producer split this umbrella kills |

## Non-goals

- Auto-migrating consumer-project content. Relocation is capacity-only (per § Acceptance) — forks move their own data.
- Moving runtime-exclusive surfaces (`settings.json`, delegation, Claude-only hooks) — they are correctly placed.
- Boiling the ocean in one diff. Each `move` row is its own child spec with its own tests + sync-harness manifest update; this umbrella never lands a mega-diff.
- Changing any capacity's *behavior*. These are pure relocations + reference rewrites; the contract of each capacity is unchanged.
- Renaming `.agent0/` itself or introducing a third top-level dir.

## Open questions

- [x] ~~Row 3 (session-state): does relocating it to `.agent0/.session-state/` justify the `probe.sh` boundary rewrite + Claude-regression risk, or is it the one shared surface that pragmatically stays?~~ → **Resolved 2026-05-28: `move`.** Phase 1 (rows 1-2) proved the relocation pattern; 101 OQ-E was a pragmatic pause ("hooks move, state stays") that the § Classification principle explicitly reopens. The 4-file contract is written by both runtimes, so the shared test says `.agent0/`. The `probe.sh` boundary rewrite is a single-line reference update, not a behavior change; Claude-regression is covered by the `session-state-isolation` suite that rides into the child spec. Rows 4-5 ride the same Phase-2 child (`104-state-dirs-to-agent0`).
- [ ] Rows 7-9 (rules/skills/validators): **deferred by decision (2026-05-28)** until Codex actually needs the rules/skills. At that point decide between a *shared* `.agent0/` location vs *per-runtime* files (each runtime carries its own). Not blocking this umbrella's other rows; revisited when the Codex-consumes-skills/rules trigger fires.
- [ ] Where exactly the § Classification principle is encoded — new `.claude/rules/harness-home.md` vs extending `.claude/rules/memory-placement.md`'s bucket model.

## Context / references

- `docs/specs/103-reminders-routines-to-agent0/` — Phase 1 child (this umbrella's first deliverable).
- `docs/specs/099-memory-multi-runtime/`, `100-multi-runtime-session-readouts/`, `101-session-handoff-multi-runtime/` — the multi-runtime lineage that already moved hooks + memory + HANDOFF to `.agent0/`; this umbrella finishes the job for the remaining shared surfaces.
- `docs/specs/101-session-handoff-multi-runtime/spec.md` § Open questions OQ-E — the prior decision to keep `.claude/.session-state/` in place (row 3 reopens it).
- `.claude/rules/memory-placement.md` — the 3-bucket model; the § Classification principle here is its generalization to all harness state.
- `.claude/rules/harness-sync.md` + `.claude/tools/sync-harness.sh` — the manifest each `move` row must update; consumer-migration posture documented here.
- `docs/specs/060-harness-gaps-2026/spec.md` — prior umbrella-spec shape this mirrors (gap matrix + closure acceptance).
