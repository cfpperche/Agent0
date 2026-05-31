# 129 — claude-exec — plan

_Drafted from `spec.md` on 2026-05-30. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

`claude-exec` and `codex-exec` are **siblings in purpose, not clones in code**: both let one runtime invoke another model's brain as a bounded non-interactive subprocess and read back a file-based result with an audit trail. We reuse the *bridge contract* the codex-exec dogfood proved sound, but the *mechanics* are rewritten around the reality of `claude -p`, which differs from `codex exec` in several load-bearing ways (no native last-message file → `jq` extraction; a permission axis instead of a filesystem sandbox; tool allowlists; session-id capture; `--add-dir` semantics). Porting here is refinement, not transcription.

Build order: (1) the helper `scripts/claude-exec.sh` — the deterministic core; (2) `SKILL.md` describing the bridge; (3) `agents/openai.yaml` so Codex discovers it; (4) the two discovery symlinks; (5) a test suite under `.agent0/tests/claude-exec-skill/` mirroring the codex-exec suite's *structure* (arg-parsing, mapping, resume, missing-dependency) but asserting Claude-specific behavior; (6) validation via `/skill validate` + `check-rubric` + `bash -n`; (7) a live smoke + the Codex-side dogfood prompt the goal asks for.

### Shared with codex-exec (the bridge contract — keep identical in spirit)

- Layout: `SKILL.md` + `scripts/<name>.sh` + `agents/openai.yaml` + `.claude/skills/<name>` & `.agents/skills/<name>` symlinks to the one canonical `.agent0/skills/<name>/` source.
- `set -euo pipefail`, argv arrays, **never `eval`**, `die()` usage errors to stderr exit 2, surface child exit code + stderr (no masking).
- Prompt sources: `--task` / `--task-file` / stdin / `-- <prompt...>`; one-source guard.
- Run dir `STATE_ROOT/<timestamp>-<slug>`; slug derive+validate (kebab-case); `--slug` override.
- Artifacts: `prompt.md`, `last-message.md`, `metadata.json`, aggregate `runs.jsonl`, `stderr.txt`, `command.txt`; `--json` → `events.jsonl`.
- `--output` containment guard: `realpath -m` + parent must be under `STATE_ROOT_REAL` (the hardened spec-128 behavior — inherit it, don't re-introduce the gap).
- Fail-clean if a required dependency is missing, before creating a success-looking dir.

### Idiomatic to Claude (where it diverges — by design, not accident)

- Invocation: `claude -p` (not `codex exec -`). Resume: `claude -p --resume <id>` (not `exec resume <id> -`).
- **Permission axis is pass-through, required, no default.** `--permission-mode <native>` forwarded verbatim (`default|plan|acceptEdits|bypassPermissions|dontAsk|auto`); absent → refuse. This is stricter than codex-exec's `--sandbox` default-of-read-only — deliberately, because Claude's permission axis is more consequential.
- New flags with no codex-exec analog: `--allowedTools` / `--disallowedTools` (compose read-only review), `--add-dir <dir>` (grant access, repo-root-contained — *not* a cwd change like codex's `--cd`), `--bare` (opt-in context-hygiene).
- Dropped: `--profile` (Codex config concept; no clean Claude 1:1 in v1), `--cwd`/`--cd` as a working-root switch (replaced by `--add-dir` semantics).
- **Last-message extraction via `jq`.** Claude has no `--output-last-message`. Without `--json`: `--output-format json` → `jq -r '.result'` → `last-message.md`, `jq -r '.session_id'` → metadata. With `--json`: `--output-format stream-json --verbose` → `events.jsonl`, then `jq` the final `type=="result"` event → `last-message.md` + `session_id`. `jq` becomes a hard dependency checked up front.
- Metadata gains `permission_mode`, `allowed_tools`, `disallowed_tools`, `add_dir`, `bare`, `session_id`; loses `sandbox`, `profile`, `cwd`.
- No launcher: invoke `claude` directly (claude self-discovers config + anchors on cwd; a `claude-local-env.sh` would be ceremony).

## Files to touch

**Create:**
- `.agent0/skills/claude-exec/scripts/claude-exec.sh` — the helper (executable, `set -euo pipefail`, argv arrays).
- `.agent0/skills/claude-exec/SKILL.md` — agentskills.io frontmatter + bridge docs (subprocess orchestration, not native delegation).
- `.agent0/skills/claude-exec/agents/openai.yaml` — Codex discovery + `policy.allow_implicit_invocation: true`.
- `.agent0/tests/claude-exec-skill/_lib.sh` — shared test harness (stub `claude`/`jq` on PATH, temp STATE_DIR via `CLAUDE_EXEC_STATE_DIR`).
- `.agent0/tests/claude-exec-skill/01-required-permission-mode.sh` — refuse when `--permission-mode` absent (fail-closed, no dir created).
- `.agent0/tests/claude-exec-skill/02-parameter-mapping.sh` — argv mapping incl. allowlists/add-dir/json; unknown-flag rejected; `--output` guard.
- `.agent0/tests/claude-exec-skill/03-resume.sh` — `--resume <id>` shape + session-id recorded.
- `.agent0/tests/claude-exec-skill/04-missing-dependency.sh` — clean fail when `claude` or `jq` absent.
- `.agent0/tests/claude-exec-skill/run-all.sh` — runner.

**Modify:**
- (none expected) `.gitignore` already covers `.agent0/.runtime-state/*`; confirm during implementation.

**Create (symlinks):**
- `.claude/skills/claude-exec` → `../../.agent0/skills/claude-exec`
- `.agents/skills/claude-exec` → `../../.agent0/skills/claude-exec`

**Delete:**
- (none)

## Alternatives considered

### Clone codex-exec.sh and find/replace `codex`→`claude`

Rejected — the user's explicit steer and the repo's "port = refinement, not transcription" discipline. A find/replace would carry over `--sandbox`/`--profile`/`--cd` (wrong axis for Claude), miss the `jq` extraction Claude *requires* (Codex has `--output-last-message`, Claude does not), and silently default the permission mode (the opposite of the agreed fail-closed). The shared contract is real; the mechanics are not.

### Build a permission abstraction (`--mode read-only|write|danger`)

Rejected (was OQ1) — pass-through of the native `--permission-mode` keeps the helper thin and avoids a mapping table that drifts as Claude's mode set evolves; read-only review is composed by the caller via `--allowedTools`.

### Default to `--bare` for a cheap isolated probe

Rejected (was OQ3) — the primary consumer is spec review, which needs project context (`CLAUDE.md`, rules); `--bare` also forces strictly `ANTHROPIC_API_KEY`, breaking OAuth/subscription auth. `--bare` stays opt-in.

## Risks and unknowns

- **`stream-json` event shape.** The exact JSON envelope of the final `result` event (key names, nesting) must be verified against the live `claude` version during implementation; the `jq` filter depends on it. Mitigate: capture a real `events.jsonl` from a smoke run and pin the filter to observed keys.
- **`--add-dir` vs repo-root containment.** Need to confirm `--add-dir` accepts a dir and that we validate it resolves under repo root (mirror codex `--cwd` guard) to avoid granting Claude access outside the project.
- **Recursion when parent is Claude.** Out of scope (non-goal), but if someone runs claude-exec from a Claude session with full context, hooks fire inside the child. `--bare` is the escape hatch; document it.
- **Auth assumptions in headless.** The child uses the machine's existing Claude auth; in a CI/cron Codex context that may be absent. Surface a clean error, not a hang.
- **`jq` availability.** New hard dependency vs codex-exec. Checked up front with an actionable error.

## Research / citations

- `claude --help` (verified 2026-05-30) — confirmed `-p`, `--output-format text|json|stream-json`, `--permission-mode` value set, `--model`, `--resume`/`--session-id`/`--continue`, `--add-dir`, `--allowedTools`/`--disallowedTools`, `--mcp-config`, `--bare`, `--verbose`.
- `.agent0/skills/codex-exec/scripts/codex-exec.sh` — bridge-contract reference (run-dir, slug, metadata, `runs.jsonl`, `--output` `realpath -m` guard at lines ~256–266).
- `.agent0/skills/codex-exec/agents/openai.yaml` — policy-block shape.
- `docs/specs/128-codex-exec-skill/` + this session's dogfood — the `--output` guard and fail-closed posture this spec inherits.
- `.agent0/context/rules/runtime-capabilities.md` — provider-neutral capability matrix.
