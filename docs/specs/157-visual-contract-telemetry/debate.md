---
meeting: visual-contract-telemetry
roster: claude,codex,human
rotation: claude,codex
tier: decision-grade
blind_phase: revealed
turn_counter: 1
next_speaker: codex
synthesis: accepted
---

# 157 — visual-contract-telemetry — debate

_Created 2026-06-05._

<!-- The YAML front-matter above is meeting.sh machine-state (spec 149): it lets
`/sdd debate` run the de-biased mechanics — `meeting.sh commit|reveal|ab-map|ledger-add|ledger-check|check-anchors <debate.md>` — directly on this file. The `**Initiating agent:**` block below is the debate skill's human-readable role protocol; the two layers coexist. -->

**Initiating agent:** Claude Code
**Reviewing agent:** Codex CLI
**Initiated by:** Claude Code session 2026-06-05

Cross-model review of `spec.md` between two tool-calling CLI agents in separate sessions, each running its own port of `/sdd debate`. Both agents read and write **this file directly**; no copy-paste, no broker.

**Roles:** the agent that scaffolded this file is the `initiating agent` (named above); the other runtime, when first invoked against this file, becomes the `reviewing agent` and fills its identity into the metadata block. Each agent's port determines its role on every invocation by comparing the `**Initiating agent:**` metadata to its own runtime-identity literal.

**Orchestration:** the human alternates which runtime is active and decides when the debate ends. Each agent's turn: read this file, find the next empty placeholder belonging to its role (`initiating agent (position)` / `initiating agent (counter)` for the initiator; `reviewing agent (critique)` for the reviewer), write it, save. Then the human invokes the other runtime.

**Stop criteria:** human-decided. Default suggested cadence is ~3 rounds; the human asks either agent to "synthesize" when the disagreement is exhausted or the value diminishes. If more than 3 rounds are useful, append `## Round 4 — …` headers manually; the round-handling logic in both skills keys on placeholder presence, not round number.

**Audit trail:** this file IS the audit trail. Git-tracked alongside the spec. No separate state file.

**Anti-confirmation-bias (spec 149, decision-grade).** Round 1 SHOULD use the **blind commit/reveal** flow so the reviewer is not anchored on the initiator's position: each agent commits `sha256` of its independent opening via `meeting.sh commit`, and `meeting.sh reveal` publishes both only after both have committed (it refuses otherwise). Convergence is gated by the **claim/evidence ledger** (`meeting.sh ledger-add` / `ledger-check`): a point with only `assertion-only` claims is NOT resolved, regardless of agreement. The Synthesis records a **minority report** (any residual objection), never smoothed away. See `.agent0/context/rules/spec-driven.md` § debate and `meeting.md` § De-biased deliberation. _(Legacy position-first Round 1 below is the fallback when the blind flow isn't run.)_

---

## Round 1 — initiating agent (position)

_Pre-populated from `spec.md` key claims at scaffold time. Structure: intent (1 paragraph) → top 3 acceptance scenarios → top 3 open questions → "where the initiating agent wants pushback"._

_Decision-grade blind Round 1 (spec 149): the initiating agent's opening was committed-then-revealed, not written here. See § Blind submissions → Turn 1 (claude)._

---

## Round 1 — reviewing agent (critique)

_The reviewing agent reads this file, finds this slot empty, writes its critique directly. Should be concrete: name spec sections, quote unclear phrases, point to missing non-goals or weak acceptance scenarios._

_Decision-grade blind Round 1 (spec 149): the reviewing agent (Codex CLI) wrote its opening INDEPENDENTLY (not a critique of the initiator's position — neither saw the other before reveal). See § Blind submissions → Turn 2 (codex)._

---

## Round 2 — initiating agent (counter)

_The initiating agent addresses each critique point: accept (will change spec) / reject (with reasoning) / defer (open question)._

{{round 2 counter — initiating agent fills after reviewing agent writes critique}}

---

## Round 2 — reviewing agent (critique)

{{round 2 critique — reviewing agent writes directly, OR leave blank if user opted to synthesize}}

---

## Round 3 — initiating agent (counter)

{{round 3 counter — initiating agent fills if debate continues past round 2}}

---

## Round 3 — reviewing agent (critique)

{{round 3 critique — final reviewing-agent slot in the template; append Round 4+ headers manually if needed}}

---

## Blind submissions (commit/reveal)

_Commitments recorded before any opening is revealed — de-anchors round 1 (spec 149)._

- commit claude — `sha256:446ff7472b1a3588` (3887 bytes)
- commit codex — `sha256:658e25f573ca1134` (5897 bytes)

### Turn 1 — claude (blind opening) (claude)

**Position (claude, blind opening — spec 157 visual-contract-telemetry).**

**Intent as I read it.** Spec 155 deferred the visual-contract HARD gate behind a rule-of-three demand test ("advisories get ignored"), but that test is un-evaluable because the advisory prints to stderr and the delegation forensic row records nothing about the visual contract. The 2026-06-05 cognixse dogfood proved the gap concretely: 67 task closures + 6 verify-contract runs (render + flow, live app), totally uncorrelated. This spec adds a `visual_contract` field to the `subagent-verify` forensic row + a reader computing the advised-vs-evidence ratio — measure-first, gate-later, mirroring spec 138's friction signal.

**Top acceptance scenarios.** (1) A declared-UI task closure records its visual-contract status on the forensic row. (2) A non-UI closure is marked as such so the ratio's denominator stays honest. (3) A reader computes the ratio read-only and exits 0.

**Where I want hard pushback — I am NOT confident here:**

1. **Is this telemetry itself demand-justified, or is it speculative observability?** This is the load-bearing risk and I want Codex to attack it. Agent0's own rule (`feedback_speculative_observability`, spec 010 the abandoned case) says: no audit/forensics/measurement tooling without rule-of-three demand. My claim is this is *demand-pulled* — a single named, deferred decision (the 155 hard gate) needs exactly this number. But one deferred maybe-gate is arguably NOT three. Counter-argument to my own spec: we'd be building measurement infrastructure for a gate that the cognixse evidence already suggests may be *unnecessary* (the contract is used voluntarily). If the hard gate never gets built, the telemetry is dead weight. **Is the honest move to NOT build this, and instead just grep the two JSONL streams by hand the two or three times the question actually comes up?** A shell one-liner over `delegation-audit.jsonl` + the agent-browser audit, run on demand, might be the whole answer — zero shipped surface.

2. **The UI-detection is the single point of failure.** The telemetry is only as trustworthy as `delegation-verify.sh`'s ability to know "this closure was a UI task" — which (spec 155 D4) means scanning `transcript_path` for `UI impact:`/`verify-contract`. If that detection is fragile (it is a grep over free-form transcript text), the ratio is built on sand: false-negative UI detection silently shrinks the denominator and makes "everything looks fine" — the exact failure mode the hard gate exists to prevent, now reproduced in the telemetry. I want Codex to say whether a telemetry signal whose denominator is a fragile grep is worth recording at all.

3. **Codex cross-runtime blindness biases the signal.** Per `delegation.md` § Codex convention-only, Codex's `SubagentStart` carries no brief text, so a Codex-orchestrated dispatch can't detect UI-ness. The telemetry would therefore measure Claude closures only — a biased sample. Does a single-runtime signal even support a cross-runtime gate decision?

4. **No threshold = a number nobody acts on.** If the reader emits "37% of UI closures had no passing report" with no defined "this crosses into rule-of-three-met", it's decoration. But defining a threshold up front re-introduces the arbitrariness the measure-first posture was supposed to avoid.

**My genuine prior (argue me out of it).** I lean toward the spec being *correct in motivation but possibly over-built in form*: the right v1 might be the smallest possible thing — record the one boolean `evidence_present` on the forensic row for declared-UI closures, ship NO reader (a documented `jq` one-liner instead), and let the rule-of-three for the *reader itself* be demand-gated. Build the field; defer the tool. Pushback welcome — including "don't build the field either, just grep on demand."

Next: codex

### Turn 2 — codex (blind opening) (codex)

Position: reject spec 157 as written. The problem is real, but this is still too close to speculative observability: one dogfood window plus one deferred maybe-gate does not justify shipping a new reader surface and a ratio that rests on a fragile denominator.

The crux is in spec.md § Intent: "blocked-by-vibe forever" and "demand-pulled telemetry" overstate the case. Spec 155 and `.agent0/context/rules/visual-contract.md` deliberately made the hard gate future and dogfood-evidence-gated; they did not create an entitlement to build measurement infrastructure immediately. The 2026-06-05 `cognixse` slice is one concrete frustration, not a rule-of-three demand pattern. Before adding harness-propagated telemetry, the honest minimum is to run an on-demand analysis over the existing audit streams and transcripts the next 2-3 times the question arises, document exactly what could and could not be answered, and only then decide whether the missing field is a recurring bottleneck. A `jq`/shell recipe in notes or a one-off local analysis is lower ceremony than a synced tool.

The spec tries to dodge the anti-pattern by saying a text-first reader is "not an observability surface" (§ Non-goals: "A dashboard / daemon / metrics service"). I do not buy that distinction. This is still audit/forensics tooling: it adds persistent forensic-row fields and a reader that computes a governance signal. Being terminal-only does not make it non-observability. The relevant question is demand and reliability, not UI vs CLI.

The denominator is the load-bearing flaw. Acceptance says a non-UI closure with no `UI impact` declaration keeps the "denominator honest," but `.agent0/hooks/delegation-verify.sh` currently infers UI-ness by grepping free-form transcript text for `UI impact:` or `DONE_WHEN:.*verify-contract`. That is not a source of truth. `.agent0/context/rules/visual-contract.md` says declaration is the source of truth and detection only suggests; spec 157 would launder a transcript grep into a metric. False negatives are catastrophic: an undeclared UI task that closes without a contract disappears from the denominator, so the ratio gets better exactly when the process fails. This would measure "declared or command-mentioned UI closures," not "UI-producing closures."

Cross-runtime makes that worse. `.agent0/context/rules/delegation.md` says Codex is convention-only and `SubagentStart` carries no brief text, so there is no authoritative dispatch-time capture. If the proposed row relies on the stop transcript, Codex coverage is at best opportunistic. A ratio that silently aggregates Claude-observable closures with Codex-unmeasured closures cannot support a cross-runtime hard-gate decision. Any v1 telemetry must segment by runtime and treat Codex/unknown as `unmeasured`, never as non-UI.

Scope should shrink. I would not ship the reader in v1. If anything ships, it should be a narrow additive row field with explicit uncertainty, for example: detection source, observed declaration level, report path, report overall, and advisory emitted. No ratio, no threshold, no "rule-of-three signal" yet. Even that is only worth doing if the field records uncertainty honestly. A boolean `ui_producing` is actively dangerous unless it means "observed declared UI," not "this task truly produced UI."

Several acceptance criteria are too soft or misleading: "recording at least" leaves the schema open where the schema is the product. "whether the `visual-contract-advisory` fired" is ambiguous: delegation-verify has its own evidence advisory and also surfaces validator stderr; the spec does not say which advisory family is counted or how pre-validator stderr is captured. "non-UI closure is recorded as such" conflates absent declaration with non-UI work — it should be `unobserved` or `declared_none`, not non-UI. "reader computes the rule-of-three signal" lacks a precise numerator, denominator, unknown handling, runtime segmentation, and threshold.

The non-goal "Correlating a specific `verify-contract` run to a specific task" undercuts the motivating problem. If stale `report.json` can satisfy the row, the metric still does not answer whether the task actually drove the UI before closure.

Missing non-goals: no aggregation across consumers; no hard-gate recommendation from telemetry until capture coverage is proven; no treating unknown/unmeasured as compliant; no reader/threshold in v1; no stale report reuse as evidence.

Strongest alternative to my position: the spec 138 precedent is real. A tiny measurement can be the only way to make a deferred gate evaluable, and without persistence the next dogfood may again lose stderr-only advisory evidence. If the implementation is just one additive object on an existing row, with no new stream and no blocking behavior, the cost may be acceptable.

Evidence that would flip me: at least two more real consumer dogfoods where the hard-gate question is asked and an ad hoc analysis fails or costs enough time to matter; plus a manual audit showing transcript-based detection has acceptable precision/recall, or a design that captures declared UI at an authoritative point on both Claude and Codex. I would also soften if v1 explicitly records `unmeasured` and ships no reader.

Strongest objection to my critique: demanding rule-of-three evidence before adding the field may make the rule-of-three impossible to evaluate, because the current advisory vanishes. My answer is that this justifies, at most, preserving the raw advisory/evidence status with uncertainty. It does not justify a denominator, a ratio, or a reader that implies more epistemic confidence than the capture path has.

Confidence: high that the reader/ratio should not ship; medium that all row telemetry should defer, because stderr loss is a real gap.

## Claim/evidence ledger

_Convergence GATE: a point with only `assertion-only` claims is NOT resolved, regardless of agreement (spec 149)._

| claim | tag | anchor |
| --- | --- | --- |
| Whether to add the minimal forensic-row field NOW (claude: the stderr advisory vanishes otherwise) or DEFER even the field to jq-on-demand for 2-3 recurrences (codex: rule-of-three on the field itself) | unresolved | (none) |
| Shipping audit/measurement tooling without a rule-of-three demand test is a named Agent0 anti-pattern; one dogfood + one deferred maybe-gate is not three | supported | path:.agent0/context/rules/spec-driven.md |
| Codex SubagentStart carries no brief text, so the signal is Claude-biased; v1 must segment by runtime and treat Codex/unknown as unmeasured, never non-UI | supported | path:.agent0/context/rules/delegation.md |
| UI-detection is a grep over free-form transcript text, NOT a source of truth (the rule says declaration is source of truth, detection only suggests) — a false-negative shrinks the denominator so the ratio improves exactly when the process fails | supported | path:.agent0/hooks/delegation-verify.sh |
| Spec 155/visual-contract.md deliberately made the hard gate future + dogfood-evidence-gated; 157's 'demand-pulled / blocked-by-vibe forever' overstates that into an entitlement to ship telemetry now | supported | path:.agent0/context/rules/visual-contract.md |
## Synthesis

_Written when the human explicitly asks an agent to synthesize ("synthesize the debate", "wrap up"). Either agent can perform synthesis — whichever one the human asks. Lists what changes in `spec.md` and why; flags unresolved disagreements._

**Synthesizing runtime:** Claude Code (initiating agent), at the human's request.

**Protocol note.** Both openings were authored blind (commit/reveal, hashes verified). Neither agent saw the other before reveal — yet both independently rejected spec 157 as written, on the same grounds. Per spec 149 that agreement is *signal, not proof*; every convergent point below is anchored in the ledger to a deterministically-verified repo path (`ledger-check`: 4 anchored, 0 assertion-only; `check-anchors`: 4/4 `ok`).

**Resolution:** `converged` — on the core finding: **spec 157 as written is over-built and crosses toward the speculative-observability anti-pattern; it should NOT be implemented as drafted.** The narrower question (ship a minimal field now vs defer even the field) is the single recorded unresolved disagreement below.

### Proposed spec changes (if 157 proceeds in trimmed form)

- **§ Intent — de-overstate.** Drop "blocked-by-vibe forever" and "demand-pulled telemetry"; reframe as: *preserve the raw advisory/evidence status with honest uncertainty so future dogfoods can be analyzed at all* — NOT a demand-justified measurement system. (Ledger #1, anchor `visual-contract.md`.)
- **§ Acceptance — remove the reader + ratio + threshold entirely** (no reader tool in v1; Scenario 3 and the "rule-of-three signal" criterion deleted). If anything ships, it is a single additive `visual_contract` object on the existing `subagent-verify` row.
- **§ Acceptance — uncertainty-honest schema** (the schema IS the product, so pin it): `{ runtime, detection_source: transcript-grep|none, declared_level: render|interaction|flow|declared_none|unobserved, report_overall: pass|fail|null, advisory_emitted: {family, fired} }`. **`ui_producing: true` is never asserted as ground truth** — only "observed declared UI".
- **§ Acceptance — fix the conflation:** "non-UI closure recorded as such" → `declared_none` vs `unobserved`; absent declaration ≠ non-UI work. Disambiguate "advisory fired" by naming the family (the delegation-verify *evidence* advisory vs surfaced validator stderr).
- **§ Acceptance — runtime segmentation is mandatory:** Codex/unknown closures are `unmeasured`, never folded into the denominator as non-UI (Ledger #3, anchor `delegation.md`).
- **§ Non-goals — add:** no ratio/threshold/reader in v1; no cross-consumer aggregation; no hard-gate recommendation from telemetry until capture coverage is *proven*; never treat unknown/unmeasured as compliant; no stale `report.json` reuse as evidence.
- **§ Non-goals — surface, don't hide, the correlation limitation:** without joining the `agent-browser` audit to the task, the field records "a passing report existed at close", NOT "this task drove the UI before closing" — state this limitation explicitly (Codex: the current non-goal silently undercuts the motivating problem).

### Unresolved disagreement (the live point — neither anchor decides it)

- **Field-now (claude) vs defer-even-the-field (codex).**
  - *claude:* add the minimal uncertainty-honest field NOW — the spec-155 advisory prints to stderr and vanishes, so without persistence the next dogfood again loses the evidence; one additive object on an existing row, no new stream, no blocking, is cheap. Anchor: stderr-loss is real (155 D4 emits to stderr only).
  - *codex:* defer even the field — run a `jq`/shell analysis on-demand the next **2-3** times the hard-gate question actually arises, document what could/couldn't be answered, and only then add the field if it's a *proven recurring bottleneck*. Anchor: the rule-of-three demand discipline (`spec-driven.md`).
  - *Why unresolved:* no external anchor adjudicates "is preserving-vanishing-evidence worth a permanent shipped field before the gate is demanded." It is a judgment call the founder owns. (Ledger #5, `unresolved`.)

**Minority report (preserved verbatim — Codex):** *"Confidence: high that the reader/ratio should not ship; medium that all row telemetry should defer, because stderr loss is a real gap."* Codex's stronger position is that **even the minimal field is premature** and the honest v1 is zero shipped surface (jq-on-demand), graduating to a field only on proven recurrence.

**Convergence evidence (ledger gate):** the 4 convergent points are each anchored to a verified repo path (`visual-contract.md`, `delegation-verify.sh`, `delegation.md`, `spec-driven.md`); `ledger-check` = 0 assertion-only. The lone unresolved point rests on a founder judgment, not agreement, and is recorded UNRESOLVED — never "converged because both agreed".

### Recommended next step

**Do NOT graduate 157 to `/sdd plan` as written.** Two defensible dispositions, founder's call:
1. **Defer 157 (Codex's position + strict rule-of-three).** Mark `Status: deferred`; add a `jq`-on-demand recipe to the spec's notes; reopen only after 2-3 real recurrences where ad-hoc analysis fails or costs real time. Zero shipped surface now.
2. **Trim 157 hard (claude's position).** Rewrite to the single uncertainty-honest additive field above (no reader, runtime-segmented, `unmeasured`-explicit), ship that, and keep the reader/ratio/threshold deferred to their own demand test.

Given the founder's consistent rule-of-three discipline and that the cognixse evidence shows the contract being used *voluntarily* (weakening even the hard gate's premise), the debate leans **(1) defer** — but it is genuinely a judgment call.

---

## Applied changes

_Filled after user confirms the synthesis._

**Founder decision (2026-06-05): KILL the spec** — stronger than the synthesis's "lean defer". The trimmed-field path (claude) and the defer path (codex) were both rejected in favor of **no spec at all**: skip the telemetry entirely; let the spec-155 advisory stand; reopen by building the **hard gate directly** if the advisory's pain is felt in real use.

- `spec.md` — `**Status:** abandoned`; added `## Closure` (kill rationale + founder-stated reopen trigger + interim `jq`-on-demand recipe). No implementation; no `plan.md`/`tasks.md` filled.
- `debate.md` — kept verbatim as the design record (blind openings + anchored ledger + Codex minority report). This is the auditable "why we did NOT build it".
- No code shipped. The hard-gate design stays parked in `.agent0/context/rules/visual-contract.md` § hardening trajectory.
