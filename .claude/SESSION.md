# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Session 2026-05-23 (late) — closed.** Shipped `session-start.sh` dual-emit refactor (commit `05a5ec8`): hook now emits one JSON with both `hookSpecificOutput.additionalContext` (model) and `systemMessage` (user-visible banner), so SESSION.md / compact-history / runtime-introspect / githooks-activation render as a banner at session boot instead of being invisible until the agent's first turn. Pattern lifted from Anthill's `reminder-surfacer.sh`; root cause is CC v2.1.0+ silently dropping SessionStart stdout from the user-visible surface. Tree clean. 12 commits to push on Agent0 main.

## WIP — resume point

**Pending empirical confirmation** that the banner actually renders visibly on next session boot. The user will reopen Claude Code immediately after this session ends — expected to see SESSION.md content as a banner before typing anything.

## Next steps

1. **Confirm banner renders.** If yes → propagate dual-emit pattern to `.claude/hooks/reminders-readout.sh` and `.claude/hooks/routines-readout.sh` (same root cause, mechanical change, ~10 lines each). User explicitly scoped this session to handoff only; reminders+routines deferred pending confirmation.
2. **If banner does NOT render** → investigate JSON shape, CC version compatibility, or whether multiple SessionStart hooks merge `systemMessage` correctly.
3. **`/sdd new memory-frontmatter-schema`** → scaffold umbrella-080 child **082** (MS-1 frontmatter schema + PostToolUse advisory validator). Foundation for 083 (MS-2 event-sourcing) and 085 (MS-5+MS-7 cap+query+decay). All three unscaffolded.
4. Dated reminders due: 029 05-30 · 035 06-07 · 046 07-01 · 060 07-19.
5. Push pending commits: `git push origin main` (Agent0 12 + mei-saas 1 + codexeng 6).

## Decisions & gotchas

- **CC v2.1.0+ drops SessionStart stdout from the user-visible banner.** Plain `printf` in a SessionStart hook only reaches the model's `additionalContext`. To render a banner the user sees before typing, emit JSON with `systemMessage` at top level (NOT documented in CC schema but proven by `/home/goat/anthill/.claude/hooks/reminder-surfacer.sh:106-112`). Use the dual-emit pattern (additionalContext + systemMessage with identical content) so model and user both get the same view.
- **claude-code-guide research can be wrong on undocumented behavior.** The agent reported `systemMessage` is "documented but NOT supported at SessionStart" — Anthill's working hook contradicts that. When platform behavior matters, dogfood/grep real working examples before trusting doc-citations.

## Carryover (orthogonal — not touched this session)

- `docs/specs/074-subagent-personas/` — untracked draft; leave for originating session.
- 5 remaining 076 findings from the original 10-finding triage table (#1, #2-byte-window, #6, #7, #10) covered by spec 075 — no follow-up specs pending unless dogfood surfaces new findings.
