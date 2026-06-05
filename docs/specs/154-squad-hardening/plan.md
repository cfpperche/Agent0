# 154 — squad-hardening — plan

_Drafted from `spec.md` on 2026-06-05._

## Approach

Three independent, small fixes at their root, each with a regression test. They don't interact, so order is by blast radius: (1) the one-line template pattern, (2) the two-line bridge env fix + a behavioral test, (3) the new `squad.sh resume` subcommand reusing the existing `_fingerprint` machinery. Then doc updates. TDD where it fits — write the failing assert, make it green.

### Resolved open questions (plan time)

- **OQ1 — `resume` safety:** the `forbidden_paths` re-check (refuse unless `--force`) is sufficient for v1. The orchestrator is a trusted operator (same trust level as `rollback`, which already does destructive `git clean`). No clean-superset check.
- **OQ2 — suppress scope:** set `CLAUDE_SKIP_SESSION_HOOKS=1` **unconditionally** in both bridges. A read-only probe equally should not nag about the handoff — any bridge subprocess is bounded and non-handoff-owning.

## Files to touch

**Modify:**
- `.agent0/skills/squad/references/squad.json.example` — replace `"secrets"` in `forbidden_paths` with `"(^|/)secrets?/"` + `"\\.secrets?(\\.[^/]+)?$"`. (Fix #1)
- `.agent0/skills/codex-exec/scripts/codex-exec.sh` — export `CLAUDE_SKIP_SESSION_HOOKS=1` into the `codex exec` subprocess env. (Fix #2)
- `.agent0/skills/claude-exec/scripts/claude-exec.sh` — same, for the `claude -p`/`claude exec` subprocess env. (Fix #2, symmetric)
- `.agent0/skills/squad/scripts/squad.sh` — add `cmd_resume()` + dispatch case `resume)`; re-baseline `boundary` to the current `_fingerprint`, set `status=running`, `turn_open=false`; refuse (unless `--force`) if the current changed-set still hits a `forbidden_paths` pattern. (Fix #3)
- `.agent0/skills/squad/references/squad-contract.md` — document the anchored `secrets` guidance + the `resume` primitive (recovery vs the destructive `rollback`).
- `.agent0/context/rules/squad.md` — one line: bridge peer turns suppress the session-handoff Stop-nag (so the peer never touches the orchestrator-owned HANDOFF); `resume` for non-destructive abort recovery.

**Create (tests):**
- `.agent0/tests/squad/NN-secrets-pattern.sh` — the example's anchored `secrets` patterns DON'T match `secrets-scan.md` but DO match `secrets/foo` + `app.secrets`.
- `.agent0/tests/squad/NN-bridge-suppresses-handoff-nag.sh` — (a) the bridges export `CLAUDE_SKIP_SESSION_HOOKS=1`; (b) behavioral: `CLAUDE_SKIP_SESSION_HOOKS=1 session-stop.sh` exits 0 / emits no `block` against a dirty tree + stale handoff.
- `.agent0/tests/squad/NN-resume-recovers.sh` — an `aborted_conflict` run + a benign tree change → `resume` → `status:running`, tree intact, next `guard` clean; AND a genuine forbidden-path change → `resume` refuses without `--force`, succeeds with it.

_(If `.agent0/tests/squad/` already has a runner, follow its numbering + glob; else create `run-all.sh` mirroring `tests/agent-browser/run-all.sh`.)_

## Alternatives considered

### Make `session-stop.sh` squad-aware (branch inside the hook)
Rejected: less general + couples the hook to squad internals. The real invariant is "a bounded bridge subprocess is never the handoff-owning session" — that's true for meeting/probe bridge turns too, so the suppression belongs at the bridge, not in a squad-specific hook branch.

### Make `resume` an alias that re-runs `turn-start`+`turn-end` (the hand-rolled hack)
Rejected: that advances the round counter and flips the holder as a side effect (semantically wrong for a recovery), and embeds the workaround instead of a real primitive. A dedicated `cmd_resume` that re-baselines in place is clean.

### Auto-revert HANDOFF in the squad pump instead of suppressing the nag
Rejected: treats the symptom. If the peer never gets nagged, it never writes HANDOFF, so there's nothing to revert — fix the cause.

## Risks and unknowns

- **`resume` as a policy-bypass.** Mitigated by the forbidden re-check + explicit `--force`. Documented as a trusted-orchestrator primitive (parity with `rollback`).
- **Suppressing the handoff nag too broadly.** `CLAUDE_SKIP_SESSION_HOOKS` already exists as the sanctioned escape hatch; bridges setting it for their child only (not the parent session) is correctly scoped — the parent orchestrator session still gets nagged normally.
- **`.agent0/tests/squad/` may not exist yet.** If absent, scaffold a minimal runner; keep it consistent with the agent-browser suite shape so it's familiar.

## Research / citations

- Live run that surfaced all three: spec 153 squad (`.agent0/HANDOFF.md` § Decisions & Gotchas records the recovery procedures verbatim).
- Verified anchors this session: `squad.json.example:16`, `session-stop.sh:13/51`, `.claude/settings.json:29`, `.codex/hooks.json:31`, `squad.sh` (`cmd_rollback`, `_fingerprint`, `cmd_turn_end`, `cmd_guard`).
