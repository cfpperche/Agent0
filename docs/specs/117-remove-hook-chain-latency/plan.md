# 117 — remove-hook-chain-latency — plan

_Drafted from `spec.md` on 2026-05-29. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Same phased shape as specs 114/115/116: sever the live cross-references first, then delete the leaf files, then regenerate the `MEMORY.md` index, then validate. The surface here is small — this capacity is almost entirely self-contained (its own tool, baseline, two memories, routine, and test suite), with exactly one live external pointer (a comment in `governance-gate.sh`). There are no entrypoint sections (no CLAUDE.md/AGENTS.md managed block), no settings.json registration, no site card, and no sync-manifest line to remove (the bench tool ships via the `.agent0/tools|*.sh` glob, which simply stops matching once the file is gone; the memories never ship). The one structural subtlety is the crontab: a leader machine has a `hook-chain-bench` line in its `AGENT0-ROUTINES` block, which dangles once the routine file is deleted.

`docs/specs/*` is frozen (094 and all later mentions stay). The two `memory-placement.md` mentions are spec-096 historical narrative and are KEPT, identical to how 114/115 left their sibling `compaction-continuity`/`rule-load-debug` mentions on the same line. `capacity-spec-index.md` has no row for this capacity (it was never a fork-propagated rule), so it is untouched.

## Files to touch

**Modify:**
- `.agent0/hooks/governance-gate.sh` — reword the line-41 comment `# --- Pre-jq fast-path probe (see .agent0/memory/hook-chain-latency.md) ---` to drop the dead memory pointer; KEEP the probe body and its CRITICAL INVARIANT documentation verbatim.

**Delete (tracked → `git rm`):**
- `.agent0/tools/bench-hooks.sh` — the bench/regression tool
- `.claude/.perf-baseline.json` — the committed baseline the tool checks against
- `.agent0/memory/hook-chain-latency.md` — companion memory (budget + bench + baseline shape + regression check)
- `.agent0/memory/hook-chain-maintenance.md` — maintainer-discipline memory (optimization techniques + add-a-hook contract)
- `.agent0/routines/hook-chain-bench.md` — the monthly regression routine
- `.claude/tests/hook-chain-latency/` (4 files: `01-baseline-exists.sh`, `02-bench-check-passes.sh`, `03-regression-fires.sh`, `run-all.sh`) — the test suite

**Crontab (per-machine, not a repo file):**
- Remove the single `hook-chain-bench` line from the `AGENT0-ROUTINES` block via `crontab -l | grep -v 'run-routine.sh hook-chain-bench' | crontab -`. The surviving `cc-platform-audit` line stays.

**Regenerate:**
- `.agent0/memory/MEMORY.md` — via `bash .agent0/tools/memory-project.sh` (drops the two deleted entries).

## Alternatives considered

### Re-run `install-routines.sh` to regenerate the whole crontab block

Rejected as the in-scope mechanism. It would correctly drop the `hook-chain-bench` entry AND incidentally repair the pre-existing stale `.claude/tools/run-routine.sh` paths in the current block (the routines moved to `.agent0/` in spec 103/105 but the installed crontab was never regenerated). But: (1) `install-routines.sh` is interactive (prompts for leader designation), awkward to drive mid-implementation; (2) the stale-path repair is a *pre-existing, independent* condition — bundling it into this removal conflates two changes and would make the diff/PR misleading. The surgical single-line removal is the minimal correct action for *this* spec. The stale-path repair is noted in `notes.md` as a follow-up for the routines capacity, not this one.

### Keep `bench-hooks.sh` as a dormant tool "in case the chain grows"

Rejected — a measurement tool with no committed baseline (we are deleting it) and no routine driving it is dead code. Speculative retention is exactly the rule-of-three antipattern this removal applies. If hook-chain latency becomes a real measured problem again, the tool is one `git revert`/re-spec away.

### Keep one of the two memories

Rejected — `hook-chain-maintenance.md` is the "how to add a `PreToolUse(Bash)` hook + keep it fast" contract; `hook-chain-latency.md` is the "budget + bench + check" reference. Both exist solely to support the bench/budget discipline being removed. The genuinely-still-useful nugget (the `if`-field pipe-alternation-is-invalid CC lesson) is already captured in the live `secrets-scan.md` rule and the spec-108 history; it does not need a standalone memory once the bench is gone. Half-keeping leaves a memory pointing at a deleted tool.

## Risks and unknowns

- **A surviving test references the deleted tool/baseline.** Mitigation: the pre-flight grep (done 2026-05-29) found no `perf-baseline`/`bench-hooks` reference outside `.claude/tests/hook-chain-latency/` itself; re-run the affected suites post-removal (acceptance Scenario 6) to confirm no fixture breaks.
- **The `governance-gate.sh` edit accidentally weakens the probe.** Mitigation: the edit is comment-text only (the `see ...` clause); the probe body and the CRITICAL INVARIANT block are untouched; run `.claude/tests/governance-gate/run-all.sh` after.
- **Crontab edit on a non-leader / no-crontab machine.** Mitigation: `crontab -l | grep -v ... | crontab -` is a no-op when the line is absent; guard against empty-crontab error by checking `crontab -l` exit first.
- **MEMORY.md projection degraded path.** If `python3`+PyYAML are absent the projector falls back to awk; mitigation: confirm the regenerated index simply lacks the two lines and projection exits clean.

## Research / citations

- Exhaustive in-repo grep (2026-05-29) — full surface enumerated in `spec.md` + this file. Findings: one live external pointer (`governance-gate.sh:41`), no sync-manifest line (glob-covered), no site card, no settings.json registration, no `capacity-spec-index` row, crontab `hook-chain-bench` entry present (with stale pre-existing paths).
- `docs/specs/{114,115,116}-*/` — removal-shape precedent (sever refs → delete leaves → regen MEMORY → validate; KEEP frozen history).
- `.agent0/memory/hook-chain-latency.md` § Scope — confirms the chain is now 2 hooks post-116, the empirical basis for "apparatus outweighs risk".
- `.claude/rules/routines.md` § Gotchas — crontab marker-block semantics (manual edits clobbered on next install; surgical removal is fine as an immediate fix because next install regenerates correctly).
