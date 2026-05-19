# 064 — project-scoped-routines — plan

_Drafted from `spec.md` on 2026-05-19. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Build a **two-mechanism capacity**: (a) git-tracked **declarative routine definitions** under `.claude/routines/<slug>.md` (frontmatter + prompt body), serving as the single source of truth that propagates via clone and sync-harness; (b) **local cron executor** (`run-routine.sh`) that — gated by a per-user opt-in leader flag — renders each definition's prompt with fresh temporal context and enqueues it as a markdown file under `.claude/.routines-state/<slug>/queue/`. The executor does NOT call `claude -p` (no API key available, and headless autonomy is Phase 2 anyway). Instead, a `SessionStart` hook (`routines-readout.sh`) detects pending queue entries on the next interactive Claude Code session and surfaces them as a `=== ROUTINES ===` block alongside the existing `=== REMINDERS ===` and `=== SESSION.md ===` injections. The human-or-Claude then dispatches each pending routine via `/routine run <slug>` (or by hand), which executes the queued prompt and on success moves the file from `queue/` → `completed/`.

Ship order: (1) **rule first** (`.claude/rules/routines.md`) so the discipline is documented before the tooling exists; (2) **skill scaffold** (`/routine new <slug>`) so authors have a template path; (3) **executor + bootstrap scripts** so the cron half works in isolation, verifiable end-to-end without any session-side dependency; (4) **SessionStart hook** to close the loop into the interactive surface; (5) **CLAUDE.md update + sync-harness check** to make the capacity discoverable and fork-propagating. Each step is independently verifiable; rolling back any step leaves the prior steps functional. This mirrors how spec 011 (runtime-introspect) and spec 016 (sync-harness) were sequenced — rule + capacity + integration + propagation, in that order.

## Files to touch

**Create:**

- `.claude/rules/routines.md` — discipline doc: when to use vs `/remind`, idempotency mandate, leader-flag explanation, override marker grammar (`# OVERRIDE: <reason ≥10 chars>` consistent with other gates), cross-references to specs 019/016/064.
- `.claude/skills/routine/SKILL.md` — agentskills.io-compliant frontmatter (per `.claude/rules/skill-compliance` conventions); subcommands `new` / `list` / `run` / `validate` / `dismiss`; `argument-hint: <new|list|run|validate|dismiss> [<slug>]`.
- `.claude/skills/routine/templates/routine.md.tmpl` — scaffold template with frontmatter (`name`, `schedule`, `on-stale`, `idempotent: true`) + prompt body + done-when block; placeholders `{{SLUG}}`, `{{DATE}}`.
- `.claude/tools/install-routines.sh` — bootstrap: interactive leader-designation prompt → writes `~/.claude/.routines-leaders.json` entry; idempotent crontab install via `# AGENT0-ROUTINES-START` / `# AGENT0-ROUTINES-END` marker block; WSL2 detection + advisory.
- `.claude/tools/uninstall-routines.sh` — symmetric removal: strips the marker block from user crontab without touching unrelated entries; removes the repo's leader-flag entry from `~/.claude/.routines-leaders.json`.
- `.claude/tools/run-routine.sh` — invoked by cron: (1) leader check, (2) prompt interpolation (`{{LAST_COMPLETED_TS}}`, `{{GIT_HEAD}}`, `{{REPO_ROOT}}`), (3) enqueue write to `.claude/.routines-state/<slug>/queue/<ts>.md`, (4) `last-queue.json` update, (5) `completed/` rotation cap at 50 (FIFO).
- `.claude/hooks/routines-readout.sh` — `SessionStart` hook: globs `.claude/.routines-state/*/queue/*.md`, formats `=== ROUTINES ===` block with slug, oldest-entry age, count, dispatch hint; silent when queue is empty (mirrors `mcp-recipes-hint.sh` pattern).
- `.claude/routines/.gitkeep` — empty scaffold so the directory exists in fresh clones (mirrors `.claude/memory/.gitkeep` convention from spec 019).
- `docs/specs/064-project-scoped-routines/notes.md` — already scaffolded; will receive in-flight decisions during implementation.

**Modify:**

- `.claude/settings.json` — register `routines-readout.sh` as a `SessionStart` hook command (matcher absent, runs unconditionally like `reminders-readout.sh`).
- `.gitignore` — add `.claude/.routines-state/` (per-machine cache, gitignored).
- `CLAUDE.md` — add `## Routines` section between `## Reminders` (if exists) and `## Compact Instructions`, mirroring the prose density of `## Memory` / `## MCP recipes` sections; one paragraph + cross-reference to `.claude/rules/routines.md`.
- `.claude/tools/sync-harness.sh` — verify glob coverage: `.claude/hooks|*.sh` picks up `routines-readout.sh`, `.claude/tools|*.sh` picks up the three new tools, `.claude/rules|*.md` picks up `routines.md`, `.claude/skills` picks up the `routine/` subdir. No manifest edit expected; verify via dogfood `--check`.

**Delete:**

- None.

## Alternatives considered

### Direct headless execution via `claude -p` instead of enqueue-for-session

Rejected because the user does not currently hold an Anthropic API key, so the cron-side cannot invoke `claude -p` autonomously. Even with an API key, the enqueue-for-session shape has a real virtue: it keeps the human-in-loop for every recurring action by default, which matches Agent0's overall "contract not promise" discipline (cf. `.claude/rules/delegation.md` § *Why DONE_WHEN exists*) — a routine that auto-commits without review is a foot-gun. Phase 2 will offer `autonomous: true` as opt-in frontmatter for routines genuinely safe to run headless (e.g. snapshot rotation, log cleanup), but the default stays "queue for next session".

### GitHub Actions executor instead of local cron

Rejected for v1 because (a) it requires the repo to live on GitHub (forks may be hosted elsewhere), and (b) it requires `ANTHROPIC_API_KEY` as a GitHub secret to do any LLM work, which closes the same door as `claude -p`. The research surfaced GitHub Actions as the cleaner long-term shape (zero bootstrap, run-once-globally, audit grátis) and a future spec layered on top of this one is the intended path; but as the *only* v1 mechanism it would block adoption. Local cron + enqueue-for-session works offline, on any OS with cron, with zero API spend.

### Distributed leader election (Redis / etcd / file-lock in repo)

Rejected because real distributed leader election (Chubby / etcd / Redis Redlock per [Google SRE](https://sre.google/sre-book/distributed-periodic-scheduling/)) is order-of-magnitude over-engineered for a dev-tools capacity. Manual leader designation via `~/.claude/.routines-leaders.json` (the "designate one machine" cheap workaround the same SRE chapter recommends) plus mandatory idempotency discipline gives 95% of the value at 5% of the complexity. The 5% remaining (accidental dual-leader spam) is caught by the SessionStart readout (human sees duplicate queue entries before action), per the 4-layer defense documented in `spec.md` § *N-fold prevention*.

### Per-routine leader (vs per-repo)

Rejected because per-routine leader granularity reintroduces the exact coordination problem this spec is built to avoid — "which machine owns routine X?". Per-repo leader has one knob, one file, one decision; per-routine leader has N knobs and N files for N routines. If a real team need surfaces where one developer wants routine A and another wants routine B on their respective machines, that's a Phase 2 problem with real data; v1 picks the simpler model.

### Imperative `/routine add <slug> --cron="..."` (state in repo via slash command)

Rejected because it puts state mutation inside an interactive session, requires a parser for cron strings inside the skill, and conflicts with the declarative-source-of-truth principle that makes the capacity propagatable. Authoring a `.claude/routines/<slug>.md` file directly is shorter, reviewable in git, and survives every edge case (multi-developer edit, fork override, diff in PR).

### `cron` daemon vs `systemd-timer` vs `launchd`

Rejected systemd-timer / launchd because: (a) cross-platform consistency matters (Linux + WSL2 + macOS contributors); cron is the lowest-common-denominator; (b) `crontab -e` is user-scoped without sudo, systemd-timer requires either `--user` mode (not always enabled in WSL2) or root; (c) the bootstrap script becomes one path instead of three. WSL2 cron quirks (manual `service cron start`) are an accepted tradeoff and documented with a `wsl-advisory:` line during install.

## Risks and unknowns

- **WSL2 cron daemon defaults vary.** WSL2 distros sometimes ship without cron auto-starting at session boot. Mitigation: `install-routines.sh` runs `service cron status` post-install and prints `wsl-advisory: cron not running; run 'sudo service cron start' and add to ~/.profile for persistence` when WSL2 is detected (via `grep -qi microsoft /proc/version`). Spike during task 6 to verify behavior on Ubuntu-WSL2.
- **Concurrent SessionStart on same machine.** If two `claude` sessions launch within milliseconds, both readout hooks may race on the same queue dir. Mitigation: readout is read-only (it doesn't mutate the queue), so worst case is identical output emitted twice — harmless. The actual `/routine run <slug>` dispatch is what mutates state, and that's serialized through user/Claude turn-taking.
- **Cron expression validation surface.** Frontmatter `schedule:` field accepts a 5-field cron string. The skill's `validate` subcommand needs to reject malformed expressions; pulling a dependency for this would violate "agentskills-portable" tier. Mitigation: ship a 30-line bash regex validator (5 fields, each `*|N|N-N|N/N|N,N`) — good enough for v1; document the validator's limits in `.claude/rules/routines.md`.
- **`completed/` rotation race.** If two routines complete near-simultaneously and the FIFO rotation runs twice within milliseconds, the keep-N count could slip below 50. Mitigation: accept the imprecision (the count is a soft cap, not a quota); `ls -t | tail -n +51 | xargs rm -f` is idempotent under races (worst case: extra deletions).
- **Leader-flag file location convention.** `~/.claude/.routines-leaders.json` lives in CC's per-user config dir — confirmed precedent: CC writes to `~/.claude/` already (e.g. `~/.claude/projects/.../`). But the *.json schema* is ours; a future CC update could conflict on filename. Mitigation: prefix the file with `.agent0-` (`.agent0-routines-leaders.json`) to namespace it. Decide during task 3.
- **Sync-harness `--force-except` semantics for `.claude/routines/`.** When a fork has its own routine definitions, an upstream `sync-harness --apply` should NOT clobber them (the directory `.claude/routines/` is the *fork's*, not the harness's). Mitigation: sync-harness glob `.claude/routines|*.md` is NOT added to the manifest (deliberately) — only the *capacity files* propagate; routine *instances* are fork-local. Verify in task 9 via dogfood.
- **Cron job ID stability.** If the user renames a routine slug (`.md` → different `.md`), the crontab entry needs to update too. Since the crontab is generated from the marker block, `install-routines.sh` regenerates the block on every run — but only if explicitly re-invoked. Mitigation: document in `.claude/rules/routines.md` that renaming a routine slug requires re-running `install-routines.sh`. Could automate via a `routines-watch.sh` post-edit hook in v2.

## Research / citations

- **Prior art matrix** (10 systems surveyed during design session 2026-05-19, captured in conversation; full citations in `spec.md` § *External research*):
  - [GitHub Actions concurrency](https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/control-the-concurrency-of-workflows-and-jobs) — `concurrency:` group pattern; informs the "overlap is the default failure mode" mental model
  - [Google SRE — Distributed Periodic Scheduling](https://sre.google/sre-book/distributed-periodic-scheduling/) — "designate one machine" workaround; why leader election is overkill for dev tools
  - [pre-commit framework](https://github.com/pre-commit/pre-commit) — `install` bootstrap pattern; #1 adoption failure is forgotten install (our `install-routines.sh` inherits this risk and addresses via SessionStart nag for missing crontab)
  - [Renovate config-in-repo](https://docs.renovatebot.com/config-overview/) — declarative source-of-truth, centralized executor; the cleaner shape we'll layer on in Phase 2 via GH Actions
  - [Goose Scheduler](https://deepwiki.com/block/goose/4.1.5-scheduler-and-recurring-tasks) — state-outside-repo failure mode (their `Paths::data_dir()`) we're explicitly avoiding by git-tracking definitions
  - [Hermes Agent cron](https://hermes-agent.nousresearch.com/docs/user-guide/features/cron) — per-user account-scoped, same gap as `/schedule`; reinforces the user-vs-project split that motivates this spec
  - [OpenCode scheduler plugin v1.2.0](https://github.com/different-ai/opencode-scheduler) — workdir-scoping lesson; we inherit "scope by repo path" via the leader-flag dict keyed on absolute repo path
  - [Claude Code routines docs](https://code.claude.com/docs/en/routines.md) — the account-scoped primitive this spec is the project-scoped sibling of
- **Internal precedents:**
  - Spec 019 (`.claude/memory/`) — the analog 3-bucket split that motivates this spec's design
  - Spec 016 (`sync-harness.sh`) — propagation mechanism; this spec must verify its glob coverage covers new files
  - Spec 011 (runtime-introspect) — shape precedent for "git-tracked state file + readback tool + opt-in env var"
  - `.claude/rules/memory-placement.md` — 3-bucket model applied here: user `/schedule` / project `.claude/routines/` / shipped-as-capacity in `.claude/{tools,hooks,rules,skills}/`
  - `.claude/rules/reminders.md` — sibling capacity boundaries; the *When to use vs `/remind`* section in `.claude/rules/routines.md` will mirror the discipline split documented there
  - `.claude/hooks/reminders-readout.sh` + `.claude/hooks/mcp-recipes-hint.sh` — direct prior art for the `SessionStart` readout pattern (silent when empty, `=== HEADER ===` block when non-empty)
  - `.claude/skills/skill/references/spec-snapshot.md` — agentskills.io frontmatter spec the new `/routine` skill must comply with
- **Conversation 2026-05-19** (heartbeat session) — full design discussion: gap analysis vs `/schedule`, two-mode (queue-now / autonomous-later) decision, 4-layer N-fold defense rationale, file inventory, open-question triage. Synthesized into this spec + plan.
