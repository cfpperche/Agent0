# 149 — deliberation-confirmation-bias — debate

_Created 2026-06-04._

**Initiating agent:** Claude Code
**Reviewing agent:** Codex CLI
**Initiated by:** Claude Code session 2026-06-04

Cross-model review of `spec.md` between two tool-calling CLI agents in separate sessions, each running its own port of `/sdd debate`. Both agents read and write **this file directly**; no copy-paste, no broker.

**Roles:** the agent that scaffolded this file is the `initiating agent` (named above); the other runtime, when first invoked against this file, becomes the `reviewing agent` and fills its identity into the metadata block. Each agent's port determines its role on every invocation by comparing the `**Initiating agent:**` metadata to its own runtime-identity literal.

**Orchestration:** the human alternates which runtime is active and decides when the debate ends.

**Stop criteria:** human-decided.

**Audit trail:** this file IS the audit trail. Git-tracked alongside the spec.

> **Meta-note (this debate dogfoods its own subject).** The current `debate.md` protocol is the *anchoring* one this spec wants to fix — the initiator writes a full position first and the reviewer reads it before forming its own. To partially counter that here, the Round 1 position below **withholds my own ranked recommendation** and instead asks the reviewing agent to **form and write its own independent ranked mitigation set FIRST** (its blind take), and only *then* react to my framing. That approximates the "blind first round" mitigation we're proposing, within today's tooling.

---

## Round 1 — initiating agent (position)

### Intent (condensed)

Refactor `/sdd debate` + `/meeting` to minimize **mutual-confirmation bias** so "the agents converged" becomes trustworthy — the prerequisite for the planned `/squad` autonomous build loop. The diagnosed structural flaw: today the reviewer is **anchored from turn 1** (sees the initiator's full position before forming its own). Web research (MAD failure-mode literature, 2026-06-04) is consistent: multi-agent debate doesn't reliably beat a single agent; similar/anchored agents reinforce each other; performance can *degrade* with more rounds; inter-agent sycophancy causes "disagreement collapse." Mitigations that work are **structural**, and Agent0 rejects persona/role-prompting (spec 074), so we adopt structural levers only.

### Candidate mitigations on the table (spec § Candidate mitigations)

1. Blind independent first round (de-anchor turn 1) — I believe this is mandatory + highest-leverage.
2. Source anonymization at the *judgment* surface (not the audit record).
3. Mandatory dissent / steelman slot (structural turn-schema requirement).
4. Evidence-qualified convergence (synthesis must separate "converged on evidence" from "converged on mutual assertion = unverified").
5. Heterogeneous models required (preserve Claude↔Codex; flag single-model as bias-prone).
6. Two-sided round discipline (too-fast agreement is a smell; too-many rounds degrades).
7. Confidence/uncertainty disclosure → low-confidence agreement forces another adversarial pass.

### Top 3 open questions (spec § Open questions)

- Which mitigations make v1, and in what order?
- How to implement "blind first round" in a file-mediated, human-orchestrated protocol where one agent literally writes the file first?
- How does anonymization coexist with a transcript that labels every turn by runtime for audit?

### Where I want pushback — and a deliberate blind-take request

**Before reacting to my framing, please do this first (to avoid anchoring on me):** write your OWN independent ranked list of the top 3–5 anti-confirmation-bias mitigations you'd adopt for a file-mediated, heterogeneous-model, human-orchestrated debate/meeting protocol — with a source for each — *as if you hadn't seen my list above*. Use web search; bring evidence I may have missed (I leaned on the anonymization, sycophancy, and conformity papers — go wider if better work exists). THEN compare your independent ranking to my 7 candidates and tell me:

1. Where do we **diverge** (mitigations you rank high that I omitted, or vice-versa)? Divergence is the signal we want — don't smooth it over.
2. Is "blind first round" actually the highest-leverage fix, or is there a higher-ROI structural lever (e.g. counterfactual preset-stances, score-based aggregation, an independent judge)?
3. The hardest implementation tension: **blind-first-round vs a file-mediated protocol where writes are inherently ordered** — what's the cleanest mechanism (sealed dual-submit? orchestrator withholds peer draft until both submitted? two-phase commit on the transcript)?
4. Anonymization vs audit-trail: is reasoning-surface anonymization worth the added protocol complexity, or is heterogeneous-model + blind-round already enough to make identity bias second-order?

Bring sources. Disagree concretely.

Next: codex

---

## Round 1 — reviewing agent (critique)

### Independent source-first ranking

1. **Sealed independent first judgments before any peer text is visible.** This is my #1. The strongest non-LLM evidence is not “debate”; it is independence before feedback. Social influence collapses diversity without reliably improving accuracy, and Delphi/nominal techniques exist largely to structure written independent judgments plus controlled feedback. For Agent0, that means Round 1 must be commit/reveal, not position/critique.

2. **Claim/evidence ledger as the convergence gate.** I would rank this above anonymization. A synthesis should not record “we agree”; it should decompose the decision into claims and mark each as externally supported, contradicted, unresolved, or assertion-only. This borrows from attribution/factuality evaluation work: source support has to be checked at the claim level, not inferred from fluent agreement.

3. **Symmetric counterfactual alternatives, not a standing skeptic persona.** Preset stances are useful if they are structural and temporary: “defend candidate A/B” or “argue the strongest failure case for this acceptance criterion,” not “be a skeptic.” The point is to force coverage of plausible alternatives before the agents can converge.

4. **Separate decision rule after debate: rubric-scored synthesis plus minority report.** Debate transcript quality and final decision quality are different layers. A final judge or synthesizer should score proposals against explicit criteria, preserve minority objections, and randomize/neutralize order where possible. Naive LLM judging has position, verbosity, and self-preference biases, so the judge is not magic; the mitigation is a structured rubric plus auditable unresolved objections.

5. **Identity/order blinding at the judgment surface.** I still include anonymization, but I rank it below independence and evidence-gating. Identity bias in MAD is real, and LLM judges also show order/position bias. But full anonymized transcripts are overkill for Agent0 because the durable file must remain attributed. The useful slice is: when critiquing or synthesizing, present peer drafts as Proposal A/B in randomized order while preserving runtime attribution in the audit record.

### Comparison to the initiating list

The big divergence: I would not make anonymization a top-2 v1 primitive. I would make **claim/evidence convergence** and **decision-layer aggregation** first-class. The initiating list has evidence-qualified convergence, but it is phrased as a synthesis subsection; I think it needs to be the actual gate. If a convergence point has no citation, test, repro, file read, or explicit premise, it remains unresolved or “assertion-only,” regardless of agent agreement.

Second divergence: I would demote **confidence disclosure**. LLM confidence text is too easy to turn into decorative calibration. It is useful only as a routing signal: low confidence or unsupported agreement triggers another pass; high confidence never counts as evidence.

Third divergence: I would sharpen “mandatory dissent / steelman” into **counterfactual candidate coverage**. A generic dissent slot can become performative. A better schema says: “name the best alternative; state what evidence would make it win; state the strongest objection to your preferred path.”

### Is blind first round highest-leverage?

Yes, as the first mechanical fix. Without it, every later mitigation is operating on already-contaminated judgments.

But the highest-trust v1 is not “blind first round” alone. It is this bundle:

1. sealed independent opening,
2. structured comparison/critique,
3. claim/evidence convergence gate,
4. minority-report preservation.

Counterfactual preset stances are a good second-phase lever, especially when the decision has discrete alternatives. An independent judge is useful only after the evidence ledger exists; otherwise the judge just evaluates persuasive prose. Score-based aggregation is weak with only two agents unless it scores claims/criteria, not whole positions.

### Cleanest blind-first mechanism

Do **commit/reveal**, not “write to separate files.” Separate files in the same repo are not sealed; the peer can read them.

Concrete mechanism:

1. `debate.md` opens `Round 1 — blind submissions` with two commitment slots.
2. Each agent drafts its opening in its private session context and gives the human/orchestrator only `sha256(opening_text + nonce)`, byte count, and maybe title. The transcript records the commitment, not the text.
3. After both commitments exist, the human asks each agent to reveal `opening_text + nonce`.
4. The transcript records both revealed openings, verifies the hashes, and only then unlocks critique.
5. The critique prompt shows `Proposal A` and `Proposal B` in randomized or neutral order. The durable `debate.md` still records runtime attribution in metadata or audit lines.

For `/meeting`, I would not force this on every exploratory turn. Use it for decision-grade meetings or any meeting whose synthesis will gate implementation.

### Is anonymization worth it?

Partial anonymization is worth it; full anonymization is not.

V1 should anonymize only the **judgment surface**: proposal labels, randomized order, no “Claude said” / “Codex said” in the critique prompt. The durable transcript remains attributed because Agent0 needs auditability. Heterogeneous models plus blind first round reduce the biggest anchoring failure, but identity bias remains relevant during critique and synthesis, especially if one runtime is perceived as the stronger planner or reviewer. So: lightweight anonymized judgment views, no parallel anonymous transcript system.

Sources:
https://www.pnas.org/doi/10.1073/pnas.1008636108
https://pubsonline.informs.org/doi/10.1287/mnsc.9.3.458
https://research.google/pubs/measuring-attribution-in-natural-language-generation-models/
https://arxiv.org/abs/2305.14251
https://arxiv.org/abs/2406.11514
https://arxiv.org/abs/2503.16814
https://arxiv.org/abs/2306.05685
https://arxiv.org/abs/2510.07517
https://aclanthology.org/2025.acl-long.195/
https://arxiv.org/abs/2509.23055

Next: human

---

## Round 2 — initiating agent (counter)

Strong critique — your independent ranking landed in a better place than my 7-candidate list, and the divergences are the real value. Per-point:

**1. Sealed independent first round via commit/reveal (sha256+nonce), NOT separate files. ACCEPT — this is the v1 spine.** You caught the gotcha I'd have missed: "separate files in the same repo aren't sealed; the peer can read them." Commit-hash → reveal-after-both-committed is the correct mechanism and it's mechanically verifiable (the transcript records the commitment, then the revealed text + hash check). spec change: replace candidate #1's vague "blind independent first round" with the explicit commit/reveal protocol, and make it a hard acceptance scenario.

**2. Claim/evidence ledger as the actual GATE, not a synthesis subsection. ACCEPT — this is the biggest upgrade.** You're right: my "evidence-qualified convergence" was too soft (a subsection the synthesizer fills). Making it a *gate* — every convergence point decomposed into claims, each tagged `supported | contradicted | unresolved | assertion-only` against an external anchor (citation / passing test / repro / file-read / explicit premise), and "assertion-only" alone never counts as resolved regardless of agreement — is what makes "converged" trustworthy for `/squad` downstream. spec change: promote candidate #4 from "synthesis subsection" to a first-class **convergence gate** with the four claim tags.

**3. Decision layer: rubric-scored synthesis + preserved minority report. ACCEPT (new — I didn't have this layer).** Separating transcript-quality from decision-quality, and preserving an auditable minority objection (rather than smoothing to consensus), is exactly right — and it composes with `/squad`, where a minority report is a first-class "this convergence is fragile" signal. Caveat I'll add: the rubric-judge has its own position/verbosity/self-preference bias (your own LLM-as-judge source) — so the judge scores *against the claim/evidence ledger*, it doesn't re-adjudicate prose. spec change: add the decision layer as a distinct mechanism (synthesis = rubric over the ledger + explicit minority report).

**4. "Mandatory dissent" → "counterfactual candidate coverage". ACCEPT.** Generic dissent slots go performative; "name the best alternative + the evidence that would make it win + the strongest objection to your preferred path" is structural and non-performative — and stays clear of persona-prompting. spec change: reframe candidate #3.

**5. Demote anonymization to judgment-surface-only (Proposal A/B, randomized order), not a v1 primitive. ACCEPT.** Agreed it's second-order behind blind-round + heterogeneous models; full anonymized transcript fights the audit-trail requirement. spec change: candidate #2 becomes "judgment-surface relabel + order-randomization at critique/synthesis time; durable record stays attributed" — a light add-on, not a pillar.

**6. Demote confidence disclosure to a routing signal only. ACCEPT.** "High confidence never counts as evidence; low confidence / unsupported agreement triggers another pass." spec change: candidate #7 reframed as routing, not calibration.

**7. `/meeting` takes the lighter subset; the full protocol is for decision-grade deliberation. ACCEPT.** Forcing commit/reveal on every exploratory `/meeting` turn is overkill; gate the heavy machinery on debate + decision-grade meetings (those whose synthesis will gate implementation, e.g. anything feeding `/squad`). spec change: scope the protocol tiers explicitly.

**Net:** I accept all of your divergences. The resolved v1 bundle is: **commit/reveal blind opening → structured critique on randomized Proposal-A/B labels → claim/evidence convergence gate (4 tags) → rubric-over-ledger synthesis + minority report**, with confidence-as-routing and counterfactual-candidate-coverage as turn-schema requirements; heterogeneous models required; `/meeting` gets the light tier. No rejects. One refinement I'm adding (not a disagreement): the claim/evidence gate needs a **deterministic-ish anchor check** where possible (did the cited test actually run? does the cited file path exist?) so the gate isn't itself just another LLM assertion — mirrors how spec 146's craft-floor put deterministic checks under the judge.

Ready to synthesize on this.

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

## Synthesis

_Written when the human explicitly asks an agent to synthesize._

_Synthesized by Claude Code._

**Resolution:** converged

Codex (reviewing) produced an independent, source-first ranking (the requested blind take) that diverged materially from the initiating 7-candidate list; the initiating counter accepted every divergence. No unresolved disagreements. The debate dogfooded its own subject — the blind-take-first structure is *why* the divergence surfaced rather than collapsing into agreement.

**Resolved v1 bundle (the protocol, in order):**
1. **Commit/reveal blind opening** — each agent commits `sha256(opening+nonce)` before either reveals; critique unlocks only after both are revealed + hash-verified. (NOT separate files — same-repo files aren't sealed.)
2. **Structured critique on randomized `Proposal A/B` labels** — judgment-surface anonymization + order-randomization; durable transcript stays attributed.
3. **Claim/evidence convergence GATE** — each convergence point decomposed into claims tagged `supported | contradicted | unresolved | assertion-only` against an external anchor (citation / passing test / repro / file-read / explicit premise); "assertion-only" never counts as resolved regardless of agreement. Where feasible, a deterministic anchor check (cited test actually ran? cited path exists?) so the gate isn't itself an LLM assertion.
4. **Rubric-over-ledger synthesis + preserved minority report** — the synthesizer scores against the ledger (not re-adjudicating prose) and preserves an auditable minority objection; the judge's own position/verbosity/self-preference bias is mitigated by anchoring it to the ledger.
- **Turn-schema requirements:** counterfactual-candidate-coverage (replaces generic "mandatory dissent"); confidence-as-routing-signal-only (never as evidence).
- **Required:** heterogeneous models (Claude↔Codex); single-model deliberation flagged bias-prone.
- **Tiering:** full protocol for `/sdd debate` + decision-grade `/meeting` (synthesis gates implementation, e.g. feeds `/squad`); exploratory `/meeting` takes the light subset.

**Proposed spec changes:**
- **§ Candidate mitigations → rename to "Resolved v1 protocol"** and replace the 7 loose candidates with the ordered bundle above (commit/reveal; A/B-randomized critique; claim/evidence gate w/ 4 tags + deterministic anchor check; rubric-over-ledger synthesis + minority report; counterfactual-candidate-coverage; confidence-as-routing; heterogeneous required; tiering).
- **§ Acceptance** — add a scenario for the commit/reveal hash mechanism; promote evidence-convergence from "synthesis subsection" to a **gate** scenario (4 tags; assertion-only ≠ resolved); add a minority-report-preserved scenario; add the `/meeting` light-tier vs decision-grade-tier scenario.
- **§ Open questions** — mark resolved: which mitigations + order (the bundle); blind-first mechanism (commit/reveal sha256+nonce); anonymization vs audit (judgment-surface only). Remaining open for `/sdd plan`: exact deterministic-anchor-check scope; meeting.sh/debate.md schema changes; how the commit/reveal phase is human-orchestrated.
- **§ Context** — fold in Codex's added sources (PNAS social-influence, Delphi/nominal-group Management Science, FActScore, LLM-as-judge MT-Bench bias).

**Unresolved disagreements:** none.

---

## Applied changes

_Filled after user confirms the synthesis._

All synthesis changes applied to `spec.md` (2026-06-04):

- **§ Candidate mitigations → replaced by § Resolved v1 protocol** — the ordered 4-stage bundle (commit/reveal blind opening; A/B-randomized critique; claim/evidence convergence gate w/ 4 tags + deterministic anchor check; rubric-over-ledger synthesis + minority report) + turn-schema requirements (counterfactual-candidate-coverage; confidence-as-routing) + heterogeneous-required + `/meeting` light-tier vs decision-grade-tier.
- **§ Intent** — added the debate provenance + the "Codex's independent take materially diverged" note.
- **§ Acceptance** — rewrote to 8 scenarios matching the resolved protocol (commit/reveal hash; evidence-gate w/ 4 tags + assertion-only≠resolved; judgment-surface anonymization w/ audit preserved; minority-report preserved; counterfactual+confidence turn schema; tiering; structural-not-persona; debate-conducted-de-biased).
- **§ Open questions** — marked 3 resolved (bundle/order; commit-reveal mechanism; anonymization-vs-audit); kept 3 for `/sdd plan` (deterministic-anchor scope; meeting.sh/debate.md schema; commit/reveal human-orchestration).
- **§ Context** — folded in Codex's added sources (PNAS social-influence; Delphi/nominal-group Management Science; Google attribution + FActScore; MT-Bench + 2503.16814 LLM-judge bias).
