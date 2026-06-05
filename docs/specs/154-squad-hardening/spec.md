# 154 — squad-hardening

_Created 2026-06-05._

**Status:** shipped

## Intent

The first real multi-turn `/squad` run (spec 153, Claude↔Codex, 8 rounds) surfaced three concrete defects in the spec-150 squad machinery — each one cost real friction and each will recur on **every** future squad run, so they are load-bearing, not speculative. (1) The default `squad.json.example` `forbidden_paths` entry `"secrets"` is an unanchored substring that false-matches any path containing the word — e.g. editing `secrets-scan.md` aborts the run `aborted_policy`. (2) The session-handoff Stop hook (`session-stop.sh`, wired for both runtimes) fires at the end of every `codex exec` / `claude exec` peer turn, blocks, and makes the peer rewrite `.agent0/HANDOFF.md` — which is the orchestrator-owned, `forbidden_paths` file — forcing the orchestrator to revert + re-baseline every single turn. (3) There is no non-destructive recovery from an `aborted_*` state: `squad.sh rollback` does `git checkout -- . && git clean -fdq` (destroys all uncommitted work), and there is no `resume`/`rebaseline`, so recovering from a false-positive abort requires a hand-rolled no-op turn. This spec fixes all three at their root so `/squad` runs cleanly without orchestrator babysitting.

## Acceptance criteria

- [ ] **Scenario: a `secrets`-named doc no longer false-trips the policy gate**
  - **Given** the `squad.json.example` template's `forbidden_paths`
  - **When** a squad turn changes a path like `.agent0/context/rules/secrets-scan.md`
  - **Then** the guard does NOT abort — the secrets pattern is anchored (`(^|/)secrets?/` for a secrets *directory* and `\.secrets?(\.[^/]+)?$` for a `.secret`/`.secrets` *file*), so it still catches real secret paths (`secrets/foo`, `app.secrets`) but not `secrets-scan.md`

- [ ] **Scenario: a bridge peer turn does not fire the handoff Stop-hook nag**
  - **Given** the `codex-exec` / `claude-exec` bridge invoking a bounded subprocess
  - **When** the subprocess ends with uncommitted changes and an un-updated `HANDOFF.md`
  - **Then** `session-stop.sh` is suppressed (the bridge sets `CLAUDE_SKIP_SESSION_HOOKS=1` in the subprocess env) — the peer never rewrites `HANDOFF.md`, because a bounded bridge subprocess is not a handoff-owning session

- [ ] **Scenario: `session-stop.sh` honors the skip env (already half-built, now load-bearing)**
  - **Given** `CLAUDE_SKIP_SESSION_HOOKS=1` in the environment
  - **When** `session-stop.sh` runs against a repo with uncommitted changes + stale handoff
  - **Then** it exits 0 with no `block` decision (this is the existing escape hatch; the bridges now set it)

- [ ] **Scenario: non-destructive recovery from a false-positive abort**
  - **Given** a `/squad` run in an `aborted_policy` / `aborted_conflict` state whose cause has been reconciled (e.g. the contract was corrected, or an out-of-band edit was reverted)
  - **When** the orchestrator runs `squad.sh resume --run <run>`
  - **Then** the run returns to `status: running` with `boundary` re-baselined to the current working tree (empty delta), **without** discarding any uncommitted work, and the next `guard` is clean

- [ ] **Scenario: `resume` cannot silently launder a genuine forbidden-path change**
  - **Given** the current tree genuinely touches a `forbidden_paths` path (a real policy violation, not a false positive)
  - **When** `squad.sh resume --run <run>` is invoked without `--force`
  - **Then** it refuses (prints the offending path, leaves status aborted) — resume is a recovery primitive for reconciled/false-positive aborts, not a policy bypass; `--force` is the explicit override

- [ ] The squad-contract reference doc (`references/squad-contract.md`) documents the anchored `secrets` pattern guidance and the `resume` recovery primitive; `rules/squad.md` notes the bridge-suppresses-handoff-nag interaction
- [ ] A regression test exists for each fix and the existing squad test suite stays green

## Non-goals

- **Reworking the single-writer / turn-lock model** — the `aborted_conflict` enforcement is correct; this spec adds a *recovery path*, it does not loosen the invariant.
- **Auto-updating `HANDOFF.md` from inside the squad** — the orchestrator still owns the handoff; we only stop the *peer* from being nagged into writing it.
- **Making `session-stop.sh` squad-aware** — the fix is at the bridge (suppress for any bounded subprocess), not a squad-specific branch inside the hook. Generality is the point: meeting/probe bridge turns also shouldn't nag.
- **Retroactively fixing the spec-153 `squad.json`** — it already uses the anchored pattern; this spec fixes the shared *template* so future specs inherit it.

## Open questions

- [ ] **`resume` safety surface** — is the `forbidden_paths` re-check on resume (refuse unless `--force`) sufficient, or should it also verify the tree is a clean superset of the last good boundary? (Lean: the forbidden re-check is enough for v1; the orchestrator is trusted, same as `rollback`.) Owner: plan time.
- [ ] **Suppress scope** — set `CLAUDE_SKIP_SESSION_HOOKS=1` in the bridges unconditionally, or only for non-read-only sandboxes? (Lean: unconditional — a read-only probe equally shouldn't nag about the handoff.) Owner: plan time.

## Context / references

- **Motivating run:** spec 153 `/squad` (`.agent0/.runtime-state/squads/153-decouple-harness-from-playwright-*`), 8 rounds — hit all three issues live; recovery procedures are recorded in `.agent0/HANDOFF.md` § Decisions & Gotchas.
- **Root-cause anchors:** `squad.json.example:16` (`"secrets"`); `session-stop.sh:13` (the `CLAUDE_SKIP_SESSION_HOOKS` escape hatch) + `:51` (the block decision); `.claude/settings.json:29` + `.codex/hooks.json:31` (the hook is wired for both runtimes); `squad.sh cmd_rollback` (destructive) + `_fingerprint`/`cmd_turn_end` (the boundary mechanism `resume` reuses).
- **Predecessor:** spec 150 `squad` (the capacity being hardened); spec 153 (the run that surfaced these).
- **Interacting rule:** `.agent0/context/rules/session-handoff.md` (the nag this spec suppresses for bridge subprocesses).
