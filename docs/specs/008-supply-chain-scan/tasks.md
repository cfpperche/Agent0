# 008 — supply-chain-scan — tasks

_Generated from `plan.md` on 2026-05-11. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [ ] 1. **Write `.claude/hooks/supply-chain-scan.sh`** (PreToolUse Bash preflight). Read `tool_input.command` via `jq -r` from stdin. Exit 0 silently if `CLAUDE_SKIP_SUPPLY_CHAIN_SCAN=1`. Match against 10 manager patterns (npm/pnpm/yarn/bun/pip/uv/poetry/pdm/cargo/go) using `[[ "$cmd" =~ ... ]]` with the per-manager verb sets documented in plan.md § *Approach*. On no match → audit `decision: "skip-not-install"` + exit 0. On match → strip any `# OVERRIDE:` comment from the package extraction stage, parse the override marker separately (start-of-line anchored, ≥10 chars reason), then audit either `decision: "advisory-override"` with `override_reason` populated (suppressing stderr) or `decision: "advisory"` (emitting `supply-chain-advisory: <manager> <action> — <packages>` on stderr). Always exits 0 (never blocks). `set -uo pipefail`, `flock`-atomic audit append, JSONL one-line shape with `ts`, `session_id`, `agent_id`, `decision`, `scope: "bash"`, `manager`, `action`, `packages`, `override_reason` fields.

- [ ] 2. **Write `.claude/hooks/supply-chain-advise.sh`** (PostToolUse Edit|Write|MultiEdit advisory). Read stdin JSON. Exit 0 silently if `CLAUDE_SKIP_SUPPLY_CHAIN_SCAN=1`. Exit 0 silently if `agent_id` is null/absent in the payload (parent-edit actor split — sub-agent only). Extract `tool_input.file_path`, take basename, check against fixed manifest list (`package.json`, `pyproject.toml`, `requirements.txt`, `Cargo.toml`, `go.mod`, `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `bun.lock`, `bun.lockb`, `uv.lock`, `poetry.lock`, `pdm.lock`, `Cargo.lock`, `go.sum`). On no match → exit 0 silently (no audit). On match → emit `supply-chain-advisory: edit <basename> — manifest may have new dep` on stderr; append audit row with `decision: "advisory"`, `scope: "edit"`, `file: "<basename>"`. Always exit 0.

- [ ] 3. **Update `.gitignore`** — add `.claude/supply-chain-audit.jsonl` and `.claude/supply-chain-audit.jsonl.lock` to the ephemeral-state block (next to the existing `secrets-audit.jsonl` entries).

- [ ] 4. **Register hooks in `.claude/settings.json`** — add `bash "$CLAUDE_PROJECT_DIR"/.claude/hooks/supply-chain-scan.sh` to the existing `PreToolUse.Bash` matcher group, and add `bash "$CLAUDE_PROJECT_DIR"/.claude/hooks/supply-chain-advise.sh` to the existing `PostToolUse."Edit|Write|MultiEdit"` matcher group.

- [ ] 5. **Write `.claude/rules/supply-chain.md`** — capacity overview (advisory-only intent, two-layer shape), decision values table (`advisory`, `advisory-override`, `skip-not-install`), override grammar (`# OVERRIDE: <reason ≥10 chars>`, start-of-line, ≥10 chars after trim), manager-pattern reference table (one row per manager: manager → matched verbs → example command), env var (`CLAUDE_SKIP_SUPPLY_CHAIN_SCAN=1`), gotchas (`npm install` no-args distinction, `go get` modules behavior, override-marker-vs-package-extraction ordering trap).

- [ ] 6. **Update `CLAUDE.md`** — add `## Supply chain` section between `## Test-driven development` and `## Secrets scan`. Single paragraph mirroring the structure of `## Secrets scan`: capacity summary, hook locations, env var, override marker, link to `.claude/rules/supply-chain.md`.

- [ ] 7. **Update `README.md`** — add one row to the capacity table: `| Supply chain scan | PreToolUse(Bash) advisory on dep-install commands across npm/pnpm/yarn/bun/pip/uv/poetry/pdm/cargo/go + PostToolUse(Edit) advisory on sub-agent edits to manifest/lockfile basenames | supply-chain.md | 008-supply-chain-scan/ |`.

- [ ] 8. **Write `.claude/tests/supply-chain/run-all.sh`** — bash runner that iterates `01..06`, captures pass/fail, summary, exit non-zero on any failure. Copy structure from `.claude/tests/secrets-scan/run-all.sh` (including the `AGENT0_ROOT="${AGENT0_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"` line; path depth is the same).

- [ ] 9. **Write `.claude/tests/supply-chain/01-bash-install-advisory.sh`** — pipes synthetic PreToolUse JSON to `supply-chain-scan.sh` with `tool_input.command = "npm install axios"`. Asserts: exit 0, stderr contains `supply-chain-advisory:`, audit log gains one row with `decision: "advisory"`, `manager: "npm"`, `action: "install"`, `packages: ["axios"]`.

- [ ] 10. **Write `.claude/tests/supply-chain/02-skip-not-install.sh`** — same shape but `tool_input.command = "npm test"`. Asserts: exit 0, no stderr, audit row with `decision: "skip-not-install"`. Also covers `npm install` with no args.

- [ ] 11. **Write `.claude/tests/supply-chain/03-edit-manifest-advisory.sh`** — pipes synthetic PostToolUse JSON to `supply-chain-advise.sh` with `tool_input.file_path = "package.json"` and `agent_id` populated. Asserts: exit 0, stderr contains `supply-chain-advisory: edit package.json`, audit row with `decision: "advisory"`, `scope: "edit"`, `file: "package.json"`.

- [ ] 12. **Write `.claude/tests/supply-chain/04-parent-edit-silent.sh`** — same as #11 but `agent_id: null`. Asserts: exit 0, no stderr, no audit row appended.

- [ ] 13. **Write `.claude/tests/supply-chain/05-override-marker.sh`** — two sub-scenarios in one script: (a) `tool_input.command = "npm install axios\n# OVERRIDE: documented chart-library upgrade per PR-123"` asserts audit `decision: "advisory-override"` with `override_reason` populated, no stderr; (b) `tool_input.command = "npm install axios  # OVERRIDE: ok"` (short reason) asserts the marker is dropped and standard `decision: "advisory"` fires.

- [ ] 14. **Write `.claude/tests/supply-chain/06-env-var-disable.sh`** — sets `CLAUDE_SKIP_SUPPLY_CHAIN_SCAN=1` for two invocations (one Bash hook, one Edit hook). Asserts: both exit 0 silently, no audit rows written, no stderr output.

- [ ] 15. **Run `bash .claude/tests/supply-chain/run-all.sh`** — confirm all 6 scenarios pass. If any fails, fix the underlying hook and re-run; update plan.md if a fix reveals the plan was wrong.

## Verification

_Each line maps 1:1 to a `spec.md` acceptance criterion._

- [ ] Scenario "Bash dep-install triggers advisory + audit" — covered by `01-bash-install-advisory.sh` (T9).
- [ ] Scenario "non-dep Bash command audits skip and falls through silently" — covered by `02-skip-not-install.sh` (T10).
- [ ] Scenario "sub-agent Edit on dep manifest triggers advisory" — covered by `03-edit-manifest-advisory.sh` (T11).
- [ ] Scenario "parent edit on dep manifest passes through silently" — covered by `04-parent-edit-silent.sh` (T12).
- [ ] Scenario "override marker recorded in audit, advisory suppressed" — covered by `05-override-marker.sh` part (a) (T13).
- [ ] Scenario "short override reason rejects the marker (still advises)" — covered by `05-override-marker.sh` part (b) (T13).
- [ ] Scenario "env-var disables both layers" — covered by `06-env-var-disable.sh` (T14).
- [ ] Scenario "missing package-manager binary still produces an audit row" — implicit in all of T9-T13: no test asserts manager-binary presence because the hook never invokes the manager. Documented in plan.md § *Risks*; no separate test script needed.
- [ ] `.claude/hooks/supply-chain-scan.sh` exists, executable, registered in settings.json (T1, T4).
- [ ] `.claude/hooks/supply-chain-advise.sh` exists, executable, registered in settings.json (T2, T4).
- [ ] `.claude/supply-chain-audit.jsonl` gitignored, append-only, `flock`-atomic (T3 + audit primitives in T1/T2).
- [ ] `.claude/rules/supply-chain.md` documents the capacity (T5).
- [ ] CLAUDE.md `## Supply chain` section present (T6).
- [ ] README capacity table has a `Supply chain scan` row (T7).

## Notes

- Implementation is parent-driven (no `Agent` delegation needed — scope is small, no model-discipline signals fire). If a future tier-2 spec adds blocking behavior and grows the diff substantially, that might be a delegation candidate.
- Test scripts are pure POSIX shell + `jq` — no language runtime, consistent with the existing `.claude/tests/secrets-scan/` suite.
- Hook scripts share primitives (flock audit append, JSON-from-stdin parsing) with `secrets-scan.sh`. Copy the shape rather than abstracting into a shared helper — each hook should be readable and standalone.
- Once landed, this capacity inherits all the gotchas already documented in `.claude/rules/secrets-scan.md` § *Gotchas* (byte-level regex false-positives in commit messages, `# OVERRIDE:` survival through JSON payload, `flock` atomicity rationale, etc.). Cross-reference where relevant rather than duplicate text.
