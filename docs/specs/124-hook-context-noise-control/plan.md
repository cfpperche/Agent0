# 124 — hook-context-noise-control — plan

_Drafted from `spec.md` on 2026-05-30. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Add one shared `SessionStart` aggregator, `.agent0/hooks/startup-brief.sh`, and make it the only model-visible
startup hook registered in `.claude/settings.json` and `.codex/hooks.json`. The older startup readout scripts
stay callable as private helpers and fixture targets, but normal runtime startup receives one bounded
`AGENT0_STARTUP_BRIEF` block. The aggregator owns session-state side effects, compact handoff summary,
due/top-N reminders, actionable routines, non-empty memory decay warnings, githooks activation advisory, and
final byte/line trimming.

Refactor `.agent0/hooks/context-inject.sh` so normal `UserPromptSubmit` emits lightweight capsules and source
pointers, not full rule bodies. Full context inventory moves behind explicit diagnostic mode
(`AGENT0_CONTEXT_DIAGNOSTIC=1` or equivalent), and selector input is sanitized before matching so pasted hook
output, generated `AGENT0_CONTEXT_INJECTION` blocks, framed readouts, and `<skill>...</skill>` payloads do not
inflate selected fragments. Keep caps conservative and operator-tunable with `AGENT0_*` env vars.

## Files to touch

**Create:**
- `.agent0/hooks/startup-brief.sh` — shared SessionStart aggregator and bounded startup context emitter.
- `.agent0/tests/context-injection/09-startup-brief-budget.sh` — regression for aggregate startup byte/line caps.
- `.agent0/tests/context-injection/10-pasted-hook-output-ignored.sh` — regression for generated/quoted prompt sanitization.
- `.agent0/tests/context-injection/11-diagnostic-index-mode.sh` — regression for explicit full-index diagnostic mode.

**Modify:**
- `.agent0/hooks/context-inject.sh` — switch prompt output to capsules/pointers, add prompt sanitization, caps, and diagnostic index mode.
- `.codex/hooks.json` — replace five `SessionStart` hook registrations with the single startup aggregator.
- `.claude/settings.json` — replace five `SessionStart` hook registrations with the single startup aggregator.
- `.agent0/tests/context-injection/*.sh` — update expectations for startup pointer/diagnostic mode and lightweight prompt capsules.
- `.agent0/tests/multi-runtime-readouts/05-hooks-json-parse.sh` — expect `startup-brief.sh` as the tracked Codex startup readout surface.
- `.agent0/tests/session-handoff-multi-runtime/05-hooks-json-parse.sh` — expect startup handoff to be carried by the aggregator registration.
- `.agent0/tests/harness-sync/35-codex-config-example-untouched.sh` — update the copied hooks fixture assertion from `session-start.sh` to `startup-brief.sh`.
- `.agent0/context/rules/runtime-capabilities.md` — describe startup brief + prompt capsules instead of startup index + full fragments.
- `.agent0/context/rules/session-handoff.md` — document that `startup-brief.sh` is the registered SessionStart surface and `session-start.sh` is helper/legacy behavior.
- `.agent0/context/rules/reminders.md` and `.agent0/context/rules/routines.md` — document aggregation/top-N behavior for startup instead of separate model-visible startup blocks.
- `.agent0/context/rules/harness-sync.md` — update the hook registration description.
- `.agent0/skills/vuln-audit/SKILL.md` — correct `metadata.agent0-portability-tier` to `agentskills-portable`.
- `docs/specs/124-hook-context-noise-control/{spec.md,tasks.md,notes.md}` — status, task checkoff, and implementation notes as work progresses.

**Delete:**
- None. The existing readout scripts remain available as helpers and direct-test targets.

## Alternatives considered

### Use `suppressOutput` and keep the existing five hooks

Rejected because the load-bearing requirement is model-visible context, not transcript aesthetics. Codex docs
also make clear that multiple matching hooks run and matching hooks from multiple sources are loaded together,
so relying on hidden-but-still-large output would preserve the context bloat and the parallel-hook surface.

### Remove the old readout scripts entirely

Rejected because `session-start.sh`, `reminders-readout.sh`, `routines-readout.sh`, and
`memory-decay-readout.sh` already encode useful behavior and have direct fixture coverage. Keeping them as
helpers preserves compatibility while solving the actual runtime problem: too many model-visible startup
registrations.

### Auto-expand full rule bodies when the selector is confident

Rejected because the observed failure mode is over-selection and over-emission during broad diagnostic prompts.
Capsules plus explicit file reads keep context costs visible and make false positives cheap.

## Risks and unknowns

- **Session-state regression risk:** replacing the registered `session-start.sh` path means the aggregator must
  preserve the start-marker, edited-files seed, porcelain snapshot, and cleanup side effects that `session-stop.sh`
  depends on.
- **Doc/test drift risk:** several tests currently assert direct `SessionStart` registration of `session-start.sh`
  or `context-inject.sh`; updating only the hook files without the tests would leave stale contracts.
- **Too-aggressive summarization risk:** top-N reminders and compact handoff can omit useful context. The brief
  must include enough pointers that the agent knows where to read full detail.
- **Runtime envelope risk:** Claude and Codex need different output envelopes. Synthetic tests must cover both.

## Research / citations

- OpenAI Codex hooks documentation — `hooks.json` and inline hooks are loaded together; multiple matching hooks
  run; project hooks require trust: <https://developers.openai.com/codex/hooks>
- Claude Code hooks documentation — `SessionStart` / `UserPromptSubmit` stdout or
  `hookSpecificOutput.additionalContext` adds model context, and `systemMessage` is separately user-visible:
  <https://docs.claude.com/en/docs/claude-code/hooks>
- Local spec 122 and 123 artifacts — current Agent0 context hydrator and tracked Codex hooks architecture.
