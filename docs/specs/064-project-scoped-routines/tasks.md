# 064 — project-scoped-routines — tasks

_Generated from `plan.md` on 2026-05-19. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Pre-flight

- [ ] 1. **Resolve open question: leader-flag filename.** Decide between `~/.claude/.routines-leaders.json` (clean) and `~/.claude/.agent0-routines-leaders.json` (namespaced, per `plan.md` § *Risks*). Default recommendation: `.agent0-routines-leaders.json` to avoid future CC collision. Record decision in `notes.md` as `### YYYY-MM-DD — parent — leader-flag filename`.

- [ ] 2. **Resolve open question: cron expression validator scope.** Confirm the 30-line bash regex is acceptable (5 fields, each matching `*|N|N-N|N/N|N,N`) — versus pulling a dep (violates portability tier). Default recommendation: ship the bash regex with explicit limits doc in `.claude/rules/routines.md`. Record decision in `notes.md`.

- [ ] 3. **Resolve open question: `idempotent: false` policy.** Confirm hard-reject at `/routine validate` (proposed) vs warn-only with `# OVERRIDE:`. Default recommendation: hard reject. Record decision in `notes.md`.

## Phase 1 — Discipline (rule first)

- [ ] 4. **Write `.claude/rules/routines.md`.** Sections: § *Summary* (one paragraph); § *When to use vs `/remind`* (decision table with worked examples — quarterly CC audit → routine; "review pricing Q3" → reminder); § *Idempotency mandate* (why hard rule); § *Leader-flag model* (per-repo opt-in, file location decided in task 1); § *Frontmatter reference* (field-by-field); § *Override marker* (same `# OVERRIDE: <reason ≥10 chars>` grammar); § *Cron expression syntax* (5-field, machine TZ, regex validator limits); § *Cross-references* (specs 019/016/064 + sibling rules `reminders.md`, `memory-placement.md`).

## Phase 2 — Skill scaffold (template path before tools depend on it)

- [ ] 5. **Scaffold `.claude/skills/routine/`.** Create `SKILL.md` with agentskills.io-compliant frontmatter (`name: routine`, `description: ...`, `argument-hint: <new|list|run|validate|dismiss> [<slug>]`, `metadata.agent0-portability-tier: cc-native`). Subcommand sections: `new <slug>`, `list`, `run <slug>`, `validate <slug>`, `dismiss <slug>`. Match the prose density and shape of `.claude/skills/remind/SKILL.md` (closest sibling).

- [ ] 6. **Write `.claude/skills/routine/templates/routine.md.tmpl`.** Frontmatter: `name: {{SLUG}}`, `schedule: "0 9 * * *"` (daily 09:00 default — author overrides), `on-stale: warn`, `idempotent: true`. Body: `# Prompt` block with example interpolation (`{{LAST_COMPLETED_TS}}`), `# Done when` block with two example criteria. Placeholders `{{SLUG}}` + `{{DATE}}`.

- [ ] 7. **Implement `/routine validate <slug>` first.** Bash script (callable from skill body via `bash .claude/skills/routine/scripts/validate.sh <slug>`). Checks: file exists; YAML frontmatter parseable; required keys present (`name`, `schedule`, `idempotent`); `idempotent: true` (hard reject per task 3); `schedule` matches 30-line bash regex (per task 2); body has `# Prompt` and `# Done when` headers. Exit 0 on pass, exit 1 on fail with stderr explaining which check failed.

- [ ] 8. **Implement `/routine new <slug>` subcommand.** Copy `routine.md.tmpl` → `.claude/routines/<slug>.md`, substitute `{{SLUG}}` and `{{DATE}}`. Refuse if file exists. Run `validate.sh` post-write as sanity check (template should pass own validator).

## Phase 3 — Cron executor (verifiable in isolation, no session dependency)

- [ ] 9. **Create `.claude/routines/.gitkeep`.** Empty file, ensures directory exists in fresh clones. Mirrors `.claude/memory/.gitkeep` convention.

- [ ] 10. **Add `.claude/.routines-state/` to `.gitignore`.** Per-machine cache; never tracked.

- [ ] 11. **Implement `.claude/tools/run-routine.sh`.** Args: `<slug>`. Steps: (a) leader check — read `~/.claude/.agent0-routines-leaders.json` (filename from task 1); abs-path key for current repo (resolve via `git rev-parse --show-toplevel`); if not leader → exit 0 silent; (b) parse routine frontmatter + body; (c) interpolate `{{LAST_COMPLETED_TS}}` (from `.claude/.routines-state/<slug>/last-completed.json`, default `"never"` if missing), `{{GIT_HEAD}}` (`git rev-parse HEAD`), `{{REPO_ROOT}}`; (d) write `.claude/.routines-state/<slug>/queue/<unix-ts>.md` with rendered prompt; (e) update `.claude/.routines-state/<slug>/last-queue.json`; (f) FIFO-rotate `completed/` to keep last 50. Idempotency-safe (re-running creates a new queue entry with same content — dedup is human responsibility via SessionStart visual).

- [ ] 12. **Implement `.claude/tools/install-routines.sh`.** Steps: (a) detect WSL2 via `grep -qi microsoft /proc/version`; if WSL2 → check `service cron status`, print `wsl-advisory:` to stderr if not running; (b) interactive prompt: `Designate this machine as routines leader for $(git rev-parse --show-toplevel)? [y/N]`; on `y` write entry to `~/.claude/.agent0-routines-leaders.json` (create file if missing, JSON object keyed on abs repo path); (c) generate crontab block from `.claude/routines/*.md` (one entry per routine: `<schedule> bash $(pwd)/.claude/tools/run-routine.sh <slug> >> $(pwd)/.claude/.routines-state/cron.log 2>&1`); (d) install into user crontab idempotently by replacing block between `# AGENT0-ROUTINES-START` / `# AGENT0-ROUTINES-END` markers (use `crontab -l 2>/dev/null` + `sed` + `crontab -`).

- [ ] 13. **Implement `.claude/tools/uninstall-routines.sh`.** Symmetric removal: strip the marker block from `crontab -l` via `sed`, pipe back to `crontab -`; remove this repo's entry from `~/.claude/.agent0-routines-leaders.json` (using `jq`); leave queue / completed state intact (user can inspect).

- [ ] 14. **End-to-end cron-side smoke test.** In a fresh test routine `.claude/routines/_smoke.md` with `schedule: "* * * * *"` (every minute), idempotent: true, prompt body `echo $(date)`: run `install-routines.sh`, wait ~70s, verify `.claude/.routines-state/_smoke/queue/<ts>.md` materialized with interpolated `{{LAST_COMPLETED_TS}}=never` and a `{{GIT_HEAD}}` SHA. Run `uninstall-routines.sh`, verify crontab clean. Delete `_smoke.md`. Record findings in `notes.md`.

## Phase 4 — SessionStart integration (close the loop)

- [ ] 15. **Implement `.claude/hooks/routines-readout.sh`.** Glob `.claude/.routines-state/*/queue/*.md`; if empty → exit 0 silent (mirror `mcp-recipes-hint.sh` pattern); else emit JSON `{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"=== ROUTINES ===\n<per-slug summary>\n=== end ROUTINES ==="}}`. Per-slug line shape: `- <slug>: N pending (oldest: Yd Yh ago) — dispatch with /routine run <slug>`.

- [ ] 16. **Register hook in `.claude/settings.json`.** Append to existing `SessionStart` hooks array (alongside `session-start.sh`, `reminders-readout.sh`, `mcp-recipes-hint.sh`): `{"type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/routines-readout.sh"}`. Verify via `jq` round-trip that JSON stays valid + sorted.

- [ ] 17. **Implement `/routine list` subcommand.** Iterate `.claude/routines/*.md`, parse frontmatter, print one line per routine: `<slug>  schedule=<cron>  leader=<yes|no|n/a>  queue=<N pending>  last-completed=<ts|never>`. Leader status read from `~/.claude/.agent0-routines-leaders.json`.

- [ ] 18. **Implement `/routine run <slug>` subcommand.** Pop oldest queue entry (move to `completed/<ts>.md` after success), dispatch the prompt body to the current Claude Code session. Idempotency note: per `plan.md`, the rule mandates routines themselves are idempotent — re-running a queue entry that was already executed should produce no destructive side effect. After successful dispatch, update `.claude/.routines-state/<slug>/last-completed.json` with the current ts.

- [ ] 19. **Implement `/routine dismiss <slug>` subcommand.** Remove ALL pending queue entries for `<slug>` (move to `completed/<ts>-dismissed.md` for audit) without executing. Used when a routine fires during an irrelevant work window.

## Phase 5 — Integration + propagation

- [ ] 20. **Add `## Routines` section to `CLAUDE.md`.** One paragraph, density mirroring `## Memory` / `## MCP recipes`. Cross-reference `.claude/rules/routines.md`. Position: between `## Reminders` (if exists) and `## Compact Instructions`. Mention the two-phase shape (v1 enqueue-for-session, Phase 2 autonomous via API key).

- [ ] 21. **Verify sync-harness glob coverage via `--check` on a test fork.** Pick or scaffold a sibling test repo with Agent0 harness; run `bash .claude/tools/sync-harness.sh --agent0-path=$(pwd) --check <fork>`. Expected drift output should mention all new files: `routines.md` rule, three `.claude/tools/*.sh` scripts, `routines-readout.sh` hook, the `routine/` skill subdir, the CLAUDE.md section. Verify `.claude/routines/` is NOT in the manifest output (capacity ships, instances don't). Record finding in `notes.md`.

## Verification — acceptance scenarios from `spec.md`

- [ ] 22. **Verify Scenario: declarative routine definition** — create `.claude/routines/_test-decl.md`, run `install-routines.sh`, wait one cron tick, confirm queue file materialized + SessionStart hook emits `=== ROUTINES ===` block on next session. Cleanup after.

- [ ] 23. **Verify Scenario: leader-flag N-fold prevention** — manually simulate non-leader state (remove repo entry from `~/.claude/.agent0-routines-leaders.json` or test in a second clone), invoke `run-routine.sh <slug>` directly, confirm exit 0 silent + no queue entry written.

- [ ] 24. **Verify Scenario: idempotent re-execution** — manually invoke `run-routine.sh <slug>` twice in succession (bypass cron), confirm two queue entries created (audit-rich, per task 1 design); confirm dispatching both produces identical side effect (using a routine whose body is `git status`, naturally idempotent).

- [ ] 25. **Verify Scenario: prompt interpolation at enqueue time** — covered by task 14 smoke test if `_smoke.md` includes `{{GIT_HEAD}}` interpolation. Re-verify with a routine that also uses `{{LAST_COMPLETED_TS}}` after a prior completion.

- [ ] 26. **Verify Scenario: session-start nag with queue digest** — covered by task 22; explicitly check the readout line format matches `- <slug>: N pending (oldest: Yd Yh ago) — dispatch with /routine run <slug>`.

- [ ] 27. **Verify Scenario: completion archival** — dispatch a queued routine via `/routine run`, confirm `queue/<ts>.md` → `completed/<ts>.md` move + `last-completed.json` update + `completed/` cap at 50 (force-populate 60 fake completed files and verify rotation).

- [ ] 28. **Verify Scenario: fork propagation via sync-harness** — covered by task 21.

- [ ] 29. **Verify static-fact checkboxes from `spec.md`** — `git status` to confirm: `.claude/routines/.gitkeep` exists and is tracked; `.claude/.routines-state/` matched by `.gitignore`; `~/.claude/.agent0-routines-leaders.json` is per-user (not in any repo); re-running `install-routines.sh` produces no duplicate crontab lines; `uninstall-routines.sh` leaves unrelated crontab entries intact; `/routine validate` rejects `idempotent: false` (write a fixture).

- [ ] 30. **Flip `spec.md` § `**Status:**` from `draft` → `in-progress` at start of implementation**, → `shipped` once tasks 1-29 are all checked.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers. For in-flight design decisions, deviations, tradeoffs, or open-questions discovered while building, use `notes.md` instead (per `.claude/rules/spec-driven.md` § The four artifacts)._
