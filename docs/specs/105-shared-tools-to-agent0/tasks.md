# 105 — shared-tools-to-agent0 — tasks

_Generated from `plan.md` on 2026-05-28. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. `git mv` the eight scripts (`sync-harness`, `probe`, `check-instruction-drift`, `bench-hooks`, `run-routine`, `install-routines`, `uninstall-routines`, `codex-local-env`) + `lib/managed-block.sh` from `.claude/tools/` to `.agent0/tools/`; confirm `.claude/tools/` is gone (no tracked files left).
- [x] 2. Repoint `sync-harness.sh`'s four internal self-refs: `COPY_CHECK_GLOBS` (`.claude/tools|*.sh` → `.agent0/tools|*.sh`), `COPY_CHECK_FILES` lib entry, `MANAGED_BLOCK_LIB` fallback, `_self_rebootstrap` `rel=`.
- [x] 3. Repoint the moved tools' own content refs (docstrings, self-invocation, cross-tool calls): `probe.sh`, `check-instruction-drift.sh`, `install-routines.sh`, `bench-hooks.sh`, `run-routine.sh`, `uninstall-routines.sh`; verify `codex-local-env.sh`.
- [x] 4. Repoint the three rule `paths:` frontmatter globs: `harness-sync.md` (sync-harness), `runtime-capabilities.md` (check-instruction-drift), `runtime-introspect.md` (probe).
- [x] 5. Rewrite rule bodies + skills: `harness-sync.md` (12, incl. § Manifest scope + § Self-rebootstrap text), `runtime-introspect.md`, `runtime-capabilities.md`, `routines.md`, `delegation.md`, `memory-placement.md`, `session-handoff.md`; `product/SKILL.md`, `routine/SKILL.md`, `routine/scripts/list.sh`.
- [x] 6. Rewrite hooks: `.agent0/hooks/routines-readout.sh`, `session-start.sh`; `.claude/hooks/propagation-advise.sh` (+ verify its shipped-surface path set picks up `.agent0/tools/`).
- [x] 7. Rewrite `CLAUDE.md` + `AGENTS.md` identically (managed-block byte-equality); then `.agent0/HANDOFF.md`, `.agent0/.runtime-state/README.md`, `.claude/tests/harness-sync/README.md`.
- [x] 8. Rewrite current-mechanism memory: `hook-chain-latency.md`, `hook-chain-maintenance.md`, `rule-load-debug.md`, `runtime-capabilities-maintenance.md`, `runtime-introspect-maintenance.md`, `propagation-advisory-maintenance.md`, `propagation-hygiene.md` (lines 22 + 68). **LEAVE** `cc-platform-hooks.md:138` (frozen historical narrative).
- [x] 9. Rewrite `.agent0/routines/hook-chain-bench.md`, `.codex/config.toml.example`, `site/src/i18n/strings.ts` (3 locales).
- [x] 10. Rewrite test refs: hand-verify `harness-sync/33`, `instruction-drift/05`, `codex-mcp-recipes/03`; sed + `git diff` spot-check the remaining `harness-sync/*`, `hook-chain-latency/{02,03}`, `runtime-capabilities/*`, `runtime-introspect/{05,07,09}`, `project-memory/02`.
- [x] 11. Add the one-line self-rebootstrap-on-relocation gotcha to `harness-sync.md` § Gotchas (spec § Open question disposition).

## Verification

- [x] 12. Smoke the relocated tools: `bash .agent0/tools/probe.sh last-run` and `bash .agent0/tools/sync-harness.sh --agent0-path=. --check .` run without "file not found" (acceptance scenarios 1, 4).
- [x] 13. Run suites green: `harness-sync`, `instruction-drift`, `runtime-introspect`, `runtime-capture-php`, `githooks-activation`, `hook-chain-latency`, `runtime-capabilities`, `codex-mcp-recipes`, `project-memory`.
- [x] 14. `grep -rn '\.claude/tools/'` across the live surface (everything except `docs/specs/`) returns only the intentional `cc-platform-hooks.md:138` historical mention; re-grep all rule frontmatter confirms no `paths:` glob still points at `.claude/tools/`; `git diff --check` clean.
- [x] 15. `sync-harness.sh --apply --dry-run` against a scratch consumer shows `.agent0/tools/*.sh` copied + old `.claude/tools/*.sh` flagged for orphan removal (acceptance scenario 3).
- [x] 16. Flip umbrella 102 § Gap matrix row 6 status to `shipped`; flip this spec's `**Status:**` to `shipped`; append `notes.md` decision entries; update `.agent0/HANDOFF.md`.

## Notes

_Populated during execution._
