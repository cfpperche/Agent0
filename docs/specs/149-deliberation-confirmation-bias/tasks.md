# 149 — deliberation-confirmation-bias — tasks

_Generated from `plan.md` on 2026-06-04 (intent locked via Codex debate; unify-on-`meeting.sh` ratified). Work top-to-bottom._

## Implementation

- [ ] 1. **`meeting.sh` commit/reveal.** Add `commit --speaker <id> --hash <sha256> --bytes <n>` (writes a blind-commitment row, no text) and `reveal --speaker <id> --text-file <f> --nonce <n>` (verifies `sha256(text+nonce)` == committed hash; refuses if not all speakers have committed; writes the revealed opening; flips state to critique-unlocked). State lives in the front-matter + a sealed `.agent0/.deliberation-state/<slug>/` scratch (gitignored) so peer prompts never include un-revealed text.
- [ ] 2. **`meeting.sh` A/B mapping.** Add `ab-map <file>` — emit a randomized `Proposal A/B ↔ runtime` mapping for the judgment surface; record the mapping in an attributed audit line so the durable transcript stays auditable while the critique view is anonymized.
- [ ] 3. **`meeting.sh` claim/evidence ledger.** Add `ledger-add --claim <text> --tag <supported|contradicted|unresolved|assertion-only> --anchor <ref>` and `ledger-check <file>` (the gate: a convergence point with only `assertion-only` claims is reported `unresolved`). Define the ledger block schema in the templates.
- [ ] 4. **`meeting.sh` anchor check (v1 scope).** Add `check-anchors <file>` — deterministic verification of cheap anchors only: cited file path exists; a named test identifier is present in the test tree. "Re-run the test" is explicitly out (v2). Emits per-anchor verified/unverified.
- [ ] 5. **`meeting.sh` tiering.** Extend `init` with `--tier light|decision-grade` (front-matter field); `light` skips commit/reveal + ledger; `decision-grade` requires them. `/sdd debate` is always decision-grade.
- [ ] 6. **Templates.** Update `meeting.md.tmpl` + `debate.md.tmpl`: blind commit/reveal round-0 block, claim-ledger section, minority-report slot in synthesis (gated by tier).
- [ ] 7. **`turn-prompt.md`.** Peer prompt carries the Proposal-A/B anonymized view, counterfactual-candidate-coverage fields ("best alternative + evidence that would make it win + strongest objection to your own path"), and a confidence marker (routing-only; never counted as evidence).
- [ ] 8. **`meeting/SKILL.md` orchestration.** Tier selection; commit→reveal→critique phase ordering; how the human pumps the blind phase (collect ALL commitments before any reveal — backed by the `reveal` mechanical guard from task 1).
- [ ] 9. **`sdd/SKILL.md` debate subcommand.** Re-point at the shared `meeting.sh` mechanics for commit/reveal + ledger + minority report; restructure Round 1 to the blind shape (no more initiator-writes-position-first). Confirm Codex-runtime parity (it already runs `meeting.sh`).
- [ ] 10. **Rules.** Update `.agent0/context/rules/meeting.md` (de-biased protocol + tiers + why, citing research + debate) and `spec-driven.md` § debate (commit/reveal + ledger).
- [ ] 11. **Tests** `.agent0/tests/deliberation-bias/`: commit/reveal hash verify (good unlocks; tampered text fails reveal; reveal refused before all commit); A/B mapping order-randomized + audit attributed; ledger gate (assertion-only ≠ resolved); `check-anchors` (missing path flagged); tier gating (light skips commit/reveal); `bash -n` + shellcheck on `meeting.sh`.

## Verification

- [ ] `bash .agent0/tests/deliberation-bias/run-all.sh` — all pass.
- [ ] Existing `bash .agent0/tests/meeting/run-all.sh` still green (no regression to the turn engine).
- [ ] Multi-runtime parity: `meeting.sh commit/reveal/ledger` runs identically invoked from a Codex-style call (runtime-neutral shell, no Claude-only deps).
- [ ] Dogfood: run a real de-biased `/sdd debate` (commit/reveal → A/B critique → ledger gate → minority report) on a throwaway spec; confirm the blind phase actually withholds peer text and the ledger gate flags an assertion-only convergence. (spec § Acceptance scenarios)
- [ ] Acceptance criteria in `spec.md` re-read and checked; Status → shipped.

## Notes

- v1 scope discipline: 4-stage bundle only. No third runtime, no autonomous loop (Etapa 2 `/squad`), no test-re-run anchor check (v2).
- The blind-phase secret-keeping convention (`.agent0/.deliberation-state/` gitignored + prompt-builder must never include un-revealed text) is the subtlest correctness point — exercise it explicitly in tests.
