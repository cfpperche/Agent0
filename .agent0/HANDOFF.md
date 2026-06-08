# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol.

---

## Current State

**Session 2026-06-08 — Spec 169 `post-launch-maintenance-loop` SHIPPED locally, not committed/pushed.** Added a provider-neutral post-launch maintenance loop as an instrument-only Agent0 surface: production signal -> work hub -> agent delegate -> human review gate -> feedback sink. V1 is only a context rule plus copyable templates; no skill, hook, daemon, webhook receiver, scheduler, provider client, validator, or runtime integration was added.

**Artifacts:** `docs/specs/169-post-launch-maintenance-loop/` is complete with Claude review/debate captured in `debate.md`; rule is `.agent0/context/rules/post-launch-maintenance-loop.md`; templates are under `.agent0/context/templates/post-launch-maintenance-loop/`; checks are under `.agent0/tests/post-launch-maintenance-loop/`.

**Product/governance wiring:** `/product` terminal handoff now points to the loop as optional after first release, not as a phase. `pipeline-coverage.md` calls it sibling infrastructure. `agent0-governance-doctrine.md` records spec 169 as a narrow slice, not the full `continuous-evolution-spine` follow-up.

**User-facing usage guidance given:** with `/product`, use the loop after SDD build + first release as post-launch setup. Without `/product`, adopt it directly from the Agent0 harness by copying/filling the templates. In both cases the consumer project owns the real integrations and starts manual/dry-run before agent delegation.

**Validation:** `bash .agent0/tests/post-launch-maintenance-loop/run-all.sh` passed; sensitive-pattern grep found no configured credentials/IDs; equivalent temporary sync dry-run copied the new rule/templates/tests; `git diff --check` passed; no unresolved `{{...}}` placeholders in spec 169 or the new surfaces.

**Prior shipped baseline:** specs 166-168 are on Agent0 `main`; spec 168 shipped `docs/agent0-roadmap.html`, spec 167 shipped scope admission, spec 166 shipped the governance doctrine. Capacity/media arc 153-165 remains complete.

## Active Work

- Spec 169 implementation is complete locally and awaiting the user's commit/push decision.
- The latest user question was answered: use with `/product` after terminal SDD handoff/release; use without `/product` as a standalone harness playbook via the templates.
- Unrelated untracked meeting directory exists at `.agent0/meetings/harness-token-weight-vs-importance-2026-06-08T00-59-10Z/`; do not stage it with spec 169 unless the user asks.

## Next Actions

- If publishing: review `git status`, stage only spec 169 paths plus the three touched docs/HANDOFF, then commit/push. Exclude the unrelated meeting directory unless intentionally publishing it.
- If asked to demonstrate adoption next, create a consumer-local `docs/ops/post-launch-maintenance/` fixture from the templates; do not configure real Sentry/Linear/GitHub/Codex/Claude credentials unless explicitly requested.
- Possible future work, not admitted by spec 169: a portable maintenance-loop skill only after dogfood shows rule+templates are too passive; broader `continuous-evolution-spine` still needs its own evidence and scope decision.
- Parked items remain condition-gated: agentskills.io re-snapshot due 2026-08-17, competitive harness audit due 2026-08-19, and old `060` deferred rows.

## Decisions & Gotchas

- Spec 169 boundary is load-bearing: Agent0 instruments the maintenance loop but does not own consumer observability, incident process, agent delegation, merge, release, rollback, or closure.
- Keep Sentry -> Linear -> Codex isolated as an example recipe. Provider-neutral guidance must keep roles by capability class: signal source, work hub, agent delegate, review gate, feedback sink.
- Usage distinction: `/product` is only a pointer after release; non-`/product` projects can use the same rule/templates directly. The mechanism is the same in both paths.
- Production signal payloads are untrusted input. Trusted task instructions and untrusted incident payload must stay separated; redaction/minimization and human review are mandatory before delegation/merge/release.
- `sync-harness.sh` uses the git index file-set. Direct dry-run will not list new untracked files; for pre-commit propagation proof, use an equivalent temporary source with only the relevant paths added to a temporary index.
