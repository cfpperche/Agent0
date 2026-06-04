# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff through tracked `.codex/hooks.json` after project/hook trust.

See `.agent0/context/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Session 2026-06-04 — spec 151 `sync-harness-local-only` SHIPPED via the first real-feature `/squad` autonomous run (Claude orchestrator ↔ real Codex).** End-to-end dogfood: de-biased planned spec (mechanism (c) auto-detect from `.gitignore`, Claude+Codex independent convergence) → `/squad` pump → green external gate → `ready_for_human_prod` → delivered. Local-only mode auto-detects (via `git check-ignore` on representative `.agent0/` paths) consumers that gitignore the harness, refreshes the gitignored `.agent0/` tree, and **skips every tracked-file write** (so a public consumer like tmux-sentinel gets local dev tooling with zero committable drift). Squad converged in 3 rounds (Claude TDD test → Codex impl → Claude orchestrator-repair), repair_attempts=1.

**The run's payload is its findings (see `docs/specs/151-squad-...notes.md` § Squad dogfood):** **F1 🔴** the gate was *vacuously green* — `harness-sync/run-all.sh` hardcoded scenarios 01-40, so the new `42` (and orphaned `41`) never ran in the suite; the external gate is only as strong as its coverage (fixed: run-all now globs `[0-9][0-9]-*.sh`). **F2 🔴** the peer bent production to a flawed contract test — Codex added a `.gitleaks.toml` bootstrap that clobbers consumer customization to satisfy a wrong R0 assertion; orchestrator review (agreement≠done) caught + reverted it and fixed the test. **F3 🟡** brief-scoping isn't enforced beyond `forbidden_paths` (Codex also rewrote this HANDOFF). Validation: harness-sync **42/42** (now incl. 41+42), `42-local-only` green, `bash -n` clean.

_Prior this session — 149/149.1/150/150.1 shipped + propagated to 5 consumers; sync-harness MAX_ARG_STRLEN baseline fix; tmux-sentinel recorded as sync-apply-only; `/squad` live dogfood (toy + real). See git log + below._

## Active Work

- **Spec 151 — shipped (about to commit/push + propagate).** Files: `.agent0/tools/sync-harness.sh`, `.agent0/context/rules/harness-sync.md`, `.agent0/tests/harness-sync/{42-local-only.sh, run-all.sh}`, spec dir.
- **`/squad` maturity backlog from F1/F2/F3** — see Next Actions; these sharpen the gate-coverage + review discipline for future squad runs.

## Next Actions

1. **Commit + push spec 151**, then **propagate to consumers** — tmux-sentinel is **apply-only** (never commit harness — see `.agent0/memory/tmux-sentinel-sync-no-commit.md`); the other 4 commit harness paths. (Eat-your-own-dogfood: with 151, tmux's sync now auto-skips tracked writes — verify the local-only notice fires there.)
2. **`/squad` F1 follow-up (consider a spec):** a gate-coverage lint — squad.json gates that run a test *suite* should assert the new spec's test is actually executed by it (not just present on disk). The vacuous-green hole is generic to squad gates.
3. **`/squad` F2/F3 follow-up:** strengthen the run brief / `forbidden_paths` defaults (peers can bend code to a bad test or touch unscoped files); consider a "review the test, not just pass it" instruction + a broader default forbidden set (e.g. HANDOFF.md).

## Decisions & Gotchas

- Local-only detection is automatic, not flag-based: a consumer must be a git repo and `git check-ignore` must ignore `.agent0/skills`, `.agent0/context`, and `.agent0/tools`.
- Local-only skips writes to tracked paths using the consumer's ignore engine. This includes COPY_CHECK files, `.claude/settings.json`, `CLAUDE.md`, `.gitignore`, project-core entrypoint mirrors, deletion cleanup of tracked orphans, legacy `.claude/` baseline removal, and runtime skill discovery links under `.claude/skills` / `.agents/skills`.
- Gitignored writes remain active: `.agent0/` harness files and `.agent0/harness-sync-baseline.json` still refresh so local tooling stays current and idempotent.
- The contract test also required normal non-local-only consumers to receive tracked `.gitleaks.toml` on first sync. The script now has a narrow first-sync git-consumer bootstrap adoption path for `.gitleaks.toml`; the existing no-baseline customization refusal remains intact for ordinary hook files.
- `run-all.sh` currently enumerates only scenarios 01-40, so direct 41/42 runs are required evidence until that runner is updated.
