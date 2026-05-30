# 128 — codex-exec-skill — plan

_Drafted from `spec.md` on 2026-05-30. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Implement `codex-exec` as an `agentskills-portable` skill with one deterministic bash helper. The canonical skill source lives in `.agent0/skills/codex-exec/`; Claude and Codex discover it through the standard `.claude/skills/codex-exec` and `.agents/skills/codex-exec` relative symlinks. The skill body stays lean: parse the user's intent, call `scripts/codex-exec.sh`, and relay the helper's output paths/status.

The helper owns every fragile detail: checking that `codex` and `.agent0/tools/codex-local-env.sh` exist, normalizing supported parameters into argv arrays, defaulting to `--sandbox read-only`, writing the prompt to a run directory, invoking `codex exec` or `codex exec resume`, and recording both a per-run `metadata.json` plus an aggregate `runs.jsonl`. It accepts natural shell flags rather than a JSON envelope in v1; prompt text comes from `--task`, `--task-file`, stdin, or arguments after `--`. `--cwd` is allowed only inside the repo root so the bridge cannot silently run Codex against unrelated filesystem state.

## Files to touch

**Create:**
- `.agent0/skills/codex-exec/SKILL.md` — portable skill body and invocation contract.
- `.agent0/skills/codex-exec/scripts/codex-exec.sh` — deterministic wrapper around `.agent0/tools/codex-local-env.sh`.
- `.agent0/skills/codex-exec/agents/openai.yaml` — Codex skill metadata with `allow_implicit_invocation: true`.
- `.claude/skills/codex-exec` — Claude discovery symlink to the canonical skill.
- `.agents/skills/codex-exec` — Codex discovery symlink to the canonical skill.
- `.agent0/tests/codex-exec-skill/01-default-read-only.sh` — verifies default sandbox, stdin prompt, output capture, and metadata with a fake `codex`.
- `.agent0/tests/codex-exec-skill/02-parameter-mapping.sh` — verifies model/profile/cwd/json/output argument placement without `eval`.
- `.agent0/tests/codex-exec-skill/03-resume.sh` — verifies `exec resume <session_id> -` and metadata recording.
- `.agent0/tests/codex-exec-skill/04-missing-codex.sh` — verifies dependency failure before creating success-looking output.
- `.agent0/tests/codex-exec-skill/run-all.sh` — test runner for the new scenarios.

**Modify:**
- `docs/specs/128-codex-exec-skill/tasks.md` — replace placeholders with the implementation checklist.
- `docs/specs/128-codex-exec-skill/notes.md` — record any implementation-time decisions/deviations.
- `docs/specs/128-codex-exec-skill/spec.md` — mark acceptance criteria and status after verification.

**Delete:**
- None.

## Alternatives considered

### JSON envelope as the primary interface

Rejected for v1 because the call site is a human/Claude skill invocation, not a machine API. A strict envelope would make simple probes harder and would require a parser dependency or fragile shell JSON handling before there is evidence the extra structure is needed. The helper still writes structured metadata so a future envelope can be added without changing the audit shape.

### Direct `codex` invocation instead of `.agent0/tools/codex-local-env.sh`

Rejected because Agent0 already centralizes repo root and `.codex/.env.local` loading in the launcher. Repeating that logic in the skill would fork the operational contract and recreate the flag-ordering pitfalls already documented in memory.

### Allow arbitrary `--cwd`

Rejected for v1. The bridge is intended to run Codex inside the current Agent0/consumer repo. Allowing arbitrary absolute paths would make a vague or implicitly-triggered invocation inspect unrelated local state. The helper accepts explicit `--cwd`, but only after resolving it under the repo root.

### Make `allow_implicit_invocation` false

Rejected by user decision. The risk is mitigated by a precise skill description and conservative wrapper defaults rather than disabling implicit invocation.

## Risks and unknowns

- Codex CLI flags can drift. Verification should use the current local `codex exec --help` / `codex exec resume --help`, and tests should assert the generated argv shape against a fake `codex`.
- `codex exec` is not a faithful proof surface for interactive Codex TUI hook behavior. The skill must document this and keep dogfood focused on non-interactive probes/reviews.
- `--json` output can be noisy. The helper captures JSONL to a file and reports the path; the parent agent should summarize the final message, not stream every event inline.
- Multiple `-C/--cd` flags rely on Codex honoring the last supplied working root after the launcher prepends the repo root. If this becomes unreliable, the launcher should grow first-class cwd override support in a later spec.

## Research / citations

- `docs/specs/128-codex-exec-skill/spec.md` — accepted behavior and non-goals.
- `docs/specs/121-multi-runtime-skills/spec.md` — canonical `.agent0/skills/<slug>` source plus runtime discovery symlinks; `allow_implicit_invocation` default behavior.
- `.agent0/context/rules/runtime-capabilities.md` — current runtime capability matrix for skills.
- `.agent0/skills/skill/SKILL.md` and `.agent0/skills/skill/templates/portable.tmpl` — scaffolding and validation conventions.
- `.agent0/tools/codex-local-env.sh` — existing launcher this wrapper must call.
- Local `codex-cli 0.135.0` help for `codex exec` and `codex exec resume` — confirms stdin `-`, `--json`, `--output-last-message`, `--model`, `--profile`, `--sandbox`, and resume prompt placement.
