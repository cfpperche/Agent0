# 082 — memory-frontmatter-schema — tasks

_Generated from `plan.md` on 2026-05-24. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. **Write `docs/specs/082-memory-frontmatter-schema/verify.sh`** — TDD red phase. Bash script that exercises all 8 acceptance scenarios from `spec.md` (conforming silent / missing required / unknown field / malformed YAML / no frontmatter / out-of-scope ignored / MEMORY.md skipped / 13 entries pass) by piping synthetic JSON payloads through the (not-yet-existing) hook and asserting stderr shape. `chmod +x`. Running it now MUST fail because the hook doesn't exist yet — this is the red signal.
- [x] 2. **Add `## Frontmatter schema` section to `.claude/rules/memory-placement.md`** — document 3 required (`name`, `description`, `metadata.type`) + 3 optional (`metadata.created_at`, `metadata.last_accessed`, `metadata.confirmed_count`) fields with semantics, value shapes, and a worked example. Above the heading add `<!-- DO NOT RENAME — referenced verbatim by .claude/hooks/memory-frontmatter-validate.sh advisory messages -->`. Cross-reference the validator hook.
- [x] 3. **Create `.claude/hooks/memory-frontmatter-validate.sh`** — bash 3.2-compatible, ~80 lines. Algorithm: read JSON from stdin → extract `tool_input.file_path` → exit-0 if not under `<project>/.claude/memory/*.md` → exit-0 if basename is `MEMORY.md` → read file → check `---` at line 1 → extract frontmatter block to next `---` → line-shape parse (top-level + 1 nested `metadata.*` level) → emit `memory-frontmatter-advisory: <file>: <reason>` to stderr for each issue → always `exit 0`. Match sibling style (`set -uo pipefail`, fail-open on jq missing, no destructive ops). Header comment cites spec 082.
- [x] 4. **`chmod +x .claude/hooks/memory-frontmatter-validate.sh`** — required for hook invocation.
- [x] 5. **Register hook in `.claude/settings.json`** — add a 5th `PostToolUse` entry with `matcher: "Edit|Write|MultiEdit"` and `command: bash "$CLAUDE_PROJECT_DIR"/.claude/hooks/memory-frontmatter-validate.sh`. Validate the JSON parses (`jq . .claude/settings.json` clean exit).
- [x] 6. **Migrate 5 non-conforming entries** — prepend frontmatter block (before existing H1) to:
  - `.claude/memory/capacity-spec-index.md` → `name: capacity-spec-index`, `metadata.type: reference`
  - `.claude/memory/forks-ephemeral-dogfood.md` → `name: forks-ephemeral-dogfood`, `metadata.type: project`
  - `.claude/memory/od-grounding-dogfood.md` → `name: od-grounding-dogfood`, `metadata.type: project`
  - `.claude/memory/product-pipeline-empirical-baseline.md` → `name: product-pipeline-empirical-baseline`, `metadata.type: project`
  - `.claude/memory/propagation-hygiene.md` → `name: propagation-hygiene`, `metadata.type: project`
  - `description:` per the proposed text in plan.md § Files to touch.
- [x] 7. **Run `verify.sh` → expect green.** All 8 acceptance scenarios pass with the hook present. If any fail, fix the hook (don't loosen the test).
- [x] 8. **Validator dogfood: invoke hook against all 13 actual `.claude/memory/*.md`** — for each, synthesize a `PostToolUse(Edit)` payload with `tool_input.file_path` pointing at the entry and pipe through the hook. Stderr MUST be empty for all 13 (acceptance criterion #9). If any emit an advisory, fix the entry.
- [x] 9. **End-to-end live test via real edit** — make a trivial Write to a temporary `.claude/memory/_e2e-test.md` with malformed frontmatter (e.g., missing `description:`), confirm the hook fires and the advisory surfaces to the next turn via stderr. Delete the test file. This confirms registration + harness wiring works, not just the script in isolation.
- [x] 10. **Sync-harness coverage check** — run `bash .claude/tools/sync-harness.sh --dry-run` (or inspect the manifest) and confirm the new hook + modified rule are enumerated for propagation. If the new hook isn't covered, add an explicit manifest entry to `.claude/harness-sync-baseline.json` and the manifest source.
- [x] 11. **Flip `spec.md` status to `shipped`** — change `**Status:** draft` → `**Status:** shipped` once all acceptance criteria check out below.
- [x] 12. **Commit** — single commit, scope `082`, body lists the 5-finding shape (hook + rule + settings + 5 migrations + verify.sh). Co-authored line per repo convention.

## Verification

_Each verify item maps to a `spec.md` acceptance criterion (numbered by appearance in the spec)._

- [x] V1. `## Frontmatter schema` section exists in `.claude/rules/memory-placement.md` and documents all 6 fields with example. (spec #1)
- [x] V2. `.claude/hooks/memory-frontmatter-validate.sh` exists, is executable, and is registered as a `PostToolUse(Edit|Write|MultiEdit)` entry in `.claude/settings.json`. (spec #2)
- [x] V3. `verify.sh` scenario "conforming entry passes silently" → green. (spec #3)
- [x] V4. `verify.sh` scenario "missing required field emits advisory" → green. (spec #4)
- [x] V5. `verify.sh` scenario "unknown field emits typo-guard advisory" → green. (spec #5)
- [x] V6. `verify.sh` scenario "malformed YAML emits parse advisory" → green. (spec #6)
- [x] V7. `verify.sh` scenario "file without frontmatter emits advisory" → green. (spec #7)
- [x] V8. `verify.sh` scenario "edits outside `.claude/memory/` are ignored" → green. (spec #8)
- [x] V9. `verify.sh` scenario "`MEMORY.md` skipped" → green. (spec #9)
- [x] V10. Validator dogfood against all 13 actual entries → zero advisories. (spec #10)
- [x] V11. Validator always exits 0 — never `exit 2` or non-zero. (spec #11)
- [x] V12. Validator advisory messages cite `.claude/rules/memory-placement.md § Frontmatter schema` as the authority. (spec #12)

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers. Append to `notes.md` for in-flight decisions per `.claude/rules/spec-driven.md` § The four artifacts._
