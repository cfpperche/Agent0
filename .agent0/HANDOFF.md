# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol.

---

## Current State

**▸ Session 2026-06-07 (latest) — Acmeyard sync followups fixed and pushed to Agent0 `main`.** Agent0 upstream has `AGENTS.md` managed block mirrored from the canonical `CLAUDE.md` block, so `check-instruction-drift.sh --agent0-path=/home/goat/Agent0` is green. Trailing whitespace was removed from tracked text files exposed by the Acmeyard sync. While validating, a real checker bug surfaced: `printf "$sync_out" | grep -q` under `pipefail` could miss `AGENTS.md` in large `sync-harness` output; fixed with here-strings and covered by `07-sync-output-grep-pipefail.sh`.

**Previous shipped session — Spec 165 `cross-dir-capacity-sourcing` SHIPPED + PUSHED `545da5a`, propagated to both consumers.** `video`+`image` now source `lib/paid-media.sh` cross-dir; gate GREEN 11/11, zero behavior change. `docs/specs/165-*`. **All 4 paid tools now on the kit.**

**Recently shipped (git log + docs/specs/, no action):** `paid-media-kit`(164); media family 159–162; `capacity-kit`(163); `frontend-designer`(158); 153–155. Consumers `cognixse`+`mei-saas` carry 161–165 (synced + pushed).

**Repos:** Agent0 is clean and in sync with `origin/main`; cognixse and mei-saas are unchanged from the previous propagated state.

## Active Work

- Nothing in flight. No live parallel-work claims.

## Next Actions

- The capacity/media arc (153–165) is complete, gated, and propagated. The 164 `video`/`image` reopen-trigger is CLOSED (spec 165).
- **Condition-gated parked items (none ripe):** agentskills.io re-snapshot reminder (due 2026-08-17); next competitive harness audit (scheduled 2026-08-19); `060` deferred rows (B2 rule-analytics @ rule-count>30, B3 agent-as-peer @ orchestration-demand, A5 PermissionRequest @ demand). Don't build until the trigger fires (rule-of-three).

## Decisions & Gotchas

- **Capacity-kit extraction discipline:** extract ONLY byte-identical-or-cleanly-parameterized plumbing; genuine per-tool variants stay local. Helpers in `lib/paid-media.sh` are **pure** (never emit, never exit). Prove behavior-preservation with `golden.sh capture` BEFORE / `verify` AFTER.
- **`--help` source-below-range gotcha:** tools print `--help` via `sed -n 'A,Bp' "$0"`; source libs below that range.
- **Cross-dir kit sourcing (165):** skill-dir tools source via `$PROJECT_DIR`, lazy-loaded inside paid subcommands. Consumer-root sourcing tests must be OBSERVABLE with a sentinel.
- **`golden.sh` is FAL_KEY-hermetic** (`env -u FAL_KEY`); `paid-golden.sh` pins set state. `git fetch` before trusting consumer `[ahead N]`.
- **Consumer push policy:** Agent0 pushed freely; cognixse/mei-saas committed local and **pushed only when the founder triggers**; `tmux-sentinel` is sync-apply-only, NEVER commit/push harness (`.agent0/memory/tmux-sentinel-sync-no-commit.md`).
- **agent-browser daemon gotchas** + fail-closed routing (spec 153, no MCP lane): see `.agent0/memory/agent-browser-primitive.md`.
