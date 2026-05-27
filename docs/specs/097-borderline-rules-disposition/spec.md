# 097 — borderline-rules-disposition

_Created 2026-05-27._

**Status:** draft

## Intent

Spec 096 (`maintainer-rules-to-memory`) shipped 3 clear-cut rule→memory moves (`hook-chain-latency`, `compaction-continuity`, `rule-load-debug`) and explicitly deferred the borderline cases. This spec dispositions the borderlines: `propagation-advisory.md`, `runtime-introspect.md`, and `runtime-capabilities.md` (the third surfaced during a post-096 conversation 2026-05-27 by applying spec 096's "consumer-side agent acts on it" test). Each carries content that mixes consumer-side load-bearing surface (override grammar, environment-variable contracts, behavior the agent invokes) with maintainer-only material (extension contracts, drift tooling, internal mechanism). The three available dispositions per file are: **split** (carve out a maintainer-binding memory entry, leave the consumer-facing surface in the rule), **move-full** (entire rule routes to memory; consumer-side agent never load-beared on it), or **keep-as-is** (re-audit confirmed consumer-side value justifies the noise cost). This spec audits each one with the spec 096 criterion explicit, applies the chosen disposition mechanically, and rewires every cross-reference + entrypoint pointer.

## Acceptance criteria

- [ ] **Scenario: each of the 3 borderlines has a documented disposition**
  - **Given** the audit table in `plan.md` § *Per-file disposition*
  - **When** the maintainer reads it after the spec lands
  - **Then** every row carries one of `split` / `move-full` / `keep-as-is`, the reasoning paragraph names which sections of the source file are consumer-binding vs maintainer-binding, and the criterion cited is the "consumer-side agent acts on it" test from `memory-placement.md § Routing decision tree`

- [ ] **Scenario: split disposition applied cleanly**
  - **Given** a file disposed as `split`
  - **When** the spec ships
  - **Then** the consumer-facing slice remains at `.claude/rules/<slug>.md` (carrying override grammar, env var contracts, behavior the agent invokes) and the maintainer-binding slice is a NEW memory entry at `.claude/memory/<slug>-internals.md` (or analogous), the rule's `## Cross-references` cites the memory companion, and every existing cross-reference resolves to the correct half (load-bearing pointers to consumer-facing surface stay on the rule path; pointers to extension/calibration/drift content rewrite to memory)

- [ ] **Scenario: move-full disposition applied cleanly**
  - **Given** a file disposed as `move-full`
  - **When** the spec ships
  - **Then** the rule file no longer exists, a memory entry exists at `.claude/memory/<slug>.md` with valid frontmatter (`name`, `description`, `metadata.type` per `memory-placement.md § Frontmatter schema`), every cross-reference is rewritten to the memory path, the `CLAUDE.md` / `AGENTS.md` managed-block section (if any) is pruned, and consumer `sync-harness.sh --check` shows the file under `- removed` with `0 customized-refused`

- [ ] **Scenario: keep-as-is disposition documented**
  - **Given** a file disposed as `keep-as-is`
  - **When** a reader inspects `plan.md` § *Per-file disposition*
  - **Then** the row carries a reasoning paragraph naming the concrete consumer-side load-bearing surface (named sections, named behavior the agent invokes), and the file's `## Notes` or § *Gotchas* gains one line acknowledging the borderline audit + the "kept-as-rule because X" rationale so the next audit doesn't re-litigate the decision from scratch

- [ ] Every cross-reference under `.claude/{hooks,tools,rules,skills,tests,memory,routines}/` + `CLAUDE.md` + `AGENTS.md` + `.claude/.runtime-state/README.md` + `site/src/i18n/capacities.ts` that previously pointed to `.claude/rules/{propagation-advisory,runtime-introspect,runtime-capabilities}.md` resolves correctly to whichever half (or full memory path) the disposition selected, or is removed if the pointer became orphan

- [ ] `bash .claude/tools/sync-harness.sh --check --agent0-path=/home/goat/Agent0 .` runs clean post-change (no spurious customized-refused or unparseable-frontmatter advisory) — applies to whichever files moved or split

- [ ] `bash .claude/tools/check-instruction-drift.sh` passes post-change — `runtime-capabilities.md` may need the drift-check's path expectation updated if its disposition is `split` or `move-full`

- [ ] `.claude/tests/` test suites that exercise any of the three capacities (e.g. `runtime-introspect/`, if present) still pass after the rewire (they validate executable behavior, not doc location)

- [ ] `.claude/rules/memory-placement.md` § *Why three buckets, not two* gains a third trigger entry citing spec 097 as the empirical case for the **split** discipline (096 established move-full; 097 establishes split as a distinct legitimate disposition)

## Non-goals

- **Re-auditing the 20 KEEP rules from spec 096's 25-rule audit.** That set was confirmed as consumer-facing in 096; revisit only if a new trigger surfaces.
- **Moving executable tools** (`probe.sh`, `check-instruction-drift.sh`, the runtime-introspect hooks, the propagation-advise hook). They ship as harness capacity; only descriptive prose moves or splits.
- **Touching consumer baselines** (`mei-saas`, `codexeng`). Those regenerate on the next consumer `--apply`; this spec is upstream-only.
- **Building a `# OVERRIDE: routing-tree-citation-exempt:` for the propagation-advisory hook firing on `memory-placement.md`'s example list.** Spec 096 noted this falls in the "canonical legitimate" category; revisit only if false-positive rate compounds.
- **Re-running the spec 096 mei-saas sync `--apply`.** Already covered in the post-096 HANDOFF Next Actions.

## Open questions

- [ ] **Order of audit per file.** Recommendation: audit + dispose `runtime-capabilities.md` FIRST (smallest content, cleanest split candidate — the matrix table is consumer-readable, the `Update rule` + `Drift enforcement` sections are maintainer-binding), then `propagation-advisory.md` (the advisory mechanism itself is consumer-load-bearing — it fires on consumer edits — but the 5-pattern table and pattern-rationale prose is maintainer-binding), then `runtime-introspect.md` (largest, most complex — `last-run.json` schema + `probe.sh` flags + env vars are consumer-load-bearing; detector pair list extension contract + inference heuristics are maintainer-binding). Confirm at `/sdd plan` time after a fresh re-read.
- [ ] **Naming convention for the split memory entry.** Two candidates: `<slug>-internals.md` (e.g. `propagation-advisory-internals.md`) or `<slug>-maintenance.md` (mirrors existing `hook-chain-maintenance.md` for hook-chain-latency). Recommendation: `<slug>-maintenance.md` for consistency with the precedent. Confirm at plan time.
- [ ] **Disposition for `runtime-capabilities.md` specifically — split vs move-full.** Move-full is defensible (drift-check is maintainer-tooling, `Update rule` binds the maintainer, the matrix is rarely consumer-loaded). Split is also defensible (the matrix has Q&A value for "can my runtime use Agent0?" — keep the matrix as consumer-facing rule, move the `Update rule` + `Drift enforcement` to maintainer memory). The cost of split is a new file + a cross-reference; the cost of move-full is losing the Q&A surface from the consumer's path-scoped autoload window. **Lean: split.** Confirm during audit pass.
- [ ] **Should the spec ship as one PR or three (one per file)?** Recommendation: one PR. Same atomicity argument as spec 096 — splitting across three PRs re-touches `CLAUDE.md`/`AGENTS.md`/`memory-placement.md` repeatedly and inflates review noise. The work is mechanically uniform (path-string rewrites + frontmatter add + targeted body extraction). Single PR matches the precedent.
- [ ] **Cross-references in the rule body to other rules being audited (transitive dependency).** Example: `runtime-introspect.md` cross-references `supply-chain.md`; `propagation-advisory.md` cross-references `delegation.md`. None of the cross-refs in scope of this audit point AT each other today (verified via spec 096's grep), but worth re-confirming at audit time so the rewires don't whack-a-mole.

## Context / references

- `.claude/rules/memory-placement.md` § *Routing decision tree* — the canonical criterion this spec applies; the "consumer-side agent acts on it" test
- `docs/specs/096-maintainer-rules-to-memory/spec.md` § *Non-goals* — the original deferral that this spec resolves; cite for lineage
- `docs/specs/096-maintainer-rules-to-memory/notes.md` — the lesson on rewire-completeness greps (Phase 1 should be repo-wide, not per-dir); this spec inherits the lesson
- The 25-rule audit conversation (2026-05-27, this session's predecessor) — classified `propagation-advisory.md` + `runtime-introspect.md` as BORDERLINE with explicit reasoning
- The post-096 review conversation (2026-05-27, current session) — surfaced `runtime-capabilities.md` as a third borderline candidate by re-applying the criterion to a rule not in the original audit set; the matrix-as-Q&A defense is real but weak
- `.claude/rules/propagation-advisory.md` — current state of file 1 of 3
- `.claude/rules/runtime-introspect.md` — current state of file 2 of 3
- `.claude/rules/runtime-capabilities.md` — current state of file 3 of 3
