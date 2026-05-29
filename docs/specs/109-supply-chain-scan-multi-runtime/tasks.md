# 109 — supply-chain-scan-multi-runtime — tasks

_Generated from `plan.md` on 2026-05-28. Work top-to-bottom; check off as completed. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Move + script edits

- [x] 1. `git mv .claude/hooks/supply-chain-scan.sh .agent0/hooks/supply-chain-preflight.sh`
- [x] 2. Update the script's header comment block: new path, new name, drop the "renamed" rationale note (mirror `secrets-preflight.sh` header), note it sources `_memory-hook-lib.sh`
- [x] 3. Source `_memory-hook-lib.sh` near the top (after `set -uo pipefail`, before stdin capture); resolve its dir relative to the script (`SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`, source `"$SCRIPT_DIR/_memory-hook-lib.sh"`), fail-open if absent
- [x] 4. Replace `PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"` (line ~92) with `PROJECT_DIR="$(memory_project_dir "$INPUT")"` — must run AFTER `INPUT` is captured; confirm the bare-install `git -C "$PROJECT_DIR" status --porcelain` probe now inherits the corrected root
- [x] 5. Set `AUDIT_LOG="$PROJECT_DIR/.agent0/supply-chain-audit.jsonl"`
- [x] 6. Compute `RUNTIME="$(memory_runtime "$INPUT")"` once; add `runtime:$RUNTIME` to the `append_audit` JSON object (new `--arg`/field); thread it so every emitted row carries it (block / block-override / advisory / advisory-override / advisory-bare-install / advisory-bare-install-override)
- [x] 7. Drop the `skip-not-install` row: at the no-detection terminus (line ~396) replace `append_audit "skip-not-install"; exit 0` with a silent `exit 0`; verify the bare-install-without-dirty-manifest fall-through also exits silently (no row)
- [x] 8. Sanity self-check: `bash -n .agent0/hooks/supply-chain-preflight.sh` clean; direct-invoke with a synthetic `npm install axios` payload → exit 2 + audit row carrying `runtime`; synthetic `ls` payload → exit 0, NO row

## Registration + cascade

- [x] 9. `.claude/settings.json` (PreToolUse, ~lines 75-84): repoint command to `.agent0/hooks/supply-chain-preflight.sh` AND **delete the `if: "Bash(npm *|…)"` line** — keep bare `"matcher": "Bash"`
- [x] 10. `.codex/config.toml.example`: add a commented `[[hooks.PreToolUse]] matcher = "^Bash$"` block after the secrets-preflight block (~line 107), command `bash "$(git rev-parse --show-toplevel)/.agent0/hooks/supply-chain-preflight.sh"`, with a comment noting block-mode default + no rewrite path
- [x] 11. `.claude/hooks/supply-chain-advise.sh`: repoint `AUDIT_LOG` to `.agent0/supply-chain-audit.jsonl` (split-log fix) AND update stale `.claude/hooks/supply-chain-scan.sh` comment refs to the new preflight path
- [x] 12. `.gitignore`: `.claude/supply-chain-audit.jsonl` → `.agent0/supply-chain-audit.jsonl`
- [x] 13. `grep -rn 'supply-chain-scan'` across the repo; fix every remaining ref (comment-only refs in `runtime-capture.sh`, any others surfaced)

## Tests + perf harness

- [x] 14. `.claude/tests/supply-chain/*.sh` (13) + `.claude/tests/supply-chain-composer/*.sh` (4) + run-all: update hook path + AUDIT_LOG path
- [x] 15. Rewrite `.claude/tests/supply-chain/02-skip-not-install.sh` to assert the no-detection case produces silent exit 0 with **no new audit row** (was: asserts a `skip-not-install` row)
- [x] 16. Perf/latency rename: `.agent0/tools/bench-hooks.sh` (`HOOK_NAMES`), `.claude/.perf-baseline.json` (filename-keyed baseline entry), `.claude/tests/hook-chain-latency/01-baseline-exists.sh` — `supply-chain-scan` → `supply-chain-preflight`
- [x] 17. Run the full supply-chain + composer test suites + `01-baseline-exists.sh`; all green

## Docs + memory

- [x] 18. `.claude/rules/supply-chain.md`: `paths:` frontmatter (`.agent0/hooks/supply-chain-*.sh` + `.agent0/supply-chain-audit.jsonl`); body — new name/path, Codex `^Bash$` activation note, dropped-`skip-not-install` documented as deliberate, bare-matcher-not-`if` recorded as a gotcha (cite the pipe-alternation invalidity)
- [x] 19. `CLAUDE.md`, `AGENTS.md`, `README.md`: path index references updated
- [x] 20. Refresh memory entries touching the old path: `capacity-spec-index.md`, `cc-platform-hooks.md`, `hook-chain-latency.md`, `hook-chain-maintenance.md`, `rule-load-debug.md`, `runtime-introspect-maintenance.md` (run `bash .agent0/tools/memory-maintain.sh finalize <entry>` per the hook-disabled discipline if applicable)

## Verification (acceptance)

- [x] 21. **Acceptance sweep:** `grep -rn 'supply-chain-scan'` returns nothing outside `docs/specs/`; the moved hook is executable; all 17 supply-chain tests + baseline test pass; a synthetic Codex-shape payload (no `CLAUDE_PROJECT_DIR`, with `cwd`) audits `runtime:"codex-cli"`; a Claude-shape payload audits `runtime:"claude-code"`
- [x] 22. **Live Claude dogfood (cold restart required):** after a full `claude` restart, in a scratch git repo run `cargo add tokio` (expect exit-2 block + `.agent0/supply-chain-audit.jsonl` row `runtime:"claude-code"`/`decision:"block"`), then the override two-line form (expect `block-override`, `override_reason` set). Record evidence in `notes.md` — tests passing is NOT sufficient (108's dormant-`if` lesson)
- [x] 23. **Codex live dogfood:** enable the `.codex/config.toml` block, restart/trust Codex, run `pip install requests`, confirm exit-2 block + `runtime:"codex-cli"` audit row, then run the override pass-through and record both rows in `notes.md`.
- [x] 24. Update `spec.md` acceptance checkboxes to `[x]` as each scenario is verified; set `**Status:** shipped` only when 21+22 are green (23 may remain a flagged handoff item, as 108 did)
