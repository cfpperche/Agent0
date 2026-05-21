# 069 — product-overwrite-git-safety — tasks

_Generated from `plan.md` on 2026-05-21. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. **Recon.** Confirm the exact text of SKILL.md Phase 0 step 1 (the `<remaining>` computation, the overwrite prompt, the `rm -r <out>` instruction, the parenthetical, the line-51 drift note). List `.claude/skills/product/scripts/` to match the existing script conventions. Re-confirm the `.claude/tests/harness-sync/` test shape (`mktemp -d` fixture, `trap` cleanup, `echo "PASS: …"`, `run-all.sh` loop) as the template for the new test dir.
- [x] 2. **Write `clear-target.sh`.** Create `.claude/skills/product/scripts/clear-target.sh`: arg `<out>` (absolute path); refuse with non-zero exit if missing / not a directory. Hold the 7-path harness allowlist as a constant with a drift-warning comment naming SKILL.md as canonical. Enumerate every top-level entry of `<out>` *including dotfiles*; for each not in the allowlist, `rm -r` it (never `rm -rf`) and print `removed <path>`. Unconditionally skip any entry whose basename is `.git` or `.claude` regardless of the allowlist (defense in depth). Exit 0 on success.
- [x] 3. **Regression tests.** Create `.claude/tests/product-overwrite/` with self-contained tests (mirror `.claude/tests/harness-sync/` shape) — one per `spec.md` scenario: `.git/` preserved, harness allowlist preserved, `<remaining>` cleared, empty/harness-only target is a no-op, a root dotfile in `<remaining>` is cleared. Add a `run-all.sh` orchestrator + `README.md`.
- [x] 4. **Run the suite.** Run `.claude/tests/product-overwrite/run-all.sh` — all tests pass. `bash -n` the script.
- [x] 5. **Rewire SKILL.md Phase 0 step 1.** Replace the `On y → rm -r <out>` instruction with `On y → bash .claude/skills/product/scripts/clear-target.sh <out>`. Correct the stale parenthetical ("WILL also remove any harness present — founder re-syncs… after") to state `.git/` and the harness are preserved. Update the `Overwrite? (y/N)` prompt message so the operator knows non-harness artifacts are cleared while `.git/` + harness survive.

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria._

- [x] Run `.claude/tests/product-overwrite/run-all.sh` — every test passes (covers: `.git/` preserved, harness preserved, `<remaining>` cleared, empty/harness-only no-op, dotfile cleared).
- [x] Empirical: on a throwaway `mktemp -d` fixture seeded with `.git/` + `.claude/` + `docs/` + `app/`, run `clear-target.sh` and confirm `.git/` and the harness survive while `docs/`/`app/` are gone.
- [x] SKILL.md Phase 0 step 1 contains no `rm -r <out>` instruction; the parenthetical no longer claims the overwrite removes the harness; the prompt message reflects the new behavior.
- [x] `bash -n .claude/skills/product/scripts/clear-target.sh` is clean; the script is executable.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._

- All 5 implementation tasks + 4 verification checks complete. `clear-target.sh` written + 5 regression tests (24-style `mktemp -d` fixtures) — all pass; empirical run confirmed `.git/` + harness survive while `docs/`/`app/` clear. SKILL.md Phase 0 step 1 rewired; no `rm -r <out>` remains.
- One in-flight decision recorded in `notes.md` (glob-based `run-all.sh`).
- Allowlist is now triplicated (SKILL.md / sync-harness.sh / clear-target.sh) — drift caveat documented in all three; single-sourcing is a separate spec.
