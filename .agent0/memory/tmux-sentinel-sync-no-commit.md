---
name: tmux-sentinel is sync-apply-only (never commit harness)
description: PUBLIC consumer; gitignores the whole .agent0/ harness on purpose. Keep sync --apply for local dev, but NEVER commit/push harness there.
metadata:
  type: project
  created_at: '2026-06-04'
  last_accessed: '2026-06-04'
  confirmed_count: 1
---
# tmux-sentinel is sync-apply-only (never commit harness)

`/home/goat/tmux-sentinel` is a **public** repo. The founder deliberately gitignores the entire Agent0 harness there (`.gitignore` line `.agent0/`, plus the runtime dirs): the harness is present **locally for development use** but must **never be committed/pushed** to the public history.

Founder intent (2026-06-04, confirmed across two messages): "ignore the whole harness in tmux-sentinel — I don't want to propagate the harness in this public project" AND "but we need to keep syncing the harness in this repo, just for use during development." So: **`sync-harness.sh --apply` YES (updates the gitignored `.agent0/` for local tooling); commit/push of any harness change NO.**

**How to apply (during consumer propagation):**

- Run `--apply` on tmux-sentinel like the others — it updates the gitignored `.agent0/` and leaves nothing tracked to commit (correct end state).
- **Do NOT run the per-consumer commit/push step for tmux-sentinel.** The only thing that can surface as "harness to commit" there is the tracked `.gitignore` (sync's gitignore-merge) and other tracked merges (CLAUDE.md/AGENTS.md) — leave them uncommitted, or `git checkout --` them, so the public repo's tracked files stay harness-free.
- The other 4 consumers (ag-antecipa, cognixse, mei-saas, tese) **do** track `.agent0/` and **do** get the harness committed — they are not public-clean like tmux-sentinel.

**Known blemish (accepted):** commit `611b159` ("chore(harness): sync Agent0 harness to bd707e7") was an accidental harness commit pushed to tmux-sentinel's public remote during the 2026-06-04 propagation. It only added 3 `.gitignore` lines (ignoring `assets/generated/.manifest.jsonl`) — benign — so the founder chose to leave it as-is rather than revert/force-push. Don't repeat it. See [[propagation-hygiene]].
