# 097 — borderline-rules-disposition — tasks

_Generated from `plan.md` on 2026-05-27. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Phase 1 — Pre-flight (catch surface area before mutating)

- [ ] 1. **Repo-wide grep** (lesson from spec 096): `grep -rln -E 'rules/(propagation-advisory|runtime-introspect|runtime-capabilities)' . --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | grep -v 'docs/specs/' | grep -v 'session-state' | grep -v 'delegation-audit' | grep -v 'rule-load-debug\.jsonl' | grep -v 'compact-history' | sort -u`. Save the result to `notes.md` under a `### 2026-05-27 — parent — pre-move cross-ref inventory` entry. Compare against plan's pre-flight inventory; flag any deltas.

- [ ] 2. **Read `check-instruction-drift.sh` anchor checks**: confirm what it greps for inside `runtime-capabilities.md`. If it anchors only on path existence + status-vocabulary terms + minimum-set capability labels (all of which survive the split into the rule), no drift-check edit needed. If it anchors on the `## Update rule` heading or other MB content moving to memory, flag in `notes.md` and update the plan before proceeding.

- [ ] 3. **Read the 3 source rules cold** one more time and confirm the CF/MB section boundary from `plan.md § Per-file disposition` matches the file's actual heading structure. Any deviation goes in `notes.md` as a deviation entry + the plan gets updated.

### Phase 2 — Create maintenance memory entries

- [ ] 4. **Create `.claude/memory/runtime-capabilities-maintenance.md`**: extract `## Update rule`, `## Drift enforcement`, `## Skill portability relationship` from the current `runtime-capabilities.md` verbatim. Prepend memory frontmatter (`name: runtime-capabilities-maintenance`, `description: Maintainer discipline for the runtime-capabilities matrix — Update rule + drift enforcement + skill-portability relationship.`, `metadata.type: project`, `metadata.created_at: 2026-05-27T00:00:00Z`). Add H1 `# Runtime capabilities maintenance` + a one-line opening that names the consumer-facing rule as the companion. Verify frontmatter validator advisory silent on stderr after the write.

- [ ] 5. **Create `.claude/memory/propagation-advisory-maintenance.md`**: extract `## The 5 patterns` (full table + extension prose), `## Pattern exclusions (legitimate keeps that bypass the scan)`, `## Shipped surface (where the hook fires)` + `### Within-surface exclusions`, `## Audit log` (capacity policy), and the maintainer-deep gotchas (diff-scope semantics, 2+-digit floor reasoning, vendor/design-systems path exclusion mechanism, pattern-volume cap rationale). Prepend frontmatter (`name: propagation-advisory-maintenance`, `description: Maintainer discipline for propagation-advisory — pattern table + shipped-surface set + audit-log policy + deep gotchas.`, `metadata.type: project`, `metadata.created_at: 2026-05-27T00:00:00Z`). Add H1 + one-line opening.

- [ ] 6. **Create `.claude/memory/runtime-introspect-maintenance.md`**: extract `### Extension via env var (HUMAN-ONLY, pre-launch)`, `## Detector pair list (v1)` extension contract narrative (KEEP the pair table in the rule), `### Inference heuristics` per-detector tables, `## State file (no audit log)` design rationale, and the maintainer-deep gotchas (sibling-process env inheritance archaeology, ANSI-strip dogfood, Cargo workspace handling, commit-message FP precedent, runtime-introspect-EXTRA-DETECT mid-session limitation). Prepend frontmatter (`name: runtime-introspect-maintenance`, `description: Maintainer discipline for runtime-introspect — detector extension contract + inference heuristics + dogfood archaeology + deep gotchas.`, `metadata.type: project`, `metadata.created_at: 2026-05-27T00:00:00Z`). Add H1 + one-line opening.

- [ ] 7. Run `bash .claude/tools/memory-project.sh` to force-regenerate `.claude/memory/MEMORY.md`. Verify 3 new entries appear and the projection is clean (no `memory-project-advisory:` lines for the new entries).

### Phase 3 — Thin the rules (remove MB sections, add Maintenance pointer)

- [ ] 8. **Thin `.claude/rules/runtime-capabilities.md`**: delete `## Update rule`, `## Drift enforcement`, `## Skill portability relationship`. Add a closing `## Maintenance` section with one line: `Maintainer discipline (update rule, drift-check anchors, skill portability relationship) lives in `.claude/memory/runtime-capabilities-maintenance.md`.` Verify the file still passes `check-instruction-drift.sh` if its anchors are still present (status-vocabulary terms + minimum-set capability labels).

- [ ] 9. **Thin `.claude/rules/propagation-advisory.md`**: delete the 5-patterns table block, `## Pattern exclusions`, `## Shipped surface` + `### Within-surface exclusions`, `## Audit log` capacity policy, and the maintainer-deep gotchas (diff-scope, 2+-digit floor reasoning, pattern-volume cap, vendor exclusion mechanism). KEEP the opening paragraph, `## What fires, what stays silent` (the consumer-facing summary), `## Override marker`, `## Escape hatch`, and a tightened `## Gotchas` with only the consumer-relevant items (parent-fire surprise, override marker ≥10-char requirement). Add `## Maintenance` closing pointer. The thinned rule MUST still let a consumer reading a `propagation-advisory: <kind> in <file>:<line>` advisory line understand what fired and how to override — verify with a synthetic advisory test prose in `notes.md`.

- [ ] 10. **Thin `.claude/rules/runtime-introspect.md`**: delete `### Extension via env var (HUMAN-ONLY, pre-launch)` paragraph, the per-detector `### Inference heuristics` tables, `## State file (no audit log)` design-rationale prose (keep one tight sentence naming the file path + atomic-rename semantics), and the maintainer-deep gotchas (sibling-process env archaeology, ANSI-strip dogfood, Cargo workspace, commit-message FP precedent, EXTRA-DETECT mid-session limitation). KEEP the opening, `## What fires, what captures` (condensed), `## Detector pair list (v1)` (the table itself, drop the extension subsection), `## last-run.json schema` (field semantics only, drop inference-heuristics-per-detector), `## Probe output shape`, `## Escape hatches`, and a tight `## Gotchas` with consumer-relevant items (probe doesn't see its own capture; PostToolUse failure routing; tool_response.exit_code absent under CC). Add `## Maintenance` closing pointer.

### Phase 4 — Rewire cross-references (per surface)

- [ ] 11. **Audit `.claude/hooks/{propagation-advise,runtime-capture,runtime-pre-mark}.sh` header comments**: rewrite any pointer that cites a MOVED section by name (e.g. `see .claude/rules/runtime-introspect.md § Inference heuristics`) to point at the memory entry. Pointers that just cite the rule generically (`see .claude/rules/runtime-introspect.md`) stay unchanged — the rule still exists.

- [ ] 12. **Audit `.claude/tools/{probe,check-instruction-drift,sync-harness}.sh`**: rewrite any pointer that cites a moved section by name. The drift-checker's path anchors stay on `.claude/rules/runtime-capabilities.md` (matrix survives split); update only if anchored on a moved heading.

- [ ] 13. **Audit `.claude/rules/{delegation,php-laravel-support}.md`** for cross-refs into the 3 moved files: `grep -n -E 'rules/(propagation-advisory|runtime-introspect|runtime-capabilities)' .claude/rules/delegation.md .claude/rules/php-laravel-support.md`. For each hit: rewrite to memory path if the cite is to a moved section; leave at rule path otherwise. Cross-references to the surviving consumer-facing slice stay on rule path.

- [ ] 14. **Audit `.claude/memory/{cc-platform-hooks,propagation-hygiene,user-global-hooks-shadow,hook-chain-latency}.md`** for cross-refs: `grep -n -E 'rules/(propagation-advisory|runtime-introspect|runtime-capabilities)' .claude/memory/*.md`. Rewrite per section-target rule.

- [ ] 15. **Audit `.claude/.runtime-state/README.md`**: the row for `.claude/.runtime-state/` points to `runtime-introspect`. Stays pointing at the rule (probe output shape + last-run schema survive in the rule). Confirm — no rewrite expected, but verify by re-reading post-edit.

- [ ] 16. **Audit `CLAUDE.md` + `AGENTS.md`** `## Runtime capabilities`, `## Runtime introspect`, `## Propagation advisory` managed-block sections. Each pointer still targets a rule that exists. Update prose ONLY if a section text literally describes a moved subsection — e.g. if CLAUDE.md says "see `.claude/rules/runtime-introspect.md § Inference heuristics`", that fragment needs rewrite to memory. Bare "See `.claude/rules/<slug>.md`" pointers stay.

- [ ] 17. **Audit `site/src/i18n/capacities.ts`** `ruleDoc` URLs for the 3 capacities. Stay pointing at `.claude/rules/<slug>.md` — the rule files survive the split. Verify by re-reading; no rewrite expected.

- [ ] 18. **Audit `.claude/tests/runtime-capabilities/*.sh`** fixture scripts: `grep -n -E 'rules/(propagation-advisory|runtime-introspect|runtime-capabilities)' .claude/tests/runtime-capabilities/*.sh`. Tests anchor on path existence + status-vocabulary terms + minimum-set rows; all survive split. Rewrite only on explicit hit.

### Phase 5 — Memory-placement.md tightening

- [ ] 19. **Update `.claude/rules/memory-placement.md § Why three buckets, not two`**: add third trigger entry citing spec 097 as the empirical case for the **split** discipline. Wording must define the split criterion clearly enough that the next maintainer auditing a borderline rule can apply it without re-deriving: _"When a rule mixes consumer-binding sections (override grammar, env vars, behavior the agent invokes) with maintainer-binding sections (extension contracts, internal mechanism, drift tooling), the right disposition is **split** into a thin consumer-facing rule + a `<slug>-maintenance.md` memory companion. Move-full only when ZERO consumer-binding content exists."_ Cross-link the precedent file pair (`.claude/rules/runtime-introspect.md` ↔ `.claude/memory/runtime-introspect-maintenance.md`) as the canonical example.

### Phase 6 — Verification

- [ ] 20. **Re-grep with the same shape as task 1**: `grep -rln -E 'rules/(propagation-advisory|runtime-introspect|runtime-capabilities)' . --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | grep -v 'docs/specs/' | grep -v 'session-state' | grep -v 'delegation-audit' | grep -v 'rule-load-debug\.jsonl' | grep -v 'compact-history' | sort -u`. Result MUST be a subset of task 1's inventory (no NEW surfaces missed); all hits MUST point at the correct slice (CF→rule path, MB→memory path).

- [ ] 21. **Run `bash .claude/tools/check-instruction-drift.sh`**. MUST pass cleanly (anchors on runtime-capabilities.md path + vocabulary terms + minimum-set rows all survive split).

- [ ] 22. **Run `bash .claude/tools/sync-harness.sh --check --agent0-path=/home/goat/Agent0 .`** (upstream self-check). MUST report `0 customized-refused, 0 overwritten`. The 3 thinned rules show as `~ stale (would update)`; the 3 new memory entries show as `+ new (would copy)` — wait, memory entries DON'T sync, so they show as `not in manifest` (correct). The thinned-rule stales are the only expected diff.

- [ ] 23. **Run `bash .claude/tools/sync-harness.sh --check --agent0-path=/home/goat/Agent0 /home/goat/mei-saas`**: MUST report the 3 thinned rules under `~ stale (would update)` with 0 `customized-refused`. No `- removed` for any of the 3 (rules survive split).

- [ ] 24. **Run `bash .claude/tests/runtime-capabilities/run-all.sh`** (if present; otherwise iterate `.claude/tests/runtime-capabilities/*.sh` per fixtures pattern). All scenarios PASS.

- [ ] 25. **Run `bash .claude/tools/memory-query.sh list --type=project | grep -E '(runtime-capabilities-maintenance|propagation-advisory-maintenance|runtime-introspect-maintenance)'`**. All 3 new entries surface.

- [ ] 26. **Read `.claude/memory/MEMORY.md`**: confirm 3 new index entries present, well-formed (one-line, under cap per `memory.config.json`).

## Verification

_Each item maps to a spec.md acceptance criterion._

- [ ] AC 1 (scenario: each of 3 borderlines has documented disposition) — verified by `plan.md § Per-file disposition` table; this spec's plan IS the audit artifact.
- [ ] AC 2 (scenario: split disposition applied cleanly) — verified by tasks 4-6 (memory creates) + 8-10 (rule thins) + 11-18 (rewires).
- [ ] AC 3 (scenario: move-full disposition applied cleanly) — N/A (no file disposed as move-full this spec; criterion exists for future audits using this template).
- [ ] AC 4 (scenario: keep-as-is disposition documented) — N/A (no file disposed as keep-as-is this spec; same as above).
- [ ] AC 5 (every cross-ref resolves correctly) — verified by task 20 re-grep + per-task audit during 11-18.
- [ ] AC 6 (sync-harness --check clean upstream) — verified by task 22.
- [ ] AC 7 (check-instruction-drift.sh passes) — verified by task 21.
- [ ] AC 8 (tests still pass) — verified by task 24.
- [ ] AC 9 (memory-placement.md § Why three buckets gains third trigger) — verified by task 19.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._
