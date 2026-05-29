# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff after opting into the `.codex/config.toml.example` session-handoff hooks.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Spec 115 (remove rule-load-debug) shipped, NOT yet committed.** The whole `rule-load-debug`
capacity is gone: hook script + memory doc `git rm`'d, runtime log/lock + their `.gitignore` lines
deleted, `InstructionsLoaded` registration dropped from `settings.json`, `rule-loads` subcommand
stripped from `probe.sh`, `MEMORY.md` regenerated, and the runtime-state README / capacity-spec-index
/ `capacities.ts` rows removed. `cc-platform-hooks.md` corrected (`6 of these 29`, attribution + dead
pointers severed; event row + empirical dedup finding preserved). Rationale: exercised exactly once
on its 2026-05-13 creation day (18 log rows, 0 since) — canonical `feedback_speculative_observability`
case. Full audit trail in `docs/specs/115-remove-rule-load-debug/` (`spec.md` § Outcome, `notes.md`).
All acceptance scenarios verified PASS; site rebuilt (`dist/` clean — also dropped spec 114's
compaction card; `site/dist` is gitignored).

`main` has **5 committed-unpushed commits** (112 + 113 + 114 from prior sessions). Spec 115's
working-tree changes are **uncommitted** (commits are user-gated). Pre-existing untracked
`docs/specs/091-sdd-debate-runner/` is unrelated (out of scope).

## Active Work

- _None in flight._

## Next Actions

1. **Commit spec 115** (working tree is staged/dirty: 1 deletion staged via `git rm`, ~8 modified +
   2 untracked spec dirs). Then `git push` the 112 + 113 + 114 + 115 commits when ready.
2. Continue the hook-migration arc — the runtime-introspect pair (`.claude/hooks/runtime-capture.sh`
   + `runtime-pre-mark.sh`) → `.agent0/`. After 115, the only remaining `.claude/hooks/*` are that
   pair + `delegation-gate.sh`.
3. vuln-audit spec when prioritized (reminder `r-2026-05-29-spec-the-vuln-audit-capacity`).

## Decisions & Gotchas

- **Three historical-narrative mentions KEPT by design** (not dangling): `propagation-hygiene.md:66`
  (frozen spec-070 cleanup record) and `memory-placement.md:58,247` (accurate spec-096 move-full
  history). Test applied: line describes a *past event that's still true* → keep; describes *live
  wiring of the deleted capacity* → remove. Same precedent spec 114 used for its KEEPs. See
  `docs/specs/115-remove-rule-load-debug/notes.md` § Design decisions.
- **`InstructionsLoaded` is Claude-only** — no Codex analogue, so the hook was correctly `.claude/`-homed;
  removal was a scope/value call, not a migration port. The platform event itself still exists (kept
  in `cc-platform-hooks.md`'s 29-event table).
- **Env:** gitleaks pre-commit active (`core.hooksPath=.githooks`); governance gate blocks `rm -rf`
  + blanket `git add` — use explicit paths + `git rm`; commits are user-gated.
