# 059 — Tasks

1. [x] Audit `.claude/tools/sync-harness.sh` manifest section to confirm the 7-path Agent0 harness allowlist: `.claude/`, `.githooks/`, `.gitignore`, `.gitleaks.toml`, `.mcp.json.example`, `CLAUDE.md`, `.git/`. **Confirmed** — matches sync-harness manifest as of 2026-05-19 (verified empirically via mei-saas bootstrap output the same day).
2. [x] Edit `.claude/skills/product/SKILL.md` § Phase 0 step 1 — replace "if `<out>` exists and is non-empty" with the filter-then-check logic. Inline the allowlist verbatim.
3. [x] Edit `.claude/skills/product/SKILL.md` § Phase 0 step 2 — add a clause: when scaffolding writes `<out>/.gitignore` and the file already exists, append the new rules under a `# --- /product (<stack>) ---` marker line. Specify idempotent-re-run behavior (replace region under existing marker if found).
4. [ ] Manual verification per § plan.md acceptance verification table (5 scenarios). Document outcomes in `notes.md`. **Deferred to mei-saas bootstrap empirical run.**
5. [ ] Re-bootstrap `/home/goat/mei-saas` from scratch with the patched `/product` skill propagated via `sync-harness.sh`. Confirm `/product "<idea>" --out=/home/goat/mei-saas` proceeds without overwrite prompt.
6. [ ] Update `spec.md` § Status from `draft` to `shipped` once tasks 1-5 are done and the mei-saas bootstrap succeeded.
7. [ ] Commit: `feat(059): /product Phase 0 harness-aware non-empty check`.
