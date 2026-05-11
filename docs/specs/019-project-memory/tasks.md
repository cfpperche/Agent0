# 019 — project-memory — tasks

_Generated from `plan.md` on 2026-05-11. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Phase 0 — scaffolding

- [x] 1. Create `.claude/memory/` directory with `.gitkeep` so empty-state is git-trackable until first content lands.
- [x] 2. Create `.claude/tests/project-memory/` with one-line `README.md` describing scenario-to-script numbering convention (mirror `.claude/tests/harness-sync/README.md`).

### Phase 1 — RED tests

Scenarios 1, 3, 5, 6, 7 are true RED (assert positive presence — fail before impl). Scenarios 2 and 4 are **invariant guards** (assert absence — pass trivially before impl, must continue passing after; protect against regression where someone adds auto-load or wires memory into sync-harness manifest).

- [x] 3. Write `01-files-are-git-tracked.sh` — assert `.claude/memory/` exists in `$AGENT0_ROOT` AND `git -C "$AGENT0_ROOT" ls-files .claude/memory/` includes the migrated `agent0-purpose.md` and `visibility-intent.md` files (status RED until Phase 2 + 3 complete).
- [x] 4. Write `02-no-fork-propagation.sh` — fixture: tmp Agent0 mock with `.claude/memory/foo.md` populated, tmp fork target. Run sync-harness `--apply`. Assert `find $FORK/.claude/memory -type f` returns empty OR no file from Agent0's memory dir landed (status: invariant guard, passes trivially before AND after impl — protects sync-harness manifest from accidental inclusion).
- [x] 5. Write `03-claude-md-has-memory-block.sh` — assert `grep -c '^## Memory$' $AGENT0_ROOT/CLAUDE.md` == 1 AND `grep -c '\.claude/memory/MEMORY\.md' $AGENT0_ROOT/CLAUDE.md` >= 1 (status RED until Phase 2).
- [x] 6. Write `04-sessionstart-no-memory-block.sh` — fixture: tmp project with `.claude/memory/{a.md, b.md, c.md, d.md, e.md}` populated. Invoke `session-start.sh` with `$CLAUDE_PROJECT_DIR=$TMPDIR`. Assert stdout contains NO `project-memory` substring AND no body content from any of the 5 memory files (status: invariant guard).
- [x] 7. Write `05-rule-cross-reference.sh` — assert `grep -c '\.claude/memory/cc-platform-hooks\.md' $AGENT0_ROOT/.claude/rules/runtime-introspect.md` >= 1 (status RED until Phase 2).
- [x] 8. Write `06-migration-shape.sh` — assert: (a) `.claude/memory/agent0-purpose.md` exists with frontmatter containing `name:`, `description:`, `type:`; (b) same for `visibility-intent.md`; (c) `~/.claude/projects/-home-goat-Agent0/memory/user_language.md` STILL EXISTS (preference stays); (d) the two migrated source files in CC per-user are GONE (status RED until Phase 3).
- [x] 9. Write `07-memory-placement-3-buckets.sh` — assert `.claude/rules/memory-placement.md` mentions all three bucket paths verbatim: `~/.claude/projects/`, `.claude/memory/`, `.claude/rules/` (status RED until Phase 2).
- [x] 10. Write `run-all.sh` driver mirroring `.claude/tests/harness-sync/run-all.sh` shape.
- [x] 11. Run `bash .claude/tests/project-memory/run-all.sh` — confirm RED state: tests 01, 03, 05, 06, 07 FAIL; tests 02, 04 PASS (invariant guards trivially pass).

### Phase 2 — GREEN: memory artifacts

- [x] 12. Create `.claude/memory/MEMORY.md` with index entries for the 3 initial memories (agent0-purpose, visibility-intent, cc-platform-hooks). Plain markdown bullet list, mirror CC per-user index shape.
- [x] 13. Create `.claude/memory/cc-platform-hooks.md` — frontmatter (`name`, `description`, `metadata.type: reference`) + body covering: (a) the 29 canonical CC hook events with one-line description each; (b) explicit "PostToolUse fires only on success" + "PostToolUseFailure exists for failure path" — quoting docs verbatim; (c) payload-shape notes for the 3 events Agent0 currently uses (PreToolUse/Bash, PostToolUse/Bash, SessionStart); (d) link to <https://code.claude.com/docs/en/hooks> as canonical source; (e) the meta-lesson sentence: "Always consult the canonical event list before designing a new hook-based capacity — Agent0 spec 011 was shipped with a foundational gap because the designer assumed the event surface was ~9 events instead of 29".

### Phase 3 — GREEN: migration

- [x] 14. Read `~/.claude/projects/-home-goat-Agent0/memory/project_agent0_purpose.md`, transcribe content (drop `originSessionId` field, keep `name`/`description`/`type`/body) into `.claude/memory/agent0-purpose.md`.
- [x] 15. Read `~/.claude/projects/-home-goat-Agent0/memory/project_visibility_intent.md`, transcribe content (drop `originSessionId`) into `.claude/memory/visibility-intent.md`.
- [x] 16. Edit `~/.claude/projects/-home-goat-Agent0/memory/MEMORY.md` — remove the lines for `project_agent0_purpose.md` and `project_visibility_intent.md`; leave `user_language` entry intact.
- [x] 17. Delete `~/.claude/projects/-home-goat-Agent0/memory/project_agent0_purpose.md` and `~/.claude/projects/-home-goat-Agent0/memory/project_visibility_intent.md`.

### Phase 4 — GREEN: documentation + cross-references

- [x] 18. Insert `## Memory` block into `CLAUDE.md` immediately before `## Compact Instructions`. ~5-7 lines: project memory location, lazy-read framing, distinction from rules (factual reference vs behavioral mandate), pointer to `.claude/memory/MEMORY.md` as index entry point.
- [x] 19. Full rewrite of `.claude/rules/memory-placement.md` — replace 2-bucket model with 3-bucket: (a) CC per-user (preferences ONLY, examples: language, terseness), (b) `.claude/memory/<topic>.md` (project factual knowledge, git-tracked, NOT shipped to forks), (c) `.claude/rules/<topic>.md` (project behavioral mandates + capacity docs, git-tracked, SHIPPED via sync-harness). Each bucket gets a "when to use" guidance line and a concrete example drawn from current state (`user_language` for per-user, `agent0-purpose` for memory, `delegation` for rule).
- [x] 20. Extend `.claude/rules/runtime-introspect.md` § Gotchas: add one sentence at the end of the existing "Claude Code's `tool_response.exit_code` does NOT exist" gotcha bullet — "See `.claude/memory/cc-platform-hooks.md` for the canonical event surface and the PostToolUse-on-success-only behavior."
- [x] 21. Run `bash .claude/tests/project-memory/run-all.sh` — confirm 7/7 PASS (all RED scenarios now GREEN, invariant guards continue to pass).

### Phase 5 — propagation verification

The `.claude/memory/` directory itself does NOT ship to forks. But the modified rule docs (`memory-placement.md`, `runtime-introspect.md`) and CLAUDE.md DO ship via sync-harness. Verify the propagation behaves correctly.

- [x] 22. Dry-run sync against pyshrnk: `bash .claude/tools/sync-harness.sh --apply --dry-run --force --force-except='.gitignore' --agent0-path=/home/goat/Agent0 /home/goat/pyshrnk`. Assert decision lines include `! overwritten .claude/rules/memory-placement.md`, `! overwritten .claude/rules/runtime-introspect.md`, `~ merged CLAUDE.md` (or equivalent), AND ZERO lines mentioning `.claude/memory/`.
- [x] 23. If task 22 looks correct, apply sync to all 3 shrnks: `bash .claude/tools/sync-harness.sh --apply --force --force-except='.gitignore' --agent0-path=/home/goat/Agent0 /home/goat/<fork>` for pyshrnk, shrnk, rshrnk. Commit per fork: `chore(harness-sync): adopt Agent0 spec 019 (project-memory rule update)`.
- [x] 24. Verify each fork: `bash .claude/tools/sync-harness.sh --check --agent0-path=/home/goat/Agent0 /home/goat/<fork>` exits 0 (no drift), AND `ls /home/goat/<fork>/.claude/memory/ 2>&1` shows the directory does NOT exist in the fork (confirms `.claude/memory/` correctly stayed Agent0-local).

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria._

- [x] **Scenario 1 — git-tracked** — `01-*.sh` PASS; `git -C /home/goat/Agent0 ls-files .claude/memory/` lists the migrated files.
- [x] **Scenario 2 — no fork propagation** — `02-*.sh` PASS; manual check: pyshrnk post-sync has no `.claude/memory/`.
- [x] **Scenario 3 — CLAUDE.md discovery** — `03-*.sh` PASS; manual `grep "^## Memory" /home/goat/Agent0/CLAUDE.md` returns 1 line.
- [x] **Scenario 4 — SessionStart no auto-load** — `04-*.sh` PASS; manual: starting a fresh session in Agent0 produces NO `project-memory` block in additional-context.
- [x] **Scenario 5 — cross-reference works** — `05-*.sh` PASS; manual `grep cc-platform-hooks /home/goat/Agent0/.claude/rules/runtime-introspect.md` returns ≥1 line.
- [x] **Scenario 6 — migration** — `06-*.sh` PASS; manual: `ls ~/.claude/projects/-home-goat-Agent0/memory/` shows ONLY `MEMORY.md` + `user_language.md`; `ls /home/goat/Agent0/.claude/memory/` shows 4 files (MEMORY.md, agent0-purpose.md, visibility-intent.md, cc-platform-hooks.md).
- [x] **Scenario 7 — 3 buckets documented** — `07-*.sh` PASS; manual reading of `memory-placement.md` confirms all 3 buckets explicit with examples.
- [x] **Static checks** — `.claude/memory/{MEMORY.md,agent0-purpose.md,visibility-intent.md,cc-platform-hooks.md}` exist; CLAUDE.md has `## Memory`; rules updated; 7 test scripts exist.
- [x] **Full driver green** — `bash .claude/tests/project-memory/run-all.sh` exits 0.
- [x] **Forks synced + committed** — pyshrnk, shrnk, rshrnk each have a sync commit; `--check` exits 0; `.claude/memory/` does NOT exist in any fork.

### Phase 6 — post-impl amendment (scaffold ships)

User-driven question post-Phase-5: "do forks gain the project-memory capacity?". The capacity (rule docs + CLAUDE.md instruction) shipped, but the empty scaffold did NOT — fork users would face an empty-dir hunt. Fix:

- [x] 25. Add `.claude/memory/.gitkeep` to `COPY_CHECK_FILES` in `.claude/tools/sync-harness.sh`. Single literal-file entry. Empty scaffold ships; memory content (`MEMORY.md`, topic files) stays out of manifest.
- [x] 26. Tighten test 02 — fixture now includes `.gitkeep` in SRC; asserts `.gitkeep` ships to fork AND that `foo.md`/`MEMORY.md` do NOT (precise semantic: scaffold yes, content no).
- [x] 27. Update `.claude/rules/memory-placement.md` with explicit "for forks of Agent0: this rule applies in your own project too" guidance. Updated quick-reference table to show "empty scaffold only" for the ships-to-forks column.
- [x] 28. Update `plan.md` with the amendment paragraph documenting the scope correction.
- [x] 29. Re-sync 3 shrnks → each gets `.claude/memory/.gitkeep` empty scaffold; verify no Agent0 content leaked.

## Notes

- This spec deliberately ships **no new code** (no hooks, no tools, no scripts). The whole capacity is convention + instruction. That's the design — auto-load mechanisms reintroduce the scaling problem the user explicitly rejected. Resist the temptation to add helpers later; cross-references from rule docs are the discoverability primitive.
- The `cc-platform-hooks.md` content is the immediate trigger of value: spec 020 (next, `runtime-capture-on-failure`) will reference it heavily and will be the first concrete user of the cross-reference pattern.
- `.claude/rules/memory-placement.md` rewrite is a behavioral mandate change for any future agent saving memory. The 3-bucket model isn't optional — it's how the project organizes knowledge from now on.
- After spec 019 lands and propagates, dogfood pass 2 in pyshrnk should reference `.claude/memory/cc-platform-hooks.md` when reproducing or retesting the PostToolUseFailure path.
- Phase 5 verification confirms the "memory does not ship" property in the wild, not just in tmp-dir tests. Worth doing — first time `.claude/memory/` exists, the implicit-out-of-scope behavior of the manifest is being trusted in production.
