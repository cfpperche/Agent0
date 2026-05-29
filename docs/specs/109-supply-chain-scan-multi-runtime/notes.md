# 109 — supply-chain-scan-multi-runtime — notes

_In-flight design memory for this spec. Append-only by convention._

## Design decisions

### 2026-05-28 — parent — bare matcher over 11 `if` handlers (Q1 resolved against research)

The official CC hooks docs confirmed a *valid* Claude-only way to scope the hook to package managers: one `if: "Bash(<prefix>)"` handler per manager (11 entries) — _"to apply multiple conditions, define a separate hook handler for each"_; pipe-alternation in a single `Bash(a|b|c)` is invalid (the dormant-bug root cause). Rejected the 11-handler route because Codex has no `if` layer (matches the tool-name regex `^Bash$` only), so the script must self-filter for Codex regardless. Eleven Claude handlers would create a two-mechanism runtime divergence + maintenance load. Chose the bare `"matcher": "Bash"` + in-script self-filter, identical on both runtimes — the same shape 108 set for secrets-preflight. This made the research (per the verify-runtime-capabilities discipline) the decisive input, and confirmed no debate was warranted (Q5).

### 2026-05-28 — parent — supply-chain-advise.sh audit-path repointed, NOT ported

The advise companion (PostToolUse Edit/Write, explicitly a non-goal to port) ALSO writes audit rows. Moving the preflight's log to `.agent0/` while leaving advise writing to `.claude/` would split the log into two files. Resolved by repointing ONLY advise's `AUDIT_LOG` constant (one-line edit) + its stale comment refs — a consequence of the hard-cutover, distinct from the deferred runtime-neutral port (apply_patch path-extraction + `.agent0/` move stay out of scope). Surfaced during plan.md drafting, not pre-empted by the spec.

### 2026-05-28 — parent — no runtime-aware output (unlike 108)

108 needed `permissionDecision:"allow"` + `updatedInput` on Codex because it rewrites the command (env-var bridge). 109 has no rewrite path and no downstream bridge (the rule states it explicitly), so block is plain exit-2 + stderr — runtime-neutral (107 proved it). `memory_runtime` is used ONLY to tag the audit `runtime` field, never to branch stdout. This made 109 materially simpler than 108.

## Deviations

_None — implementation followed plan.md._

## Tradeoffs

### 2026-05-28 — parent — dropped `skip-not-install` audit row (Q2, user-confirmed)

Under the bare matcher the hook runs on every Bash; keeping the forensic `skip-not-install` row would write a JSONL line per `ls`/`cat`/`git status` — an unbounded firehose. Dropped it (silent no-row on non-detection), mirroring 108's `skip-not-commit` drop. Cost given up: the "proof the hook ran on every command" forensic signal. Worth it: the audit log now records dep-install-shaped invocations only, and the hook's reach is verifiable via the perf harness / live dogfood instead. Edited tests 02 (rewritten to assert silent-no-row) and 13 (sub-cases b/c).

## Open questions

### 2026-05-28 — parent — Claude live dogfood PASSED (task 22 closed)

Post-cold-restart session: the bare `"matcher": "Bash"` registration is now live and the real `PreToolUse(Bash)` hook fired through the Bash tool (not direct invocation — the only proof that survives the 108 dormant-`if` lesson).

- **Block test** — `cargo add tokio` (cwd = Agent0 repo) → tool DENIED with the `supply-chain-block:` corrective template. Audit row:
  ```json
  {"ts":"2026-05-28T23:33:52Z","decision":"block","scope":"bash","runtime":"claude-code","manager":"cargo","action":"add","packages":["tokio"],"override_reason":null}
  ```
- **Override test** — two-line form in `/tmp` (`cargo add tokio` + `# OVERRIDE: live 109 dogfood of the override pass-through`) → passed the gate; cargo then errored harmlessly (exit 101, no `Cargo.toml` in `/tmp`). Audit row:
  ```json
  {"ts":"2026-05-28T23:34:07Z","decision":"block-override","scope":"bash","runtime":"claude-code","manager":"cargo","action":"add","packages":["tokio"],"override_reason":"live 109 dogfood of the override pass-through"}
  ```

Both rows carry `runtime:"claude-code"` (resolved via `CLAUDE_PROJECT_DIR`). Task 22 green. Task 23 was later closed by the Codex CLI live dogfood entry below.

### 2026-05-28 — parent — pre-live verification snapshot

Before the live-fire rows landed, the in-session/synthetic coverage was:

- **Verified now:** moved hook blocks `npm install` / `pip install` / `cargo add` (exit 2) with correct `runtime` tag (claude-code via `CLAUDE_PROJECT_DIR`, codex-cli via `cwd`-only synthetic payload); `ls` and bare-install-without-dirty-manifest exit silently with no audit row; all 19 tests green (13 supply-chain + 4 composer + baseline + harness-sync-05); settings.json has the bare matcher with no `if`; grep-clean of stale hook-path refs (only intentional "moved from" breadcrumbs + spec-dir names remain).
- **Later live-fire closure:** Claude block+override rows are recorded above; Codex block+override rows are recorded below.

### 2026-05-28 — Codex CLI live dogfood passed (task 23)

Codex setup required two runtime-real steps that synthetic tests did not cover:

- Added the real `.codex/config.toml` `[[hooks.PreToolUse]] matcher = "^Bash$"` block after `secrets-preflight.sh`.
- Cold-started Codex; the TUI reported `1 hook is new or changed`, so the new `pre_tool_use:3:0` handler had to be trusted before it would run.
- First live `codex exec` attempt executed `pip` instead of blocking because Codex's local shell surfaced the command as `/bin/bash -lc 'pip install requests'`; fixed by unwrapping common `bash/sh -c/-lc` launchers before the supply-chain tokenizer. Regression coverage: `07-tokenizer-shape.sh` (wrapper detection) + `09-block-override-valid.sh` (wrapper + two-line override).

Live audit rows used as acceptance evidence:

```json
{"ts":"2026-05-28T23:46:10Z","session_id":"019e70fb-06a7-7733-a0a3-f09d53d88406","agent_id":null,"decision":"block","scope":"bash","runtime":"codex-cli","manager":"pip","action":"install","packages":["requests"],"override_reason":null}
{"ts":"2026-05-28T23:47:19Z","session_id":"019e70fc-0a88-7431-894a-9e141e78dbd6","agent_id":null,"decision":"block-override","scope":"bash","runtime":"codex-cli","manager":"pip","action":"install","packages":["requests"],"override_reason":"live 109 codex dogfood of the override pass-through"}
```
