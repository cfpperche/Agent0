# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state

Eleven capacities on `main`, all green. Last delivered: spec 009 (`supply-chain-block`) — Bash preflight blocks dep-mutating commands by default; `CLAUDE_SUPPLY_CHAIN_BLOCK=0` falls back to advisory; `CLAUDE_SKIP_SUPPLY_CHAIN_SCAN=1` disables both layers. Supply-chain suite 11/11 PASS via `bash .claude/tests/supply-chain/run-all.sh`.

## WIP

None.

## Next steps

No spec in flight. Candidates:

- **Live-dogfood spec 009 against a fresh fork** — first-fork friction is the load-bearing risk (`docs/specs/009-supply-chain-block/plan.md` § *Risks*). Best target: a sibling not yet exercised this cycle (e.g. `/home/goat/rshrnk` cargo branch).
- **Go dogfood pass** — last unverified validator branch; low expected yield, defer until something Go-shaped becomes interesting.
- **Extend tokenizer flag allowlist** — narrowly, only if a real session produces noisy `packages` arrays in the supply-chain audit log.
- **Audit-log forensics tooling** — `jq` one-liners (block rate per session, top blocked packages, override-reason patterns) packaged under `.claude/tools/` if forensic analysis becomes recurring.

## Decisions & gotchas

Process-knowledge that doesn't fit cleanly in any `.claude/rules/*.md` (capacity-specific gotchas live there — don't duplicate):

- **Dogfood until two consecutive passes yield 0 findings, then graduate.** Yield-decay is the pivot signal — pyshrnk surfaced 2, shrnk 0; after that, the next session's value is in promoting the capacity, not finding more bugs.
- **Every advisory-capacity needs a live-dogfood pass before "done", not just smoke tests.** Smoke tests run with clean fixtures and trust the audit log; real-session usage surfaces tokenizer leaks and stderr-observability gaps that fixtures don't.
- **For hook changes with a clean spec, write all RED tests first.** Spec 009: 4 failing tests written upfront, then a single GREEN patch pass — 11/11 PASS on first attempt with zero iteration.
- **SESSION.md auto-injection has a ~2KB preview budget.** When SESSION.md exceeds it, only the preview reaches context; the full file lands at a persisted path on disk. Keep this file terse — replace stale content rather than appending (`git log` is the audit trail).
