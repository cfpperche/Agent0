# 107 — governance-gate-refinement — tasks

_Generated from `plan.md` on 2026-05-28. Work top-to-bottom. Check boxes as tasks complete._

## Implementation

- [x] 1. **rm family widen** — block `rm -r -f` / `rm -f -r` / separate `-R` variants in addition to the combined `-rf`/`-fr` token. Preserve non-blocks: `rm -r` (no force), `rm -i`, `grep -rf`. `bash -n`.
- [x] 2. **git clean family** — block `git clean` when force (`-f`/`--force`, incl. inside a combined short cluster like `-fdx`) AND broad (`-d`/`-x`/no pathspec); allow `-n`/`--dry-run`.
- [x] 3. **whole-tree checkout/restore family** — block `git checkout -- .`, `git checkout -- :/`, `git restore .`, `git restore :/`, index-wide `git restore --staged .`; allow `git checkout -- <file>`, branch switches, targeted `git restore <path>`.
- [x] 4. **fast-path probe extension + comment fix** — add `clean`/`checkout`/`restore` keywords to the pre-jq probe regex in lockstep with families 2-3; correct the "falls through to the jq path" comment to document early-exit + the probe-superset invariant.
- [x] 5. **header doc** — expand the gate header to record the 3 families, the "common-obvious destructive shapes — not a sandbox" principle, and the override grammar. Thin; no catalog.
- [x] 6. **test suite** — `.claude/tests/governance-gate/` with: rm shapes (block + non-block), git clean force/dry-run, whole-tree vs targeted checkout/restore, drift-guard (probe ⊇ families), override valid/invalid, settings registration, shellcheck/bash -n + `run-all.sh`. Run in place.
- [x] 7. **move + register** — move `.claude/hooks/governance-gate.sh` → `.agent0/hooks/`; repoint `.claude/settings.json` `PreToolUse(Bash)`; add commented `[[hooks.PreToolUse]]` matcher `"^Bash$"` → `.agent0/hooks/governance-gate.sh` to `.codex/config.toml.example`; update the suite's hook path to `.agent0/`.
- [x] 8. **revalidate + dogfood** — re-run the suite against the moved hook; `bash -n`; live-dogfood a real blocked + allowed Bash command through the live gate.

## Verification

- [x] `rm -r -f x` blocked; `rm -r x` / `rm -i x` / `grep -rf p .` allowed.
- [x] `git clean -fdx` blocked; `git clean -n` allowed.
- [x] `git checkout -- .` / `git restore .` blocked; `git checkout -- file.txt` / `git checkout main` allowed.
- [x] drift-guard test passes (every family-blocked shape also hits the probe).
- [x] override `# OVERRIDE: <≥10 chars>` allows; `<10 chars` still blocks.
- [x] gate at `.agent0/hooks/governance-gate.sh`; `settings.json` points there; `.codex/config.toml.example` has the commented Bash block; old `.claude/hooks/` copy gone.
- [x] suite green; `bash -n` clean; live dogfood confirms block+allow.

## Notes

- The gate reads only `tool_input.command` — no `PROJECT_DIR`, no state — so the `.agent0/` move needs no `_memory-hook-lib` and no runtime branch (unlike spec 106's stop hook).
- Port is BUNDLED per user decision (overrode the debate's keep-separate lean). secrets-scan + supply-chain-scan ports remain a later batch.

## Dogfood (both runtimes, live)

- **Claude (2026-05-28):** live-dogfooded in the implementing session — the moved gate blocked a real `rm -rf` (exit 2, message from `.agent0/hooks/governance-gate.sh` with the refined "rm with recursive (-r/-R) and force (-f) flags" trigger), allowed an ordinary command, AND blocked the implementer's own commit (message body contained `rm -r -f`) — resolved by committing via a message file. The gate doesn't trust its own author.
- **Codex (2026-05-28, independently dogfooded):** `.codex/config.toml` with `[features] hooks=true` + active `[[hooks.PreToolUse]]` matcher `^Bash$` → `.agent0/hooks/governance-gate.sh`. Three cases: (a) `rm -rf /tmp/<nonexistent>` → BLOCKED (`governance-gate: blocked [destructive]`, exit-2 semantics); (b) `echo …` → ALLOWED; (c) same `rm -rf … # OVERRIDE: <≥10 chars>` → ALLOWED. Verdict PASS — Codex fires PreToolUse(Bash) at the `.agent0/` path with identical block/allow/override behavior. Confirms the clean Bash-surface port has zero runtime asymmetry (unlike spec 106's delegation split).
