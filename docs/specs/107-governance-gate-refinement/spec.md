# 107 — governance-gate-refinement

_Created 2026-05-28._

**Status:** shipped

## Intent

`.claude/hooks/governance-gate.sh` is the project's `PreToolUse(Bash)` safety floor — it blocks three families (destructive ops, hook-bypass, blanket staging) with an `# OVERRIDE:` escape hatch, and is the **canonical precedent** for the override-marker grammar the other gates cite. It is the simplest gate (≈113 lines, no state, no audit log, no rule) and has worked unchanged for a long time. As we refine the harness hook-by-hook, this spec asks: **what, if anything, is worth refining here — without overengineering a speed-bump into a sandbox?** An empirical probe (2026-05-28) surfaced concrete material: `rm -r -f` (separate flags) evades the gate while `rm -rf` is blocked; several destructive shapes (`git clean -fdx`, `find -delete`, `dd`, `chmod -R`, `: >` truncation) pass; overrides leave no durable audit trace; and the pre-jq fast-path keyword list can silently drift from the family regexes. The decision this spec forces, via Claude↔Codex debate: which of these are genuine correctness fixes vs scope-creep that buys false confidence.

## Acceptance criteria

_Finalized after the Claude↔Codex debate (converged 2026-05-28; see `debate.md` § Synthesis)._

- [x] **Scenario: separate-flag rm is no longer a trivial bypass**
  - **Given** `rm -r -f <path>` / `rm -f -r <path>` / `-R` variants (flags as separate tokens)
  - **When** the gate runs
  - **Then** it blocks identically to `rm -rf`; and `rm -r` (no force), `rm -i`, `grep -rf` stay allowed (no false-positive)

- [x] **Scenario: git clean force+broad blocked, dry-run allowed**
  - **Given** `git clean -fdx` (or `-f` with `-d`/`-x`/no pathspec)
  - **When** the gate runs
  - **Then** it blocks (same destroy-uncommitted-work family as `git reset --hard`); `git clean -n` / `--dry-run` stays allowed

- [x] **Scenario: whole-tree checkout/restore blocked, targeted allowed**
  - **Given** `git checkout -- .` / `git checkout -- :/` / `git restore .` / `git restore :/` / index-wide `--staged .`
  - **When** the gate runs
  - **Then** it blocks; `git checkout -- <file>`, branch switches, and targeted `git restore <path>` stay allowed

- [x] **Scenario: fast-path probe is a superset of the families (drift guard)**
  - **Given** every command shape any family blocks
  - **When** the pre-jq fast-path probe runs
  - **Then** the probe matches it (so the full regex is reached) — a regression test asserts probe ⊇ families; the misleading "falls through" comment is corrected to document the early-exit + superset invariant

- [x] **Scenario: override marker** — `# OVERRIDE: <reason ≥10 chars>` on a blocked command → allowed; reason `<10 chars` → still blocked

- [x] The gate header records the "common-obvious destructive shapes, hook bypass, blanket staging — not a sandbox" principle; coverage additions are justified case-by-case, not by chasing every destructive shell form

- [x] **Scenario: multi-runtime port** — `governance-gate.sh` lives at `.agent0/hooks/`; `.claude/settings.json` `PreToolUse(Bash)` points there; `.codex/config.toml.example` carries a commented `[[hooks.PreToolUse]]` matcher `"^Bash$"` block; the gate blocks identically under both runtimes (reads only `tool_input.command`)

- [x] Each accepted change ships with a regression test in `.claude/tests/governance-gate/`

## Non-goals

- Turning the gate into an exhaustive destructive-command sandbox. It is a speed-bump for the common-and-obvious; an agent determined to be destructive has unbounded shell forms (pipes, `eval`, `xargs`, scripts) the gate cannot and should not chase.
- Making the pattern families configurable (env-var pattern file, per-project allowlists). No demand (rule-of-three); adds a config surface heavier than the value.
- Changing the `# OVERRIDE:` grammar itself (it is the shared project precedent; changing it ripples to every gate).
- **Override-audit jsonl** — RESISTED. Override reasons sit beside full shell commands/paths and can carry secrets; a durable log would need redaction + retention + gitignore/sync + a reader story — too much infra for a rare local escape hatch with no demonstrated forensic workflow. Revisit only on a real rule-of-three forensic need.
- **Shell-primitive families** (`dd`, `truncate`, `: >` redirect, `chmod -R`, `find -delete`/`-exec rm`) — RESISTED. Unbounded shapes; adding regexes implies a completeness the hook cannot deliver and breeds false confidence. No `chmod -R 777 /` carve-out (not a principled family). The gate is a speed-bump, not a sandbox.
- **Porting secrets-scan / supply-chain-scan to `.agent0/`** — those are the *next* batch (same clean Bash-surface shape); only `governance-gate.sh` is ported in this spec.

## Open questions

- [x] **Coverage line — FIX / CONSIDER / RESIST** — RESOLVED: FIX = `rm` separate-flag + `git clean` force/broad + whole-tree `checkout`/`restore`; RESIST = shell primitives (no chmod carve-out).
- [x] **Override audit** — RESOLVED: NO. Override reasons can carry secrets → durable log needs redaction/retention/sync infra; not justified for a rare escape hatch.
- [x] **Fast-path drift guard** — RESOLVED: YES, load-bearing. Probe must be a superset of families (a miss exits before the regex); the existing comment misdescribes this as "falls through" and is corrected. Regression test added.
- [x] **Doc gap** — RESOLVED: thin. Header records the families + "not a sandbox" + override grammar; separate rule only if the override-precedent citations need an anchor.
- [x] **Bundle the port?** — RESOLVED: YES (user decision). Move to `.agent0/` + register both runtimes in this spec; secrets-scan + supply-chain-scan ports are a later batch.

## Context / references

- `.claude/hooks/governance-gate.sh` — the hook (3 families, fast-path pre-jq, override marker)
- `.claude/rules/delegation.md` § Override marker — cites "same shape as the governance gate"
- `.claude/rules/tdd.md` — cites the governance gate as the canonical override shape
- `.agent0/memory/hook-chain-latency.md` — the fast-path pre-jq is part of the Bash-chain latency budget
- `docs/specs/106-delegation-hooks-multi-runtime/` — the just-shipped sibling port (the clean-vs-asymmetric contrast)
- Empirical probe 2026-05-28 (in `debate.md` Round 1) — the grounded coverage findings
