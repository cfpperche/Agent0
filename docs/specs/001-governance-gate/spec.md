# 001 — governance-gate

_Created 2026-05-10. Status: draft._

## Intent

A single `PreToolUse(Bash)` hook that enforces a project-wide safety floor against the LLM agent itself: blocks a small, fixed set of destructive / hook-bypassing / blanket-staging shell patterns unless the agent acknowledges intent via one inline override marker. Local-only enforcement (no CI mirror).

The hook protects the human from agent mistakes the agent cannot self-correct: irreversible filesystem damage, force-pushes that overwrite shared history, secret leaks via blanket `git add`, and the meta-attack of disabling other safety hooks via `--no-verify`.

## Pattern families in scope (exactly 3 — no more, no less)

1. **Destructive ops**
   - `rm -rf` and combined-flag variants (`-fr`, `-Rf`, `-fR`, `-rfv`, `-arf`, etc.)
   - `git push --force` and `git push -f`
   - `git reset --hard`

2. **Hook bypass (meta-defense)**
   - `git commit --no-verify`
   - `git push --no-verify`
   Without this family, `--no-verify` would silently disable the other two.

3. **Blanket staging**
   - `git add -A`, `git add --all`, `git add .`, `git add *`
   - `git commit -a`, `-am`, `-ma`, `--all`
   Rationale: secret leaks (`.env`), artifact pollution (`node_modules`), parallel-session interference.

## Override contract — the ONLY escape

Single inline marker: `# OVERRIDE: <reason>` where the reason is **≥10 characters after whitespace trim, after the literal `OVERRIDE:` token**. Case-sensitive — `BYPASS`, `Override`, etc. are NOT accepted.

Example:

```
rm -rf node_modules  # OVERRIDE: clean reinstall after lockfile corruption
```

If the marker is present and valid → exit 0 (allow). If any pattern matches and the marker is absent or invalid → exit 2 (block) with stderr identifying the family, the trigger, and how to override.

## Acceptance criteria

- [ ] Hook file at `.claude/hooks/governance-gate.sh`, executable
- [ ] Registered on `PreToolUse` with matcher `"Bash"` in `.claude/settings.json`
- [ ] `set -uo pipefail` (no `-e`)
- [ ] bash 3.2-compatible (no associative arrays, no `mapfile`, `cp -R` not `-r`)
- [ ] `jq` is a hard dependency; missing jq → fail closed (exit 2)
- [ ] Reads CC PreToolUse JSON from stdin, extracts `.tool_input.command` via `jq -r`
- [ ] Empty/missing command → exit 0
- [ ] Pattern check order: destructive → no-verify → blanket-staging; first match wins; stderr names the family
- [ ] Live smoke: `rm -rf /tmp/whatever` blocks; same command with valid `# OVERRIDE:` marker passes
- [ ] Live smoke: one no-verify case blocks
- [ ] Live smoke: one blanket-staging case blocks

## Non-goals

- A 4th pattern family (no broader scope creep)
- Splitting into multiple hook files (one consolidated gate)
- CI / server-side mirror of these rules
- An allowlist file or env-var bypass — override marker is the only escape, by design
- Case-insensitive marker or synonyms (`BYPASS`, `SKIP`, etc.)
- Implementation in Node / Python
- Long-form `rm --recursive --force` coverage (explicitly out of scope per user brief)
- `--force-with-lease` blocking (safer than `--force`, distinct flag, out of scope)

## Context

User-supplied brief in conversation 2026-05-10. Brief originally specified top-level `hooks/`; aligned with project pattern under `.claude/hooks/` alongside session-start, session-stop, pre-compact for consistency and auditability.
