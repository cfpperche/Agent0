# 128 — codex-exec-skill — notes

_Created 2026-05-30._

## Design decisions

### 2026-05-30 — parent — Shell flags over JSON envelope

The implementation kept v1 as a shell-flag interface (`--task`, `--task-file`, stdin, `--model`, `--profile`, `--sandbox`, `--cwd`, `--resume`, `--json`, `--output`, `--slug`) instead of adding a strict JSON envelope parser. This keeps Claude-side use direct while still producing structured `metadata.json` and `runs.jsonl` for audit/evals.

### 2026-05-30 — parent — Repo-contained cwd

`--cwd` resolves to a real directory and must stay under the repo root. That is the right default for an implicitly invocable bridge: a vague trigger cannot silently point Codex at unrelated local filesystem state.

## Deviations

### 2026-05-30 — parent — Aggregate metadata plus per-run metadata

The plan leaned toward per-run `metadata.json` only unless needed. Implementation added both per-run `metadata.json` and aggregate `.agent0/.runtime-state/codex-exec/runs.jsonl` because the spec acceptance required an appended metadata line and the aggregate log is the simplest audit surface.

### 2026-05-30 — parent — Dogfood output containment fix

Claude dogfood passed the default flow but found a genuine escape hatch: explicit `--output /absolute/path` let the helper place `last-message.md`, `prompt.md`, `metadata.json`, `stderr.txt`, and `command.txt` outside gitignored runtime state. The fix constrains `--output` to `CODEX_EXEC_STATE_DIR` / `.agent0/.runtime-state/codex-exec`, with relative paths resolving under that state root and absolute paths outside it rejected before artifact creation.

## Tradeoffs

### 2026-05-30 — parent — Fake Codex tests plus one live smoke

Most verification uses fake `codex` binaries so argument ordering, output capture, failure handling, and resume shape are deterministic and do not spend model calls. A single live smoke then proves the real local Codex CLI path works without turning the test suite into a network-bound gate.

## Open questions

None remaining for v1.

## Claude dogfood prompt

Copy/paste this into Claude Code from the Agent0 repo root:

```text
Dogfood spec 128's `/codex-exec` bridge.

Constraints:
- Read-only dogfood only. Do not edit files.
- Do not run broad test suites.
- Use the `/codex-exec` skill if Claude discovers it; if slash invocation is unavailable, run the helper directly.

Task:
1. Invoke the bridge with:
   /codex-exec --json --slug claude-dogfood-readonly --task "Review docs/specs/128-codex-exec-skill/spec.md and .agent0/skills/codex-exec/SKILL.md for one concrete remaining risk. If none, reply NO_RISKS."
2. Inspect the helper summary, the generated `metadata.json`, `last-message.md`, and `events.jsonl`.
3. Report exactly:
   - PASS or FAIL
   - command shape used (`/codex-exec` or direct helper)
   - exit_code
   - sandbox value from metadata
   - last_message path
   - whether Codex returned a substantive answer
   - any concrete issue found in the bridge contract
```
