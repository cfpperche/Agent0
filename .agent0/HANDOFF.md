# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects and enforces this file through hooks; Codex can do the same after the `.codex/config.toml.example` Agent0 hook blocks are enabled.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Multi-runtime hook migration — `.claude/hooks/*` → `.agent0/` hook-by-hook.** Specs 106-111 ALL shipped+merged+pushed. **111 delegation-verify-subagent-stop is fully closed** — live-dogfooded on BOTH runtimes, README updated. Working tree clean except pre-existing untracked `docs/specs/091-sdd-debate-runner/` (out of scope).

- 111 replaced per-edit `post-edit-validate.sh` with `.agent0/hooks/delegation-verify.sh` on `SubagentStop` (runtime-neutral, keyed by `agent_id`; block → one continuation → partial-result via `stop_hook_active`). 8 verifier scenarios + `061-delegation-stop` green.
- Live proof both runtimes (rows in `docs/specs/111-*/notes.md`): Claude pass (`acb46fdc…`, parallel with the close row); Codex blocked→exhausted (`019e741e…`, `stop_hook_active` false→true, no loop). Both OQs resolved by evidence. Design pivot: SubagentStop hooks run in PARALLEL → counter-contract, not a sentinel.

## Active Work

- _None in flight._ The full 106-111 migration arc is committed and pushed; nothing uncommitted except the out-of-scope untracked `091` dir.

## Next Actions

1. **Continue the hook migration (next session).** Remaining `.claude/hooks/*` to port to runtime-neutral `.agent0/`: the PostToolUse(Edit) edit-surface advisories (`propagation-advise.sh`, `supply-chain-advise.sh`, `secrets-advise.sh` — share the `apply_patch` path-extraction already in `_memory-hook-lib.sh`) and the runtime-introspect pair (`runtime-capture.sh` / `runtime-pre-mark.sh`). Apply the proven 106-111 pattern: bare/standard matcher, `_memory-hook-lib.sh` sourcing, runtime-tagged output, and a **live both-runtime dogfood via real audit rows before flipping shipped** (the session's hard-won lesson: check the live state, don't assume cold-restart-gating).
2. Leave `docs/specs/091-sdd-debate-runner/` untouched unless explicitly resumed.

## Decisions & Gotchas

- **Artifact proof beats test assumptions:** hook-registration work is not shipped unless real runtime audit rows prove the hook fired. Tests can pass while a registration is dormant.
- **Codex trust gate:** project `.codex/config.toml` hook changes require a cold Codex start and trust approval. Spec 111 trust landed for `subagent_stop:0:0` (verify) and `subagent_stop:1:0` (stop).
- **Codex TUI vs `codex exec`:** in 0.135.0, `codex exec` probes emitted `subagent-start` rows only; real `SubagentStop` + `subagent-verify` rows came from the TUI surface (`codex --no-alt-screen ...`).
- **111 design pivot:** SubagentStop hooks run in parallel, so sentinel/close-row suppression is invalid. `delegation-verify.sh` writes `consecutive_failures`; unchanged `delegation-stop.sh` reads it for close-row `exit`; escalation keys on `stop_hook_active`.
- **Existing gotchas still apply:** launcher-wrapped Bash commands (`/bin/bash -lc`), cold-restart requirements for settings reloads, hook-move path cascades, and governance hooks blocking broad inline shell strings.
