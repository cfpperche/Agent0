# 069 — product-overwrite-git-safety

_Created 2026-05-21._

**Status:** shipped

## Intent

`/product`'s Phase 0 overwrite path destroys data it has no business touching. When `--out` points at a directory that already holds non-harness artifacts, the skill prompts `Overwrite? (y/N)` and, on `y`, runs `rm -r <out>` — a blunt delete of the *entire* target. The detection that decides whether to prompt is harness-aware (spec 059): it computes `<remaining>` by subtracting a 7-path allowlist — `.claude/`, `.githooks/`, `.gitignore`, `.gitleaks.toml`, `.mcp.json.example`, `CLAUDE.md`, and `.git/` — from the target's contents. But the deletion that follows ignores that allowlist entirely. The result is an inconsistency with a sharp edge: `/product --out=<an existing git repo>` answered `y` deletes `.git/`, and with it all version history and any local-only commits. SKILL.md line 49 acknowledges the harness loss ("founder re-syncs via sync-harness.sh after") — but a wiped `.git/` cannot be re-synced; it is unrecoverable. This was flagged as "Gap F" in spec 068's non-goals and deferred. The mei-saas catch-up (2026-05-21) made it concrete: running `/product` against the freshly-committed mei-saas repo to regenerate its foundation would `rm -r` the very checkpoint commit created to make the rewrite reversible. This spec makes the overwrite deletion honor the same allowlist the detection already uses — overwrite removes `<remaining>` and nothing else.

## Acceptance criteria

- [x] **Scenario: overwrite preserves `.git/`**
  - **Given** `<out>` is an existing git repository that also holds prior `/product` artifacts
  - **When** the operator runs `/product` (no `--from-step`) and confirms `y` at the overwrite prompt
  - **Then** `<out>/.git/` is untouched — history and local commits survive — while the prior `/product` artifacts are removed and the run proceeds to Init

- [x] **Scenario: overwrite preserves the Agent0 harness**
  - **Given** `<out>` holds harness-allowlist files (`.claude/`, `CLAUDE.md`, `.gitleaks.toml`, etc.) alongside prior `/product` artifacts
  - **When** the operator confirms `y` at the overwrite prompt
  - **Then** every harness-allowlist path survives the overwrite — no post-overwrite `sync-harness` re-bootstrap is needed

- [x] **Scenario: a non-harness artifact is still cleared**
  - **Given** `<out>` holds a prior `docs/` tree, `app/`, `.state.json`, and other non-allowlist artifacts
  - **When** the operator confirms `y` at the overwrite prompt
  - **Then** every path in `<remaining>` (the non-allowlist set) is removed, so Init starts from a clean docs tree

- [x] **Scenario: detection and decline paths are unchanged**
  - **Given** `<out>` is empty, harness-only, or the operator answers `n`
  - **When** `/product` runs Phase 0
  - **Then** behavior is identical to today — empty/harness-only proceeds with no prompt and no delete; `n` aborts cleanly with exit 0

- [x] SKILL.md Phase 0 step 1 no longer instructs `rm -r <out>`; the deletion is scoped to the `<remaining>` set, and the stale parenthetical claiming the overwrite "WILL also remove any harness present" is corrected.

## Non-goals

- **The `--from-step` resume path.** State-version validation (the v2/v3/v4 abort messages) is untouched — this spec changes only the no-`--from-step` overwrite branch.
- **The allowlist contents.** The 7-path set is not changed; this spec makes the *deletion* use the set the *detection* already uses. The SKILL.md ↔ `sync-harness.sh` allowlist duplication (flagged in SKILL.md line 51) is a separate concern.
- **A "wipe everything including `.git`" mode.** If an operator genuinely wants a bare-slate target, they `rm` it themselves before invoking `/product`. The skill never destroys `.git/`.
- **Other skills / `sync-harness.sh`.** Scope is `/product`'s Phase 0 only.

## Open questions

- [x] Q1 — After a selective overwrite of a git repo, the removed paths show as deletions in `git status`. Is that the intended end state (operator reviews the diff — same posture as every other fork-mutating Agent0 primitive), or should the skill say anything about it? _Lean: intended, no extra handling — resolve in plan._
- [x] Q2 — Should the fix stay prose-in-SKILL.md, or extract the Phase 0 overwrite into a script that can be regression-tested? _Resolve in plan, weighing effort against the testability gain — `/product` currently has no Phase 0 test._

## Context / references

- `.claude/skills/product/SKILL.md` Phase 0 step 1 (the overwrite logic) and the harness allowlist (lines ~37-51) — the locus of the fix.
- `docs/specs/068-harness-sync-baseline-reconciliation/spec.md` § Non-goals — where "Gap F" was named and deferred.
- `docs/specs/059-*` — introduced the harness-aware idempotency check / allowlist that this spec extends to the deletion side.
- Session 2026-05-21 — mei-saas catch-up; the empirical trigger (running `/product` against the committed mei-saas repo would `rm -r` checkpoint commit `a2c8ec2`).
