# 092 — multi-runtime-handoff

_Created 2026-05-26._

**Status:** draft

## Intent

Unify Agent0's session handoff so Claude Code and Codex can coordinate through one canonical, runtime-neutral work-state file instead of treating `.claude/SESSION.md` as the only source of truth. Today Claude Code receives `.claude/SESSION.md` automatically through `SessionStart` and is nudged to update it through `Stop`; Codex can only participate manually, and any future `AGENTS.md` guidance would have to point at a Claude-namespaced file. This spec introduces a neutral handoff contract, migrates Claude's hooks to read and enforce that contract, gives Codex an explicit read/update convention through `AGENTS.md`, and preserves a compatibility path for existing Claude-only sessions. The goal is shared state and clear ownership between runtimes, not a full `.claude/` namespace migration or a Codex hook implementation.

## Acceptance criteria

- [ ] **Scenario: both runtimes read the same handoff**
  - **Given** a repo with the new canonical handoff file populated
  - **When** Claude Code starts a session and Codex starts work from `AGENTS.md`
  - **Then** both runtimes are directed to the same handoff source covering the four required sections: `Current State`, `Active Work`, `Next Actions`, and `Decisions & Gotchas`

- [ ] **Scenario: Claude hook injection uses the neutral handoff**
  - **Given** the canonical handoff file exists
  - **When** the Claude `SessionStart` hook runs
  - **Then** it injects the neutral handoff content instead of requiring agents to rely on `.claude/SESSION.md` as the primary source

- [ ] **Scenario: Claude stop enforcement protects the neutral handoff**
  - **Given** a Claude Code session edits repo files tracked by the existing session-state machinery
  - **When** the `Stop` hook evaluates whether a handoff update is required
  - **Then** it checks freshness of the neutral handoff file and blocks once per session when repo edits happened but the handoff was not updated. Stop preserves the current edit-attribution behavior: when `.claude/.session-state/<id>/edited-files.txt` exists and is empty, Stop exits silently (Claude session edited nothing the tracker could see). Cross-runtime attribution for Codex-authored edits stays out of v1; the legacy porcelain-compare fallback's known false-positive (Codex edits during a Claude bystander session, `edited-files.txt` missing) remains a documented legacy risk, not a new mechanism.

- [ ] **Scenario: Codex has an explicit manual convention**
  - **Given** Codex opens the repo and reads root `AGENTS.md`
  - **When** the task is non-trivial or changes repo files (per `.claude/rules/spec-driven.md` § *When SDD applies* as the canonical "non-trivial" definition; AGENTS.md and `.claude/rules/session-handoff.md` cross-reference)
  - **Then** Codex is instructed to read the neutral handoff before acting and update it before finishing, using the same short sections Claude uses

- [ ] **Scenario: active parallel work is visible across runtimes**
  - **Given** Claude and Codex are both working in the repo
  - **When** either runtime claims or releases an active `Active Work` bullet
  - **Then** the handoff's `Active Work` section names the thread with three required fields — **owner runtime**, **touched paths**, and **release condition** — so the other runtime can avoid conflicting edits. `Active Work` replaces the prior `Ownership / Locks` framing and subsumes the existing `Parallel WIP` convention.

- [ ] **Scenario: legacy Claude-only readers do not lose the handoff**
  - **Given** a user or older instruction still opens `.claude/SESSION.md`
  - **When** the neutral handoff is canonical
  - **Then** `.claude/SESSION.md` is a short **static pointer file** naming `.agent0/HANDOFF.md` as the canonical handoff (plus reference to `.claude/rules/session-handoff.md`), with no work-state content. Claude hooks read/enforce `.agent0/HANDOFF.md` directly — they do not chase or parse the pointer file.

- [ ] The canonical handoff path is `.agent0/HANDOFF.md`. The file is git-tracked in the fork (matches today's `.claude/SESSION.md` posture). The 4 KB size discipline of `.claude/rules/session-handoff.md` applies.

- [ ] The handoff template contains the required sections: `Current State`, `Active Work`, `Next Actions`, and `Decisions & Gotchas`. `Active Work` bullets carry **owner runtime + touched paths + release condition**; this section subsumes the existing `Parallel WIP` convention in `.claude/rules/session-handoff.md` (rule edited in same implementation to migrate the bullet grammar).

- [ ] The size discipline remains at or below the existing handoff target: keep the canonical handoff under 4 KB and replace stale content rather than appending a journal.

- [ ] Project-local handoff content is not copied over fork-owned work by `sync-harness.sh`; any sync change must preserve that handoff is per-project state, not Agent0-managed policy.

- [ ] Claude `SessionStart` hook injects `.agent0/HANDOFF.md` on **both** `source=startup` AND `source=compact`, alongside any compact-specific context (`COMPACT_NOTES.md`). No source-dependent handoff source — single canonical file across both hook firings. `.claude/rules/compaction-continuity.md` updated to match.

- [ ] Missing-handoff fallback is **3-layered**: (a) if `.agent0/HANDOFF.md` exists → inject/enforce it; (b) else-if `.claude/SESSION.md` exists and is NOT the pointer-only file → fall back to legacy `.claude/SESSION.md` + emit migration advisory; (c) else → emit one-line advisory (`'.agent0/HANDOFF.md' missing — create it to enable handoff`) and proceed without aborting the session. Detection of "pointer-only file" is plan-level (content-marker, size-threshold, or frontmatter — picked in plan).

- [ ] Rule updates in same implementation: `.claude/rules/session-handoff.md` is rewritten to reference `.agent0/HANDOFF.md` as canonical, migrate `Parallel WIP` content into the new `Active Work` shape, and document the asymmetric Claude/Codex enforcement (Claude = hooks; Codex = AGENTS.md convention).

- [ ] Tests cover Claude hook read path, Claude stop freshness path, missing neutral handoff fallback (3-layered), and `.claude/SESSION.md` compatibility behavior.

## Non-goals

- **Full `.claude/` to `.agent0/` migration.** This spec only moves the live handoff contract. Hooks, rules, skills, validators, and settings remain where they are.
- **Codex hook parity.** Codex gets an explicit convention through `AGENTS.md`; automatic Codex lifecycle enforcement is future scope.
- **A shared database, daemon, lock server, or broker.** The handoff is a markdown file in the repo.
- **Hard lock enforcement.** `Active Work` bullets are advisory coordination, not a filesystem lock that prevents edits.
- **Long-term memory migration.** Durable project knowledge still belongs in `.claude/memory/<topic>.md` until a separate namespace spec changes that.
- **Conversation transcript synchronization.** The handoff summarizes state; it does not try to merge Claude and Codex chat histories.
- **Solving concurrent writes perfectly.** The contract reduces accidental collisions; it does not make simultaneous writes to the same markdown file safe without human coordination.
- **Mirror compatibility shape for `.claude/SESSION.md`.** Pointer-only is the v1 contract; a write-through mirror is rejected because it reintroduces two mutable sources of truth.
- **6-section template.** Collapsed to 4 sections (`Current State` / `Active Work` / `Next Actions` / `Decisions & Gotchas`) because the extra splits (Active Threads vs Ownership/Locks; Decisions vs Gotchas) did not earn their cost.
- **`.agent0/` under sync-harness scope.** `.agent0/HANDOFF.md` and the entire `.agent0/**` tree are per-project state, NOT in `sync-harness.sh`'s manifest in v1. Future neutral-namespace files must opt into sync explicitly via a follow-up spec — sync-by-default is rejected as scope creep.
- **Cross-runtime edit attribution.** Codex-authored file edits are NOT attributed through Claude's `Stop` hook in v1. Codex has no lifecycle hook to attribute through; building one is future scope. The known legacy-porcelain-fallback false-positive (Codex edits in a Claude bystander session with no `edited-files.txt`) stays as a documented legacy risk.

## Open questions

- [ ] Should the first implementation require `AGENTS.md` from spec 090 to exist first, or can it update only Claude hooks plus the neutral file and let 090 wire Codex instructions later? Lean: implement after 090 applies (which it now has — d2a9806's parent chain ships 090) so both runtime entrypoints can point at the same file in one pass.
- [ ] **(plan-level)** Should `.claude/.session-state/<id>/edited-files.txt` (or equivalent) gain a stale-claim advisory check beyond the v1 release-condition requirement? Each `Active Work` bullet already MUST carry a release condition (explicit field, not implicit); v1 enforces no TTL automatically (advisory only). Plan decides whether to add a separate `stale-claim-advisory:` line in `Stop` / `SessionStart` when a bullet's release condition appears unmet across N sessions.

_Resolved during debate (see § Synthesis in `debate.md`):_

- ~~Q1 canonical path~~ → **resolved**: `.agent0/HANDOFF.md` (neutral namespace; root-level capitalized would clutter root and break naming convention).
- ~~Q2 `.claude/SESSION.md` shape~~ → **resolved**: static pointer only (no mirror, no compat content).
- ~~Q5 tracked vs gitignored~~ → **resolved**: tracked, matching today's `.claude/SESSION.md`.

## Context / references

- `.claude/rules/session-handoff.md` — current Claude-only handoff rule, size discipline, start/stop behavior, and parallel WIP convention.
- `.claude/SESSION.md` — current live handoff file that this spec would replace or shim.
- `.claude/hooks/session-start.sh` — injects the current handoff into Claude Code context.
- `.claude/hooks/session-stop.sh` — enforces handoff freshness for Claude Code sessions that edited files.
- `.claude/.session-state/` — per-session state used by Claude hooks for edit attribution and block-once behavior.
- `docs/specs/090-multi-runtime-entrypoints/` — establishes `AGENTS.md` as Codex's root instruction entrypoint and keeps root `AGENTS.md` Agent0-owned in v1.
- `docs/specs/091-sdd-debate-runner/` — paused runner spec; depends on reliable cross-runtime handoff if it later orchestrates long-running debates.
- `.claude/rules/memory-placement.md` — durable knowledge remains memory, not handoff.
- `.claude/rules/compaction-continuity.md` — touched by the SessionStart `source=compact` decision (both startup and compact read `.agent0/HANDOFF.md`).
- `docs/specs/092-multi-runtime-handoff/debate.md` — cross-model debate (Codex CLI initiating, Claude Code reviewing) over Rounds 1-2 that resolved Q1 / Q2 / Q5, narrowed the section template from 6 to 4, established `Active Work` as the single coordination primitive subsuming `Parallel WIP`, picked pointer-only compat for `.claude/SESSION.md`, and established the 3-layer missing-file fallback.
