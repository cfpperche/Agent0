# 150 — squad

_Created 2026-06-04._

**Status:** shipped (2026-06-04 — squad.sh state machine + skill + contract + rule; squad tests 8/8; meeting 15/15, deliberation-bias 11/11, harness-sync 40/40 no-regression. Live 2-agent pump = separate cost-gated dogfood.)

## Intent

Add `/squad` — an **autonomous, symmetric, ping-pong multi-agent build loop**: two (later N) heterogeneous LLM runtimes (Claude Code ↔ Codex CLI today) implement a spec together, taking turns *without a human pumping each turn*, until an **externally-verified done-condition** is met — at which point the human enters to approve and trigger production. It is the **Etapa 2** capstone of the roadmap whose Etapa 1 (`149-deliberation-confirmation-bias`) just shipped: a squad's value hinges on "the agents agree it's done" being trustworthy, so `/squad` reuses 149's de-biased deliberation mechanics and — critically — **never lets agent agreement BE the done-condition.** Done is defined by reality external to the agents (acceptance tests that run green, build/lint/typecheck, a staging smoke), not by the models concluding they're finished.

The honest framing the founder and Claude converged on (across this session): the maximalist "infinite, 100% AI, human only at the very end, convergence = the agents agreeing" vision has three load-bearing flaws — (a) convergence ≠ correctness (mutual confirmation: two models can agree on a shared wrong belief), (b) "infinite" = unbounded cost + drift, (c) "human only at the end" removes the human from exactly the last-20% where agents are weakest, and autonomous-to-prod is the highest-risk surface. `/squad` therefore ships the **bounded, gate-driven, human-at-milestones** version that earns more autonomy with evidence (rule-of-three), carrying spec-138's safety thinking. The building blocks already exist (symmetric `codex-exec`/`claude-exec` bridges that can write; the `meeting.sh`/`debate.md` turn protocol; 149's commit-reveal + claim/evidence gate; validators + `/verify` + `delegation-verify` as external oracles; `/goal`'s done-condition; `/loop`'s self-pacing). The genuinely-new piece is the **autonomous pump + its safety rails** (termination, write-serialization, cost bound, failure handling).

## Candidate scope (the debate resolves the v1 cut)

1. **Autonomous pump** — the initiating runtime runs the loop: implement its turn → invoke the peer via the exec bridge (workspace-write) → read the peer's turn → continue, until the done-condition or a bound. Symmetric: either runtime can initiate (like `/meeting`/`debate` — whoever starts owns the loop), so a human in a Codex session gets the same capability via `claude-exec`.
2. **Done-condition = external gates only** — a machine-checkable gate set (acceptance tests pass + build/lint/typecheck green + optional staging smoke). Agent agreement is *necessary but never sufficient*; it gates *proposing* done, the external check *confirms* it. Reuses 149's claim/evidence ledger for the "why we think it's done" record.
3. **Bounded, not infinite** — a token/round budget ceiling (à la `budget.total`) + a per-phase human checkpoint cadence; "infinite" is rejected.
4. **Write-serialization** — only the current turn-holder writes the tree (the `meeting.sh` single-writer-per-turn invariant) OR worktree-per-agent + merge; both editing concurrently is the core hazard.
5. **Human at milestone gates** — spec-approved, phase-complete, pre-prod — trending to fewer gates as trust is earned; NOT "human only at the end".
6. **Agents prepare prod, human triggers prod** — autonomous to staging; the production deploy is human-pulled (governance-gate / outward-action-confirmation posture).
7. **Failure handling** — peer returns broken work / a gate fails → bounded repair attempts, then abort-to-human with a report (never silent loop or silent descope).

## Open questions (for the debate — using the 149 blind/ledger flow)

- [x] **v1 cut:** is v1 a *single* autonomous ping-pong implementing one already-`/sdd plan`-ned spec to green gates, human approving the plan up front and the deploy at the end? Or smaller (assisted: human pumps but agents co-implement)?
- [x] **Who/what owns the pump loop** mechanically (a new `squad.sh`? `/loop` + a done-condition? a `/goal`-style Stop-condition driving exec calls?) and how termination is enforced (budget exhausted / gates green / max repair attempts).
- [x] **Write-serialization model:** turn-locked single-writer vs worktree-per-agent + merge — tradeoffs for conflict, review, rollback.
- [x] **Done-gate definition surface:** where the external gate set is declared (the spec's acceptance criteria as executable tests? a `squad.yaml`? the project validator?) and how "staging smoke" is represented without coupling to a stack.
- [x] **Relationship to spec 138** (bounded-autopilot, demand-gated) and 091 (debate-runner, parked): does `/squad` supersede/absorb them, or sit beside them?
- [x] **Cost governance:** budget-ceiling shape + how a runaway is circuit-broken (mirror the 200 KB artifact cap / `budget.remaining()` patterns).

## Acceptance criteria

- [x] **Scenario: turn-lock enforces single-writer**
  - **Given** a squad run whose `turn_holder` is `claude`
  - **When** `squad.sh turn-start --speaker codex` is invoked
  - **Then** it refuses (exit 3) — only the current turn-holder may take a turn

- [x] **Scenario: agreement alone never closes the run (the 149-dependent invariant)**
  - **Given** both agents have `propose-done` but the gate command is red
  - **When** `squad.sh gate` / `status` runs
  - **Then** `status` is NOT `ready_for_human_prod` — `ready_for_human_prod` requires the external gate green, not agent agreement

- [x] **Scenario: gate green → ready_for_human_prod**
  - **Given** both agents proposed done and the `squad.yaml` gate commands all pass
  - **When** `squad.sh gate` runs
  - **Then** `status` becomes `ready_for_human_prod` (the human approves + triggers prod from there; the squad never deploys to production)

- [x] **Scenario: bounded — budget exhaustion aborts**
  - **Given** the run reaches its `max_rounds` (or token/spend ceiling)
  - **When** the next `turn-end` runs
  - **Then** `status` becomes `aborted_budget` (never infinite); the loop stops with a report

- [x] **Scenario: repair ceiling aborts**
  - **Given** the gate has failed `max_repair_attempts` times for the run
  - **When** the next `gate` fails
  - **Then** `status` becomes `aborted_repairs` (no silent infinite repair)

- [x] **Scenario: out-of-turn / forbidden writes are caught**
  - **Given** changes appear outside the current turn-holder's turn, or a `forbidden`/`human-gated` path is touched
  - **When** `squad.sh guard` runs
  - **Then** `status` becomes `aborted_conflict` (out-of-turn) or `aborted_policy` (forbidden path) — never silently accepted

- [x] **Scenario: symmetric initiation**
  - **Given** a human in a Codex session (or a Claude session)
  - **When** they start `/squad`
  - **Then** the initiating runtime owns the loop and drives the peer via the exec bridge (`claude-exec` from Codex; `codex-exec` from Claude) — no runtime is privileged

- [x] The deterministic core (`squad.sh`: state, turn-lock, budget, gate, terminal states, guard, rollback) is shell-unit-tested in `.agent0/tests/squad/`; the live multi-agent pump is exercised by a dry-run (stub peer + stub gate), with a real 2-agent dogfood as a separate cost-gated step.

## Non-goals

- The maximalist "infinite, 100% AI, human only at the very end" framing — explicitly rejected (see Intent).
- Autonomous **production** deploy — agents prepare; the human triggers prod.
- A third+ runtime in v1 — the protocol is N-ready but v1 is Claude↔Codex (orthogonal: `runtime-capabilities.md` § Future runtimes). The `/squad` (vs `/pair`) name future-proofs for it.
- Re-opening 149's deliberation design — `/squad` consumes it, does not change it.
- Replacing `/product` or SDD — `/squad` is the *implementation loop* that runs a spec the existing pipeline produced.

## Context / references

- **Etapa 1 dependency:** `docs/specs/149-deliberation-confirmation-bias/` (the de-biased deliberation mechanics `/squad` reuses — commit/reveal, claim/evidence gate, minority report).
- Building blocks: `.agent0/skills/{codex-exec,claude-exec}/` (symmetric write-capable bridges), `.agent0/skills/meeting/scripts/meeting.sh` (turn protocol), `.agent0/hooks/delegation-verify.sh` + `.agent0/validators/run.sh` (external oracle at close), `/verify`, `/goal` (`docs/specs/062-goal-skill/`), `/loop`.
- Safety lineage: `docs/specs/138-meeting-bounded-autopilot/` (bounded autopilot, demand-gated — `/squad` is the demand realized, carrying its bounded/gate-driven discipline), `.agent0/context/rules/artifact-budgets.md` (runaway circuit-breaker), governance-gate (destructive-op floor).
- This session's design conversation (the 3-flaw critique of the maximalist vision + the bounded/gate-driven reframe) is the seed; the `/sdd debate` on this spec runs the **spec-149 blind commit/reveal + claim/evidence flow** (dogfood).

## Resolution (decision-grade debate, 2026-06-04 — dogfooded the spec-149 blind/ledger flow)

Claude ↔ Codex authored openings **blind** (commit/reveal; hashes verified) and **converged independently** on the v1 cut; the claim/evidence ledger passed (8 claims, 0 assertion-only). Transcript + ledger: `.agent0/meetings/squad-v1-design-2026-06-04T17-48-21Z/meeting.md`.

**Resolved v1 cut:**
1. Full autonomous pump on ONE pre-planned spec (assisted = `--mode assisted` debug path, not the default).
2. New `.agent0/skills/squad/scripts/squad.sh` + file-backed run dir `.agent0/squads/<slug>-<ts>/`; initiating runtime owns the loop; symmetry via `codex-exec`/`claude-exec`.
3. Pump-enforced terminal states: `ready_for_human_prod` / `human_checkpoint_required` / `aborted_budget` / `aborted_repairs` / `aborted_conflict` / `aborted_policy`. Agreement only → "propose done"; the external gate closes the run.
4. v1 write model = turn-locked single-writer on one tree (worktree-per-agent + merge is v2); per-turn `git diff --stat` snapshot + refuse out-of-turn changes + rollback to last clean turn boundary.
5. Done-gate = executable contract `docs/specs/NNN/squad.yaml` (acceptance + `.agent0/validators/run.sh` + build/lint/typecheck + optional smoke + budgets + checkpoint cadence + forbidden/human-gated patterns). Spec = intent; squad.yaml = executable gate.
6. Supersedes spec 138's autonomous-loop concern (carries its bounded/gate-driven safety); unrelated to 091.
7. Hard round + token (+ wall-clock/spend) ceilings; exhaustion → circuit-break → partial-result + abort report.

**Spec-149 fast-follows surfaced by this dogfood (a `149.1` polish, not blockers):**
- `/sdd debate`'s `debate.md` has no YAML front-matter, so `meeting.sh commit/reveal/ledger <debate.md>` cannot run on it as-is — `/sdd debate` needs a front-matter shim or a sidecar transcript to literally invoke the 149 mechanics. (This dogfood used a decision-grade `/meeting` transcript, which IS meeting.sh-native.)
- A ledger claim containing a literal `|` corrupts the markdown-table column parse in `check-anchors` (the gate still passed; cosmetic).

Next: `/sdd plan 150`.
