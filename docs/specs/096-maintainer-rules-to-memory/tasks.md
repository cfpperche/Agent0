# 096 — maintainer-rules-to-memory — tasks

_Generated from `plan.md` on 2026-05-27. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Phase 1 — Pre-flight grep (catch surface area before mutating)

- [x] 1. Run `grep -rln -E 'hook-chain-latency|compaction-continuity|rule-load-debug' .claude/ CLAUDE.md AGENTS.md` and save the result to `notes.md` under a `### 2026-05-27 — parent — pre-move cross-ref inventory` entry. This is the load-bearing surface for the rewire step; anything missed here gets caught by Phase 5 (re-grep) but earlier discovery is cheaper.

- [x] 2. Grep also for runtime reads (not just text mentions): `grep -rn -E '(cat|head|tail|<) .*\.claude/rules/(hook-chain-latency|compaction-continuity|rule-load-debug)' .claude/`. Should be empty; if a hook or tool literally reads the file at runtime, that's a blocker that changes the plan (would need a redirect, not just a path rewrite).

### Phase 2 — Create memory files

- [x] 3. Create `.claude/memory/hook-chain-latency.md`: copy the current body of `.claude/rules/hook-chain-latency.md` verbatim, prepend frontmatter (`name: hook-chain-latency`, `description: PreToolUse(Bash) chain latency budget + bench tooling for maintainers extending the hook chain.`, `metadata.type: reference`, `metadata.created_at:` set to today UTC ISO-8601). Verify the frontmatter validator accepts it (advisory line should be silent on stderr after the write).

- [x] 4. Create `.claude/memory/compaction-continuity.md`: same pattern. Description: `PreCompact+SessionStart snapshot pair preserving raw signal across /compact; mechanism + retention details.`

- [x] 5. Create `.claude/memory/rule-load-debug.md`: same pattern. Description: `Opt-in InstructionsLoaded JSONL audit log for diagnosing path-scoped rule loads; off by default.`

- [x] 6. Run `bash .claude/tools/memory-project.sh` to force-regenerate `.claude/memory/MEMORY.md` from frontmatter. Verify three new entries appear and the projection is clean (no `memory-project-advisory:` lines).

### Phase 3 — Rewire cross-references

- [x] 7. Update `.claude/hooks/governance-gate.sh`: rewrite `.claude/rules/hook-chain-latency.md` → `.claude/memory/hook-chain-latency.md` (or remove the pointer if the comment is purely a "see also" and the surrounding code doesn't load-bear on it).

- [x] 8. Update `.claude/hooks/runtime-pre-mark.sh`: same path rewrite for hook-chain-latency.

- [x] 9. Update `.claude/hooks/rule-load-debug.sh`: self-pointer rewrite (`.claude/rules/rule-load-debug.md` → `.claude/memory/rule-load-debug.md`).

- [x] 10. Update `.claude/tools/bench-hooks.sh`: rewrite hook-chain-latency rule path → memory path.

- [x] 11. Update `.claude/tools/probe.sh`: rewrite rule-load-debug + compaction-continuity rule paths → memory paths (run `grep -n` first to confirm exact lines). _N/A — `grep` confirmed probe.sh has no rule-doc pointers (line 181 is the JSONL audit-log path `.claude/.rule-load-debug.jsonl`, not a rule reference)._

- [x] 12. Audit `.claude/rules/*.md` for cross-refs into the three moved files: `grep -ln -E 'rules/(hook-chain-latency|compaction-continuity|rule-load-debug)' .claude/rules/`. For each hit: if it's a load-bearing "see X for the contract" pointer, rewrite to `.claude/memory/`; if it's a tail "Cross-references" list with no behavioral dependency, drop the bullet entirely (rules→memory cross-pointing is unidiomatic in this codebase). _N/A — grep returned no hits in `.claude/rules/`; the only intra-rule self-refs were inside the deleted rule files themselves._

- [x] 13. Audit `.claude/tests/{hook-chain-latency,compaction-continuity}/*` for embedded doc-pointer strings (test names + assertions usually don't reference docs, but content scripts sometimes do). `grep -rn 'rules/(hook-chain-latency|compaction-continuity|rule-load-debug)' .claude/tests/`. Rewrite hits.

### Phase 4 — Delete old rules + update entrypoints

- [x] 14. Delete `.claude/rules/hook-chain-latency.md`, `.claude/rules/compaction-continuity.md`, `.claude/rules/rule-load-debug.md`. Do this AFTER all cross-refs are rewired (Phase 3 complete).

- [x] 15. Edit `CLAUDE.md`: remove the `## Rule load debug` section (line 99 + its body paragraph) and the `## Hook chain latency` section (line 115 + its body paragraph). Verify the managed-block markers (if any wrap these sections) stay intact.

- [x] 16. Edit `AGENTS.md`: remove the `## Rule load debug` section (line 79 + body). `## Hook chain latency` is NOT present in AGENTS.md and needs no removal — pre-existing drift this work incidentally closes.

- [x] 17. Update `.claude/rules/memory-placement.md` § *Routing decision tree*: add a tightened criterion line — "capacity operational docs (how to extend, calibrate, regress-check) that the consumer-side agent never acts on → memory, not rule". Also amend § *Why three buckets, not two* to cite the 2026-05-27 audit as a second trigger alongside the existing CC-32-hooks discovery.

### Phase 5 — Verification

- [x] 18. Re-grep for any remaining `\.claude/rules/(hook-chain-latency|compaction-continuity|rule-load-debug)` references: `grep -rln -E 'rules/(hook-chain-latency|compaction-continuity|rule-load-debug)' .`. Expected output: empty (with the possible exception of `docs/specs/` historical mentions, which per spec § Open Question 3 stay untouched). _Two missed surfaces caught and fixed in flight: `.claude/.runtime-state/README.md` (synced, ships to consumers) + `site/src/i18n/capacities.ts` (marketing-site URLs). Final re-grep clean._

- [x] 19. Run `bash .claude/tests/hook-chain-latency/run-all.sh`. Expected: all 3 scenarios pass. The tests validate executable behavior of the bench tool and baseline, not doc location, so they should be unaffected. _All 3 PASS._

- [x] 20. Run `bash .claude/tests/compaction-continuity/run-all.sh`. Expected: all 6 scenarios pass. _All 6 PASS._

- [x] 21. Run `bash .claude/tools/sync-harness.sh --check --agent0-path=/home/goat/Agent0 /home/goat/mei-saas`. Expected: the three rule paths appear under `- removed` (orphan deletion in consumer); zero `! customized` for them; no unparseable-frontmatter advisory. _All three appear under `- removed`; 0 customized-refused; 0 overwritten._

- [x] 22. Read `.claude/memory/MEMORY.md`: confirm the three new index entries are present and well-formed (one-line, < 250 chars per `memory.config.json` cap).

- [x] 23. Run `bash .claude/tools/memory-query.sh list --type=reference` and verify the three new entries surface. Sanity check on frontmatter parseability.

## Verification

_Each item maps to a spec.md acceptance criterion._

- [x] AC 1 (scenario: consumer sync no rule drift) — verified by task 21
- [x] AC 2 (scenario: consumer session loads no managed-block pointer) — verified by tasks 15 + 16 + re-reading CLAUDE.md / AGENTS.md post-edit
- [x] AC 3 (scenario: maintainer reads moved content via memory index) — verified by tasks 22 + 23
- [x] AC 4 (static: 3 memory files exist + frontmatter validator passes) — verified by tasks 3, 4, 5 (validator silent on stderr after each create)
- [x] AC 5 (static: 3 rule files no longer exist) — verified by task 14
- [x] AC 6 (static: every cross-reference updated or removed) — verified by tasks 7-13 + 18 (the empty re-grep)
- [x] AC 7 (static: CLAUDE.md + AGENTS.md managed blocks cleaned) — verified by tasks 15 + 16
- [x] AC 8 (static: memory-placement.md criterion explicit) — verified by task 17
- [x] AC 9 (static: upstream sync `--check` clean) — verified by extending task 21 to also include `--agent0-path=/home/goat/Agent0 .` — `0 customized-refused, 0 overwritten`
- [x] AC 10 (static: test suites still pass) — verified by tasks 19 + 20

## Notes

- **Missed surfaces caught in flight:** `.claude/.runtime-state/README.md` (table rows + Discipline paragraph) and `site/src/i18n/capacities.ts` (i18n string constants — Agent0 marketing-site URLs). Both have path pointers shaped `.claude/rules/<moved>.md`; Phase 1 grep scoped to `.claude/{hooks,tools,rules,skills,tests}/` + entrypoints missed them. Both were rewritten before declaring done. Lesson: Phase 1 grep should be unscoped (`grep -rln` over the whole repo, excluding only `.git`/`node_modules`/`docs/specs/`) rather than per-dir; the per-dir scoping was inherited from `.claude/rules/propagation-hygiene.md § The shipped file class` which is propagation-leak-focused, not rewire-completeness-focused. The lessons table in `propagation-hygiene.md` could absorb this if it surfaces again.
- **Memory-Placement-routing-tree tightening side-effect:** the rule's example list now mentions `hook-chain-latency.md` / `compaction-continuity.md` / `rule-load-debug.md` and spec 096 by number. The propagation-advisory hook is path-scoped — it fires on `.claude/rules/<file>.md` edits, where the cited slugs and "spec 096" both trip its regex. The override `# OVERRIDE: propagation-exempt: ...` was NOT added because the hook fired silently (no edit refused) — the advisory is informational, and citing a moved-file's slug in the very rule that documents the move is the canonical legitimate use the override exists for. Re-confirm at next propagation-hygiene audit; if it flags, add the marker.
- **AGENTS.md drift closed incidentally:** `## Hook chain latency` existed in `CLAUDE.md` but not in `AGENTS.md` (never propagated when spec 094 shipped). This spec's CLAUDE.md prune of that section closes the drift without needing a separate change.
- **Minimal-touch resolution (spec § OQ1) held.** Body content of the three moved files is verbatim except for:
  - `hook-chain-latency.md`: "This rule documents..." → "This entry documents..."; "This rule is the consumer-facing surface" + paired sentence rephrased as a memory-companion description; "the rule's 80 ms target" → "the 80 ms target".
  - `hook-chain-maintenance.md` (existing memory): "Maintainer-binding companion to `.claude/rules/hook-chain-latency.md`. The rule documents..." → "Maintainer-binding companion to `.claude/memory/hook-chain-latency.md`. The companion entry documents..."; "consumer-facing rule" → "companion entry" in the Cross-references section.
  - `compaction-continuity.md` + `rule-load-debug.md`: body copied verbatim, only `.claude/rules/...` paths rewritten in cross-references (notably the rule-load-debug `compaction-continuity` cross-ref).
- **Frontmatter:** Each new entry got `name` + `description` + `metadata.type: reference` + `metadata.created_at: 2026-05-27T00:00:00Z` (per `memory-placement.md § Frontmatter schema`). Validator silent post-write; `memory-query.sh list --type=reference` parses all three.
