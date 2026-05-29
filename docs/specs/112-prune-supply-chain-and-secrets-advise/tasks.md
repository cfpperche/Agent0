# 112 — prune-supply-chain-and-secrets-advise — tasks

_Generated from `plan.md` on 2026-05-29. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### A. Deletions
- [x] 1. Delete `.agent0/hooks/supply-chain-preflight.sh`, `.claude/hooks/supply-chain-advise.sh`, `.claude/hooks/secrets-advise.sh`.
- [x] 2. Delete `.claude/tests/supply-chain/` and `.claude/tests/supply-chain-composer/` (whole dirs).
- [x] 3. Delete `.claude/rules/supply-chain.md`.

### B. Settings + gitignore
- [x] 4. `.claude/settings.json` — remove the three registrations (supply-chain-preflight PreToolUse, supply-chain-advise PostToolUse, secrets-advise PostToolUse). Verify `secrets-preflight.sh` + `propagation-advise.sh` remain. Validate JSON parses.
- [x] 5. `.gitignore` — remove `.agent0/supply-chain-audit.jsonl` + `.lock` lines; keep `secrets-audit.jsonl`.

### C. Docs (entrypoints + README)
- [x] 6. `CLAUDE.md` — remove the `## Supply chain` managed-block section.
- [x] 7. `AGENTS.md` — remove the `## Supply chain` section.
- [x] 8. `README.md` — remove the supply-chain table row; drop "supply-chain" from the override-marker gate list; remove the "Pick supply-chain mode" setup step (renumber following steps).

### D. Perf / bench / latency (atomic — keep consistent)
- [x] 9. `.claude/.perf-baseline.json` — remove the `supply-chain-preflight.sh` entry; confirm JSON parses.
- [x] 10. `.agent0/tools/bench-hooks.sh` — remove `supply-chain-preflight.sh` from `HOOK_NAMES`; fix the audit-log + hook comments.
- [x] 11. `.claude/tests/hook-chain-latency/01-baseline-exists.sh` — remove `supply-chain-preflight.sh` from the asserted-hook loop.

### E. Twin-comment + fixtures
- [x] 12. `.claude/hooks/runtime-capture.sh` — drop the "tokeniser-twin with supply-chain-preflight.sh" cross-ref comments; keep the tokeniser code.
- [x] 13. `.claude/tests/harness-sync/05-settings-merge-additive.sh` — swap supply-chain fixture entry for a surviving hook; fix the assertion comment.
- [x] 14. `.claude/tests/harness-sync/06-claude-md-section-append.sh` — swap `## Supply chain` example section for a surviving one.

### F. Canonical memory index
- [x] 15. `.agent0/memory/capacity-spec-index.md` — remove the supply-chain capacity rows.

### G. Delegated cross-ref sweep (OQ-1 policy)
- [x] 16. Dispatch ONE sub-agent (5-field brief) to sweep `.claude/rules/*.md` (minus the deleted supply-chain.md) + `.agent0/memory/*.md` (minus capacity-spec-index, done in task 15) for supply-chain references; apply OQ-1 policy: drop named supply-chain exemplars from gate-family lists, remove dead `supply-chain.md` links, remove live-capacity prose; LEAVE generic "other gates" mentions. DELIVERABLE: edited-file list + per-file change summary appended to `docs/specs/112-*/notes.md`.

### H. secrets-scan rule excision
- [x] 17. `.claude/rules/secrets-scan.md` — remove § *Soft advisory* + `CLAUDE_SECRETS_ADVISE_ON_EDIT` references + the advise-hook row in § *What fires* / § *Escape hatch*; keep native gate + preflight + override + audit sections.

### I. vuln-audit direction
- [x] 18. Add a `/remind`-shaped reminder to `.agent0/reminders.yaml` to spec the vuln-audit capacity (research osv-scanner/npm-audit/pip-audit + trigger surface).
- [x] 19. Update `.agent0/HANDOFF.md`: note 112 removed supply-chain + secrets-advise, propagation-advise verified maintainer-only, vuln-audit is the next direction.

## Verification

- [x] 20. `git grep -l -i "supply.chain" -- ':!docs/specs/'` returns only intentional survivors (none should present it as a live capacity; runtime-capture tokeniser code comments may keep a generic note). No reference to `supply-chain.md`, `supply-chain-preflight.sh`, or `supply-chain-advise.sh` in live files.
- [x] 21. `git grep -l "secrets-advise\|ADVISE_ON_EDIT" -- ':!docs/specs/'` returns nothing.
- [x] 22. `jq . .claude/settings.json` parses; `jq` shows zero `supply-chain`/`secrets-advise` commands; `secrets-preflight.sh` + `propagation-advise.sh` present.
- [x] 23. `sync-harness.sh` `COPY_CHECK_EXCLUDE` still lists all 3 propagation-advise paths (propagation verify-only acceptance).
- [x] 24. Run remaining test suites (`harness-sync`, `hook-chain-latency`, `secrets-scan`, `propagation-advisory`, `typecheck-advisory`) — all green; no orphaned supply-chain suite.
- [x] 25. `.gitignore` no longer lists supply-chain-audit; still lists secrets-audit. CLAUDE.md/AGENTS.md/README carry no live supply-chain capacity.

## Notes

_Populated during execution._
