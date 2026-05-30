# 120 — vuln-audit — tasks

_Generated from `plan.md` on 2026-05-30. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. Create `.agent0/tests/vuln-audit/` with a shared `_lib.sh` helper that puts a canned `osv-scanner` stub on a temp PATH (configurable: exit code + JSON fixture), mirroring the `secrets-scan/` fake-command pattern.
- [x] 2. Write the 10 numbered test scenarios (`01`–`10`) per `plan.md` § Files.
- [x] 3. Write `run-all.sh` that executes `01`–`10` and reports pass/fail counts.
- [x] 4. Implement `.agent0/tools/vuln-audit.sh`: arg parsing (`[path]`, `--json`, `--exit-code`, `--severity`), engine-absent → `unavailable` advisory, `jq`-absent fail-open.
- [x] 5. Implement the thin lockfile→ecosystem map + tree walk → `found` bucket; cross-reference osv-scanner `results[].source.path` → `covered`; remainder → `skipped/unsupported` with reason (bun.lockb → migrate hint).
- [x] 6. Implement osv-scanner invocation + defensive `jq` parse → findings (package, version, id+CVE alias, severity from CVSS/database_specific, fixed version, direct|transitive, path) + result-status derivation from exit code (0→clean, 1→findings, 128→clean-no-pkgs, other→failed).
- [x] 7. Implement renderers: human-readable default + `--json` deterministic doc; apply `--severity` floor + `--exit-code` mapping.
- [x] 8. Run `bash .agent0/tests/vuln-audit/run-all.sh` → all green (48 asserts, 10 scenarios).
- [x] 9. Write `.claude/skills/vuln-audit/SKILL.md` (thin, tier `cc-native`) and validate (`validate.sh` exit 0).
- [x] 10. Write `.claude/rules/vuln-audit.md` (trigger surface, engine choice + why, status/`--exit-code` semantics, `--json` posture, no-override rationale, non-goals).
- [x] 11. Add the `## Vuln audit` section to `CLAUDE.md` (inside `AGENT0:BEGIN/END`) and mirror in `AGENTS.md`; added a row to `.claude/rules/runtime-capabilities.md`.
- [x] 12. Confirmed sync-harness manifest globs cover the 4 new paths (`.claude/skills` + `.agent0/tests` recursive; `.claude/rules|*.md` + `.agent0/tools|*.sh` globs). No upstream baseline file exists (written into consumers at sync time) — no edit needed.

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria._

- [x] All 10 scenarios in `.agent0/tests/vuln-audit/run-all.sh` pass (covers: findings/clean/unavailable/failed status, three-bucket coverage, bun.lockb skipped, `--json` shape, `--exit-code`, transitive path, severity floor).
- [x] `bash .agent0/tools/vuln-audit.sh --help` and a default run on this repo behave sanely (no real osv-scanner → `unavailable` advisory, exit 0; correctly discovered `site/bun.lock` etc.).
- [x] No new hook registration in `.claude/settings.json` (on-demand only — zero `vuln-audit` entries on any `PreToolUse`/pre-commit path).
- [x] Skill frontmatter passes the agentskills validator (`validate.sh` exit 0).

## Notes

_Post-merge reminder: run the tool once against a real project with the real `osv-scanner` binary (network-bound) to confirm the JSON parse matches live output — the 10 CI scenarios use a deterministic offline stub. A `/remind` entry should carry this forward._
