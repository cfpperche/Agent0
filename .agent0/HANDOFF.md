# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff after opting into the `.codex/config.toml.example` session-handoff hooks.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Spec 116 (remove runtime-introspect) shipped, NOT yet committed.** The capacity is gone in full:
`runtime-capture.sh` + `runtime-pre-mark.sh`, `probe.sh`, `runtime-introspect.md` rule, the maintainer
memory, both test suites (`runtime-introspect/` 17 + `runtime-capture-php/` 7), and the
`.agent0/.runtime-state/` snapshot. 3 settings.json registrations removed (`PostToolUseFailure` event
now absent). `.claude/hooks/` now holds **only `delegation-gate.sh`**. ~25 cross-refs rewired
(CLAUDE/AGENTS section, session-start readout, delegation.md `/goal` verifier, runtime-capabilities
matrix + `check-instruction-drift.sh` required-row list, php-laravel-support, cc-platform-hooks,
bench-hooks/perf-baseline, site card + marketing copy). Historical-narrative mentions KEPT per the
spec-115 test. Decision rationale + per-file keep-vs-rewire in `docs/specs/116-remove-runtime-introspect/`
(`spec.md` § Outcome, `notes.md`). Site rebuilt — `dist/` clean.

Spec 115 (rule-load-debug) is committed + pushed (`94f1c6e`); `origin/main` == that. Spec 116's
working-tree changes are **uncommitted** (commits user-gated). Pre-existing untracked
`docs/specs/091-sdd-debate-runner/` unrelated (out of scope).

## Active Work

- _None in flight._

## Next Actions

1. **Commit + push spec 116** when ready (working tree dirty: ~30 files modified + 5 git-rm deletions
   + the 116 spec dir).
2. **Pre-existing test failure to fix separately:** `typecheck-advisory/08-globs-nested-workspace.sh`
   FAILS because Node 24's default compile cache (`node-compile-cache/`) pollutes the test's isolated
   TMPDIR git workspace → validator counts 102 prod files. NOT a spec-116 regression (confirmed: no
   changes under `typecheck-advisory/` or `validators/run.sh`). Fix = set `NODE_DISABLE_COMPILE_CACHE=1`
   or `.gitignore` the cache in the test's tmp repo. Scope a small spec or one-off.
3. vuln-audit spec when prioritized (reminder `r-2026-05-29-spec-the-vuln-audit-capacity`).

## Decisions & Gotchas

- **The harness pruning arc continues (112→113→114→115→116).** runtime-introspect removed as
  overengineering: the `SubagentStop` validator (spec 111) is the enforcement path; the parent sees
  Bash stdout inline; the read-side probe had no evidence of use. After 116 the only first-party
  `.claude/hooks/` script is `delegation-gate.sh` (legitimately Claude-only — gates the `Agent` tool).
- **Rode-along marketing fix:** `site/src/i18n/strings.ts` lifecycle sentence also named the
  already-removed `post-edit validator` (111) + `PreCompact` (114) — rewrote to surviving capacities
  rather than ship false copy. Documented in `notes.md`.
- **Env:** gitleaks pre-commit active (`core.hooksPath=.githooks`); governance gate blocks `rm -rf`
  + blanket `git add` (and blocked my `rm -rf` mid-session — use explicit paths + `git rm`/`git mv`);
  commits are user-gated.
