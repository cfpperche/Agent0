# 099 — memory-multi-runtime — tasks

_Generated from `plan.md` on 2026-05-27. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Phase A — Foundation (additive, zero behavior change)

- [x] 1. **Resolve Codex `apply_patch` payload shape for parser implementation.** The hook parser accepts `tool_input.command` as the documented/primary patch-body field and tolerates `tool_input.input`, `tool_input.patch`, `tool_input.content`, or string `tool_input` as defensive fallbacks. The live probe was not run in this already-started Codex session; the implementation is covered by synthetic payload tests and the deviation is recorded in `notes.md`. **Done when** `03-codex-apply-patch-hooks.sh` exercises `tool_input.command` with patch headers and notes.md records the live-probe limitation.

- [x] 2. **Create `.agent0/tools/memory-maintain.sh`** with two subcommands:
  - `validate <entry>` — checks frontmatter against the schema in `memory-placement.md § Frontmatter schema`; emits `memory-frontmatter-advisory: <kind> in <path>:<line>` on stderr; exits 0 always (advisory, never blocks).
  - `finalize <entry-path>` — runs `validate` then `memory-project.sh`; idempotent; on validate failure prints advisory + continues; on projection failure exits non-zero with corrective hint.
  - **Done when** both subcommands work standalone (`bash .agent0/tools/memory-maintain.sh validate .agent0/memory/cc-platform-hooks.md` exits 0 silently; manually break frontmatter in a throwaway entry → verify advisory text; manually mess up MEMORY.md → run finalize → verify re-projection).

- [x] 3. **Create `.agent0/memory/.gitkeep`** sentinel so the new bucket exists in fresh clones. **Done when** file exists, empty, git-tracked.

### Phase B — Hook port with cross-runtime detection + compat shims

- [x] 4. **Implement runtime-detection branching** via shared `.agent0/hooks/_memory-hook-lib.sh` sourced by all 4 memory hooks. This centralizes path extraction, runtime/actor detection, and legacy-path transition helpers. **Done when** the branching pattern is committed to one direction and reflected in tasks 5-8.

- [x] 5. **Create `.agent0/hooks/memory-events-journal.sh`.** Reads stdin JSON; detects runtime via `tool_name` (Edit|Write|MultiEdit → Claude; apply_patch → Codex); extracts path via `tool_input.file_path` OR patch-header parsing per probe finding (task 1); filters for `.agent0/memory/*.md` (and legacy `.claude/memory/*.md` during consumer migration); runs `memory-maintain.sh validate` + `memory-project.sh`; appends JSONL event to `.agent0/.memory-events.jsonl` with `actor` derived from `tool_name`. **Done when** the script handles both payload shapes correctly (verified against synthetic Claude payload + synthetic Codex payload).

- [x] 6. **Create `.agent0/hooks/memory-index-gate.sh`.** PreToolUse gate; same runtime detection + path extraction as task 5; if extracted path == `.agent0/memory/MEMORY.md` (or `.claude/memory/MEMORY.md` during transition), block with exit 2 + corrective template unless edit content contains `# OVERRIDE: memory-index-edit: <reason ≥10 chars>` (greppable via stdin payload — `tool_input.new_string` for Claude Edit; `tool_input.command` patch body for Codex apply_patch). **Done when** synthetic block + synthetic override-accept both behave correctly.

- [x] 7. **Create `.agent0/hooks/memory-frontmatter-validate.sh`.** Thin caller: detect path, exec `bash .agent0/tools/memory-maintain.sh validate <path>`. **Done when** hook emits the advisory identically for the same malformed entry regardless of which runtime invoked it.

- [x] 8. **Create `.agent0/hooks/memory-decay-readout.sh`.** SessionStart handler; invokes `bash .agent0/tools/memory-query.sh decay --readout`; identical framed `=== MEMORY DECAY ===` output for both runtimes. **Done when** running the hook directly emits the expected frame.

- [x] 9. **Replace 4 old hook scripts with `exec`-shims.** Each `.claude/hooks/memory-*.sh` becomes literally:
  ```bash
  #!/usr/bin/env bash
  exec bash "$(dirname "$0")/../../.agent0/hooks/$(basename "$0")" "$@"
  ```
  **Done when** all 4 shims are 2 lines, executable bit preserved, and the shim correctly delegates (test by invoking the shim with a sample payload → verify the delegated script's behavior fires).

- [x] 10. **Update `.claude/settings.json` hook registrations** at lines 29, 117, 164, 173 (per current state grep): replace `.claude/hooks/memory-*.sh` with `.agent0/hooks/memory-*.sh`. **Done when** grep `.claude/hooks/memory-` in settings.json returns zero matches.

- [x] 11. **Shell-level Claude-compatible verification (post-Phase-B).** Feed synthetic Claude-style payloads through the shared hooks: edit a memory entry, verify `memory-events-journal.sh` appends and MEMORY.md regenerates; edit MEMORY.md raw → verify gate blocks; introduce frontmatter error → verify advisory; run decay readout directly. **Done when** all 4 hook behaviors pass the shell test suite.

### Phase C — Namespace move (atomic rename + reference updates)

- [x] 12. **Move 22 memory entries + MEMORY.md** from `.claude/memory/` → `.agent0/memory/`. Preserve filename identity so Git can detect renames in the final diff. **Done when** `ls .agent0/memory/*.md | wc -l` shows 23 files + `.gitkeep`; `.claude/memory/` no longer contains the project-memory corpus.

- [x] 13. **Move 5 memory tools** from `.claude/tools/memory-*` → `.agent0/tools/memory-*` (memory-project.sh, memory-query.sh, memory-query-helper.py, memory-backfill.sh, memory-backfill-metadata.sh). **Done when** `ls .agent0/tools/memory-* | wc -l` >= 5; no `.claude/tools/memory-*` remains.

- [x] 14. **Move `.claude/memory.config.json` to `.agent0/memory.config.json`**. **Done when** grep across `.agent0/tools/` + `.agent0/hooks/` for old path returns zero matches.

- [x] 15. **Grep + update all internal references** from `.claude/memory/`, `.claude/tools/memory-*`, `.claude/hooks/memory-*` (canonical paths, not the shims) to the new `.agent0/` paths. Targets: `.claude/rules/*.md`, `.claude/skills/**/*.md`, `.agent0/tools/memory-*`, `.agent0/hooks/*.sh`, `docs/specs/`, `.gitignore`, `AGENTS.md`, `CLAUDE.md`. **Done when** `grep -rn "\.claude/memory/" .claude .agent0 docs AGENTS.md CLAUDE.md 2>/dev/null | grep -v "compat shim"` returns expected residuals only (legitimate historical citations in old specs/debate and migration playbooks are fine; live contract references must update).

- [x] 16. **Update `.gitignore`** with `.agent0/.memory-events.jsonl` while keeping legacy `.claude/.memory-events.jsonl` ignored during the migration window. **Done when** git status shows no untracked memory event journals after running a memory edit.

- [x] 17. **Shell-level Claude-compatible verification (post-Phase-C).** Same as task 11, now against `.agent0/memory/` paths. **Done when** all 4 hook behaviors pass; journal events land in `.agent0/.memory-events.jsonl`; decay readout reads from `.agent0/memory/`.

### Phase D — Defenses + documentation

- [x] 18. **Extend `.githooks/pre-commit`** with non-mutating projection drift check. Append a new section (after gitleaks): detect if any staged file matches `.agent0/memory/*.md`; if yes, compute projected MEMORY.md into a temp file via `bash .agent0/tools/memory-project.sh --dry-run --out=<tmp>` (add `--dry-run`/`--out` flags to memory-project.sh if not present); diff vs staged `.agent0/memory/MEMORY.md`; on drift exit 1 with `pre-commit-blocked: MEMORY.md drift detected; run 'bash .agent0/tools/memory-maintain.sh finalize' and re-stage`; on no-drift exit 0 silently. Fast-path: short-circuit immediately if no `.agent0/memory/*.md` files staged. **Done when** synthetic drift triggers block and synthetic no-drift passes.

- [x] 19. **Create `.claude/tests/agents-memory-block-budget.sh`.** Greps `AGENTS.md` for `## Memory` heading; counts non-blank lines from that heading up to the next `## ` heading (exclusive); exits 1 with corrective message if > 12; exits 0 silently if ≤ 12. **Done when** synthetic 13-line block fails the test; 12-line block passes; missing `## Memory` section emits a distinct error.

- [x] 20. **Extend `.codex/config.toml.example`** with commented `[hooks]` block following spec 098 conventions. Register `PreToolUse` matching `apply_patch` → `.agent0/hooks/memory-index-gate.sh`; `PostToolUse` matching `apply_patch` → 2 entries (`memory-events-journal.sh`, `memory-frontmatter-validate.sh`); `SessionStart` → `memory-decay-readout.sh`. Verify TOML schema against `developers.openai.com/codex/config-reference`. **Done when** `tomllib` (Python) or `tomlq` (CLI) parses the file without error; commented out by default with explanatory header above the block.

- [x] 21. **Rewrite `AGENTS.md § Memory` block within 12 non-blank lines.** Cover: trigger list (one line — link to memory-placement.md for full), `.agent0/memory/MEMORY.md` trigger-driven read direction, hook activation pointer (`.codex/config.toml.example`), `memory-maintain.sh finalize` fallback command, `memory-query.sh decay --readout` for hook-disabled sessions, "do not raw-edit `MEMORY.md`" rule, pointer to `memory-placement.md § Multi-runtime usage`. **Done when** `bash .claude/tests/agents-memory-block-budget.sh` exits 0.

- [x] 22. **Update `CLAUDE.md § Memory` block** — replace path references from `.claude/memory/` → `.agent0/memory/`. Keep the rest of the block intact (already correct in shape). **Done when** grep `\.claude/memory/` in CLAUDE.md returns zero matches.

- [x] 23. **Add `## Multi-runtime usage` section to `.claude/rules/memory-placement.md`.** Cover: operational trigger list verbatim (the one mentioned in AGENTS.md), hook activation flow for both runtimes (Claude via `.claude/settings.json`, Codex via `.codex/config.toml.example`), Bash-write non-coverage gap (apply_patch is v1 surface), `PostToolUseFailure` Claude-only event divergence, double-fire framing (sequential runtimes emit distinct events keyed by runtime/session_id/tool_use_id), `.githooks/pre-commit` activation requirement (`git config core.hooksPath .githooks`), AGENTS.md 12-line budget convention. **Done when** all 7 sub-topics are covered with concrete pointers (file paths, exact commands).

- [x] 24. **Update `.claude/rules/runtime-capabilities.md` `memory` row.** Codex column: `convention` → `native-opt-in`. Notes column: append "Codex hooks port the four memory implementations via `.codex/config.toml.example`; `apply_patch` is the v1 hook-coverage surface; `Bash` writes are out of strict parity and caught by `.githooks/pre-commit` backstop; finalizer fallback for hook-disabled sessions." **Done when** grep `memory.*convention` returns no match in the Codex column.

- [x] 25. **Verify/extend `.claude/tools/sync-harness.sh` manifest globs** to cover `.agent0/hooks/*.sh`, `.agent0/tools/memory-*`, `.agent0/memory/.gitkeep`, `.agent0/memory.config.json`. Inspect current globs first (`grep -n "glob\|pattern\|manifest" .claude/tools/sync-harness.sh | head -20`); extend if needed. **Done when** dry-run sync from Agent0 to a fresh scratch consumer dir produces a manifest containing all the new paths.

- [x] 26. **Verify harness-sync baseline behavior for new `.agent0/*` files.** There is no upstream `.claude/harness-sync-baseline.json`; the baseline is consumer-local and written during sync. **Done when** the harness-sync suite passes and a dry-run/apply against a scratch consumer includes `.agent0/hooks/*.sh`, `.agent0/tools/memory-*`, `.agent0/memory/.gitkeep`, and `.agent0/memory.config.json`.

### Phase E — Consumer migration playbook

- [x] 27. **Write `docs/specs/099-memory-multi-runtime/migration-playbook.md`.** Ordered steps: (a) `git pull` to receive sync of new `.agent0/` files; (b) verify shims still work (existing setup unchanged); (c) decision point — migrate now or later; if now: (d) `git mv .claude/memory/*.md .agent0/memory/`; (e) move customized `.claude/memory.config.json` to `.agent0/memory.config.json`; (f) update consumer's `.claude/settings.json` hook paths from `.claude/hooks/memory-*.sh` → `.agent0/hooks/memory-*.sh`; (g) remove the 4 shim files at `.claude/hooks/memory-*.sh`; (h) verify with `bash .agent0/tools/memory-project.sh` + run existing `.claude/tests/harness-sync/*` suite; (i) commit. Include a rollback section and `mei-saas`/`codexeng` audit command. **Done when** playbook is self-contained (a consumer operator can follow without re-asking).

- [x] 28. **Document consumer customization pre-flight.** Include the exact audit command for `mei-saas` + `codexeng`: `git log --all --diff-filter=M -- .claude/hooks/memory-* .claude/tools/memory-* .claude/memory.config.json | head -30`. **Done when** migration-playbook.md records the audit command and says no consumer migration is executed by Agent0 spec 099 itself.

- Out of scope for this upstream implementation: execute manual migration in `mei-saas`. Do not push consumer migrations from spec 099 unless the operator asks for that follow-up explicitly.

- Out of scope for this upstream implementation: execute manual migration in `codexeng`. Do not push consumer migrations from spec 099 unless the operator asks for that follow-up explicitly.

## Verification

_Acceptance checks tied to spec.md acceptance criteria. Each maps to one or more scenarios in `spec.md § Acceptance criteria`._

- [x] **V1 — Codex hook-parity scenarios.** Feed synthetic Codex `apply_patch` hook payloads through the shared hooks: malformed frontmatter emits `memory-frontmatter-advisory:`; raw `.agent0/memory/MEMORY.md` patch blocks with exit 2 + corrective template + override grammar; valid entry patch regenerates MEMORY.md and writes `.agent0/.memory-events.jsonl` with `actor: "Codex CLI"`; decay hook direct run emits the expected frame. Covers spec scenarios 3, 4, 5, 6, 10.

- [x] **V2 — Shared scripts + config layout.** Inspect `.agent0/hooks/memory-*.sh` exist (4 files); grep `.claude/settings.json` shows registrations at `.agent0/hooks/` paths (4 hits); `.codex/config.toml.example` carries commented `[hooks]` block with `apply_patch` + `SessionStart` matchers pointing at `.agent0/hooks/memory-*.sh`. Covers spec scenarios 7, 8.

- [x] **V3 — Finalizer fallback.** Run `bash .agent0/tools/memory-maintain.sh finalize <path>` outside hook context and verify projection runs + entry is validated without writing a hook journal event. Covers spec scenario 9.

- [x] **V4 — Capability matrix.** Grep `.claude/rules/runtime-capabilities.md` `memory` row — verify Codex column == `native-opt-in`, Notes column carries the new prose. Covers spec scenario 11.

- [x] **V5 — Pre-commit drift backstop.** In a temp repo, edit a memory entry without running finalize and verify `.githooks/pre-commit` blocks with the corrective message; run finalize, re-stage MEMORY.md, and verify the hook passes. Covers spec scenario 12.

- [x] **V6 — AGENTS.md budget enforcement.** Run `bash .claude/tests/agents-memory-block-budget.sh` against current `AGENTS.md` → exits 0; the script carries distinct failure messages for missing block and over-budget block. Covers spec scenario 13.

- [x] **V7 — Migration playbook existence + completeness.** Verify `docs/specs/099-memory-multi-runtime/migration-playbook.md` exists; verify the ordered steps are present; verify `mei-saas` + `codexeng` audit notes are present. Covers spec scenario 14.

- [x] **V8 — Consumer migration playbook exists.** Verify `docs/specs/099-memory-multi-runtime/migration-playbook.md` exists, lists ordered migration steps, includes rollback, includes the `mei-saas`/`codexeng` customization audit command, and explicitly says Agent0 spec 099 does not execute downstream migrations.

- [x] **V9 — Trigger-list + entrypoint discovery.** Verify `AGENTS.md § Memory` lists the operational trigger list; verify `CLAUDE.md § Memory` block points at `.agent0/memory/`; verify both runtimes read the same `.agent0/memory/MEMORY.md` source (grep both entrypoints for the path). Covers spec scenarios 1, 2.

- [x] **V10 — Static facts.** Verify: `.claude/rules/memory-placement.md` has `## Multi-runtime usage` section with all 7 sub-topics; `.agent0/tools/memory-*` are shell-invocable from project root (`bash .agent0/tools/memory-project.sh`, `memory-query.sh decay --readout`, `memory-maintain.sh validate <path>`, `memory-maintain.sh finalize <path>`); tests cover advisory parity + projection idempotence + decay readout + AGENTS.md budget + pre-commit drift check (greppable as committed shell scripts in `.claude/tests/` or `.agent0/tests/`).

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._

- Task 1's live Codex `apply_patch` probe was replaced by a tolerant parser plus synthetic payload coverage because this Codex session was already running before the example hook config existed. A fresh-session live smoke remains a useful reviewer check, but the implementation does not depend on a single brittle field: it accepts `tool_input.command` first and defensive fallbacks after that.
- The compat-shims approach (task 9) is the load-bearing transitional-state decision from `plan.md § Alternatives considered`. If shims prove brittle or sync-harness misbehaves, escalate to user before falling back to hard cutover (Option B was explicitly rejected).
- Phase D tasks 21-22 (AGENTS.md + CLAUDE.md edits) are the propagation-advisory sensitive zone — both files ship to consumers. Run `grep` for `spec 099` / `docs/specs/099` / personal paths in the diff before commit (per `.claude/rules/propagation-advisory.md`).
- Consumer execution for `mei-saas` and `codexeng` is downstream follow-up work, not part of this upstream implementation.
- The shim-removal follow-up (after both consumers migrate) is OUT of scope for this spec; track via `notes.md` § next-actions for a `chore(099-followup)` commit.
