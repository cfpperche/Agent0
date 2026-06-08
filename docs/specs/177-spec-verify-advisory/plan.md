# 177 — spec-verify-advisory — plan

_Drafted from `spec.md` on 2026-06-08. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Three small, independent pieces, all markdown+shell, all propagating through existing sync globs:

1. **Declaration syntax** — a spec opts in by adding one or more lines `**Verify:** \`<command>\`` to its `tasks.md` (canonical) — typically under `## Verification`. The marker is a literal `**Verify:**` followed by a backtick-fenced command. Multiple lines = multiple commands run in order. `spec.md` is scanned as a fallback so a single-file spec still works.

2. **`spec-verify.sh` tool** — a standalone runtime-neutral tool (no capacity-kit dependency; that kit is for media tools). Takes a spec dir, extracts the declared commands, runs each with `bash -c` from the repo root, captures pass/fail, appends a timestamped `## Verification log` block to the spec's `notes.md`, and prints human or `--json` output. Exit codes: `0` all declared commands passed, `1` at least one failed, `2` none declared. Follows the `doctor.sh`/`diagram.sh` arg-parse idiom (`--json`, `--quiet`, `-h`, unknown-flag → exit 64).

3. **Validator advisory** — extend `.agent0/validators/run.sh` with a bounded, opt-in check: for each `docs/specs/*/spec.md` declaring `**Status:** shipped`, if its sibling `tasks.md` declares a `**Verify:**` command AND `notes.md` has no `pass` record for the latest run (or no `## Verification log` at all), emit one `spec-verify-advisory:` line to stderr. Specs that declare no verify command are skipped entirely (opt-in, no nag). The check is a couple of greps — cheap even across ~180 specs — and never touches the `ok` field (non-blocking, mirrors `typecheck-advisory`/`lint-advisory`).

Order: tool first (it's the load-bearing artifact and the dogfood target), then tests, then validator wiring, then the rule doc, then dogfood (run on this spec + wire squad.json gate).

## Files to touch

**Create:**
- `.agent0/tools/spec-verify.sh` — the verify-runner tool (executable).
- `.agent0/context/rules/spec-verify.md` — rule doc (frontmatter `paths:`, H2 sections, Gotchas, consumer-extension note).
- `.agent0/tests/spec-verify/run-all.sh` — test harness covering the six scenarios + json shape.
- `docs/specs/177-spec-verify-advisory/squad.json` — squad contract; `gate[]` runs the test harness + `spec-verify.sh` on this spec.

**Modify:**
- `.agent0/validators/run.sh` — add the `spec-verify-advisory:` emission (non-blocking, opt-in scan).
- `docs/specs/177-spec-verify-advisory/tasks.md` — declare this spec's own `**Verify:**` command (dogfood).
- `CLAUDE.md` / `AGENTS.md` — add a one-line managed-index entry for the capability (matching the existing `## Lint validator` / `## Typecheck advisory` index style), if the managed-block convention requires it.

**Delete:**
- none.

## Alternatives considered

### Declare the verify command in `spec.md` instead of `tasks.md`

Rejected because `spec.md` is intent-pure by Agent0 doctrine ("the user owns intent"; the `/sdd` skill refuses to auto-fill it). An executable shell command is a "do" artifact, so `tasks.md` is its natural home. We keep a `spec.md` fallback scan so single-file specs aren't broken, but the canonical, documented home is `tasks.md`.

### Have the validator auto-RUN the verify command

Rejected — executing arbitrary spec-declared shell on every `SubagentStop` is a security and latency hazard (and could mutate the tree). The validator only *advises*; running is explicit via `spec-verify.sh` or the squad gate. This matches the rest of the advisory family, which detects-but-does-not-act.

### Nag every shipped spec with no verify command

Rejected — that is exactly the "ceremony kills the signal" failure both Claude and Codex flagged in the adoption analysis. The mechanism is opt-in: a spec is only checked once it declares a `**Verify:**`. Absence is never nagged.

### SQLite ledger / persisted `last_verified_result` row (the studied project's design)

Rejected wholesale — conflicts with Agent0's markdown+hooks center of gravity and would split truth away from specs/git. We persist the result as a markdown `## Verification log` block in `notes.md` (git-tracked, human-readable) instead of a DB row.

## Risks and unknowns

- **Stale/unsafe verify commands** — a declared command can rot or be stack-opinionated. Mitigation: opt-in + advisory-only + documented in the rule doc that commands must be runnable from repo root and side-effect-free; never auto-run.
- **Validator latency** — scanning all spec dirs each `SubagentStop`. Mitigation: a single `grep -l` for `**Status:** shipped` narrows the set before the per-spec checks; bounded and cheap.
- **`notes.md` append discipline** — appending must not clobber the in-flight design-memory sections. Mitigation: append a clearly-delimited `## Verification log` section at end; never edit existing sections.
- **Cross-runtime advisory surfacing** — Claude (stderr) vs Codex (JSON `additionalContext`). The validator already routes advisories per-runtime; we reuse that path rather than inventing a new one.
- **Unknown:** whether the managed CLAUDE.md/AGENTS.md index requires an entry for advisory-family capabilities or whether the rule doc alone suffices — verify against how `typecheck-advisory` is indexed.

## Research / citations

- `repository-harness` study + Codex adoption ranking: `.agent0/.runtime-state/codex-exec/20260608T203313Z-rh-adopt/last-message.md`.
- Validator + advisory idiom map (this session's Explore agent): `.agent0/validators/run.sh:29,66,77,91`; `.agent0/hooks/propagation-advise.sh:82-96`.
- Tool idiom: `.agent0/tools/diagram.sh`, `.agent0/tools/doctor.sh:24-35`.
- Sync globs: `.agent0/tools/sync-harness.sh:186-203`.
- Squad gate: `docs/specs/163-capacity-kit/squad.json:8-18`; `.agent0/context/rules/squad.md`.
