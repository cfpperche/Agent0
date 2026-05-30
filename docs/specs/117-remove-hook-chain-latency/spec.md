# 117 — remove-hook-chain-latency

_Created 2026-05-29._

**Status:** shipped

## Outcome

Shipped 2026-05-29. `hook-chain-latency` removed in full: `bench-hooks.sh`, `.claude/.perf-baseline.json`, both memories (`hook-chain-latency.md` + `hook-chain-maintenance.md`), the `hook-chain-bench` routine, and the `.claude/tests/hook-chain-latency/` suite (4 files) all `git rm`'d. The dangling `hook-chain-bench` crontab line was surgically dropped from the `AGENT0-ROUTINES` block (surviving `cc-platform-audit` line intact); no `hook-chain-bench` routines-state dir existed to clear. `MEMORY.md` regenerated 21→19 entries (projection clean). The single live cross-ref — the dead `see .agent0/memory/hook-chain-latency.md` pointer in `governance-gate.sh:41` — was reworded; the pre-jq probe body + CRITICAL INVARIANT stayed verbatim (validated: the gate even blocked an `rm -rf` mid-implementation, confirming it works). The two `memory-placement.md` spec-096 narrative mentions were KEPT (still-true history; same disposition 114/115 used for their sibling `compaction-continuity`/`rule-load-debug` mentions on the same line). `capacity-spec-index.md` untouched (no row ever existed). Validation: governance-gate / secrets-scan / harness-sync / instruction-drift suites all PASS; repo-wide grep outside `docs/specs/` returns only the two KEEP-listed lines; `settings.json` parses. One pre-existing unrelated condition noted, not bundled: the installed crontab still uses stale `.claude/tools/` run-routine paths (a spec-103/105 migration leftover, independent of this removal — `notes.md`).

## Intent

Remove the `hook-chain-latency` capacity (spec 094) entirely — the `bench-hooks.sh` measurement tool, the committed `.claude/.perf-baseline.json`, both maintainer memories (`hook-chain-latency.md` + `hook-chain-maintenance.md`), the monthly `hook-chain-bench` routine (plus its crontab entry), the `.claude/tests/hook-chain-latency/` test suite, and every live cross-reference. The capacity benchmarks the `PreToolUse(Bash)` hook chain against a committed p95 baseline and a 25%-tolerance regression check, run monthly.

It is now overengineering relative to the risk it guards. The chain it benches has shrunk to **two hooks** — `governance-gate.sh` + `secrets-preflight.sh` — after the spec-112→116 pruning arc removed supply-chain-scan, the secrets Edit-time advisory, and runtime-pre-mark from the `PreToolUse(Bash)` path. A bench tool + committed baseline + monthly cron routine + two memory files + a three-scenario test suite is a large apparatus to guard the latency of a 2-hook chain whose intrinsic cost is dominated by the unavoidable WSL2 bash-spawn IPC floor (~13 ms) that no optimization of ours can move. The asymmetry — measurement apparatus weight vs the perf risk actually guarded — is the same skeptical-pruning signal as specs 114/115/116 (`feedback_speculative_observability`, rule-of-three demand test): the bench has fired in one routine slot per month with no recorded regression, the read side has no evidence of catching a real problem, and the synthetic command-set caveat means it never claimed to predict real-session p95 anyway.

**Critical scope boundary:** removal is the *measurement apparatus only*, NOT the hook optimizations spec 094 introduced. The pre-jq raw-stdin probe in `governance-gate.sh` is a genuine, independently-valuable latency win (the no-op fast-path skips a `jq` spawn) and STAYS — only the dead `see .agent0/memory/hook-chain-latency.md` pointer in its comment is reworded. The `sed`-instead-of-`jq` extraction documented in the maintenance memory lived in `runtime-pre-mark.sh`, already deleted in spec 116, so nothing to preserve there.

## Acceptance criteria

- [ ] **Scenario: bench tool, baseline, both memories, and routine are gone**
  - **Given** the repo after this spec ships
  - **When** `ls .agent0/tools/bench-hooks.sh .claude/.perf-baseline.json .agent0/memory/hook-chain-latency.md .agent0/memory/hook-chain-maintenance.md .agent0/routines/hook-chain-bench.md` runs
  - **Then** every path reports "No such file or directory"

- [ ] **Scenario: test suite removed**
  - **Given** the repo after this spec ships
  - **When** `ls .claude/tests/hook-chain-latency` runs
  - **Then** the directory is gone

- [ ] **Scenario: dangling crontab entry dropped**
  - **Given** a leader machine whose crontab `AGENT0-ROUTINES` block listed `hook-chain-bench`
  - **When** the routine file is deleted and the `hook-chain-bench` line is removed from the crontab block
  - **Then** `crontab -l` shows no `hook-chain-bench` line and the surviving `cc-platform-audit` routine entry is intact

- [ ] **Scenario: governance-gate optimization preserved, dead pointer reworded**
  - **Given** `.agent0/hooks/governance-gate.sh`
  - **When** inspected after the change
  - **Then** the pre-jq fast-path probe + its CRITICAL INVARIANT documentation are intact AND the comment no longer points to the deleted `.agent0/memory/hook-chain-latency.md`

- [ ] **Scenario: MEMORY.md index regenerated; both maintainer entries gone**
  - **Given** the deleted `hook-chain-latency.md` + `hook-chain-maintenance.md`
  - **When** `bash .agent0/tools/memory-project.sh` runs
  - **Then** `MEMORY.md` has no `hook-chain-latency` / `hook-chain-maintenance` line and the projection runs clean

- [ ] **Scenario: surviving test suites still green after removal**
  - **Given** the remaining `.claude/tests/`
  - **When** the affected suites are run (governance-gate, secrets-scan, harness-sync, instruction-drift)
  - **Then** they pass — no surviving test references the deleted bench tool, baseline, or test dir

- [ ] No live (non-`docs/specs/`) reference to the deleted capacity survives that implies it still exists: a repo-wide grep for `hook-chain-latency|hook-chain-maintenance|hook-chain-bench|bench-hooks|perf-baseline|CLAUDE_HOOK_CHAIN` outside `docs/specs/` returns only KEEP-listed lines (the spec-096 historical-narrative mentions in `memory-placement.md` — see § Decisions / `notes.md`).
- [ ] `.agent0/hooks/governance-gate.sh` keeps its pre-jq probe; only the dead memory pointer in the comment is reworded.

## Non-goals

- **Not removing the hook optimizations.** The `governance-gate.sh` pre-jq raw-stdin probe stays — it is a real latency win independent of the bench that measured it. Only the measurement scaffold and its dead pointer go.
- **Not touching `governance-gate.sh` / `secrets-preflight.sh` behavior.** The two `PreToolUse(Bash)` hooks the chain consisted of are unaffected; their rules (`delegation.md`, `secrets-scan.md`) are unchanged.
- **Not rewriting `docs/specs/*` history** (094 and every later mention) — frozen audit trail per `.claude/rules/spec-driven.md`.
- **Not rewriting `memory-placement.md`'s spec-096 narrative.** The two mentions there describe the historical rule→memory move (still-true history, same disposition 114/115 used for their sibling `compaction-continuity` / `rule-load-debug` mentions on the same line). KEEP.
- **Not re-implementing a replacement.** If hook-chain latency ever becomes a real, measured problem again, it can be re-specced; rebuilding the apparatus now would re-trip the rule-of-three demand test.
- **Not editing `capacity-spec-index.md`.** The hook-chain-latency capacity was never indexed there (it was maintainer-internal memory, not a fork-propagated rule/capacity), so there is no row to remove.

## Open questions

- [x] Crontab cleanup mechanism — re-run `install-routines.sh` (regenerates the whole `AGENT0-ROUTINES` block from `.agent0/routines/*.md`, also repairing the pre-existing stale `.claude/tools/` paths) vs a surgical single-line `crontab -l | grep -v | crontab -`. Resolved in `plan.md`: the surgical removal is the minimal, non-interactive, in-scope action; the stale-path repair is a pre-existing condition, noted but not bundled (independent of this removal — it is the routines capacity's own fix). Recorded in `notes.md`.
- [x] None blocking otherwise.

## Context / references

- `.agent0/memory/hook-chain-latency.md` + `.agent0/memory/hook-chain-maintenance.md` — the maintainer memories being deleted (full capacity description + maintainer discipline)
- `.agent0/tools/bench-hooks.sh`, `.claude/.perf-baseline.json`, `.agent0/routines/hook-chain-bench.md`, `.claude/tests/hook-chain-latency/` — the apparatus
- `docs/specs/094-hook-chain-latency/` — origin spec (empirical baseline + optimization decisions)
- `docs/specs/{114-remove-compaction-continuity,115-remove-rule-load-debug,116-remove-runtime-introspect}/` — immediate removal precedents (same shape + KEEP-history discipline); 116 removed runtime-pre-mark from the chain this benched
- `docs/specs/112-prune-supply-chain-and-secrets-advise/` — pruned the chain further (the shrinkage that motivates this removal)
- `feedback_speculative_observability` (user auto-memory) — the rule-of-three demand test this applies
