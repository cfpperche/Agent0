# 018 — githooks-activation-hint — tasks

_Generated from `plan.md` on 2026-05-11. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Phase 0 — scaffolding

- [x] 1. Create `.claude/tests/githooks-activation/` directory with a one-line `README.md` describing the scenario-to-script numbering convention (mirror `.claude/tests/runtime-introspect/` shape).

### Phase 1 — RED tests (failing)

Each script builds a tmp-dir fixture (mock project with/without `.githooks/`, with/without `git config core.hooksPath`), invokes `session-start.sh`, asserts stdout. All must fail until Phase 2 lands.

- [x] 2. Write `.claude/tests/githooks-activation/01-advisory-fires-when-inactive.sh` — fixture: tmp git repo with `.githooks/pre-commit`, `core.hooksPath` NOT set. Assert hook stdout contains `=== githooks-activation ===` and the literal command `git config core.hooksPath .githooks`.
- [x] 3. Write `.claude/tests/githooks-activation/02-silent-when-activated.sh` — fixture: same as 01 but with `git config core.hooksPath .githooks` already run. Assert hook stdout does NOT contain `githooks-activation`.
- [x] 4. Write `.claude/tests/githooks-activation/03-silent-when-no-githooks-dir.sh` — fixture: tmp git repo with NO `.githooks/` directory. Assert hook stdout does NOT contain `githooks-activation`.
- [x] 5. Write `.claude/tests/githooks-activation/04-skip-env-var.sh` — fixture: tmp git repo with `.githooks/pre-commit`, config NOT set, but `CLAUDE_SKIP_GITHOOKS_HINT=1` exported. Assert hook stdout does NOT contain `githooks-activation`.
- [x] 6. Write `.claude/tests/githooks-activation/run-all.sh` — driver mirroring `.claude/tests/harness-sync/run-all.sh` shape: loops `01-*.sh` through `04-*.sh`, reports pass/fail per scenario, exits non-zero if any failed.
- [x] 7. Run `bash .claude/tests/githooks-activation/run-all.sh` — verify all 4 scenarios FAIL (RED state confirmed). Some may "accidentally" pass (tests 03 + 04 may pass because the hook currently emits nothing githooks-related — acceptable, they'll continue to pass post-impl).

### Phase 2 — GREEN implementation

- [x] 8. Modify `.claude/hooks/session-start.sh` — append the githooks-activation block after the runtime-introspect block (around line 60). Block shape:
  ```bash
  # githooks-activation (spec 018): surface the manual core.hooksPath
  # activation command when .githooks/ is present but config doesn't point
  # at it. Lazarus reasoning per .claude/rules/secrets-scan.md § Gotchas.
  if [[ -d "$PROJECT_DIR/.githooks" && "${CLAUDE_SKIP_GITHOOKS_HINT:-0}" != "1" ]]; then
    current_hookspath="$(git -C "$PROJECT_DIR" config --get core.hooksPath 2>/dev/null || true)"
    if [[ "$current_hookspath" != ".githooks" ]]; then
      printf '\n=== githooks-activation ===\n'
      printf 'Native git hooks NOT activated (gitleaks pre-commit inert).\n'
      printf 'Run once: git config core.hooksPath .githooks\n'
      printf '=== end githooks-activation ===\n'
    fi
  fi
  ```
- [x] 9. Re-run `bash .claude/tests/githooks-activation/run-all.sh` — all 4 scenarios must now PASS.

### Phase 3 — documentation

- [x] 10. Modify `.claude/rules/secrets-scan.md` § Gotchas — extend the existing "core.hooksPath activation is MANUAL by design" gotcha with a closing sentence: "A SessionStart hint (spec 018) emits the activation command when `.githooks/` is present but `core.hooksPath` is not set — see `.claude/hooks/session-start.sh` § githooks-activation. `CLAUDE_SKIP_GITHOOKS_HINT=1` suppresses it."

### Phase 4 — propagate to forks

Spec 016 (harness-sync) is the propagation channel. The sync tool will detect drift in `.claude/hooks/session-start.sh` (changed in Agent0 since each shrnk's last sync) and update on apply.

- [x] 11. Activate `core.hooksPath` in Agent0 itself: `git -C /home/goat/Agent0 config core.hooksPath .githooks`. The hint should now stay silent on Agent0's next session start (self-verification).
- [x] 12. From Agent0 root, dry-run sync each shrnk: `bash .claude/tools/sync-harness.sh --apply --dry-run --agent0-path=/home/goat/Agent0 /home/goat/<fork>` for each of pyshrnk, shrnk, rshrnk. Expected: 1 `! overwritten` (session-start.sh) — drift-only update. The `.gitignore` will still show as customized (real customization preserved).
- [x] 13. Apply sync to each shrnk with `--force --force-except='.gitignore'`. Commit per fork: `chore(harness-sync): adopt Agent0 spec 018 (githooks-activation hint)`.

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria._

- [x] **Scenario 1 — advisory fires when inactive** — `01-*.sh` PASS; manual: starting a fresh session in pyshrnk (post-sync, before `git config core.hooksPath .githooks`) shows the `=== githooks-activation ===` block in additional-context.
- [x] **Scenario 2 — silent when activated** — `02-*.sh` PASS; manual: after running `git config core.hooksPath .githooks` in pyshrnk, restarting the session shows NO block.
- [x] **Scenario 3 — silent when no githooks dir** — `03-*.sh` PASS; manual: session start in a non-Agent0 project (no `.githooks/`) shows NO block.
- [x] **Scenario 4 — opt-out via env var** — `04-*.sh` PASS; manual: `CLAUDE_SKIP_GITHOOKS_HINT=1 claude` in a fork with inactive hooks shows NO block.
- [x] **Static checks** — `.claude/hooks/session-start.sh` contains a `githooks-activation` block; `.claude/rules/secrets-scan.md` § Gotchas references the SessionStart hint; all 4 test scripts exist under `.claude/tests/githooks-activation/`.
- [x] **Full driver green** — `bash .claude/tests/githooks-activation/run-all.sh` exits 0.
- [x] **Synced to all 3 shrnks** — commit landed in each of pyshrnk / shrnk / rshrnk with the activation hint live; `bash .claude/tools/sync-harness.sh --check --agent0-path=/home/goat/Agent0 <fork>` exits 0 (no drift).

## Notes

- This spec is a follow-on signal that closes the discoverability gap left by spec 007. The Lazarus-vector reasoning is intact (no auto-activation), but the manual step is now passively surfaced.
- After spec 018 ships and propagates, every new fork sync will trigger the advisory on its next session start — by design. The advisory is one block of ~4 lines, smaller than SESSION.md.
- If real complaints about advisory noise surface, v2 candidates: (a) suppress after N consecutive sessions where it fired; (b) only emit when stdin source = `startup` (not `resume`/`compact`/`clear`). Defer until evidence.
