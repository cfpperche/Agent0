# 183 — runtime-platform-audit

_Created 2026-06-09._

**Status:** shipped

**Closure:** 2026-06-09 — shipped (local). Generalized `cc-platform-audit` → `runtime-platform-audit` (provider-neutral; audits Claude + Codex hooks snapshots + agentskills.io snapshot + runtime-capabilities matrix cell values). Old routine deleted; cron re-registered via `install-routines.sh`. Verify: `routine validate` OK; doctor 24 ok/0 broken; instruction-drift anchors pass. Dry-run proved the new surface — Codex hooks 10/10 match (no drift), matrix `~29→~30` cell-drift caught + fixed. Residual: (1) Codex `apply_patch` Edit/Write-alias claim needs live-`/hooks` verification before rewriting `codex-cli-hooks.md` (notes.md follow-up); (2) consumer sync deferred (harness-only; propagates the routine + the matrix correction).

**UI impact:** none

## Intent

Agent0 maintains per-runtime platform snapshots that drift as the upstream runtimes ship features, but only **one** runtime is audited for that drift. The weekly `cc-platform-audit` routine checks Claude Code's docs against `cc-platform-hooks.md` (+ the agentskills.io snapshot). Meanwhile `codex-cli-hooks.md` exists and is equally drift-prone — its own "why this memory exists" records **two** real incidents where the `runtime-capabilities.md` matrix carried stale Codex cells (`hooks=unsupported`, spec 099; `subagents=unsupported`) that a spec-design conversation trusted without re-verifying — but **no routine audits it**. Worse, the highest-value surface — the **per-cell values** of `runtime-capabilities.md` — has no drift check at all: `check-instruction-drift.sh` deliberately validates only the matrix's *structure* (file exists, anchors, vocabulary, minimum rows), never whether a cell's "supported/unsupported" claim still matches upstream reality. That cell-value gap is exactly what bit Agent0 twice.

This spec **generalizes `cc-platform-audit` into one provider-neutral `runtime-platform-audit` routine** rather than cloning a parallel Codex routine (per the governance doctrine: avoid per-runtime routine proliferation; Agent0 is provider-neutral by design — `runtime-capabilities.md` *is* the provider-neutral matrix). The generalized routine sweeps a data-driven list of `(runtime, upstream-doc, snapshot-target)` audit units in a single weekly run, **and** adds a per-cell drift check of the `runtime-capabilities.md` matrix against each runtime's upstream docs — closing the gap `check-instruction-drift.sh` leaves open. It preserves the existing routine contract (idempotent, leave-diff-for-review-never-commit, on-stale warn). Not speculative: the demand is documented (≥2 incidents) and the snapshots/docs already exist and are WebFetchable.

## Acceptance criteria

- [x] **Scenario: one routine audits all runtimes**
  - **Given** the generalized `runtime-platform-audit` routine
  - **When** it runs
  - **Then** in a single execution it audits Claude Code (hooks → `cc-platform-hooks.md`) AND Codex CLI (hooks → `codex-cli-hooks.md`) against their upstream docs, reporting drift per runtime — not one routine per runtime

- [x] **Scenario: matrix cell-value drift is checked (the spec-099 gap)**
  - **Given** `runtime-capabilities.md` asserting per-runtime capability cells (e.g. `Codex CLI = supported/unsupported`)
  - **When** the routine runs
  - **Then** it diffs the definitive per-cell claims for each runtime that has a declared upstream doc against that doc, and proposes a matrix edit when a cell contradicts upstream — the check `check-instruction-drift.sh` deliberately omits

- [x] **Scenario: agentskills.io snapshot is audited against its true source, not CC docs**
  - **Given** `spec-snapshot.md` mirrors `agentskills.io/specification` (its own single-source contract)
  - **When** the routine audits skills
  - **Then** it diffs `spec-snapshot.md` against `agentskills.io/specification` (the canonical source); CC-specific skill frontmatter extensions (`argument-hint`, `disable-model-invocation`, `user-invocable`, `disallowed-tools`, `model`, `context: fork`) are reported as **informational** and never written into `spec-snapshot.md`

- [x] **Scenario: routine contract preserved**
  - **Given** the generalized routine
  - **When** drift is found
  - **Then** it applies edits to the relevant memo/matrix and **leaves the diff uncommitted** for human review (never auto-commits); when no drift, it reports `no-drift-detected since <ts>`; frontmatter stays `idempotent: true`, `on-stale: warn`, weekly schedule

- [x] **Scenario: clean migration off cc-platform-audit**
  - **Given** the existing `cc-platform-audit` routine
  - **When** this spec ships
  - **Then** `cc-platform-audit.md` is retired (removed or superseded so it no longer double-fires the Claude audit), `runtime-platform-audit.md` is registered via `install-routines.sh`, and the routine validator passes on the new file

- [x] Future-runtime rows with no declared upstream doc URL are **skipped, not guessed** (the audit list is the allowlist); the prompt names what it skipped
- [x] The stale `29-event table` reference in the current routine prompt is corrected to `30` (or made count-agnostic) during the port
- [x] `bash .agent0/skills/routine/scripts/validate.sh runtime-platform-audit` passes; `bash .agent0/tools/doctor.sh` reports 0 broken

## Non-goals

- Building a per-cell *parser/validator* for `runtime-capabilities.md` (a deterministic shell check). The audit is LLM-judgment work inside the routine prompt, consistent with how `cc-platform-audit` already operates — not an extension of `check-instruction-drift.sh`.
- Auto-committing audit results. The leave-diff-for-human-review contract is deliberate and preserved.
- Adding runtimes beyond Claude Code + Codex CLI to the audit list now (future runtimes join when they have both a snapshot and a fetchable doc URL).
- Changing `check-instruction-drift.sh` — it keeps validating structure only; the routine covers cell values. The two are complementary.
- Re-architecting the routine engine, cron model, or leader-flag mechanism.

## Open questions

- [x] **Retire mechanism for `cc-platform-audit`:** delete the file outright, or keep it as a tombstone? Lean: delete the routine definition (git history preserves it) and let `install-routines.sh` drop its cron block; the gitignored state dir can stay (orphaned, harmless) or be cleaned. Decide at plan time.
- [x] **How aggressive is the matrix cell-value audit?** Check only cells for runtimes with a declared doc URL (Claude, Codex), or attempt all cells? Lean: only runtimes in the audit allowlist (skips future-runtime placeholder rows, avoids false drift). Confirm at plan time.
- [x] **One prompt with per-runtime sections, or a small data table the prompt iterates?** Lean: an explicit audit-unit list at the top of the prompt body (`runtime | upstream-doc | snapshot-target | audit-kind`) the routine walks — keeps adding a runtime to a one-row edit. Confirm shape at plan time.

## Context / references

- `.agent0/routines/cc-platform-audit.md` — the routine being generalized (weekly Mon 9am, `idempotent`, `on-stale: warn`, leave-diff contract)
- `.agent0/memory/cc-platform-hooks.md` — Claude hooks snapshot (just corrected 2026-06-09: exit-2 semantics)
- `.agent0/memory/codex-cli-hooks.md` — Codex hooks snapshot (10 events; source `developers.openai.com/codex/hooks`); its "why this memory exists" records the 2 stale-matrix incidents
- `.agent0/memory/runtime-capabilities-maintenance.md` — confirms `check-instruction-drift.sh` validates matrix *structure* only, never cell values
- `.agent0/context/rules/runtime-capabilities.md` — the provider-neutral matrix whose cells are the high-value audit target
- `.claude/skills/skill/references/spec-snapshot.md` — agentskills.io mirror (audit against agentskills.io, not CC)
- `.agent0/context/rules/routines.md` — routine discipline (idempotency mandate, cron, leader model)
- Spec 099 — the canonical stale-Codex-cell incident; `[[feedback_verify_runtime_capabilities]]` (the behavioral discipline this routine automates); `[[feedback_speculative_observability]]` (rule-of-three — met here by ≥2 documented incidents)
