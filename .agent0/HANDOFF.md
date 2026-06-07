# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**▸ Session 2026-06-07 (latest) — Spec 164 `paid-media-kit` SHIPPED + PUSHED `ed47b6e`.** The deferred second layer of 163, founder-directed in one loop (meeting+sdd+impl with Codex; "don't let followups resolve everything"). Decision-grade `/meeting` (claude+codex, spec-149 blind openings converged independently; 11-claim ledger all anchored) → Explore kill-gate measurement → `/sdd` → implement → Codex adversarial review (2 findings fixed). **Honest re-scope:** the optimistic 5-target plan collapsed to **4 PURE helpers** in `.agent0/tools/lib/paid-media.sh` — `pm_yaml_top`/`pm_yaml_tier_field` (the `*-tiers.yaml` oracle, = sound's `yget`/`ytop`) + `pm_has_fal_key`/`pm_fal_key_state` (leak-safe FAL_KEY). Migrated `sound`+`audio --remote` (audio reader proven byte-identical first). Cost-formula/gate/fal-invocation stayed LOCAL (genuine variants); `image` out; `video` = named reopen-trigger. Gate GREEN 11/11. Full detail in `docs/specs/164-paid-media-kit/` + meeting `.agent0/meetings/paid-media-kit-honest-scope-2026-06-07T01-33-04Z/`.

**▸ Consumer harness-sync (same session) — `cognixse` `267aa21` + `mei-saas` `3a394c6`, both PUSHED.** Propagated 161/162/163/164 (60 copied each, 0 refused, 0 overwritten). **Load-bearing fix verified live:** both consumers had `lib/` with only `managed-block.sh` (no `capacity.sh`) — kernelized `audio`/`transcribe` would have sourced a missing lib; the sync carried both libs + the tools together, post-sync `caps` exit 0 on all four. Harness-only delta.

**Recently shipped (in `git log` + `docs/specs/`, no action needed):** media family `/transcribe`(159) `/audio`(160) `/sound`(161) `/diagram`(162); `capacity-kit`(163) kernel; `frontend-designer`(158); visual-contract gate(155); squad-hardening(154); browser decouple-from-playwright(153). All on `origin/main`.

**Repos:** Agent0, cognixse, mei-saas all clean + in sync with `origin/main`.

## Active Work

- Nothing in flight. No live parallel-work claims.

## Next Actions

- **Parked reopen-trigger — `video` YAML-reader → `pm_yaml_*`.** Only worth doing when a skill-dir→`tools/lib/` cross-dir `source`/sync smoke test is in scope (the genuinely-separate portability concern that kept `video`/`image` out of 164). Not pressing; no demand yet.
- No other queued work — the media + capacity-kit arc is complete and propagated.

## Decisions & Gotchas

- **Capacity-kit extraction discipline (163→164):** extract ONLY byte-identical-or-cleanly-parameterized plumbing; genuine per-tool variants stay local. Helpers in `lib/paid-media.sh` are **pure** (never emit, never exit) — that's what lets one lib serve tools with divergent failure contracts (`sound` compact `cap_fail` vs `audio` pretty local `fail`). A `pm_require_fal_key` was rejected for this reason. Prove behavior-preservation with `golden.sh capture` BEFORE / `verify` AFTER.
- **`--help` source-below-range gotcha (recurs every capacity migration):** tools print `--help` via `sed -n 'A,Bp' "$0"`; inserting a `source` line inside that range drifts `--help`. Always source the lib BELOW the help range (sound 3-22, audio 3-30).
- **`golden.sh` is now FAL_KEY-hermetic** (`env -u FAL_KEY` per run); `paid-golden.sh` pins the set state. A consumer showing `[ahead N]` may be a stale `origin/*` ref — `git fetch` before trusting it.
- **Consumer push policy:** Agent0 pushed freely; cognixse/mei-saas committed local and **pushed only when the founder triggers**; `tmux-sentinel` is sync-apply-only, NEVER commit/push harness (`.agent0/memory/tmux-sentinel-sync-no-commit.md`).
- **agent-browser daemon gotchas** + fail-closed routing (spec 153, no MCP lane): see `.agent0/memory/agent-browser-primitive.md`.
