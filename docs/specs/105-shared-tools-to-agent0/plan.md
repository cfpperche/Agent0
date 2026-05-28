# 105 — shared-tools-to-agent0 — plan

_Drafted from `spec.md` on 2026-05-28. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

A pure path-relocation across six layers, applied in a dependency-safe order so the live session and the consumer-migration path both stay coherent. The change is mechanical — every reference is a literal `.claude/tools/<x>` that swaps to `.agent0/tools/<x>` — but it has two genuinely delicate spots: `sync-harness.sh` is **self-referential** (its own manifest, lib-source path, and self-overwrite guard name `.claude/tools/`), and three **path-scoped rules** trigger on the tool paths via `paths:` frontmatter. Both are caught explicitly below.

Order: (1) `git mv` the eight scripts + `lib/` so the files live at the new path first. (2) Repoint `sync-harness.sh`'s four internal self-references (manifest glob, lib literal, `MANAGED_BLOCK_LIB` fallback, `_self_rebootstrap` rel). (3) Repoint the moved tools' own internal content references (docstrings, cross-tool invocations). (4) Repoint the three rule `paths:` frontmatter globs — these are functional triggers; if missed, editing the moved tool stops loading its companion rule. (5) Rewrite live references in rules' bodies, hooks, skills, entrypoints (CLAUDE.md + AGENTS.md identically — managed-block byte-equality), HANDOFF, READMEs, current-mechanism memory, routines, the Codex example, and the site i18n strings. (6) Rewrite test references (hand-verify the assertion-sensitive harness-sync / instruction-drift / codex-mcp-recipes suites; sed the rest). Then run every affected suite.

**Live vs frozen rule (the load-bearing scoping decision):** rewrite every reference *outside* `docs/specs/`; leave every reference *inside* `docs/specs/NNN-*/` untouched (frozen design memory — except this spec, 105, whose `.claude/tools/` mentions correctly describe the source of the move). One memory exception: `.agent0/memory/cc-platform-hooks.md:138` references `probe.sh`'s old path inside a *historical debugging narrative* (a frozen observation about CC hook-dedup), not a current-mechanism instruction — leave it, same spirit as a frozen spec. All other memory refs describe current mechanism (how to invoke `bench-hooks.sh`, `probe.sh`, `check-instruction-drift.sh`; the shipped-surface glob set) → rewrite.

## Files to touch

**git mv (the relocation itself):**
- `.claude/tools/{sync-harness,probe,check-instruction-drift,bench-hooks,run-routine,install-routines,uninstall-routines,codex-local-env}.sh` → `.agent0/tools/`
- `.claude/tools/lib/managed-block.sh` → `.agent0/tools/lib/managed-block.sh`
- Confirm `.claude/tools/` holds no tracked files afterward (dir removed)

**Modify — `sync-harness.sh` internal self-references (4 spots, ~5 ref lines):**
- `COPY_CHECK_GLOBS`: `.claude/tools|*.sh` → `.agent0/tools|*.sh` (the existing `.agent0/tools|memory-*` stays — it covers `memory-query-helper.py`; the `*.sh` glob covers everything else, dedup via the sorted-uniq manifest)
- `COPY_CHECK_FILES`: `.claude/tools/lib/managed-block.sh` → `.agent0/tools/lib/managed-block.sh`
- `MANAGED_BLOCK_LIB` fallback (≈ lines 120-121): `.claude/tools/lib/managed-block.sh` → `.agent0/`
- `_self_rebootstrap` `rel=` (≈ line 330): `.claude/tools/sync-harness.sh` → `.agent0/tools/sync-harness.sh`

**Modify — moved tools' own content refs (docstrings, self-invocation, cross-tool calls):**
- `probe.sh` (7), `check-instruction-drift.sh` (2), `install-routines.sh` (2), `bench-hooks.sh` (1), `run-routine.sh` (1), `uninstall-routines.sh` (1); verify `codex-local-env.sh`

**Modify — rule `paths:` frontmatter (functional triggers — MUST move):**
- `.claude/rules/harness-sync.md` — `paths: .claude/tools/sync-harness.sh` → `.agent0/…`
- `.claude/rules/runtime-capabilities.md` — `paths: .claude/tools/check-instruction-drift.sh` → `.agent0/…`
- `.claude/rules/runtime-introspect.md` — `paths: .claude/tools/probe.sh` → `.agent0/…`

**Modify — rule bodies + skills + hooks:**
- `.claude/rules/`: `harness-sync.md` (12 — heaviest; incl. § Manifest scope glob list + § Self-rebootstrap "COPY_CHECK_GLOBS → .claude/tools/*.sh"), `runtime-introspect.md` (6), `runtime-capabilities.md` (4), `routines.md` (5), `delegation.md` (1), `memory-placement.md` (1), `session-handoff.md` (1)
- `.claude/skills/product/SKILL.md` (1), `.claude/skills/routine/SKILL.md` (3), `.claude/skills/routine/scripts/list.sh` (1)
- `.agent0/hooks/routines-readout.sh` (1), `.agent0/hooks/session-start.sh` (2)
- `.claude/hooks/propagation-advise.sh` (1) + verify its shipped-surface path set includes `.agent0/tools/` after the move

**Modify — entrypoints (byte-equal managed block) + state docs:**
- `CLAUDE.md` (3) + `AGENTS.md` (3) — edit identically; `instruction-drift/03` asserts byte-equality
- `.agent0/HANDOFF.md` (2), `.agent0/.runtime-state/README.md` (3), `.claude/tests/harness-sync/README.md` (1)

**Modify — current-mechanism memory + routines + codex + site:**
- `.agent0/memory/`: `hook-chain-latency.md` (4), `hook-chain-maintenance.md` (1), `rule-load-debug.md` (1), `runtime-capabilities-maintenance.md` (2), `runtime-introspect-maintenance.md` (1), `propagation-advisory-maintenance.md` (1), `propagation-hygiene.md` (2 — line 22 glob set + line 68 path)
- **LEAVE:** `.agent0/memory/cc-platform-hooks.md:138` (frozen historical narrative)
- `.agent0/routines/hook-chain-bench.md` (1)
- `.codex/config.toml.example` (1 — `codex-local-env.sh` launch instruction; shipped file)
- `site/src/i18n/strings.ts` (3 — FAQ copy in en/pt/es naming `sync-harness.sh`; not shipped surface but live public docs, kept accurate)

**Modify — tests (hand-verify the assertion-sensitive ones; sed the rest):**
- Hand-verify: `harness-sync/33-self-overwrite-single-run.sh` (11 — exercises the self-rebootstrap path being repointed), `instruction-drift/05-sync-harness-detects-agents-md-drift.sh` (6 — invokes sync-harness against a fixture), `codex-mcp-recipes/03-local-env-launcher.sh` (4 — invokes codex-local-env.sh)
- sed + spot-check: remaining `harness-sync/*` (1 ref each), `hook-chain-latency/{02,03}`, `runtime-capabilities/*` (+ `fixtures.sh`), `runtime-introspect/{05,07,09}`, `project-memory/02`

**Leave untouched (frozen):** every `docs/specs/NNN-*/` except `105` itself.

## Alternatives considered

### Split into per-tool child specs (one per script)

Rejected. The eight tools share `sync-harness.sh`'s manifest, the same three path-scoped rules, the same test suites (harness-sync references most tools), and the same entrypoint managed block. Splitting would multiply churn on those shared files and produce eight baseline bumps for one coherent mechanical move. Bundling is *less* diff, not a mega-diff — exactly the 104 reasoning (it bundled three state dirs for the same reason).

### Move the consumer-side baseline file (`.claude/harness-sync-baseline.json`) in the same pass

Rejected (and recorded as a non-goal). It is a consumer-side runtime artifact, not a tool, and its path is hardcoded in every existing consumer's `git`-tracked tree; relocating it would break reconciliation for every consumer mid-flight. It belongs to a later, separately-reasoned refactor — not this row.

### Add a back-compat shim at `.claude/tools/` that forwards to `.agent0/tools/`

Rejected. Violates the repo's no-backwards-compat-shim discipline (CLAUDE.md). The sync deletion pass already migrates consumers cleanly (old tools become orphans, removed); a shim would be dead weight that never gets removed.

## Risks and unknowns

- **Self-rebootstrap transitional crash (the spec's open question).** A consumer whose stale `.claude/tools/sync-harness.sh` runs the migrating `--apply` gets that file deleted (orphan) while bash reads it; the old script also guards the old path in `_self_rebootstrap`. Same one-time crash already documented in `harness-sync.md` § Gotchas — the run already wrote `.agent0/tools/sync-harness.sh`, so a re-run completes. **Disposition: accept; add one gotcha line to `harness-sync.md` noting the tool-relocation instance.** No mitigation code.
- **`harness-sync` tests are assertion-sensitive.** Tests 33 (self-overwrite) and the manifest-walking ones assert exact paths and may build synthetic `.claude/tools/` fixtures. Blind sed could corrupt an expected-output heredoc or, worse, make a test pass against the wrong path. Mitigation: read tests 33 / instruction-drift 05 / codex-mcp-recipes 03 in full before editing; for the rest, sed then `git diff` spot-check.
- **CLAUDE.md/AGENTS.md managed-block byte-equality.** `instruction-drift/03` fails if the two managed blocks diverge by a byte. Any `.claude/tools/` mention inside the managed region must be edited identically in both. Mitigation: run `instruction-drift` after.
- **Missing a path-scoped rule trigger.** If a `paths:` glob is left at `.claude/tools/…`, the rule silently stops loading when the moved tool is edited (no error, just absent context). Mitigation: the three known ones are listed; re-grep all rule frontmatter post-edit to confirm none remain.
- **`propagation-advise.sh` shipped-surface set.** The hook scans shipped files for leak patterns; its path set may hardcode `.claude/tools/`. If so, edits to the moved tools would stop being scanned. Verify and repoint the hook's surface set (and the `propagation-advisory-maintenance.md` doc that mirrors it).
- **Live-session mid-migration window.** This session's hooks/probe resolve the old path until the edits land; harmless and ephemeral (same as 104). `CLAUDE_SKIP_SESSION_HOOKS=1` is the escape hatch if it interferes.

## Research / citations

- `docs/specs/104-state-dirs-to-agent0/{spec,plan,tasks,notes}.md` — direct precedent for the relocation shape, the dependency-safe ordering, the byte-equality + harness-sync-fixture gotchas, and the capacity-only posture. Read in full this session.
- `.claude/rules/harness-sync.md` § Manifest scope / § Self-rebootstrap / § Path relocations / § Gotchas — read in full (injected this session); confirms the manifest mechanics, the self-overwrite guard, and the pre-existing transitional-crash gotcha this move adds an instance to.
- `.claude/tools/sync-harness.sh` lines 120-121, 180-206, 324-360 — read directly; confirms the four internal self-reference spots and the `find -maxdepth 1 -type f -name` glob-walk semantics that make `.agent0/tools|*.sh` + `.agent0/tools|memory-*` jointly cover the moved set.
