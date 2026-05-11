# 008 — supply-chain-scan — plan

_Drafted from `spec.md` on 2026-05-11. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Two new hook scripts mirror the `secrets-scan{,advise}.sh` pair: a `PreToolUse(Bash)` preflight that parses `tool_input.command` for dep-install shapes across 10 package managers, and a `PostToolUse(Edit|Write|MultiEdit)` advisory that fires on sub-agent edits to a fixed list of manifest/lockfile basenames. Both write a JSONL audit row to `.claude/supply-chain-audit.jsonl` with `flock`-atomic appends. Override marker grammar is unchanged from the existing gates (`# OVERRIDE: <reason ≥10 chars>`, start-of-line anchored). Env var `CLAUDE_SKIP_SUPPLY_CHAIN_SCAN=1` disables both layers — symmetric with `CLAUDE_SKIP_SECRETS_SCAN`.

The Bash preflight uses `[[ "$cmd" =~ ... ]]` per manager to detect install/add/update verbs followed by at least one non-flag positional argument. Packages are extracted from the matched argument list by filtering tokens that start with `-`. Multi-package commands result in one audit row with all packages in a `packages: [...]` array — never one row per package. The stderr advisory is one line: `supply-chain-advisory: <manager> <action> — <packages>`. The override marker, when valid, suppresses the stderr line and records `decision: "advisory-override"` with `override_reason` in the audit row; when too short, the marker is dropped and the advisory fires normally.

The Edit/Write advisory checks `tool_input.file_path`'s basename against a fixed allowlist (`package.json`, `pyproject.toml`, `requirements.txt`, `Cargo.toml`, `go.mod`, plus the canonical lockfile siblings). Sub-agent only — the actor-split keys on the presence of `agent_id` in the stdin payload, mirroring `secrets-advise.sh` and the post-edit validator. Parent edits pass through silently, no audit row. The advisory line is `supply-chain-advisory: edit <basename> — manifest may have new dep`. We deliberately do NOT parse the edit's actual diff to determine "is this a real dep change or a comment edit" — that's runtime cost without enough signal at this iteration's advisory-only nature.

Implementation order is dependency-respecting: (1) ship the Bash preflight including the audit primitive (`flock` writer + JSON construction via `jq`); (2) ship the Edit/Write advisory reusing the same audit primitive shape; (3) `.gitignore` the audit log; (4) register both hooks in `settings.json`; (5) write the rule doc, CLAUDE.md section, README capacity row; (6) write seven scenario test scripts under `.claude/tests/supply-chain/` (mirroring `.claude/tests/secrets-scan/` shape and reusing its `AGENT0_ROOT` convention).

## Files to touch

**Create:**
- `.claude/hooks/supply-chain-scan.sh` — PreToolUse(Bash) preflight, ~200 LOC
- `.claude/hooks/supply-chain-advise.sh` — PostToolUse(Edit|Write|MultiEdit) advisory, ~80 LOC
- `.claude/rules/supply-chain.md` — rule doc (capacity overview, decision values table, override grammar, manager-pattern reference table, gotchas)
- `.claude/tests/supply-chain/run-all.sh` — test runner, mirror of the secrets-scan runner
- `.claude/tests/supply-chain/01-bash-install-advisory.sh` — scenario 1 (Bash install → advisory + audit)
- `.claude/tests/supply-chain/02-skip-not-install.sh` — scenario 2 (non-dep Bash command → skip audit)
- `.claude/tests/supply-chain/03-edit-manifest-advisory.sh` — scenario 3 (sub-agent edit to manifest → advisory)
- `.claude/tests/supply-chain/04-parent-edit-silent.sh` — scenario 4 (parent edit to manifest → silent)
- `.claude/tests/supply-chain/05-override-marker.sh` — scenarios 5 + 6 (valid override + short-reason rejection)
- `.claude/tests/supply-chain/06-env-var-disable.sh` — scenario 7 (`CLAUDE_SKIP_SUPPLY_CHAIN_SCAN=1` silences both layers)

**Modify:**
- `.claude/settings.json` — append `PreToolUse(Bash)` + `PostToolUse(Edit|Write|MultiEdit)` hook entries
- `.gitignore` — add `.claude/supply-chain-audit.jsonl` + lock sibling
- `CLAUDE.md` — add `## Supply chain` section mirroring `## Secrets scan` structure (~10 lines)
- `README.md` — add `Supply chain scan` row to the capacity table

**Delete:** _none_

## Alternatives considered

### "Big 3" managers only (`npm` / `pip` / `cargo`)

Rejected — framework cost is identical whether we ship 3 or 10 manager regexes. Each additional manager is one regex line. Limiting to 3 leaves pnpm/yarn/bun (JS), uv/poetry/pdm (Python), and Go-modules without coverage, which is half the actual user base. Ship all 10.

### Shape-rejection (blocking) on dep-install commands without override

Rejected for iter 1. `npm install` is a much more frequent action than `git commit`; a blocking preflight would interrupt every iteration loop and create exactly the friction we just avoided with the advisory shape of `secrets-advise`. The audit log is the discipline; the override marker exists for when a user wants the action explicitly recorded as deliberate. A follow-up spec (e.g. `009-supply-chain-block`) can add this if usage shows the advisory isn't enough.

### Glob-walking in the Edit/Write hook (e.g. `**/package.json`)

Rejected. Forks with `tests/fixtures/pkg-with-bad-deps/package.json` (legitimate fixture content) would trigger advisories during routine fixture edits. Exact-basename match gives ~95% of the signal at 0% false-positive cost. Forks with weird layouts can extend via env var later if needed.

### Lockfile-diff parsing to distinguish new deps from version bumps

Rejected — running `git diff HEAD~1 -- package-lock.json | jq` per hook firing is expensive and brittle (lockfile shapes vary across npm/pnpm/yarn versions and break across major releases). For iter 1 both shapes are advisory and get the same audit row.

### One audit row per package on multi-package installs

Rejected. `npm install foo bar baz` produces one Bash invocation but three packages; storing three rows would either share a non-unique key or invent one. Easier path: one row, `packages: ["foo", "bar", "baz"]` field. `jq` post-processing can split if a forensic query needs it.

## Risks and unknowns

- **False negatives on flag-heavy commands.** Detection requires at least one non-flag token after the verb. Most real installs satisfy this (`npm install foo`, `npm install --save-dev foo`, `npm i -D foo`). Edge case: `npm install -- foo` (using `--` as flag/arg separator) might not match cleanly depending on how the regex handles `--`. Acceptable false negative for iter 1; advisory-only doesn't need 100% recall.
- **`npm install` / `bun install` with no args = resolve from lockfile, not a mutation.** Detection requires at least one positional arg after the verb. Covered by scenario 2 in `tests/supply-chain/02-skip-not-install.sh`.
- **`go get` deprecated for non-module usage but still works for module dep adds.** Pattern stays since Go modules behavior is documented and stable.
- **Audit-log growth in CI-style runs.** A dev iterating with `npm install` repeatedly writes one row per invocation. Acceptable; one-line JSONL appends are cheap (< 4096 bytes per row, atomic on Linux).
- **Override marker on `npm install foo  # OVERRIDE: ...`.** Detection regex must strip `# ...` from the package extraction step before assembling the `packages: [...]` array — otherwise the audit could include `# OVERRIDE:` and the reason as if they were package names. Mirror the secrets-scan preflight's marker-extraction-first ordering.
- **Hook latency.** Two more hooks fire on every Bash invocation and every Edit/Write. Negligible (~5-20ms each), but a fork running thousands of edits in a session pays it cumulatively. Watch in real-world use; if friction surfaces, the env-var-disable is the escape valve.

## Research / citations

- `npm install` flags reference: <https://docs.npmjs.com/cli/v10/commands/npm-install>
- `pnpm add` reference: <https://pnpm.io/cli/add>
- `yarn add` reference: <https://classic.yarnpkg.com/en/docs/cli/add>
- `bun add` reference: <https://bun.sh/docs/cli/add>
- `pip install` reference: <https://pip.pypa.io/en/stable/cli/pip_install/>
- `uv add` reference: <https://docs.astral.sh/uv/concepts/projects/dependencies/>
- `poetry add` reference: <https://python-poetry.org/docs/cli/#add>
- `pdm add` reference: <https://pdm-project.org/latest/usage/dependency/>
- `cargo add` reference: <https://doc.rust-lang.org/cargo/commands/cargo-add.html>
- `go get` modules behavior: <https://go.dev/ref/mod#go-get>
- Sibling implementation reused for primitives: `.claude/hooks/secrets-scan.sh` (preflight shape gate, override parsing, audit log) and `.claude/hooks/secrets-advise.sh` (PostToolUse Edit|Write|MultiEdit, sub-agent actor split)
- Lazarus 2025 "Contagious Interview" attack pattern context: `.claude/rules/secrets-scan.md` § *Gotchas* under the `core.hooksPath` MANUAL design rationale
