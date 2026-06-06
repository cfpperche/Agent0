# 157 — visual-contract-telemetry

_Created 2026-06-05._

**Status:** abandoned — killed 2026-06-05 by the decision-grade `/sdd debate` (no replacement spec). See `## Closure`.

**UI impact:** none

## Closure

**Killed, not deferred** — founder decision 2026-06-05 after the decision-grade debate (`debate.md`). Both Claude Code and Codex CLI, in independent blind openings, concluded this spec is **over-built and premature** — it builds measurement infrastructure for a *maybe*-decision (the spec-155 hard gate), on an **unreliable signal** (UI-ness inferred by a transcript grep, whose false-negatives make the ratio look *better* when the process fails), with a **single-runtime blind spot** (Codex can't detect UI-ness at dispatch). It trips Agent0's own anti-pattern guard: no audit/measurement tooling without a rule-of-three demand test — and we have **one** dogfood frustration, not three.

**The decision (simpler than this spec):** skip the telemetry entirely. The spec-155 visual-contract advisory ships and earns adoption on its own (the 2026-06-05 cognixse dogfood already shows `verify-contract` — render **and** flow — being run *voluntarily* against a live app, which weakens the hard gate's "agents ignore it" premise in the first place).

**Reopen trigger (founder-stated):** *if the spec-155 advisory proves insufficient in real use — i.e. the founder feels the pain of UI tasks closing without driving the UI — come back to Agent0 and ask to build the visual-contract HARD gate **directly** (skipping this telemetry).* The hard-gate design is preserved in `.agent0/context/rules/visual-contract.md` § hardening trajectory (flow-first, `SubagentStop`-blocking, `visual-contract-exempt:` override).

**Interim answer if the question arises before then** — run this `jq` by hand over a consumer's logs (the debate's recommended on-demand alternative; zero shipped surface):

```bash
# UI-ish task closures (declared UI or verify-contract in the brief) — eyeball whether they carried a contract pass.
jq -c 'select(.event=="subagent-verify")' <consumer>/.agent0/delegation-audit.jsonl
# Cross-reference the same window's verify-contract runs:
jq -c '.' <consumer>/.agent0/.runtime-state/agent-browser/audit-*.jsonl
```

The full reasoning, the anchored claim/evidence ledger, and Codex's verbatim minority report live in `debate.md` — kept as the design record.

## Intent

Spec 155 deliberately shipped the visual-contract gate **advisory-only**, with hardening to a blocking gate explicitly deferred behind a rule-of-three demand test: *"dogfood evidence that advisories get ignored."* But that test is **currently un-evaluable** — the `visual-contract-advisory:` is printed to stderr and vanishes, and the delegation forensic row (`subagent-verify` in `.agent0/delegation-audit.jsonl`, written by `emit_verify_row()`) records `decision`/`validator_exit` but **nothing about the visual contract**. So "advisories get ignored" has no numerator and no denominator; the hard gate is blocked-by-vibe forever. The 2026-06-05 `cognixse` dogfood makes this concrete: that consumer logged **67 `subagent-verify` task closures** AND **6 `agent-browser verify-contract` runs** (render + flow tiers, against the live app on `localhost:3000`) in the same window — yet the two streams are **uncorrelated**, so we cannot answer the one question the hard-gate decision needs: *did UI-producing task closures actually carry a passing visual-contract, or did they close on static review?* This spec adds the **measurement** (a `visual_contract` field on the forensic row + a reader that computes the advised-vs-evidence ratio) so the hard-gate decision can be made from real data — mirroring how spec 138 added the `/meeting` autopilot-friction *signal* before any autopilot was gated. Measure first, gate later.

## Acceptance criteria

- [ ] **Scenario: a UI-task closure is recorded with its visual-contract status**
  - **Given** a delegated task whose brief declared `UI impact: render|interaction|flow` reaches `SubagentStop`
  - **When** `delegation-verify.sh` writes its `subagent-verify` forensic row
  - **Then** the row carries a `visual_contract` object recording at least: whether the brief was UI-producing, the declared level, whether the `visual-contract-advisory` fired, and whether passing evidence (`report.json .overall=="pass"`) was present

- [ ] **Scenario: a non-UI closure is recorded as such (denominator stays honest)**
  - **Given** a delegated task with no `UI impact` declaration (default `none`)
  - **When** its forensic row is written
  - **Then** the `visual_contract` field marks it non-UI (so the ratio's denominator counts only UI-producing closures, not all closures)

- [ ] **Scenario: the reader computes the rule-of-three signal**
  - **Given** a consumer's `delegation-audit.jsonl` with a mix of UI closures (some with evidence, some without)
  - **When** the reader tool runs over it
  - **Then** it reports the advised-vs-evidence ratio (UI closures that fired the advisory / closed without a passing report ÷ total UI closures), a short readout, and exits 0 — read-only, never gates

- [ ] Telemetry is **non-blocking and additive**: it never changes `delegation-verify.sh`'s exit code or decision; an absent/old row (no `visual_contract` field) is read as "unmeasured", not an error
- [ ] The capability ships harness-neutral under `.agent0/` (forensic-row writer + reader tool + a rule note), propagated by sync-harness; no `.claude/`-only dependency
- [ ] This spec does **not** introduce any hard gate — it only makes the existing advisory measurable (the hard-gate decision stays deferred, now evidence-able)

## Non-goals

- **Building the visual-contract HARD gate.** Out of scope by design — this spec produces the *evidence* the hard-gate decision needs, nothing more (spec 155 § hardening trajectory).
- **Changing the spec-155 advisory itself** (what fires, when). Telemetry observes the existing advisory; it does not alter its triggering.
- **A dashboard / daemon / metrics service.** A text-first reader over the JSONL, in the `status`/`doctor` tradition — not an observability surface (anti-drift: see `[[feedback_speculative_observability]]`).
- **Correlating a specific `verify-contract` run to a specific task** via the `agent-browser` audit log. v1 records the contract status *at the forensic row* (what `delegation-verify.sh` already checks per spec 155 D4); joining the two JSONL streams is a richer future step, not needed for the ratio.
- **Retroactively backfilling** the 67 pre-telemetry `cognixse` rows. The signal accrues from the next dogfood forward.

## Open questions

- [ ] **Exact `visual_contract` row schema.** Minimum viable field set: `{ ui_producing: bool, declared_level: none|render|interaction|flow|null, advisory_fired: bool, evidence_present: bool, report_overall: pass|fail|null }`? Is `report_overall` worth capturing vs just `evidence_present`? Owner: plan-time / debate.
- [ ] **How does `delegation-verify.sh` know the declared level + brief UI-ness at row-write time?** Spec 155 D4 already has it scan `transcript_path` for `UI impact:`/`verify-contract` in `DONE_WHEN`; reuse that exact detection, or is it too fragile to base telemetry on? Owner: debate (this is the load-bearing question — telemetry is only as good as the UI-detection).
- [ ] **Where does the reader live + what is its surface?** A standalone `.agent0/tools/visual-contract-telemetry.sh read`, or folded into `status.sh`/`doctor.sh`? What's the readout shape + does it name a (non-binding) threshold for "advisories are being ignored"? Owner: plan-time / debate.
- [ ] **Ratio definition.** Numerator = UI closures where advisory fired AND no passing report (the "ignored" case)? Or split into two ratios (declared-but-no-evidence vs undeclared-UI-surface)? What count crosses into "rule-of-three met"? Owner: debate.
- [ ] **Cross-runtime.** Codex's `SubagentStart` payload carries no brief text (per `delegation.md` § Codex convention-only), so Codex can't detect UI-ness at dispatch — does the telemetry degrade gracefully to "unmeasured" on Codex, or is there a Codex-side capture point? Owner: debate.

## Context / references

- **Motivating evidence:** 2026-06-05 `cognixse` audit — `.agent0/delegation-audit.jsonl` (67 `subagent-verify`, all `blocked`/`exhausted`) + `.agent0/.runtime-state/agent-browser/audit-2026-06-05.jsonl` (6 `verify-contract`: 4 render `contract-verify` + 2 `contract-flow` against `localhost:3000`/`/login`). The two streams are uncorrelated → the hard-gate signal is unmeasurable today.
- `docs/specs/155-visual-contract-acceptance-gate/` — the advisory this measures; § hardening trajectory (the deferred hard gate this unblocks), § Decisions D4 (the delegation-verify evidence check + the UI-detection this reuses).
- `docs/specs/138-meeting-bounded-autopilot/` (+ `/meeting friction` signal) — the precedent: ship the *measurement* of a demand-gated capability before the capability, so rule-of-three is evaluable from real artifacts.
- `.agent0/hooks/delegation-verify.sh` — `emit_verify_row()` (the forensic-row writer to extend) + the spec-155 declared-UI evidence check (the UI-detection to reuse).
- `.agent0/context/rules/visual-contract.md` — the rule to annotate with the telemetry + hardening-evidence pointer.
- `.agent0/memory/feedback_speculative_observability.md` — the anti-drift guard: this is demand-pulled telemetry (a named, deferred decision needs it), not speculative observability.
