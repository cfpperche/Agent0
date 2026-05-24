# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol (4 KB size discipline + reader-side truncation defence).

---

## Current state

**Session 2026-05-24 (3rd) — complete propagation-hygiene audit shipped.** Five-tier sweep across the entire fork-bound surface (`.claude/{hooks,rules,tools,validators,skills,tests,agents}/`, CLAUDE.md, root configs). Final scan returns **zero residuals**. All test suites pass; sync-harness end-to-end validated against `mei-saas`.

3 commits pushed:

- **`2851191`** — A+B+C cleanup (49 files, +162/-184): specific-fork names (mei-saas/shrnk/pyshrnk) stripped from rules; personal `/home/goat/*` paths → `~/Agent0` / `~/some-fork`; spec-NNN in stderr templates → `Rule: <path>` pointers; memory-file pointers stripped; memory basenames-as-examples in memory-placement.md generalized.

- **`f230186`** — D-tier cleanup (80 files, +364/-460): **all anthill references stripped** from `/product` (~121 across 47 files; methodology preserved standalone — Torres, Cagan, Lenny, Dunford, GDPR, etc.); **all spec-NNN refs stripped** from `/product` docs; **fork-portable tests** — `05-rule-cross-reference.sh` + `06-migration-shape.sh` DELETED (tested patterns that don't exist in forks).

- **`0849b26`** — final residual sweep (159 files, +210/-210): test-file headers, fixture paths (`/home/goat/shrnk` → `/tmp/shrnk-fixture`; `rshrnk` → `sample-crate`), rule-body residuals, skill-toolkit spec-033 refs.

D3 kept by design: Agent0 naming in `harness-sync.md` — the tool IS Agent0, flag IS `--agent0-path`.

## WIP — resume point

**No active WIP.** All goal hook conditions satisfied. Working tree clean.

## Next steps

1. **No immediate carryover.** Audit complete; future drift auto-surfaces via `memory/propagation-hygiene.md`.
2. **Optional**: next sync-harness against mei-saas/codexeng propagates the cleaned content (dry-run validated — clean delta beyond the 2 deleted tests).
3. **Dated reminders**: 029 (05-30) · 035 (06-07) · 046 (07-01) · 060 (07-19).

## Decisions & gotchas

- **Propagation-hygiene memory empirically validated** by 3 commits totaling 288 files. The "anthill basenames-as-examples" follow-up flagged at L57 of that memory is fully resolved.
- **Sub-agent delegation worked well for editorial scope.** Two opus sub-agents (D1 anthill + D2 spec-NNN) handled ~210 edits each across ~47-77 files. Brief shape: clear constraints + survey commands + DONE_WHEN grep. Reports verifiable.
- **Sed sweeps + surgical Edits is the right mix.** ~60% sed-pattern bulk; ~40% surgical Edit for context-sensitive rewrites. Pure-sed creates ungrammatical residuals; pure-Edit is 10× tool calls.
- **`# Spec NNN VN —` was a near-miss.** Sed regex needed `(\s[A-Z]+)?` to catch the `V7` version-letter variant.
- **Test fixture paths matter for fork-portability.** Hardcoded `/home/goat/<repo>` in fixture command strings would resolve to nonexistent paths in fork CI; replaced with `/tmp/<name>-fixture` generics.
- **Methodology citations are durable.** "(Torres OST)", "(Lenny 1-pager)", "(Cagan SVPG)", "(April Dunford)", "(GDPR Art 25)", "(Nielsen heuristics)" survived as standalone — industry-canonical, fork-friendly, zero-leak.

## Carryover (orthogonal — not touched this session)

- `docs/specs/074-subagent-personas/` — untracked draft; leave for originating session.
