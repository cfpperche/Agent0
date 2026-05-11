# Supply chain

A two-layer capacity that surfaces dependency-manifest mutations as a privileged action so they leave an audit trail and a (soft) friction point. Spec: `docs/specs/008-supply-chain-scan/`.

**This is an advisory-only capacity.** It never blocks. The audit log + stderr advisory line ARE the discipline — agents that read advisories on their next turn become aware of dep mutations they would otherwise smuggle past review. A future spec can add blocking semantics if the advisory proves insufficient; the override marker grammar is already wired up to support that transition.

## What fires, what advises

**Bash preflight — `PreToolUse(Bash)` → `.claude/hooks/supply-chain-scan.sh`.** Tokenises `tool_input.command` and looks for `(manager, verb, packages)` triples across 10 package managers. On match → audits `decision: "advisory"` (or `advisory-override` when a valid `# OVERRIDE:` marker is present), emits `supply-chain-advisory: <manager> <action> — <packages>` on stderr (suppressed when override is valid). On no match → audits `decision: "skip-not-install"` for forensic completeness (mirrors `secrets-scan.sh`'s `skip-not-commit` row-per-bash discipline; the audit log is gitignored, growth is acceptable). Always exits 0.

**Edit/Write advisory — `PostToolUse(Edit|Write|MultiEdit)` → `.claude/hooks/supply-chain-advise.sh`.** Sub-agent only — exits 0 silently for parent edits (the `agent_id` actor-split, mirrored from `.claude/rules/delegation.md` § *Post-edit validator loop* and `.claude/rules/secrets-scan.md` § *Soft advisory*). On a delegated edit, takes the basename of `tool_input.file_path` and compares against a fixed allowlist of manifest + lockfile names (no glob walking — exact basename match only). On match → audits `decision: "advisory"`, `scope: "edit"`, `file: "<basename>"`; emits `supply-chain-advisory: edit <basename> — manifest may have new dep` on stderr. On non-match → exits 0 silently, no audit row.

## Manager detection table

Each row: manager → matched verb whitelist → example command. Detection requires at least one non-flag positional argument after the verb — `npm install` (no args) is a lockfile resolve, not a mutation, so it audits as `skip-not-install`.

| Manager | Verbs detected | Example |
| --- | --- | --- |
| `npm` | `install`, `i`, `add`, `update`, `upgrade` | `npm install axios` |
| `pnpm` | `install`, `i`, `add`, `update`, `up` | `pnpm add axios` |
| `yarn` | `add` | `yarn add axios` |
| `bun` | `install`, `i`, `add`, `update` | `bun add axios` |
| `pip` | `install` | `pip install axios` |
| `uv` | `add` | `uv add axios` |
| `poetry` | `add` | `poetry add axios` |
| `pdm` | `add` | `pdm add axios` |
| `cargo` | `add`, `update` | `cargo add tokio` |
| `go` | `get` | `go get example.com/mod` |

Detection is tokenisation-based, not regex anchored to start-of-line: `python -m pip install foo` matches (the `pip install foo` substring is found mid-command). Chained commands work too: `git push && npm install foo` triggers on the second half.

## Manifest+lockfile basename allowlist

The Edit/Write hook fires on exact basename match against:

- **JS/TS**: `package.json`, `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `bun.lock`, `bun.lockb`
- **Python**: `pyproject.toml`, `requirements.txt`, `uv.lock`, `poetry.lock`, `pdm.lock`
- **Rust**: `Cargo.toml`, `Cargo.lock`
- **Go**: `go.mod`, `go.sum`

No glob walking — `tests/fixtures/pkg-with-bad-deps/package.json` matches because the basename is `package.json`, regardless of containing directory. This is deliberate: forks that fixture-test manifests will trip the advisory occasionally; the cost (one stderr line) is lower than the alternative (false negatives on real edits to fixture-named manifests in production paths).

## Override grammar

A line in `tool_input.command` matching `^[[:space:]]*# OVERRIDE: <reason>` skips the advisory and records `decision: "advisory-override"` with `override_reason` populated in the audit row. **Start-of-line anchored** (with optional leading whitespace) — identical shape to the secrets-scan preflight. Inline-trailing markers on a single line are NOT accepted; that re-opens the spec-002 false-positive where `# OVERRIDE:` inside a quoted string was matching. Use a **two-line Bash command** form:

```bash
npm install axios
# OVERRIDE: documented chart-library upgrade per discussion in conversation
```

Bash treats line 2 as a no-op comment when the command actually runs; the hook sees line 2 as start-of-line text and matches.

`<reason>` must be ≥10 characters after trim. **Short reasons silently degrade** to the plain advisory path (no corrective stderr template). This is deliberately softer than the secrets-scan preflight, which exits 2 with a corrective template for too-short reasons — secrets-scan is a blocking gate, supply-chain is advisory-only, so a too-short reason on supply-chain just means "the override didn't take, the advisory fires normally". The 10-char floor matches the governance / delegation / secrets gates for consistency.

There is no env-var bridge for this hook (unlike `CLAUDE_SECRETS_OVERRIDE_REASON`): the override marker affects ONLY the audit row's decision value. No downstream layer needs to read it.

## Escape hatch

`CLAUDE_SKIP_SUPPLY_CHAIN_SCAN=1` in the environment makes both hooks (Bash + Edit/Write) exit 0 silently — no scan, no audit entry. Use for throwaway scratch sessions or when the advisory volume is overwhelming during a focused dep-management session. Setting the variable in a long-lived shell config disables the discipline permanently and silently — wrong escape; the override marker is the right tool for "this one install needs to land deliberately".

There is no separate env var for the Edit/Write side (unlike the secrets-scan family's `CLAUDE_SECRETS_ADVISE_ON_EDIT`). Both layers are ON by default. The friction is low (one stderr line + one audit row per match); if even that proves too noisy, the single `CLAUDE_SKIP_SUPPLY_CHAIN_SCAN=1` switch turns the whole capacity off.

## Audit log

`.claude/supply-chain-audit.jsonl`, gitignored, append-only, `flock`-atomic. Every Bash hook invocation writes exactly one line (even `skip-not-install` cases — forensic completeness). Every Edit/Write hook invocation that matches the manifest list writes one line; non-matches and parent-edits write nothing.

| Decision | Scope | Meaning |
| --- | --- | --- |
| `skip-not-install` | `bash` | Bash command does not contain a recognised `<manager> <verb> <packages>` triple |
| `advisory` | `bash` | Dep-install detected, no valid override marker; stderr line emitted |
| `advisory-override` | `bash` | Dep-install detected + valid override marker; no stderr; `override_reason` populated |
| `advisory` | `edit` | Sub-agent Edit/Write/MultiEdit on a manifest-or-lockfile basename; `file` field names the basename |

Common fields across all rows: `ts` (ISO 8601 UTC), `session_id` (or `null`), `agent_id` (or `null`). Bash rows additionally carry `manager`, `action`, `packages` (array, possibly null on skip rows), `override_reason` (string or null). Edit rows carry `scope: "edit"` and `file: "<basename>"`. Read with `jq -c .` or `tail -f`.

## Gotchas

- **`npm install` with no args is NOT a mutation.** Detection requires at least one non-flag positional argument after the verb. `npm install` alone (lockfile resolve) audits as `skip-not-install`. Same for `bun install`, `pdm install`, `poetry install`, etc.
- **Flag-only commands are also skipped.** `pip install --help` collects no packages → falls through to `skip-not-install`. Acceptable — those aren't real installs.
- **`pip install -r requirements.txt` records `requirements.txt` as a package name.** False positive on the package extraction (it's a file, not a package), but the advisory still fires correctly and forensics can disambiguate by reading the `packages` field.
- **Override marker must NOT trail inline.** Single-line `npm install foo  # OVERRIDE: ...` does NOT match the start-of-line anchor; the marker is missed and the standard advisory fires. Use the two-line shape (`npm install foo\n# OVERRIDE: ...`). The exact same trap was documented for secrets-scan; the rationale (false-positive on quoted strings containing `# OVERRIDE:`) carries over.
- **Edit/Write hook does NOT parse the actual diff.** A sub-agent that edits the licence header of `package.json` triggers the advisory the same as one that adds a new dep. False positives are accepted because the alternative (lockfile-diff parsing per hook firing) is expensive and brittle across manager versions.
- **Audit-log volume on the Bash side is HIGH.** Every Bash invocation writes a `skip-not-install` row when no install pattern matches. A session that runs hundreds of `ls`/`cat`/`git status` calls produces hundreds of rows. The log is gitignored and one-line JSONL appends are cheap, but if forensics becomes painful, the `jq -c '. | select(.decision != "skip-not-install")'` filter strips the noise.
- **Hook latency adds up.** Two more hooks fire on every Bash + every Edit/Write/MultiEdit. Each adds ~10-30ms. For agents iterating quickly, cumulative cost matters. If friction surfaces, `CLAUDE_SKIP_SUPPLY_CHAIN_SCAN=1` is the per-session disable.
- **Tokenisation does NOT respect quoting.** `pip install "foo[extras]"` would split `"foo[extras]"` as the package (string preserved by the shell, but the hook sees the token before shell processing). Edge case for iter 1; advisory fires correctly with the quoted string in the packages array, which is forensically usable.
- **`#`-starting tokens terminate the package list.** Useful: the override-marker line (line 2 of a multi-line command) gets tokenised but `#` ends package collection. Risk: a package legitimately starting with `#` (none in any manager's namespace) would be cut off; not a real-world concern.
- **`uv pip install <pkg>` is treated as a `pip` install, not a `uv` action.** The tokeniser sees `uv pip install foo`: at index 0 `uv` matches the manager set but its verb whitelist is `add` only — `pip` is not in `uv`'s verbs, so the manager+verb check fails. Continuing, at index 1 `pip` matches and its verb `install` follows. Result: detected as `pip install foo`. Acceptable; the audit shows `manager: "pip"` rather than `manager: "uv"` but the user intent is preserved.
