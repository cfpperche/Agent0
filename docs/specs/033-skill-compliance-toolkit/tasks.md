# 033 — skill-compliance-toolkit — tasks

_Generated from `plan.md` on 2026-05-17. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Phase A — knowledge artifacts (no logic depends on these until Phase B)

- [x] 1. Create the skill scaffold: `mkdir -p .claude/skills/skill/{templates,references,scripts,tests/fixtures}`
- [x] 2. Write `.claude/skills/skill/references/spec-snapshot.md` — verbatim copy of https://agentskills.io/specification with a dated header (`Retrieved: 2026-05-17`, source URL, attribution to Anthropic + agentskills.io contributors)
- [x] 3. Write `.claude/skills/skill/references/portability-tiers.md` — definition of the 3 tiers (`cc-native`, `agentskills-portable`, `runtime-agnostic`), one canonical `compatibility:` text per tier, at least one example from the Agent0 skill suite per tier, plus a decision flowchart (which tier applies given body shape)
- [x] 4. Write `.claude/skills/skill/references/description-best-practices.md` — condensed from https://agentskills.io/skill-creation/best-practices, focused on description authoring (good vs poor examples, keyword density, the "when to use" rule)
- [x] 5. Write `.claude/skills/skill/references/frontmatter-validation-rules.md` — human-readable enumeration of every check `validate.sh` performs, with the spec citation per rule + remediation hint per failure mode

### Phase B — validator + fixtures (testable in isolation)

- [x] 6. Build the fixture corpus under `.claude/skills/skill/tests/fixtures/`: 8 fixtures total (1 compliant + 7 failure modes: missing-name, dirname-mismatch, name-regex-fail, description-oversize, compatibility-oversize, body-too-long, missing-frontmatter)
- [x] 7. Implement `.claude/skills/skill/scripts/validate.sh` — bash, zero-dep, executable; parses YAML frontmatter, applies rules per `frontmatter-validation-rules.md`, exit 0 on pass / non-zero on fail with stderr listing each violation by rule name; `command -v skills-ref` short-circuits to defer-to-canonical
- [x] 8. Implement `.claude/skills/skill/tests/validate.test.sh` — executable shell harness; iterates fixtures, runs `validate.sh` against each, compares exit code against the fixture's expected outcome (encoded as `EXIT=N` in sibling `EXPECTED` file); exits non-zero on any mismatch
- [x] 9. Run `bash .claude/skills/skill/tests/validate.test.sh` — exit 0 (8/8 fixtures classified correctly)

### Phase C — resolve open questions before logic that depends on them

- [x] 10. Resolve spec Open Question #1 (`metadata.portability-tier` collision risk): WebSearch found no prior community claim on `portability-tier`. Defensive choice: namespace as `agent0-portability-tier` (kebab-prefix) to defend against future upstream collision. Documented in `references/portability-tiers.md` § "Why the namespace is `agent0-` prefixed".
- [x] 11. Resolve spec Open Question #4 + plan Risk #1 (`argument-hint` migration): claude-code-guide agent consulted official Claude Code docs (https://code.claude.com/docs/en/skills.md). Verdict: `argument-hint` is read only at top-level. Decision: porter leaves `argument-hint:` at top-level (no nesting). Documented in `references/portability-tiers.md` § "On `argument-hint` placement" and inline in `port-frontmatter.sh` header.

### Phase D — templates + porter

- [x] 12. Write `.claude/skills/skill/templates/SKILL.md.tmpl` — canonical compliant template; all spec-defined fields present with `# comment` per field explaining purpose + cap; `metadata.agent0-portability-tier:` slot per Phase C decision
- [x] 13. Write `.claude/skills/skill/templates/cc-native.tmpl` and `templates/portable.tmpl` — per-tier pre-filled variants; `compatibility:` text matches the canonical text in `portability-tiers.md`
- [x] 14. Implement `.claude/skills/skill/scripts/port-frontmatter.sh` — idempotent patcher; reads existing SKILL.md, adds missing required fields (`name:` from dirname, `compatibility:` from detected tier), keeps `argument-hint:` top-level (Phase C decision), preserves body bytes verbatim. Sandbox-tested on copy of `remind/SKILL.md`: validate-pass + body-bytes-identical (5664 bytes) + idempotent (md5 stable on re-run).

### Phase E — meta-skill orchestrator

- [x] 15. Write `.claude/skills/skill/SKILL.md` — meta-skill with 5 subcommands (`new`, `audit`, `port`, `validate`, `list`); follows the `/sdd` shape; self-compliant (verified via `validate.sh .claude/skills/skill` → exit 0; CC harness picked it up and surfaced it in the available-skills list as `skill`)
- [x] 16. Add `## Skill compliance` capacity section to `CLAUDE.md` — single paragraph after `## Rule load debug`, before `## Compact Instructions`; follows existing capacity-section convention (cites spec 033, points at `/skill` toolkit + references files + the two locked decisions)

### Phase F — dogfood

- [x] 17. Port the 3 first-party Agent0 skills via `bash .claude/skills/skill/scripts/port-frontmatter.sh .claude/skills/<slug>`: ran for `remind`, `sdd`, `brainstorm`; body bytes byte-identical (5664/14779/14454 bytes pre = post); all 3 detected as `cc-native` tier; all 3 pass `validate.sh` after port

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria. Each one should map to a checklist item there._

- [x] 18. **Meta-skill self-compliance**: `bash validate.sh .claude/skills/skill` → exit 0, silent stderr ✓
- [x] 19. **First-party skills pass after port**: `validate.sh` on remind, sdd, brainstorm — all PASS ✓
- [x] 20. **Scaffolder produces compliant SKILL.md without manual edits**: scaffolded `sample-throwaway` via `cp cc-native.tmpl + sed`, validated PASS, cleaned up ✓
- [x] 21. **Audit enumerates with tier labels, no false positives**: ran audit loop, 4 skills all compliant + cc-native (`remind/sdd/brainstorm/skill`). External CC-marketplace skills not enumerated per resolved Open Q #3 ✓
- [x] 22. **Port preserves body bytes**: verified during Phase F — diff silent on all 3 ports ✓
- [x] 23. **Validator exit-code shape and stderr clarity**: compliant fixture → exit 0 silent; name-regex-fail → exit 1 with `rule2-name-regex` + `rule3-name-dirname-mismatch` on stderr (prefixed per rule ID) ✓
- [x] 24. **skills-ref defer-to-canonical**: N/A — skills-ref not installed in dev environment. Code path verified by inspection at `validate.sh:42-44` (`command -v skills-ref >/dev/null 2>&1 && exec skills-ref validate "$skill_dir"`)
- [x] 25. **Knowledge artifacts present and non-empty**: 4 reference files exist, sizes 7398 / 8562 / 5307 / 6405 bytes; all have discoverable H1 titles ✓

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._

- **gawk reserved-word bug in `validate.sh`** (Phase B). First-pass implementation passed `-v close="$close_line"` to awk, but gawk reserves `close` as a builtin function name. Bug surfaced only on stderr spot-check — the test harness checks exit codes only, and the wrapper exits silently when awk fails late in the script. **Lesson:** stderr-matching in the test harness would have caught it earlier. Fixed by renaming `-v` variable to `cl`. Soft warnings (rule7/rule8) were silently broken before the fix.

- **`/skill audit --all` external listing** (Phase E + verification T21). Spec.md scenario originally said audit should list CC-marketplace skills as `[external]`. Implementation diverged: audit operates on `.claude/skills/*/SKILL.md` only — external skills have no on-disk SKILL.md so they can't be inspected. The non-goal already said "may list" (not must), and the resolved-Open-Question #3 made the divergence explicit. Updated spec.md scenario + Open Questions accordingly.

- **CC harness picked up the meta-skill at write time** (Phase E). After writing `.claude/skills/skill/SKILL.md`, the next session-loaded `system-reminder` listed `skill` in the available-skills set with its description — confirms CC reads SKILL.md frontmatter live and that the meta-skill description shape works.

- **Body byte-identity verification template** for the porter went through a self-bug too — my first smoke-test extracted body using awk with an off-by-one count, returned the whole new file, and reported a (spurious) diff. Re-extracted with the same awk pattern as the porter itself uses; verified identity. Worth keeping the `tail -n +$((CLOSE+1))` idiom canonical across this toolkit.

- **Defer-to-canonical not runtime-tested.** `skills-ref` (Python validator) is not installed in this dev environment, so the `exec skills-ref validate ...` branch was only inspected, not executed. If a future Agent0 contributor installs `skills-ref` (`pip install -e skills-ref` from the agentskills repo), running `/skill validate skill` once will exercise that branch and confirm pass-through behavior. Worth a one-line REMINDERS.md item.

- **What's NOT in this spec** (handed off to future work):
  - `PreToolUse(Skill)` hook to auto-block invalid skills at invocation (deferred per plan.md "Alternatives considered")
  - Body rewriting for portability (e.g. turning `${CLAUDE_SKILL_DIR}` into a runtime-agnostic indirection) — separate spec if/when a real consumer demands it
  - Cross-runtime conformance testing (running ported skills under Hermes/Codex/Cursor and confirming behavior) — belongs to REMINDERS.md item #2 (publish `mcp-product-pipeline`)
  - Skill marketplace publishing (hermeshub / skilldock.io / agentskills.so) — downstream of compliance; this spec ends at "skill is compliant"
