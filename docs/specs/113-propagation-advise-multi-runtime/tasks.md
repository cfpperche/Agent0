# 113 — propagation-advise-multi-runtime — tasks

_Generated from `plan.md` on 2026-05-29. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### A. Move + rewrite the hook
- [x] 1. `git mv .claude/hooks/propagation-advise.sh .agent0/hooks/propagation-advise.sh`.
- [x] 2. Rewrite the hook: source `_memory-hook-lib.sh`; use `memory_project_dir` for PROJECT_DIR; branch on `memory_runtime`. Build common `(relpath, content)` pairs:
  - Claude `Edit|Write|MultiEdit` → existing per-tool content extraction.
  - Codex `apply_patch` → parse `memory_patch_body` into per-file sections (`*** (Add|Update|Delete|Move) File:`), content = that section's `^+` added lines (prefix stripped).
- [x] 3. Feed each pair through the SHARED scan: shipped-surface scoping + within-surface exclusions (self-path updated to `.agent0/hooks/propagation-advise.sh`) + override marker + 5 `scan_pattern` calls + `head -5` cap. Keep `CLAUDE_SKIP_PROPAGATION_ADVISE=1` and exit 0.
- [x] 4. `chmod +x` the moved hook (git mv preserves mode, verify).

### B. Registration + sync
- [x] 5. `.claude/settings.json` — update the PostToolUse command path to `.agent0/hooks/propagation-advise.sh`; `jq` parses.
- [x] 6. `.agent0/tools/sync-harness.sh` — `COPY_CHECK_EXCLUDE`: change `.claude/hooks/propagation-advise.sh` → `.agent0/hooks/propagation-advise.sh`. Confirm the `merge_settings_json` basename filter (`contains("propagation-advise.sh")`) still matches.

### C. Tests
- [x] 7. Update `HOOK=` path in all 11 `.claude/tests/propagation-advisory/NN-*.sh` to `.agent0/hooks/propagation-advise.sh`.
- [x] 8. Add `12-codex-apply-patch-triggers.sh` — `apply_patch` payload writing `spec 080` into `.claude/rules/foo.md` fires `propagation-advisory: spec-NNN`; hook exits 0.
- [x] 9. Add `13-codex-non-shipped-silent.sh` — `apply_patch` writing a leak into a NON-shipped path (e.g. `docs/specs/...`) stays silent, exit 0.
- [x] 10. Wire `12` + `13` into `run-all.sh` (extend the `for n in ...` list).

### D. Docs
- [x] 11. `.claude/rules/propagation-advisory.md` — new path + runtime-neutral firing; one-line pointer to maintainer Codex activation in the maintenance memory.
- [x] 12. `.agent0/memory/propagation-advisory-maintenance.md` — full maintainer-only Codex activation (own gitignored `.codex/config.toml`, `^apply_patch$` matcher, NOT the shipped example) + dangling-ref rationale.
- [x] 13. `.claude/rules/runtime-capabilities.md` — update any propagation-advise framing from Claude-only → runtime-neutral (add/adjust note).
- [x] 14. `CLAUDE.md` + `AGENTS.md` § Propagation advisory — update the hook path reference (`.claude/hooks/` → `.agent0/hooks/`) if named.

## Verification

- [x] 15. `bash .claude/tests/propagation-advisory/run-all.sh` — all 14 scenarios PASS (11 existing regression on Claude + 3 new Codex).
- [x] 16. Manual Claude regression: pipe an `Edit` payload with a `spec 080` leak into the moved hook → `propagation-advisory: spec-NNN` on stderr, exit 0.
- [x] 17. Manual Codex sim: pipe an `apply_patch` payload (leak in a shipped path) into the moved hook → advisory fires; a non-shipped-path apply_patch → silent.
- [x] 18. `jq . .claude/settings.json` parses; the propagation-advise command points at `.agent0/hooks/`.
- [x] 19. `git grep -n "propagation-advise" .codex/config.toml.example` returns NOTHING (no dangling Codex block ships).
- [x] 20. `git grep -n "\.claude/hooks/propagation-advise" -- ':!docs/specs/'` returns nothing (no stale path references in live files).
- [x] 21. Real Codex `apply_patch` dogfood surfaces `propagation-advisory: spec-NNN` in the Codex transcript/log for a shipped throwaway file. 2026-05-29 final dogfood created `.claude/rules/_dogfood-113d.md`; the hook emitted JSON stdout with `hookSpecificOutput.additionalContext`, and Codex surfaced `propagation-advisory: spec-NNN in .claude/rules/_dogfood-113d.md:1 — this refs spec 080` as developer context. Non-shipped and override dogfoods stayed silent.

## Notes

_Populated during execution._
