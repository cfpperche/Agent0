# 116 — remove-runtime-introspect — plan

_Drafted from `spec.md` on 2026-05-29. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Phased removal, references-first then files, same order as spec 115 but wider. Sever the live registrations and cross-refs first (settings, entrypoints, rules, memory, site, sync-manifest), then delete the leaf files (hooks, tool, rule, maintainer memory, both test suites, runtime state), then regenerate `MEMORY.md`, then validate (settings parse, full test suite, grep, site build, bench). The one structural subtlety: `.agent0/.runtime-state/README.md` is the cross-capacity state catalog and must survive — only its runtime-introspect row is dropped. `docs/specs/*` is frozen. Historical-narrative memory mentions follow the spec-115 keep-vs-rewire test.

## Files to touch

**Delete:**
- `.claude/hooks/runtime-capture.sh`, `.claude/hooks/runtime-pre-mark.sh` — the hook pair
- `.agent0/tools/probe.sh` — read-back tool (last subcommand `last-run` goes; `rule-loads` already gone in 115)
- `.claude/rules/runtime-introspect.md` — the rule
- `.agent0/memory/runtime-introspect-maintenance.md` — maintainer memory
- `.claude/tests/runtime-introspect/` (17 files), `.claude/tests/runtime-capture-php/` (7 files) — test suites
- `.agent0/.runtime-state/last-run.json` + `.agent0/.runtime-state/in-flight/` — gitignored runtime snapshot (keep README.md)

**Modify:**
- `.claude/settings.json` — drop PreToolUse(Bash) `runtime-pre-mark`, PostToolUse(Bash) `runtime-capture`, and the whole `PostToolUseFailure` event (its only hook was runtime-capture)
- `CLAUDE.md` + `AGENTS.md` — remove the `## Runtime introspect` managed-block section
- `.agent0/hooks/session-start.sh` — remove the `=== runtime-introspect ===` SessionStart readout
- `.agent0/hooks/delegation-stop.sh` — reword the `mirror runtime-capture.sh` comment (dead ref)
- `.claude/rules/delegation.md` — § "Why DONE_WHEN exists": drop the `probe.sh last-run` verifier citation, leave `delegation-verify.sh` as sole verifier
- `.claude/rules/runtime-capabilities.md` — drop the local-test-capture / runtime-introspect matrix row
- `.claude/rules/{lint-validator,php-laravel-support,session-handoff,memory-placement}.md` — sever cross-refs
- `.agent0/memory/{cc-platform-hooks,capacity-spec-index,harness-home,hook-chain-latency,hook-chain-maintenance,propagation-hygiene,user-global-hooks-shadow,visibility-intent}.md` — per-file keep-vs-rewire
- `.agent0/.runtime-state/README.md` — remove the runtime-introspect row
- `.gitignore` — runtime-state ignore lines (preserve the README exception)
- `site/src/i18n/capacities.ts` — remove the runtime-introspect card
- `.agent0/tools/sync-harness.sh` — remove deleted paths from the manifest/COPY_CHECK set
- `.claude/.perf-baseline.json` — prune the removed hooks' entries (bench regenerates)

**Regenerate:**
- `.agent0/memory/MEMORY.md` — via `memory-project.sh`

## Alternatives considered

### Keep `probe.sh` as an empty shell for future subcommands

Rejected — a dispatcher with zero subcommands is cruft; the only-just-removed `rule-loads` and now `last-run` leave nothing. A future tool can re-create it. Empty scaffolding hides intent.

### Keep the capture hooks but stop the SessionStart readout / drop the probe

Rejected — half-removal leaves the every-Bash-call stamping (the overengineering the user flagged) while killing the only read path. Either the passive-capture loop earns its keep whole, or it goes whole. It goes.

### Delete `.agent0/.runtime-state/README.md` with the dir

Rejected — the README catalogs the other live state dirs (browser/delegation/routines). Deleting it loses the discovery entry point for capacities that still exist. Keep README, drop one row.

## Risks and unknowns

- **Test fixtures referencing the capacity** — harness-sync (05/06/13/14/15), hook-chain-latency (01), runtime-capabilities (fixtures), session-state-isolation suites mention settings/CLAUDE.md/gitignore/perf-baseline. Risk they assert removed content. Mitigation: run the full suite post-removal (acceptance Scenario 4); fix any fixture that breaks.
- **settings.json connector commas** — removing the last PostToolUse hook + the trailing PostToolUseFailure event needs careful comma surgery. Mitigation: `jq .` parse check.
- **`.perf-baseline.json` may be asserted by hook-chain-latency test** — pruning vs regenerating. Mitigation: inspect the test; regenerate the baseline if the bench tool supports `--check`/rebaseline.
- **Managed-block sections in CLAUDE.md/AGENTS.md** — these are inside a sync-managed block; removing a `##` section must not break the block markers. Mitigation: edit section body only, preserve block delimiters.

## Research / citations

- Exhaustive in-repo grep (2026-05-29) — full surface enumerated in `spec.md` + this file. Two file-lists captured: capacity-name refs and `.runtime-state`/`last-run` refs.
- Usage evidence (2026-05-29): `last-run.json` write-side live (stamped today), read-side unevidenced — the asymmetry that motivates removal.
- `docs/specs/115-remove-rule-load-debug/` + `114-remove-compaction-continuity/` — removal-shape precedent.
- `.agent0/memory/codex-cli-hooks.md` — confirms the migration alternative was viable, making the deliberate choice to remove (not migrate) explicit.
