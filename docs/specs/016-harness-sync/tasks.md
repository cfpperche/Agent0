# 016 — harness-sync — tasks

_Generated from `plan.md` on 2026-05-11. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Phase 0 — scaffolding

- [x] 1. Create `.claude/tests/harness-sync/` directory and write a one-line `README.md` inside describing the scenario-to-script numbering convention (mirror `.claude/tests/runtime-introspect/README.md` shape if it exists, else inline the convention).
- [x] 2. Create empty stub `.claude/tools/sync-harness.sh` with shebang `#!/usr/bin/env bash`, `set -euo pipefail`, a `usage()` function emitting the canonical CLI, and `chmod +x`. No real logic yet — this exists so the RED tests can invoke it and fail with usage-mismatch errors rather than file-not-found.

### Phase 1 — RED tests (failing)

Each script writes a tmp-dir fixture (mock Agent0 source + mock fork target), invokes `sync-harness.sh`, asserts expected stdout/stderr/exit, and cleans up. All must fail at this phase.

- [x] 3. Write `.claude/tests/harness-sync/01-check-mode-lists-drift.sh` — fixture: fork missing 2 hooks + 1 rule doc. Assert `--check` lists each missing file with `+ would copy` or similar marker, exit code 1.
- [x] 4. Write `.claude/tests/harness-sync/02-apply-copies-missing.sh` — fixture: same as 01. Assert `--apply` copies each missing file with `+ copied <path>` line, fork ends up with all files, re-running `--check` exits 0.
- [x] 5. Write `.claude/tests/harness-sync/03-apply-refuses-customized.sh` — fixture: fork has `.claude/hooks/secrets-scan.sh` with a hash-mismatch ediff. Assert `--apply` emits `!! customized: <path>` on stderr, leaves the file untouched, exits non-zero. Other un-customized files in the same run still copy successfully.
- [x] 6. Write `.claude/tests/harness-sync/04-force-overrides.sh` — fixture: same as 03. Assert `--apply --force` overwrites the file (hash now matches Agent0), emits `! overwritten: <path>` warning, exit 0.
- [x] 7. Write `.claude/tests/harness-sync/05-settings-merge-additive.sh` — fixture: fork's `.claude/settings.json` registers only 3 hook entries (governance / delegation / secrets-scan); Agent0's has the current 6+. Assert `--apply` ends with all Agent0 entries present in fork (dedup-by-matcher+command), fork's pre-existing entries preserved, no duplicates.
- [x] 8. Write `.claude/tests/harness-sync/06-claude-md-section-append.sh` — fixture: fork's `CLAUDE.md` has only Overview / Stack / Spec-driven development / Delegation / Compact Instructions; missing Supply chain / Runtime introspect / MCP recipes / Harness sync. Assert `--apply` appends the missing sections immediately before `## Compact Instructions`, fork-authored sections preserved verbatim.
- [x] 9. Write `.claude/tests/harness-sync/07-dry-run-no-writes.sh` — fixture: fork with drift. Assert `--apply --dry-run` emits the same per-file decision lines as a real apply, but `find <fork-path> -newer <pre-run-marker>` returns zero files. Exit 0.
- [x] 10. Write `.claude/tests/harness-sync/08-out-of-scope-untouched.sh` — fixture: fork has `src/main.ts`, `tests/integration.test.ts`, `docs/README.md`, `package.json`, `.mcp.json` all with marker content. Assert `--apply` leaves all of them byte-identical (`sha256sum` before vs after).
- [x] 11. Write `.claude/tests/harness-sync/09-idempotent-apply.sh` — fixture: fork at full drift. Run `--apply` twice; assert second run emits only `= up to date` lines (no `+ copied`, no `~ merged`), zero file modifications between runs (sha256sum stable).
- [x] 12. Write `.claude/tests/harness-sync/10-agent0-path-explicit.sh` — fixture: invoke from a tmp dir that is NOT Agent0 and has no `AGENT0_HARNESS_PATH` set. Assert `--apply ~/some-fork` (no `--agent0-path`) exits 2 with usage hint on stderr mentioning both `--agent0-path` and `AGENT0_HARNESS_PATH`.
- [x] 13. Write `.claude/tests/harness-sync/11-mcp-json-untouched.sh` — fixture: fork has populated `.mcp.json` with secret-adjacent content (mock `DATABASE_URL` line); no `.mcp.json.example`. Assert `--apply` copies `.mcp.json.example` from Agent0, leaves `.mcp.json` byte-identical.
- [x] 14. Write `.claude/tests/harness-sync/run-all.sh` — driver: loops `01-*.sh` through `11-*.sh`, runs each, reports pass/fail per scenario, exits non-zero if any failed.
- [x] 15. Run `bash .claude/tests/harness-sync/run-all.sh` — verify all 11 scenarios fail (RED state confirmed). Test 10 passes coincidentally because the stub's exit-2-with-usage satisfies scenario 10 (acceptable — it'll continue to pass post-impl).

### Phase 2 — GREEN implementation

Implement `sync-harness.sh` incrementally; re-run the test driver after each section to watch scenarios flip RED → GREEN.

- [x] 16. Implement `usage()` + `arg_parse()` in `sync-harness.sh`: parse `--check` (default) / `--apply` / `--dry-run` / `--force` / `--agent0-path=PATH` (or `=` form) / positional fork-path. Refuse unknown flags. Refuse missing `--agent0-path` AND missing `AGENT0_HARNESS_PATH` env. This unblocks scenario 10.
- [x] 17. Implement `resolve_paths()` — validate `--agent0-path` points at a real Agent0 repo (sanity check: `.claude/` exists + `CLAUDE.md` at root — loosened from `.claude/hooks/` to fit minimal mock fixtures), validate fork-path exists. Set globals `AGENT0_ROOT` and `FORK_ROOT`.
- [x] 18. Implement the **manifest constants** at top of script: 4 arrays — `COPY_CHECK_RECURSIVE` (find -type f under: `.claude/skills`, `.claude/tests`, `.claude/agents`), `COPY_CHECK_GLOBS` (dir|pattern pairs: `.claude/hooks|*.sh`, `.claude/rules|*.md`, `.claude/tools|*.sh`, `.claude/validators|*.sh`), `COPY_CHECK_FILES` (`.mcp.json.example`, `.gitleaks.toml`, `.githooks/pre-commit`, `.gitignore`). Denylist is implicit — the walk only reads from Agent0 manifest paths, so out-of-scope fork content is never visible.
- [x] 19. Implement `walk_copy_check()` + `process_file()` — for each entry in the COPY_CHECK manifest, enumerate via `find`, compare hashes, emit decision line, perform action under `--apply`. Handles `+ copied` / `+ would copy` / `= up to date` / `!! customized` / `! overwritten`. Mode-preserve via `cp -p`. This unblocks scenarios 1, 2, 3, 4, 7, 9, 11.
- [x] 20. Implement `merge_settings_json()` — jq with `-s` to combine fork + Agent0, dedup_key function on `(matcher, hooks[].command)` tuple, write atomically (`mktemp + mv`). Compare merged result to existing fork content — if same, skip; if differs, write. This unblocks scenario 5.
- [x] 21. Implement `merge_claude_md()` — extract `^## ` headings from both, compute missing-in-fork via `comm -23`, locate `## Compact Instructions` line in fork, insert missing sections (full content extracted from Agent0 via awk) before that line. EOF fallback when anchor missing emits `!! claude-md: missing "## Compact Instructions" anchor — appending at EOF` warning. **Plan divergence: when no missing headings, treat as up-to-date regardless of body hash — fork-authored sections intentionally diverge.** This unblocks scenario 6.
- [x] 22. Implement summary stderr line: `synced: <N> copied, <M> merged, <K> up-to-date, <C> customized-refused, <O> overwritten`. Exit code policy: check+drift=1, apply+customized-refused=1, else 0.
- [x] 23. Re-run `bash .claude/tests/harness-sync/run-all.sh` — all 11 scenarios PASS. Single plan divergence captured in plan.md (CLAUDE.md heading-set comparison, not full-file hash).

### Phase 3 — documentation

- [x] 24. Write `.claude/rules/harness-sync.md` — operational reference. Sections (mirror `runtime-introspect.md` shape): What fires / Modes / Customization-detection algorithm / settings.json merge strategy / CLAUDE.md merge strategy / Manifest scope / Escape hatches (`--force`, `AGENT0_HARNESS_PATH`) / Audit (git diff, not JSONL) / Gotchas (Compact Instructions anchor missing, whitespace false-positive, settings.json growth, fork-only test survival, manual `core.hooksPath` activation).
- [x] 25. Modify `CLAUDE.md` — insert `## Harness sync` capacity block immediately before `## Compact Instructions`. Block content: 5-8 lines summarising the tool + flag matrix + link to `.claude/rules/harness-sync.md`. Mirror the `## MCP recipes` and `## Runtime introspect` block shape.

### Phase 4 — live verification on real shrnks

- [x] 26. Dry-run sync against pyshrnk: 64 copied, 2 merged, 4 customized-refused (`session-start.sh`, `secrets-scan.md`, `validators/run.sh`, `.gitignore`). First 3 are drift-only; `.gitignore` has real fork-specific stack patterns.
- [x] 27. Dry-run sync against shrnk: 64 copied, 2 merged, 3 customized-refused (drops `session-start.sh` — shrnk has the current version; same other 3).
- [x] 28. Dry-run sync against rshrnk: 64 copied, 2 merged, 3 customized-refused (drops `secrets-scan.md` — rshrnk has the current version; same `validators/run.sh` + `.gitignore`).

**Scope expansion (post-dry-run):** Findings drove adding `--force-except=GLOB` flag so forks can adopt drift-only updates while preserving real customizations (canonical case: `.gitignore`). Implemented + tested as scenario 12.

- [x] 29. Applied to pyshrnk: `92c7013` — 65 copied, 2 merged, 3 overwritten (drift), 1 customized-refused (.gitignore).
- [x] 30. Applied to shrnk: `c10927a` — same shape.
- [x] 31. Applied to rshrnk: `a1a14e8` — 65 copied, 2 merged, 2 overwritten (rshrnk had current secrets-scan.md), 1 customized-refused.
- [x] 32. Hand-merged each fork's `.gitignore` in the SAME commit as the sync (not a separate commit — simpler review trail). Preserved Python lines in pyshrnk, `node_modules/` in shrnk, `target/` in rshrnk; corrected pre-existing path bug `tests/secrets-scan/.tmp/` → `.claude/tests/secrets-scan/.tmp/` in shrnk.

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria. Each one should map to a checklist item there._

- [x] **Scenario 1 — check mode lists drift** — `01-*.sh` PASS.
- [x] **Scenario 2 — apply copies missing** — `02-*.sh` PASS.
- [x] **Scenario 3 — refuses customized** — `03-*.sh` PASS.
- [x] **Scenario 4 — `--force` overrides** — `04-*.sh` PASS.
- [x] **Scenario 5 — settings.json merge additive** — `05-*.sh` PASS.
- [x] **Scenario 6 — CLAUDE.md section append** — `06-*.sh` PASS.
- [x] **Scenario 7 — dry-run no writes** — `07-*.sh` PASS.
- [x] **Scenario 8 — out-of-scope untouched** — `08-*.sh` PASS.
- [x] **Scenario 9 — idempotent apply** — `09-*.sh` PASS.
- [x] **Scenario 10 — explicit `--agent0-path`** — `10-*.sh` PASS.
- [x] **Scenario 11 — `.mcp.json.example` synced, `.mcp.json` never touched** — `11-*.sh` PASS.
- [x] **Scenario 12 — `--force-except=GLOB` preserves matching files** — `12-*.sh` PASS (added post-Phase-4 dry-run discovery).
- [x] **Static checks** — `.claude/tools/sync-harness.sh` exists + executable; `.claude/rules/harness-sync.md` exists; `CLAUDE.md` has `## Harness sync` before `## Compact Instructions`; all 12 test scripts exist.
- [x] **Full driver green** — `bash .claude/tests/harness-sync/run-all.sh` exits 0 (12/12 PASS).
- [x] **All three shrnks synced + committed** — pyshrnk `92c7013`, shrnk `c10927a`, rshrnk `a1a14e8`. `--check` exits 0 for each (0 drift).

## Notes

- The sync tool inverts the failure mode of every other Agent0 capacity: most hooks fail open (broken validator → no block) to avoid locking the agent out; sync-harness fails closed (broken hash compare → refuse apply) because the cost of overwriting a fork customization silently is higher than the cost of refusing a sync.
- Phase 4 (live verification on real shrnks) is where any test-fixture vs reality gap surfaces. Expect at least one dry-run finding that feeds back as a manifest tweak or denylist addition. Update `plan.md` if it does.
- After all three shrnks are synced and committed, dogfood B1 (pyshrnk) per its `docs/dogfood-plan.md` becomes executable for the first time — spec 011 probe + spec 012 hint will actually exist in pyshrnk.
- Consider documenting in `harness-sync.md`'s Gotchas: "First sync of a long-stale fork can produce a large diff — review section-by-section in the fork, not as one giant blob".
