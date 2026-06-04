# 149 — deliberation-confirmation-bias

_Created 2026-06-04._

**Status:** draft

## Intent

Refactor Agent0's two cross-model deliberation primitives — `/sdd debate` (`debate.md`) and `/meeting` (`meeting.md`) — to **minimize mutual-confirmation bias** between the LLM agents, so that "the agents converged" becomes a more trustworthy signal. This is the **prerequisite for the planned `/squad`** autonomous multi-agent build loop (Etapa 2): a squad whose done-condition leans on agent agreement is only as sound as the agreement is bias-resistant. Today both primitives have a **structural anchoring flaw**: the initiating agent writes its full position *first*, and the reviewing agent sees it *before* forming its own — so the reviewer is anchored from turn 1 (the exact setup the sycophancy/conformity literature flags). Combined with same-context exchange and identity-labeled turns, this biases toward premature convergence ("disagreement collapse") rather than genuine error-correction.

Web research (2026-06-04 — see § Context) on multi-agent-debate (MAD) failure modes converges on a consistent finding: **MAD does not reliably beat a single agent; when agents are similar or anchored, responses reinforce one another and majority/first-mover opinions dominate even when wrong; performance can *degrade* with more rounds; inter-agent sycophancy causes "disagreement collapse" before correctness.** The mitigations that work are **structural**, not persona-based — Agent0 rejected persona/role-prompting on research grounds (spec 074 / `[[feedback_no_persona_role_prompting]]`), so this spec adopts structural levers only. The v1 protocol below was **resolved via a web-backed `/sdd debate` with Codex** (`debate.md`) whose own conduct was structured to avoid the bias it studies (Codex produced an independent source-first ranking *before* seeing the initiator's recommendation — and it materially diverged, which is the wanted signal). The heterogeneous Claude↔Codex pairing is itself a bias advantage we preserve and require.

## Resolved v1 protocol (from the Codex debate — see `debate.md` § Synthesis)

The de-biased deliberation runs in this order; each stage maps to a concrete mechanism:

1. **Commit/reveal blind opening.** Each agent commits `sha256(opening_text + nonce)` (+ byte count) to the transcript *before* either reveals; critique unlocks only after both commitments exist and both texts are revealed and hash-verified. Removes turn-1 anchoring. (NOT "write to separate files" — same-repo files are not sealed; the peer can read them.)
2. **Structured critique on randomized `Proposal A/B` labels.** Judgment-surface anonymization + order randomization at critique/synthesis time; the durable transcript still attributes each turn to its runtime (audit trail preserved). A light add-on, not a pillar — second-order behind blind-round + heterogeneous models.
3. **Claim/evidence convergence GATE** (the load-bearing upgrade). Each convergence point is decomposed into claims, each tagged `supported | contradicted | unresolved | assertion-only` against an *external anchor* (citation / passing test / repro / file-read / explicit premise). **"assertion-only" never counts as resolved, regardless of agent agreement.** Where feasible, a deterministic anchor check (did the cited test actually run? does the cited path exist?) so the gate is not itself just another LLM assertion (mirrors spec 146's craft-floor: deterministic checks under the judge).
4. **Rubric-over-ledger synthesis + preserved minority report.** The synthesizer scores against the claim/evidence ledger (it does not re-adjudicate prose), and preserves an auditable **minority objection** rather than smoothing to consensus. The judge's own position/verbosity/self-preference bias is mitigated by anchoring it to the ledger, not free-form prose.

Turn-schema requirements (structural, not persona): **counterfactual-candidate-coverage** ("name the best alternative + the evidence that would make it win + the strongest objection to your preferred path" — replaces generic "mandatory dissent", which goes performative); **confidence-as-routing-signal-only** (low confidence / unsupported agreement triggers another adversarial pass; high confidence never counts as evidence).

Required & tiered: **heterogeneous models** (Claude↔Codex; single-model deliberation flagged bias-prone). **Full protocol** applies to `/sdd debate` and **decision-grade** `/meeting` (whose synthesis gates implementation, e.g. anything feeding `/squad`); **exploratory** `/meeting` takes a light subset (no forced commit/reveal per turn).

## Acceptance criteria

- [ ] **Scenario: commit/reveal blind opening de-anchors round 1**
  - **Given** a de-biased `/sdd debate` (or decision-grade `/meeting`) opens
  - **When** round 1 runs
  - **Then** each agent records a `sha256(opening+nonce)` commitment *before* any opening text is revealed; critique is blocked until both commitments exist and both openings are revealed and hash-verified; neither agent's opening was authored with the other's opening visible

- [ ] **Scenario: convergence is gated on external evidence, not agreement**
  - **Given** the agents agree on a point
  - **When** the convergence gate evaluates it
  - **Then** the point is decomposed into claims, each tagged `supported | contradicted | unresolved | assertion-only` against an external anchor; a point with only `assertion-only` claims is recorded **unresolved** regardless of agreement; where an anchor is mechanically checkable (a named test, a file path) the check is run rather than trusted

- [ ] **Scenario: judgment-surface anonymization, audit preserved**
  - **Given** the critique/synthesis stage
  - **When** an agent judges the peer's contribution
  - **Then** it sees randomized `Proposal A/B` labels (no "Claude said"/"Codex said"), while the durable transcript still attributes every turn to its runtime

- [ ] **Scenario: minority report is preserved, not smoothed**
  - **Given** synthesis with a residual objection from one agent
  - **When** the synthesis is written
  - **Then** it scores proposals against the claim/evidence ledger and records the minority objection verbatim as an auditable "fragile-convergence" signal (not dropped into a consensus narrative)

- [ ] **Scenario: turn schema enforces counterfactual coverage + confidence-as-routing**
  - **Given** any substantive turn
  - **Then** it carries the counterfactual-candidate-coverage fields and a confidence marker; low-confidence or unsupported agreement triggers an additional adversarial pass; high confidence is never counted as evidence

- [ ] **Scenario: tiered application**
  - **Given** an exploratory `/meeting` vs a `/sdd debate` (or decision-grade `/meeting`)
  - **Then** the full protocol (commit/reveal + gate + minority report) applies to the latter; the former takes the light subset; the tier is explicit, not implicit

- [ ] **Scenario: structural, not persona-based** — none of the mechanisms is a standing role-play identity ("be the skeptic"); all are protocol / turn-schema / anonymization / evidence-gate mechanisms, consistent with `[[feedback_no_persona_role_prompting]]`.

- [ ] The protocol was resolved via a web-backed cross-model `/sdd debate` (recorded in `debate.md`), structured to avoid the bias it studies (independent blind take first); both agents brought sources.

## Non-goals

- Building `/squad` — explicit **Etapa 2** (later spec), gated on this landing.
- Persona / role-prompting mitigations — rejected per `[[feedback_no_persona_role_prompting]]`.
- Erasing the transcript-as-audit-trail — anonymization is judgment-surface only; the durable record stays attributed.
- Autonomous (human-unpumped) deliberation looping — that is the `/squad` / spec-138 autopilot concern.
- Full anonymized parallel transcript system — rejected in the debate as overkill vs the audit requirement.
- Adding a third model runtime — orthogonal (`runtime-capabilities.md` § Future runtimes).

## Open questions

_Core design resolved in the Codex debate (`debate.md` § Synthesis); these remain for `/sdd plan`._

- [x] **Which mitigations + order** → resolved: the 4-stage bundle + turn-schema requirements above.
- [x] **Blind-first mechanism** → resolved: commit/reveal (`sha256(opening+nonce)`), not separate files.
- [x] **Anonymization vs audit** → resolved: judgment-surface relabel + order-randomization only; durable record stays attributed.
- [ ] **Exact deterministic-anchor-check scope** — which anchors are mechanically verified (test-ran, path-exists) vs trusted-as-cited. For `/sdd plan`.
- [ ] **`meeting.sh` / `debate.md.tmpl` schema changes** — how the commit/reveal phase, the A/B relabeling, and the claim ledger are represented in the files + driven by `meeting.sh`. For `/sdd plan`.
- [ ] **How the commit/reveal phase is human-orchestrated** in the file-mediated, one-writer-at-a-time model (who holds the nonce until both commit). For `/sdd plan`.

## Context / references

- Web research (2026-06-04), Claude + Codex:
  - MAD frameworks / failure modes — emergentmind.com (MAD doesn't reliably beat single agents; echo-chamber reinforcement; degradation with more rounds).
  - "Measuring and Mitigating Identity Bias in Multi-Agent Debate via Anonymization" — arxiv 2510.07517.
  - "Conformity in Large Language Models" — ACL 2025 (aclanthology 2025.acl-long.195).
  - "Peacemaker or Troublemaker: How Sycophancy Shapes Multi-Agent Debate" — arxiv 2509.23055.
  - "Good Arguments Against the People Pleasers" (reasoning reduces yet masks sycophancy) — arxiv 2603.16643.
  - "Confirmation Bias as a Cognitive Resource in LLM-Supported Deliberation" — arxiv 2509.14824.
  - "Counterfactual Debating with Preset Stances" — arxiv 2406.11514.
  - **Added by Codex:** social-influence collapses diversity — PNAS 10.1073/pnas.1008636108; Delphi/nominal-group structured independent judgment — Management Science 10.1287/mnsc.9.3.458; claim-level attribution/factuality — Google "Measuring Attribution in NLG" + FActScore (arxiv 2305.14251); LLM-as-judge position/verbosity/self-preference bias — MT-Bench (arxiv 2306.05685) + arxiv 2503.16814.
- Agent0 internals: `.agent0/skills/sdd/SKILL.md` (debate subcommand) + `templates/debate.md.tmpl`; `.agent0/skills/meeting/SKILL.md` + `scripts/meeting.sh` + `templates/meeting.md.tmpl` + `references/turn-prompt.md`; `.claude/skills/product/references/quality-judge.md` (independent-judge precedent); `docs/specs/146-product-craft-floor/` (deterministic-checks-under-the-judge precedent for the anchor check).
- `[[feedback_no_persona_role_prompting]]`; the 2026-06-03 OD-meeting `max_consecutive_model_turns=4` fast-convergence as a local instance of the bias.
- **Etapa 2 successor:** `/squad` (renamed from `/pair`) autonomous build loop — depends on this.
