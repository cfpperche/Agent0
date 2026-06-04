# 150 — squad — plan

_Drafted from `spec.md` (v1 cut resolved in the 2026-06-04 dogfooded debate). Update if implementation reveals the plan is wrong._

## Approach

Split the resolved design into a **deterministic state machine** (`squad.sh`, fully shell-unit-testable, like `meeting.sh`) and a **runtime-driven pump loop** (described in `SKILL.md`, orchestrated by the initiating runtime via the exec bridges). `squad.sh` owns everything mechanical — run-dir state, the turn-lock (single-writer), per-turn `git diff` snapshot + out-of-turn/forbidden-path guard, the budget counters, the gate runner, and the terminal-state transitions. The runtime owns the *content* of each turn and the loop control flow, exactly mirroring the meeting.sh (state) ↔ runtime (content) split. This keeps the bias-/safety-critical logic testable and provider-neutral, and means the genuinely-hard "autonomous pump" is thin orchestration over a tested core.

The done-condition is an **executable contract** `docs/specs/NNN/squad.yaml` (acceptance + validator + build/lint/typecheck + optional smoke + budgets + checkpoint cadence + forbidden/human-gated path patterns). `squad.sh gate` runs it; agent agreement only sets `propose_done`, and `gate` green is what moves to `ready_for_human_prod`. Build order: (1) `squad.yaml` schema + example; (2) `squad.sh init` + state.json; (3) turn-lock + diff-snapshot + guard; (4) budget + repair counters + terminal states; (5) `gate` runner; (6) `rollback`; (7) `SKILL.md` pump loop + the `--mode assisted` debug path; (8) rule + tests; (9) dogfood dry-run + validate. The live multi-agent pump is exercised via a dry-run harness (stub peer + stub gate) — a real 2-agent code-writing run is a separate, cost-gated activity, NOT a unit test.

## Files to touch

**Create:**
- `.agent0/skills/squad/SKILL.md` — the `/squad` skill: `init`/`run`/`status`/`abort` subcommands; the pump loop (initiator drives: turn → `squad.sh turn-end` → `gate` → terminal? else invoke peer via `codex-exec`/`claude-exec` workspace-write → repeat); symmetric initiation; `--mode assisted` (human pumps) debug path; the human-checkpoint + human-triggers-prod discipline. agentskills.io-compliant frontmatter.
- `.agent0/skills/squad/scripts/squad.sh` — the deterministic state machine (subcommands below). bash 3.2-compatible, `set -uo pipefail`, jq for state.json.
- `.agent0/skills/squad/references/squad.yaml.example` — annotated example gate contract.
- `.agent0/skills/squad/references/squad-contract.md` — the `squad.yaml` schema + the terminal-state semantics (reference doc).
- `.agent0/tests/squad/` — shell suite (run-all + scenarios), building a temp git repo.
- `.agent0/context/rules/squad.md` — the capacity rule (what `/squad` is, the bounded/gate-driven/human-at-gates discipline, the terminal states, relationship to 138/149).

**Modify:**
- `CLAUDE.md` — add a `## Squad` managed-block section (index entry, like the other capacities).
- `docs/specs/138-meeting-bounded-autopilot/spec.md` — mark its autonomous-loop concern superseded-by-150 (a one-line status note; 138's friction *measurement* stays).
- `.gitignore` — ignore the run-dir tree `.agent0/squads/` (ephemeral per-run state; or place under `.agent0/.runtime-state/squads/` to inherit the existing ignore — decide in impl, lean toward `.runtime-state` for zero new gitignore).

**`squad.sh` subcommands:**
- `init --spec <NNN-slug> [--initiator <id>] [--run-root <dir>]` → read `docs/specs/<NNN-slug>/squad.yaml`; create run dir + `state.json` (`status=running`, `turn_holder=<initiator>`, `round=0`, `repair_attempts=0`, budget from yaml, `start_head=<git HEAD>`); echo run dir.
- `turn-start --run <dir> --speaker <id>` → assert `turn_holder==id` (else exit 3, turn-lock); stamp turn begin.
- `turn-end --run <dir> --speaker <id>` → record `git diff --stat` + changed paths; `round++`; flip `turn_holder`; enforce budget (round/token ceiling) → `status=aborted_budget` if exhausted.
- `guard --run <dir>` → out-of-turn change detection (paths changed since last clean boundary by the non-holder) → `aborted_conflict`; forbidden/human-gated path touched → `aborted_policy`.
- `gate --run <dir>` → run `squad.yaml` gate commands; all-green + `propose_done` (both agents) → `ready_for_human_prod`; any fail → `repair_attempts++`, `> max` → `aborted_repairs`.
- `propose-done --run <dir> --speaker <id>` → record an agent's done-proposal (agreement only *proposes*; `gate` confirms).
- `rollback --run <dir>` → `git restore`/`checkout` to last clean turn boundary.
- `status --run <dir>` → print state.json; `abort --run <dir> --reason <r>` → terminal abort + report stub.

## Alternatives considered

### Pump loop owned by `/loop` or `/goal` instead of a dedicated `squad.sh`
Rejected (debate, both agents independently): `/squad` coordinates two runtimes + writes + gates + budgets + repairs + abort reports — it needs its own durable, auditable state machine. `/loop`/`/goal` are useful *inputs* (self-pacing, done-conditions) but can't own multi-runtime write-serialization + terminal states.

### Worktree-per-agent + merge for v1 write model
Rejected for v1 → v2: introduces LLM-vs-LLM merge conflict resolution, duplicated installs, rollback complexity *before the loop is proven*. v1 = turn-locked single-writer on one tree (the meeting.sh invariant) + per-turn diff snapshot + rollback.

### Agent agreement as (part of) the done-condition
Rejected — the whole point of the 149 dependency. Agreement only sets `propose_done`; the external `gate` (tests/build/validator green) is the sole closer. This is enforced mechanically: `ready_for_human_prod` requires `gate` green, not just `propose_done`.

### Unit-test a live 2-agent pump
Not feasible — a real run costs tokens + needs a target spec + wall-clock. v1 tests the deterministic core (state transitions, lock, budget, gate-runner with a stub, terminal states, guard) in a temp git repo; the live pump is validated by a dry-run (stub peer/gate) + a documented real dogfood as a separate cost-gated step.

## Risks and unknowns

- **The live pump is the real risk** — an autonomous loop calling exec bridges that write code. v1 de-risks by: hard budget ceiling, max-repair abort, turn-lock + out-of-turn guard, human checkpoints, and human-triggers-prod. The first real dogfood should be a tiny, low-risk pre-planned spec.
- **Out-of-turn detection** relies on git diff between turn boundaries; an agent that edits outside its turn (or the exec bridge writing unexpectedly) must be caught — `guard` compares changed paths to the turn_holder's expected scope.
- **squad.yaml coupling** — must declare gates without freezing a stack (Agent0 ships mechanisms, not stack opinions): the validator is stack-aware already; acceptance/build commands are project-declared.
- **Run-dir placement** — `.agent0/.runtime-state/squads/` (gitignored, ephemeral) vs a tracked `.agent0/squads/` (auditable run history). Lean ephemeral; the durable record is the spec + git history of the turns.
- **Scope** — this is the largest single capacity in the roadmap. v1 discipline: deterministic core + thin pump + one dry-run; NO worktree, NO 3rd runtime, NO autonomous-to-prod.

## Research / citations

- Resolved design: `docs/specs/150-squad/spec.md` § Resolution + the dogfooded debate transcript `.agent0/meetings/squad-v1-design-2026-06-04T17-48-21Z/meeting.md` (independent blind convergence + ledger).
- Precedents: `.agent0/skills/meeting/scripts/meeting.sh` (state-machine + turn-lock pattern, + the spec-149 mechanics), `.agent0/validators/run.sh` (stack-aware external gate), `.agent0/hooks/delegation-verify.sh` (external-oracle-at-close), `.agent0/context/rules/artifact-budgets.md` (runaway circuit-breaker), governance-gate (destructive-op floor), `docs/specs/138-meeting-bounded-autopilot/` (bounded/gate-driven safety lineage).
