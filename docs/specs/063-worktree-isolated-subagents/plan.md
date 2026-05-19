# 063 — worktree-isolated-subagents — plan

_Drafted from `spec.md` on 2026-05-19. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach (revised 2026-05-19 per Option B redirect)

_Pre-flight empirical discovery of CC 2.1.144's native worktree primitives changed the design. See `spec.md` § Redesign. The original approach below the line `## Approach (original — superseded)` is preserved as design memory._

Three minimal-viable additions, no new brief field:

1. **Extend `.claude/hooks/delegation-gate.sh`** to extract `tool_input.isolation` from the PreToolUse(Agent) payload and include it in the dispatch audit row as the 13th field. Cost: ~2 lines (one `jq -r` extraction, one `--arg` + schema entry in the `jq -n` build). Identical pattern to the `tool_use_id` extension shipped for spec 061. The audit row schema becomes additive — pre-deploy rows lack the `isolation` field; post-deploy rows have it as empty string when unset, `"worktree"` when set. No migration needed.

2. **Add `## Worktree isolation` section to `.claude/rules/delegation.md`** after the existing `## Audit log` section. Documents:
   - What CC's native mechanism does (parent sets `isolation`, sub-agent gets system-prompt injection to call `EnterWorktree`, worktree at `.claude/worktrees/<name>/`, cleanup at session-end or `ExitWorktree`)
   - When parents should declare isolation (parallel dispatches with overlap risk; new files in unknown locations; destructive ops)
   - When NOT to (single read-only sub-agent; sub-agent must observe parent in-flight state)
   - Why no brief field (canonical mechanism is `tool_input.isolation`; brief duplication would be redundant — gate cannot bridge brief to tool params anyway)

3. **Modify `.claude/hooks/post-edit-validate.sh`** to derive the validator's cwd from the git toplevel of the edit's `tool_input.file_path`, falling back to `$PROJECT_DIR` when git resolution fails. Subshell-isolated `cd` so the rest of the hook (which uses `$PROJECT_DIR` for state paths) is unaffected. Independent gain — also helps any sub-agent edit in a subdirectory that the parent project doesn't directly own, not just worktree-isolated ones.

Order of operations:

1. Spec docs redirected (this commit's first slice) — `spec.md` § Redesign, `plan.md` (here), `tasks.md`, `notes.md` updated.
2. Implement audit field in `delegation-gate.sh` (~2 lines).
3. Implement validator scoping in `post-edit-validate.sh` (~10 lines including derivation + fallback).
4. Document via new section in `delegation.md`.
5. Empirical e2e: dispatch a tiny `Agent` call with `isolation: "worktree"` in tool params (or without — both cases need verification); tail `delegation-audit.jsonl` to confirm `isolation` field populated correctly.
6. Commit as `feat(063): worktree isolation discipline — audit + scoping + rule`. Push.

## Approach (original — superseded by Redesign 2026-05-19)

Layer on top of the `Agent` tool's existing `isolation: "worktree"` parameter without modifying the tool itself. The 6th optional handoff field `ISOLATION:` is a contract between parent and gate — the gate validates and audits, the parent (assistant model) is responsible for setting the `isolation` parameter in the actual tool call when its own brief declared it. This is rule-only discipline at the parent boundary, same pattern as `user-prompt-framing.md` (the actor cannot externally enforce on itself, but the rule + audit + visibility close the loop).

The harder problem is the post-edit validator scoping. The validator fires on `Edit`/`Write`/`MultiEdit` from a sub-agent, but the worktree path is only known after `Agent` tool creates it. Two compatible mechanisms:

1. **Gate stamps state at dispatch:** when `ISOLATION: worktree` is parsed, the gate creates `.claude/.delegation-state/agents/<agent_id>/isolation = "worktree"` and `worktree_path = ""` (placeholder).
2. **Validator probes for worktree:** the post-edit validator, when running for a sub-agent's edit, checks the per-agent state file. If `isolation = worktree`, it derives the worktree path from the edit's file argument (which is an absolute path — the worktree root is its containing git toplevel via `git rev-parse --show-toplevel`).

This avoids needing the gate to know the worktree path ahead of time. The validator simply `cd`s into whatever git toplevel the edit happened in, which IS the worktree if the sub-agent operated there.

Order of operations:

1. **Empirical pre-flight: verify the parallel-Agent worktree pattern.** Construct a test scenario where parent dispatches two `Agent` calls in parallel with `isolation: "worktree"` set in each. Inspect: (a) does each get its own worktree path? (b) does the worktree auto-cleanup work when no changes? (c) does the post-edit hook see the sub-agent edits with worktree-rooted absolute paths? Findings inform whether the validator-probe mechanism is sufficient.
2. **Hook parser extension.** Extend `delegation-gate.sh` field parser to recognize `ISOLATION:` (case-insensitive). Validate value against allowed set `{worktree}`. Empty/missing = null. Unknown value = block with corrective stderr.
3. **Audit schema extension.** Add `isolation` field to the audit row JSON. Update `.claude/rules/delegation.md` § Audit log.
4. **State file.** When `ISOLATION` is set, gate writes `.claude/.delegation-state/agents/<agent_id>/isolation`.
5. **Validator scoping.** Modify `post-edit-validate.sh` to `cd` into the edit's containing git toplevel before invoking the validator runner. This is safe regardless of isolation (parent's toplevel = current cwd; worktree's toplevel = the worktree dir).
6. **Rule update.** Document the new field in `.claude/rules/delegation.md` with use-case examples (parallel dispatch).
7. **Tests** for the 7 spec scenarios.

## Files to touch

**Create:**
- `.claude/tests/<NNN>-isolation/run.sh` — orchestrator + fixtures
- `.claude/tests/<NNN>-isolation/fixtures/*.txt` — brief samples (ok, typo, empty, etc.)

**Modify:**
- `.claude/hooks/delegation-gate.sh` — add ISOLATION parsing + validation; audit field
- `.claude/hooks/post-edit-validate.sh` — `cd` to edit's git toplevel before validator
- `.claude/rules/delegation.md` — § The 5-field handoff: document 6th optional field; § Audit log: list new field

**Delete:** none

## Alternatives considered

### Gate rewrites the `Agent` tool call payload to inject `isolation: "worktree"`

Rejected — hooks return stderr or exit codes; they do not have a sanctioned mutation API for tool-call payloads. Claude Code's hook surface (per `cc-platform-hooks.md` memory) doesn't expose payload mutation pre-dispatch. Documented in Open Question #1.

### Use a separate field name like `WORKTREE: true` instead of `ISOLATION: worktree`

Rejected — `ISOLATION` is a forward-compatible namespace; v2 might add `ISOLATION: docker` or `ISOLATION: process`. `WORKTREE: true/false` binds the field to one mechanism, paying namespace cost when expansion arrives.

### Auto-set `ISOLATION: worktree` whenever the gate detects parallel dispatches (heuristic detection)

Rejected for v1 — overreach. The parent might dispatch parallel calls deliberately on non-overlapping files (e.g. independent module rewrites). Heuristic detection adds friction without confidence the collision is real. Wait for rule-of-three drift evidence before opt-out → opt-in flip.

### Skip the field entirely; rely on Claude Code's `Agent` tool description to nudge parent

Rejected because the tool description is generic; Agent0's discipline is project-specific. Without a brief field, there's no audit surface to ask "did we use isolation for that risky parallel dispatch?". The audit value alone justifies the field.

## Risks and unknowns

- **Risk: parent declares ISOLATION but forgets to set the `Agent` tool parameter.** Audit will record `isolation: "worktree"` while the actual dispatch ran without isolation, creating an audit/reality mismatch. Mitigation: rule-only documentation now; future hook surface (per Open Question #1) may enable enforcement.
- **Risk: validator-probe via git toplevel breaks on non-git contexts.** If a sub-agent edits a file outside a git repo, `git rev-parse --show-toplevel` fails. Mitigation: fail-open — if toplevel resolution errors, run validator in parent cwd (status quo).
- **Risk: worktree auto-cleanup races with validator execution.** If the `Agent` tool auto-cleans the worktree (no changes made) before the post-edit hook fires for the last edit, the `cd` fails. Mitigation: the `Agent` tool's documented contract is "cleanup if no changes" — edits-then-cleanup implies changes happened, so cleanup wouldn't fire. Verify in pre-flight (step 1).
- **Risk: test environment doesn't support git worktree.** Some CI sandboxes restrict git operations. Mitigation: tests assert on parsing + audit shape (no live worktree); a separate manual scenario verifies end-to-end on the developer's machine.
- **Unknown: does the `Agent` tool emit a hook event (e.g. `WorktreeCreate`) when it creates the temporary worktree?** If yes, that's a cleaner state-stamp surface than the validator-probe. Resolution: scan Claude Code's hook event list for worktree-specific events (`.claude/memory/cc-platform-hooks.md`).

## Research / citations

- Claude Code worktrees: https://code.claude.com/docs/en/worktrees
- `Agent` tool description (system prompt) — declares `isolation: "worktree"` parameter
- Internal: `.claude/rules/delegation.md` § The 5-field handoff (the discipline being extended)
- Internal: `.claude/memory/cc-platform-hooks.md` (if it documents worktree hook events; verify in tasks step 1)
- Spec 002 (delegation gate design) for the field-parsing pattern; spec 014 (gate hardening) for case-insensitive parsing semantics
