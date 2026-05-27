# 095 — harness-consumer-vocab — plan

_Drafted from `spec.md` on 2026-05-27. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Single-PR mass-rename of the consumer-of-harness vocabulary across the **shipped surface** (the manifest `sync-harness.sh` propagates). The rename is per-occurrence reviewed — not blind sed — because the word "fork" carries two meanings in this repo: the deprecated consumer-relationship sense (the target of this rename) and a legitimate git-operation sense ("fork the Agent0 repo on GitHub to contribute upstream") that must stay. The empirical scope is **494 occurrences across ~85 files** — larger than the handoff's "~50" estimate, but still tractable as one diff if grouped commit-by-category for review.

Vocabulary decided in spec OQs (confirmed 2026-05-27):

| Old | New |
| --- | --- |
| fork (consumer-relationship) | `consumer project` (prose) / `consumer` (adjective) / `<consumer-path>` (CLI) |
| fork-bound surface | `shipped surface` |
| fork-bound file | `shipped file` |
| fork-customization / fork-customized | `consumer customization` / `consumer-customized` |
| fork-only / fork-specific | `consumer-only` / `consumer-specific` |
| first-fork friction | first-consumer friction |

Order of operations is **glossary → CLI → rules → propagation pair → tests → entrypoints → drift check**. Glossary first so reviewers have the canonical vocabulary while reading every later hunk; CLI second because the rest of the codebase references `<consumer-path>` and the new flag-help. Rules ahead of tests because tests reference rule-prose in their assertion messages. Propagation-advisory rule + hook + tests + paired memory (`propagation-hygiene.md`, per OQ #3) renamed as a single sub-step — they are physically separate but documentally one pair. Drift check (`bash .claude/tools/sync-harness.sh --check --agent0-path=. <consumer-path>`) against a real consumer (mei-saas) is the smoke test that the rename didn't accidentally leak inconsistent vocabulary into the sync surface — it is run BEFORE merge, not after.

The work is **not split into bundles** internally (this is the OQ #4 single-PR decision), but commit hygiene inside the PR groups files by category — reviewer reads one commit per file class (`harness-sync.md`, then `sync-harness.sh`, then `tests/harness-sync/`, then propagation-pair, then CLAUDE.md/AGENTS.md/skills) instead of 85 files in one mega-diff. The sync-harness baseline (`.claude/harness-sync-baseline.json`) re-baselines as the final step before the consumer-side sync — every shipped file gets a new hash because every shipped file changed, so re-baselining is mechanical.

## Files to touch

**Modify (per-occurrence reviewed rename — keep legitimate git-operation "fork" usages):**

- **Glossary host (1 file)**
  - `.claude/rules/harness-sync.md` (84 occurrences — heaviest single file) — add canonical `## Glossary` section near the top defining harness / consumer project / shipped surface / and explicitly the surviving git-operation "fork" usage; rename all 84 occurrences.

- **CLI tool (2 files)**
  - `.claude/tools/sync-harness.sh` (61 occurrences) — positional arg `<fork-path>` → `<consumer-path>`; shell variable `FORK_PATH` → `CONSUMER_PATH`; usage / help text; error message `missing <fork-path>` → `missing <consumer-path>`; in-script comments.
  - `.claude/tools/memory-project.sh` (1 occurrence) — comment only.

- **Rules — heavy renames (5 files, ≥10 occurrences each)**
  - `.claude/rules/mcp-recipes.md` (21)
  - `.claude/rules/memory-placement.md` (14)
  - `.claude/rules/image-gen.md` (12)
  - `.claude/rules/lint-validator.md` (11)

- **Rules — medium renames (3 files, 5-10 occurrences each)**
  - `.claude/rules/typecheck-advisory.md` (8)
  - `.claude/rules/php-laravel-support.md` (8)
  - `.claude/rules/secrets-scan.md` (6)

- **Rules — light renames (≤5 occurrences each — batched)**
  - `.claude/rules/runtime-introspect.md` (4) / `.claude/rules/supply-chain.md` (3) / `.claude/rules/routines.md` (3) / `.claude/rules/rule-load-debug.md` (2) / `.claude/rules/hook-chain-latency.md` (1) / `.claude/rules/compaction-continuity.md` (1)

- **Propagation pair (4 surfaces — atomic sub-commit per OQ #3)**
  - `.claude/rules/propagation-advisory.md` (5) — rename "fork-bound surface" → "shipped surface" everywhere; rename description prose.
  - `.claude/hooks/propagation-advise.sh` (5) — rename internal `path-exclusion` comment refs to "fork-bound"; the regex labels stay (they target a class of leak pattern, not a vocabulary).
  - `.claude/tests/propagation-advisory/06-non-fork-path-silent.sh` — rename to `06-non-shipped-path-silent.sh`; update assertion strings.
  - `.claude/memory/propagation-hygiene.md` (22) — per OQ #3, included for pair consistency. Rename "fork-bound files" → "shipped files", "fork-bound surface" → "shipped surface", "leaf fork" → "leaf consumer project", "every fork" → "every consumer project". Frontmatter `description:` field also updates.

- **Hooks (3 files)**
  - `.claude/hooks/session-start.sh` / `.claude/hooks/session-stop.sh` / `.claude/hooks/mcp-recipes-hint.sh` — 1 occurrence each, prose in stderr or comment.

- **Skills (15 files, mostly 1-3 occurrences each)**
  - `.claude/skills/{brainstorm,image,product,remind,routine,sdd,skill}/SKILL.md`
  - `.claude/skills/image/references/tier-pricing.md`
  - `.claude/skills/skill/references/portability-tiers.md`
  - `.claude/skills/product/references/pipeline-coverage.md`
  - `.claude/skills/product/templates/pipeline/{02-prototype,04-validation,08-system-design,10-roadmap,11-cost-estimate}/...` — `.md` files where "fork" appears in prose explaining the consumer relationship.

- **Tests (~40 files in `.claude/tests/harness-sync/` + small adjacent dirs)**
  - All test scripts in `.claude/tests/harness-sync/01-...sh` through `34-...sh` — rename local shell variable `FORK="$TMPDIR/fork"` → `CONSUMER="$TMPDIR/consumer"` (cosmetic but consistent); rename mkdir paths `fork/` → `consumer/`; update assertion message strings that contain "fork". Rename test files themselves:
    - `13-gitignore-merge-fork-missing.sh` → `13-gitignore-merge-consumer-missing.sh`
    - `14-gitignore-merge-fork-customized.sh` → `14-gitignore-merge-consumer-customized.sh`
  - `.claude/tests/harness-sync/README.md` — rename vocabulary in prose.
  - `.claude/tests/project-memory/02-no-fork-propagation.sh` (13) — rename file → `02-no-consumer-propagation.sh`; update assertion strings.
  - `.claude/tests/secrets-scan/07-template-portable.sh` (21) — rename "fresh fork" prose comments.
  - `.claude/tests/typecheck-advisory/{01,06}-...sh` / `.claude/tests/instruction-drift/05-sync-harness-detects-agents-md-drift.sh` / `.claude/tests/mcp-recipes/05-co-exists-with-011.sh` / `.claude/tests/propagation-advisory/{01,02,05,06}-...sh` — small string + path renames.

- **Entrypoints (2 files)**
  - `CLAUDE.md` (7) — § Harness sync and adjacent sections reframe consumer relationship.
  - `AGENTS.md` (8) — same renames as CLAUDE.md (the two are baseline-tracked siblings).

- **Validator (1 file)**
  - `.claude/validators/run.sh` — 1 prose comment occurrence.

**Re-baseline (1 file, final step):**

- `.claude/harness-sync-baseline.json` — regenerated by `bash .claude/tools/sync-harness.sh --baseline` after every shipped file is final. Hash field changes for every renamed file; mechanical re-write.

**Keep unchanged (legitimate git-operation "fork" — do NOT rename, audit each):**

- Phrasing like "fork the Agent0 repo on GitHub to contribute upstream" — survives wherever it occurs (sample: zero current occurrences found, but the spec acceptance criterion calls out the case explicitly so reviewers must verify per-occurrence).

**Explicitly excluded from scope (per spec § Non-goals):**

- `docs/specs/*` — immutable design memory.
- All other `.claude/memory/*.md` files except `propagation-hygiene.md` — per OQ #3, only the paired memory is in scope.
- Vendor / design-systems content (`.claude/skills/*/vendor/`, `.claude/skills/*/design-systems/`).

## Alternatives considered

### Sed-driven blind mass-rename

Rejected because the word "fork" carries two distinct meanings in this codebase (consumer relationship + git-operation), and the latter must survive. A blind `sed -i 's/\bfork\b/consumer/g'` would mangle the legitimate cases (the few that currently exist, plus any future addition by an unaware contributor). Per-occurrence review is the only safe path; the cost is reviewer time, paid once.

### Incremental rename across 3-5 PRs (one per file class)

Rejected per OQ #4 — single PR was the chosen path. Reasoning: leaves the codebase in mixed-vocabulary state for weeks; new contributors hit both terms during the transition; sync-baseline would churn N times (one re-baseline per PR); coordination cost with the deferred consumer-side syncs (mei-saas + codexeng) multiplies. The single-PR cost (large diff) is one-time and reviewable when grouped by commit-per-category.

### Rename only the public surface (CLI + CLAUDE.md), leaving rules/tests/memory

Rejected because OQ #2 decided to rename "fork-bound surface" → "shipped surface", which is a *concept* the propagation-advisory rule and its paired memory document end-to-end. A partial rename creates the exact doc-sync gap the OQ #3 decision rejected: rule says "shipped surface" while memory says "fork-bound". Better to do one full pass.

### Skip the paired memory rename (per Non-goal #1)

Rejected per OQ #3 — included for pair consistency. Reasoning: `propagation-hygiene.md` and `propagation-advisory.md` are an explicit doc-pair with cross-refs; divergent vocabulary breaks the pair. Cost is ~5 min of edits; win is no doc-sync gap.

## Risks and unknowns

- **Reviewer fatigue on a ~85-file PR.** Mitigated by commit-per-category grouping (one commit per file class — glossary, CLI, rules-heavy, rules-medium, rules-light, propagation-pair, tests, entrypoints, baseline). Reviewer can sign off per commit. Still — single PR review burden is real and unavoidable.
- **The internal shell variable rename `FORK_PATH` → `CONSUMER_PATH` is invasive in `sync-harness.sh`.** This is cosmetic (shell vars are private), but renaming makes the diff larger. Mitigation: keep the rename consistent everywhere it appears in the script (~60 occurrences); do NOT leave half. Tests that scrape stderr strings (`missing <fork-path>` etc) need to update in lockstep.
- **Test fixtures that `mkdir fork/` and reference `$FORK`** — renaming the directory and variable is mechanical but the test scripts are 34 files. Easy to miss one. Mitigation: after the test-rename commit, `grep -rn '\bfork\b\|FORK' .claude/tests/harness-sync/` should return zero hits aside from intentional legitimate git-operation prose (sample-check expected zero).
- **The sync-harness re-baselining step changes every shipped file's hash.** Once the rename lands, every consumer project's next `--check` will see "stale" on every shipped file. This is exactly the OQ #5 decision (defer sync until 095 ships); consumers (mei-saas, codexeng) get one big `--apply` cycle. Document this in the PR body so future-self in the consumer-sync session doesn't panic at the volume of drift.
- **`propagation-advise.sh` exclusion list** references "fork-bound" in comments but the regex *patterns* don't carry the word — confirmed by sampling. Safe to rename the comments without touching the patterns.
- **CLAUDE.md and AGENTS.md drift.** These are baseline-tracked siblings (§ harness-sync.md). After the rename, both must end up textually equivalent in the renamed sections, OR the `.claude/tests/instruction-drift/05-sync-harness-detects-agents-md-drift.sh` test fails. Mitigation: edit CLAUDE.md first, copy the edited block into AGENTS.md, then run the test.
- **Unknown: are there `# OVERRIDE: propagation-exempt:` markers anywhere that lock in old vocabulary?** Answer found via `grep -r 'propagation-exempt' .claude/` — zero results. No override-marker maintenance needed.
- **Unknown: consumer-side `.claude/settings.json` references the harness CLI flag.** Need to confirm no consumer's settings.json hard-codes `<fork-path>` in a script invocation. Sample-check: `grep 'fork-path' /home/goat/mei-saas /home/goat/codexeng -r 2>/dev/null` (run pre-merge to verify).

## Research / citations

- `docs/specs/095-harness-consumer-vocab/spec.md` — the source spec; intent + acceptance criteria + resolved OQs.
- Conversation 2026-05-27 — maintainer raised the vocabulary mismatch ("essa rule hook-chain-latency.md é shipada para forks? talvez a nomenclatura forks está errado").
- `.claude/rules/harness-sync.md` — current canonical doc for the sync mechanism (will host the new glossary).
- `.claude/rules/propagation-advisory.md` + `.claude/memory/propagation-hygiene.md` — the paired-doc precedent (OQ #3).
- `.claude/rules/hook-chain-latency.md` + `.claude/memory/hook-chain-maintenance.md` — analogous rule/memory split shipped in commit `83a4ed7` (same session as this spec was scaffolded); precedent for keeping shipped-surface and maintainer-only surface physically separate.
- `.claude/tools/sync-harness.sh` — CLI source; the single point of truth for the positional-arg name.
- Spec 092 (multi-runtime handoff) — precedent of vocabulary-precise renames in this repo; uses "runtime" instead of "agents-that-fork-the-config".
- Spec 094 (hook-chain-latency) follow-up split (commit `83a4ed7`) — the immediate trigger that surfaced the consumer-vs-fork mismatch.
- Grep audits (run 2026-05-27): 494 total occurrences across 85 files in shipped surface (excluding `.claude/memory/*` except `propagation-hygiene.md`, `docs/specs/*`, vendor, design-systems).
