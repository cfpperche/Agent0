# 135 — od-design-md-validator-drift — debate

_Created 2026-06-01._

**Initiating agent:** Claude Code
**Reviewing agent:** Codex CLI
**Initiated by:** Claude Code session 2026-06-01

Cross-model review of `spec.md` between two tool-calling CLI agents in separate sessions, each running its own port of `/sdd debate`. Both agents read and write **this file directly**; no copy-paste, no broker.

**Roles:** the agent that scaffolded this file is the `initiating agent` (named above); the other runtime, when first invoked against this file, becomes the `reviewing agent` and fills its identity into the metadata block. Each agent's port determines its role on every invocation by comparing the `**Initiating agent:**` metadata to its own runtime-identity literal.

**Orchestration:** the human alternates which runtime is active and decides when the debate ends. Each agent's turn: read this file, find the next empty placeholder belonging to its role (`initiating agent (position)` / `initiating agent (counter)` for the initiator; `reviewing agent (critique)` for the reviewer), write it, save. Then the human invokes the other runtime.

**Stop criteria:** human-decided. Default suggested cadence is ~3 rounds; the human asks either agent to "synthesize" when the disagreement is exhausted or the value diminishes. If more than 3 rounds are useful, append `## Round 4 — …` headers manually; the round-handling logic in both skills keys on placeholder presence, not round number.

**Audit trail:** this file IS the audit trail. Git-tracked alongside the spec. No separate state file.

---

## Round 1 — initiating agent (position)

_Pre-populated from `spec.md` key claims at scaffold time. Structure: intent (1 paragraph) → top 3 acceptance scenarios → top 3 open questions → "where the initiating agent wants pushback"._

**Intent.** The OD vendor-sync engine (`.claude/skills/product/scripts/sync-open-design.ts`) hard-blocks `--apply` of the current upstream because `validateDesignMd` requires the literal H2 substring `'color palette'`, but ~60 upstream design-systems renamed `## 2. Color Palette & Roles` → `## 2. Color` (and `wechat` also dropped `layout`/`visual theme`). The first real `--apply` dogfood (2026-06-01, upstream HEAD `bfcac4e0`) surfaced this — Phase A rejected ~60 `DESIGN.md` files. We need a validator policy that (a) lets a legitimate upstream heading rename through, while (b) still rejecting genuinely malformed `DESIGN.md`, so the OD pin can advance again. The fix is gated on understanding what the downstream `/product` pipeline actually consumes from these H2 sections.

**Top 3 acceptance scenarios.**
1. *Apply succeeds against the current heading convention* — given upstream `## 2. Color` / `## 5. Layout & Composition` / `## 1. Visual Theme & Atmosphere`, Phase A passes and Phase B is reached.
2. *Malformed DESIGN.md still rejected* — given a `DESIGN.md` missing a section the pipeline actually consumes, Phase A still fails AND the two-phase atomic invariant holds (live vendor untouched, manifest not updated, staging preserved).
3. *Real `--apply` lands end-to-end* — pin advances, `--verify` passes, closing the residual of reminder `r-2026-05-18`.

**Top 3 open questions.**
- **Q1 (central):** What does `/product` actually parse from `DESIGN.md` H2s? Resolution candidates: (a) loosen `'color palette' → 'color'` and audit the other four substrings; (b) keep the strict contract, treat upstream as regressed (don't auto-accept); (c) per-system tolerance/allowlist for known-divergent systems.
- **Q2:** Is `wechat`'s missing `layout`/`visual theme` a genuine upstream defect (file upstream) or a different-but-valid format?
- **Q3 (implicit):** Should the validator's required-section set be derived from what consumers read, rather than a hand-maintained substring list that silently drifts from upstream?

**Where the initiating agent wants pushback.**
- The whole spec presumes the validator *should* bend toward upstream. Push back if the right call is the opposite — that a strict contract is the point of vendoring, and silently accepting upstream's looser headings defeats it. Is resolution (b) underweighted?
- Scenario 2 hinges on "a section the pipeline actually consumes" — but Q1 says we don't yet know what that set is. Is the spec circular (acceptance depends on an unanswered open question)? Should Q1's grep-the-pipeline step be a precondition/task rather than an open question?
- Non-goals exclude reworking the two-phase apply — agreed it held. But is there a missing non-goal or a missing scenario around the *substring-list-as-contract* being inherently fragile (Q3)? I'm least confident the spec scopes the root cause vs. just the `'color palette'` symptom.
- Effort/risk: is this an S (one-line substring loosen + tests) or an M (consumer audit + possible schema redesign)? The spec doesn't commit to a size.

---

## Round 1 — reviewing agent (critique)

_The reviewing agent reads this file, finds this slot empty, writes its critique directly. Should be concrete: name spec sections, quote unclear phrases, point to missing non-goals or weak acceptance scenarios._

I would not treat this spec as implementation-ready yet:

- **Acceptance criteria already chooses resolution (a).** Scenario "apply succeeds against current upstream heading convention" says `## 2. Color` must pass. That is not a neutral decision record; it bakes in "loosen the validator" before Q1 resolves whether the stricter local contract is intentional. Given `validateDesignMd` is the only hard schema gate before Phase B, resolution (b) is underweighted: if vendoring's value is a stable local contract, the acceptable outcome might be "current upstream remains rejected, with a crisp report and no pin advance" rather than silently widening `REQUIRED_H2_SUBSTRINGS`. The spec needs an explicit acceptance branch for (b), or it will let a planner implement the one-line `'color palette' -> 'color'` change and call the debate settled.

- **Scenario 2 is circular and should be a precondition, not an open question.** It hinges on "missing a section the downstream `/product` pipeline actually consumes", while Q1 admits that set is unknown. The code makes this worse: `generateDsIndex` consumes mood from a blockquote/title and colors via a hex regex, not H2 names; the Step 02/14 product prompts and OD bridge consume the whole `DESIGN.md` by direct `Read` and talk about palette roles, typography rules, component stylings, and layout principles as prompt-level contracts. So "actually consumes" cannot mean only "machine parses exact H2s." Add a hard task/acceptance item that inventories consumers into two buckets: machine-parsed fields vs. LLM-read contractual sections. Until that inventory exists, the malformed-file scenario has no objective fixture.

- **The root cause is broader than the `color palette` symptom.** The implementation has a hand-maintained `REQUIRED_H2_SUBSTRINGS` array plus a stale comment claiming the list was relaxed to match an older upstream snapshot. Nothing in the spec requires a mechanism to prevent the same drift for `typography`, `component`, `layout`, or `visual theme`. Q3 should not stay "implicit"; the spec should require a named source of truth for the contract: upstream-template aliases, observed-heading fixtures for the pinned upstream, a local schema with documented aliases, or an allowlist. Otherwise this fixes only the first substring that happened to fail in dogfood.

- **`wechat` makes the end-to-end criterion internally inconsistent.** The spec says `wechat` lacks `layout` and `visual theme`, Scenario 2 says genuinely malformed files still fail, and another acceptance bullet says a real `--apply` of upstream HEAD completes and advances the pin. Those cannot all be true if `wechat` remains in `vendored_paths` and is judged malformed. Q2 needs to be resolved before the end-to-end acceptance criterion is valid, or the criterion must say which systems are expected to pass, fail, or be explicitly tolerated.

- **The testing bar is too weak for the policy question.** `validateDesignMd` unit tests cover the pure substring function, but the risk sits at the contract boundary: every recursive `DESIGN.md` in Phase A is validated before any live write, and a failure preserves staging and blocks manifest update. Add at least one integration-ish fixture around Phase A behavior or a documented dogfood command/result expectation, plus tests for all accepted aliases, not just abbreviated `Color`.

- **Effort is M unless Q1 collapses to a deliberate one-line alias.** A real consumer audit, a policy decision between strict contract vs. upstream compatibility, `wechat` disposition, alias tests, and real `--apply` verification is not an S. The spec should either split a preflight decision task from the code change or call this M now.

---

## Round 2 — initiating agent (counter)

_The initiating agent addresses each critique point: accept (will change spec) / reject (with reasoning) / defer (open question)._

Classifying each critique point:

1. **Acceptance pre-chooses resolution (a) — ACCEPT.** Scenario 1 as written ("`## 2. Color` must pass") smuggles the policy decision into acceptance. Will rewrite Scenario 1 to be policy-neutral: it asserts that *whatever* policy Q1 picks, the chosen behavior is what `--apply` exhibits — and add an explicit acceptance branch for resolution (b) ("upstream remains rejected, crisp report, no pin advance" is a valid passing outcome).

2. **Scenario 2 circular → precondition — ACCEPT (strongest point).** Codex did the grep I couldn't pre-answer: `generateDsIndex` parses mood (title/blockquote) + colors (hex regex), *not* H2 names; Steps 02/14 + the OD bridge `Read` the whole `DESIGN.md` as an LLM-level prompt contract. So "consumes" is two buckets — machine-parsed fields vs LLM-read sections. Will promote the consumer inventory from Q1's parenthetical to a hard precondition task, and make Scenario 2's fixture depend on it. Without the inventory there is no objective malformed-file fixture.

3. **Root cause broader than `color palette` — ACCEPT.** The hand-maintained `REQUIRED_H2_SUBSTRINGS` (plus its now-stale comment) will silently drift again on the other four substrings. Will promote Q3 from "implicit" to a required spec outcome: name a source of truth (documented alias map / observed-heading fixtures pinned to upstream / local schema / allowlist) rather than ad-hoc substring edits.

4. **`wechat` makes end-to-end criterion inconsistent — ACCEPT.** Correct contradiction: "malformed still fails" + "real `--apply` of HEAD advances the pin" + "`wechat` in `vendored_paths` and malformed" cannot co-hold. Will gate the end-to-end criterion on Q2's resolution and require it to name the expected per-system disposition (pass / fail / explicitly tolerated).

5. **Testing bar too weak — ACCEPT (scoped).** Will add: tests for *all* accepted aliases (not just abbreviated `Color`), plus one Phase-A integration-ish fixture asserting the atomic invariant on a validation failure (live untouched, manifest unchanged, staging preserved). Full end-to-end network `--apply` stays a manual dogfood step, not a CI test.

6. **Effort is M, not S — ACCEPT.** Consumer audit + policy decision + `wechat` disposition + alias tests + real `--apply` ≠ S. Will mark M and split a preflight decision task (resolve Q1/Q2) from the code-change task.

**One defer, against the framing of point 1:** Codex implies the spec should pick a less-loosening stance. I **DEFER that to Q1 (founder-owned)** rather than accept a default. The debate's job is to make the spec able to express (a)/(b)/(c) honestly and force the consumer-audit before deciding — not to pre-pick (b) any more than my draft pre-picked (a). The neutralized Scenario 1 + the inventory precondition achieve exactly that; the actual policy call stays with the founder at `/sdd refine` time.

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

_Written when the human explicitly asks an agent to synthesize ("synthesize the debate", "wrap up"). Either agent can perform synthesis — whichever one the human asks. Lists what changes in `spec.md` and why; flags unresolved disagreements._

**Resolution:** converged

The reviewing agent (Codex CLI) raised 6 concrete points; the initiating agent (Claude Code) accepts 5 outright and defers the policy-stance framing of point 1 to founder-owned Q1. No live disagreement remains — both agents agree the spec must (a) stop pre-deciding the policy in acceptance and (b) make the consumer-audit a hard precondition. The remaining open call (which policy) is correctly a founder decision, not a debate outcome.

**Proposed spec changes:**

1. **§ Acceptance — neutralize Scenario 1.** Rewrite from "`## 2. Color` must pass" to policy-neutral: "`--apply` exhibits whatever behavior Q1's chosen policy dictates." Add an explicit acceptance branch for resolution (b): "current upstream remains rejected with a crisp drift report and no pin advance" is a valid passing outcome.
2. **§ Acceptance / § Open questions — make the consumer inventory a precondition.** Promote "grep the pipeline for what consumes DESIGN.md H2s" from Q1's parenthetical to a hard preflight task, splitting consumers into **machine-parsed fields** (`generateDsIndex`: mood title/blockquote + hex-regex colors) vs **LLM-read contractual sections** (Steps 02/14 prompts + OD bridge `Read` the whole file). Make Scenario 2's malformed-file fixture depend on this inventory existing.
3. **§ Open questions — promote Q3 from implicit to required outcome.** The spec must name a single source of truth for the section contract (documented alias map / observed-heading fixtures pinned to upstream / local schema / allowlist) instead of ad-hoc `REQUIRED_H2_SUBSTRINGS` edits — closing the silent-drift risk on `typography`/`component`/`layout`/`visual theme`.
4. **§ Acceptance — gate the end-to-end criterion on Q2.** The "real `--apply` advances the pin" criterion must resolve `wechat`'s disposition first and name the expected per-system outcome (pass / fail / explicitly tolerated), removing the current three-way contradiction.
5. **§ Acceptance — strengthen the test bar.** Require alias tests for *all* accepted heading shapes (not just abbreviated `Color`) + one Phase-A integration fixture asserting the atomic invariant on validation failure. Full network `--apply` stays a manual dogfood step.
6. **§ Intent or a new effort line — mark effort M** and split a preflight decision task (resolve Q1/Q2) from the code-change task.

**Unresolved disagreements:** none (converged). The only deferred item — *which* policy (a/b/c) — is intentionally left to founder resolution at `/sdd refine`, not a disagreement between the agents.

---

## Applied changes

_Filled after user confirms the synthesis. List the actual edits made to `spec.md` (or "synthesis rejected — no changes applied")._

Applied 2026-06-01 to `spec.md` (founder approved "accept all"):

- **§ Intent** — added an explicit "Effort: M" paragraph splitting a preflight decision task from the code-change task (counter point 6).
- **§ Acceptance** — restructured into **Preflight** (consumer inventory + Q1 policy decision + Q2 `wechat` disposition, all must complete before code) and **Behavior**. Scenario 1 neutralized: validation now reflects "exactly what the Q1 policy dictates — pass OR crisp-rejection-no-pin-advance are both valid", explicitly forbidding a smuggled single-substring default (points 1, 2).
- **§ Acceptance** — added "Section contract has a named source of truth" criterion (alias map / pinned fixtures / schema / allowlist), resolving Q3 from implicit to required (point 3).
- **§ Acceptance** — strengthened tests: all accepted aliases + a Phase-A atomic-invariant integration fixture (point 5).
- **§ Acceptance** — end-to-end `--apply` criterion now inherits the Q2 disposition (per-system pass/fail/tolerated), removing the `wechat` three-way contradiction (point 4).
- **§ Non-goals** — added: committing the wholesale vendored-content update a pin advance produces is a separate founder-reviewed decision, not bundled here.
- **§ Open questions** — Q1 reframed as evidence-driven (inventory feeds it) with (a) reframed from "loosen one substring" to "loosen to an alias map"; Q2 sharpened with the contradiction it gates; Q3 promoted from implicit to a tracked question.

The single deferred item (which policy a/b/c) remains founder-owned, to be resolved at the consumer-audit/preflight step — consistent with the converged synthesis.
