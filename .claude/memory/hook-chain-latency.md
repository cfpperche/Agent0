---
name: hook-chain-latency
description: PreToolUse(Bash) chain latency budget + bench tooling for maintainers extending the hook chain.
metadata:
  type: reference
  created_at: 2026-05-27T00:00:00Z
---

# Hook chain latency

The `PreToolUse(Bash)` hook chain sits on the critical path of every Bash tool call the agent makes; cost there is user-perceived as "slow agent". This entry documents the latency budget the chain meets, the bench tool that measures it, and how to interpret a regression report.

This entry pairs with `.claude/memory/hook-chain-maintenance.md` (the upstream-maintainer discipline — optimization techniques + the contract for adding a new `PreToolUse(Bash)` hook). Neither file ships to consumer projects; both bind the upstream maintainer who edits any of the four registered hooks.

## Scope

In-scope:

- `PreToolUse(Bash)` hooks registered in `.claude/settings.json` — `governance-gate.sh`, `secrets-scan.sh`, `supply-chain-scan.sh`, `runtime-pre-mark.sh` at time of writing.
- The full chain's wall-clock p95 against a representative command set.

Out-of-scope:

- `PostToolUse` / `PostToolUseFailure` hooks. Different chain, different perf profile, no user-perceptible-on-next-prompt cost.
- The native `.githooks/pre-commit` (gitleaks). Empirically ~33 ms; not the bottleneck.
- Claude Code's harness IPC. Out of our hands.
- `Edit|Write|MultiEdit` hook chain. If it surfaces as slow, scope a separate spec.

## Budget

**p95 ≤ 80 ms for fast-path Bash commands** (no-op, `ls`, `cat`, `echo`, `git status`, `git log`, `grep`).

Fast-path is defined as: a Bash command none of the four gates have a real reason to scrutinize. Under the current `if`-field narrowing in `.claude/settings.json`, `secrets-scan.sh` doesn't spawn unless the command shape contains `git commit`, and `supply-chain-scan.sh` doesn't spawn unless the shape contains a package-manager keyword. The chain on a true fast-path command therefore reduces to:

```
IPC floor (bash spawn + stdin pipe)   ~13 ms p95 on WSL2
+ governance-gate.sh fast-path        ~20 ms p95
+ runtime-pre-mark.sh fast-path       ~38 ms p95
= ~70 ms p95 chain on fast-path
```

Slow-path commands (those a gate exists to inspect — `git commit`, `npm install`, etc.) are NOT bounded by this budget. The gate runs its full logic — pattern matching, audit-row writing, override-marker parsing. Those costs are paid in service of the gate's contract.

The 80 ms target is empirical, not aspirational. It corresponds to ~3× improvement over the 2026-05-26 baseline (governance-gate 62 ms + secrets-scan 68 ms + supply-chain-scan 73 ms + runtime-pre-mark 35 ms = ~238 ms uncoordinated chain).

If a future Claude Code release lifts the WSL2 IPC floor or the harness changes its `if`-field semantics, the budget moves with concrete reasoning recorded in this section. Don't lower the budget unless measurement on the current floor proves room exists; don't raise it without measurement either.

## Bench tool

`.claude/tools/bench-hooks.sh` measures per-hook p50/p95 against a representative command set. Three modes:

```bash
# Capture / re-capture baseline. Writes .claude/.perf-baseline.json.
bash .claude/tools/bench-hooks.sh --baseline [--reps N]

# Check current hooks against committed baseline. Exits 2 on regression
# beyond tolerance (default 25%; override with --tolerance PCT or
# CLAUDE_HOOK_CHAIN_TOLERANCE_PCT env var).
bash .claude/tools/bench-hooks.sh --check [--reps N] [--tolerance PCT]

# Pure run — print results to stdout/stderr, no file IO. For ad-hoc inspection.
bash .claude/tools/bench-hooks.sh [--reps N]
```

Default `--reps` is 100. The bench redirects `CLAUDE_PROJECT_DIR` to a per-run tmpdir so the hooks' own audit-log writes (`secrets-audit.jsonl`, `supply-chain-audit.jsonl`, `runtime-state/in-flight/`) never pollute the real project tree. Tmpdir is cleaned at exit.

Timing uses bash 5+'s `$EPOCHREALTIME` (microsecond precision built-in, no external timing tool). The bench requires bash 5+ and jq; it aborts with a clear error otherwise.

The bench invokes each hook directly with a synthetic stdin payload — bypassing Claude Code's harness, so the `if`-field narrowing isn't applied during the measurement. This is by design: the bench measures **intrinsic per-hook cost**, while the `if`-field benefit is a runtime characteristic that varies by command-shape distribution. The regression check catches drift in intrinsic cost; the runtime distribution drives the production p95.

## Baseline JSON shape

`.claude/.perf-baseline.json` is committed at the project root level (under `.claude/`). Shape:

```json
{
  "git_sha": "abc1234",
  "harness_version": "unknown",
  "os": "Linux 6.6.114.1-microsoft-standard-WSL2",
  "ts": "2026-05-26T20:55:14Z",
  "reps": 100,
  "cells": {
    "noop": {
      "noop": { "p50_ms": 9.0, "p95_ms": 13.5, "n": 100 },
      "ls":   { "p50_ms": 9.6, "p95_ms": 14.0, "n": 100 },
      "...":  { "..." : "..." }
    },
    "governance-gate.sh": { "...": "..." },
    "secrets-scan.sh":    { "...": "..." },
    "supply-chain-scan.sh": { "...": "..." },
    "runtime-pre-mark.sh":  { "...": "..." }
  }
}
```

`cells` is a 2-level object: outer key is the hook filename (or `"noop"` for the harness-IPC floor), inner key is the command label from the default command set. Each leaf is `{p50_ms, p95_ms, n}`. The schema is deliberately stable — `--check` reads `.cells[hook][cmd].p95_ms` directly; adding new cells is additive (existing entries unaffected); removing a cell that the current bench expects is a `null` and skipped on check.

`git_sha` is informational — the baseline corresponds to that commit's hooks. When hooks change in a PR, the baseline is expected to be re-captured in the same PR; the `--check` test catches the case where someone changed a hook and forgot.

## Regression check

The dedicated test suite `.claude/tests/hook-chain-latency/` carries three scenarios:

- `01-baseline-exists.sh` — `.claude/.perf-baseline.json` parses and has expected fields/cells.
- `02-bench-check-passes.sh` — `bench-hooks.sh --check` exits 0 against the current hooks. A loose tolerance (50%) absorbs sample noise at the test's small N.
- `03-regression-fires.sh` — inject a 100 ms `sleep` into governance-gate.sh, run `--check` against the slow tree, expect exit non-zero with stderr naming the offending cell. Confirms the alarm fires.

Run via `bash .claude/tests/hook-chain-latency/run-all.sh`.

The check is not wired into a `pre-commit` hook in v1. The monthly routine `.claude/routines/hook-chain-bench.md` runs `--check` on day-1 of each month and reports any regression to the next interactive session without auto-fixing or silently re-baselining.

## Cross-references

- `.claude/memory/hook-chain-maintenance.md` — upstream-maintainer discipline (optimization techniques + the 5-step contract for adding a new `PreToolUse(Bash)` hook).
- `.claude/rules/runtime-introspect.md` — sibling perf-observability rule; the `runtime-pre-mark.sh` hook this entry measures is owned by that capacity.
- `.claude/rules/secrets-scan.md` — `secrets-scan.sh` contract; the `if`-field narrowing preserves it exactly because the hook body is unchanged.
- `.claude/rules/supply-chain.md` — `supply-chain-scan.sh` contract; same.
- `.claude/rules/delegation.md` — `governance-gate.sh` sits in the broader delegation/governance family.

## Gotchas

- **Sample noise is real.** Even at `--reps 100`, p95 measurements vary by ±5-10 ms run-to-run on WSL2 (Linux scheduler quanta, filesystem cache warmth, system load). The default `--tolerance 25%` is calibrated to absorb noise at typical N; lowering it requires raising N.
- **The bench measures intrinsic per-hook cost, not production chain p95.** `if`-field narrowing means hooks don't spawn on irrelevant commands in production; the bench always runs every hook. Production p95 will be lower than the bench's chain sum (because narrowing cuts the chain) — the gap is the optimization's actual value.
- **WSL2 fork+exec overhead is the floor.** Each `bash <hook>` subprocess pays ~3-5 ms more on WSL2 than on native Linux. The IPC noop cell quantifies this. Native-Linux installations will hit the budget more easily; the 80 ms target assumes the WSL2 floor.
- **`if` field "always runs when the command is too complex to parse".** From the docs: the harness can't always parse `bash -c "..."` or other meta-shell shapes, and falls open by running the hook. This is the right semantic — false positives on complex shapes are safer than missed inspections — but it means the bench's reported p95 floor IS the worst case the production hook can hit.
- **The bench can be expensive itself.** 100 reps × 5 hooks × 10 commands × ~25 ms per cell = ~125 s for a single baseline run. Use lower `--reps` (20) for iteration; full N=100 for the locked baseline.
- **The bench's command set is synthetic.** A real-session distribution probe (instrumented `PostToolUse(Bash)` advisory hook logging command shapes) was scoped in the hook-chain-latency spec plan but deferred — the synthetic set covers the obvious shapes and the bench is honest about the gap. If the bench predicts wins that aren't perceived in real usage, the synthetic set is wrong and the deferred work becomes the next priority.
