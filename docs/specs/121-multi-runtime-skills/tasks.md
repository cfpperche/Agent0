# 121 — multi-runtime-skills — tasks

_Generated from `plan.md` on 2026-05-30. Work top-to-bottom._

## Implementation

- [x] 1. Create `.agent0/skills/.gitkeep` and `.agents/skills/.gitkeep`; confirm `.agents/` is not gitignored.
- [x] 2. Move `.claude/skills/vuln-audit/SKILL.md` → `.agent0/skills/vuln-audit/SKILL.md` (git mv); remove the now-empty `.claude/skills/vuln-audit/`.
- [x] 3. Create relative discovery symlinks: `.claude/skills/vuln-audit` → `../../.agent0/skills/vuln-audit`; `.agents/skills/vuln-audit` → `../../.agent0/skills/vuln-audit`.
- [x] 4. Verify the relocated SKILL.md has no `${CLAUDE_SKILL_DIR}` dependency (already confirmed) and still validates against the agentskills spec.
- [x] 5. sync-harness: add `.agent0/skills` to `COPY_CHECK_RECURSIVE`; add the two `.gitkeep`s to `COPY_CHECK_FILES`.
- [x] 6. sync-harness: implement `sync_skill_discovery_links()` — for each `.agent0/skills/<slug>/`, ensure `.claude/skills/<slug>` + `.agents/skills/<slug>` relative symlinks; detect symlink-hostile checkout (probe) → fall back to materialized copy + `skills-advisory:`. Call it on the apply path (not dry-run/check).
- [x] 7. Write `.agent0/tests/multi-runtime-skills/` scenarios 01–08 + `run-all.sh`.
- [x] 8. Add the **skills** row to `.claude/rules/runtime-capabilities.md`.
- [x] 9. Document the model + per-skill migration runbook in `.claude/rules/harness-sync.md` (+ a pointer in `portability-tiers.md`).
- [x] 10. Update `.agent0/memory/harness-home.md` deferred-skills disposition.
- [x] 11. Update `.agent0/memory/MEMORY.md` index if harness-home entry summary changed (via projection, not raw edit).

## Verification

- [x] `bash .agent0/tests/multi-runtime-skills/run-all.sh` — all scenarios pass.
- [x] `bash .agent0/tests/harness-sync/run-all.sh` — no regression from the sync-harness change.
- [x] `/vuln-audit` still works through the relocated path (`bash .agent0/tools/vuln-audit.sh --help` + a default run; the skill body still points at `.agent0/tools/vuln-audit.sh`).
- [x] Relocated SKILL.md passes `validate.sh` (agentskills frontmatter).
- [x] Both symlinks resolve to the same canonical `.agent0/skills/vuln-audit/SKILL.md` (realpath equality).

## Notes

_Post-merge: a real fresh Codex session should confirm `codex debug prompt-input` lists `vuln-audit` from `.agents/skills` and that explicit `$vuln-audit` invocation runs the tool — the offline tests assert symlink/discovery-path structure, not a live Codex session._
