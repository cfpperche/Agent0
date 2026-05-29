# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects and enforces this file through hooks; Codex can do the same after the `.codex/config.toml.example` Agent0 hook blocks are enabled.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Multi-runtime hook migration — porting `.claude/hooks/*` to `.agent0/` hook-by-hook.** 106 delegation + 107 governance + 108 secrets-preflight + 109 supply-chain-preflight ALL SHIPPED + merged. **110 post-edit-validate-multi-runtime SHIPPED (research/decision spec)** — resolved via Claude↔Codex `/sdd debate` + human override; **111 delegation-verify-subagent-stop scaffolded (`draft`)** as the implementation spec. Working tree clean except pre-existing untracked `docs/specs/091-sdd-debate-runner/` (out of scope).

- **110 decision (the key outcome):** the per-edit `post-edit-validate.sh` is to be **deleted entirely**, NOT ported. Codex `PostToolUse(apply_patch)` carries no parent-vs-subagent discriminator (verified at developers.openai.com/codex/hooks — `agent_id`/`agent_type` only on Subagent events), so a per-edit port is non-viable. The debate recommended a two-hook split; the human overrode to **full removal** → one runtime-neutral `delegation-verify.sh` at `SubagentStop`. Mid-flight thrash detection consciously given up for zero per-edit suite cost. Full rationale in `docs/specs/110-*/debate.md`.

## Active Work

- _None in flight._ 110 closed; 111 is the next build, queued for a fresh focused session.

## Next Actions

1. **Implement spec 111 (`delegation-verify-subagent-stop`)** in a fresh focused session — it's substantial + risk-tailed (new `SubagentStop` hook on both runtimes + removal cascade + live Codex dogfood). Run `/sdd plan` then `/sdd tasks` on `docs/specs/111-*` first. Scope (from 110 § Follow-up path): add `.agent0/hooks/delegation-verify.sh` (SubagentStop, both runtimes, `agent_id`-keyed, block→one-continuation→partial-result, verify-before-close-row ordering); delete `post-edit-validate.sh` + its `PostToolUse(Edit\|Write\|MultiEdit)` registration; relocate the `tdd-advisory:` surfacing into the new hook; rewrite `delegation.md` § Post-edit validator loop. **Resolve 111's OQs by live dogfood, not assumption:** does a continued sub-agent preserve its `agent_id`, and how does `stop_hook_active` behave across a validation-blocked stop (108/109 lesson — both-runtime live fire before shipped).
2. After 111: remaining migration surfaces — PostToolUse edit-surface advisories (`propagation-advise` / `supply-chain-advise` / `secrets-advise`, `apply_patch` path extraction) + `runtime-capture.sh` / `runtime-pre-mark.sh`.

## Decisions & Gotchas

- **Tests pass even while a registration is dormant** — none exercise CC's `if`/matcher dispatch. Only a real PreToolUse fire (post-cold-restart) proves a hook-registration spec; 109 is marked shipped only because both live rows are now recorded. (CC `if` pipe-alternation invalidity + the bare-matcher fix are fully in `.claude/rules/supply-chain.md` § What fires and `.agent0/memory/hook-chain-maintenance.md`.)
- **Codex hook trust is a separate runtime gate** — after editing project `.codex/config.toml`, a cold Codex start showed `1 hook is new or changed`; until trusted, the new project hook did not run. Trust state landed in `~/.codex/config.toml` for `/home/goat/Agent0/.codex/config.toml:pre_tool_use:3:0`.
- **Codex shell launcher wrapper matters** — real `codex exec` surfaced commands as `/bin/bash -lc '<cmd>'`; the supply-chain tokenizer now unwraps common `bash/sh -c/-lc` launchers before looking for manager+verb.
- **`/resume` and `/clear` do NOT reload settings.json hooks** — only a COLD `claude` restart does. The git-mv'd 109 hook did not break the pre-restart session because the old dormant `if` never fired anyway.
- **Hook-move cascade:** a rename breaks hardcoded paths AND the filename-keyed perf harness (`bench-hooks.sh`, `.perf-baseline.json`, latency test). ALWAYS `grep -rn '<oldname>'` after a move.
- **Gates block your own tooling:** feed `--no-verify` / `rm -r` via a file or split calls, never a multi-line inline Bash (governance scans the whole string); `git commit -F`. `091-sdd-debate-runner` is pre-existing untracked, out of scope.
