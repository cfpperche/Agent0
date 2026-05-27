# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects and enforces this file through hooks; Codex reads and updates it by convention through `AGENTS.md`.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Statusline extracted from harness to user-global `~/.claude/`** (commit `bab8ebf`, 7 files, -275/+25). Script lives at `~/.claude/scripts/statusline.mjs`, wired from `~/.claude/settings.json`; harness no longer ships or merges it. Test battery 35/35 PASS. Consumers symmetric: mei-saas `45e43ba`, codexeng `6b323a5`. Rationale in commit body + `harness-sync.md` § Gotchas (extracted 2026-05-27).

**Spec 099 (`memory-multi-runtime`) still pre-Phase-A.** `spec/plan/tasks.md` filled, draft. The `.claude/memory/` → `.agent0/memory/` migration changes are present in the **working tree only** — the statusline commit was carefully scoped to avoid pulling 099 WIP.

**Agent0 1 commit ahead of `origin/main`** (`bab8ebf`); previous 10-ahead state from prior HANDOFF was pushed.

Pre-existing/paused: `docs/specs/091-sdd-debate-runner/` untracked; `.codex/config.toml` + `.codex/.env.local` machine-local.

## Active Work

_None. Statusline extraction shipped end-to-end. Spec 099 Phase A still untouched._

## Next Actions

1. **Push Agent0 `main`** (1 commit ahead — `bab8ebf` statusline extraction). Operator's call.
2. **Push mei-saas + codexeng** (1 commit each — `45e43ba`, `6b323a5`). Confirm before pushing each remote.
3. **Begin Spec 099 Phase A task 1**: dump-probe Codex `apply_patch` payload shape — requires an active Codex CLI session to register a transient probe hook, invoke a small `apply_patch`, capture stdin JSON, document the actual field carrying the patch body. Save findings to `docs/specs/099-memory-multi-runtime/notes.md`. Then delete the probe.
4. **Spec 099 absorbs 2 leftover edits**: the working tree has unstaged statusline-context edits in `.agent0/memory/agent0-purpose.md` (statusline bullet) and `.agent0/memory/compaction-continuity.md` (key list `$schema / hooks`). The next spec 099 commit that handles the `.claude/memory/` → `.agent0/memory/` rename should absorb them inline rather than separate commits.
5. **After Phase A** (tasks 1-3): continue per `tasks.md` top-to-bottom. Phases B + C mechanical once probe lands.
6. Keep spec 091 paused unless explicitly resumed.

## Decisions & Gotchas

- **Statusline = operator UX, not project policy.** Sub-bugs A/B in `harness-sync.md` § Gotchas documented the failure class; extraction eliminates it. Lessons preserved with `extracted 2026-05-27` markers.
- **Partial-staging recipe for mixed-hunks files** (when separating in-scope edits from in-flight WIP edits in the same file): backup → `git checkout HEAD -- <f>` → re-apply only in-scope edits → `git add <f>` → restore working tree from backup. Then unstage unwanted pre-staged renames via `git restore --staged` looped over `git diff --cached --diff-filter=R --name-status HEAD`.
- **Spec 099 transitional-state shape: Option A (compat shims).** Old `.claude/hooks/memory-*.sh` paths become 3-line `exec` shims to canonical `.agent0/hooks/memory-*.sh`. Existing consumers keep working post-sync; manual migration removes the shims.
- **Spec 099 namespace lock: `.agent0/memory/`.** User-ratified Scenario B; OQ-1 became plan-phase enumeration only.
- **Codex `apply_patch` payload shape is unverified.** Task 1 of Phase A is the dump-probe; do NOT write the patch-header parser before the probe lands real payload samples. Same lesson as `cc-platform-hooks.md` § Meta-lesson.
- **Re-audit pending in `runtime-capabilities.md`.** The Codex lifecycle-hooks promotion implies adjacent rows (`delegation/subagents`, `runtime introspect`, `session handoff`) may also need promotion. Track via next competitive-harness audit cycle.
- Codex HTTP MCP bearer auth uses `bearer_token_env_var`, not literal `bearer_token`. Codex does not auto-load dotenv.
