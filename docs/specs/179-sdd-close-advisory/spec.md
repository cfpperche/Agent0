# 179 — sdd-close-advisory

_Created 2026-06-09._

**Status:** shipped
**Closure:** 2026-06-09 — `sdd-close.sh` + opt-in validator advisory + rule + index + suite; tests 8/8; doctor 24 ok/0 broken; advisory silent (0) on live corpus; recency design pivoted to `**Closure:**` opt-in mid-build (see notes.md); residual: none

**UI impact:** none

## Intent

The closure convention (commit `d6da13c`: `**Status:**` enum + `**Closure:**` line) gives a spec a place to record *that* it is done and *with what evidence* — but nothing checks that a spec's own artifacts actually agree with its declared `shipped` status. The gap is concrete and was hit **this session**: spec 177 sat `**Status:** shipped` with **every box in `tasks.md` still `[ ]`** — discovered only because a cross-model debate happened to dig there. In a 160+-spec corpus, that kind of "done"-state drift is invisible. This spec adds an **opt-in-feeling, read-only, non-blocking** checker that makes closure inconsistencies visible without bloating ceremony — the markdown+shell+advisory idiom of spec 177's `spec-verify`, which it complements (verify proves the spec's *command* still passes; close proves the spec's *artifacts* agree with its status).

The checker reports, per shipped (or `shipped-partial`) spec: unchecked `tasks.md` boxes, unchecked `## Acceptance criteria` boxes, surviving `{{...}}` template placeholders, and a missing `**Closure:**` line.

The **central design constraint** is noise. Naively nagging all 160+ shipped specs would flood the validator with advisories on legacy specs that legitimately carry residual unchecked boxes (the rule itself notes "the earliest specs keep their flat-checklist shape") — re-introducing the exact speculative-observability / nag anti-pattern the project rejects. So the capability is split into two surfaces with different noise postures:

- **On-demand auditor** (`.agent0/tools/sdd-close.sh`) — the human runs it deliberately (whole corpus or one spec); it reports **everything**, including `missing-closure`. No noise problem because invocation is intentional.
- **Validator advisory** (`sdd-close-advisory:`) — fires automatically but is **opt-in via the `**Closure:**` line**, exactly mirroring how spec-verify opts in via `**Verify:**`. Only a spec that has *formally closed* (declares `**Closure:**`, asserting "done with this evidence") is checked; if its artifacts contradict that assertion (unchecked tasks/acceptance boxes or surviving placeholders), one advisory line fires. Specs **without** a `**Closure:**` line are never nagged — so the legacy corpus stays silent and Agent0's high spec-cadence never floods. `missing-closure` is therefore NOT an advisory finding (a spec with no closure line simply has not opted in); it remains a finding of the on-demand auditor. **Why opt-in beats recency:** a rolling time-window was tried and rejected during implementation — Agent0 ships ~4 specs/day, so even a 14-day window captured ~80 specs, and since the closure convention is brand-new every pre-convention spec tripped `missing-closure`. The `**Closure:**` line is the honest, self-scoping signal of "this spec is being held to the modern bar."

It serves any agent or human closing a spec, ships to consumers via `sync-harness`, and adds no blocking gate.

## Acceptance criteria

- [x] **Scenario: tool flags a shipped spec with unchecked tasks**
  - **Given** a shipped spec whose `tasks.md` still has `- [ ]` boxes (the 177 shape)
  - **When** `bash .agent0/tools/sdd-close.sh <spec-dir>` runs
  - **Then** it reports the unchecked-tasks finding and exits 1, without modifying any file

- [x] **Scenario: tool is clean on a fully-closed spec**
  - **Given** a shipped spec with all tasks + acceptance checked, no surviving placeholders, and a `**Closure:**` line
  - **When** the tool runs on it
  - **Then** it reports no findings and exits 0

- [x] **Scenario: tool detects surviving placeholders and missing closure**
  - **Given** a shipped spec with a `{{...}}` placeholder and no `**Closure:**` line
  - **When** the tool runs
  - **Then** both the placeholder finding and the missing-closure finding are reported

- [x] **Scenario: validator advisory is opt-in via the Closure line**
  - **Given** two shipped specs each with an unchecked task box — one that declares `**Closure:**`, one that does not
  - **When** `.agent0/validators/run.sh` runs
  - **Then** exactly one `sdd-close-advisory:` line is emitted (the one that declared `**Closure:**`); the spec without a closure line is silent; the validator's `ok`/exit is unchanged

- [x] **Scenario: the legacy corpus stays silent**
  - **Given** the live Agent0 corpus where ~160 shipped specs predate the closure convention (no `**Closure:**` line) and carry residual unchecked boxes
  - **When** the validator runs
  - **Then** no `sdd-close-advisory:` fires for any of them — only specs that opted in by declaring `**Closure:**` are ever checked

- [x] `.agent0/tools/sdd-close.sh` exists, is executable, accepts `[<spec-dir>] [--json] [-h]`, is read-only (writes nothing), and exits `0` clean / `1` findings / `64` usage
- [x] `--json` emits a single well-formed JSON object (parses under `jq`) listing per-spec findings
- [x] `.agent0/validators/run.sh` emits `sdd-close-advisory:` to stderr only for shipped specs that declare `**Closure:**` and have a consistency finding, never altering `ok`; opt-out via `CLAUDE_VALIDATOR_SKIP_SDD_CLOSE=1`; silent on the current corpus (0 advisories)
- [x] `.agent0/context/rules/sdd-close.md` documents the tool, the advisory, the two-surface noise split, and the consumer-extension note
- [x] Test suite `.agent0/tests/sdd-close/` covers every acceptance scenario over throwaway fixture specs and is green
- [x] Managed-index entry added to `CLAUDE.md` + `AGENTS.md` (matching the `## Spec verify advisory` style)

## Non-goals

- Re-running or duplicating `**Verify:**` checks — that is spec 177's `spec-verify`; sdd-close stays strictly on static closure consistency and does not touch verify territory (no double advisory).
- Any blocking gate — advisory-only, never alters validator `ok`/exit; never auto-fixes (no checking boxes, no writing `**Closure:**`).
- Nagging the legacy corpus — the validator advisory is opt-in via `**Closure:**` precisely so the ~160 historical specs (which never declared closure) are not flooded.
- A new status/closure schema — consumes the `d6da13c` convention as-is.
- Cross-spec relations or a closure dashboard (speculative observability — out).

## Open questions

_All resolved during implementation (the dogfood overturned the recency design — see `notes.md` § Design decisions):_

- [x] ~~Recency window default — 14 vs 7 days~~ → **recency dropped entirely.** A time-window floods in a ~4-spec/day repo (14 days ≈ 80 specs) and nags every pre-convention spec. Replaced by **opt-in via the `**Closure:**` line** — self-scoping, silent by default, migration-immune, no date math.
- [x] ~~Should `missing-closure` trigger the advisory?~~ → **No.** Under opt-in, a missing closure line *is* the opt-out signal; it cannot also be a nag. `missing-closure` stays a finding of the on-demand auditor only.
- [x] One advisory line per spec (aggregating findings) vs one per finding? → **one per spec**, like `spec-verify-advisory`, to keep stderr quiet.

## Context / references

- `.agent0/tools/spec-verify.sh` + `.agent0/validators/run.sh` lines 26-55 (spec 177) — the idiom to mirror: opt-in, stderr-only, placed before stack-detection, never touches `ok`.
- Closure convention commit `d6da13c`; the 177 unchecked-tasks inconsistency is the canonical motivating defect.
- `.claude/skills/sdd/SKILL.md` § `list` — the recency-window pattern (`CLAUDE_SDD_IN_FLIGHT_RECENCY_DAYS`) was considered for noise control and rejected during implementation; opt-in via `**Closure:**` replaced it (see `notes.md` § Design decisions).
- `.agent0/context/rules/spec-driven.md` (revised by spec 178) — this spec passes the new 5-question admission gate (new tool + validator surface, consumer-facing, crosses the Agent0↔consumer boundary), so it is correctly spec-driven.
- `.agent0/context/rules/agent0-governance-doctrine.md` / `scope-admission-governance.md` — scope classification in `plan.md`.
