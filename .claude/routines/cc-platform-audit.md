---
name: cc-platform-audit
schedule: "0 9 * * 1"
idempotent: true
on-stale: warn
stale-after-days: 14
---

# Prompt

You are running the weekly Claude Code platform audit against `.claude/memory/cc-platform-hooks.md`.

**Last execution:** {{LAST_COMPLETED_TS}}. **Current HEAD:** {{GIT_HEAD}}. **Repo:** {{REPO_ROOT}}.

Steps:

1. WebFetch <https://code.claude.com/docs/en/hooks> and capture current content.
2. Compare the hook events / payload shapes / event semantics list against what `.claude/memory/cc-platform-hooks.md` documents (especially the 29-event table and payload-shape gotchas).
3. For each drift detected:
   - **New event** not in memo → propose edit adding to the table
   - **Payload shape changed** for documented event → propose edit correcting
   - **Event removed / deprecated** → propose edit removing or marking deprecated
   - **Behavior changed** (exit-code semantics, when-fires, etc.) → propose edit correcting
4. If NO drift detected, respond with exactly: `no-drift-detected since {{LAST_COMPLETED_TS}}` (no edits).
5. If drift exists: apply the proposed edits to `.claude/memory/cc-platform-hooks.md` (DO NOT commit — leave diff for human review via `git diff`).
6. Bonus: also check <https://code.claude.com/docs/en/skills> and <https://code.claude.com/docs/en/slash-commands> against the agentskills.io snapshot at `.claude/skills/skill/references/spec-snapshot.md` — propose edits there too if relevant.

# Done when

- Edit applied to `.claude/memory/cc-platform-hooks.md` (or other relevant memos) reflecting current drift between CC release notes and our snapshot,
  OR
- Message `no-drift-detected since {{LAST_COMPLETED_TS}}` explicitly reported in chat with no edits applied.
- (Automatic) `.claude/.routines-state/cc-platform-audit/completed/<ts>.md` materialized by `/routine run` on archival.

<!--
Created 2026-05-19 as Agent0's first real routine (dogfood + actual value).
Weekly schedule (Mon 9am UTC) balances drift-caught-early frequency against
cost (1 web fetch + 1 LLM session per week).
Idempotent: re-running in the same week re-checks drift; if edit was already
applied, the re-run sees the updated memo and reports no-drift-detected.
-->
