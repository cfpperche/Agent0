# 021 — browser-auth-workflow — tasks

_Generated from `plan.md` on 2026-05-12. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. **Create the storage-state bucket scaffold.** `mkdir -p .claude/.browser-state && touch .claude/.browser-state/.gitkeep`. Verify the directory + sentinel file are present.

- [x] 2. **Update `.gitignore`.** In the "Ephemeral state under .claude/" block (around lines 6-16), add a new line: `.claude/.browser-state/*.json`. Verify `git check-ignore .claude/.browser-state/foo.json` resolves (exits 0) and `git check-ignore .claude/.browser-state/.gitkeep` does NOT resolve (exits 1).

- [x] 3. **Add `## Authenticated workflow` section to `.claude/rules/mcp-recipes.md`.** Insert after the existing `## Activation workflow` section (around line 168). Content must cover:
  - The Playwright headed → save → reuse lifecycle with concrete commands (start in headed mode, log in, invoke `browser_storage_state` to save to `.claude/.browser-state/<host>.json`, restart with `--storage-state=<path>` for headless reuse).
  - The `BROWSER_AUTH_REQUIRED: <host>` signaling convention — exact phrase the agent emits, plus a one-line follow-up template pointing at this rule section and naming the next concrete step the human should take.
  - The X/Twitter `unrollnow.com/status/<id>` shortcut: try first when `.claude/.browser-state/x.com.json` is missing; fall back to `BROWSER_AUTH_REQUIRED:` on failure. Mention `threadreaderapp.com` as a backup target.
  - A short "when Chrome DevTools is the better choice" paragraph: debugging perf/network on an already-authenticated session, NOT routine auth-gated reading.
  - The expired-state recovery pattern: agent recognizes 401/403/login-redirect → re-emits `BROWSER_AUTH_REQUIRED:` rather than retrying blindly.

- [x] 4. **Update `### Chrome DevTools MCP` recipe in `.claude/rules/mcp-recipes.md`.** Within the existing `## Recipes` section (the `### Chrome DevTools MCP` subsection starting around line 27): add a one-paragraph positioning note framing it as the debug-only complement to Playwright. Explicitly flag `--autoConnect` as opt-in (not the default workflow) with a security note pointing at the new `## Authenticated workflow` section.

- [x] 5. **Cross-reference `.claude/.browser-state/*.json` in `.claude/rules/secrets-scan.md`.** Add a brief paragraph (in `## Gotchas` or as a small new sub-section near credential-class references) noting that storage-state JSON files carry session cookies + localStorage = same blast radius as a leaked password; primary defense is `.gitignore`, doc-level reminder is here.

- [x] 6. **Add `## Browser auth` capacity section to `CLAUDE.md`.** Insert between `## Memory` (line 65) and `## Compact Instructions` (line 69). One paragraph in the same shape as `## MCP recipes` and `## Memory`: name the capacity, name Playwright as default + Chrome DevTools as debug, name the storage-state path (`.claude/.browser-state/<host>.json`), name the `BROWSER_AUTH_REQUIRED:` signal, and point at `.claude/rules/mcp-recipes.md § Authenticated workflow` for full detail.

- [x] 7. **Add out-of-scope comment in `.claude/tools/sync-harness.sh`.** Near the `COPY_CHECK_RECURSIVE`, `COPY_CHECK_GLOBS`, `COPY_CHECK_FILES` array declarations, add a comment explicitly naming `.claude/.browser-state/` AND `.claude/memory/` (re-stating existing spec 019 design) as project-local paths that must NEVER be added to the manifest. Forensic protection — cheap insurance against a future maintainer mistakenly extending scope.

## Verification

- [x] 8. **Sync-harness manifest unchanged.** `grep -n 'browser-state' .claude/tools/sync-harness.sh` returns ONLY the out-of-scope comment line from task 7 — no `COPY_CHECK_*` array entry. Sanity-check by running `bash .claude/tools/sync-harness.sh --check ~/pyshrnk` (or any fork) and confirming no `.claude/.browser-state/` lines appear in the drift output.

- [x] 9. **Gitignore behavior verified.** `git check-ignore -v .claude/.browser-state/x.com.json` confirms the pattern matches; `git check-ignore -v .claude/.browser-state/.gitkeep` confirms it does NOT (exits 1). `git status` after `touch .claude/.browser-state/test.json` shows the file IS ignored.

- [x] 10. **Acceptance scenarios from spec.md present in rule doc.** Confirm each of the four scenarios in `spec.md § Acceptance criteria` maps to a paragraph or example in the new `## Authenticated workflow` section: (a) signal on missing state, (b) reuse on existing state, (c) X/Twitter shortcut + fallback, (d) Chrome DevTools as debug not default. One grep per scenario keyword suffices.

- [x] 11. **No new hook, MCP, env var, or audit log introduced.** `git diff --stat HEAD` shows changes only in: `.claude/.browser-state/.gitkeep` (new), `.gitignore` (modified), `.claude/rules/mcp-recipes.md` (modified), `.claude/rules/secrets-scan.md` (modified), `CLAUDE.md` (modified), `.claude/tools/sync-harness.sh` (modified, comment only), `docs/specs/021-browser-auth-workflow/*` (new). NO changes to `.claude/settings.json`, `.claude/hooks/`, `.mcp.json.example`, `.claude/validators/`. Negative-space check confirms the spec stayed in its scope.

- [x] 12. **Validator dry-run is clean.** `bash .claude/validators/run.sh` exits 0 — no stack to detect on the Agent0 base, no advisories. Spec is doc-only so this is a sanity check rather than a real signal.

- [ ] 13. **Live smoke test (optional but recommended).** With Playwright MCP enabled in `.mcp.json`, attempt to read a known auth-gated page (or revisit the original X/Twitter trigger thread). Observe: the agent either uses the `unrollnow.com` shortcut for X, OR emits `BROWSER_AUTH_REQUIRED: <host>` and waits for the human. Confirm the chat-only convention works in practice before declaring the spec delivered.

## Notes

- Spec is **pure documentation + convention + one gitignore entry**. The "implementation" is six text edits and one empty file. Expect the diff to be small but the rule-doc additions substantive (the new `## Authenticated workflow` section will be ~50-100 lines of guidance with concrete commands).
- The **commit grouping** can stay as a single commit (`feat(browser-auth): spec 021 — Playwright + Chrome DevTools auth workflow`) or split into two if reviewers prefer (a) scaffold + gitignore + sync-harness comment, (b) rule docs + CLAUDE.md. Single commit is fine for a spec this small.
- **Fork rollout** is via `git pull` after Agent0 lands the change — the existing `harness-sync` tool already covers `.claude/rules/*.md`, `.gitignore`, `CLAUDE.md` (structured merge). No bespoke migration step needed. Forks discover the empty `.claude/.browser-state/` bucket via the `.gitkeep` sentinel.
- If task 13 (live smoke test) surfaces friction with the chat-only signaling — agent silently retries instead of emitting `BROWSER_AUTH_REQUIRED:` — that's the trigger to escalate to a `PostToolUse(WebFetch)` advisory hook in a follow-up spec. Documented as v2 candidate in `plan.md § Risks`.
