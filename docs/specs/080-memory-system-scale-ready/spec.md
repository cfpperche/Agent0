# 080 — memory-system-scale-ready

_Created 2026-05-23._

**Status:** draft
**Type:** umbrella

## Intent

Evolve Agent0's project-memory bucket (`.claude/memory/`) and reminders capacity (`.claude/REMINDERS.md`) to operate at complex-project scale — ~100-500 entries, parallel sessions, multi-contributor forks — without shipping policy-leak.

Current state: 13 plain markdown entries with a hand-edited `MEMORY.md` index; reminders as plain bullets; no frontmatter schema validation; no decay; no event-sourcing; per-compaction snapshot overwrites the previous. The system works at solo-founder scale and breaks at production-fork scale (parallel-session clobber, frontmatter drift, index bloat, stale crowding, compact-overwrite loss). Anthill resolved each of these failure modes mechanically over 6 weeks of dogfood (see `/tmp/research/anthill.md`). This umbrella ports the *mechanisms* — event-sourcing, schema validator, decay engine with transparent defaults, per-compaction history, programmable reminders — without porting the *policies* (drawer taxonomy, tier caps, founder profile YAML, auto-memory sync).

Agent0 is itself an agentic product, shipping to forks via `sync-harness.sh`. A fork operating on a complex software project at scale needs the memory system to be *capable of scale* even if Carlos's Agent0 repo doesn't yet hit it. Saying "we don't need it because we don't use it" limits Agent0 to small-project forks.

## Acceptance criteria

This umbrella is **shipped** when every row in the gap matrix below has its child spec at status `shipped`. Per `.claude/rules/spec-driven.md` § *The four artifacts*, umbrella acceptance is gap-matrix closure, not a code delta.

### The 7 mechanisms (gap matrix)

| MS | Capacity | Child spec | Status | Notes |
|---|---|---|---|---|
| MS-1 | Frontmatter schema (3 required + 3 optional) + validator hook (PostToolUse advisory) | 082 | pending | Foundation for MS-2, MS-5, MS-7 |
| MS-2 | Event-sourced memory always-on + raw-edit gate + projection helper | 083 | pending | Requires 082; rejects parallel-session clobber |
| MS-3 | Per-compaction snapshot history (`.claude/.compact-history/<ISO>.md`) | 081 | ✓ shipped | Fixed documented gotcha in compaction-continuity.md (2026-05-23) |
| MS-4 | `.claude/reminders.yaml` refactor + `check_command` + snooze | 084 | pending | Manual migration of existing bullets; no migration tooling |
| MS-5 | Index-line length cap (250 chars) + `memory-query.sh` | 085 | pending | Requires 082+083; paired with MS-7 |
| MS-6 | Runtime-state subsystem README (`.claude/.runtime-state/README.md`) | 081 | ✓ shipped | Enumerates 6 existing state subsystems with rule pointers (2026-05-23) |
| MS-7 | Decay engine (advisory-default) + confirm/archive helpers + readout hook | 085 | pending | Default formula transparent + overridable; `auto_archive: false` |

Estimated total: ~1.440 LOC across 4 child specs (081, 082, 083, 084, 085).

### Closure scenarios

- [x] **Scenario: 081 closure** — **Given** child spec 081 covering MS-3 + MS-6 exists; **When** 081 status flips to `shipped`; **Then** rows MS-3 and MS-6 in the gap matrix above flip to ✓ and `081 status: shipped`.
- [ ] **Scenario: 082 closure** — **Given** child spec 082 covering MS-1 exists; **When** 082 ships; **Then** the MS-1 row flips to ✓.
- [ ] **Scenario: 083 closure** — **Given** child spec 083 covering MS-2 exists AND 082 is shipped; **When** 083 ships; **Then** the MS-2 row flips to ✓ and dependency is satisfied.
- [ ] **Scenario: 084 closure** — **Given** child spec 084 covering MS-4 exists; **When** 084 ships; **Then** the MS-4 row flips to ✓.
- [ ] **Scenario: 085 closure** — **Given** child spec 085 covering MS-5 + MS-7 exists AND 082+083 are shipped; **When** 085 ships; **Then** rows MS-5 and MS-7 flip to ✓.
- [ ] All 4 non-goals (NG-1..NG-4) are documented in `.claude/rules/memory-placement.md` as explicit boundaries; at least one mechanism's child spec text cross-references the NG it respects.

## Non-goals

Four explicit boundaries — Agent0 ships mechanisms, not policies. Each NG documents an Anthill primitive that we **reject** as policy-leak.

- **NG-1 — No cross-bucket sync between auto-memory and project-memory.** The 3-bucket model in `.claude/rules/memory-placement.md` mandates isolation between `~/.claude/projects/<path>/memory/` (CC auto-memory, per-user, single-machine) and `.claude/memory/` (project memory, project-team via clone). Anthill ships `memory-sync-in.sh` + `memory-sync-out.sh` for bidirectional sync — this conflates two distinct audiences with two distinct propagation properties. Agent0 explicitly rejects this pattern. No mechanism in this umbrella reads from one bucket and writes to the other.

- **NG-2 — No founder/user behavioral profile YAML inside `.claude/memory/`.** Per-user behavioral calibration is CC auto-memory territory (Anthropic-side, per-user-per-machine). Project memory holds project facts, not user traits. Anthill's `.anthill/memory/founder/<email>/profile.yaml` (typed traits + dimensions + confidence + evidence) is the canonical anti-pattern — it places per-user state inside project memory, breaking NG-1's separation. Agent0's `~/.claude/projects/.../memory/user_*.md` covers this need in the correct bucket.

- **NG-3 — No drawer taxonomy shipped.** Anthill ships a fixed 6-drawer taxonomy (`architecture|feedback|project|reference|consolidated|invariants`) enforced via JSON Schema `allOf` coupling. Adding a drawer requires schema edit. This is a *policy* (project semantics vary). Agent0 ships the *mechanism* — frontmatter schema validator with extensible `type` field — and lets the fork declare its taxonomy in `.claude/memory.config.json`. The shipped base schema requires `type` but does not constrain its value set.

- **NG-4 — No frozen tier system with shipped caps/decay thresholds.** Anthill ships a fixed L1-L4 tier system with caps `L2=30 / L3=15 / L4=5` and decay windows `L3=60d / L4=∞`. These numbers are derived from Anthill's specific dogfood scale. The mechanism (decay engine + frontmatter convention) IS shipped via MS-7, but with transparent default formula and all numerics overridable in `.claude/memory.config.json`. Forks at different scales pick different thresholds; Agent0 doesn't pretend to know.

## Open questions

- [ ] **OQ-1** `confirmed_count` increment mechanism — manual via `memory-confirm.sh <name>` helper (founder/agent calls explicitly when re-validating), or auto-increment via read-detection hook? Tentative: manual-via-helper (Anthill's read-detection was fragile). Re-visit in 085 if usage shows systemic under-incrementing.
- [ ] **OQ-2** Decay scoring axis — wall-clock time (`days_since_last_accessed`) or session-count (`sessions_without_access`)? Wall-clock is simpler; session-count is more honest for bursty cadences. Default: wall-clock; fork overrides formula in `memory.config.json`. Locked in 085.
- [ ] **OQ-3** MS-2 raw-edit gate scope — gate only `MEMORY.md` (the projection), or also individual `.claude/memory/*.md` files? Tentative: only `MEMORY.md`. Individual files stay hand-editable; their write triggers a PostToolUse event append to `memory-events.jsonl`. Locked in 083.
- [ ] **OQ-4** Should the `.claude/memory.config.json` template ship with Agent0 (as a starter forks customize) or be absent (forks create on demand)? Lean ship-as-template — discoverability beats minimalism for a config that forks will inevitably want.
- [x] **OQ-5** Migration timing for existing 13 Agent0 memories — at MS-2 ship time, append events for each entry manually in one commit, or let them remain "pre-event-sourcing" entries (file exists but no journal record)? Decision: manual append at ship time, single commit titled `chore(080): backfill memory-events.jsonl from existing entries`. Idempotent if the event journal has unique `entry_id` per add. **RESOLVED 2026-05-24 by 083:** journal is gitignored per-machine (overrides the "single commit" framing); backfill lives in `.claude/tools/memory-backfill.sh` as a per-machine one-shot, not a git history commit. Rationale: git-tracked append-only JSONL produces merge conflicts on every concurrent commit across multi-contributor forks; entry files themselves are git-tracked and carry the durable record via `git log --follow`. See `docs/specs/083-memory-events-journal/spec.md` § Non-goals.

## Context / references

- `.claude/rules/memory-placement.md` — canonical 3-bucket model; NGs in this umbrella reinforce its boundaries
- `.claude/rules/reminders.md` — current REMINDERS.md spec; MS-4 supersedes
- `.claude/rules/compaction-continuity.md` — current COMPACT_NOTES.md spec; MS-3 supersedes the overwrite behavior
- `.claude/memory/anthill-archived.md` — Anthill is the quality benchmark; this umbrella ports mechanisms (not policies) from it
- `.claude/memory/forks-ephemeral-dogfood.md` — rationale for hard-cutover migration posture (no real production fork uses Agent0 yet)
- `.claude/memory/feedback_no_shipped_stack_opinions.md` — "ship mechanisms, not policies" — the load-bearing constraint for the 4 non-goals
- `.claude/memory/feedback_speculative_observability.md` — rule-of-three demand test; relaxed here because Agent0 is a *product* not just a project (must prepare for fork-at-scale, not just current-Agent0)
- `/tmp/research/synthesis.md` — 2026-05-23 comparative synthesis (Obsidian + OpenCode + Hermes + Anthill) motivating the umbrella
- `/tmp/research/anthill.md` — Anthill deep-dive; bucket-mapping table; the conflation findings that informed NG-1 + NG-2
- `/tmp/research/hermes.md` — Hermes counterexample (no governance gate → Słomka critique) validates the hooks-first design Agent0 retains
- `/tmp/research/opencode.md` — OpenCode eager-load AGENTS.md bug (#18037) validates the lazy-read `MEMORY.md` index Agent0 retains
