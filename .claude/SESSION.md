# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state

Spec 016 (harness-sync) **delivered**. All 12 acceptance scenarios green; sync tool applied to all 3 shrnks; each is now at zero drift vs Agent0.

- pyshrnk `92c7013` — adopts specs 008-012 + 016
- shrnk `c10927a` — same
- rshrnk `a1a14e8` — same

The drift that blocked dogfood is closed. Specs 011 (probe.sh) and 012 (mcp-recipes-hint.sh) now exist in each fork — dogfood B1/B2/B3 are unblocked.

## WIP

Spec 016 not yet committed in Agent0. The implementation files (`.claude/tools/sync-harness.sh`, `.claude/rules/harness-sync.md`, `.claude/tests/harness-sync/`, CLAUDE.md addition, spec/plan/tasks updates) are all in working tree.

**Scope expansion landed during Phase 4 dry-run:** `--force-except=GLOB[,GLOB...]` flag (scenario 12) — chosen over global-force-only after dry-runs showed `.gitignore` had real fork-specific patterns while other customized files were drift-only. Canonical use: `--apply --force --force-except='.gitignore'`.

**Plan divergence captured:** CLAUDE.md uses heading-set comparison (not full-file hash), because fork-authored body always differs from Agent0. Documented in plan.md.

**Order-preservation fix during apply:** initial CLAUDE.md merge sorted missing headings alphabetically, scrambling the section order in the fork. Fixed via `grep -Fxv` walk that preserves Agent0's natural order.

## Next steps

1. Commit spec 016 in Agent0 (single commit covering impl + spec + tests).
2. Begin dogfood B1 (pyshrnk) per its `docs/dogfood-plan.md` — frontend addition + pytest validation + Playwright MCP visual check.
3. Dogfood B2 (shrnk), B3 (rshrnk) — gap-finding pass on rshrnk.
4. Apply dogfood findings as follow-up specs (cargo detector for spec 011 likely from rshrnk).
5. Specs 014 + 015 land at any point (independent of dogfood).

Untracked carryovers (prior sessions, awaiting review):
- `docs/specs/010-audit-forensics/`
- `docs/specs/013-lint-validator-extension/`

## Decisions & gotchas

- **`--force-except=GLOB` is the per-file safety hatch** for forks where some customized files are drift-only (`session-start.sh`, `secrets-scan.md`, `validators/run.sh`) but others are real customization (`.gitignore` with stack patterns). Without it, the user had to choose between leaving drift OR clobbering customization — neither tenable. Glob list is comma-separated; matched via Bash `case` patterns against the relative path.
- **`.gitignore` is always real customization.** Forks add stack-specific lines (Python: `.venv/`, `__pycache__/`; JS: `node_modules/`; Rust: `target/`) that Agent0 (stack-agnostic template) never has. Hand-merge in the same commit as the sync is fine — keeps the audit trail clean.
- **CLAUDE.md merge preserves Agent0's section order.** Initial impl sorted alphabetically (bug); fixed before any commit landed. The order matters for readability: `Spec-driven development` → `Delegation` → capacities → `Compact Instructions`.
- **`core.hooksPath` activation stays manual in each synced fork.** Sync wrote `.githooks/pre-commit` but does NOT run `git config core.hooksPath .githooks` — Lazarus-vector reasoning per `.claude/rules/secrets-scan.md`. Each fork developer activates consciously, once.
- **Dogfood plans assumed pre-sync state.** Those `docs/dogfood-plan.md` files in each shrnk reference Agent0 capacities (probe.sh, mcp-recipes-hint.sh) that NOW EXIST in the synced forks. The plans are accurate and executable.
- **SESSION.md auto-injection has a ~2KB preview budget.** Replace stale content rather than appending — `git log` is the audit trail.
