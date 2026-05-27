---
name: hook-chain-maintenance
description: Maintainer discipline for the PreToolUse(Bash) hook chain — optimization techniques + 5-step contract for adding a new hook. Read before adding/editing PreToolUse(Bash) hooks.
metadata:
  type: project
  created_at: '2026-05-27T00:09:44Z'
  last_accessed: '2026-05-27'
  confirmed_count: 0
---
# Hook chain maintenance

Maintainer-binding companion to `.claude/rules/hook-chain-latency.md`. The rule documents what consumers of the harness see (budget, bench tool, regression check); this memory documents the upstream-maintainer discipline applied when adding or editing a `PreToolUse(Bash)` hook.

Read before adding any new `PreToolUse(Bash)` hook, or editing the optimization-sensitive bodies of `governance-gate.sh`, `secrets-scan.sh`, `supply-chain-scan.sh`, `runtime-pre-mark.sh`.

## Optimization techniques

Three techniques applied to the v1 hook chain (spec 094, 2026-05-26):

### 1. `if`-field matcher narrowing in `.claude/settings.json`

For hooks that only need to inspect a subset of Bash commands, use the per-handler `if` field with permission-rule syntax. From Claude Code docs:

> "The `if` condition `Bash(rm *)` matches because `rm -rf /tmp/build` is a subcommand matching `rm *`, so this handler spawns. If the command had been `npm test`, the `if` check would fail and `block-rm.sh` would never run, avoiding the process spawn overhead."

Applied to:

- `secrets-scan.sh` — narrows to `Bash(git commit *|git commit|*git commit *|*git commit)`. The hook itself short-circuits on non-`git commit` after `jq` parse anyway, but matcher-narrowing prevents the spawn outright — a free ~70 ms saving per non-commit Bash call.
- `supply-chain-scan.sh` — narrows to `Bash(npm *|pnpm *|yarn *|bun *|pip *|uv *|poetry *|pdm *|cargo *|go *|composer *)`. Same logic.

Not applied to:

- `governance-gate.sh` — destructive patterns can appear anywhere; can't narrow safely.
- `runtime-pre-mark.sh` — must run on every Bash to stamp the `started_at` timestamp.

### 2. Pre-jq raw-stdin probe (governance-gate.sh)

Before paying for `jq` parse, grep the raw JSON stdin for any keyword that could possibly trigger a block:

```bash
if ! printf '%s' "$INPUT" \
    | grep -qE 'rm[[:space:]]+-|--force|--no-verify|--hard|add[[:space:]]+...'; then
  exit 0
fi
```

The probe is **sufficient-but-not-necessary**: a probe-miss is a guaranteed no-block, so exit 0 is safe; a probe-hit (false positive) falls through to the existing full-regex path under `jq`, which makes the real decision. False negatives (a real block pattern with no keyword in the raw JSON) are impossible by construction — the keyword set IS the set of fragments any matching regex contains.

Reduction: governance-gate.sh noop p95 from ~62 ms → ~20 ms (-68%).

### 3. sed instead of jq for single-field extraction (runtime-pre-mark.sh)

Where a hook only needs one JSON field (`tool_use_id` for runtime-pre-mark), `sed` extraction is faster than a `jq -r` spawn:

```bash
TOOL_USE_ID="$(printf '%s' "$INPUT" \
  | sed -n 's/.*"tool_use_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
  | head -1)"
```

JSON is key-order-independent and this regex finds the key wherever it appears. The hook falls back to `jq` if `sed` fails (defensive — fail-open posture is preserved).

Reduction: runtime-pre-mark.sh noop p95 from ~35 ms → ~26 ms (-24%).

## Adding a new PreToolUse(Bash) hook

Contract for any new `PreToolUse(Bash)` hook contributed upstream:

1. **Benchmark before merge.** `bash .claude/tools/bench-hooks.sh --baseline` to add the new hook's cells. Verify p95 against the budget on the default command set.
2. **Narrow with `if` if possible.** If the hook only inspects a subset of commands (anything narrower than "every Bash invocation"), declare an `if:` field on the hook handler in `.claude/settings.json`. Use permission-rule syntax: `Bash(<glob>|<glob>|...)`. Add a comment in `settings.json` near the new entry explaining why the pattern is sufficient.
3. **Pre-jq probe inside the hook body** for any hook that can't narrow at the matcher layer. Cheapest possible check first (grep against raw stdin), full logic only on probe-hit.
4. **Commit the updated baseline.** The PR adding the hook must also update `.claude/.perf-baseline.json` so the regression check stays calibrated.
5. **Avoid audit-row writes on the fast-path.** A `skip-*` audit row that fires on every Bash call adds ~5-10 ms (jq spawn × 2 for serialization + file write) — a real cost. Document the row's forensic value in the hook's rule before keeping it.

## Maintainer gotchas

- **Pre-jq probes are not free.** `grep -qE` against a 200-byte JSON string costs ~3-5 ms. Worth it when the alternative is a 25-30 ms `jq` spawn, but not free. For hooks with very simple matchers, jq might be acceptable; measure before optimizing.
- **Hook source edits are user-facing audit trail.** The pre-jq probe added to `governance-gate.sh` is documented in the hook with a reference to spec 094 (`# Pre-jq fast-path probe (the hook-chain-latency spec-hook-chain-latency)`). Future maintainers can grep for the spec slug to understand why the probe exists. Preserve this when editing.
- **`if`-field syntax: choose generosity over precision.** The exact glob shape is permission-rule syntax — see Claude Code's hooks + permissions docs. For supply-chain-scan, the obvious pattern `Bash(npm install *|pnpm install *|...)` would miss `npm i foo` and `pnpm add foo`; the broader `Bash(npm *|pnpm *|...)` catches all sub-commands and lets the hook decide. Trade-off: more hook spawns than strictly necessary, but no false negatives.

## Cross-references

- `.claude/rules/hook-chain-latency.md` — consumer-facing rule (budget, bench tool, baseline shape, regression check).
- `docs/specs/094-hook-chain-latency/` — original empirical baseline + optimization decisions.
- `.claude/memory/propagation-hygiene.md` — sibling maintainer-binding memory (fork-bound files carry no upstream-internal pointers); same shipping discipline.
