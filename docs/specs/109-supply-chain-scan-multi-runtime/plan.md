# 109 — supply-chain-scan-multi-runtime — plan

_Drafted from `spec.md` on 2026-05-28. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

`git mv` + rename `.claude/hooks/supply-chain-scan.sh` → `.agent0/hooks/supply-chain-preflight.sh`, then make four edits to the script body: (1) source `_memory-hook-lib.sh` and replace `PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"` with `memory_project_dir "$INPUT"` (this single change fixes both the audit-log location AND the bare-install `git -C "$PROJECT_DIR" status` probe — they share the variable); (2) add a `runtime` field (from `memory_runtime "$INPUT"`) to every audit row; (3) move the audit log to `.agent0/supply-chain-audit.jsonl`; (4) drop the `skip-not-install` audit row — non-detection Bash now exits silently with no row. Unlike 108 there is **no command-rewrite path**, so no `permissionDecision`/`updatedInput` output and no runtime-branched stdout — `memory_runtime` is used only for the audit `runtime` tag. Then fix the dormant registration (bare `"matcher": "Bash"`, drop the invalid `if`-pipe) and cascade every reference (settings, codex example, gitignore, the advise sibling's audit path, tests, perf harness, rule, doc index, memory).

The detection engine — manager table, verb whitelists, tokeniser terminators, value-taking-flag allowlist, block-vs-advisory modes, override grammar, bare-install sub-path — is preserved **verbatim**. This is a relocation + registration-fix + audit-provenance change, not a detection-logic change.

## Key decisions

- **Bare `"matcher": "Bash"`, no `if`.** The current `if: "Bash(npm *|pnpm *|…)"` is invalid CC permission-rule syntax (pipe-alternation unsupported → dormant). The script already self-filters (audits/blocks only on a real `(manager, verb, packages)` triple), so the in-script filter is the precise layer and the matcher is just the broad trigger. Mirrors 108. The valid-but-Claude-only 11-`if`-handler alternative is rejected (see Alternatives).
- **Drop `skip-not-install` (Q2, user-confirmed).** Under the broad matcher the hook runs on every Bash; a forensic row per `ls`/`cat` is a firehose. Non-detection → silent, no audit. Real detections (block/advisory/bare-install) still audit. Edits `02-skip-not-install.sh` to assert silent-no-row.
- **Rename file (Q3, user-confirmed)** to `supply-chain-preflight.sh`. Keep slug/test-dir/audit-filename (`supply-chain`, `supply-chain-audit.jsonl`).
- **Root + git-probe via `memory_project_dir "$INPUT"`** replaces `${CLAUDE_PROJECT_DIR:-$PWD}` — fixes Codex subdirectory-cwd for both the log path and the dirty-manifest probe.
- **Audit hard-cutover** to `.agent0/supply-chain-audit.jsonl` (no legacy-read, per 106/108), `runtime` field added (`claude-code`/`codex-cli`). All other decision values unchanged; `skip-not-install` retired.
- **`supply-chain-advise.sh` audit path repointed, NOT ported.** The advise hook (a non-goal to port) ALSO writes audit rows; leaving it at `.claude/supply-chain-audit.jsonl` while the preflight writes to `.agent0/` would split the log. So its `AUDIT_LOG` constant is repointed to `.agent0/supply-chain-audit.jsonl` (one-line edit). This is a consequence of the hard-cutover, distinct from the deferred runtime-neutral port (apply_patch path-extraction, `.agent0/` move) which stays out of scope.

## Files to touch

**Move + edit:**
- `.claude/hooks/supply-chain-scan.sh` → `.agent0/hooks/supply-chain-preflight.sh` (`git mv` + the 4 body edits + source the lib + update the header comment block)

**Modify:**
- `.claude/settings.json` — repoint command to `.agent0/hooks/supply-chain-preflight.sh`; **delete the `if: "Bash(npm *|…)"` line** (lines 75-84), keep bare `"matcher": "Bash"`
- `.codex/config.toml.example` — new commented `[[hooks.PreToolUse]] matcher = "^Bash$"` block after the secrets-preflight block (~line 107), pointing at the moved hook
- `.claude/hooks/supply-chain-advise.sh` — repoint `AUDIT_LOG` to `.agent0/supply-chain-audit.jsonl` + update stale `.claude/hooks/supply-chain-scan.sh` comment refs to the new path
- `.gitignore` — audit path `.claude/supply-chain-audit.jsonl` → `.agent0/supply-chain-audit.jsonl`
- `.claude/tests/supply-chain/*.sh` (13) + `.claude/tests/supply-chain-composer/*.sh` (4) + any run-all — hook path + AUDIT_LOG path; **`02-skip-not-install.sh` rewritten** to assert silent-no-audit-row instead of a `skip-not-install` row
- `.agent0/tools/bench-hooks.sh` (`HOOK_NAMES`), `.claude/.perf-baseline.json` (filename-keyed baseline), `.claude/tests/hook-chain-latency/01-baseline-exists.sh` — rename key `supply-chain-scan` → `supply-chain-preflight`
- `.claude/rules/supply-chain.md` — `paths:` frontmatter glob (`.claude/hooks/supply-chain-*.sh` → `.agent0/hooks/supply-chain-*.sh`, audit path), new name/path in body, Codex activation note, dropped-`skip-not-install` decision, bare-matcher-not-`if` gotcha
- `CLAUDE.md`, `AGENTS.md`, `README.md` — path index references
- comment-only path refs flagged by `grep -rn supply-chain-scan`: `runtime-capture.sh`, plus any memory files
- memory refresh: `capacity-spec-index.md`, `cc-platform-hooks.md`, `hook-chain-latency.md`, `hook-chain-maintenance.md`, `rule-load-debug.md`, `runtime-introspect-maintenance.md`

## Alternatives considered

### 11 separate `if` handlers (one per manager) on Claude
Rejected. The official docs confirm this is the *valid* way to narrow on Claude (`if: "Bash(npm *)"`, `if: "Bash(pnpm *)"`, …), and it would avoid the per-Bash process spawn AND keep `skip-not-install` meaningful (rare). But: (a) Codex has no `if`-equivalent — it matches the tool-name regex `^Bash$` only — so the script must self-filter for Codex regardless; 11 Claude handlers would create a two-mechanism runtime divergence (Claude narrows via config, Codex narrows in-script). (b) 11 settings.json entries to maintain vs one. (c) 108 set the bare-matcher precedent and accepted the per-Bash spawn cost. One consistent mechanism (in-script filter) across both runtimes wins over a Claude-only perf micro-opt.

### Keep the `-scan` name (move only, no rename)
Rejected (Q3, user-confirmed rename). Would avoid the perf-harness filename-key ripple, but breaks the parallel with `secrets-preflight.sh` and keeps a name that materially overstates the layer (it gates command shapes, scans no dependency contents).

### Keep audit log at `.claude/`
Rejected. 106/108 set the `.agent0/` hard-cutover precedent; both writers (preflight + the advise sibling, via its repointed constant) are reachable. A split log (preflight in `.agent0/`, advise in `.claude/`) is the worse outcome.

### Bundle the `supply-chain-advise.sh` runtime-neutral port here
Rejected (mirrors 108's deferral of `secrets-advise.sh`). The advise port needs `apply_patch` path-extraction for Codex — a separate edit-surface unit. 109 repoints only its audit-log constant (to avoid the split), nothing more.

## Risks and unknowns

- **Codex live dogfood is human-dependent.** Requires editing local `.codex/config.toml`, restarting Codex, running a real `pip install foo`. I validate everything else (Claude block live after cold-restart, all 17 tests, grep-clean, perf baseline, synthetic Codex-payload audit-runtime tag). The Codex live step is a handoff item, not silently claimed — same posture as 108.
- **Live Claude verification requires a COLD restart**, not `/resume` or `/clear` (settings.json hook registrations only reload on cold start — handoff gotcha). The dormant-`if` fix won't take effect mid-session; the block scenario must be verified in a fresh `claude` process.
- **Per-Bash spawn latency.** Under the bare matcher the hook spawns on every Bash; the script is heavier than secrets-preflight (tokeniser loop + a `git status --porcelain` on bare-install). Early-exit on no-match keeps the common path cheap, but the perf-baseline update should confirm the latency stays within the documented envelope.
- **Split-log regression if the advise repoint is forgotten.** The single highest-risk omission: if `supply-chain-advise.sh`'s `AUDIT_LOG` is not repointed, edit-scope rows silently keep landing in `.claude/supply-chain-audit.jsonl`. Acceptance + a grep-clean check guard this.
- **`runtime` detection edge.** `memory_runtime` returns `codex-cli` when `CLAUDE_PROJECT_DIR` is unset. Tests export `CLAUDE_PROJECT_DIR` → `claude-code` (correct for the Claude-shape assertions); a synthetic Codex payload (no `CLAUDE_PROJECT_DIR`, with `cwd`) drives the `codex-cli` audit-tag assertion.

## Research / citations

- Official Claude Code hooks docs (verified 2026-05-28): <https://code.claude.com/docs/en/hooks> — `if` field uses permission-rule syntax; _"There is no `&&`, `||`, or list syntax for combining rules; to apply multiple conditions, define a separate hook handler for each"_ — confirms the pipe-alternation `if` is dormant and the bare-matcher fix is correct.
- Official Codex hooks docs (verified 2026-05-28): <https://developers.openai.com/codex/hooks> — `^Bash$` matcher, exit-2 block (no rewrite path needed here).
- `docs/specs/108-secrets-scan-multi-runtime/{spec,plan,notes}.md` — the direct template (dormant-`if` diagnosis, rename rationale, broad-matcher audit-spam drop, `_memory-hook-lib.sh` sourcing, Codex activation block, live-dogfood-required lesson).
- `.agent0/hooks/_memory-hook-lib.sh` — `memory_project_dir()` / `memory_runtime()` signatures (read 2026-05-28).
- `.agent0/hooks/secrets-preflight.sh` — sibling shape for lib sourcing + audit `runtime` tagging.
- `.claude/rules/secrets-scan.md` § *What fires* + § *Audit log* — the canonical write-up of the bare-matcher / dropped-`skip-not-commit` decisions this port mirrors.
