# 149 — deliberation-confirmation-bias — plan

_Drafted from `spec.md` on 2026-06-04 (intent locked via the Codex debate). Update if implementation reveals the plan is wrong._

## Approach

Implement the resolved v1 protocol (commit/reveal blind opening → A/B-randomized critique → claim/evidence convergence gate → rubric-over-ledger synthesis + minority report) as **shared mechanics in `meeting.sh`**, then have BOTH `/meeting` and `/sdd debate` consume them. Today there are two turn engines: `/meeting` is driven by the `meeting.sh` state machine (front-matter header + `append-turn`/`advance`/`resolve-speaker`), while `/sdd debate` is prose-only (the skill manages `debate.md` slots by placeholder presence, no script). The anti-bias machinery (hash commit/reveal, A/B label mapping, claim-ledger schema, tier) is identical for both, so it belongs in `meeting.sh` as new subcommands; the debate skill calls the same script rather than re-implementing the protocol in prose. This unifies the two engines on the bias-critical path and keeps the logic testable (shell, like the existing `meeting.sh`/`delegation-gate` suites).

Build order (each independently testable): (1) commit/reveal in `meeting.sh` + state schema; (2) claim/evidence ledger schema + the synthesis-gate check; (3) A/B label mapping at the judgment surface; (4) turn-schema requirements (counterfactual-coverage, confidence-as-routing) in `turn-prompt.md` + the debate template; (5) tiering (`light` vs `decision-grade`); (6) wire `/sdd debate` to the shared mechanics; (7) tests + docs (rules). The deterministic anchor-check (does the cited test run / path exist) is scoped minimally in v1 — a `check-anchors` helper that verifies file-path and "named test exists" anchors, leaving "re-run the test" as a documented v2 (keeps blast radius small; mirrors spec 146's deterministic-checks-under-the-judge).

## Files to touch

**Modify (mechanics):**
- `.agent0/skills/meeting/scripts/meeting.sh` — new subcommands: `commit --speaker <id> --hash <sha256> --bytes <n>` (records a blind commitment row, no text); `reveal --speaker <id> --text-file <f> --nonce <n>` (verifies `sha256(text+nonce)` == committed hash, then writes the opening; unlocks critique only when all commitments revealed); `ab-map <file>` (emit a randomized Proposal-A/B ↔ runtime mapping for the judgment surface, recorded in an audit line); `ledger-add`/`ledger-check` (claim rows with `tag` ∈ {supported,contradicted,unresolved,assertion-only} + `anchor`); `check-anchors <file>` (deterministic: cited path exists? named test present? — v1 scope); `init --tier light|decision-grade`. Reuse existing front-matter helpers.
- `.agent0/skills/meeting/templates/meeting.md.tmpl` — add the blind-submission (commit/reveal) round-0 block, the claim-ledger section, the minority-report slot in synthesis; gated by tier.
- `.agent0/skills/meeting/references/turn-prompt.md` — peer prompt carries: Proposal-A/B anonymized view (no "Claude said"), counterfactual-candidate-coverage fields ("best alternative + evidence that would make it win + strongest objection to your own path"), confidence marker (routing-only, never evidence).
- `.agent0/skills/meeting/SKILL.md` — orchestration: tier selection; the commit→reveal→critique phase ordering; how the human pumps the blind phase (collect both commitments before any reveal).
- `.agent0/skills/sdd/SKILL.md` (`debate` subcommand) — re-point the debate protocol at the shared `meeting.sh` mechanics for commit/reveal + ledger + minority report (debate is always `decision-grade`).
- `.agent0/skills/sdd/templates/debate.md.tmpl` — restructure Round 1 to the blind commit/reveal shape (replaces "initiator writes position first, reviewer reads it"); add claim-ledger + minority-report to synthesis.

**Modify (rules/docs):**
- `.agent0/context/rules/meeting.md` — document the de-biased protocol, the tiers, and why (cite the research + the debate).
- `.agent0/context/rules/spec-driven.md` § debate — document the commit/reveal + ledger.

**Create (tests):**
- `.agent0/tests/deliberation-bias/` — commit/reveal hash verify (good hash unlocks; tampered text fails reveal); A/B mapping is order-randomized but audit stays attributed; ledger gate (assertion-only ≠ resolved); `check-anchors` (missing path flagged); tier gating (light skips commit/reveal). Plus `bash -n`/shellcheck.

## Alternatives considered

### Implement the protocol twice (in the debate skill prose AND meeting.sh) instead of unifying
Rejected: the bias-critical mechanics (hash verify, ledger tags, A/B mapping) must behave identically in both, and prose-only logic is untestable + drifts. Unifying on `meeting.sh` gives one tested implementation; the cost is wiring `/sdd debate` to call a script it currently doesn't.

### "Orchestrator withholds peer draft" (no hash) instead of commit/reveal
Lighter, but the debate explicitly rejected it: without the hash commitment there's no tamper-evidence that an agent didn't revise its opening after glimpsing the peer's. The `sha256(opening+nonce)` commit is cheap and makes the blind phase auditable. Keep commit/reveal; the withhold is the degraded fallback when an agent can't compute a hash.

### Full anonymized parallel transcript
Rejected in the debate — fights the audit-trail requirement. Anonymization is judgment-surface only.

### Re-run cited tests inside the anchor check (v1)
Deferred to v2 — re-running arbitrary cited commands is a blast-radius + sandbox concern. v1 checks cheap, safe anchors (path-exists, named-test-present); "re-ran green" is a documented future.

## Risks and unknowns

- **Human-orchestration of the blind phase** — in a human-pumped flow the human must collect BOTH commitments before triggering either reveal; if they reveal A before B commits, the blindness is lost. Mitigation: `meeting.sh reveal` refuses until all commitments are present (mechanical guard, not discipline).
- **Secret-keeping between commit and reveal** — the agent's opening must live somewhere the peer's prompt never includes (a gitignored `.agent0/.deliberation-state/` scratch, or the agent's own session context). The orchestrator must not leak it into the peer prompt. Needs a clear convention + the prompt-builder honoring it.
- **Wiring `/sdd debate` to a script** — debate is currently script-free; adding a `meeting.sh` dependency changes its portability story (Codex must run the same script — it can, `meeting.sh` is runtime-neutral shell, already used by `/meeting` on both runtimes). Confirm parity.
- **Ledger overhead** — the claim/evidence gate adds real work per convergence point; risk of it becoming box-ticking. Mitigation: keep it to *convergence points only*, not every claim; the deterministic anchor check keeps at least the checkable ones honest.
- **Scope** — this touches both deliberation skills + their templates + a rule. It's an M/L. Keep v1 to the 4-stage bundle; resist gold-plating (no third-runtime, no autonomous loop — those are explicit non-goals / Etapa 2).

## Research / citations

- The Codex debate (`debate.md`) — resolved the protocol; its synthesis is the spec's § Resolved v1 protocol. Sources folded into `spec.md` § Context (PNAS social-influence, Delphi/nominal-group, FActScore/attribution, MT-Bench LLM-judge bias, anonymization/sycophancy/conformity papers).
- Code: `.agent0/skills/meeting/scripts/meeting.sh` (399 lines; front-matter helpers, `append-turn`/`advance`/`resolve-speaker`/`friction`), `.agent0/skills/sdd/templates/debate.md.tmpl`, `.agent0/skills/meeting/references/turn-prompt.md`.
- Precedent: `docs/specs/146-product-craft-floor/` (deterministic checks consumed by an LLM judge — the model for the anchor check); the delegation-gate test suite (shell-test convention for the new tests).
