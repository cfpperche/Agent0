# 158 — frontend-designer-skill — tasks

_Work top-to-bottom. Check off as you go. If a task reveals the plan is wrong, update `plan.md` first._

## Scaffold
- [x] 1. Scaffold the skill via `/skill new frontend-designer --tier agentskills-portable` (canonical `.agent0/skills/frontend-designer/` + both discovery symlinks).

## Deterministic helper (TDD: red → green)
- [x] 2. Write `tests/01-detect-and-artifacts.sh` first (red): asserts `detect` reports framework/design-system/`/product`/harness for fixture dirs; `artifacts-dir` resolves spec-dir vs `docs/design/<surface>/`; `scaffold-docs` writes both docs from templates; `verify` fails closed when `agent-browser` is unavailable; `caps` prints hard-dep availability.
- [x] 3. Implement `scripts/frontend-designer.sh` subcommands until the test passes (green): `caps`, `detect`, `artifacts-dir`, `scaffold-docs`, `verify`.
- [x] 4. Write the templates: `reference-research.md.tmpl`, `design-direction.md.tmpl`, `fixture-spec.json.tmpl`.

## Skill body + references
- [x] 5. Author `SKILL.md` body: 3 modes (`create`/`refine`/`explore`) with per-mode input/output/acceptance contracts; the stack ladder; the craft loop with explicit stop criteria + max-iteration bound; artifact locations; done-proof + native-honesty; dependency footprint; argument parsing; eval scenarios.
- [x] 6. Author `references/{craft-loop,stack-ladder,reference-research,done-proof}.md`.

## Integration
- [x] 7. Add `.agent0/context/rules/frontend-designer.md` (capacity rule + anti-drift constraints + boundary vs `/product`/visual-contract).
- [x] 8. Add the `## Frontend designer` block to `CLAUDE.md`.

## Validate
- [x] 9. `bash .agent0/skills/skill/scripts/validate.sh .agent0/skills/frontend-designer` passes; run the shell test green; run `doctor.sh` to confirm no harness breakage.
- [x] 10. Regenerate (n/a in source repo — `.agent0/skills` + `.agent0/context` are auto-managed via COPY_CHECK_RECURSIVE; consumer baselines self-update) the harness-sync baseline so the new tracked files are registered.
- [x] 11. Commit the skill + spec (spec `Status: in-progress`).

## Dogfood (separate task phase — see task list #4)
- [x] 12. Demo A — greenfield + real design-system (web): green `verify-contract` report, output reuses fixture tokens.
- [x] 13. Demo B — refine-existing: before/after evidence, bounded diff, preserved behavior, critique loop stops on criteria.
- [x] 14. Demo C — no-design-system fallback on a non-web platform: token-proposal + native-honesty (render evidence if achievable, else labeled).
- [x] 15. Mark spec `Status: shipped`; update HANDOFF.
