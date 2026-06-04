# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Session 2026-06-04 (squad) — spec 149 `deliberation-confirmation-bias` IMPLEMENTED + VALIDATED + SHIPPED.** `origin/main` @ `3db5138`. Etapa 1 of the `/squad` roadmap done. The de-biased deliberation protocol is now live in `meeting.sh` (shared by `/sdd debate` + decision-grade `/meeting`): **commit/reveal** blind opening (seals each independent opening under gitignored `.agent0/.runtime-state/deliberation/`, `reveal` refuses until all model speakers commit + verifies hashes), **ab-map** (randomized Proposal A/B critique view; transcript stays attributed), **ledger-add/ledger-check** convergence GATE (`assertion-only` ⇒ unresolved regardless of agreement), **check-anchors** (deterministic path/test verify; test-rerun is v2), **init --tier light|decision-grade**. Prose wired: `turn-prompt.md` (counterfactual coverage + confidence-as-routing, structural not persona), both templates (blind/ledger/minority-report), `meeting/SKILL.md` § De-biased decision-grade flow, `sdd/SKILL.md` blind Round 1, rules `meeting.md` + `spec-driven.md`. **Tests: deliberation-bias 9/9; meeting 15/15; multi-runtime-skills pass; harness-sync 40/40 — no regression.** Design notes: orchestrator-sealed (not agent-resupply); blindness is procedural+tamper-evident, not cryptographic vs an adversarial peer. **Not yet propagated to consumers.**

_Prior this session — spec 149 designed (debate) + planned; see below._

**Session 2026-06-04 (squad) — spec 149 design/plan (superseded by the implementation above).** `origin/main` @ `4bfaa1e`. This is **Etapa 1 of a 2-etapa roadmap toward `/squad`** (autonomous multi-agent build loop): before building a squad whose done-condition leans on agent agreement, harden the deliberation primitives so "the agents converged" is trustworthy. Resolved (via a web-backed Claude↔Codex `/sdd debate` that dogfooded its own subject — Codex gave an independent source-first ranking *before* seeing my list and materially diverged): a 4-stage de-biased protocol — **(1) commit/reveal blind opening (`sha256+nonce`, not separate files); (2) randomized Proposal-A/B critique (judgment-surface anonymization; audit stays attributed); (3) claim/evidence convergence GATE (4 tags; `assertion-only` ≠ resolved; deterministic anchor check where feasible); (4) rubric-over-ledger synthesis + preserved minority report** + counterfactual-candidate-coverage & confidence-as-routing turn schema; heterogeneous models required; `/meeting` light-tier vs decision-grade tier. **Architectural call (founder-ratified): unify the mechanics as shared `meeting.sh` subcommands; `/sdd debate` calls the same script (one tested impl, not two).** 11 ordered tasks in `tasks.md`. **Etapa 2 = `/squad`** (renamed from `/pair`), gated on Etapa 1 landing.

_Prior 2026-06-04 — spec 148 `publish-boundary-closeout-check` closed._

**Session 2026-06-04 — spec 148 `publish-boundary-closeout-check` closed.** The handoff-discipline meeting converged on a hook-backed fix for the recurring "section done but HANDOFF stale" failure. `SessionStart` now records `start-head`; `SessionStop` now has a clean publish-boundary branch: when session commits are pushed and the latest session commit does not touch `.agent0/HANDOFF.md`, it nags once to force a final handoff re-read/update.

Validation passed: `bash .agent0/tests/session-handoff/run-all.sh` (11/11), `bash .agent0/tests/session-handoff-multi-runtime/run-all.sh` (6/6), `bash .agent0/tests/harness-sync/run-all.sh` (40/40), `bash -n .agent0/hooks/session-start.sh .agent0/hooks/session-stop.sh .agent0/tests/session-handoff/11-publish-boundary-closeout.sh`, and `git diff --check`.

**Session 2026-06-04 — Codex `/video` skill-loader warning fixed locally.** Meeting investigation traced the startup warning to `.agent0/skills/video/SKILL.md` frontmatter: unquoted `argument-hint` contained `code: scaffold`, which strict YAML parses as invalid at column 46. The value is now quoted, and `/skill` validation rejects invalid YAML frontmatter before field extraction.

Validation passed: `bash -n .agent0/skills/skill/scripts/validate.sh`; `/skill` fixtures 9/9 including `invalid-yaml-colon-space`; `validate.sh` over every `.agent0/skills/*` skill (only existing body-size warning for `/skill`); PyYAML parse over every skill frontmatter; multi-runtime-skills 9/9; video tests 4 pass / 1 integration skip; `git diff --check` clean.

## Active Work

- No active Agent0 work claimed. Spec 149 (Etapa 1) is implemented, validated, and on `origin/main` (`3db5138`); all 11 tasks + verification checked.

## Next Actions

**Optional — propagate spec 149 to the 4 consumers** (cognixse, mei-saas, tese, ag-antecipa). Changed files are all tracked under `.agent0/` (meeting.sh, templates, turn-prompt, SKILLs, rules) + the new test suite → a `sync-harness.sh --apply` carries them cleanly (the `/sdd debate` + `/meeting` skills are harness-managed). Not urgent; can ride the next routine consumer sync.

**▶ Etapa 2 — open the `/squad` spec** (autonomous ping-pong build loop; symmetric initiation; **done-condition = external gates, not agent-agreement**, now that 149's de-biased deliberation exists to make agreement trustworthy). Carries spec-138's safety thinking: bounded (token/round ceiling), gate-driven, human-at-milestone-gates, agents-prepare-prod-human-triggers. Start `/sdd new squad` → refine → cross-model `/sdd debate` (now using the spec-149 blind/ledger flow — dogfood). Renamed from `/pair`; future-proofs for more runtimes.

## Decisions & Gotchas

- `assets/generated/.manifest.jsonl` is now local audit state, not durable project history.
- Do not add the manifest to `sync-harness.sh` copy lists; that would risk copying Agent0 prompt/cost history into consumers.
- `/video` policy is unchanged: `.video-manifest.jsonl` remains governed by `.agent0/context/rules/video-gen.md`.
- `argument-hint:` is still a top-level skill frontmatter field; values containing `: ` must be quoted or block-styled.
- Spec 148 intentionally does not parse handoff prose; the mechanical proof is that the latest pushed session commit touches `.agent0/HANDOFF.md`.
- Root `AGENTS.md` and `CLAUDE.md` are Agent0-managed entrypoints; consumer-local Codex guidance still belongs in `AGENTS.override.md` or nested `AGENTS.md`.
