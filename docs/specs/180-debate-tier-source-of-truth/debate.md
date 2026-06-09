---
meeting: debate-tier-source-of-truth
roster: claude,codex,human
rotation: claude,codex
tier: decision-grade
blind_phase: revealed
turn_counter: 2
next_speaker: claude
synthesis: pending
---

# 180 — debate-tier-source-of-truth — debate

_Created 2026-06-09._

<!-- The YAML front-matter above is meeting.sh machine-state (spec 149): it lets
`/sdd debate` run the de-biased mechanics — `meeting.sh commit|reveal|ab-map|ledger-add|ledger-check|check-anchors <debate.md>` — directly on this file. The `**Initiating agent:**` block below is the debate skill's human-readable role protocol; the two layers coexist. -->

**Initiating agent:** Claude Code
**Reviewing agent:** {{reviewing agent name}}
**Initiated by:** Claude Code session 2026-06-09

Cross-model review of `spec.md` between two tool-calling CLI agents in separate sessions, each running its own port of `/sdd debate`. Both agents read and write **this file directly**; no copy-paste, no broker.

**Roles:** the agent that scaffolded this file is the `initiating agent` (named above); the other runtime, when first invoked against this file, becomes the `reviewing agent` and fills its identity into the metadata block. Each agent's port determines its role on every invocation by comparing the `**Initiating agent:**` metadata to its own runtime-identity literal.

**Orchestration:** the human alternates which runtime is active and decides when the debate ends. Each agent's turn: read this file, find the next empty placeholder belonging to its role (`initiating agent (position)` / `initiating agent (counter)` for the initiator; `reviewing agent (critique)` for the reviewer), write it, save. Then the human invokes the other runtime.

**Stop criteria:** human-decided. Default suggested cadence is ~3 rounds; the human asks either agent to "synthesize" when the disagreement is exhausted or the value diminishes. If more than 3 rounds are useful, append `## Round 4 — …` headers manually; the round-handling logic in both skills keys on placeholder presence, not round number.

**Audit trail:** this file IS the audit trail. Git-tracked alongside the spec. No separate state file.

**Anti-confirmation-bias (spec 149, decision-grade).** Round 1 SHOULD use the **blind commit/reveal** flow so the reviewer is not anchored on the initiator's position: each agent commits `sha256` of its independent opening via `meeting.sh commit`, and `meeting.sh reveal` publishes both only after both have committed (it refuses otherwise). Convergence is gated by the **claim/evidence ledger** (`meeting.sh ledger-add` / `ledger-check`): a point with only `assertion-only` claims is NOT resolved, regardless of agreement. The Synthesis records a **minority report** (any residual objection), never smoothed away. See `.agent0/context/rules/spec-driven.md` § debate and `meeting.md` § De-biased deliberation. _(Legacy position-first Round 1 below is the fallback when the blind flow isn't run.)_

---

## Round 1 — initiating agent (position)

_Pre-populated from `spec.md` key claims at scaffold time. Structure: intent (1 paragraph) → top 3 acceptance scenarios → top 3 open questions → "where the initiating agent wants pushback"._

_Superseded by the de-anchored blind flow (spec 149): see **Turn 1 — claude (blind opening)** under § Blind submissions. The position-first slot is intentionally not used because this debate ran decision-grade._

---

## Round 1 — reviewing agent (critique)

_The reviewing agent reads this file, finds this slot empty, writes its critique directly. Should be concrete: name spec sections, quote unclear phrases, point to missing non-goals or weak acceptance scenarios._

_The reviewing agent's (Codex CLI) critique arrived inside its blind opening — see **Turn 2 — codex (blind opening)** under § Blind submissions. Its four concrete critiques of `spec.md` are addressed in the Round 2 counter below._

---

## Round 2 — initiating agent (counter)

_The initiating agent addresses each critique point: accept (will change spec) / reject (with reasoning) / defer (open question)._

Addressing Codex's four critiques from its blind opening (Turn 2):

1. **ACCEPT — "blocked" is undefined; risks becoming a discretionary bypass under a formal name.** Strongest critique. The degraded gate must be *objective*: position-first is permitted ONLY after an attempted `meeting.sh commit`/`reveal` actually fails (binary missing, corrupted state, runtime cannot exec it) — not "I chose not to run the blind flow." Will add an acceptance scenario requiring the attempt-and-fail precondition, and word the `spec-driven.md`/`SKILL.md` edits as "attempted-and-failed," not "unavailable/blocked."

2. **ACCEPT — Intent vs acceptance contradiction risk (meeting.md owning BOTH tier model AND SDD mandate).** Correct, and it's a latent contradiction in my own spec wording. Resolution to bake into the target edits: `meeting.md` says it defines *the mechanics of the decision-grade tier*; `spec-driven.md` says *SDD decides that `/sdd debate` always uses that tier*. meeting.md must not assert the SDD-specific mandate. Will sharpen the Intent paragraph so it doesn't claim meeting.md "defines /sdd debate as decision-grade."

3. **ACCEPT — the "not full-confidence" mark needs a verifier-visible home + exact string.** Agreed; this resolves my own OQ1. Pin it: a required `debate-degraded:` line in the debate transcript AND a `**Resolution:** degraded`-style marker in the Synthesis metadata, so the degraded state can't be silently lost. Promote from open-question to acceptance criterion.

4. **ACCEPT (partial) — non-Claude ports could keep teaching the old fallback.** Fair. I won't port the *wording* into Codex/Cursor/Aider ports (they own those), but I'll add an acceptance check that no *shared/runtime-neutral* surface (the two rules + the symlink-shared SKILL.md) still teaches position-first as a discretionary tier. The non-goal stays for per-runtime *prose*; the no-new-contradiction check covers the shared surface.

On Codex's three pushback points:
- **(a) spec-driven.md owns SDD policy vs "meeting owns all tiers":** I hold spec-driven.md as policy owner. "meeting owns all tiers" would force meeting.md to encode an SDD-specific mandate, recreating the cross-domain coupling we're removing. DEFER the exact one-line boundary wording to plan time, but the ownership split is converged.
- **(b) should degraded mode exist at all, or hard-fail?** Genuine open tension — mirrors my own rule-of-three doubt (have we ever hit "meeting.sh unavailable"?). DEFER to an explicit Open question: "hard-fail vs degraded-with-label." Lean: degraded-with-objective-gate (Codex critique #1 makes it safe), but a hard-fail is defensibly cleaner for decision-grade doctrine. Decide at plan time.
- **(c) does consumer sync belong in this spec's acceptance?** ACCEPT — split it. The doctrine fix is local; propagation is a separate closeout. Will demote the "syncs cleanly to 3 consumers" criterion from acceptance to a post-ship closeout note.

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

- commit claude — `sha256:41266146a156ca31` (2570 bytes)
- commit codex — `sha256:ba4a4e82c1194f57` (3242 bytes)

### Turn 1 — claude (blind opening) (claude)

**Claude — blind opening (spec 180, debate-tier-source-of-truth)**

**Position.** The contradiction is real and the fix is a clean three-way assignment of ownership, not picking one file as "the source." Two distinct concerns are being conflated under the word "source of truth":

1. *Policy* — "is a `/sdd debate` always decision-grade?" → YES. This is **SDD governance doctrine** (what a `debate.md`'s existence *means*), so it belongs in `spec-driven.md`. Consumers inherit it; every runtime port (Codex/Cursor/Aider) must conform to it. A skill must never own this, because a skill is one port among many — a port owning cross-runtime doctrine is the exact drift vector the rule layer exists to neutralize.
2. *Mechanics* — "what does decision-grade rigor concretely require?" → blind commit/reveal + ledger + minority report. This belongs in `meeting.md` (the spec-149 owner). It should NOT re-assert the SDD mandate; it should point `/sdd debate`'s mandatory-tier back to `spec-driven.md`.

`SKILL.md` is then purely procedural and defers upward.

**The substantive bug** is `SKILL.md:170`: it keeps the legacy position-first Round 1 as a *discretionary* fallback "when the blind flow isn't run." If a debate is *always* decision-grade, a choosable lighter path cannot exist. Reclassify position-first as **degraded-mode-only** — permitted solely when `meeting.sh` mechanics are unavailable/blocked, emitting a `debate-degraded:` advisory and marking the synthesis as not full-confidence. It is a necessity path, never a convenience tier.

**Where I most want pushback (3 points):**
- Is `spec-driven.md` truly the right home for the *policy*, or is the cleaner split to keep BOTH the policy and a one-line tier definition in `meeting.md` and have `spec-driven.md` merely cite it? I argue spec-driven.md, but the boundary is debatable — the risk is two rules both feeling authoritative.
- Should the degraded path still *attempt* the ledger/minority-report (partial de-bias), or is a half-decision-grade artifact worse than an honestly-labeled non-decision-grade one (false confidence)?
- Is introducing a `debate-degraded:` token over-engineering? A rule-of-three test: have we ever actually hit "meeting.sh unavailable" in practice, or is this a fallback for a failure mode that doesn't occur — in which case the honest fix is to *delete* the position-first path entirely rather than ceremonially label it.

**Anti-goal I want held:** do not introduce a real `--tier light` for `/sdd debate`. `light` stays exclusive to exploratory `/meeting`.


### Turn 2 — codex (blind opening) (codex)

**Position** — `spec-driven.md` should own the policy because `/sdd debate` is part of the SDD lifecycle, and the policy question is "what does it mean when an SDD spec elects to run debate?" `meeting.md` should own reusable decision-grade mechanics because blind commit/reveal, ledger checks, and minority reports are shared by `/meeting` and `/sdd debate`. The skill should own execution choreography only: role detection, scaffold behavior, turn slots, and the exact command path into `meeting.sh`.

I would resolve the contradiction by making "debate is always decision-grade" mean: once `/sdd debate` is invoked on a spec, the normal path must enter the blind commit/reveal flow before any agent reads the peer's opening. The position-first Round 1 should remain only as degraded recovery, not as an alternate tier and not as a convenience fallback. Its gate should be objective: `meeting.sh` missing, refusing due corrupted state, or unusable in the current runtime after an attempted command. The fallback belongs in the skill because it is procedural recovery, but `spec-driven.md` should state the doctrine-level consequence: degraded debate is labelled and cannot be cited as full-confidence decision-grade evidence.

**Strongest critique of the spec as written** — The spec says degraded mode is allowed when "`meeting.sh` mechanics are unavailable/blocked", but it does not define what counts as blocked. Without an acceptance scenario requiring an attempted `meeting.sh commit` or a concrete failure condition, this can degrade into the same discretionary bypass under a more formal name.

The acceptance scenario "SDD doctrine has one home" says `spec-driven.md` is the "sole source of the policy", but the Intent still says `meeting.md:85-87` "defines `/sdd debate` as decision-grade." The target wording must avoid creating a new contradiction where meeting owns both the general tier model and an SDD-specific mandate. I would require `meeting.md` to say it defines the mechanics of the decision-grade tier, while SDD decides that `/sdd debate` always uses that tier.

The "SKILL.md defers and reclassifies the fallback" scenario asks degraded use to "marks the synthesis as not full-confidence decision-grade", but no acceptance criterion says where that mark lives or what exact string is verifier-visible. Put this in `debate.md` synthesis metadata or a required `debate-degraded:` transcript line; otherwise the state is easy to lose.

The non-goal "Porting the wording change into non-Claude skill ports" is risky. If Codex/Cursor/Aider ports conform to the rule, the acceptance should at least require no new contradiction in shared/runtime-neutral surfaces. Otherwise the source-of-truth fix could leave operational ports still teaching the old fallback.

**Where I most want pushback** — First, whether `spec-driven.md` should own only SDD policy, or whether a shorter "meeting owns all tiers" model would reduce future drift. Second, whether degraded mode should be allowed at all; a hard fail may be cleaner for decision-grade doctrine. Third, whether consumer sync belongs in this spec's acceptance, since the policy contradiction can be fixed locally while propagation may deserve a separate closeout step.

## Claim/evidence ledger

_Convergence GATE: a point with only `assertion-only` claims is NOT resolved, regardless of agreement (spec 149)._

| claim | tag | anchor |
| --- | --- | --- |
| position-first Round 1 is degraded-mode gated by an OBJECTIVE meeting.sh failure (attempted-and-failed), never discretionary convenience | supported | Codex blind opening (Turn 2): 'blocked' must be defined as attempted meeting.sh commit + concrete failure, else it becomes the same bypass under a formal name |
| SKILL.md must NOT be the source of the doctrine — a skill is one runtime port and owning cross-runtime policy is a drift vector | supported | runtime-capabilities.md: skills are symlink-shared byte-identical across ports; both Claude and Codex independently reached this in blind openings (Turn 1 + Turn 2) |
| meeting.md owns the decision-grade MECHANICS (blind commit/reveal, ledger, minority report), not the SDD-specific mandate | supported | meeting.md:85-87 already defines the light/decision-grade tier model + meeting.sh as the mechanics owner |
| spec-driven.md owns the SDD policy 'a /sdd debate, when run, is always decision-grade' | supported | CLAUDE.md: rules are provider-neutral doctrine inherited by consumers + ports conform; SKILL.md description self-defers to spec-driven.md for when-SDD-applies |
## Synthesis

_Written when the human explicitly asks an agent to synthesize ("synthesize the debate", "wrap up"). Either agent can perform synthesis — whichever one the human asks. Lists what changes in `spec.md` and why; flags unresolved disagreements._

**Resolution:** converged

Both runtimes independently (blind) reached the same ownership split: `spec-driven.md` = SDD *policy*, `meeting.md` = decision-grade *mechanics*, `SKILL.md` = execution choreography only, and position-first = degraded recovery (not a tier). All four ledger claims are `supported` (0 assertion-only). Codex's four critiques are accepted and fold into spec edits; three pushback points become explicit Open questions / scope splits rather than unresolved disagreements.

**Proposed spec changes:**

- **§ Intent** — sharpen so it does NOT say "`meeting.md:85-87` defines `/sdd debate` as decision-grade." Reword to: meeting.md defines *the mechanics of the decision-grade tier*; `spec-driven.md` (SDD) decides `/sdd debate` always *uses* that tier. (Codex critique #2)
- **§ Acceptance** — add a scenario making the degraded gate *objective*: position-first is permitted only after an *attempted* `meeting.sh commit`/`reveal` actually fails; replace "unavailable/blocked" wording with "attempted-and-failed" throughout. (Codex critique #1)
- **§ Acceptance** — promote the "not full-confidence" mark from open-question to a criterion with a concrete home + string: a required `debate-degraded:` transcript line AND a degraded marker in the Synthesis metadata. (Codex critique #3)
- **§ Acceptance** — add a "no shared-surface contradiction" check: the two rules + the symlink-shared `SKILL.md` must not teach position-first as a discretionary tier (the per-runtime *prose* port stays a non-goal). (Codex critique #4)
- **§ Acceptance** — demote "syncs cleanly to 3 consumers" from acceptance to a post-ship closeout note (propagation ≠ the doctrine fix). (Codex pushback c)
- **§ Open questions** — add "hard-fail vs degraded-with-label for the unavailable case" (Codex pushback b); keep the `debate-degraded:` emit-point question only insofar as plan-time wording, since acceptance now pins its existence.

**Unresolved disagreements:** none (converged; open tensions captured as explicit Open questions, not disagreements).

**Minority report:** (preserved verbatim — a residual objection from either agent is an auditable "fragile-convergence" signal, NOT smoothed into consensus; "none" if there is none)

- **Codex (residual, pushback b):** a *hard-fail* when `meeting.sh` is unavailable may be cleaner for decision-grade doctrine than any degraded-with-label path — the degraded path, even objectively gated, still ships a lower-confidence artifact under the decision-grade banner. Not resolved in favor of degraded; carried as a live Open question for plan time, not smoothed into "degraded is fine."

**Convergence evidence (ledger gate):** each "converged" point above is backed by an external anchor (citation / passing test / repro / file-read / explicit premise), not bare agreement — run `meeting.sh ledger-check` if a ledger was kept. Points resting on agreement alone are recorded UNRESOLVED.

---

## Applied changes

_Filled after user confirms the synthesis. List the actual edits made to `spec.md` (or "synthesis rejected — no changes applied")._

All 6 proposed changes applied to `spec.md` (2026-06-09):

- **§ Intent** — reworded: `meeting.md` defines the *mechanics* of the decision-grade tier; SDD (`spec-driven.md`) decides `/sdd debate` always *uses* it; degraded gate reworded to "attempted-and-failed `meeting.sh`".
- **§ Acceptance** — "meeting.md owns mechanics" scenario: added the explicit "must NOT assert the SDD mandate itself" clause.
- **§ Acceptance** — added scenario "degraded mode has an objective gate (not discretion)" (attempted-and-failed).
- **§ Acceptance** — added scenario "degraded state is verifier-visible with a fixed string" (`debate-degraded:` line + Synthesis marker).
- **§ Acceptance** — added "no shared-surface contradiction" criterion; demoted the consumer-sync criterion to a new **§ Post-ship closeout** (not acceptance).
- **§ Open questions** — added "hard-fail vs degraded-with-label" (the preserved minority report) with a rule-of-three check; reframed the `debate-degraded:` OQ to emit-mechanics-only since its existence is now a criterion.
