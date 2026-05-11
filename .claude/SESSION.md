# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state

Spec 012 delivered + validated (commit `df31a1a`). Specs 014 (mcp-recipes-extras) and 015 (monorepo-stack-detect) filled and committed (`554c8f8`). Dogfood roteiros committed in each shrnk repo (`fdd317c` pyshrnk / `8f1f52b` shrnk / `bba06f1` rshrnk).

**Drift discovered late session:** all three shrnks (pyshrnk / shrnk / rshrnk) are at Agent0's spec 001-007 state — they MISS specs 008-012 entirely (hooks, rules, tools, settings entries, CLAUDE.md sections, `.mcp.json.example`). Dogfood for spec 011+012 blocked until shrnks sync.

User chose to resolve via **spec 016 — harness-sync**: ship a `.claude/tools/sync-harness.sh` one-way sync tool (Agent0 → fork). Spec.md filled and **awaits user ratification of the 4 open questions + 10 design decisions before `/sdd plan`**. Three specs untracked: 010 (carryover prior session), 013 (out-of-band scaffold, unknown author), 016 (this session, awaiting ratification).

## WIP

`docs/specs/016-harness-sync/spec.md` — 11 acceptance scenarios + 9 non-goals + 4 open questions. Key decisions awaiting user OK before `/sdd plan`:

- Customization detected by **hash-compare** (file differs from Agent0 + already existed = customized → refuse without `--force`).
- `settings.json` merged structurally-additive (append hook entries, no replace).
- `CLAUDE.md` capacity sections appended before `## Compact Instructions` anchor.
- Scope: only `.claude/*` + a few top-level (`.mcp.json.example`, `.gitleaks.toml`, `.githooks/pre-commit`, `.gitignore`); NEVER touches `src/`, `tests/`, `docs/`, `.mcp.json`, package manifests.
- `--check` is default mode (read-only); `--apply` explicit; `--dry-run` separate.
- Spec 016 v1 syncs `.claude/tests/` too (they ARE part of the harness, the RED→GREEN scenarios travel with the capacity).

Next user turn: ratify (or amend) → `/sdd plan` → `/sdd tasks` → impl → use spec 016 to bring all 3 shrnks up to date → THEN run the dogfood B1/B2/B3 sequence with everything actually active.

## Next steps

1. User ratifies 016 design → `/sdd plan` → `/sdd tasks` → RED tests → impl
2. Sync each shrnk via `bash .claude/tools/sync-harness.sh --apply ~/pyshrnk` (etc.); commit in each fork
3. Begin dogfood B1 (pyshrnk) per its `docs/dogfood-plan.md`. Frontend addition + spec 011 pytest validation + spec 012 hint observation + Playwright MCP visual validation
4. Dogfood B2 (shrnk), B3 (rshrnk) — gap-finding pass on rshrnk per its plan
5. Apply dogfood findings as follow-up specs (e.g. cargo detector for spec 011 if rshrnk surfaces it)
6. Specs 014 + 015 can land at any point (independent of dogfood)

Untracked carryovers:
- `docs/specs/010-audit-forensics/` (prior session)
- `docs/specs/013-lint-validator-extension/` (out-of-band scaffold, unknown author)

## Decisions & gotchas

- **Shrnks were forked at Agent0 spec 007 state.** All three (pyshrnk / shrnk / rshrnk) identical defect: no supply-chain (008/009), no runtime-introspect (011), no mcp-recipes (012). Drift recurs every Agent0 spec; manual propagation doesn't scale. Spec 016 closes the gap permanently.
- **Dogfood plans assume synced state.** The 3 dogfood-plan.md files committed in each shrnk reference Agent0 capacities (probe.sh, mcp-recipes-hint.sh) that DON'T EXIST in those forks today. The plans are correct as future-state docs but cannot be executed until 016 ships and a sync runs. Document this dependency explicitly.
- **Sync tool is one-way (Agent0 → fork) and conservative.** Hash-compare detects customizations; default mode is read-only (`--check`); apply refuses to overwrite without `--force`. NEVER touches product code (`src/`, fork's `tests/`, package manifests). NEVER auto-commits — developer reviews diff.
- **`core.hooksPath` activation stays manual in synced forks.** Same Lazarus reasoning as everywhere else. Sync writes `.githooks/pre-commit` but does not `git config core.hooksPath .githooks` — developer types that command consciously.
- **Spec 016 takes priority over dogfood execution.** Without 016, dogfood is theatre. After 016, dogfood is real validation. Sequence: 016 ship → sync all 3 shrnks → dogfood B1/B2/B3.
- **Specs 014 + 015 independent of this sequencing.** Can land before or after 016. The detect_at refactor (015) is a clean target after 014's OTel/Grafana branches land, but order is flexible.
- **SESSION.md auto-injection has a ~2KB preview budget.** Replace stale content rather than appending — `git log` is the audit trail.
