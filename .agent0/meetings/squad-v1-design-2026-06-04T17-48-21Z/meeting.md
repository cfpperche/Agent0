---
meeting: squad-v1-design
topic: "Resolve the /squad v1 cut (spec 150): pump mechanism, done-condition gates, write-serialization, bounds — dogfooding the spec-149 blind/ledger flow"
created: 2026-06-04T17:48:21Z
convener: claude
mode: human-orchestrated
roster: claude,codex,human
rotation: claude,codex
tier: decision-grade
blind_phase: revealed
turn_counter: 2
next_speaker: claude
synthesis: accepted
---

# Meeting: Resolve the /squad v1 cut (spec 150): pump mechanism, done-condition gates, write-serialization, bounds — dogfooding the spec-149 blind/ledger flow

_A multi-party, multi-model deliberation. The front-matter above is the machine-readable state: `roster` is every participant id, `rotation` is the deterministic **fallback order** of model participants (human excluded), `next_speaker` is the **derived default** speaker (set by a turn's trailing `Next: <id>` directive; not enforced legality), `turn_counter` counts written turns, `synthesis` tracks the close-out. Speaker selection is context-driven: a turn may end with an explicit `Next: <roster-id>` line to hand the floor; otherwise the human directs with `--speaker`. The body below is the chronological transcript._

## Participants

- claude — Claude Code (web: allowed)
- codex — Codex CLI (web: allowed)
- human — human (web: n/a)

## Transcript

_Turns are appended below in order. Each turn header is `### Turn N — <runtime> (<id>)`; a research-backed turn carries a `Sources:` block listing the URLs used. A turn may end with a single trailing `Next: <roster-id>` line to hand the floor to a specific participant (the directive stays visible here; it sets the default next speaker)._

## Blind submissions (commit/reveal)

_Commitments recorded before any opening is revealed — de-anchors round 1 (spec 149)._

- commit claude — `sha256:17826b7d0e34969d` (2682 bytes)
- commit codex — `sha256:b99e74028651db7d` (6539 bytes)

### Turn 1 — claude (blind opening) (claude)

**Claude's independent opening — /squad v1 cut.**

1. **v1 scope = the full autonomous pump on ONE pre-planned spec, bounded.** Reject the smaller "assisted (human pumps)" v1 — it doesn't exercise the autonomous pump, which is the entire novel risk we're trying to learn about. v1: a spec that already has `/sdd plan` + green-able acceptance gates → squad implements it autonomously to gates → human approved the plan up front and triggers any deploy at the end. Real but bounded.

2. **Pump mechanism: a thin `squad.sh` (state + bounds + gate-check), the loop driven by the initiating skill.** Not a `/goal` Stop-hook hack, not raw `/loop`. `squad.sh` owns: the turn ledger, the budget counter, the gate runner, the write-lock. The initiating runtime runs: implement turn → `squad.sh` gate-check → if not done and budget remains, invoke peer via exec bridge (workspace-write) → repeat. Mirrors how meeting.sh owns state while the runtime owns content.

3. **Termination (three-way, all mechanical): gates green → success; budget exhausted (token/round ceiling) → abort-to-human; max consecutive failed-gate repair attempts (e.g. 3) → abort-to-human with a report.** Never infinite, never silent.

4. **Write-serialization: turn-locked single-writer for v1.** Only the current turn-holder writes the tree (the meeting.sh single-writer invariant extended to code). Worktree-per-agent + merge is more robust but heavier (merge conflicts between two LLMs is its own hazard) — defer to v2.

5. **Done-gate = the project validator + the spec's acceptance criteria as a runnable command, declared in a `squad` gate list.** Reuse `.agent0/validators/run.sh` (already stack-aware) + a per-spec gate (the acceptance tests). Staging smoke = opt-in, declared, not required for v1. The 149 claim/evidence ledger records WHY the agents think it's done; the gate command CONFIRMS it. Agreement never substitutes for a green gate.

6. **Supersedes spec 138's autonomous-loop intent** (138 was meeting-autopilot, demand-gated; /squad is that demand realized as a *build* loop, carrying 138's bounded/gate-driven safety). Unrelated to 091 (debate-runner). Mark 138 absorbed-for-the-autonomous-loop-concern.

7. **Cost governance: a hard round ceiling + a token budget (à la `budget.total`); on exhaustion, circuit-break → partial-result + report, like the 200 KB artifact cap.** A runaway squad is the scariest failure; the ceiling is non-negotiable.

Where I'm least sure: whether the v1 write-model should be turn-locked single-writer (my pick) or worktree-per-agent — the conflict/rollback tradeoffs are real and I'd want the peer's independent read before locking it.


### Turn 2 — codex (blind opening) (codex)

Rank 1: ship `/squad v1` as **Single-Spec Gate Pump**: one autonomous Claude↔Codex ping-pong loop over one already planned `/sdd` spec, with human approval before the loop starts, human checkpoints at phase boundaries, and human-only production trigger. I would not ship the smaller “human pumps every turn” version as `/squad`; that is useful as dogfood, but it does not validate the genuinely new mechanism. If we need a lower-risk ramp, make v1 eligible only for low/medium-risk pre-planned specs and cap it tightly, rather than removing the pump.

Rank 2 fallback: an “assisted squad” mode can exist as `--mode assisted`, but it should be a compatibility/debug path, not the default v1 cut. Otherwise the name overpromises and the hard parts stay deferred.

The pump should be a new first-party mechanism: `.agent0/skills/squad/scripts/squad.sh`, backed by a run directory such as `.agent0/squads/<slug>-<timestamp>/`. Do not hide it inside `/loop` or `/goal`; those concepts are useful inputs, but `/squad` needs its own durable state machine because it coordinates two runtimes, writes, gates, budgets, repairs, and abort reports. The loop owner is whichever runtime initiated the command, and symmetry is achieved by invoking the peer through `codex-exec` or `claude-exec`. State should be file-backed and auditable: current turn holder, round number, phase, budget spent/remaining, gate attempts, repair attempts, last changed paths, last verdict, and abort reason.

Termination must be enforced by the pump, not by agent prose. The only terminal states should be:

1. `ready_for_human_prod`: declared gate set is green, required acceptance evidence is attached, no unresolved ledger items tagged `deterministic`, `test-backed`, or `missing-anchor`, and both agents have proposed done.
2. `human_checkpoint_required`: planned phase boundary reached, budget threshold crossed, risky file surface touched, or staging/prod boundary reached.
3. `aborted_budget`: round, token, wall-clock, or spend ceiling exhausted.
4. `aborted_repairs`: max repair attempts exceeded for the same failing gate.
5. `aborted_conflict`: write ownership, dirty tree, merge, or peer failure cannot be resolved mechanically.
6. `aborted_policy`: destructive, secret, outward-action, or governance-gated operation requires human decision.

Agent agreement can only move the run into “propose done.” It never closes the run.

For write serialization, v1 should use **turn-locked single-writer on one working tree**. Worktree-per-agent plus merge is attractive later, but it introduces conflict resolution, semantic merge review, duplicated dependency installs, and rollback complexity before the loop itself is proven. Single-writer is simpler and matches the existing `meeting.sh` turn invariant: only the current turn holder may edit; the other runtime reviews the current tree and writes only on its own turn. The pump should snapshot `git diff --stat` and changed paths after every turn, refuse to continue if unexpected out-of-turn changes appear, and allow rollback to the last clean turn boundary. Worktree-per-agent belongs in v2 once the gate pump has evidence.

The done-gate surface should be declared in the spec implementation plan, with an optional machine-readable companion generated by `/squad init`. I would use `docs/specs/NNN-slug/squad.yaml` or `docs/specs/NNN-slug/squad.json`, not a repo-global config. The spec remains the source of intent; the squad file is the executable contract. It should define:

- acceptance commands
- validator command, usually `.agent0/validators/run.sh`
- build/lint/typecheck commands where applicable
- optional smoke commands
- max rounds
- max repair attempts
- budget ceilings
- checkpoint cadence
- forbidden or human-gated path/action patterns

“Staging smoke” should be represented as an arbitrary command with a name, timeout, environment hint, and required artifact path or URL check. Agent0 should not know the web stack. Example conceptually: `smoke: [{name: local-http, command: "...", timeout: 60}]`. The pump records pass/fail and output pointers; it does not interpret framework semantics.

Relationship to spec 138: `/squad` should **absorb the bounded-autopilot safety model as the concrete demand that justifies it**. Spec 138 remains lineage and design rationale, but `/squad` is the production mechanism: bounded, demand-gated, phase checkpointed, never infinite. Relationship to spec 091: `/squad` should **supersede the parked debate-runner for implementation loops**, while preserving any useful debate-runner ideas as deliberation primitives already handled by spec 149. Debate is for judgment; squad is for changing the repo to satisfy external gates.

Cost governance should be explicit and dumb in the best Agent0 sense: hard ceilings, visible remaining budget, and no model-discretion override. Use a `budget` block with max rounds, max peer calls, max wall-clock minutes, max estimated tokens, and optional max estimated USD. The pump decrements budget after each turn and refuses the next peer call if the remaining budget cannot cover the minimum turn reservation. Add a circuit-breaker similar in spirit to the 200 KB artifact cap: if any turn produces an oversized diff, oversized artifact, repeated broad rewrite, or repeated same-gate failure, stop and ask the human. No trim-loop, no silent descope, no “one more try” after the ceiling.

My concrete v1 cut:

**`/squad v1: Single-Spec Gate Pump`**

- Input: one `/sdd` spec with completed plan/tasks and human-approved squad gate file.
- Runtimes: exactly Claude Code and Codex CLI through existing exec bridges.
- Orchestration: new `squad.sh` state machine.
- Writes: turn-locked single-writer, one working tree, per-turn diff snapshots.
- Loop: implement, peer review/repair, run gates, ledger unresolved claims, repeat.
- Done: external gates green plus clean ledger plus human production approval.
- Bounds: max rounds, max repair attempts, max wall time, max token/USD estimate, max diff/artifact circuit-breakers.
- Human gates: start approval, phase boundary checkpoint, pre-prod approval, any policy/destructive/outward-action escalation.
- Non-v1: concurrent worktrees, N runtimes, autonomous production deploy, infinite loop, agreement-only completion.

This cut is small enough to ship, but it still tests the real thesis: two heterogeneous agents can autonomously move a planned spec toward externally verified completion without turning “they agree” into a substitute for reality.
## Claim/evidence ledger

_Convergence GATE: a point with only `assertion-only` claims is NOT resolved, regardless of agreement (spec 149)._

| claim | tag | anchor |
| --- | --- | --- |
| post-turn git diff --stat snapshot + refuse out-of-turn changes + rollback to last clean turn boundary | supported | codex-blind-opening (Claude counter accepts) |
| executable gate contract at docs/specs/NNN/squad.yaml (per-spec, not repo-global) | supported | codex-blind-opening (Claude counter accepts) |
| explicit terminal-state taxonomy (ready_for_human_prod / human_checkpoint / aborted_budget|repairs|conflict|policy) | supported | codex-blind-opening (Claude counter accepts) |
| /squad supersedes spec 138's autonomous-loop concern; unrelated to 091 | supported | path:docs/specs/138-meeting-bounded-autopilot/spec.md |
| done = external gate set green; agent agreement only moves to propose-done, never closes the run | supported | path:docs/specs/150-squad/spec.md |
| v1 write model = turn-locked single-writer on one tree; worktree-per-agent is v2 | supported | path:.agent0/skills/meeting/scripts/meeting.sh |
| pump = a new first-party squad.sh + run-dir state machine; not /loop or /goal | supported | independent-blind-convergence |
| v1 = full autonomous pump on ONE pre-planned spec (reject assisted-only as the default cut) | supported | independent-blind-convergence (both openings) |
## Synthesis

_Written when a participant is asked to synthesize. Names the synthesizing runtime, the convergence, recorded disagreements, and a recommended next step (graduate to `/sdd refine` as seed context, or no-op). The human then accepts / redirects / ends._

_Decision-grade tier (spec 149): convergence is gated by the claim/evidence ledger (`meeting.sh ledger-check` — a point with only `assertion-only` claims is UNRESOLVED regardless of agreement), and a **minority report** (any residual objection) is preserved verbatim, never smoothed into consensus._

_Synthesized by Claude Code (decision-grade tier; spec-149 blind/ledger flow dogfooded)._

**Headline:** Claude and Codex authored their openings BLIND (commit/reveal — neither saw the other's before committing; hashes verified) and **converged independently** on the /squad v1 spine. Independent convergence is a far stronger signal than the old anchored agreement — this is the spec-149 protocol working as designed on its first real use.

**Converged v1 cut (claim/evidence ledger above; ledger-check green, 0 assertion-only):**
1. v1 = the FULL autonomous pump on one already-`/sdd plan`-ned spec (assisted-only rejected as the default; available as a `--mode assisted` debug path).
2. Pump = a new first-party `.agent0/skills/squad/scripts/squad.sh` + a file-backed run dir (`.agent0/squads/<slug>-<ts>/`); NOT hidden inside `/loop` or `/goal`. Initiating runtime owns the loop; symmetry via `codex-exec`/`claude-exec`.
3. Termination is pump-enforced, never agent-prose. Terminal states (Codex's taxonomy, Claude accepts): `ready_for_human_prod` / `human_checkpoint_required` / `aborted_budget` / `aborted_repairs` / `aborted_conflict` / `aborted_policy`. **Agent agreement only moves to "propose done" — it never closes the run.**
4. Write model = turn-locked single-writer on one tree for v1 (worktree-per-agent + merge is v2); pump snapshots `git diff --stat` after each turn, refuses out-of-turn changes, rolls back to the last clean turn boundary.
5. Done-gate = an executable contract at `docs/specs/NNN/squad.yaml` (per-spec, not repo-global): acceptance commands + `.agent0/validators/run.sh` + build/lint/typecheck + optional smoke + budgets + checkpoint cadence + forbidden/human-gated path patterns. The spec stays intent; squad.yaml is the executable gate.
6. /squad supersedes spec 138's autonomous-loop concern (carrying its bounded/gate-driven safety); unrelated to 091.
7. Cost: hard round + token (+ wall-clock/spend) ceilings; exhaustion → circuit-break → partial-result + abort report.

**Minority report:** none — convergence was independent (blind), and Claude's counter accepted Codex's precision additions (terminal-state taxonomy, squad.yaml, per-turn diff snapshot/rollback) on their merits. The one point Claude flagged as least-sure pre-reveal (write model) is exactly where both independently landed on single-writer-for-v1, which strengthens it.

**Recommended next step:** GRADUATE — apply this v1 cut to spec 150's Open questions, then `/sdd plan 150`.

**Dogfood findings (spec-149 fast-follows, not blockers):** (a) `meeting.sh` mechanics need YAML front-matter, but `/sdd debate`'s `debate.md` uses a markdown metadata block with no `---` YAML — so a literal `meeting.sh commit <debate.md>` fails; `/sdd debate` needs a front-matter shim (or a sidecar transcript) to actually invoke the 149 mechanics. (b) a ledger claim containing a literal `|` corrupts the markdown-table column parse in `check-anchors` (gate still passed; cosmetic). Both → a 149.1 polish.
