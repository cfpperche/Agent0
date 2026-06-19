# 208 — unused-code-audit — tasks

_Generated from `plan.md` on 2026-06-18. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

**Verify:** `bash docs/specs/208-unused-code-audit/verify.sh`

## Implementation

### Engine (the substance — build + prove first)

- [x] 1. Resolve the one remaining mechanism fork before writing code: `unconfigured` strictness — hard-stop vs defaults-with-banner. (Sync-propagation question already resolved 2026-06-18 — see notes.md / plan.md.) Record the ruling in `notes.md`. **(Maintainer pause.)**
- [x] 2. Confirm knip's real JSON output shape + config surfaces against the locally-installed/`npx` knip version; record the documented top-level keys the parser will depend on in `notes.md` (defensive-parse contract).
- [x] 3. Create three throwaway JS/TS fixtures under a gitignored temp area (NOT committed): `clean` (knip config + no unused), `findings` (unused export/file/dep), `unconfigured` (knip resolvable, no config). Wire them into `docs/specs/208-unused-code-audit/verify.sh` so the acceptance run is mechanical and repeatable.
- [x] 4. Write `.agent0/tools/unused-code.sh` skeleton: arg parse (`[path] [--json] [--exit-code]`, no `--severity`), `-h/--help` from header block, `jq`-absent fail-open, status-machine scaffold. Mirror `.agent0/tools/vuln-audit.sh` structure.
- [x] 5. Implement stack detection: JS/TS markers (`package.json` + bun/pnpm/npm lockfiles) → pick runner; no JS/TS markers → emit `no-stack` clean no-op (exit 0). Test against a non-JS dir.
- [x] 6. Implement engine resolution + `unavailable`: gate on local `node_modules/.bin/knip` first, then `npx knip --version` (never trigger a network install); absent → status `unavailable` + install hint, exit 0.
- [x] 7. Implement config detection + `unconfigured`: probe knip config surfaces (`knip.{json,jsonc,ts,js}`, `.knip.*`, `package.json#knip`); per task-1 ruling, hard-stop at `unconfigured` (or defaults-with-banner) + config pointer.
- [x] 8. Implement the run path: `<runner> knip --reporter json`, defensive `jq` parse → `clean` (empty) / `findings` (≥1, classified by kind: unused file / export / dependency / unreferenced member) / `failed` (error or unparseable, with reason — never crash).
- [x] 9. Implement output: human-readable default (status line + per-finding `[kind] path — candidate unused`, never "delete this") and `--json` structured doc with the shape-only disclaimer; `--exit-code` maps statuses for consumer CI only (default exit 0 for all).
- [x] 10. Run `bash -n` + the three fixtures + no-stack + unavailable via `verify.sh`; all green.

### Codex review gate (engine)

- [x] 11. Send `.agent0/tools/unused-code.sh` to codex for read-only review (`.agent0/skills/codex-exec/scripts/codex-exec.sh`, high effort); fold findings; report verdict to maintainer. **(Pause before skill/rule.)**

### Wrappers + index

- [x] 12. Write `.claude/skills/unused-code/SKILL.md` — thin wrapper modeled on `vuln-audit/SKILL.md` (frontmatter shape, `argument-hint`, `agentskills-portable` tier, points at the rule). Validate with `/skill validate unused-code`.
- [x] 13. Write `.agent0/context/rules/unused-code-audit.md` — canonical contract (on-demand posture, JS-knip-only + per-stack deferral, `unconfigured` caveat, status/exit-code model, report-never-delete + no-override-marker, `validator.json` custom-command hybrid, `/routine` recipe, finding-taxonomy/public-API-boundary/engine-native-suppression notes, non-goals) with `paths:` frontmatter trigger.
- [x] 14. Add the `## Unused-code audit` entry to the `CLAUDE.md` managed block (one paragraph, shape of `## Vuln audit`), pointing at the rule.
- [x] 15. Confirm the three shipped files are git-tracked so existing `sync-harness.sh` globs (`.agent0/tools|*.sh`, `.agent0/context/**`, `.claude/skills/**`) propagate them — NO baseline/manifest edit (resolved 2026-06-18; baseline is a per-consumer computed artifact, not a source-repo file). `git add` the new files.

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria._

- [x] 16. `verify.sh` green: `clean`/`findings`/`unconfigured` fixtures + `no-stack` no-op + `unavailable` hint all produce the spec'd status and exit 0 (maps spec scenarios 1–5).
- [x] 17. Manual check: a `.agent0/validator.json` with `{ "name": "deadcode", "run": "npx knip" }` is executed by `run.sh` with no new first-class category added (spec scenario 6).
- [x] 18. `/skill validate unused-code` passes; rule doc + CLAUDE.md entry present; `bash .agent0/tools/doctor.sh` clean (spec static-fact criteria).
- [x] 19. Codex reviews the full final diff; fold; report verdict. Then fill `**Closure:**` in `spec.md` and check all spec/tasks boxes. **(Pause for maintainer OK before commit.)**

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._
