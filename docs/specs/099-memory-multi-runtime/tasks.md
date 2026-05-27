# 099 — memory-multi-runtime — tasks

_Generated from `plan.md` on 2026-05-27. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Phase A — Foundation (additive, zero behavior change)

- [ ] 1. **Dump-probe Codex `apply_patch` payload shape.** Write a transient `.agent0/hooks/probe-apply-patch.sh` that on `PostToolUse(apply_patch)` does `jq -c . > /tmp/codex-apply-patch-payload.json` and exits 0. Register it in `.codex/config.toml` (local, not the example), invoke any small `apply_patch` in a Codex session, capture the payload, verify `tool_input.command` (or whatever field) carries the patch body. Document the actual shape in `notes.md`. Delete the probe hook + the local config registration. **Done when** notes.md has a verified field name for the patch body + a sample patch with headers.

- [ ] 2. **Create `.agent0/tools/memory-maintain.sh`** with two subcommands:
  - `validate <entry>` — checks frontmatter against the schema in `memory-placement.md § Frontmatter schema`; emits `memory-frontmatter-advisory: <kind> in <path>:<line>` on stderr; exits 0 always (advisory, never blocks).
  - `finalize <entry-path>` — runs `validate` then `memory-project.sh`; idempotent; on validate failure prints advisory + continues; on projection failure exits non-zero with corrective hint.
  - **Done when** both subcommands work standalone (`bash .agent0/tools/memory-maintain.sh validate .claude/memory/cc-platform-hooks.md` exits 0 silently; manually break frontmatter in a throwaway entry → verify advisory text; manually mess up MEMORY.md → run finalize → verify re-projection).

- [ ] 3. **Create `.agent0/memory/.gitkeep`** sentinel so the new bucket exists in fresh clones. **Done when** file exists, empty, git-tracked.

### Phase B — Hook port with cross-runtime detection + compat shims

- [ ] 4. **Implement runtime-detection branching** (decide: shared bash function in `.agent0/hooks/_lib.sh` sourced by all 4 hooks, OR inline copy-paste). Lean: inline copy-paste (5-10 lines per hook), avoids sourcing pitfalls when hooks run from different cwd. Document the choice in `notes.md`. **Done when** the branching pattern is committed to one direction and reflected in tasks 5-8.

- [ ] 5. **Create `.agent0/hooks/memory-events-journal.sh`.** Reads stdin JSON; detects runtime via `tool_name` (Edit|Write|MultiEdit → Claude; apply_patch → Codex); extracts path via `tool_input.file_path` OR patch-header parsing per probe finding (task 1); filters for `.agent0/memory/*.md` (use parametrized path so v1 .claude/memory/ + v2 .agent0/memory/ both work during transition); runs `memory-maintain.sh validate` + `memory-project.sh`; appends JSONL event to `.agent0/.memory-events.jsonl` with `actor` derived from `tool_name`. **Done when** the script handles both payload shapes correctly (verified against synthetic Claude payload + synthetic Codex payload from task 1's probe output).

- [ ] 6. **Create `.agent0/hooks/memory-index-gate.sh`.** PreToolUse gate; same runtime detection + path extraction as task 5; if extracted path == `.agent0/memory/MEMORY.md` (or `.claude/memory/MEMORY.md` during transition), block with exit 2 + corrective template unless edit content contains `# OVERRIDE: memory-index-edit: <reason ≥10 chars>` (greppable via stdin payload — `tool_input.new_string` for Claude Edit; `tool_input.command` patch body for Codex apply_patch). **Done when** synthetic block + synthetic override-accept both behave correctly.

- [ ] 7. **Create `.agent0/hooks/memory-frontmatter-validate.sh`.** Thin caller: detect path, exec `bash .agent0/tools/memory-maintain.sh validate <path>`. **Done when** hook emits the advisory identically for the same malformed entry regardless of which runtime invoked it.

- [ ] 8. **Create `.agent0/hooks/memory-decay-readout.sh`.** SessionStart handler; invokes `bash .agent0/tools/memory-query.sh decay --readout`; identical framed `=== MEMORY DECAY ===` output for both runtimes. **Done when** running the hook directly emits the expected frame (verified against current `.claude/hooks/memory-decay-readout.sh` output byte-for-byte).

- [ ] 9. **Replace 4 old hook scripts with `exec`-shims.** Each `.claude/hooks/memory-*.sh` becomes literally:
  ```bash
  #!/usr/bin/env bash
  exec bash "$(dirname "$0")/../../.agent0/hooks/$(basename "$0")" "$@"
  ```
  **Done when** all 4 shims are 3 lines, executable bit preserved, and the shim correctly delegates (test by invoking the shim with a sample payload → verify the delegated script's behavior fires).

- [ ] 10. **Update `.claude/settings.json` hook registrations** at lines 29, 117, 164, 173 (per current state grep): replace `.claude/hooks/memory-*.sh` with `.agent0/hooks/memory-*.sh`. **Done when** grep `.claude/hooks/memory-` in settings.json returns zero matches.

- [ ] 11. **End-to-end Claude Code verification (post-Phase-B).** In a fresh Claude Code session: edit a memory entry, verify `memory-events-journal.sh` fires (check JSONL append) and MEMORY.md regenerates; edit MEMORY.md raw → verify gate blocks; introduce frontmatter error → verify advisory; restart session → verify decay readout. **Done when** all 4 hook behaviors fire identically to pre-spec baseline.

### Phase C — Namespace move (atomic rename + reference updates)

- [ ] 12. **`git mv` 22 memory entries + MEMORY.md** from `.claude/memory/` → `.agent0/memory/`. Use individual `git mv` per file (not `git mv -k`) to preserve per-file history cleanly. **Done when** `ls .agent0/memory/*.md | wc -l` shows 23 files + `.gitkeep`; `.claude/memory/` is empty.

- [ ] 13. **`git mv` 5 memory tools** from `.claude/tools/memory-*` → `.agent0/tools/memory-*` (memory-project.sh, memory-query.sh, memory-query-helper.py, memory-backfill.sh, memory-backfill-metadata.sh). **Done when** `ls .agent0/tools/memory-* | wc -l` == 5; no `.claude/tools/memory-*` remains.

- [ ] 14. **`git mv .claude/memory.config.json .agent0/memory.config.json`**. **Done when** grep across `.agent0/tools/` + `.agent0/hooks/` for old path returns zero matches.

- [ ] 15. **Grep + update all internal references** from `.claude/memory/`, `.claude/tools/memory-*`, `.claude/hooks/memory-*` (canonical paths, not the shims) to the new `.agent0/` paths. Targets: `.claude/rules/*.md`, `.claude/skills/**/*.md`, `.claude/tools/memory-*` (now `.agent0/tools/`), `.agent0/hooks/*.sh`, `docs/specs/`, `.gitignore`, `AGENTS.md`, `CLAUDE.md`. **Done when** `grep -rn "\.claude/memory/" .claude .agent0 docs AGENTS.md CLAUDE.md 2>/dev/null | grep -v "compat shim"` returns expected residuals only (legitimate historical citations in old specs are fine; live contract references must update).

- [ ] 16. **Update `.gitignore`** entry from `.claude/.memory-events.jsonl` → `.agent0/.memory-events.jsonl`. **Done when** git status shows no untracked `.agent0/.memory-events.jsonl` after running a memory edit.

- [ ] 17. **End-to-end Claude Code verification (post-Phase-C).** Same as task 11, now against `.agent0/memory/` paths. Restart Claude session to ensure SessionStart re-reads. **Done when** all 4 hook behaviors fire identically; journal events land in `.agent0/.memory-events.jsonl`; decay readout reads from `.agent0/memory/`.

### Phase D — Defenses + documentation

- [ ] 18. **Extend `.githooks/pre-commit`** with non-mutating projection drift check. Append a new section (after gitleaks): detect if any staged file matches `.agent0/memory/*.md`; if yes, compute projected MEMORY.md into a temp file via `bash .agent0/tools/memory-project.sh --dry-run --out=<tmp>` (add `--dry-run`/`--out` flags to memory-project.sh if not present); diff vs staged `.agent0/memory/MEMORY.md`; on drift exit 1 with `pre-commit-blocked: MEMORY.md drift detected; run 'bash .agent0/tools/memory-maintain.sh finalize' and re-stage`; on no-drift exit 0 silently. Fast-path: short-circuit immediately if no `.agent0/memory/*.md` files staged. **Done when** synthetic drift triggers block; synthetic no-drift commit succeeds; commit with no memory files staged adds <50ms latency (measured).

- [ ] 19. **Create `.claude/tests/agents-memory-block-budget.sh`.** Greps `AGENTS.md` for `## Memory` heading; counts non-blank lines from that heading up to the next `## ` heading (exclusive); exits 1 with corrective message if > 12; exits 0 silently if ≤ 12. **Done when** synthetic 13-line block fails the test; 12-line block passes; missing `## Memory` section emits a distinct error.

- [ ] 20. **Extend `.codex/config.toml.example`** with commented `[hooks]` block following spec 098 conventions. Register `PreToolUse` matching `apply_patch` → `.agent0/hooks/memory-index-gate.sh`; `PostToolUse` matching `apply_patch` → 2 entries (`memory-events-journal.sh`, `memory-frontmatter-validate.sh`); `SessionStart` → `memory-decay-readout.sh`. Verify TOML schema against `developers.openai.com/codex/config-reference`. **Done when** `tomllib` (Python) or `tomlq` (CLI) parses the file without error; commented out by default with explanatory header above the block.

- [ ] 21. **Rewrite `AGENTS.md § Memory` block within 12 non-blank lines.** Cover: trigger list (one line — link to memory-placement.md for full), `.agent0/memory/MEMORY.md` trigger-driven read direction, hook activation pointer (`.codex/config.toml.example`), `memory-maintain.sh finalize` fallback command, `memory-query.sh decay --readout` for hook-disabled sessions, "do not raw-edit `MEMORY.md`" rule, pointer to `memory-placement.md § Multi-runtime usage`. **Done when** `bash .claude/tests/agents-memory-block-budget.sh` exits 0.

- [ ] 22. **Update `CLAUDE.md § Memory` block** — replace path references from `.claude/memory/` → `.agent0/memory/`. Keep the rest of the block intact (already correct in shape). **Done when** grep `\.claude/memory/` in CLAUDE.md returns zero matches.

- [ ] 23. **Add `## Multi-runtime usage` section to `.claude/rules/memory-placement.md`.** Cover: operational trigger list verbatim (the one mentioned in AGENTS.md), hook activation flow for both runtimes (Claude via `.claude/settings.json`, Codex via `.codex/config.toml.example`), Bash-write non-coverage gap (apply_patch is v1 surface), `PostToolUseFailure` Claude-only event divergence, double-fire framing (sequential runtimes emit distinct events keyed by runtime/session_id/tool_use_id), `.githooks/pre-commit` activation requirement (`git config core.hooksPath .githooks`), AGENTS.md 12-line budget convention. **Done when** all 7 sub-topics are covered with concrete pointers (file paths, exact commands).

- [ ] 24. **Update `.claude/rules/runtime-capabilities.md` `memory` row.** Codex column: `convention` → `native-opt-in`. Notes column: append "Codex hooks port the four memory implementations via `.codex/config.toml.example`; `apply_patch` is the v1 hook-coverage surface; `Bash` writes are out of strict parity and caught by `.githooks/pre-commit` backstop; finalizer fallback for hook-disabled sessions." **Done when** grep `memory.*convention` returns no match in the Codex column.

- [ ] 25. **Verify/extend `.claude/tools/sync-harness.sh` manifest globs** to cover `.agent0/hooks/*.sh`, `.agent0/tools/memory-*`, `.agent0/memory/.gitkeep`, `.agent0/memory.config.json`. Inspect current globs first (`grep -n "glob\|pattern\|manifest" .claude/tools/sync-harness.sh | head -20`); extend if needed. **Done when** dry-run sync from Agent0 to a fresh scratch consumer dir produces a manifest containing all the new paths.

- [ ] 26. **Regenerate `.claude/harness-sync-baseline.json`** to reflect the new file surface. Run whatever command the sync-harness rule documents (likely `bash .claude/tools/sync-harness.sh --regenerate-baseline` or similar); commit the resulting baseline change. **Done when** baseline JSON includes the new `.agent0/*` paths and excludes the moved-from `.claude/memory/`, `.claude/tools/memory-*`, etc.

### Phase E — Consumer migration playbook + execution

- [ ] 27. **Write `docs/specs/099-memory-multi-runtime/migration-playbook.md`.** Ordered steps: (a) `git pull` to receive sync of new `.agent0/` files; (b) verify shims still work (existing setup unchanged); (c) decision point — migrate now or later; if now: (d) `git mv .claude/memory/*.md .agent0/memory/`; (e) `git mv .claude/tools/memory-* .agent0/tools/`; (f) `git mv .claude/memory.config.json .agent0/memory.config.json`; (g) update consumer's `.claude/settings.json` hook paths from `.claude/hooks/memory-*.sh` → `.agent0/hooks/memory-*.sh`; (h) remove the 4 shim files at `.claude/hooks/memory-*.sh` (they delegate to .agent0/ which the consumer is now using directly); (i) verify with `bash .agent0/tools/memory-project.sh` + run existing `.claude/tests/harness-sync/*` suite; (j) commit + push. Include a "rollback" section (revert to pre-migration commit if anything breaks). Include `mei-saas`-specific + `codexeng`-specific notes if their git history shows customizations of any memory hook. **Done when** playbook is self-contained (a consumer operator can follow without re-asking).

- [ ] 28. **Pre-flight: grep mei-saas + codexeng for memory-hook customizations.** Clone both consumers (or use existing checkouts); `cd <consumer>; git log --all --diff-filter=M -- .claude/hooks/memory-* .claude/tools/memory-* .claude/memory.config.json | head -30`. If any commits show customization, document the resolution path in the playbook (task 27). **Done when** notes.md records the customization audit result for each consumer.

- [ ] 29. **Execute manual migration in `mei-saas` per playbook.** Follow tasks (a)-(j) from the playbook in `/path/to/mei-saas` checkout. After step (i), run a sanity edit of a memory entry → verify hooks fire + journal append + MEMORY.md regen. **Done when** consumer is on the new layout, all hooks work, commit pushed to `github.com:cfpperche/mei-saas.git`.

- [ ] 30. **Execute manual migration in `codexeng` per playbook.** Same as task 29 against `codexeng` checkout. **Done when** consumer is on the new layout, all hooks work, commit pushed to `github.com:cfpperche/codexeng.git`.

## Verification

_Acceptance checks tied to spec.md acceptance criteria. Each maps to one or more scenarios in `spec.md § Acceptance criteria`._

- [ ] **V1 — Codex hook-parity scenarios.** In a Codex CLI session in Agent0 with hooks activated (`.codex/config.toml` from the extended template): (a) `apply_patch` to add a malformed-frontmatter entry under `.agent0/memory/` → verify `memory-frontmatter-advisory:` emitted with identical text to Claude's; (b) `apply_patch` to edit `.agent0/memory/MEMORY.md` directly → verify PreToolUse blocks with exit 2 + corrective template + override grammar; (c) `apply_patch` to add a valid entry → verify MEMORY.md regenerates AND `.agent0/.memory-events.jsonl` gains a line with `actor: "Codex CLI"`; (d) session restart → verify `=== MEMORY DECAY ===` framed block matches Claude's output. Covers spec scenarios 3, 4, 5, 6, 10.

- [ ] **V2 — Shared scripts + config layout.** Inspect `.agent0/hooks/memory-*.sh` exist (4 files); grep `.claude/settings.json` shows registrations at `.agent0/hooks/` paths (4 hits); `.codex/config.toml.example` carries commented `[hooks]` block with `apply_patch` + `SessionStart` matchers pointing at `.agent0/hooks/memory-*.sh`. Covers spec scenarios 7, 8.

- [ ] **V3 — Finalizer fallback.** In a Codex session with `[features] hooks = false` in `.codex/config.toml`: edit a memory entry → verify NO journal event was written (hooks disabled); run `bash .agent0/tools/memory-maintain.sh finalize <path>` → verify projection runs + entry is validated. Covers spec scenario 9.

- [ ] **V4 — Capability matrix.** Grep `.claude/rules/runtime-capabilities.md` `memory` row — verify Codex column == `native-opt-in`, Notes column carries the new prose. Covers spec scenario 11.

- [ ] **V5 — Pre-commit drift backstop.** Activate `.githooks/pre-commit` via `git config core.hooksPath .githooks`; (a) edit a memory entry without running finalize → `git add .agent0/memory/<file>.md` → `git commit -m test` → verify commit blocked with the corrective message; (b) run finalize, re-stage MEMORY.md, retry commit → verify success; (c) commit unrelated change (no memory files staged) → verify commit succeeds with <50ms hook latency. Covers spec scenario 12.

- [ ] **V6 — AGENTS.md budget enforcement.** Run `bash .claude/tests/agents-memory-block-budget.sh` against current `AGENTS.md` → exits 0. Synthetically add a 13th non-blank line to the `## Memory` block → re-run → exits 1 with corrective message. Restore. Covers spec scenario 13.

- [ ] **V7 — Migration playbook existence + completeness.** Verify `docs/specs/099-memory-multi-runtime/migration-playbook.md` exists; verify all 10 steps (a)-(j) per task 27 are present and ordered; verify mei-saas-specific + codexeng-specific notes are present. Covers spec scenario 14.

- [ ] **V8 — Consumer migrations succeeded.** Verify `mei-saas` and `codexeng` both have:
  - `.agent0/memory/` directory exists with entries
  - `.claude/settings.json` references `.agent0/hooks/memory-*.sh` (not `.claude/hooks/`)
  - No `.claude/hooks/memory-*.sh` files remain (shims removed)
  - Latest commit on each project's main branch confirms migration. Covers the migration-execution aspect of scenario 14.

- [ ] **V9 — Trigger-list + entrypoint discovery.** Verify `AGENTS.md § Memory` lists the operational trigger list; verify `CLAUDE.md § Memory` block points at `.agent0/memory/`; verify both runtimes read the same `.agent0/memory/MEMORY.md` source (grep both entrypoints for the path). Covers spec scenarios 1, 2.

- [ ] **V10 — Static facts.** Verify: `.claude/rules/memory-placement.md` has `## Multi-runtime usage` section with all 7 sub-topics; `.agent0/tools/memory-*` are shell-invocable from project root (`bash .agent0/tools/memory-project.sh`, `memory-query.sh decay --readout`, `memory-maintain.sh validate <path>`, `memory-maintain.sh finalize <path>`); tests cover advisory parity + projection idempotence + decay readout + AGENTS.md budget + pre-commit drift check (greppable as committed shell scripts in `.claude/tests/` or `.agent0/tests/`).

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._

- Task 1 (Codex `apply_patch` payload probe) is the canonical "verify before parser" — same lesson as `.claude/memory/cc-platform-hooks.md` § Meta-lesson (spec 020 `PostToolUseFailure` shape divergence). Do NOT skip even if it feels redundant.
- The compat-shims approach (task 9) is the load-bearing transitional-state decision from `plan.md § Alternatives considered`. If shims prove brittle or sync-harness misbehaves, escalate to user before falling back to hard cutover (Option B was explicitly rejected).
- Phase D tasks 21-22 (AGENTS.md + CLAUDE.md edits) are the propagation-advisory sensitive zone — both files ship to consumers. Run `grep` for `spec 099` / `docs/specs/099` / personal paths in the diff before commit (per `.claude/rules/propagation-advisory.md`).
- Tasks 29-30 (consumer execution) require `git push` authorization to `mei-saas` + `codexeng` remotes — confirm with operator before pushing.
- The shim-removal follow-up (after both consumers migrate) is OUT of scope for this spec; track via `notes.md` § next-actions for a `chore(099-followup)` commit.
