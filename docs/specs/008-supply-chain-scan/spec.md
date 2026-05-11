# 008 — supply-chain-scan

_Created 2026-05-11. Status: draft._

## Intent

A capacity that surfaces dependency-manifest mutations as a privileged action so they leave an audit trail and (optionally) a friction point. Same threat model as the manual `core.hooksPath` install step: dependency-confusion / typosquat / poisoned-package attacks (the Lazarus-2025 "Contagious Interview" pattern continues to be the canonical reference) start with a single line of change — `npm install <something-that-looks-real>` — and the harness today has zero visibility into when an LLM agent reaches for that line. This capacity closes the gap with a hook pair that mirrors the secrets-scan two-layer shape: a `PreToolUse(Bash)` preflight that detects dep-mutating commands across the major package managers, plus a `PostToolUse(Edit|Write|MultiEdit)` advisory on sub-agent edits to dependency manifest files. Both write a JSONL audit row; the override marker records intent.

First iteration is **advisory-only** (no blocking) — the audit log + the stderr advisory line are the discipline. Blocking modes (new-dep-requires-override, registry pinning, lockfile-signature verification) are deferred non-goals (§ *Non-goals*). The advisory is sub-agent-only on the Edit/Write side (mirrors `.claude/rules/secrets-scan.md` § *Soft advisory* actor-split — parent edits are observable by the user directly so the advisory is dead weight for them).

## Acceptance criteria

- [ ] **Scenario: Bash dep-install triggers advisory + audit**
  - **Given** an agent runs `npm install axios` (or any dep-mutating command in the manager set)
  - **When** the `PreToolUse(Bash)` hook fires
  - **Then** one `supply-chain-advisory: <manager> <action> — <packages>` line lands on stderr, one audit row is appended to `.claude/supply-chain-audit.jsonl` with `decision: "advisory"`, `manager: "npm"`, `action: "install"`, `packages: ["axios"]`, and the command proceeds (exit 0)

- [ ] **Scenario: non-dep Bash command audits skip and falls through silently**
  - **Given** a Bash command like `npm test`, `npm run build`, or anything not in the dep-mutation pattern set
  - **When** the `PreToolUse(Bash)` hook fires
  - **Then** no stderr output, one audit row with `decision: "skip-not-install"` (forensic completeness, mirrors the secrets-scan preflight's `skip-not-commit`)

- [ ] **Scenario: sub-agent Edit on dep manifest triggers advisory**
  - **Given** a delegated sub-agent edits `package.json` to add `"axios": "^1.6.0"` in the `dependencies` block (`agent_id` populated in the payload)
  - **When** the `PostToolUse(Edit|Write|MultiEdit)` hook fires
  - **Then** one `supply-chain-advisory: edit <manifest> — manifest may have new dep` line on stderr, one audit row with `decision: "advisory"`, `scope: "edit"`, `file: "package.json"`, and the edit is not reverted (advisory only)

- [ ] **Scenario: parent edit on dep manifest passes through silently**
  - **Given** the parent agent (not a delegated sub-agent — `agent_id` absent from payload) edits `package.json`
  - **When** the `PostToolUse(Edit|Write|MultiEdit)` hook fires
  - **Then** no advisory, no audit row (the agent_id actor-split, mirrored from `.claude/rules/delegation.md` § *Post-edit validator loop*)

- [ ] **Scenario: override marker recorded in audit, advisory suppressed**
  - **Given** a two-line Bash command — line 1 is `npm install axios`, line 2 is `# OVERRIDE: documented chart-library upgrade per discussion in conversation` (marker on its own line, start-of-line anchored — same shape as `secrets-scan.sh` override grammar; inline trailing markers are NOT accepted)
  - **When** the `PreToolUse(Bash)` hook fires
  - **Then** no stderr advisory line; one audit row with `decision: "advisory-override"` and `override_reason: "documented chart-library upgrade per discussion in conversation"`; command proceeds

- [ ] **Scenario: short override reason silently drops the marker (still advises)**
  - **Given** a two-line Bash command with line 2 `# OVERRIDE: ok` (reason < 10 chars after trim)
  - **When** the `PreToolUse(Bash)` hook fires
  - **Then** the marker is dropped (no env-var propagation, no `override_reason` populated); the advisory fires as if no marker were present; audit row records `decision: "advisory"` with `override_reason: null`. No stderr error about the short reason — supply-chain is advisory-only, so an invalid override silently degrades to the normal advisory path rather than blocking with a corrective stderr template (which is the secrets-scan preflight's pattern because it has shape-rejection semantics)

- [ ] **Scenario: env-var disables both layers**
  - **Given** `CLAUDE_SKIP_SUPPLY_CHAIN_SCAN=1` is set in the agent's environment
  - **When** either hook fires for any matcher
  - **Then** the hook exits 0 silently — no advisory, no audit row

- [ ] **Scenario: missing package-manager binary still produces an audit row**
  - **Given** the detected manager (e.g. `pnpm`) is not on `PATH`
  - **When** the `PreToolUse(Bash)` hook fires on a `pnpm add foo` command
  - **Then** the hook does NOT depend on the manager binary being present — detection is regex-only against the command string; audit row written normally (the hook never invokes the manager)

- [ ] `.claude/hooks/supply-chain-scan.sh` exists, is executable, registered on `PreToolUse(Bash)` matcher in `.claude/settings.json`
- [ ] `.claude/hooks/supply-chain-advise.sh` exists, is executable, registered on `PostToolUse(Edit|Write|MultiEdit)` matcher in `.claude/settings.json`
- [ ] `.claude/supply-chain-audit.jsonl` is gitignored, append-only, `flock`-atomic — same shape as `.claude/secrets-audit.jsonl`
- [ ] `.claude/rules/supply-chain.md` documents the capacity (audit decision values, override grammar, env var, list of detected manager patterns, gotchas)
- [ ] CLAUDE.md gains a `## Supply chain` section mirroring the `## Secrets scan` section structure
- [ ] README capacity table gains a row for `Supply chain scan`

## Non-goals

- **Blocking installs.** First iter is advisory-only. A future spec can add a "new-top-level-dep requires `# OVERRIDE:`" gate, but the friction model for that is more contentious than the audit/advisory pattern and shouldn't gate landing this one.
- **Registry pinning / signature verification.** Sigstore lookup, npm provenance, PyPI trusted publishers — all out of scope. These are detection-of-tampering features that belong in a hypothetical `supply-chain-verify` spec, not this one.
- **Distinguishing new top-level deps from version bumps.** Both treated the same. A future spec could check the lockfile diff to differentiate; this iter just records the action.
- **Per-package allowlist / blocklist.** No `.supplychain.toml` or similar config file. Trust is documented per commit via the override marker.
- **Multi-package install row-splitting in the audit log.** One audit row per Bash command, all packages in one `packages` array field. Forensic queries can split via `jq` if needed.
- **CI mirror.** Local-only enforcement, matching the secrets-scan and governance-gate convention.
- **`npm install` / `pip install` with no arguments.** Those resolve from manifest, don't mutate it — not a supply-chain action.
- **Hatch / Spack / Bazel / other niche package managers.** Iter 1 covers the major ones (see § *Open questions*); fork-specific managers can be added later.

## Context / references

- Lazarus 2025 "Contagious Interview" attack pattern context: documented in `.claude/rules/secrets-scan.md` § *Gotchas* under the `core.hooksPath` MANUAL design rationale
- Sibling capacity for shape: `docs/specs/006-secrets-scan/` (original) and `docs/specs/007-secrets-scan-timing/` (two-layer model). This spec inherits the JSONL audit + override marker + env-var-disable primitives from there.
- The five existing gates use the `# OVERRIDE: <reason ≥10 chars>` shape — supply-chain-scan adopts it unchanged.
