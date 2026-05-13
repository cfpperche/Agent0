# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state

Rule-infra modernization shipped + validated, user-global secrets hook removed, dotclaude fully decommissioned. **Tier 2 dogfood v2 ran with non-stopword fixture (`AKIAJZTRFAKEKEYABCDE`) → both layers behaved as designed (block on bare commit, override-pass through on `# OVERRIDE:` marker). Rollback clean.**

Commits in Agent0 from prior session-stretches:
- `bd4b087` docs(memory): broaden InstructionsLoaded dedup finding
- `6fe806d` docs(rules): rule-load-debug per-rule dedup gotcha
- `1b1c451` chore(session): handoff level 3 PASS
- `f2ae87f` Revert "test fixture for dogfood" (neutralizes a Tier 2 v1 commit `185f4c2` that landed with a non-bloqueado fake credential — see § Decisions)

Tier 2 v2 dogfood (this session, 2026-05-13 ~17:08–17:09 UTC) — no commits left behind:
- Bare commit attempt → preflight `passthrough` (17:08:56Z) + native `block, finding_count:1, staged_files_count:1` (17:08:56Z) — exit 1, HEAD stayed at `f2ae87f`.
- Override commit (`# OVERRIDE: dogfood validation of two-layer secrets-scan post v1 fix`) → preflight `override-pass-through` with parsed `override_reason` (17:09:10Z) + native `override, finding_count:1` with same `override_reason` (17:09:10Z) — commit `e774efe` created.
- Rollback (`git reset --soft HEAD~1` + `git restore --staged` + `rm` + `rmdir tests/fixtures && rmdir tests`) → HEAD back to `f2ae87f`, fixture file + `tests/fixtures/` + `tests/` all gone. Verified via `git status --short`.

## Parallel WIP

- spec 025/026 session(s): touching `packages/mcp-product-pipeline/**`, `docs/specs/026-mcp-pipeline-deep-port/**`. Origin/main is at `93ca5aa feat(026): Phase A plumbing extensions for deep-port` (1 commit ahead of local). Local has parallel-session WIP across spec-025/026 files. Other sessions: defer those paths.
- this session: ran Tier 2 v2 dogfood; touched `.claude/SESSION.md` and (transiently, now cleaned) `tests/fixtures/fake-aws-key.txt`. Did NOT touch `packages/mcp-product-pipeline/**` or `docs/specs/026-*`.

## WIP — uncommitted (this session)

- `.claude/SESSION.md` — this rewrite (unstaged)
- `.claude/rules/secrets-scan.md` — § Gotchas + 1 bullet about gitleaks stopword list (now STAGED in working tree; staging state shifted between SessionStart snapshot and dogfood run — likely a parallel session restaged it, NOT a side-effect of v2 dogfood commands)
- Parallel WIP (other sessions): files modified/staged across spec 025/026 lane (see § Parallel WIP)

Local branch diverged 1↔1 with origin: local has `f2ae87f` (revert), origin has `93ca5aa` (Phase A). Resolve via `git pull --rebase` whenever convenient — both lines are wanted.

## Next steps

1. **Commit this session's bookkeeping** — suggested:
   - `docs(rules): gitleaks-stopword dogfood gotcha` for the secrets-scan.md edit
   - `chore(session): tier 2 v2 PASS + handoff` for SESSION.md
2. **Reconcile divergence with origin** — `git pull --rebase` + push when spec 026 lane is at a quiet point.
3. **Spec 025/026 lane** — separate session(s); don't touch from this lane.
4. **Pyshrnk CLAUDE.md reconciliation** — long carryover.
5. **Commit shrnk-mono sync** — 13 modified + 2 untracked there, awaiting `chore(harness-sync): adopt rule-load-debug + path-scoped frontmatter`. Orthogonal lane.

## Decisions & gotchas

- **Tier 2 v2 PASS (NEW, 2026-05-13).** Non-stopword fixture (`AKIAJZTRFAKEKEYABCDE`) end-to-end test of two-layer secrets-scan after dotclaude decommission. Bare commit blocked by native gitleaks (preflight `passthrough` + native `block, finding_count:1`); override marker `# OVERRIDE: dogfood validation of two-layer secrets-scan post v1 fix` accepted by both layers (preflight `override-pass-through` + native `override`) with reason captured in audit row. Rollback step 8 followed the v2 playbook (read `git log -1` first → confirmed HEAD on `e774efe` → `git reset --soft HEAD~1` → cleanup) and ended at `f2ae87f` with no orphan commits. Used `git commit <path>` form to isolate fixture from parallel-session staged WIP — preflight allowed (`cmd_shape: null`), staged_files_count was 1.
- **Tier 2 v1 false PASS (carryover, 2026-05-13).** Dogfood committed `AKIAIOSFODNN7EXAMPLE` expecting native gitleaks block; preflight wrote `passthrough` + native wrote `allow` (`finding_count: 0`) — gate ran correctly, test input was the bug. `AKIAIOSFODNN7EXAMPLE` is in gitleaks' default stopword list (canonical AWS docs example, exempted to reduce false-positive noise). Gotcha landed in `.claude/rules/secrets-scan.md` § Gotchas with the recommended non-stopword fakes (`AKIAJZTRFAKEKEYABCDE`, `AKIAQQ7777FAKEKEY999`). Commit `185f4c2` reverted via `f2ae87f` — used `git stash → revert → stash pop` to preserve parallel spec 025/026 WIP.
- **Tier 2 v1 agent rollback bug (carryover).** Playbook step 7 (`git reset --soft HEAD~1` etc.) was conditional in the agent's mental model on "did the block fire?" — when block didn't fire (because v1 fixture was a stopword), agent skipped reset, leaving commit orphaned. v2 prompt mandated `git log -1` check FIRST and v2 dogfood (this session) followed it — clean rollback.
- **`git commit <path>` preflight observation (NEW, 2026-05-13).** Preflight registered `decision: "passthrough", cmd_shape: null, staged_files_count: 1`. The single-file path argument scopes both the gate's view and the native scanner's diff — useful pattern when working in a repo with cross-session staged WIP. Compound shapes (e.g. `<expr> && git commit ...`) still get rejected by preflight as `reject-shape, cmd_shape: "compound-and"` — even when the compound LHS is something harmless like `PRE_COMMIT_TS=$(date)`. Workaround: just run `git commit` in its own Bash invocation.
- **dotclaude fully decommissioned (NEW, 2026-05-13).** `~/dotclaude/` removed (recoverable via `git clone git@github.com:cfpperche/dotclaude.git`); `~/.cache/dotclaude/` removed; `~/.claude/settings.json` cleaned (no `hooks`, no `statusLine`, comment updated); `crontab -r` (was 2 dotclaude jobs pointing at deleted scripts). Side effects: no statusline customization until you reinstate; non-Agent0 repos lose user-global secrets safety net (Agent0 forks self-protect via own 2-layer). Refs in `~/.claude/{history.jsonl,projects/*,file-history/*,paste-cache/*}` untouched (CC's read-only audit, not load-bearing). User-global hook `pre-commit-secrets-scan.sh` was a leftover from pre-2026-05-02 dotclaude migration; removal finishes the migration that was half-done.
- **User-global hooks shadow project hooks.** Carryover. Diagnostic remains `ls ~/.claude/hooks/` for any future "Agent0 capacity behaving weird" debug. See `.claude/memory/user-global-hooks-shadow.md`.
- **`InstructionsLoaded` dedup is per-rule.** Carryover; documented in cc-platform-hooks.md § Empirical and rule-load-debug.md § Gotchas.
- **CLAUDE.md `## Section` summaries proved LOAD-BEARING.** Carryover from supply-chain block dogfood.
- **Hooks are harness siblings.** Carryover; env vars must be exported pre-launch.
- **`session_id` observed shifting mid-session in shrnk-mono dogfood log.** Carryover finding; flag for investigation if reliability becomes a concern.
- **Skill-eval framework NOT adopted.** Reference `.claude/memory/skill-eval-pattern.md`. Trigger to revisit: third silent regression.
