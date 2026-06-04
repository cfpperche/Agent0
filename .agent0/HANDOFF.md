# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Session 2026-06-04 — spec 150.3 `/squad` hardening SHIPPED + propagated; harness arc closed, no demand-validated next item (founder: let demand drive).** The generic class-prevention for F1/F2/F3 (the 151 dogfood findings; concrete instances were already fixed in 151): **F1** → `squad-contract.md` § "Author fail-closed gates" (gate the spec's own test exists + require a globbing runner; "if removing the impl leaves the gate green, the gate is wrong"). **F2** → `SKILL.md` pump bullet "review the peer's diff — a green gate is necessary, not sufficient" (a peer can bend production to a flawed test). **F3** → `squad.json.example` default `forbidden_paths` now forbids `\.agent0/HANDOFF\.md` (only forbidden_paths is mechanically enforced; the NL brief is a hint) + new regression `tests/squad/11-contract-example-forbids-handoff.sh`. **Squad suite 11/11**, `/skill validate squad` clean. Recorded in `docs/specs/150-squad/notes.md` § 150.3.

_Prior this session — spec 151 shipped + propagated via the first real-feature `/squad` run; see below._

**Session 2026-06-04 — spec 151 `sync-harness-local-only` SHIPPED via the first real-feature `/squad` autonomous run (Claude orchestrator ↔ real Codex).** End-to-end dogfood: de-biased planned spec (mechanism (c) auto-detect from `.gitignore`, Claude+Codex independent convergence) → `/squad` pump → green external gate → `ready_for_human_prod` → delivered. Local-only mode auto-detects (via `git check-ignore` on representative `.agent0/` paths) consumers that gitignore the harness, refreshes the gitignored `.agent0/` tree, and **skips every tracked-file write** (so a public consumer like tmux-sentinel gets local dev tooling with zero committable drift). Squad converged in 3 rounds (Claude TDD test → Codex impl → Claude orchestrator-repair), repair_attempts=1.

**The run's payload is its findings (see `docs/specs/151-squad-...notes.md` § Squad dogfood):** **F1 🔴** the gate was *vacuously green* — `harness-sync/run-all.sh` hardcoded scenarios 01-40, so the new `42` (and orphaned `41`) never ran in the suite; the external gate is only as strong as its coverage (fixed: run-all now globs `[0-9][0-9]-*.sh`). **F2 🔴** the peer bent production to a flawed contract test — Codex added a `.gitleaks.toml` bootstrap that clobbers consumer customization to satisfy a wrong R0 assertion; orchestrator review (agreement≠done) caught + reverted it and fixed the test. **F3 🟡** brief-scoping isn't enforced beyond `forbidden_paths` (Codex also rewrote this HANDOFF). Validation: harness-sync **42/42** (now incl. 41+42), `42-local-only` green, `bash -n` clean.

_Prior this session — 149/149.1/150/150.1 shipped + propagated to 5 consumers; sync-harness MAX_ARG_STRLEN baseline fix; tmux-sentinel recorded as sync-apply-only; `/squad` live dogfood (toy + real). See git log + below._

## Active Work

- **None in flight.** 149/149.1/150/150.1/150.2/150.3 + 151 all shipped to Agent0 + propagated to consumers (`origin/main` @ `5c4cc23`+; 4 tracked consumers committed/pushed; tmux-sentinel local-only auto-skip, tracked tree clean). No active spec; no draft worth pursuing (091 deferred, 138 superseded by 150).

## Next Actions

- **No demand-validated harness item.** Founder decision 2026-06-04: **let real demand drive the next item — do NOT manufacture speculative harness work.** This repo's canonical drift trap is speculative observability/tooling (see the user-level `feedback-speculative-observability` memory + spec 010). The next item should come from: (a) a real product/consumer need the founder names, or (b) another real-feature `/squad` dogfood that surfaces a genuine gap. The one founder-stated forward-intent — visibility = agent runtime self-debug (`.agent0/memory/visibility-intent.md`) — is real but **demand-gated**: build only when a concrete pending question exists that `jq`/`tail`/`grep` can't answer cheaply (none surfaced this session — squad was orchestrated by reading `state.json` with `jq` directly).
- `/squad` worktree-per-agent (v2) remains noted in `rules/squad.md` but unbuilt — single-writer turn-locking did not bottleneck the 151 run, so no demand yet.

## Decisions & Gotchas

- Local-only detection is automatic, not flag-based: a consumer must be a git repo and `git check-ignore` must ignore `.agent0/skills`, `.agent0/context`, and `.agent0/tools`.
- Local-only skips writes to tracked paths using the consumer's ignore engine. This includes COPY_CHECK files, `.claude/settings.json`, `CLAUDE.md`, `.gitignore`, project-core entrypoint mirrors, deletion cleanup of tracked orphans, legacy `.claude/` baseline removal, and runtime skill discovery links under `.claude/skills` / `.agents/skills`.
- Gitignored writes remain active: `.agent0/` harness files and `.agent0/harness-sync-baseline.json` still refresh so local tooling stays current and idempotent.
- **(Corrected — was a stale Codex-turn note)** There is **no** `.gitleaks.toml` first-sync bootstrap: Codex added one to pass a flawed contract test (151 finding F2); the orchestrator **reverted it** (it would clobber consumer-customized gitleaks configs) and fixed the test instead. The customized-refusal for a divergent `.gitleaks.toml` is intact, as designed.
- **(Corrected)** `harness-sync/run-all.sh` now **globs `[0-9][0-9]-*.sh`** (151 finding F1) — it no longer hardcodes 01-40, so 41/42 (and future scenarios) run in the suite automatically. harness-sync suite is 42/42.
