# 119 — delegation-gate-state-to-agent0

_Created 2026-05-29._

**Status:** shipped

## Outcome

Shipped 2026-05-29. `git mv .claude/hooks/delegation-gate.sh → .agent0/hooks/delegation-gate.sh` (`.claude/hooks/` removed, empty); `.claude/.delegation-state` + `.claude/.brainstorm-state` relocated to `.agent0/` (gitignored, content preserved). Scoped sed of the 3 literals across 17 files; a repo-wide grep for the 3 literals outside `docs/specs/` returns zero. Delicate spots all verified: `settings.json` command → `.agent0/hooks/delegation-gate.sh` (jq parses, registration stays Claude-only); `delegation-verify.sh`/`delegation-stop.sh` STATE_DIR → `.agent0/.delegation-state`; CLAUDE.md + AGENTS.md byte-equal gate path; brainstorm SKILL.md 11/11 paths → `.agent0/`; `.gitignore` both lines → `.agent0/`. `harness-home.md` principle refined (location-vs-registration split; 3 surfaces moved from `stays`/`deferred` to `move`). `runtime-capabilities.md` lifecycle-hooks row dropped the now-stale `.claude/hooks/*.sh` owner-file ref. **Validation: all 5 affected suites PASS** (instruction-drift incl. byte-equal block, governance-gate, delegation-verify, 061-delegation-stop 10/10, harness-sync). `docs/specs/` frozen-clean vs HEAD.

**Deviation:** the planned removal of the `.claude/hooks|*.sh` manifest glob was reverted — it is needed by ~16 harness-sync test fixtures (which synthesize `$SRC/.claude/hooks/`) and gives legacy-consumer back-compat; it is harmlessly inert over the now-absent real dir. Criterion #5 was rewritten accordingly. See `notes.md`.

**Session note:** the Bash output channel degraded intermittently (empty returns) during implementation — all final state was re-verified directly; the work is complete and the repo intact.

## Intent

Relocate the last three `.claude/`-resident harness surfaces that are not genuinely Claude-exclusive to the runtime-neutral `.agent0/` home, completing the umbrella-102 consolidation for the hook + state layer:

1. **`.claude/hooks/delegation-gate.sh` → `.agent0/hooks/delegation-gate.sh`** — the last hook left in `.claude/hooks/` (every sibling — `governance-gate`, `secrets-preflight`, `delegation-verify`, `delegation-stop`, the memory hooks — already lives in `.agent0/hooks/`). Moving it empties and removes `.claude/hooks/`.
2. **`.claude/.delegation-state/` → `.agent0/.delegation-state/`** — the per-`agent_id` loop-budget counter dir, written by `delegation-verify.sh` and read by `delegation-stop.sh` (both already in `.agent0/hooks/`). Gitignored, ephemeral.
3. **`.claude/.brainstorm-state/` → `.agent0/.brainstorm-state/`** — the `/brainstorm` skill's session+render state dir. Gitignored, ephemeral.

**The principle this refines (and why it overrides the prior `harness-home.md` disposition).** `harness-home.md` currently classes `delegation-gate.sh` as `stays` (Claude-only hooks registered via `settings.json`) and `.brainstorm-state` as "must not relocate before its producer". Specs 117/118 established a sharper rule that this spec makes explicit: **what is runtime-specific is the *registration* (the `settings.json` command pointer, the `Agent`-tool semantics), not the file's *location*.** `delegation-verify.sh` already proves this — it is registered in `settings.json` (Claude) AND `.codex/config.toml.example` (Codex) yet lives in `.agent0/hooks/`. `delegation-gate.sh` stays Claude-*registered* (only Claude's `Agent` tool fires `PreToolUse(Agent)`; the gate is a no-op concept on Codex), but its file belongs in `.agent0/hooks/` alongside the rest of the delegation family. Co-locating all hooks at one path makes the tree legible and the manifest uniform. The two state dirs follow their producers (already in `.agent0/hooks/`); `.brainstorm-state` co-locates by repointing the skill's read/write path in the same diff (the skill *file* stays in `.claude/skills/`, deferred — but its *state output* moves with the consolidation, satisfying the co-location rule's intent: no producer/state split). `harness-home.md` is updated as part of this spec to record the refined principle and move all three rows to `move`/shipped.

This is a pure path relocation, same playbook as specs 105/118: move first, repoint references in dependency-safe order, leave `docs/specs/*` frozen.

## Acceptance criteria

- [ ] **Scenario: delegation-gate lives under `.agent0/hooks/`, `.claude/hooks/` removed**
  - **Given** the repo after this spec ships
  - **When** `ls .agent0/hooks/delegation-gate.sh` and `ls .claude/hooks` run
  - **Then** the `.agent0/` path exists AND `.claude/hooks` reports "No such file or directory" (the dir is empty after the move and removed)

- [ ] **Scenario: git history preserved for the gate**
  - **Given** the relocated gate
  - **When** `git log --follow --oneline .agent0/hooks/delegation-gate.sh` runs
  - **Then** it shows the file's pre-move history (moved via `git mv`)

- [ ] **Scenario: settings.json registration repointed (registration stays Claude-only, path moves)**
  - **Given** `.claude/settings.json`
  - **When** parsed with `jq` and the `PreToolUse(Agent)` hook command inspected
  - **Then** the command is `bash "$CLAUDE_PROJECT_DIR"/.agent0/hooks/delegation-gate.sh`; no `.claude/hooks/delegation-gate.sh` string remains; JSON parses

- [ ] **Scenario: state dirs relocated with their producers**
  - **Given** the repo after this spec ships
  - **When** the loop-budget path constants in `delegation-verify.sh` and `delegation-stop.sh` are inspected, and the `/brainstorm` skill's state path
  - **Then** all resolve under `.agent0/.delegation-state/` and `.agent0/.brainstorm-state/` respectively; no `.claude/.delegation-state`/`.claude/.brainstorm-state` reference remains; `.gitignore` ignores the new paths

- [ ] **Scenario: sync-harness manifest covers the moved gate; `.claude/hooks` glob retained**
  - **Given** `.agent0/tools/sync-harness.sh`
  - **When** `COPY_CHECK_GLOBS` is inspected
  - **Then** the moved gate is covered by the existing `.agent0/hooks|*.sh` glob AND the `.claude/hooks|*.sh` glob is **retained** (inert over the now-absent real dir, but kept for legacy-consumer back-compat and because ~16 harness-sync test fixtures synthesize `$SRC/.claude/hooks/`); the harness-sync suite passes. _(Deviation from plan — see `notes.md`. The original criterion called for removing the glob; that broke the fixtures and removed back-compat, so it was reverted.)_

- [ ] **Scenario: CLAUDE.md and AGENTS.md stay byte-equal in the managed block**
  - **Given** both entrypoints reference the gate path in the AGENT0-managed region
  - **When** the path is repointed
  - **Then** both are edited identically; `instruction-drift/03-managed-blocks-byte-equal.sh` passes

- [ ] **Scenario: affected suites green after the move**
  - **Given** the relocated files
  - **When** delegation-verify, 061-delegation-stop, governance-gate, harness-sync, instruction-drift suites run
  - **Then** each passes — no script references a stale `.claude/hooks/delegation-gate.sh` or `.claude/.delegation-state` path

- [ ] No live (non-`docs/specs/`) reference to `.claude/hooks/delegation-gate.sh`, `.claude/.delegation-state`, or `.claude/.brainstorm-state` survives: a repo-wide grep outside `docs/specs/` returns nothing.
- [ ] `harness-home.md` records the refined principle (location → `.agent0/`; registration is the only runtime-specific bit) and shows all three surfaces as `move`/shipped, not `stays`/`deferred`.

## Non-goals

- **Not moving the `/brainstorm` skill file itself.** `.claude/skills/` is still `deferred` per spec 102 (the "Codex consumes skills" trigger isn't met). Only the skill's *state output path* moves; the `SKILL.md` stays in `.claude/skills/`.
- **Not changing the gate's behavior or its Claude-only registration.** It still fires only on Claude's `PreToolUse(Agent)`; Codex has no pre-dispatch gate (spec 106). Only the file path changes.
- **Not renaming `CLAUDE_DELEGATION_VALIDATOR` / `CLAUDE_DELEGATION_LOOP_BUDGET`** or other `CLAUDE_*` env vars — same non-goal as spec 118.
- **Not moving `.claude/rules` / `.claude/skills` / `.claude/agents` / `.claude/worktrees`.** Rules/skills/agents still `deferred`; worktrees is CC-native (`EnterWorktree`).
- **Not auto-migrating consumer state dirs.** Same hard-cutover posture as 103/104/105 (`harness-sync.md` § Path relocations) — consumers `git mv` their own gitignored state on next sync.
- **Not rewriting `docs/specs/*`** — frozen, except this spec (119).

## Open questions

- [x] Does moving `delegation-gate.sh` violate the `harness-home.md` `stays` disposition? Resolved: the disposition is superseded by the refined principle (registration vs location split, already proven by `delegation-verify.sh`). `harness-home.md` is updated in this spec rather than treated as immovable — it is project memory, not a frozen contract.
- [x] Can `.brainstorm-state` move while its skill stays in `.claude/skills/`? Resolved: yes — co-location is satisfied by repointing the skill's state path in the same diff (no producer/state split is created; the skill writes/reads the new path). The skill file's own location is a separate, deferred decision.
- [x] Empty `.claude/hooks/` — remove or keep? Resolved: remove. An empty dir with no tracked files is cruft; git won't track it anyway. The manifest glob is dropped so sync stops expecting it.

## Context / references

- `.agent0/memory/harness-home.md` — the classification principle being refined + the `stays`/`deferred` dispositions being overridden
- `docs/specs/{105-shared-tools-to-agent0,118-move-validators-tests-to-agent0}/` — the relocation playbook this mirrors
- `docs/specs/{106-delegation-hooks-multi-runtime,111-delegation-verify-subagent-stop}/` — established `delegation-verify.sh`/`delegation-stop.sh` in `.agent0/hooks/` with the registration-vs-location split this generalizes
- `.claude/rules/delegation.md` — the delegation capacity (gate + state) whose paths change
- `.claude/rules/harness-sync.md` § Path relocations (capacity-only) — consumer-migration posture
