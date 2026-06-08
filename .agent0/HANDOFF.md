# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol.

---

## Current State

**▸ Session 2026-06-07 (latest) — Spec 168 `agent0-roadmap-html` SHIPPED + PUSHED to Agent0 `main`.** Added standalone `docs/agent0-roadmap.html`, inspired by roadmap.sh at the pattern level only, plus frontend-designer artifacts and a render-tier fixture under `docs/specs/168-agent0-roadmap-html/`. It visualizes Agent0 as a template/governance harness across evolution, quality, security, context, replication, multi-runtime, and scope admission, distinguishing shipped/instrument/deferred/missing work. `agent-browser verify-contract` is green via `file://` with an absolute report outdir.

**Previous shipped session — Spec 167 `scope-admission-governance` SHIPPED + PUSHED to Agent0 `main`.** Scope admission is now a first-class rule at `.agent0/context/rules/scope-admission-governance.md`, linked from the Agent0 governance doctrine and SDD rule. It defines admission outcomes (`admit`, `instrument-only`, `harden-existing`, `defer`, `reject`), evidence ladder, admission brief, hardening bar, product-drift boundary, and deferred-work recording discipline. No hook/validator/tool/script/sync apply was added.

**Previous shipped session — Spec 166 `agent0-governance-doctrine` SHIPPED + PUSHED to Agent0 `main`.** The future-Agent0 brainstorm was closed/rendered, Claude was consulted via `claude-exec`, and the resulting doctrine is now codified in `.agent0/context/rules/agent0-governance-doctrine.md`. `CLAUDE.md` and `AGENTS.md` both point to it from the shared managed block; `check-instruction-drift.sh --agent0-path=/home/goat/Agent0` is green and `doctor.sh` reports OK (22 ok, 0 advisory, 0 broken). Doctrine: Agent0 remains a stack-neutral template/governance harness, not a product by default; new capacities must pass explicit scope-admission discipline.

**Previous shipped session — Acmeyard sync followups fixed and pushed to Agent0 `main`.** Agent0 upstream has `AGENTS.md` managed block mirrored from the canonical `CLAUDE.md` block, so `check-instruction-drift.sh --agent0-path=/home/goat/Agent0` is green. Trailing whitespace was removed from tracked text files exposed by the Acmeyard sync. While validating, a real checker bug surfaced: `printf "$sync_out" | grep -q` under `pipefail` could miss `AGENTS.md` in large `sync-harness` output; fixed with here-strings and covered by `07-sync-output-grep-pipefail.sh`.

**Previous shipped session — Spec 165 `cross-dir-capacity-sourcing` SHIPPED + PUSHED `545da5a`, propagated to both consumers.** `video`+`image` now source `lib/paid-media.sh` cross-dir; gate GREEN 11/11, zero behavior change. `docs/specs/165-*`. **All 4 paid tools now on the kit.**

**Recently shipped (git log + docs/specs/, no action):** `paid-media-kit`(164); media family 159–162; `capacity-kit`(163); `frontend-designer`(158); 153–155. Consumers `cognixse`+`mei-saas` carry 161–165 (synced + pushed).

**Repos:** Agent0 `main` carries spec 167. cognixse and mei-saas are unchanged from the previous propagated state.

## Active Work

- No active implementation work.
- No live parallel-work claims.

## Next Actions

- Remaining candidate follow-ups from the doctrine, not yet ripe without separate scope decision: `gate-algebra`, `security-governance-lane`, `continuous-evolution-spine`.
- The capacity/media arc (153–165) is complete, gated, and propagated. The 164 `video`/`image` reopen-trigger is CLOSED (spec 165).
- **Condition-gated parked items (none ripe):** agentskills.io re-snapshot reminder (due 2026-08-17); next competitive harness audit (scheduled 2026-08-19); `060` deferred rows (B2 rule-analytics @ rule-count>30, B3 agent-as-peer @ orchestration-demand, A5 PermissionRequest @ demand). Don't build until the trigger fires (rule-of-three).

## Decisions & Gotchas

- **Capacity-kit extraction discipline:** extract ONLY byte-identical-or-cleanly-parameterized plumbing; genuine per-tool variants stay local. Helpers in `lib/paid-media.sh` are **pure** (never emit, never exit). Prove behavior-preservation with `golden.sh capture` BEFORE / `verify` AFTER.
- **Agent0 governance doctrine (166):** before expanding Agent0 capacities, classify the proposal by layer (continuous-evolution spine, quality/security domains, context/replication substrate, multi-runtime transversal, scope-admission meta-governance) and by boundary (`own` / `instrument` / `ignore`). Product-like ownership of consumer release/operation stays out unless future evidence moves the boundary.
- **Scope admission (167):** new capacity proposals must land in one outcome (`admit`, `instrument-only`, `harden-existing`, `defer`, `reject`) and name evidence, v1 posture, blast radius, validation, and non-goals before planning a mechanism. Hard gates require deterministic checks, low false-positive risk, bypass/audit posture, consumer blast-radius analysis, and tests.
- **`--help` source-below-range gotcha:** tools print `--help` via `sed -n 'A,Bp' "$0"`; source libs below that range.
- **Cross-dir kit sourcing (165):** skill-dir tools source via `$PROJECT_DIR`, lazy-loaded inside paid subcommands. Consumer-root sourcing tests must be OBSERVABLE with a sentinel.
- **`golden.sh` is FAL_KEY-hermetic** (`env -u FAL_KEY`); `paid-golden.sh` pins set state. `git fetch` before trusting consumer `[ahead N]`.
- **Consumer push policy:** Agent0 pushed freely; cognixse/mei-saas committed local and **pushed only when the founder triggers**; `tmux-sentinel` is sync-apply-only, NEVER commit/push harness (`.agent0/memory/tmux-sentinel-sync-no-commit.md`).
- **agent-browser daemon gotchas** + fail-closed routing (spec 153, no MCP lane): see `.agent0/memory/agent-browser-primitive.md`.
