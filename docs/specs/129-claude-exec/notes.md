# 129 — claude-exec — notes

_Created 2026-05-30._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building**._

## Design decisions

### 2026-05-31 — parent — Prompt always via stdin (variadic flags swallow positional args)

The single most important divergence from a naive port. `claude --allowedTools <tools...>` and `--add-dir <dirs...>` are greedy/variadic: passing the prompt as a positional arg makes it vanish (`Error: Input must be provided either through stdin or as a prompt argument`). Confirmed empirically during implementation. The helper always pipes the prompt via stdin (`"${cmd[@]}" < "$prompt_file"`), matching codex-exec's stdin approach for an unrelated reason here (greedy flags, not subcommand shape).

### 2026-05-31 — parent — Unified jq filter for both output formats

Claude has no `--output-last-message` (Codex does), so the final message is extracted from JSON. Verified live: `--output-format json` emits one `type:"result"` object; `--output-format stream-json --verbose` emits JSONL whose final `type=="result"` line carries the same fields. One filter works for both: `select(.type=="result")|.result` (message) and `|.session_id` (capture for `--resume`). `jq` is therefore a hard dependency, checked up front; `stream-json` additionally requires `--verbose` in `-p` mode (helper adds it automatically under `--json`).

### 2026-05-31 — parent — Pass-through over abstraction (resolved OQ1)

`claude-exec` is a sibling of codex-exec in purpose, not a clone in code. `--permission-mode` is required, fail-closed, forwarded verbatim (no `read-only/write/danger` mapping table that would drift as Claude's mode set evolves). Read-only review is composed by the caller via the opt-in `--allowedTools "Read Grep Glob"`. Other resolutions: no launcher (invoke `claude` directly); `--bare` opt-in not default (reviews need project context; `--bare` forces `ANTHROPIC_API_KEY` auth); `allow_implicit_invocation: true` (safe because fail-closed refuses vague triggers before any paid run).

## Deviations

_(none — implementation matched plan.md.)_

## Tradeoffs

### 2026-05-31 — parent — Metadata schema diverges from codex-exec by design

Gains `permission_mode`, `allowed_tools`, `disallowed_tools`, `add_dir`, `bare`, `session_id`; loses `sandbox`, `profile`, `cwd`. Dropped `--profile` (no clean Claude 1:1 in v1) and `--cwd`/`--cd` (replaced by `--add-dir` grant-access semantics — not a working-root switch). Accepted cost: the two skills' run logs are not field-identical, which is correct — they bridge to different brains.

## Design decisions (cont.)

### 2026-05-31 — parent — Floor gate (--allow-writes) added after Codex dogfood

The Codex-side dogfood (the goal deliverable) ran clean on all three mechanical tests but surfaced a real contract gap: the spec promised "read-only/critique stays the floor," yet pure pass-through accepted write/execute-capable modes (`acceptEdits`, `bypassPermissions`, `dontAsk`, `auto`) with no gate — `auto`/`dontAsk` especially don't *look* like write modes. The floor was caller discipline, not a bridge invariant. User chose to harden (over relaxing the spec). Added `--allow-writes`: write-capable modes are refused fail-closed without it; `default`/`plan` pass as the floor. The gate is **orthogonal to pass-through** — the native mode value is still forwarded verbatim, so this is not the permission abstraction we rejected in OQ1. Verified: 50/50 tests (was 38), live gate refuses `acceptEdits` without confirmation. This is the bidirectional-dogfood loop working as designed — Claude critiquing the bridge Claude runs on.

## Open questions

### 2026-05-31 — parent — Minor v1 limits

`--add-dir` is single-value in v1 though Claude accepts multiple; widen if needed. The floor gate's write-capable set is hardcoded ({acceptEdits, bypassPermissions, dontAsk, auto}); if Claude adds a new write-capable mode it must be added here too (acceptable — same maintenance the native validation list already needs).
