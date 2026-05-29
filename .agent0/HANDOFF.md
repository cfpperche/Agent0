# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects and enforces this file through hooks; Codex can do the same after the `.codex/config.toml.example` Agent0 hook blocks are enabled.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Multi-runtime hook migration:** specs 106-110 shipped+merged. **111 delegation-verify-subagent-stop shipped+merged** (`444bf70`) and now live-dogfooded on both Claude and Codex. The user asked whether the dogfood fully passed; answer given: yes for the requested Codex CLI scenario, with the caveat that the valid proof came from Codex TUI, not `codex exec`.

- 111 replaced `post-edit-validate.sh` with `.agent0/hooks/delegation-verify.sh` on `SubagentStop`, keyed by `agent_id`. Test suite was green before this session: 8 verifier scenarios + `061-delegation-stop`.
- Claude live proof: real `Agent` dispatch `acb46fdc0a91cab59` produced `decision:"pass"` in `.agent0/delegation-audit.jsonl`; SubagentStop hooks fire in parallel.
- Codex live proof: Codex TUI `codex-cli 0.135.0`, real `.codex/config.toml` SubagentStop verify block enabled/trusted, temporary failing `package.json` used and then removed. Canonical `subagent-verify` rows are recorded in `docs/specs/111-delegation-verify-subagent-stop/notes.md`.
- Codex rows: blocked at `2026-05-29T14:23:42Z`, then exhausted at `2026-05-29T14:23:55Z`, both with `agent_id:"019e741e-4344-7b93-b782-a1f10484e1da"`. `stop_hook_active` flipped `false -> true`, proving no infinite stop loop.

## Active Work

- _None in flight._ 111 evidence is captured; no Codex TUI sessions are left running; the temporary failing `package.json` was removed.
- Working tree remains intentionally uncommitted: `.agent0/HANDOFF.md` and `docs/specs/111-delegation-verify-subagent-stop/notes.md` modified; pre-existing untracked `docs/specs/091-sdd-debate-runner/` is out of scope.

## Next Actions

1. Review/commit the 111 evidence docs if desired: `docs/specs/111-delegation-verify-subagent-stop/notes.md` and `.agent0/HANDOFF.md`.
2. Leave `docs/specs/091-sdd-debate-runner/` alone unless the user explicitly resumes that work.
3. Next migration candidates: PostToolUse edit-surface advisories (`propagation-advise`, `supply-chain-advise`, `secrets-advise`, `apply_patch` path extraction) plus `runtime-capture.sh` / `runtime-pre-mark.sh`.

## Decisions & Gotchas

- **Artifact proof beats test assumptions:** hook-registration work is not shipped unless real runtime audit rows prove the hook fired. Tests can pass while a registration is dormant.
- **Codex trust gate:** project `.codex/config.toml` hook changes require a cold Codex start and trust approval. Spec 111 trust landed for `subagent_stop:0:0` (verify) and `subagent_stop:1:0` (stop).
- **Codex TUI vs `codex exec`:** in 0.135.0, `codex exec` probes emitted `subagent-start` rows only; real `SubagentStop` + `subagent-verify` rows came from the TUI surface (`codex --no-alt-screen ...`).
- **111 design pivot:** SubagentStop hooks run in parallel, so sentinel/close-row suppression is invalid. `delegation-verify.sh` writes `consecutive_failures`; unchanged `delegation-stop.sh` reads it for close-row `exit`; escalation keys on `stop_hook_active`.
- **Existing gotchas still apply:** launcher-wrapped Bash commands (`/bin/bash -lc`), cold-restart requirements for settings reloads, hook-move path cascades, and governance hooks blocking broad inline shell strings.
