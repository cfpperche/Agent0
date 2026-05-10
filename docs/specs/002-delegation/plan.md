# 002 — delegation — plan

_Drafted from `spec.md` on 2026-05-10. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Two cooperating bash hooks plus a project-side validator stub, mirroring the conventions of `001-governance-gate`:

1. **`PreToolUse` on the `Agent` tool** (`.claude/hooks/delegation-gate.sh`) does three things in fixed order: (a) parse the prompt, look for a valid `# OVERRIDE: …` marker; (b) if no override, validate the 5 structured fields (`TASK`, `CONTEXT`, `CONSTRAINTS`, and either `DELIVERABLE` or `DONE_WHEN`) — missing → `exit 2` with the canonical template printed to stderr; (c) regardless of validation outcome (when not blocked), write a JSONL audit line, score 5 escalation signals against the prompt, and emit an `additionalContext` advisory if ≥2 fire on a non-opus model.

2. **`PostToolUse` on `Edit | Write | MultiEdit`** (`.claude/hooks/post-edit-validate.sh`) runs only if the payload includes an `agent_id` (i.e., a delegated sub-agent did the edit; parent edits omit the key entirely — confirmed by probe). It acquires a non-blocking lock (skip-if-busy), resolves the validator via env override → project default → fail-open, runs it, and on failure emits `exit 2` with the captured stdout/stderr tail. Per-`agent_id` consecutive-failure counters live under `.claude/.delegation-state/agents/<agent_id>` and trip a `LOOP BUDGET EXCEEDED` message past the cap.

3. **`.claude/validators/run.sh`** is a thin auto-detect that picks the first matching stack from `bun → pnpm → npm → python → go → rust` and runs typecheck + tests. It always emits a JSON result `{ ok, command, exit, duration_ms, stdout, stderr }` so the post-edit hook has a uniform contract. When no stack matches, the validator emits `ok=true` so the hook fails open. The validator script is *project-side* (re-implementable per repo); the hook contract is the JSON shape, not the script identity.

This split — two hooks + one stub — keeps each piece audit-sized, lets the validator evolve without touching the hook, and lets the actor-detection logic be the single load-bearing line (`payload.agent_id != null`) instead of a fragile flag-file dance.

## Files to touch

**Create:**
- `.claude/hooks/delegation-gate.sh` — `PreToolUse(Agent)`: 5-field validation, override marker, audit log, escalation advisory.
- `.claude/hooks/post-edit-validate.sh` — `PostToolUse(Edit|Write|MultiEdit)`: actor gate, lock, validator dispatch, loop budget.
- `.claude/validators/run.sh` — auto-detect stack and emit JSON result. Project-replaceable.
- `.claude/rules/delegation.md` — working-agreement rule: when delegating, format the 5 fields; when override is appropriate; how to read the audit log; how to escape the loop budget.
- `docs/specs/002-delegation/tasks.md` — generated next via `/sdd tasks`.

**Modify:**
- `.claude/settings.json` — add two hook entries: `PreToolUse[matcher=Agent]` and `PostToolUse[matcher=Edit|Write|MultiEdit]`. Keep them alongside the existing `PreToolUse[matcher=Bash]` from the governance gate.
- `.gitignore` — add `.claude/.delegation-state/` and `.claude/delegation-audit.jsonl` (ephemeral per-machine state and append-only audit log).
- `CLAUDE.md` — one-paragraph reference to the delegation working agreement, pointing at the rule file (consistent with how spec-driven development is referenced).

**Delete:** none.

## Naming, paths, and env vars

| Concern | Choice | Rationale |
|---|---|---|
| Hook file names | `delegation-gate.sh`, `post-edit-validate.sh` | "gate" mirrors `governance-gate.sh` for the blocking PreToolUse; "validate" is descriptive for the post-edit role |
| Validator script | `.claude/validators/run.sh` | Pluralizable dir for future per-language validators if ever needed; `run.sh` is the entrypoint |
| Audit log | `.claude/delegation-audit.jsonl` | JSONL, append-only, gitignored. Top-level under `.claude/` (sibling to `COMPACT_NOTES.md`) so `tail -f` is one path away |
| Loop-budget state | `.claude/.delegation-state/agents/<agent_id>` | Mirrors `.claude/.session-state/` convention; one file per agent_id holding a single integer (consecutive-fail count) |
| Lock file | `.claude/.delegation-state/validate.lock` | Single global lock. Concurrent edits skip-if-busy (validator is idempotent so a queued one is redundant) |
| Loop budget cap env var | `CLAUDE_DELEGATION_LOOP_BUDGET` (default `5`) | `CLAUDE_*` namespace consistent with harness conventions |
| Validator override env var | `CLAUDE_DELEGATION_VALIDATOR` | Absolute path to a custom validator. Falls back to `.claude/validators/run.sh`, then fail-open |

## Audit log schema

One JSON object per line, written by `delegation-gate.sh`:

```json
{
  "ts": "2026-05-10T21:00:00Z",
  "session_id": "416ac9d2-...",
  "subagent_type": "general-purpose",
  "model": "opus",
  "model_specified": true,
  "formatted": true,
  "override": null,
  "advisory_emitted": false,
  "escalation_signals": [],
  "task_summary": "first 120 chars of TASK field, or first 120 chars of prompt if no TASK"
}
```

Notes:
- `model_specified=false` when `tool_input.model` key is absent (parent inherited the default — confirmed in probe).
- `formatted=true` iff all 5 fields matched (case-insensitive `<FIELD>:` substring); `formatted=false` only possible alongside `override≠null` (otherwise the call was blocked and never logged).
- `override` is the marker reason text when present, otherwise `null`. Keeps the audit visible even when the marker bypassed the field check.
- `escalation_signals` is the array of triggered signal names (e.g. `["security", "schema"]`); empty when none fired.

## Validator JSON contract

`run.sh` (or any `CLAUDE_DELEGATION_VALIDATOR` replacement) MUST emit exactly one JSON object on stdout:

```json
{
  "ok": true,
  "command": "bun test && bun tsc --noEmit",
  "exit": 0,
  "duration_ms": 8421,
  "stdout": "…last 4 KB…",
  "stderr": "…last 4 KB…"
}
```

`ok` is the contract field — anything else is diagnostic. The hook never re-runs commands itself; it only reads `ok`. Capping `stdout`/`stderr` at ~4 KB keeps the audit (and any error surfacing) bounded.

## Stack auto-detect order

First match wins. Each step is a single existence check; no stack discovery beyond presence-of-marker:

1. `bun.lockb` or `bunfig.toml` → `bun test && bun run typecheck` (typecheck script may be absent — fall through to `bun tsc --noEmit` if `tsconfig.json` exists)
2. `pnpm-lock.yaml` → `pnpm test && pnpm typecheck` (or `pnpm tsc --noEmit` fallback)
3. `package-lock.json` or `package.json` (npm fallback) → `npm test --silent && npm run typecheck` (best-effort)
4. `pyproject.toml` or `requirements.txt` → `python -m pytest -q && python -m mypy . || true` (mypy soft-fail on first pass; spec acceptance only requires presence of the chain)
5. `go.mod` → `go test ./... && go vet ./...`
6. `Cargo.toml` → `cargo test --quiet && cargo clippy -q -- -D warnings`
7. None of the above → emit `{ "ok": true, "command": "no-stack-detected", "exit": 0, "duration_ms": 0, "stdout": "", "stderr": "" }` (fail-open).

For the *current* Agent0 base repo (no language stack yet), step 7 fires — meaning the validator is inert until a real stack appears. That's the correct dogfood state for a base repo.

## Escalation signals (5 total)

Pattern hits on the prompt text, case-insensitive. Score = number of signals that fire.

| Signal | Trigger pattern (regex, case-insensitive) |
|---|---|
| `large-fileset` | `\b(10\|[1-9][0-9])\+?\s+files\b` (e.g. "10 files", "20+ files") |
| `multi-integration` | `(?:integrate\|integration\|api).{0,200}(?:integrate\|integration\|api).{0,200}(?:integrate\|integration\|api)` (3 mentions of integration/api within reasonable proximity) |
| `cross-domain` | both `(frontend\|ui\|react\|component)` AND `(backend\|server\|api\|database)` fire on the same prompt |
| `schema-data` | `\b(schema\|migration\|migrate\|database\s+model\|er[- ]diagram)\b` |
| `security` | `\b(auth\|authentication\|payment\|pii\|credential\|secret\|token\|encryption)\b` |

Score ≥2 AND (`model_specified=false` OR `model != "opus"`) → emit advisory. Advisory text:

> Delegation appears complex (signals: <list>). Consider re-issuing with `model: "opus"` for stronger reasoning. This is advisory only — the call has been allowed.

The advisory is informational; the hook always returns `permissionDecision: "allow"` and never blocks on escalation.

## Loop-budget mechanics

State file is plain text containing the consecutive-failure count for one `agent_id`:

- Validator passes → write `0` (or remove file).
- Validator fails AND count < cap → increment, emit standard "fix before declaring done" stderr.
- Validator fails AND count ≥ cap → emit `LOOP BUDGET EXCEEDED — stop editing and report a partial result`. Counter is *not* further incremented (no point).

The cap reset on pass means a sub-agent that recovers can keep working. State is per-agent so a fresh delegation starts at 0 even if the previous one tripped the cap.

Cleanup: state files are not pruned automatically. Stale entries from old `agent_id`s are harmless (they only matter when that exact id reappears, which won't happen — agent ids are session-scoped). A future `tasks.md` step may add a `find ... -mtime +7 -delete` cron-style sweep but it's not required for spec acceptance.

## Locking strategy

`flock -n` on `.claude/.delegation-state/validate.lock` (non-blocking). If acquisition fails, exit 0 — a validation is already in flight, and the validator is deterministic over the working tree, so a piggy-backed second run would just duplicate work. Concurrent sub-agent edits are rare in practice but the lock makes the hook safe under that case.

`flock` is in `util-linux` and present on every Linux distribution this project targets. macOS lacks `flock` by default; the macOS escape is `mkdir`-as-mutex (`mkdir lockdir && trap 'rmdir lockdir' EXIT`). The hook uses `command -v flock` to pick the right path. Falling back to no-lock is acceptable (reverts to the pre-design behavior of stacked validations) and is documented as a soft degradation.

## Override marker

Identical shape to governance: `# OVERRIDE: <reason ≥10 chars>`, case-sensitive, marker terminator is end-of-line. Reason <10 chars → block as if marker were absent (with a stderr hint that the reason is too short).

Two refinements introduced after dogfooding revealed false positives during the first real delegation through the gate (audit entry on 2026-05-10 captured a marker reason extracted from prose that documented the marker):

- **Start-of-line anchor.** The marker is recognized only when it appears at the start of a line (with optional leading whitespace) — regex `^[[:space:]]*# OVERRIDE: .*`. Markers buried mid-paragraph (typical when documentation discusses the marker) are not treated as bypass. Markdown headers use `# ` for h1; a top-level heading literally `# OVERRIDE: ...` would still trip the gate, but that's a deliberate-looking choice and acceptable.
- **Override suppresses block, not validation.** The 5-field check ALWAYS runs. The override marker only changes what the script does on a missing-fields result — with override, allow; without override, block. The audit `formatted` field therefore reflects the *actual* validation result, not whether validation was skipped. This makes the audit log honest: `override=<reason>, formatted=true` (override on a properly formatted prompt) and `override=<reason>, formatted=false` (override actually used to bypass missing fields) are both recorded, and a future analyst can distinguish defensive override use from real bypass use.

Code-fence awareness (skipping markers inside fenced blocks) is intentionally NOT added — it doubles the parsing complexity for marginal benefit, and the start-of-line anchor already handles the common case.

## Alternatives considered

### Move the validator INSIDE the sub-agent definition (frontmatter `PostToolUse` per agent)

Considered after the docs research initially suggested actor detection wasn't exposed. Rejected once the probe confirmed `agent_id` is in the payload: an in-agent hook would require modifying every sub-agent definition (or wrapping every dispatch in a project-specific "delegation wrapper" sub-agent), which doesn't satisfy the spec's "gate every Agent call" non-goal. The project-level `PostToolUse` with actor detection is one place to maintain instead of N.

### Hybrid `SubagentStart` flag-file + `PostToolUse` flag check

Considered as a fallback for the actor-detection problem. Rejected: relies on a fragile temp-file dance (race conditions when the parent edits during a sub-agent's lifetime, no clean way to know which sub-agent owns which edit when multiple are active, no `agent_id` correlation). Once the probe confirmed the direct `agent_id` signal, this option became strictly inferior.

### Single combined hook (PreToolUse + PostToolUse handled by one script branching on `hook_event_name`)

Considered for symmetry with the consolidated governance gate. Rejected: the two events have different blast radius (`PreToolUse(Agent)` runs once per delegation; `PostToolUse(Edit)` runs on every file edit), different failure semantics (block-with-template vs block-with-validator-output), and different state. Co-locating them would mean a single script with two near-disjoint code paths — more audit surface, not less. Two narrowly-scoped scripts beat one branching script here.

### Implement validator in TypeScript/Node for stack-aware ergonomics

Rejected. Mirrors the `001-governance-gate` decision: bash + jq is portable, near-zero startup, no install. Node would add latency to every sub-agent edit. Stack auto-detection is six `[ -f X ]` checks — bash handles it trivially.

### Block on missing/broken validator (fail-closed)

Rejected. Spec explicitly mandates fail-open for missing/broken validators ("Don't fail-closed on missing/broken validator"). Reason: a broken validator that permanently blocks editing is worse than no validation — the agent loses the ability to make progress, and the user must intervene to fix the validator before any further work can happen.

### Filter delegations by sub-agent type (e.g., exempt `Explore` from 5-field check)

Rejected. Spec explicitly forbids ("Don't filter delegations by sub-agent type — gate every Agent call"). Reason: the 5-field discipline is universal — even `Explore` benefits from explicit constraints (file scope, depth, what to ignore) that a one-liner won't capture. The override marker is the per-call escape, not an allowlist.

## Risks and unknowns

- **`model` key absence is documented but feels fragile.** If a future Claude Code build adds a default `model: null` to `tool_input`, the audit's `model_specified` field semantics shift. Mitigation: derive `model_specified` from `has("model")` (jq), not from `model != null`. Both paths produce sane behavior; the field is informational anyway.
- **`additionalContext` rendering.** Confirmed via docs that `PreToolUse` hooks emit `hookSpecificOutput.additionalContext` for non-blocking advisories. Not yet confirmed empirically that the parent agent reliably sees the advisory in the next turn after the Agent call — there's a chance Claude Code only surfaces it under certain UI states. If smoke test reveals it's silently dropped, we'd need to surface the advisory as an audit-log-only signal (less helpful but not broken).
- **`flock` on macOS.** The fallback to `mkdir`-mutex is a documented soft path, but if a future contributor disables it without testing on macOS, concurrent validations could overlap. Documenting in the rule file mitigates.
- **`# OVERRIDE:` marker collision with prompt content.** A prompt that legitimately discusses an OVERRIDE marker (e.g. "explain what `# OVERRIDE: <reason>` does") would trip the override path. Acceptable per the same reasoning as governance: gate is anti-mistake, not anti-malice.
- **Loop budget per-`agent_id` doesn't survive sub-agent restart.** If a sub-agent stops and the parent re-dispatches the same task to a new `agent_id`, the budget resets. This is by design (a fresh delegation deserves a fresh budget), but it does mean a determined retry loop could evade the cap with re-dispatch. Audit log catches the pattern; no automated mitigation in scope.
- **No probe-confirmed shape for `tool_response` on `PostToolUse`.** The hook doesn't read `tool_response`, so this is OK, but if a future change wants to inspect what the edit actually did (for diff-aware validation), the payload shape would need a second probe.

## Research / citations

- Spec `docs/specs/001-governance-gate/spec.md` and `plan.md` — convention source for override marker, jq-on-stdin, fail-mode posture, registration shape in `settings.json`.
- Claude Code hooks docs (`https://code.claude.com/docs/en/hooks.md`) — verified by `claude-code-guide` agent, conversation 2026-05-10. Source for: `Agent` matcher (renamed from `Task` in v2.1.63), `tool_input.{prompt, description, subagent_type, model}` schema, `hookSpecificOutput.additionalContext` shape.
- Empirical probe — `.claude/.runtime/probe/` (registered in `.claude/settings.local.json`, both removed after analysis), conversation 2026-05-10. Source for: `agent_id` and `agent_type` are in the `PostToolUse` payload for sub-agent edits and absent for parent edits; `session_id` and `transcript_path` are inherited from parent (NOT useful for actor detection); `tool_input.model` key is *absent* (not null) when unspecified.
- `.claude/rules/spec-driven.md` — workflow rationale (spec-first for new modules touching 4+ files).
- `.claude/rules/research-before-proposing.md` — drove the docs+probe resolution of the three open questions before this plan was drafted.
