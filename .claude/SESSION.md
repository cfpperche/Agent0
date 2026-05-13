# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state

**Dogfood→fix→validate-in-fork loop closed end-to-end 2026-05-13.** 3 Agent0-side fixes derived from shrnk-mono dogfood pass `a6c0585e`, each validated in a follow-up dogfood pass in the same fork:

- `02364e4 fix(validator)` — exclude supply-chain lockfile basenames (`*.lock *.lockb go.sum */go.sum`) from TDD warning loop. Closes false-positive `no_test_change_for_prod_edit` on `bun.lock` mutations.
- `e9b7f53 feat(supply-chain)` — detect bare lockfile-resolve install (`{npm,pnpm,bun}.{install,i}`) with dirty manifest (`package.json` / `pyproject.toml` / `Cargo.toml` / `go.mod` via `git -C $PROJECT_DIR status --porcelain`). New audit values `advisory-bare-install` + `advisory-bare-install-override`. Closes parent-edit + bare-install coverage gap (Edit advisory was sub-agent-only; bare install audited `skip-not-install`).
- `f716452 fix(validator)` — `set -f` around classification loop. Closes pathname-expansion bug where unquoted `$excluded_globs` got pathname-expanded against cwd before the case stmt (root match → literal compare → nested workspace manifests leaked). Surfaced during validation of `02364e4` in commit `d4eada2` (shrnk-mono). Test 08 sanity-checked: revert reproduces leak, restore fixes.

Validation cycle in shrnk-mono (same session_id `a6c0585e`): `e424bda` → `d4eada2` → `adf6217` → `42a3593` → `dba0bd5` → `508e95f`. Final pass status: "cleanest dogfood pass yet" — zero new reminders accumulated. Supply-chain audit confirmed `advisory-bare-install`/`override` shapes match design; meta-gotcha "commit message FP on supply-chain prose" hit twice and recovered with documented OVERRIDE workaround.

## WIP

**Spec 025 (mcp-product-pipeline) DRAFT in working tree — uncommitted, 35 tasks pending.** `docs/specs/025-mcp-product-pipeline/{spec,plan,tasks}.md` drafted 2026-05-12 17:21-17:24 in a prior session, never committed. Proof-of-concept of "Agent0 stays a thin harness core; capability extensions ship as opt-in MCP servers in `packages/`". 12-step product-planning pipeline (Discovery 1-4 / Identity 5-7 / Specification 8-12) lifted from anthill SDLC. Activation = single `.mcp.json` block, zero hooks/rules/CLAUDE.md mutations in forks. Handoff to `/sdd` at step 12. Next session: commit drafts as baseline OR revise first, then walk tasks.md Phase A→D.

## Next steps

1. **Spec 025 decision** — commit drafts as baseline (`docs(specs): add 025 mcp-product-pipeline draft`) and then walk implementation, OR revise spec/plan first.
2. **CC hooks underused reminder** (due 2026-05-13, only remaining bullet) — inventory the 29 events from `.claude/memory/cc-platform-hooks.md` vs `.claude/settings.json` registered, identify 1-2 gaps worth prototyping. `UserPromptSubmit` (detect ambiguous prompts) is the named candidate.
3. **shrnk-mono future dogfood candidates** (if appetite): MCP recipes activation, browser-auth signal, secrets-scan compound forms, validator multi-stack monorepo lint walk.
4. **Pyshrnk CLAUDE.md reconciliation** — Starlette adoption vs "no frameworks" rule conflict (carryover, no progress this session).

## Decisions & gotchas

- **Validator's TDD classification loop needs `set -f` discipline.** Unquoted globs in `for g in $glob_str` pathname-expand BEFORE the case stmt sees them. In populated repos this collapses `*.json` to literal root matches → case becomes literal compare → nested workspace paths leak. The `set -f` guard restores proper case-pattern glob matching against `/`-containing paths. Closed by `f716452`.
- **Supply-chain block fires on commit-message PROSE mentioning manager+verb pairs.** Documented gotcha confirmed twice in shrnk-mono session `a6c0585e` (2026-05-12T00:30:35Z, 00:33:17Z). Recovery: multi-line `# OVERRIDE: <reason>` marker on its own line outside the heredoc. Tokenizer doesn't differentiate prose from real commands.
- **`bun install` (bare) IS a supply-chain signal when manifest is dirty.** Pre-`e9b7f53` design treated all bare installs as `skip-not-install` (lockfile resolve). Post-fix, the dirty-manifest predicate via `git status --porcelain` flips it to `advisory-bare-install`. OVERRIDE marker silences with audit trail.
- **`sync-harness.sh --force --force-except='<glob>'`** preserves fork-side stack-specific files (notably `.gitignore` with uncommented stack patterns) while accepting drift on everything else. Used by shrnk-mono in `42a3593`.
- **SESSION.md ~2KB preview budget** — replace stale content; `git log` is the audit trail. This file is currently the actively-load-bearing handoff, NOT a journal of completed work.
