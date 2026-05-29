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

Maintainer-binding companion to `.agent0/memory/hook-chain-latency.md`. The companion entry documents the chain budget + bench tool + regression check; this memory documents the upstream-maintainer discipline applied when adding or editing a `PreToolUse(Bash)` hook.

Read before adding any new `PreToolUse(Bash)` hook, or editing the optimization-sensitive bodies of `governance-gate.sh`, `secrets-preflight.sh`, `runtime-pre-mark.sh`.

## Optimization techniques

Three techniques applied to the v1 hook chain (spec 094, 2026-05-26):

### 1. `if`-field matcher narrowing in `.claude/settings.json`

For hooks that only need to inspect a subset of Bash commands, use the per-handler `if` field with permission-rule syntax. From Claude Code docs:

> "The `if` condition `Bash(rm *)` matches because `rm -rf /tmp/build` is a subcommand matching `rm *`, so this handler spawns. If the command had been `npm test`, the `if` check would fail and `block-rm.sh` would never run, avoiding the process spawn overhead."

**⚠️ Pipe-alternation inside a single `Bash(...)` is NOT valid CC syntax — corrected 2026-05-28 after the spec-108 V8-Claude live dogfood.** The `if`-field accepts permission-rule syntax, where `|` is a recognized *shell command separator* ("a rule must match each subcommand independently"), NOT an alternation operator. Multi-pattern rules must be **separate array elements** (`"Bash(npm run *)", "Bash(git commit *)"`), never `Bash(a|b|c)`. A handler whose `if` is `Bash(a|b|c)` can never match a real single command (which contains no literal `|`), so it **silently never spawns at all** — including on the commands it was supposed to inspect. That is a dormant-hook correctness bug, not narrowing. Confirmed vs <https://code.claude.com/docs/en/permissions.md>; single-pattern `if` (the `Bash(rm *)` quote above) is fine.

Originally claimed as applied to (BOTH were pipe-alternation → BOTH were dormant; the "~70 ms saving" was illusory because the hook never ran, not because it was intelligently narrowed):

- `secrets-preflight.sh` — was `Bash(git commit *|git commit|*git commit *|*git commit)`. The pattern never matched, so the Claude preflight never fired on any `git commit` (the V8-Claude dogfood caught this — a compound `git add ... && git commit` passed unblocked). **Fixed 2026-05-28: dropped the `if`, now bare `"matcher": "Bash"`** — spawns on every Bash and short-circuits internally (the hook body already exits silently on non-`git commit`, the spec-108 broad-matcher design). Live-verified: `reject-shape` + `override-pass-through` rows now land on real commits.

The lesson: **prefer a bare `"matcher": "Bash"` + a cheap in-script probe over an `if`-field whenever more than one command-prefix must be matched.** A single-prefix hook can use `if: "Bash(<one-glob>)"`; anything needing alternation cannot express it in one `if` and should self-filter in the body. The intrinsic per-spawn cost is small (jq + grep + early exit); a dormant hook that silently skips its contract is far worse than an always-spawning one.

Not narrowed (correctly use bare `Bash` matcher — spawn on every Bash, filter in-body):

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

1. **Benchmark before merge.** `bash .agent0/tools/bench-hooks.sh --baseline` to add the new hook's cells. Verify p95 against the budget on the default command set.
2. **Narrow with `if` if possible.** If the hook only inspects a subset of commands (anything narrower than "every Bash invocation"), declare an `if:` field on the hook handler in `.claude/settings.json`. Use permission-rule syntax: `Bash(<glob>|<glob>|...)`. Add a comment in `settings.json` near the new entry explaining why the pattern is sufficient.
3. **Pre-jq probe inside the hook body** for any hook that can't narrow at the matcher layer. Cheapest possible check first (grep against raw stdin), full logic only on probe-hit.
4. **Commit the updated baseline.** The PR adding the hook must also update `.claude/.perf-baseline.json` so the regression check stays calibrated.
5. **Avoid audit-row writes on the fast-path.** A `skip-*` audit row that fires on every Bash call adds ~5-10 ms (jq spawn × 2 for serialization + file write) — a real cost. Document the row's forensic value in the hook's rule before keeping it.

## Maintainer gotchas

- **Pre-jq probes are not free.** `grep -qE` against a 200-byte JSON string costs ~3-5 ms. Worth it when the alternative is a 25-30 ms `jq` spawn, but not free. For hooks with very simple matchers, jq might be acceptable; measure before optimizing.
- **Hook source edits are user-facing audit trail.** The pre-jq probe added to `governance-gate.sh` is documented in the hook with a reference to spec 094 (`# Pre-jq fast-path probe (the hook-chain-latency spec-hook-chain-latency)`). Future maintainers can grep for the spec slug to understand why the probe exists. Preserve this when editing.
- **`if`-field syntax: a multi-prefix matcher CANNOT be expressed in one `if` — use a bare matcher + in-script filter.** (Superseded the original "choose generosity" advice after the 108/109 dormant-`if` discovery, see § above.) Pipe-alternation inside a `Bash(...)` is invalid permission-rule syntax — it never matches, so the hook silently never spawns. The correct shape for any hook that needs to match multiple command prefixes: bare `"matcher": "Bash"` + the hook self-filters in-body. Trade-off: a spawn on every Bash (cheap: jq + tokenise + early exit), but correct on both runtimes and no dormant-hook risk.

## Cross-references

- `.agent0/memory/hook-chain-latency.md` — companion entry (budget, bench tool, baseline shape, regression check).
- `docs/specs/094-hook-chain-latency/` — original empirical baseline + optimization decisions.
- `.agent0/memory/propagation-hygiene.md` — sibling maintainer-binding memory (fork-bound files carry no upstream-internal pointers); same shipping discipline.
