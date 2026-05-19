# 064 — project-scoped-routines

_Created 2026-05-19._

**Status:** shipped

## Intent

Claude Code's native `/schedule` skill stores routines as account-scoped cloud state on Anthropic's backend — the right shape for per-user automations, but the wrong shape for **project-scoped** recurring work that multiple developers cloning a shared repo all benefit from (quarterly CC platform audits, weekly dependency drift checks, scheduled re-research of stack defaults snapshots, etc.). This is the same gap that justified spec 019's project memory bucket: `/schedule` is to project routines what CC's per-user memory is to `.claude/memory/` — necessary but insufficient when the source of truth needs to live in git, propagate via clone, and ship to forks via sync-harness. This spec introduces `.claude/routines/` — git-tracked declarative routine definitions — plus a local cron executor that renders prompts into a session-level queue (NOT autonomous execution via `claude -p`, which would require an Anthropic API key the founder doesn't currently hold). The next interactive Claude Code session reads the queue and dispatches each pending routine, keeping the human-in-loop while making "remember to do X every N weeks" a property of the repo, not of the developer's head.

## Acceptance criteria

- [x] **Scenario: declarative routine definition**
  - **Given** a fork has cloned Agent0 and run `./.claude/tools/install-routines.sh` once, designating itself as leader
  - **When** the developer creates `.claude/routines/cc-knowledge-audit.md` with frontmatter `schedule: "0 9 1 */3 *"` and commits it
  - **Then** the next cron tick on the leader machine matching that schedule renders the prompt into `.claude/.routines-state/cc-knowledge-audit/queue/<ts>.md`, and the next interactive Claude Code session emits a `=== ROUTINES ===` block listing the pending routine

- [x] **Scenario: leader-flag N-fold prevention**
  - **Given** three developers have cloned the same repo, but only one ran `install-routines.sh` answering "y" to the leader-designation prompt
  - **When** the scheduled cron tick fires on all three machines simultaneously
  - **Then** only the leader machine writes to `queue/`; the other two `run-routine.sh` invocations exit 0 silently after checking `~/.claude/.agent0-routines-leaders.json` for this repo

- [x] **Scenario: idempotent re-execution**
  - **Given** a routine ran successfully and produced output (commit, edit, or `no-drift-detected` log)
  - **When** the same routine is dispatched again within the same scheduling window (manual `/routine run <slug>` or accidental dual-leader)
  - **Then** the second execution either no-ops because state is already current, or produces an identical artifact — no destructive side effect, no duplicated PR / commit / issue

- [x] **Scenario: prompt interpolation at enqueue time**
  - **Given** `.claude/routines/<slug>.md` contains `{{LAST_COMPLETED_TS}}` and `{{GIT_HEAD}}` placeholders in the prompt body
  - **When** `run-routine.sh` renders the queue entry
  - **Then** placeholders are substituted with values read from `.claude/.routines-state/<slug>/last-completed.json` and `git rev-parse HEAD` respectively, so the dispatched prompt carries fresh temporal context

- [x] **Scenario: session-start nag with queue digest**
  - **Given** ≥1 routine has pending queue entries from prior cron ticks
  - **When** a new Claude Code session starts in the repo
  - **Then** `routines-readout.sh` (SessionStart hook) emits a `=== ROUTINES ===` block listing each pending slug, age of oldest queued entry, count of queued entries, and the slash-command form to dispatch (`/routine run <slug>`)

- [x] **Scenario: completion archival**
  - **Given** a queued routine has just been successfully executed in an interactive session
  - **When** the dispatched routine reports done (per its `# Done when` block)
  - **Then** the queue file moves from `queue/<ts>.md` → `completed/<ts>.md`, `last-completed.json` updates, and `completed/` rotation caps at 50 entries (oldest dropped FIFO)

- [x] **Scenario: fork propagation via sync-harness**
  - **Given** a fork that previously adopted Agent0's harness and is running `sync-harness.sh --check`
  - **When** spec 064 capacities land in upstream Agent0
  - **Then** `--check` reports drift for `.claude/tools/{install,uninstall,run}-routines.sh`, `.claude/hooks/routines-readout.sh`, `.claude/rules/routines.md`, `.claude/skills/routine/SKILL.md`; `--apply` installs them; fork-specific `.claude/routines/*.md` definitions are NOT overwritten (sync ships the capacity, not the routine instances)

- [x] `.claude/routines/<slug>.md` files exist and are git-tracked (NOT gitignored)
- [x] `.claude/.routines-state/**` is gitignored (per-machine ephemeral cache)
- [x] `~/.claude/.agent0-routines-leaders.json` is per-user, never in any repo
- [x] `install-routines.sh` is idempotent: re-running produces no duplicate crontab entries (uses `# AGENT0-ROUTINES-START / END` marker block)
- [x] `uninstall-routines.sh` removes the marker block cleanly without touching unrelated crontab entries
- [x] `/routine validate <slug>` rejects a routine declaring `idempotent: false` in its frontmatter
- [x] The discipline is documented in `.claude/rules/routines.md`, cross-referenced from CLAUDE.md `## Routines` section
- [x] Sync-harness manifest includes all capacity files; `--check` on a fork reports drift when this spec lands upstream

## Non-goals

- **Autonomous headless execution via `claude -p`.** Phase 2 territory. v1 only enqueues prompts for the next interactive session — no Anthropic API key required. The frontmatter field `autonomous: true` (and the runner adaptation it implies) is explicitly out of scope for this spec.
- **GitHub Actions / centralized cloud executor.** The research surveyed `.github/workflows/`-based execution as the cleaner long-term path; that's a separate spec layered on top of this one once headless execution lands. v1 is local-cron only.
- **Distributed leader election (Redis / etcd / Chubby-style).** Per Google SRE distributed-cron literature, real leader election is the right answer for serious distributed cron — and overkill for a dev-tools capacity. v1 uses manual leader designation (one machine answers "y" at bootstrap) backed by idempotency discipline.
- **Per-routine leader granularity.** v1 leader is per-repo, not per-slug. Per-slug granularity reintroduces the "which machine owns routine X" coordination problem this spec is trying to avoid.
- **Cross-fork override semantics for routine definitions.** Forks can add their own `.claude/routines/*.md` (capacity ships via sync, instances don't), but the rules for what happens when a fork wants to *modify* an upstream-shipped routine are deferred — currently sync-harness's hash-compare + `--force` machinery is the answer by default.
- **Secret management.** v1 routines run prompts; they don't need API tokens. If a Phase 2 autonomous routine needs an env-scoped secret, that's a Phase 2 design problem.
- **Web UI / dashboard for routine status.** Per `.claude/memory/feedback_speculative_observability.md`, observability infrastructure is built after rule-of-three demand has been observed, not pre-emptively. SessionStart nag is the only surface in v1.
- **Replacing `/remind`.** `/remind` is for one-shot deferred items with no cadence. `/routine` is for recurring cadence-driven items. They serve different ends; both stay.

## Open questions

- [x] **Queue collapsing semantics.** Should multiple cron ticks between two interactive sessions produce multiple queue files (audit-rich) or substitute the latest (terse)? Recommended default: append (multiple files), but the SessionStart readout collapses the display to "N pending since <oldest>". Owner: founder, decide before plan.
- [x] **`idempotent: false` policy.** Reject at validate time (proposed), or warn-only with override marker? Recommended: hard reject — non-idempotent recurring work has no home here; route to `/remind` or `/sdd` instead. Owner: founder.
- [x] **`crontab` install mechanism.** User-level `crontab -e` (no sudo, current proposal) vs. `/etc/cron.d/` drop-in (system-wide, needs sudo). Recommended: user crontab, idempotency via comment marker. Owner: founder; verify WSL2 cron daemon defaults before locking.
- [x] **WSL2 portability detection.** WSL2 cron sometimes requires `service cron start` manual activation per session. Should `install-routines.sh` detect WSL2 and warn / auto-configure, or document and skip? Recommended: detect + warn + emit one-line `wsl-advisory:` to stderr. Owner: founder; spike during plan phase.
- [x] **`completed/` rotation cap.** Hard-coded 50 (current proposal) vs. env-configurable `CLAUDE_ROUTINES_KEEP_N`? Recommended: hard-code 50 for v1, promote to env var only if rule-of-three demand emerges. Owner: founder.
- [x] **Routine vs `/remind` triage rule.** Need explicit `.claude/rules/routines.md` § *When to use vs `/remind`* table. The line is "recurring cadence" vs "one-shot deferred", but the rule should give worked examples (quarterly CC audit → routine; "review pricing in Q3" → reminder; "weekly dependency check" → routine). Owner: founder, finalize during rule authoring.

## Context / references

- **Spec 019 — project memory bucket.** The parent shape: git-tracked, project-bounded, multi-developer-shared, distinct from per-user equivalent. `/routines` is to `/schedule` what `.claude/memory/` is to CC's per-user memory.
- **Spec 016 — harness sync.** Mechanism for propagating the capacity to forks; manifest must include new files.
- **`.claude/rules/memory-placement.md`** — the 3-bucket model (per-user / project / shipped-to-forks); same model applies to routines (per-user `/schedule` / project `.claude/routines/` / capacity in `.claude/{tools,hooks,rules,skills}/`).
- **`.claude/rules/research-before-proposing.md`** — research conducted; sources cited below.
- **`.claude/memory/feedback_speculative_observability.md`** — rule-of-three demand-test; gates the Phase 2 (`claude -p` autonomous) and the dashboard/UI work behind real adoption data.
- **`.claude/skills/remind/SKILL.md`** + `.claude/rules/reminders.md`** — the sibling capacity that handles one-shot deferred items; `/routine` differentiates via cadence.
- **Conversation 2026-05-19** — design discussion in the heartbeat session; full research matrix of 10 prior-art systems (GitHub Actions, GitLab schedules, Renovate, Dependabot, pre-commit, Hermes Agent, Goose, Codex CLI, OpenCode, agentskills.io) captured for `plan.md`.
- **External research:**
  - [GitHub Actions concurrency](https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/control-the-concurrency-of-workflows-and-jobs) — gotcha #2 (overlap prevention pattern)
  - [Google SRE — Distributed Periodic Scheduling](https://sre.google/sre-book/distributed-periodic-scheduling/) — why leader election is overkill here; "designate one machine" is the canonical cheap workaround
  - [Goose Scheduler](https://deepwiki.com/block/goose/4.1.5-scheduler-and-recurring-tasks) — closest agent-harness analog; state-outside-repo failure mode we're explicitly avoiding
  - [Hermes Agent cron](https://hermes-agent.nousresearch.com/docs/user-guide/features/cron) — per-user account-scoped, same gap as `/schedule`
  - [OpenCode scheduler plugin](https://github.com/different-ai/opencode-scheduler) — workdir-scoping pattern (v1.2.0 lesson we inherit)
  - [Claude Code routines docs](https://code.claude.com/docs/en/routines.md) — the account-scoped primitive this spec layers a project-scoped sibling onto
