# 009 — supply-chain-block

_Created 2026-05-11._

**Status:** shipped

## Intent

Promote the supply-chain Bash preflight (spec 008 `PreToolUse(Bash)` → `.claude/hooks/supply-chain-scan.sh`) from advisory-only to a **blocking gate** for dep-mutating commands. The capacity currently records `advisory` audit rows and emits a `supply-chain-advisory:` stderr line, but never returns a non-zero exit — agents can silently install any dependency from any registry with zero friction beyond a one-line nudge.

The 008 advisory has been live-dogfooded twice (`/home/goat/pyshrnk` uv, `/home/goat/shrnk` bun) and the detection is now sound: tokenizer stops at shell separators, value-taking flag values don't leak into the packages array (b730b63), scoped npm packages and multi-package installs are handled. With detection trusted, the next discipline gap is *intent capture* — every dep mutation should leave a deliberate record of *why*, the way every commit in a secrets-scan repo leaves either a clean diff or a documented override reason.

This spec is the symmetric companion to specs 006/007 (secrets-scan blocking): same `# OVERRIDE: <reason ≥10 chars>` grammar, same corrective stderr template pattern (issue #24327 mitigation), same env-var escape hatch shape. The Edit/Write side (`.claude/hooks/supply-chain-advise.sh`) stays advisory-only — basename matches don't parse the diff, so blocking on `package.json` edits would block license-header changes the same as new-dep additions, an FP rate too high for a blocking gate.

## Acceptance criteria

- [x] **Scenario: Bash dep-install in default block mode without override**
  - **Given** the Bash preflight runs in default (block) mode
  - **When** a recognised `(manager, verb, packages)` triple is detected without a valid override marker
  - **Then** the hook exits 2, emits a `supply-chain-block:` stderr template naming the manager/action/packages and showing the corrective override form, and audits one row with `decision: "block"`

- [x] **Scenario: Bash dep-install in default block mode WITH valid override marker**
  - **Given** the Bash preflight runs in default (block) mode
  - **When** a recognised dep-install triple is detected AND the command contains a line matching `^[[:space:]]*# OVERRIDE: <reason ≥10 chars>`
  - **Then** the hook exits 0 silently (no stderr template), and audits one row with `decision: "block-override"`, `override_reason` populated from the marker

- [x] **Scenario: Bash dep-install in advisory opt-out mode**
  - **Given** `CLAUDE_SUPPLY_CHAIN_BLOCK=0` is set
  - **When** a recognised dep-install triple is detected without override
  - **Then** the hook behaves identically to spec 008: exits 0, emits the `supply-chain-advisory:` stderr line, audits `decision: "advisory"`. With override marker, audits `decision: "advisory-override"` (existing values preserved exactly)

- [x] **Scenario: Short override reason in block mode still blocks**
  - **Given** the Bash preflight runs in default (block) mode
  - **When** the command contains `# OVERRIDE: skip` (reason <10 chars after trim)
  - **Then** the hook exits 2 with the corrective template (same as no-override path), audits `decision: "block"`. Reason floor is NOT a soft-degrade in block mode — it must match secrets-scan's `override-too-short` behaviour, not 008's silent-fallback

- [x] **Scenario: Edit/Write on manifest stays advisory under block mode**
  - **Given** the Bash preflight runs in default (block) mode AND a sub-agent edits a manifest basename (e.g. `package.json`)
  - **When** the `PostToolUse(Edit|Write|MultiEdit)` hook fires
  - **Then** behaviour is unchanged from spec 008 — exits 0, emits `supply-chain-advisory: edit ...`, audits `decision: "advisory"`, `scope: "edit"`. The Edit/Write hook never blocks regardless of `CLAUDE_SUPPLY_CHAIN_BLOCK` value

- [x] **Scenario: `CLAUDE_SKIP_SUPPLY_CHAIN_SCAN=1` still silences both layers**
  - **Given** `CLAUDE_SKIP_SUPPLY_CHAIN_SCAN=1` is set
  - **When** any Bash invocation or sub-agent Edit/Write/MultiEdit fires
  - **Then** both hooks exit 0 silently with no scan and no audit row (existing throwaway-session escape preserved, takes precedence over `CLAUDE_SUPPLY_CHAIN_BLOCK`)

- [x] **Scenario: `skip-not-install` audit shape unchanged**
  - **Given** a Bash command that is not a recognised dep-install (e.g. `ls -la`, `npm test`, `bun install` with no args)
  - **When** the preflight runs in either block or advisory mode
  - **Then** the audit row is `decision: "skip-not-install"` with the existing field shape — block mode does NOT add friction to non-mutating commands

- [x] **Scenario: Stderr template ends with verbatim corrected form**
  - **Given** the preflight blocks a dep-install in block mode
  - **When** the agent reads the rejected stderr on its next turn (Claude Code issue #24327 mechanic)
  - **Then** the stderr ends with the EXACT two-line corrected shape — the original command on line 1, `# OVERRIDE: <reason>` placeholder on line 2 — so the agent can copy-paste without semantic reasoning. Template is a contract, not friendly UI

- [x] `.claude/hooks/supply-chain-scan.sh` updated with block-mode branch, ≥10-char enforcement in block mode, mode-gated stderr template
- [x] `.claude/rules/supply-chain.md` § *What fires, what advises* updated to describe block-mode-by-default semantics; new § *Block vs advisory mode* section; audit-log table extended with `block` and `block-override` decision values; gotchas updated for the new default
- [x] `.claude/tests/supply-chain/` extended with 4 new scenario scripts: block-default, block-override-valid, block-override-too-short, advisory-opt-out (preserve existing 7 scenarios as regression guards)
- [x] CLAUDE.md § *Supply chain* summary block updated to reflect block-by-default + new env var; ≤2 sentences of marginal text
- [x] README per-fork checklist gains one bullet describing the env var `CLAUDE_SUPPLY_CHAIN_BLOCK=0` for forks that want to keep advisory-only mode

## Non-goals

- **Edit/Write blocking** — basename-only matching has too high an FP rate (license header edits, formatting changes, restructuring) to be a blocking gate. Stays advisory; revisit only if a future spec adds diff-parsing to the hook.
- **Per-package allowlist / known-safe bypass** — no list of "trusted" packages that bypass block without the override marker. Maintaining such a list is brittle (CVE history, ownership changes, name-squatting) and undercuts the discipline. The override marker IS the bypass.
- **Per-manager block toggles** — no `CLAUDE_SUPPLY_CHAIN_BLOCK_NPM=0` granularity. Either the discipline is on (default) or off (`=0`). Forks that want manager-specific behaviour can fork the hook.
- **Special-casing `pip install -r requirements.txt`** — current behaviour captures `requirements.txt` as the "package" (documented FP); under block mode this still fires as a block, which is correct (a requirements-file install IS a supply-chain mutation). The override marker is the way through.
- **Blocking on `npm ci` / `bun install` / `cargo build` / equivalent lockfile-respecting installs** — these don't mutate the manifest and audit as `skip-not-install` today. Stays that way under block mode (consistent with the "block only on dep mutations" framing).
- **Retroactive activation on existing forks** — only fresh forks of Agent0 from the commit that lands this spec get the new default. Existing forks updating to the new harness pick up the new default automatically on their next `git pull`; the README checklist documents the env-var opt-out as the migration hint.
- **New audit fields beyond decision values** — no `mode` field added to the row shape. The decision values (`block` vs `advisory`, `block-override` vs `advisory-override`) already encode the mode unambiguously, and adding a field would break existing `jq` queries against the log.

## Open questions

(none — three design choices resolved with user via AskUserQuestion 2026-05-11: scope = Bash only, default = opt-out / block-on, trigger = any dep-mutation)

## Context / references

- `docs/specs/008-supply-chain-scan/` — base advisory capacity (spec.md, plan.md, tasks.md)
- `docs/specs/006-secrets-scan/` and `docs/specs/007-secrets-scan-timing/` — sibling blocking-gate precedent; reuse the override-grammar, audit-log, and stderr-template patterns wholesale
- `.claude/rules/supply-chain.md` — current advisory discipline; § *Override grammar* and § *Audit log* are the load-bearing sections this spec extends
- `.claude/rules/secrets-scan.md` § *Gotchas* — issue #24327 stderr-as-contract note; same mechanic applies here
- Commits `b730b63` (tokenizer fix) and `6b0ea3e` (gotchas) — the recent live-dogfood improvements that make this spec viable
- Live-dogfood passes 2026-05-11: `/home/goat/pyshrnk` (uv branch, surfaced 2 findings) and `/home/goat/shrnk` (bun branch, 0 new findings — yield decay signal that prompted this spec)
