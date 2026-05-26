# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects and enforces this file through hooks; Codex reads and updates it by convention through `AGENTS.md`.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

Spec 093 (runtime-capability-registry) scaffolded end-to-end in one session: `spec.md` drafted, 2-round cross-model debate (Codex initiating, Claude reviewing) converged at Round 2, all 14 synthesis bullets applied to `spec.md`, `debate.md` § Applied changes filled, `plan.md` drafted with vocabulary pressure-test dry-run, `tasks.md` drafted with 17 numbered tasks across 7 layers + verification. Status: `draft`; ready for implementation top-to-bottom starting at Layer 0 (vocabulary lock-in gate).

Converged design: registry lives at `.claude/rules/runtime-capabilities.md` (NOT `.agent0/*` — that namespace stays per-project per spec 092); six-state vocabulary (`native` / `native-opt-in` / `convention` / `read-only` / `planned` / `unsupported`); AGENTS.md `## Codex Capability Tiers` table removed in favor of pointer + skeptical default; CLAUDE.md managed-block parity; `check-instruction-drift.sh` extended with 5 anchor-level invariants; tests under `.claude/tests/runtime-capabilities/`; MCP recipes row pre-shipped as the vocabulary pressure-test (Claude=`native-opt-in`).

Spec 090 (multi-runtime-entrypoints) and 092 (multi-runtime-handoff) remain shipped. Spec 091 (sdd-debate-runner, `docs/specs/091-sdd-debate-runner/`) remains paused and **untracked** on the working tree — do not commit or resume without explicit user direction.

## Active Work

_None._

## Next Actions

1. Work `docs/specs/093-runtime-capability-registry/tasks.md` top-to-bottom starting with **Layer 0 task 1** (re-confirm the 12-row × 2-runtime vocabulary pressure-test from `plan.md § Approach` step 1 + verify `.claude/hooks/mcp-recipes-hint.sh` exists at that exact path).
2. If Layer 0 surfaces any row that resists the six-state vocabulary, update `spec.md § Scenario: status vocabulary` BEFORE proceeding — do not silently expand the vocabulary in the registry.
3. After registry ships, MCP parity becomes the obvious spec-094 candidate (the worked-example row already lists current owner files and the `native-opt-in` marker).
4. Keep spec 091 paused and untracked unless the user explicitly resumes it.

## Decisions & Gotchas

- 093 registry path is `.claude/rules/runtime-capabilities.md` — `.agent0/*` rejected in debate because spec 092 made that namespace per-project state; mixing Agent0-managed policy in would blur the contract. Existing `.claude/rules/*` sync glob covers the new file with zero manifest edits.
- YAML/JSON sidecar rejected in Round 2: two canonical files for one registry would reintroduce the drift risk the spec is built to eliminate. Markdown canonical; the five anchor-level drift checks don't parse cells, so parsing-fragility is moot. Promote to a schema only when a real machine-read use case appears.
- `AGENTS.md` `## Codex Capability Tiers` is being removed in the same change as the registry ships — drift check (c) makes this irreversible without breaking CI. Fork-local reintroduction must use `AGENTS.override.md`, not in-place edits to the managed block.
- `MINIMUM_SET` array in `check-instruction-drift.sh` is a second source of truth alongside `spec.md` Scenario 1's 12-row enumeration. A future spec promoting a 13th row to the minimum updates both in the same commit; the array literal carries a comment naming the spec as canonical source.
- `.agent0/HANDOFF.md` is git-tracked but **outside** `sync-harness.sh`'s manifest by design — per-project state, never fork-managed. (Carried forward from 092; informs why 093's registry can't live here.)
- Block-once Stop semantics, edit-attribution tracker, porcelain-compare fallback unchanged from 092.
