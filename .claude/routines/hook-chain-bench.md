---
name: hook-chain-bench
schedule: "0 10 1 * *"
idempotent: true
on-stale: warn
stale-after-days: 14
---

# Prompt

You are running the monthly hook-chain latency regression check against the committed perf baseline.

**Last execution:** {{LAST_COMPLETED_TS}}. **Current HEAD:** {{GIT_HEAD}}. **Repo:** {{REPO_ROOT}}.

Steps:

1. Run: `bash .claude/tools/bench-hooks.sh --check`
2. Inspect the exit code:
   - **Exit 0** → no regression beyond tolerance. Respond with exactly: `no-regression-detected since {{LAST_COMPLETED_TS}}` (no edits).
   - **Exit non-zero** → a hook cell regressed past the tolerance threshold. The tool prints the offending `<hook>:<cmd>` cell(s) on stderr with measured-vs-baseline p95.
3. On regression:
   - Read `.agent0/memory/hook-chain-latency.md` § *Optimization techniques* for the three levers (matcher-narrowing, pre-jq probe, sed-instead-of-jq).
   - Inspect the offending hook(s) in `.claude/hooks/` and identify why the cell got slower (recent edit? new dependency? jq spawn re-introduced on the fast-path?).
   - Report findings to chat — **do NOT auto-fix and do NOT re-baseline**. The baseline is the contract; silently re-capturing it would mask the regression.
   - Suggest one of: revert the offending hook edit, apply an optimization from the rule, or (with justification) re-baseline.

# Done when

- Either `no-regression-detected since {{LAST_COMPLETED_TS}}` reported in chat with no edits,
  OR
- Regression report in chat naming the offending cells with measured-vs-baseline p95 numbers, root-cause hypothesis, and recommended next step.
- (Automatic) `.claude/.routines-state/hook-chain-bench/completed/<ts>.md` materialized by `/routine run` on archival.

<!--
Scaffold created 2026-05-26 via /routine new hook-chain-bench.
Monthly schedule (day-1 10:00 UTC) — bench is ~125s at N=100 reps, monthly cadence
balances drift-caught-early against cost.
Idempotent: --check reads .perf-baseline.json + measures current + compares;
re-running same day produces same exit code (modulo bench sample noise within
the tolerance window). No state mutation.
See .claude/rules/routines.md for full discipline + frontmatter reference.
-->
