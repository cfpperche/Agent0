# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Session 2026-05-24 (5th) — propagation-advisory hook shipped + Option B handoff queued.** Commit `3a66f88` shipped the PostToolUse hook + rule + 11 tests + settings/CLAUDE.md wire-up. Hook fires on edits to fork-bound paths and emits `propagation-advisory:` lines for 5 leak classes (spec-NNN, docs/specs/NNN, anthill, personal-path, memory-pointer). 11/11 tests pass; 5/5 project-memory tests still pass; smoke-test 4-scenario confirmed mid-implementation.

**Open self-consistency tension surfaced post-ship:** the propagation-advisory mechanism itself ships to forks (hook + rule + tests + settings entry + CLAUDE.md section all in fork-bound manifest), but the discipline it enforces is **upstream-maintainer-bound** per `.claude/memory/propagation-hygiene.md § Why this is memory, not a rule`. Leaf forks have zero downstream propagation, so the hook generates **false positives** on their legitimate own-spec / own-path / own-memory refs. **Decision: implement Option B** — exclude propagation-advisory from the sync-harness manifest (same posture as `.claude/memory/` shipping only `.gitkeep`).

Session 4 (parallel) shipped commit `9314e12` with `.claude/memory/bertolini-dogfood-loop.md` (cascade-classification pattern, deferred per rule-of-three). Untouched here.

## WIP — resume point

**No active WIP.** Next session implements Option B from scratch.

## Next steps — Option B implementation plan

1. **Read `.claude/tools/sync-harness.sh`** — find the exclusion mechanism. `.claude/memory/` is the precedent (ships only `.gitkeep`); look for the exclusion pattern around the file-walk + `is_memory_path`-style check. Confirm hook point.

2. **Add 4 path exclusions** to the manifest:
   - `.claude/hooks/propagation-advise.sh`
   - `.claude/rules/propagation-advisory.md`
   - `.claude/tests/propagation-advisory/**`

3. **Settings.json hook entry** — `merge_settings_json` propagates the PostToolUse(Edit|Write|MultiEdit) hooks block. Options: (a) filter by command-path substring `propagation-advise.sh` in merge; (b) accept that forks see the registration but exclude the file (registration becomes a no-op — fail-safe per test 09 opt-out). Option (b) is cheaper.

4. **CLAUDE.md managed block** — the `## Propagation advisory` section is inside AGENT0:BEGIN/END. Easiest: just remove the section from CLAUDE.md (the rule doc + memory carries the substance for Agent0).

5. **Update `propagation-hygiene.md` memory** — L22 surface definition. Add exception: "EXCEPT `propagation-advise.sh` + `propagation-advisory.md` + `tests/propagation-advisory/` which are upstream-maintainer-bound and excluded from the sync manifest (same posture as `.claude/memory/`)."

6. **Test** — `bash .claude/tools/sync-harness.sh --check --agent0-path=. ~/mei-saas`. Expected: 4 propagation-advisory paths absent from copy plan; no drift advisories about them.

7. **Forks cleanup** — `mei-saas` + `codexeng` never received the propagation-advisory (it shipped in 3a66f88, no sync since). Clean state by construction.

8. **Commit + push** — `chore(propagation-advisory): exclude from sync manifest — upstream-maintainer-bound`.

## Decisions & gotchas

- **Self-consistency lens from `propagation-hygiene.md` L57-60** is right: a discipline that binds only the upstream maintainer should not ship its enforcement mechanism to forks where it's inert or false-positive-generating. Same logic that puts the memory in `.claude/memory/` (not `.claude/rules/`) applies to its hook companion.
- **Test surface stays intact in Agent0** — the 11 scenario tests still run against Agent0's copy. Excluding from manifest only stops the sync.
- **`CLAUDE_SKIP_PROPAGATION_ADVISE=1` becomes redundant for forks** under Option B. Keep the env var in Agent0 for throwaway-session use; disappears from fork experience.
- **Forks-that-are-templates** (rare; downstream propagators) can opt-in by manually copying the 4 files + settings entry. Capacity remains discoverable via Agent0 git history.
- **Don't touch `.claude/memory/bertolini-dogfood-loop.md`** — session 4's work, separate concern.

## Carryover (orthogonal — not touched this session)

- `docs/specs/074-subagent-personas/` — untracked draft (carried from earlier handoff).
