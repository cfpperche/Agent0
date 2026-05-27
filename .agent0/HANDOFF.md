# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects and enforces this file through hooks; Codex reads and updates it by convention through `AGENTS.md`.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Spec 099 (`memory-multi-runtime`) fully scoped and ready for Phase A implementation.** `spec.md` + `plan.md` + `tasks.md` all filled; `debate.md` carries 4 debate rounds + revised synthesis + Applied changes (resolution: converged on hook-port direction after Round 3 critique invalidated the original asymmetric-convention premise). Spec status declared `draft`; flips to `in-progress` when Phase A task 1 lands.

**Agent0 is 10 commits ahead of `origin/main`** — not yet pushed. Recent: spec 098 ship + fixes (5 commits, 0f660d3 baseline), `runtime-capabilities` Codex lifecycle-hooks promotion (bb23dcf), spec 099 debate + synthesis + applied changes + plan + tasks (4 commits, latest cf945f2).

The Codex CLI lifecycle hooks discovery (2026-05-27 mid-debate) is the load-bearing finding of this session: matrix row updated `unsupported` → `native`; project memory `.claude/memory/codex-cli-hooks.md` captures the canonical hook surface; user-level feedback memory `feedback_verify_runtime_capabilities.md` captures the discipline lesson.

Pre-existing/paused work still present:

- `docs/specs/091-sdd-debate-runner/` is untracked and paused.
- Prior local fal.ai/Codex MCP setup remains machine-local (`.codex/config.toml`, `.codex/.env.local`) and should not be committed.

## Active Work

_None. Spec 099 is fully scoped and waiting for Phase A task 1 to start implementation._

## Next Actions

1. **Push Agent0 `main`** (10 commits ahead; cleanly buildable). Operator's call — not auto-pushed this session.
2. **Begin Phase A task 1**: dump-probe Codex `apply_patch` payload shape — requires an active Codex CLI session to register a transient probe hook, invoke a small `apply_patch`, capture stdin JSON, document the actual field carrying the patch body (likely `tool_input.command` per docs but unverified). Save findings to `docs/specs/099-memory-multi-runtime/notes.md`. Then delete the probe.
3. **After Phase A** (tasks 1-3): continue per `tasks.md` top-to-bottom. Phase B (hook port + shims) and Phase C (namespace move) are mechanical once task 1's probe finding is in hand.
4. **Phase E** (consumer migrations in mei-saas + codexeng) requires `git push` authorization to the consumer remotes — confirm before pushing.
5. Keep spec 091 paused unless explicitly resumed.
6. Do not commit `.codex/config.toml` or `.codex/.env.local`; they are local machine state.

## Decisions & Gotchas

- **Spec 099 transitional-state shape: Option A (compat shims).** Old `.claude/hooks/memory-*.sh` paths become 3-line `exec` shims to canonical `.agent0/hooks/memory-*.sh`. Existing consumers keep working post-sync; manual migration removes the shims. Option B (hard cutover) rejected — would break consumers because sync-harness deletes upstream-removed files but consumer settings.json (refused-customized) still references them.
- **Spec 099 namespace lock: `.agent0/memory/`.** User-ratified Scenario B early in the debate; OQ-1 became plan-phase enumeration task only. Memory tools + 4 memory hooks + `memory.config.json` all move under `.agent0/`; other Claude-specific paths stay under `.claude/`.
- **Codex `apply_patch` payload shape is unverified empirically.** Task 1 of Phase A is the dump-probe; do NOT write the patch-header parser before the probe lands real payload samples. Same lesson as `cc-platform-hooks.md` § Meta-lesson (spec 020 `PostToolUseFailure` shape divergence).
- **Codex hooks finding invalidated the entire pre-Round-4 convergence.** Old synthesis preserved in debate.md with SUPERSEDED marker (audit trail). Future readers must reach the "Synthesis (revised after Round 4)" section, not the first one.
- **Re-audit pending in runtime-capabilities.md.** The lifecycle-hooks promotion implies adjacent rows (`delegation/subagents`, `runtime introspect`, `session handoff`) may also need promotion to `native` or `native-opt-in`. Track via the next competitive-harness audit cycle.
- Codex HTTP MCP bearer auth should use `bearer_token_env_var`; literal `bearer_token` is not a valid fal.ai `streamable_http` path in the tested Codex version. Codex does not auto-load dotenv.
