# 096 — maintainer-rules-to-memory — plan

_Drafted from `spec.md` on 2026-05-27. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Single PR, mechanical move. Three rule files become three memory files (move + add required frontmatter; keep body content verbatim, modulo header rephrasing where literally inaccurate per Open Question 1's "minimal touch" resolution). Cross-references in hooks / tools / other rules get rewired one-by-one (paths only — pointer text stays). `CLAUDE.md` loses two managed-block sections (`## Rule load debug`, `## Hook chain latency`); `AGENTS.md` loses one (`## Rule load debug` only — `## Hook chain latency` was never propagated there, pre-existing drift this spec incidentally closes). `memory-placement.md`'s § *Routing decision tree* gets a tightened criterion line so the next maintainer-binding capacity-doc routes to memory at write time instead of needing a follow-up audit. Order matters: write the memory files first (with frontmatter that passes the validator), THEN rewire pointers, THEN delete the rule files, THEN update the managed blocks. Doing the rule deletion before the memory creation would leave a window where cross-refs from hooks point to nothing.

The work is atomic-by-design: every change in this PR is part of the same conceptual move; splitting across multiple PRs would touch `CLAUDE.md` + `AGENTS.md` + `memory-placement.md` repeatedly and inflate review noise. The bulk-sed lesson from spec 095 doesn't apply here (no word-boundary patterns, no shell-var rewrites, no adjectival compounds — just path string replacement and 3 file moves).

## Files to touch

**Create:**
- `.claude/memory/hook-chain-latency.md` — full body of the current rule + memory frontmatter (`name: hook-chain-latency`, `description: PreToolUse(Bash) chain latency budget + bench tooling for maintainers extending the hook chain.`, `metadata.type: reference`). Headings adjusted only where the prose literally said "this rule" → "this entry".
- `.claude/memory/compaction-continuity.md` — full body + frontmatter (`name: compaction-continuity`, `description: PreCompact+SessionStart snapshot pair preserving raw signal across /compact; mechanism + retention details.`, `metadata.type: reference`).
- `.claude/memory/rule-load-debug.md` — full body + frontmatter (`name: rule-load-debug`, `description: Opt-in InstructionsLoaded JSONL audit log for diagnosing path-scoped rule loads; off by default.`, `metadata.type: reference`).

**Modify:**
- `.claude/memory/MEMORY.md` — three new index entries auto-projected by the `PostToolUse` memory-events-journal hook on first write of each new memory file (no manual edit; the hook regenerates the file deterministically from frontmatter). Verified by reading MEMORY.md after each create.
- `.claude/rules/memory-placement.md` — tighten § *Routing decision tree* with one explicit case: "capacity operational docs (how to extend, calibrate, regress-check) that the consumer-side agent never acts on → memory, not rule". Also amend § *Why three buckets, not two* to cite the 2026-05-27 audit as the second trigger (alongside the CC-32-hooks discovery).
- `CLAUDE.md` — delete lines 99-100 (`## Rule load debug` + body) and lines 115-116 (`## Hook chain latency` + body) from the managed block. Re-emit the managed block deterministically via the managed-block library (`.claude/tools/lib/managed-block.sh`) if direct edit is fragile; otherwise straight Edit.
- `AGENTS.md` — delete `## Rule load debug` section only (line 79). `## Hook chain latency` was never added to AGENTS.md — pre-existing drift this work closes.
- `.claude/hooks/governance-gate.sh` — path rewrite: `.claude/rules/hook-chain-latency.md` → `.claude/memory/hook-chain-latency.md` (if doc-pointer comment) or remove pointer if no longer load-bearing.
- `.claude/hooks/runtime-pre-mark.sh` — same.
- `.claude/hooks/rule-load-debug.sh` — same for rule-load-debug self-pointer.
- `.claude/tools/bench-hooks.sh` — same for hook-chain-latency reference.
- `.claude/tools/probe.sh` — path rewrites for rule-load-debug + (if present) compaction-continuity.
- `.claude/tests/hook-chain-latency/*.sh`, `.claude/tests/compaction-continuity/*.sh` — only update embedded doc-pointer strings if any test content greps the rule path; the test directory names themselves stay (test naming is independent of doc location).
- Other `.claude/rules/*.md` cross-refs that point at any of the three — update only when load-bearing (an agent reading the rule and being told "see X" benefits from a working link); a "Cross-references" footer that just lists related files can drop the moved ones rather than re-point to memory (rules don't cross-ref into memory in this codebase's current style).

**Delete:**
- `.claude/rules/hook-chain-latency.md` — moved to memory.
- `.claude/rules/compaction-continuity.md` — moved to memory.
- `.claude/rules/rule-load-debug.md` — moved to memory.

## Alternatives considered

### Move one rule at a time across three separate specs / PRs

Rejected because each PR would re-touch `CLAUDE.md`, `AGENTS.md`, `memory-placement.md`, and the surrounding cross-ref graph — the propagation-advisory hook would fire three times, the consumer sync would need three cycles, and the MEMORY.md index would re-shuffle thrice. The work is mechanically uniform (path string replacement + frontmatter add); atomicity is the lower-risk shape.

### Keep the files in `.claude/rules/` but add `consumer-skip: true` (or equivalent) frontmatter and have `sync-harness.sh` filter them out

Rejected because it introduces new manifest semantics for what is a one-off classification fix. The existing rule/memory distinction already cleanly encodes "ships to consumers" vs "stays project-local"; adding a per-file opt-out flag duplicates the criterion and creates ambiguity for the next maintainer ("which mechanism applies here?"). The bucket is the contract; respect it.

### Demote the three sections to subsections inside CLAUDE.md's `## Memory` section as pointers

Rejected because the entire premise is that the consumer-side agent doesn't benefit from the content. Keeping a top-level pointer would re-introduce the noise we're trying to remove. The maintainer who needs the doc opens `.claude/memory/MEMORY.md` (which is part of the standard memory-discovery flow per `memory-placement.md`); no orientation pointer needed in CLAUDE.md.

### Move + simultaneously trim "rule-shaped" framing prose (Override marker sections, etc.) from the moved files

Rejected for v1 per spec § Open Question 1 — minimal touch. Trimming is genuine work (each section needs judgment on whether it's still relevant in a memory entry) and would dilute the move's diff with content edits. The decay engine's surfacing of stale entries (`memory-query.sh decay --readout`) is the natural follow-up trigger to clean prose if needed.

## Risks and unknowns

- **Runtime file reads we didn't grep for.** The grep caught text-string mentions of the three rules across `.claude/{hooks,tools,rules,skills,tests}/`. If any hook or tool does a runtime `cat` / `head` / similar that loads the file content from `.claude/rules/<slug>.md`, the move breaks it silently. Mitigation: post-move, run the full test suite under `.claude/tests/` and the bench-hooks `--check` — both exercise the hook chain and would surface a missing-file error.
- **MEMORY.md regeneration ordering.** The `PostToolUse` memory-events-journal hook regenerates MEMORY.md after every memory edit; doing three Write calls in sequence is fine, but if the journal helper is missing (no `jq` or PyYAML) the projection degrades to the awk path and may not include the new entries cleanly. Mitigation: explicitly run `bash .claude/tools/memory-project.sh` once after all three creates to force a clean projection.
- **Frontmatter validator stricter than expected.** The current `memory-frontmatter-validate.sh` checks for `name` / `description` / `metadata.type` and rejects unknown top-level keys. If the moved files end up with markdown-in-description that confuses YAML parsing, the validator emits an advisory but doesn't block — still want to read the validator output once after each create to confirm clean.
- **AGENTS.md drift discovery.** Plan assumes the only AGENTS.md change is removing `## Rule load debug`. If the `runtime-capabilities.md` registry or some other AGENTS.md content references the moved rules, that needs separate update. The grep covered AGENTS.md and CLAUDE.md; running the same grep post-move as an audit check covers this.
- **Open Question 1 (minimal-touch vs trim) plays out.** If during the move the verbatim copy reveals prose so obviously rule-shaped that it's misleading in memory (e.g. "the override marker for this rule is…"), the implementer has to decide row-by-row whether to leave it (per the recommendation) or trim for honesty. Bias toward leaving — flag it in `notes.md` for a follow-up cleanup spec if it accumulates.
- **Consumer sync flow assumption.** Spec AC 1 asserts the three files appear as `- removed` (orphan deletion) in the consumer `--check`. This relies on the consumer-side baseline still listing them as managed files; if a consumer manually deleted them already, the sync sees no drift to remove. Acceptance is "no spurious `customized-refused`" — that's what actually matters. Wording in the AC is good; risk noted.

## Research / citations

- `.claude/rules/memory-placement.md` — the 3-bucket model + routing decision tree. The canonical criterion this spec applies.
- `.claude/rules/harness-sync.md` § *Manifest* — confirms `.claude/memory/` ships scaffold-only via `.gitkeep`, so the bucket change automatically stops downstream propagation.
- `.claude/rules/propagation-advisory.md` § *The 5 patterns* — none of the patterns fire on moves within the upstream; the propagation hook is consumer-shipping-leak-focused, not internal-rearrangement-focused. Verified by reading the regex set.
- `.claude/rules/memory-placement.md` § *Event journal* — confirms that the `PostToolUse(Edit|Write|MultiEdit)` hook handles MEMORY.md regeneration on memory writes; no manual MEMORY.md edit needed.
- Empirical grep `2026-05-27`: cross-references confined to `.claude/{hooks,tools,tests}/` + `CLAUDE.md` + `AGENTS.md`; no skills or other rules need surgery for this set.
- Conversation 2026-05-27 (this session): the 25-rule audit table, the user's framing that triggered it (`hook-chain-latency.md` in consumer context with no consumer use-case).
