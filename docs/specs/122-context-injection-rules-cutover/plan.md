# 122 — context-injection-rules-cutover — plan

_Drafted 2026-05-30._

## Approach

Hard-cut the harness away from Claude Code's native `.claude/rules/` loader:

1. Move all first-party rule documents to `.agent0/context/rules/`.
2. Add `.agent0/hooks/context-inject.sh` as the single runtime-neutral hydrator.
3. Register the hydrator in Claude Code project settings and Codex's opt-in config template.
4. Update sync-harness to ship `.agent0/context/` and stop shipping `.claude/rules/`.
5. Update entrypoints, runtime-capabilities, docs, and tests to point at the new surface.

The hydrator v1 is deliberately deterministic: it emits a small startup index at `SessionStart`, and
on `UserPromptSubmit` emits selected fragments based on prompt text, explicit path mentions, and
frontmatter `paths:` globs where they can be reduced to useful literal anchors. Every injected block
is provenance-labeled and bounded.

## Files to touch

**Create / move:**
- `.agent0/context/rules/*.md` — moved former `.claude/rules/*.md` files.
- `.agent0/hooks/context-inject.sh` — shared hydrator.
- `.agent0/tests/context-injection/` — focused tests.

**Modify:**
- `.claude/settings.json` — add `SessionStart` + `UserPromptSubmit` hook registrations.
- `.codex/config.toml.example` — add commented matching hook blocks.
- `.agent0/tools/sync-harness.sh` — ship `.agent0/context`; drop `.claude/rules` from manifest.
- `.agent0/tools/check-instruction-drift.sh` + runtime-capabilities tests — registry path moves.
- `CLAUDE.md` + `AGENTS.md` — managed block points at `.agent0/context/rules/*`.
- `.agent0/context/rules/runtime-capabilities.md`, `harness-sync.md`, `memory-placement.md` — document
  the cutover.
- README / site copy where it names `.claude/rules` as the rule home.

**Delete as a native surface:**
- `.claude/rules/*.md` — no first-party harness rule bodies remain there.

## Risks

- **Path-scoped parity loss.** Claude's native rules could load on file access; hooks see prompts and
  lifecycle events. v1 mitigates with prompt/path selection and explicit source labels.
- **Startup context bloat.** Loading all former rules would exceed the spirit of the cutover. The
  startup hook emits an index; prompt turns hydrate selected fragments.
- **Consumer stale files.** Existing consumers may already have `.claude/rules`. The plan must verify
  sync deletion behavior before claiming clean migration.
- **Current-session inertia.** A Claude/Codex session that was already open before the change may keep
  older instructions/hooks until restarted.

## Validation

- `bash .agent0/tests/context-injection/run-all.sh`
- `bash .agent0/tests/runtime-capabilities/run-all.sh`
- `bash .agent0/tests/harness-sync/run-all.sh`
- `bash .agent0/tests/instruction-drift/run-all.sh`
- `rg -n "\\.claude/rules" --glob '!docs/specs/**'` should show no live harness references except
  deliberate historical notes, if any.
