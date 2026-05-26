# Session handoff

Canonical runtime-neutral handoff for Agent0 sessions. Claude Code injects and enforces this file through hooks; Codex reads and updates it by convention through `AGENTS.md`.

See `.claude/rules/session-handoff.md` for the protocol, 4 KB size discipline, fallback behavior, and reader-side truncation defense.

---

## Current State

Spec 093 (runtime-capability-registry) shipped and **audited OK by Claude Code**: `.claude/rules/runtime-capabilities.md` carries 12 capacities × `Claude Code` + `Codex CLI` cells in the six-state vocabulary; AGENTS.md `## Codex Capability Tiers` removed (replaced by registry pointer + skeptical default); CLAUDE.md / AGENTS.md managed blocks byte-identical; `check-instruction-drift.sh` enforces the 5 anchor invariants (a)-(e); `.claude/tests/runtime-capabilities/` has 8 fixtures green. Validation at audit: runtime-capabilities 8/8, instruction-drift 6/6, harness-sync 33/33, drift-check on real repo exit 0, `git diff --check` clean.

Spec 094 (hook-chain-latency) **scaffolded in parallel** during 093 review window: `spec.md` filled with empirical baseline (4 PreToolUse(Bash) hooks × 20-50 ms each; ~150-300 ms per Bash call; gitleaks fast at ~33 ms, NOT bottleneck). `plan.md` / `tasks.md` still placeholder — next step `/sdd plan`.

Specs 090, 092, 093 shipped. Spec 091 (sdd-debate-runner) remains paused and **untracked**.

## Active Work

_None._

## Next Actions

1. Decide whether to proceed with `/sdd plan` for 094 (hook-chain-latency) next, or pivot to MCP parity (would become 095) per the `MCP recipes` registry row.
2. The illustrative example `planned: 094-mcp-parity` in 093 spec.md Scenario 1 is now misleading since 094 is hook-chain-latency. Maintainer call: leave as-is (`e.g.` example) or rewrite to `NNN-mcp-parity`.
3. Keep spec 091 paused and untracked unless explicitly resumed.
4. Any future spec touching runtime support must update `.claude/rules/runtime-capabilities.md` in the same change.

## Decisions & Gotchas

- 093 registry path is `.claude/rules/runtime-capabilities.md` — `.agent0/*` rejected in debate because spec 092 made that namespace per-project state. Existing `.claude/rules/*` sync glob covers it.
- YAML/JSON sidecar rejected in Round 2: two canonical files would reintroduce drift. Markdown canonical; the 5 anchor checks don't parse cells. Promote to schema only when a real machine-read need surfaces.
- `## Codex Capability Tiers` is permanently gone — drift check (c) makes it irreversible. Fork-local reintroduction uses `AGENTS.override.md`.
- `MINIMUM_SET` array in `check-instruction-drift.sh` is a 2nd source of truth alongside spec Scenario 1's 12-row enumeration; comment cites spec as canonical.
- `.claude/tests/instruction-drift/04` and `06` re-purposed for the new contract and `source` `../runtime-capabilities/fixtures.sh` — minor cross-suite coupling vs inline-fixture style of siblings; not a regression.
- 093 implementation by Codex + 094 scaffold by Claude ran in parallel without collision because they touched disjoint paths.
