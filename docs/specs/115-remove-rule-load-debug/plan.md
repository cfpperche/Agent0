# 115 — remove-rule-load-debug — plan

_Drafted from `spec.md` on 2026-05-29. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Mechanical removal in dependency order: sever live references first, then delete the files they pointed at, then regenerate derived artifacts, then validate. The hook is leaf-level (nothing depends on its *output* programmatically — the probe reads its log, the README/index/site only describe it), so the only ordering constraint is "regenerate `MEMORY.md` after the entry file is gone" and "edit `settings.json` carefully so it stays valid JSON". Everything in `docs/specs/*` is left frozen — git is the audit trail. The edit to `cc-platform-hooks.md` is the one judgment call: preserve the platform facts, sever only the capacity attribution and dead doc-pointers (see § Alternatives).

## Files to touch

**Delete:**
- `.claude/hooks/rule-load-debug.sh` — the hook implementation
- `.agent0/memory/rule-load-debug.md` — the capacity doc
- `.claude/.rule-load-debug.jsonl` + `.claude/.rule-load-debug.jsonl.lock` — gitignored runtime log + flock file (machine-local)

**Modify:**
- `.claude/settings.json` — remove the `InstructionsLoaded` hook block (last key under `hooks`; fix trailing comma on the preceding `PostToolUseFailure` block)
- `.agent0/tools/probe.sh` — remove the `rule-loads)` case branch, its usage-block lines, and the `CLAUDE_RULE_LOAD_DEBUG` hint
- `.gitignore` — remove the two `.claude/.rule-load-debug.jsonl*` lines
- `.agent0/.runtime-state/README.md` — drop the `.rule-load-debug.jsonl` table row; in the intro paragraph drop `rule-load-debug` from the Claude-exclusive-state list
- `.agent0/memory/cc-platform-hooks.md` — correct "7 of these 29" → "6 of these 29", remove the `InstructionsLoaded (rule-load-debug, opt-in)` bullet, sever the two `rule-load-debug.md` cross-references (§ Empirical closing line + § Cross-references bullet); KEEP the event-table row + the empirical dedup finding
- `.agent0/memory/capacity-spec-index.md` — remove the `Rule load debug` row
- `site/src/i18n/capacities.ts` — remove the `id: "rule-load-debug"` capacity object

**Regenerate (not hand-edited):**
- `.agent0/memory/MEMORY.md` — via `bash .agent0/tools/memory-project.sh` after the entry is deleted (raw edit is gate-blocked)

## Alternatives considered

### Delete the empirical dedup section + event-table row in `cc-platform-hooks.md` too

Rejected because those are CC-platform facts (how `InstructionsLoaded` behaves, that the event exists at all), not properties of our hook. The dedup finding was *discovered* via the rule-load-debug dogfood but is true independent of it. Deleting genuine platform knowledge to satisfy a literal "remove all mentions" reading would be a net loss — the same KEEP-platform-knowledge discipline spec 114 applied to its `/compact` mentions. Only the capacity *attribution* and *dead pointers* to the deleted doc are removed.

### Leave the gitignored `.jsonl` log in place

Rejected — a gitignored log whose only writer is deleted is exactly the orphan-state failure mode `.agent0/.runtime-state/README.md` § Discipline warns against ("drop its row in the same commit that removes the writer"). Delete the file and de-gitignore in the same change.

## Risks and unknowns

- **`settings.json` comma handling** — `InstructionsLoaded` is the final key in `hooks`; removing it requires turning the preceding block's closing `],` into `]`. Mitigated by the `jq .` parse check in acceptance.
- **`site` build toolchain** — Astro build may have its own dependency/setup needs; if `npm run build` is not runnable in this environment, fall back to a `tsc`/parse sanity check on the edited `capacities.ts` and note the deferral. The source edit is the load-bearing change; the dist rebuild is already a separately-tracked HANDOFF action.
- **MEMORY.md projection tooling** — relies on `memory-project.sh` (python3+PyYAML or awk fallback). Low risk; it's the sanctioned path and runs on every memory edit already.

## Research / citations

- Exhaustive in-repo grep (2026-05-29) for `rule-load-debug` / `rule-loads` / `CLAUDE_RULE_LOAD_DEBUG` / `InstructionsLoaded` — the full reference surface is enumerated in `spec.md` § Acceptance + this plan's file list.
- Usage-history check (2026-05-29): `.claude/.rule-load-debug.jsonl` = 18 rows, all 2026-05-13, 2 sessions, zero since — the demand-test evidence.
- `docs/specs/114-remove-compaction-continuity/` — precedent for capacity-removal shape + KEEP-platform-knowledge discipline.
