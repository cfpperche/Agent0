# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects/nags through hooks; Codex receives the same handoff after opting into the `.codex/config.toml.example` session-handoff hooks.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

**Spec 112 (prune-supply-chain-and-secrets-advise) implemented — pending commit.** A critical re-eval of the three advise hooks (2026-05-29) led to:

- **Supply-chain capacity REMOVED entirely** — `supply-chain-preflight.sh`, `supply-chain-advise.sh`, `supply-chain.md`, both test dirs, settings registrations, `.gitignore` audit entries, CLAUDE.md/AGENTS.md/README sections, perf-baseline cell, bench-hooks entry, `.codex/config.toml.example` block, site capacity card + i18n prose, and all cross-refs across rules/memory. Decision: don't gate lib usage at install time.
- **`secrets-advise.sh` REMOVED** — redundant with the commit-time gitleaks gate + `secrets-preflight.sh`. secrets-scan.md § Soft advisory excised; native gate + preflight untouched.
- **`propagation-advise.sh` verified maintainer-only** — already in `sync-harness.sh` `COPY_CHECK_EXCLUDE`; no change needed (verify-only).

Working tree dirty with all 112 edits + staged deletions. Pre-existing untracked `docs/specs/091-sdd-debate-runner/` remains out of scope.

## Active Work

- _None in flight._ Spec 112 edits are complete and validated, awaiting the user's commit decision.

## Next Actions

1. **Commit spec 112** (the user gates commits). Suggested: `feat(112): remove supply-chain capacity + secrets-advise hook; propagation-advise stays maintainer-only`.
2. **Vuln-audit is the replacement direction** (reminder `r-2026-05-29-spec-the-vuln-audit-capacity`). When prioritized: `/sdd new`, research osv-scanner vs npm audit vs pip-audit vs per-ecosystem, decide trigger surface (on-demand skill vs routine/cron vs commit gate). Philosophy: detect vulnerable *installed* libs and act — never block installs.
3. **Hook migration arc continues** (prior session's thread): the remaining `.claude/hooks/*` to port to runtime-neutral `.agent0/` are now just `propagation-advise.sh` and the runtime-introspect pair (`runtime-capture.sh` / `runtime-pre-mark.sh`). The supply-chain + secrets advise hooks are gone, not ported.

## Decisions & Gotchas

- **"Is it necessary?" precedes "should we port it?"** — 112 deleted two capacities instead of porting them in the 106-111 arc. The migration is the right moment to prune dead weight.
- **propagation-advise was ALREADY consumer-excluded** — the "consumers don't need it" directive was a no-op; surfaced by reading `sync-harness.sh:216-218`. Don't rubber-stamp work that's already done.
- **Footprint had hidden surfaces** — initial `--include` greps missed `.codex/config.toml.example` (ships to consumers) and `site/src/i18n/*.ts`. A broad `git grep` (no extension filter) caught them. Always sweep without filters before declaring a removal complete.
- **Scope-discipline call:** the site's pipeline-prose still names "post-edit validator" (spec 111's debt, not 112's) — intentionally left for a future site refresh.
- **Settings changes need session restart**; the removed hooks stayed registered+active this session (advisory/non-blocking, no functional impact). Verified removal via `jq` on settings.json, not by triggering hooks.
- **Consumer auto-prune of orphaned settings entries is deferred** (additive merge); file deletions DO propagate via the sync deletion pass.
