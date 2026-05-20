# 059 — `/product` Phase 0 harness-aware non-empty check

_Created 2026-05-19._

**Status:** shipped

## Problem

`/product` Phase 0 idempotency check (`SKILL.md` § Phase 0) declares any non-empty `--out` dir as "already used" and prompts overwrite-or-abort. The natural founder workflow — `mkdir mei-saas && cd mei-saas && sync-harness` (install Agent0) THEN `/product --out=.` (generate product) — fails this check, because the harness install populates `.claude/`, `.githooks/`, `.gitignore`, `.gitleaks.toml`, `.mcp.json.example`, `CLAUDE.md`, `.git/` BEFORE `/product` runs.

Responding `y` to the overwrite prompt runs `rm -r <out>` which **wipes the just-installed harness**. Responding `n` aborts without progress. The skill was designed assuming `--out` is empty or holds a prior `/product` run's artifacts — not a freshly-bootstrapped Agent0 fork.

Empirical trigger 2026-05-19: founder bootstrapping mei-saas (a real product, full roadmap Fases 1-8) wanted Agent0-disciplined-from-day-1, i.e. harness IN the project before any code. Workflow blocked. Workaround discussed in conversation: forge `docs/.state.json` + `--from-step=01` (brittle — slug computation isn't deterministic from outside). Better fix: teach Phase 0 to ignore Agent0 harness paths when checking non-empty.

## Acceptance criteria

- [x] **Scenario: empty `<out>` → existing fresh-run path**
  - **Given** `<out>` does not exist OR exists but contains zero files
  - **When** `/product` Phase 0 runs
  - **Then** skill proceeds to Phase 0 step 2 (Init) without prompting

- [x] **Scenario: `<out>` contains only Agent0 harness paths → treat as fresh**
  - **Given** `<out>` contains a subset of `{.claude/, .githooks/, .gitignore, .gitleaks.toml, .mcp.json.example, CLAUDE.md, .git/}` and nothing else
  - **When** `/product` Phase 0 runs
  - **Then** skill proceeds to Phase 0 step 2 (Init) without prompting; no `rm -r`; harness preserved

- [x] **Scenario: `<out>` contains `/product` artifacts → existing overwrite logic**
  - **Given** `<out>` contains `docs/` OR `app/` OR `package.json` OR any path outside the harness allowlist
  - **When** `/product` Phase 0 runs without `--from-step`
  - **Then** prompt `<out> exists and is non-empty. Overwrite? (y/N) ▷` — preserving spec 048 semantics for prior `/product` runs

- [x] **Scenario: `--from-step=NN` resume with harness present → existing resume path** *(verified by inspection — empirical run gated on mei-saas founder /product invocation; see notes.md)*
  - **Given** `<out>/docs/.state.json` exists with valid v4 shape AND `<out>` also contains Agent0 harness paths
  - **When** `/product` runs with `--from-step=NN`
  - **Then** state validation runs as today (version + slug + idea + flags.stack match); on pass, skill jumps to step NN; harness paths are transparent to the validation logic

- [x] **Scenario: `/product` writes `.gitignore` over existing harness `.gitignore` → append, don't replace**
  - **Given** `<out>/.gitignore` already exists (from Agent0 harness)
  - **When** `/product` scaffolds the Next.js / Expo project and would write `.gitignore`
  - **Then** the new rules are appended to the existing file under a `# --- /product (Next.js) ---` marker line; Agent0's existing rules (e.g. `.claude/.runtime-state/`) are preserved verbatim above the marker

- [x] `.claude/skills/product/SKILL.md` § Phase 0 step 1 lists the Agent0 harness allowlist explicitly so future contributors can see the exempt set without reading spec 059

## Non-goals

- **Surgical `rm -r`** that preserves harness when re-running `/product` on a `<out>` with BOTH harness AND prior `/product` artifacts. The full `rm -r <out>` is preserved for this case (covered by spec 048's existing behavior). User re-bootstraps via `sync-harness.sh` after the rm if needed. Surgical rm is a follow-up spec when empirically needed.
- **Configurable harness allowlist.** The 7-path list is hardcoded in SKILL.md per sync-harness manifest. Forks extending the harness handle drift themselves.
- **Auto-merging `CLAUDE.md`** when `/product` writes its own. Spec 058 (claude-md-managed-block) covers harness-side merging; `/product` does NOT write CLAUDE.md today, so no conflict to handle.
- **Validator/hook changes.** Phase 0 changes are SKILL.md prose only — model-orchestrated, no shell code.

## Open questions

1. Is the harness allowlist `{.claude/, .githooks/, .gitignore, .gitleaks.toml, .mcp.json.example, CLAUDE.md, .git/}` complete? Audit sync-harness manifest at implementation time and lock the list to that.
2. Should the `.gitignore` append-marker be `# --- /product (Next.js) ---` (verbose) or `# /product` (terse)? Verbose chosen for grepability; revisit if forks complain.
3. What if a founder has manually-edited files at `<out>/` root (e.g. `IDEAS.md`) that are NOT harness AND NOT `/product` output? Current spec treats them as `/product` artifacts → triggers overwrite prompt. Acceptable: founder gets a chance to abort. Surgical rm would handle this better but is out of scope (see Non-goals).
