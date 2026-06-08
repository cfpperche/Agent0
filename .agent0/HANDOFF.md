# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol.

---

## Current State

**Session 2026-06-08 (latest) — Entrypoint capability-index COMPACTION shipped to Agent0 `main` + 3 consumers (all local commits, not pushed).** The Agent0-managed block in `CLAUDE.md`/`AGENTS.md` (the always-on entrypoint index) was compacted: opt-in capability + infra sections collapsed to a one-line discovery-function form (`/command (+ tool) — what it does (keywords) — distinction vs neighbor → rule`), invariants (SDD, governance, runtime-capabilities, handoff, delegation, secrets, memory, Compact Instructions) kept dense. Managed block **22,571 → 12,843 bytes (~2,431 tokens saved per session)**; 35 sections preserved; CLAUDE.md ≡ AGENTS.md in the block. Commit `d2d1aec` on Agent0 main.

**How it was decided (not ad-hoc):** graduated from `/meeting` `.agent0/meetings/harness-token-weight-vs-importance-2026-06-08T00-59-10Z/` (classification of harness components by token-weight × importance). The human's stack-neutrality critique killed `rule_selected` frequency-as-importance instrumentation (harness ships to stack-neutral consumers; frequency on the Agent0 repo is unrepresentative → deferred as speculative observability). A scaffolded spec 170 + Codex `/sdd debate` then collapsed an over-engineered routing benchmark into a basic smoke test; **spec 170 was deleted** (proportionality — see new memory `feedback_match_rigor_to_reversibility`).

**Validation:** blind routing smoke test **16/16 on both runtimes** (Claude subagent + Codex via `codex-exec`) over every near-ontology trap pair (audio/sound/transcribe, image/diagram/video, product/frontend-designer, meeting/brainstorm) + false-positive + no-capability cases. Mechanical regression green: `doctor.sh` 22 ok/0 broken, `harness-sync` 28/28, `agents-memory-block-budget` pass.

**Consumers shipped (apply + commit on each `main`, local only):** mei-saas `ade8500`, cognixse `5d1e9ad`, acmeyard `d05efa0`. All brought current with Agent0 main (compaction + specs 166/167/169 + product/browser/spec-driven updates); sync was 100% clean (0 customized-refused, 0 overwritten). Consumer commits staged harness paths only (`CLAUDE.md AGENTS.md .claude .agent0`, 23 files each).

**Prior shipped baseline:** specs 166-168 on Agent0 `main`; spec 168 shipped `docs/agent0-roadmap.html`, 167 scope admission, 166 governance doctrine. Capacity/media arc 153-165 complete.

## Active Work

- No active implementation work. Agent0 working tree is clean. The compaction is committed locally on all four repos; nothing is pushed (user chose keep-local).
- Spec 169 `post-launch-maintenance-loop` was committed to Agent0 main as `fda6594` during this session, and propagated to the 3 consumers by the bring-current sync — source and consumers are consistent (no gap).
- cognixse has unrelated uncommitted product work (`backoffice/leads/page.tsx`, `actions.ts`, 2 e2e) — left untouched, never staged.

## Next Actions

- When ready to publish: `git push` on Agent0 + the 3 consumers (local commits pending).
- Compaction follow-through if real usage shows a missed capability: restore that one section's dense form (the compaction is reversible by design — the documented revert trigger; the smoke test proves cue-retention under attention, NOT spontaneous mid-task discovery).
- Parked items remain condition-gated: agentskills.io re-snapshot due 2026-08-17, competitive harness audit due 2026-08-19, old `060` deferred rows. Governance follow-ups `gate-algebra`, `security-governance-lane`, `continuous-evolution-spine` still need their own scope decisions.

## Decisions & Gotchas

- **Importance of a harness rule is NOT measurable by frequency on the Agent0 repo** — the harness ships to stack-neutral consumers; frequency here describes harness development, not consumer use, and consumer-local telemetry never returns. Importance-for-shipping = severity-if-omitted × breadth-of-applicability, disciplined by a discovery-function-per-line test (each entrypoint line must prove command/keywords/distinction/pointer, *including* governance lines).
- The compacted one-liners preserved routing in the smoke test specifically because the `NOT X → /Y` neighbor pointers carry the disambiguation — do not drop them when editing capability lines, or cost migrates from tokens to mis-routing.
- `sync-harness` brings a consumer to the Agent0 source HEAD-on-disk wholesale, not per-change; "ship one change" still pulls every stale/new harness file. Surface the full drift list before applying to external repos.
- When committing a harness sync into a consumer that has its own product work in flight, stage harness paths explicitly (`CLAUDE.md AGENTS.md .claude .agent0`), never `git add -A` — cognixse this session had product changes that must not ride along.
