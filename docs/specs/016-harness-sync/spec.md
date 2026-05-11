# 016 — harness-sync

_Created 2026-05-11. Status: draft._

## Intent

Ship a one-way sync tool (`.claude/tools/sync-harness.sh <fork-path>`) that copies the current Agent0 harness state into a fork — hooks, rules, tools, validators, skills, `.mcp.json.example`, plus a careful structured merge of `.claude/settings.json` and `CLAUDE.md` capacity sections. The drift between Agent0 (specs 008+/011+/012+) and the three URL-shortener forks (pyshrnk / shrnk / rshrnk, all forked at ~001-007) blocks any meaningful dogfood of newer capacities and will recur every time Agent0 ships a new spec. The tool is **explicit and conservative**: dry-run is the default mode, fork-customized files are detected and preserved unless `--force`, product code (`src/`, `tests/` outside `.claude/tests/`) is never touched, settings.json is merged not replaced. Forks adopt newer capacities deliberately by running `sync-harness.sh --apply`; the harness writes the new files, the fork developer reviews the diff and commits.

## Acceptance criteria

- [ ] **Scenario: check mode lists drift**
  - **Given** a fork at `~/pyshrnk` missing `.claude/hooks/runtime-capture.sh` (and other 011 artifacts) plus the spec 008/009/012 set
  - **When** the user runs `bash .claude/tools/sync-harness.sh --check ~/pyshrnk` from the Agent0 repo
  - **Then** stdout lists each missing file (with absolute or relative path) and each file with a hash mismatch (drift signal); exit code is 0 if no drift, 1 if drift exists

- [ ] **Scenario: apply mode copies missing files**
  - **Given** a fork with the drift from scenario 1
  - **When** the user runs `bash .claude/tools/sync-harness.sh --apply ~/pyshrnk`
  - **Then** every missing file is copied (with mode preserved for executable hooks), the user sees a per-file `+ copied` line, and re-running `--check` shows zero missing files

- [ ] **Scenario: apply mode refuses to overwrite customized files**
  - **Given** a fork has edited `.claude/hooks/secrets-scan.sh` (a file shared with Agent0 but customized in the fork)
  - **When** the user runs `bash .claude/tools/sync-harness.sh --apply ~/fork`
  - **Then** the customized file is NOT overwritten; stderr emits `!! customized: <path>` and a diff hint; exit code is non-zero; the rest of the sync proceeds for un-customized files

- [ ] **Scenario: `--force` overrides customization protection**
  - **Given** the same setup as scenario 3
  - **When** the user runs `bash .claude/tools/sync-harness.sh --apply --force ~/fork`
  - **Then** the customized file IS overwritten with the Agent0 version, with a `! overwritten: <path>` warning line, exit code 0

- [ ] **Scenario: `--force-except=GLOB` preserves matching files under --force**
  - **Given** a fork with two customized files (`hookA.sh` and `.gitignore`) and the user wants to force-adopt drift-only Agent0 updates but preserve `.gitignore`
  - **When** the user runs `bash .claude/tools/sync-harness.sh --apply --force --force-except='.gitignore' ~/fork`
  - **Then** `hookA.sh` IS overwritten (`! overwritten`) but `.gitignore` is preserved (`!! customized` line still fires, file unchanged); exit non-zero because at least one file remained refused

- [ ] **Scenario: settings.json merge (additive, no replace)**
  - **Given** a fork's `.claude/settings.json` registers only specs 001-007 hooks (governance / delegation / secrets) and the user runs `--apply`
  - **When** the merge runs
  - **Then** the new hook entries (supply-chain-scan, runtime-pre-mark, runtime-capture, mcp-recipes-hint, etc.) are appended to the appropriate `PreToolUse` / `PostToolUse` / `SessionStart` arrays; existing entries are left untouched; entries already present are not duplicated

- [ ] **Scenario: CLAUDE.md capacity-section append**
  - **Given** the fork's `CLAUDE.md` is missing `## Supply chain`, `## Runtime introspect`, `## MCP recipes` sections
  - **When** apply runs
  - **Then** those sections are appended before `## Compact Instructions` (the canonical "always last" anchor); fork-authored sections (Overview / Stack / Conventions / Gotchas) are left untouched

- [ ] **Scenario: dry-run shows actions without performing them**
  - **Given** the fork has drift
  - **When** the user runs `bash .claude/tools/sync-harness.sh --apply --dry-run ~/fork`
  - **Then** stdout shows the same `+ copied` / `!! customized` / `~ merged` lines as a real apply, but no filesystem changes are made

- [ ] **Scenario: out-of-scope files never touched**
  - **Given** the fork has product code at `src/`, tests at `tests/` (NOT under `.claude/tests/`), and other top-level dirs (`docs/`, `node_modules/`, etc.)
  - **When** apply runs
  - **Then** nothing outside the harness scope (defined below) is read, written, or stat-checked; the fork's product code is invisible to the sync

- [ ] **Scenario: idempotent apply**
  - **Given** a fork that has just been synced (no drift)
  - **When** the user runs `--apply` again immediately
  - **Then** zero file operations occur; output shows `= up to date` per file scanned; exit code 0

- [ ] **Scenario: explicit `--agent0-path` arg (or env)**
  - **Given** the user runs the tool from a fork (not from Agent0 itself)
  - **When** the user runs `bash sync-harness.sh --agent0-path=/home/goat/Agent0 --apply ~/another-fork`
  - **Then** the tool uses the explicit path as the source; if no `--agent0-path` and no `AGENT0_HARNESS_PATH` env, the tool refuses to guess and exits with a usage hint

- [ ] **Scenario: `.mcp.json.example` synced; `.mcp.json` never touched**
  - **Given** a fork with a customized `.mcp.json` (developer's own active MCP config) but no `.mcp.json.example`
  - **When** apply runs
  - **Then** `.mcp.json.example` is copied from Agent0; `.mcp.json` is left exactly as-is (treated as developer-owned secret-adjacent config)

- [ ] `.claude/tools/sync-harness.sh` exists, is executable, supports `--check` / `--apply` / `--dry-run` / `--force` / `--agent0-path` flags
- [ ] `.claude/rules/harness-sync.md` documents the tool: scope, modes, customization-detection algorithm, merge strategy for settings.json + CLAUDE.md
- [ ] CLAUDE.md gains `## Harness sync` block linking to the rule doc
- [ ] Tests under `.claude/tests/harness-sync/` cover all scenarios above using tmp-dir fixtures

## Non-goals

- **Bidirectional sync** (fork → Agent0). v1 is one-way only. Forks contributing improvements back to Agent0 do so via PR review, not auto-sync.
- **Auto-detection of Agent0 path.** Must be explicit (`--agent0-path` or `AGENT0_HARNESS_PATH`). Guessing leads to wrong-source syncs.
- **`core.hooksPath` activation** in the fork. That step is manual per `.claude/rules/secrets-scan.md` § Gotchas (Lazarus vector). The fork developer runs `git config core.hooksPath .githooks` themselves after the sync if they want gitleaks active.
- **Auto-commit in the fork.** The sync writes files; the fork developer reviews `git diff` and commits manually. Same posture as every other harness primitive (audit-log writes, etc.).
- **Per-spec selective sync** (`--spec=011,012`). v1 syncs the full harness; partial syncs introduce drift complexity (e.g. spec 011 hook present but spec 011 rule doc missing). Revisit in v2 if real demand surfaces.
- **YAML/TOML parsing**. settings.json (JSON) and `.gitignore` (line-based) suffice. We don't touch `.githooks/pre-commit` content (kept identical via hash check, not parsed) or `.gitleaks.toml` (TOML — hash check only).
- **Cross-fork comparison** (`sync-harness diff ~/forkA ~/forkB`). Out of scope; users use `diff -r` directly.
- **Performance optimization.** Sync runs at developer command, not in a hot loop. A 5-second sync is acceptable.
- **GUI / interactive mode.** Pure CLI, scripted.

## Open questions

- [ ] **Customization detection algorithm** — proposal: hash-compare current file content against the Agent0 version. If the fork's hash differs AND the file existed before this sync run, treat as customized (refuse without `--force`). If the file doesn't exist, treat as missing (copy without prompt). Confirm vs. alternative: track an Agent0-commit-marker in the fork (more invasive).
- [ ] **CLAUDE.md merge granularity** — proposal: identify capacity sections by `^## <Title>` heading and append missing ones immediately before `## Compact Instructions`. If a fork has renamed sections, the tool won't match and will warn. Confirm vs. token-based parsing (more complex).
- [ ] **Harness scope definition** — proposal table (v1):
  - **Always sync (no customization check):** `.claude/skills/sdd/templates/` (template files; never customized in forks).
  - **Sync with customization check:** `.claude/hooks/*.sh`, `.claude/rules/*.md`, `.claude/tools/*.sh`, `.claude/validators/*.sh`, `.claude/agents/` (if present), `.mcp.json.example`, `.gitleaks.toml`, `.githooks/pre-commit`, `.gitignore`.
  - **Structured merge:** `.claude/settings.json`, `CLAUDE.md`.
  - **NEVER touched:** anything under `src/`, `tests/` (outside `.claude/tests/`), `docs/`, `target/`, `node_modules/`, `.venv/`, `dist/`, `build/`, fork-only `.git*` files (`.gitattributes`, etc.), `package.json`, `Cargo.toml`, `pyproject.toml`, `.env*`, `.mcp.json`.
  Confirm this list captures the right boundary.
- [ ] **What about test files in `.claude/tests/`?** — proposal: sync them (they ARE part of the harness — RED→GREEN scenarios that future syncs need to verify the harness still works). Same customization check as hooks. Forks running their own tests against the harness benefit from up-to-date scenarios.

## Context / references

- The drift discovered 2026-05-11: pyshrnk / shrnk / rshrnk all forked at ~Agent0 spec 001-007 state, missing all later capacities (008-012). Dogfood for specs 011+012 blocked until shrnks are synced.
- Spec 011 (`docs/specs/011-runtime-introspect/`) — the canonical reason this drift hurts: dogfood can't validate.
- Spec 012 (`docs/specs/012-mcp-recipes/`) — same.
- `.claude/rules/spec-driven.md` § Workflow — every Agent0 spec ships docs-only by default; the propagation to forks has been manual until now. This spec closes the gap.
- Memory: `project_agent0_purpose.md` — Agent0 is the user's generic base repo for new projects; the forks ARE the test-bed that proves it works. Syncing is part of "being a good base".
- Similar tooling references (informational):
  - Cookiecutter / cruft (Python template sync — concept inspiration)
  - `dotbot` (dotfile sync)
  - `nix-darwin` declarative sync (overkill but conceptually related)
