# 096 — maintainer-rules-to-memory — tasks

_Generated from `plan.md` on 2026-05-27. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Phase 1 — Pre-flight grep (catch surface area before mutating)

- [ ] 1. Run `grep -rln -E 'hook-chain-latency|compaction-continuity|rule-load-debug' .claude/ CLAUDE.md AGENTS.md` and save the result to `notes.md` under a `### 2026-05-27 — parent — pre-move cross-ref inventory` entry. This is the load-bearing surface for the rewire step; anything missed here gets caught by Phase 5 (re-grep) but earlier discovery is cheaper.

- [ ] 2. Grep also for runtime reads (not just text mentions): `grep -rn -E '(cat|head|tail|<) .*\.claude/rules/(hook-chain-latency|compaction-continuity|rule-load-debug)' .claude/`. Should be empty; if a hook or tool literally reads the file at runtime, that's a blocker that changes the plan (would need a redirect, not just a path rewrite).

### Phase 2 — Create memory files

- [ ] 3. Create `.claude/memory/hook-chain-latency.md`: copy the current body of `.claude/rules/hook-chain-latency.md` verbatim, prepend frontmatter (`name: hook-chain-latency`, `description: PreToolUse(Bash) chain latency budget + bench tooling for maintainers extending the hook chain.`, `metadata.type: reference`, `metadata.created_at:` set to today UTC ISO-8601). Verify the frontmatter validator accepts it (advisory line should be silent on stderr after the write).

- [ ] 4. Create `.claude/memory/compaction-continuity.md`: same pattern. Description: `PreCompact+SessionStart snapshot pair preserving raw signal across /compact; mechanism + retention details.`

- [ ] 5. Create `.claude/memory/rule-load-debug.md`: same pattern. Description: `Opt-in InstructionsLoaded JSONL audit log for diagnosing path-scoped rule loads; off by default.`

- [ ] 6. Run `bash .claude/tools/memory-project.sh` to force-regenerate `.claude/memory/MEMORY.md` from frontmatter. Verify three new entries appear and the projection is clean (no `memory-project-advisory:` lines).

### Phase 3 — Rewire cross-references

- [ ] 7. Update `.claude/hooks/governance-gate.sh`: rewrite `.claude/rules/hook-chain-latency.md` → `.claude/memory/hook-chain-latency.md` (or remove the pointer if the comment is purely a "see also" and the surrounding code doesn't load-bear on it).

- [ ] 8. Update `.claude/hooks/runtime-pre-mark.sh`: same path rewrite for hook-chain-latency.

- [ ] 9. Update `.claude/hooks/rule-load-debug.sh`: self-pointer rewrite (`.claude/rules/rule-load-debug.md` → `.claude/memory/rule-load-debug.md`).

- [ ] 10. Update `.claude/tools/bench-hooks.sh`: rewrite hook-chain-latency rule path → memory path.

- [ ] 11. Update `.claude/tools/probe.sh`: rewrite rule-load-debug + compaction-continuity rule paths → memory paths (run `grep -n` first to confirm exact lines).

- [ ] 12. Audit `.claude/rules/*.md` for cross-refs into the three moved files: `grep -ln -E 'rules/(hook-chain-latency|compaction-continuity|rule-load-debug)' .claude/rules/`. For each hit: if it's a load-bearing "see X for the contract" pointer, rewrite to `.claude/memory/`; if it's a tail "Cross-references" list with no behavioral dependency, drop the bullet entirely (rules→memory cross-pointing is unidiomatic in this codebase).

- [ ] 13. Audit `.claude/tests/{hook-chain-latency,compaction-continuity}/*` for embedded doc-pointer strings (test names + assertions usually don't reference docs, but content scripts sometimes do). `grep -rn 'rules/(hook-chain-latency|compaction-continuity|rule-load-debug)' .claude/tests/`. Rewrite hits.

### Phase 4 — Delete old rules + update entrypoints

- [ ] 14. Delete `.claude/rules/hook-chain-latency.md`, `.claude/rules/compaction-continuity.md`, `.claude/rules/rule-load-debug.md`. Do this AFTER all cross-refs are rewired (Phase 3 complete).

- [ ] 15. Edit `CLAUDE.md`: remove the `## Rule load debug` section (line 99 + its body paragraph) and the `## Hook chain latency` section (line 115 + its body paragraph). Verify the managed-block markers (if any wrap these sections) stay intact.

- [ ] 16. Edit `AGENTS.md`: remove the `## Rule load debug` section (line 79 + body). `## Hook chain latency` is NOT present in AGENTS.md and needs no removal — pre-existing drift this work incidentally closes.

- [ ] 17. Update `.claude/rules/memory-placement.md` § *Routing decision tree*: add a tightened criterion line — "capacity operational docs (how to extend, calibrate, regress-check) that the consumer-side agent never acts on → memory, not rule". Also amend § *Why three buckets, not two* to cite the 2026-05-27 audit as a second trigger alongside the existing CC-32-hooks discovery.

### Phase 5 — Verification

- [ ] 18. Re-grep for any remaining `\.claude/rules/(hook-chain-latency|compaction-continuity|rule-load-debug)` references: `grep -rln -E 'rules/(hook-chain-latency|compaction-continuity|rule-load-debug)' .`. Expected output: empty (with the possible exception of `docs/specs/` historical mentions, which per spec § Open Question 3 stay untouched).

- [ ] 19. Run `bash .claude/tests/hook-chain-latency/run-all.sh`. Expected: all 3 scenarios pass. The tests validate executable behavior of the bench tool and baseline, not doc location, so they should be unaffected.

- [ ] 20. Run `bash .claude/tests/compaction-continuity/run-all.sh`. Expected: all 6 scenarios pass.

- [ ] 21. Run `bash .claude/tools/sync-harness.sh --check --agent0-path=/home/goat/Agent0 /home/goat/mei-saas`. Expected: the three rule paths appear under `- removed` (orphan deletion in consumer); zero `! customized` for them; no unparseable-frontmatter advisory.

- [ ] 22. Read `.claude/memory/MEMORY.md`: confirm the three new index entries are present and well-formed (one-line, < 250 chars per `memory.config.json` cap).

- [ ] 23. Run `bash .claude/tools/memory-query.sh list --type=reference` and verify the three new entries surface. Sanity check on frontmatter parseability.

## Verification

_Each item maps to a spec.md acceptance criterion._

- [ ] AC 1 (scenario: consumer sync no rule drift) — verified by task 21
- [ ] AC 2 (scenario: consumer session loads no managed-block pointer) — verified by tasks 15 + 16 + re-reading CLAUDE.md / AGENTS.md post-edit
- [ ] AC 3 (scenario: maintainer reads moved content via memory index) — verified by tasks 22 + 23
- [ ] AC 4 (static: 3 memory files exist + frontmatter validator passes) — verified by tasks 3, 4, 5 (validator silent on stderr after each create)
- [ ] AC 5 (static: 3 rule files no longer exist) — verified by task 14
- [ ] AC 6 (static: every cross-reference updated or removed) — verified by tasks 7-13 + 18 (the empty re-grep)
- [ ] AC 7 (static: CLAUDE.md + AGENTS.md managed blocks cleaned) — verified by tasks 15 + 16
- [ ] AC 8 (static: memory-placement.md criterion explicit) — verified by task 17
- [ ] AC 9 (static: upstream sync `--check` clean) — verified by extending task 21 to also include `--agent0-path=/home/goat/Agent0 .`
- [ ] AC 10 (static: test suites still pass) — verified by tasks 19 + 20

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._
