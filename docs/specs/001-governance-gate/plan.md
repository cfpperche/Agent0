# 001 — governance-gate — plan

_Drafted from `spec.md` on 2026-05-10._

## Approach

Single bash script `.claude/hooks/governance-gate.sh` runs on every `PreToolUse(Bash)` event. Flow:

1. Read JSON from stdin → extract `.tool_input.command` via `jq -r`.
2. If the command contains a valid `# OVERRIDE: <reason ≥10 chars>` marker → exit 0 (allow).
3. Otherwise run pattern checks in fixed order (destructive → no-verify → blanket-staging). First match wins.
4. On match: write helpful stderr (family, trigger, command, how to override) and exit 2.
5. No match: exit 0.

Patterns are POSIX-ERE regexes. The script uses no Bash-4 features (no associative arrays, no `mapfile`) so it survives macOS bash 3.2.

## Files to touch

**Create:**
- `.claude/hooks/governance-gate.sh` — the gate, alongside the other CC hooks

**Modify:**
- `.claude/settings.json` — register `PreToolUse` with matcher `"Bash"`

**No deletes.**

## Regex strategy

POSIX-ERE (`grep -E`), with these design choices:

- **Word boundaries** (`\b`) on command names so `git` doesn't match `git-foo` and `rm` doesn't match `arm`.
- **`[^|;&]*` between command name and flag** to prevent the flag matcher bleeding across `;`/`|`/`&&` into an unrelated downstream command. Real CC tool calls rarely chain, so this is a cheap robustness win.
- **`([[:space:]]|$)` after flag tokens** as a terminator. This is what excludes `--force-with-lease` from the `--force` matcher (the `-` after `force` is a non-whitespace, non-EOL char), and what excludes `-fast` from the `-f` matcher.
- **Combined-flag `rm`**: pattern `-([a-zA-Z]*[rR][a-zA-Z]*[fF]|[a-zA-Z]*[fF][a-zA-Z]*[rR])[a-zA-Z]*` — at least one `r/R` and one `f/F` in any order, possibly with other letters. Catches `-rf`, `-fr`, `-Rf`, `-fR`, `-rfv`, `-arf`. Does **not** catch `rm --recursive --force` (out of scope per spec).
- **Combined-flag `git commit -a*`**: pattern `-[a-zA-Z]*a[a-zA-Z]*` — `a` anywhere in a short-flag cluster. Catches `-a`, `-am`, `-ma`, `-amS`. Plus `--all` separately.

## Override extraction

`grep -oE '# OVERRIDE: .*'` extracts from the marker to end-of-line. Strip prefix, trim leading/trailing whitespace, count bytes. ≥10 chars → valid. The marker is case-sensitive by simply not using `-i`.

Edge case: marker inside a string literal (`echo "# OVERRIDE: spoof"`) would still match. The gate is a discipline against the agent, not a syntactic sandbox; bad-faith bypass is out of scope.

## Fail-closed on missing jq

Per spec, `jq` is a hard dependency. If `jq` is missing or input is malformed JSON, the hook exits 2 (block). Costs UX: every Bash call breaks until `jq` is installed. But "silent fallback" would mean governance silently disabled — the opposite of the design intent.

Implementation: `if ! CMD="$(... | jq -r ...)"; then echo "..." >&2; exit 2; fi`. Works because `set -uo pipefail` (no `-e`) lets us inspect the pipeline status without auto-exit.

## Alternatives considered

### Multiple hook files (one per family)

Rejected. Spec explicitly forbids: "Don't split into multiple hook files — one consolidated gate." Reason: a single gate is one thing to audit, one trigger order to reason about, one place where overrides land. Splitting fragments the contract.

### Allowlist file (`.governance-allow`)

Rejected. Spec explicitly forbids. Reason: allowlists drift, get stale, accumulate cruft, and create a "just add to the list" muscle that defeats the gate. The inline override marker forces a per-call decision with reasoning visible in conversation/git history.

### Top-level `hooks/` (per original brief)

Considered, then aligned with project pattern. Brief specified top-level `hooks/` — plausible reasoning would be separating governance/policy from CC lifecycle. Rejected because: (1) all four hooks fire from the same harness with the same shape, splitting them is artificial; (2) `.claude/hooks/` is the canonical location, top-level `hooks/` would be a one-off; (3) auditability wins when all hooks are co-located.

### Implementation in Node (matching statusline.mjs)

Rejected. Spec explicitly forbids: "Don't write the hook in Node/Python — bash 3.2 + jq, period." Reason: bash + jq is portable, near-zero startup, no dep install. Node would add latency to every Bash tool call.

## Risks and unknowns

- **PreToolUse mid-session activation**: unclear whether registering a new PreToolUse hook in `.claude/settings.json` activates in the current session or only the next one. The spec's "Sanity-check live in the same session" wording assumes yes. Will know after smoke test.
- **Regex false positives**: e.g., a comment like `# this is a -rf cleanup` inside a here-doc could theoretically match. Practically rare in CC tool calls. Accepted.
- **Override marker in string literal**: as noted above. Accepted — gate is anti-mistake, not anti-malice.
- **`--force-with-lease` excluded**: the spec listed `--force` and `-f` specifically. `--force-with-lease` is technically also a force push, but safer. Following spec literally: not blocked. Note this loophole in the spec's non-goals.

## Research / citations

- User-supplied brief, conversation 2026-05-10 (the spec itself is the primary source).
- Claude Code PreToolUse hook docs: exit-code semantics (0 = allow, 2 = block, stderr surfaces in re-prompt).
- Existing repo patterns: `.claude/hooks/session-start.sh`, `pre-compact.sh`, `session-stop.sh` for hook style; `.claude/settings.json` for registration shape.
