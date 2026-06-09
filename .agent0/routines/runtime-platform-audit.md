---
name: runtime-platform-audit
schedule: "0 9 * * 1"
idempotent: true
on-stale: warn
stale-after-days: 14
---

# Prompt

You are running the weekly **multi-runtime platform audit** — a provider-neutral drift check (spec 183, generalized from the former `cc-platform-audit`). You sweep every audit unit in the list below in ONE run, then the runtime-capabilities matrix.

**Last execution:** {{LAST_COMPLETED_TS}}. **Current HEAD:** {{GIT_HEAD}}. **Repo:** {{REPO_ROOT}}.

## Audit units (the allowlist — a row with no upstream doc URL is skipped, never guessed)

| runtime | upstream doc | snapshot target | audit kind |
| --- | --- | --- | --- |
| Claude Code | <https://code.claude.com/docs/en/hooks> | `.agent0/memory/cc-platform-hooks.md` | hook events / payload shapes / exit-code & when-fires semantics |
| Claude Code | <https://code.claude.com/docs/en/skills> + <https://code.claude.com/docs/en/commands> | (informational only — see § agentskills.io) | CC-specific skill frontmatter extensions |
| Codex CLI | <https://developers.openai.com/codex/hooks> | `.agent0/memory/codex-cli-hooks.md` | hook events / payload shapes / tool-name surface |
| _(open standard)_ | <https://agentskills.io/specification> | `.claude/skills/skill/references/spec-snapshot.md` | frontmatter field set + name/description constraints |

## Steps

For **each** audit unit with a snapshot target:

1. WebFetch the upstream doc and capture current content.
2. Compare against the snapshot target. Classify each drift:
   - **New item** (event/field) not in snapshot → propose edit adding it
   - **Shape/constraint changed** for a documented item → propose edit correcting
   - **Item removed / deprecated** → propose edit removing or marking deprecated
   - **Behavior changed** (exit-code semantics, when-fires, tool-name surface, etc.) → propose edit correcting
3. If drift exists, apply the edits to the snapshot target. **DO NOT commit — leave the diff for human review via `git diff`.**

Then audit the **runtime-capabilities matrix** (the high-value cell-value check `check-instruction-drift.sh` deliberately omits):

4. Read `.agent0/context/rules/runtime-capabilities.md`. For each runtime that appears as an audit unit above (Claude Code, Codex CLI — NOT future-runtime placeholder rows), check each definitive per-cell claim (`supported` / `unsupported` / tier) for that runtime against its upstream doc. If a cell contradicts upstream (the spec-099 stale-cell failure mode), propose a matrix edit and apply it (still uncommitted). When you also change a cell, follow the Update rule in `.agent0/memory/runtime-capabilities-maintenance.md`.

Discipline notes:

- **`spec-snapshot.md` mirrors agentskills.io, NOT Claude Code.** Audit it against `agentskills.io/specification` only. CC-specific skill frontmatter extensions (`argument-hint`, `disable-model-invocation`, `user-invocable`, `disallowed-tools`, `model`, `context: fork`, `arguments`) are CC's own layer — report them as **informational** in chat; never write them into `spec-snapshot.md`.
- If any upstream doc is unreachable, report the unit as `unreachable: <unit>` and continue with the rest (one failed fetch must not abort the sweep).
- Name any audit unit you skipped (e.g. a future-runtime row with no doc URL).

# Done when

- For every audit unit: either an edit applied to its snapshot target / the matrix reflecting current drift, OR it is accounted for as `no-drift` / `unreachable`, AND
- A consolidated report in chat: per-unit `drift-applied <target>` | `no-drift-detected since {{LAST_COMPLETED_TS}}` | `unreachable <unit>`, plus any informational CC-extension notes,
- All edits left UNCOMMITTED (human reviews `git diff`),
- (Automatic) `.agent0/.routines-state/runtime-platform-audit/completed/<ts>.md` materialized by `/routine run` on archival.

<!--
Spec 183 (2026-06-09): generalized from cc-platform-audit (Agent0's first
routine, 2026-05-19). Provider-neutral by design — one weekly run audits all
runtime snapshots + the runtime-capabilities matrix cells, rather than one
routine per runtime. Weekly (Mon 9am UTC) balances drift-caught-early against
cost (~3-4 web fetches + 1 LLM session per week). Idempotent: re-running in the
same week re-checks drift; if an edit was already applied, the re-run sees the
updated snapshot and reports no-drift-detected.
Demand is documented, not speculative: codex-cli-hooks.md records two stale
runtime-capabilities cells (spec 099 hooks; subagents) that bit Agent0 before
any routine covered the Codex/matrix surface.
-->
