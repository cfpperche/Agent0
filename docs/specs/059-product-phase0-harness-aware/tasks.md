# 059 — Tasks

1. [x] Audit `.claude/tools/sync-harness.sh` manifest section to confirm the 7-path Agent0 harness allowlist: `.claude/`, `.githooks/`, `.gitignore`, `.gitleaks.toml`, `.mcp.json.example`, `CLAUDE.md`, `.git/`. **Confirmed** — matches sync-harness manifest as of 2026-05-19 (verified empirically via mei-saas bootstrap output the same day).
2. [x] Edit `.claude/skills/product/SKILL.md` § Phase 0 step 1 — replace "if `<out>` exists and is non-empty" with the filter-then-check logic. Inline the allowlist verbatim.
3. [x] Edit `.claude/skills/product/SKILL.md` § Phase 0 step 2 — add a clause: when scaffolding writes `<out>/.gitignore` and the file already exists, append the new rules under a `# --- /product (<stack>) ---` marker line. Specify idempotent-re-run behavior (replace region under existing marker if found).
4. [x] Manual verification per § plan.md acceptance verification table (5 scenarios). Document outcomes in `notes.md`. **Done 2026-05-19 via synthetic smoke test in `/tmp/test-{empty,harness,artifacts}/`** — scenarios 1/2/3/5 PASS; scenario 4 verified by inspection (gated on empirical `/product` run by mei-saas founder). See `notes.md` § *Synthetic smoke test outcomes*.
5. [x] Re-bootstrap `/home/goat/mei-saas` from scratch with the patched `/product` skill propagated via `sync-harness.sh`. **Done 2026-05-19** — sync-harness propagated patched SKILL.md; `.gitleaks.toml` pre-fixed inline (`[allowlist]` form) before initial commit; bootstrap commit `5f33e3e` landed clean. `/product` invocation pending in fresh CC session by founder.
6. [x] Update `spec.md` § Status from `draft` to `shipped` once tasks 1-5 are done and the mei-saas bootstrap succeeded.
7. [ ] Commit: `feat(059): /product Phase 0 harness-aware non-empty check`.
