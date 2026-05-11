# Session handoff

Read at the start of every Claude Code session and updated at the end. Captures work-in-progress context that wouldn't otherwise survive between sessions.

See `.claude/rules/session-handoff.md` for the protocol.

---

## Current state

Eleven capacities on `main`, all green. Last delivered: rshrnk live-dogfood pass for spec 009 + 2 cargo coverage fixes (commits `cc9d981` / `55cc935` / `158a9a3`):

- cargo verb whitelist gained `install` (was `add update` only — asymmetric with npm/pip/yarn/bun/pnpm whose `install` verb is detected too)
- value-taking flag allowlist gained `--features` / `-F` (feature names were leaking as packages, e.g. `cargo add tokio --features full` → `["tokio","full"]`)

Supply-chain suite 12/12 PASS via `bash .claude/tests/supply-chain/run-all.sh`.

## WIP

None.

## Next steps

No spec in flight. Candidates:

- **Second cargo dogfood pass** — yield-decay rule isn't satisfied (rshrnk surfaced 2 findings; need one 0-finding pass to graduate). Another sibling fork or extended rshrnk probes (workspace flags, `cargo install --path .` local installs, `cargo remove`).
- **Go dogfood pass** — last unverified validator branch; low expected yield, defer until something Go-shaped becomes interesting.
- **Audit-log forensics tooling** — `jq` one-liners (block rate per session, top blocked packages, override-reason patterns) packaged under `.claude/tools/` if forensic analysis becomes recurring.

## Decisions & gotchas

Process-knowledge that doesn't fit cleanly in any `.claude/rules/*.md` (capacity-specific gotchas live there — don't duplicate):

- **Dogfood until two consecutive 0-finding passes, then graduate (per-ecosystem).** Tally: bun=0, uv=2, cargo=2. Bun graduated; cargo needs another 0-finding pass.
- **Every capacity needs a live-dogfood pass before "done".** Smoke tests miss tokenizer leaks, stderr-observability gaps, and recursive FPs (the cargo-install verb fix's commit body tripped its own new block — caught via OVERRIDE multi-line shape outside the heredoc).
- **For hook changes with a clean spec, write all RED tests first.** Two confirmations — spec 009 (4 REDs → 11/11 first attempt) and rshrnk fixes (2 REDs → 12/12 first attempt).
- **SESSION.md auto-injection has a ~2KB preview budget.** When SESSION.md exceeds it, only the preview reaches context; the full file lands at a persisted path on disk. Keep this file terse — replace stale content rather than appending (`git log` is the audit trail).
