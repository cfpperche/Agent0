# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**▸ Session 2026-06-07 (latest) — Spec 165 `cross-dir-capacity-sourcing` SHIPPED + PUSHED `545da5a`, propagated to both consumers (also pushed).** Founder-directed ("same rigor as 164, resolve followups in-loop"), closing the 164 reopen-trigger: **skill-dir** tools `video`+`image` now source `lib/paid-media.sh` cross-dir. Decision-grade `/meeting` → measurement → `/sdd` → build → Codex review (FIX-FIRST, 2 fixed). The "cross-dir cable" was already built (both gen.sh anchor on `$PROJECT_DIR` + cross into `tools/` for fal-rest); only new bit = *sourcing* a lib. Pattern `. "$PROJECT_DIR/.agent0/tools/lib/paid-media.sh"`, **lazy-loaded inside paid subcommands** (non-paid lanes work lib-absent; absent paid path → exit 70). `video` reader → `pm_yaml_*` binders (byte-identical); `video`+`image` FAL_KEY → `pm_has_fal_key || die_no_fal_key`; **`image` pipe-table intact** (anti-punt: converting creates surface, retires nothing). New gate `cross-dir-source.sh` (8 lanes, observable sentinel). Gate GREEN 11/11, zero behavior change. `docs/specs/165-*`. **All 4 paid tools now on the kit.**

**Recently shipped (git log + docs/specs/, no action):** `paid-media-kit`(164); media family 159–162; `capacity-kit`(163); `frontend-designer`(158); 153–155. Consumers `cognixse`+`mei-saas` carry 161–165 (synced + pushed).

**Repos:** Agent0, cognixse, mei-saas all clean + in sync with `origin/main`.

## Active Work

- Nothing in flight. No live parallel-work claims.

## Next Actions

- **None pressing.** The capacity/media arc (153–165) is complete, gated, and propagated. The 164 `video`/`image` reopen-trigger is now CLOSED (spec 165).
- **Condition-gated parked items (none ripe):** agentskills.io re-snapshot reminder (due 2026-08-17); next competitive harness audit (scheduled 2026-08-19); `060` deferred rows (B2 rule-analytics @ rule-count>30, B3 agent-as-peer @ orchestration-demand, A5 PermissionRequest @ demand). Don't build until the trigger fires (rule-of-three).

## Decisions & Gotchas

- **Capacity-kit extraction discipline (163→164):** extract ONLY byte-identical-or-cleanly-parameterized plumbing; genuine per-tool variants stay local. Helpers in `lib/paid-media.sh` are **pure** (never emit, never exit) — that's what lets one lib serve tools with divergent failure contracts (`sound` compact `cap_fail` vs `audio` pretty local `fail`). A `pm_require_fal_key` was rejected for this reason. Prove behavior-preservation with `golden.sh capture` BEFORE / `verify` AFTER.
- **`--help` source-below-range gotcha (recurs every capacity migration):** tools print `--help` via `sed -n 'A,Bp' "$0"`; inserting a `source` line inside that range drifts `--help`. Always source the lib BELOW the help range.
- **Cross-dir kit sourcing (spec 165):** skill-dir tools source the kit via `$PROJECT_DIR` (not `../../../`), **lazy-loaded inside paid subcommands** so non-paid lanes work lib-absent. A test pointing `CLAUDE_PROJECT_DIR` at a bare temp must provision the lib there (else the paid path exits 70). A consumer-root sourcing test must be OBSERVABLE (a sentinel marker), not just "didn't exit 70".
- **`golden.sh` is now FAL_KEY-hermetic** (`env -u FAL_KEY` per run); `paid-golden.sh` pins the set state. A consumer showing `[ahead N]` may be a stale `origin/*` ref — `git fetch` before trusting it.
- **Consumer push policy:** Agent0 pushed freely; cognixse/mei-saas committed local and **pushed only when the founder triggers**; `tmux-sentinel` is sync-apply-only, NEVER commit/push harness (`.agent0/memory/tmux-sentinel-sync-no-commit.md`).
- **agent-browser daemon gotchas** + fail-closed routing (spec 153, no MCP lane): see `.agent0/memory/agent-browser-primitive.md`.
