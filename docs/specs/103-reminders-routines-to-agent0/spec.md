# 103 — reminders-routines-to-agent0

_Created 2026-05-28._

**Status:** shipped

## Intent

Phase 1 of the `.agent0/` harness consolidation (umbrella `102-harness-consolidate-agent0`): relocate the **reminders** and **routines** capacities' state/data from `.claude/` to `.agent0/`, so the canonical harness home holds them alongside the already-relocated memory, session hooks, and HANDOFF.md. Both capacities are runtime-neutral by the umbrella's shared test — their readout hooks already live in `.agent0/hooks/` (specs 099/100) and fire on both Claude and Codex — but their data still sits under Claude's conventional home, splitting each capacity across two trees. This is a pure relocation + reference rewrite: no behavior, schema, or contract change. Moves: `.claude/reminders.yaml` → `.agent0/reminders.yaml`; `.claude/routines/` → `.agent0/routines/`; `.claude/.routines-state/` → `.agent0/.routines-state/`.

## Acceptance criteria

- [ ] **Scenario: reminders readout reads the relocated data**
  - **Given** `.agent0/reminders.yaml` exists with a `status: pending` entry and no `.claude/reminders.yaml` remains
  - **When** `.agent0/hooks/reminders-readout.sh` fires at SessionStart (Claude or Codex payload)
  - **Then** the `=== REMINDERS ===` block contains the entry, resolved from `.agent0/reminders.yaml`

- [ ] **Scenario: /remind helper writes to the relocated path**
  - **Given** the `/remind` helper runs `add "<text>"`
  - **When** it persists state
  - **Then** it creates/updates `.agent0/reminders.yaml` (never `.claude/reminders.yaml`)

- [ ] **Scenario: routine subcommands operate on the relocated tree**
  - **Given** a routine at `.agent0/routines/<slug>.md`
  - **When** `/routine list` / `validate <slug>` / `run <slug>` execute
  - **Then** they resolve definitions from `.agent0/routines/` and per-machine state from `.agent0/.routines-state/`

- [ ] **Scenario: cron enqueue writes to the relocated state dir**
  - **Given** `.claude/tools/run-routine.sh` fires for a leader machine
  - **When** it enqueues a render
  - **Then** the queue file lands under `.agent0/.routines-state/<slug>/queue/` (not `.claude/.routines-state/`)

- [ ] **Scenario: subdir launch still resolves to git-root data**
  - **Given** a session launched from a repo subdirectory
  - **When** the reminders/routines readouts fire
  - **Then** `memory_project_dir` resolves the git root and reads `.agent0/reminders.yaml` / `.agent0/routines/` there

- [ ] `git mv` preserves history: `.agent0/reminders.yaml` and `.agent0/routines/*.md` are tracked with continuous `git log --follow`; `.claude/reminders.yaml` and `.claude/routines/` no longer exist.
- [ ] `.gitignore` ignores `.agent0/.routines-state/` and no longer lists `.claude/.routines-state/`.
- [ ] Zero references to `.claude/reminders.yaml`, `.claude/routines`, or `.claude/.routines-state` across the shipped surface (`.agent0/hooks/`, `.claude/skills/`, `.claude/tools/`, `.claude/rules/`, `.claude/tests/`, `AGENTS.md`, `CLAUDE.md`) — historical `docs/specs/` and ephemeral `.claude/.session-state/*` excluded.
- [ ] `sync-harness.sh` manifest updated: base-dirs/special-files reference `.agent0/routines/.gitkeep` (not `.claude/routines/.gitkeep`); `--apply --dry-run` against a fixture consumer shows the relocated paths propagate with no dangling old path.
- [ ] All affected suites pass: `multi-runtime-readouts/`, any `routine`/`remind` tests, plus the broader regression set touched in spec 100/101.

## Non-goals

- Moving the user-scope leader file `~/.claude/.agent0-routines-leaders.json`. It lives outside the repo tree, is already `.agent0-`namespaced, and relocating it would break existing leader designations. Stays.
- Auto-migrating consumer-fork data. Capacity-only per umbrella 102 — existing forks move their own `.claude/reminders.yaml` / `.claude/routines/` on next sync; documented in `.claude/rules/harness-sync.md`.
- Any reminders/routines behavior, schema, cron-syntax, or override-grammar change.
- Re-tiering `/remind` or `/routine` (both stay `cc-native`; data location is independent of skill portability tier).
- Touching the `undecided` umbrella rows (session-state, runtime-state, browser-state, tools, rules, skills, validators).

## Open questions

- [ ] Physically `mv` this machine's existing gitignored `.claude/.routines-state/` content to `.agent0/.routines-state/`, or update paths and let it regenerate (orphaning the old `completed/` history)? Lean: `mv` it — cheap, preserves the local audit trail.
- [ ] Does the `.codex/config.toml.example` (and the machine-local `.codex/config.toml`) need any change? Expected no — the Codex hook blocks point at `.agent0/hooks/*.sh` scripts, which resolve data paths internally; confirm during plan.

## Context / references

- `docs/specs/102-harness-consolidate-agent0/` — parent umbrella; this is its Phase 1, rows 1-2 of the gap matrix.
- `.claude/rules/reminders.md`, `.claude/rules/routines.md` — capacity rules carrying the most `.claude/`-path references to rewrite.
- `.agent0/hooks/reminders-readout.sh` (`YAML_FILE="$PROJECT_DIR/.claude/reminders.yaml"`), `.agent0/hooks/routines-readout.sh` — readout hooks to repoint.
- `.claude/skills/remind/scripts/reminders-helper.py` (`_project_root` → `.claude/reminders.yaml`), `.claude/skills/routine/scripts/{list,new,validate}.sh`, `.claude/skills/routine/templates/routine.md.tmpl` — helper/script path constants.
- `.claude/tools/{install,run,uninstall}-routines.sh`, `.claude/tools/sync-harness.sh` — cron tools + propagation manifest.
- `.claude/tests/multi-runtime-readouts/{01-reminders-fixture,02-routines-fixture,04-subdir-launch}.sh` — fixtures asserting the old paths.
- Full reference surface mapped 2026-05-28 (grep in conversation): rules `runtime-capabilities.md` + `image-gen.md`, `skill/SKILL.md` + `portability-tiers.md`, `.claude/.runtime-state/README.md`, `AGENTS.md`, `CLAUDE.md`.
