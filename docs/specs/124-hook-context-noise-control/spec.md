# 124 — hook-context-noise-control

_Created 2026-05-30._

**Status:** shipped

## Intent

Reduce Agent0 hook-injected context noise without weakening the cross-runtime harness contract.

Specs 122 and 123 moved Agent0 behavioral context to `.agent0/context/rules/` and made Codex consume
tracked `.codex/hooks.json` registrations. The contract works, but the real Codex TUI experience shows a
bad UX failure: normal startup and diagnostic prompts can surface multiple large `hook context` blocks,
including handoff, reminders, memory decay, context indexes, and prompt-selected rule bodies. The same
logical hook architecture is less visually disruptive in Claude Code, but Agent0 should not rely on that
runtime-specific presentation difference.

This spec keeps one source of truth and native hooks for both runtimes, but changes the emitted context
shape: startup becomes one bounded summary-first brief, prompt-time context becomes lightweight capsules or
source pointers by default, and generated/quoted diagnostic text stops confusing the selector into loading
nearly every fragment.

## Acceptance criteria

- [x] **Scenario: startup uses one bounded Agent0 brief**
  - **Given** a fresh Agent0 checkout with `.claude/settings.json` and `.codex/hooks.json`
  - **When** `SessionStart` hooks are inspected for both runtimes
  - **Then** the five separate startup context registrations (`context-inject.sh`, `session-start.sh`,
    `reminders-readout.sh`, `routines-readout.sh`, `memory-decay-readout.sh`) are replaced by one shared
    Agent0 startup brief registration per runtime.
  - **And** any existing per-capacity scripts that still provide useful data are called by the aggregator
    internally, not registered as separate model-visible `SessionStart` hooks.

- [x] **Scenario: startup output is summary-first and bounded**
  - **Given** a fixture repo with a non-empty handoff, many pending reminders, a routine state directory,
    and memory decay output available
  - **When** the shared startup brief hook receives a normal `SessionStart` payload
  - **Then** it emits one framed brief no larger than 6,000 bytes and no longer than 80 lines.
  - **And** the brief contains compact handoff state, due-only/top-N reminders, routines only when actionable,
    and memory decay only when non-empty.
  - **And** normal startup does not emit the full `AGENT0_CONTEXT_INJECTION` fragment index.

- [x] **Scenario: explicit diagnostics can still inspect context inventory**
  - **Given** a maintainer needs to debug Agent0 context selection
  - **When** they invoke the context hydrator directly or set the documented diagnostic mode for startup
  - **Then** the context fragment index can still be produced on demand with provenance labels.
  - **And** the normal Claude/Codex startup path remains summary-first.

- [x] **Scenario: prompt-time context is lightweight by default**
  - **Given** a user prompt that mentions SDD, hooks, runtime context, or other Agent0 capacities
  - **When** `UserPromptSubmit` runs the context hydrator
  - **Then** the emitted block uses short capsules or source pointers by default instead of injecting full
    `.agent0/context/rules/user-prompt-framing.md` and `.agent0/context/rules/spec-driven.md` bodies every
    turn.
  - **And** the block tells the agent which selected files to read before acting when the task depends on
    the omitted detail.

- [x] **Scenario: generated hook output does not poison selection**
  - **Given** a prompt that pastes prior `hook context:` output, an `AGENT0_CONTEXT_INJECTION` block,
    `=== HANDOFF.md ===` / `=== REMINDERS ===` frames, or a `<skill>...</skill>` block
  - **When** `UserPromptSubmit` selects Agent0 context
  - **Then** those generated or quoted regions are ignored for fragment selection.
  - **And** the selected fragment count is capped to the highest-confidence matches instead of selecting
    most of `.agent0/context/rules/`.

- [x] **Scenario: selector caps are configurable but conservative by default**
  - **Given** no special environment variables are set
  - **When** a broad prompt mentions many Agent0 capacity names
  - **Then** the hydrator emits at most five selected fragment capsules and stays under 6,000 bytes.
  - **And** an operator can raise or lower the byte/fragment caps through documented `AGENT0_*` environment
    variables for local dogfood without changing tracked hooks.

- [x] **Scenario: regression tests pin the noise budgets**
  - **Given** `.agent0/tests/context-injection/` and multi-runtime readout fixtures
  - **When** the focused test suite runs
  - **Then** it proves all of the following:
    - aggregate startup output stays under the fixed byte/line budget;
    - a pasted-hook diagnostic prompt does not select every rule fragment;
    - a large reminders fixture is summarized instead of emitted raw;
    - normal startup does not emit the full fragment index;
    - direct diagnostic mode can still emit the fragment index.

- [x] **Scenario: Claude and Codex retain the same Agent0 contract**
  - **Given** the shared aggregator and prompt hydrator
  - **When** equivalent Claude-shaped and Codex-shaped hook payloads are run through synthetic fixtures
  - **Then** both runtimes receive the same Agent0 facts and instructions within the bounded output shape,
    while preserving each runtime's required output envelope (`hookSpecificOutput.additionalContext` for
    Claude where needed, plain stdout / Codex-supported shape for Codex where appropriate).

- [x] `.agent0/skills/vuln-audit/SKILL.md` declares `metadata.agent0-portability-tier:
  agentskills-portable`, and the `.claude/skills/vuln-audit` plus `.agents/skills/vuln-audit` symlink views
  show the same corrected metadata.

- [x] The vuln-audit metadata correction is documented as an adjacent cleanup from this investigation and
  does not change `.agent0/tools/vuln-audit.sh` behavior.

## Non-goals

- Hiding noisy hook output by relying on `suppressOutput`. Current runtime behavior still makes model-visible
  context the load-bearing channel; this spec reduces what Agent0 emits.
- Removing startup context entirely. The agent should still receive handoff, actionable reminders/routines,
  memory decay warnings, and context-selection guidance when relevant.
- Reintroducing `.claude/rules/*.md` as a Claude-native harness surface.
- Changing Codex hook trust semantics or requiring local `.codex/config.toml` hook blocks.
- Rewriting the reminder, routine, memory, or handoff data models. This spec changes their readout shape.
- Applying dependency vulnerability fixes. Only the `vuln-audit` skill metadata mismatch is in scope.

## Open questions

- [x] Should the startup aggregator replace the older readout scripts entirely, or keep them as private
  helpers for compatibility and tests?
  - **Decision:** keep the older readout scripts callable as private helpers, but register only the
    aggregator as model-visible `SessionStart` context.
- [x] Should prompt-time capsules ever auto-expand full rule bodies, or should expansion always require the
  agent to read the named file explicitly?
  - **Decision:** do not auto-expand full rule bodies in normal mode. Prompt-time context emits capsules or
    pointers; the agent reads the named file explicitly when the task depends on the detail.

## Context / references

- `docs/specs/122-context-injection-rules-cutover/` — introduced `.agent0/context/rules/` and
  `.agent0/hooks/context-inject.sh`.
- `docs/specs/123-codex-hooks-json/` — moved Codex hook registration to tracked `.codex/hooks.json`.
- `.codex/hooks.json` — previously carried five model-visible `SessionStart` commands; now carries the
  shared `startup-brief.sh` registration.
- `.claude/settings.json` — previously mirrored the same separate readout registrations; now carries the
  shared `startup-brief.sh` registration.
- `.agent0/hooks/context-inject.sh` — previously emitted a startup index and full prompt-selected fragments;
  now emits prompt capsules by default and keeps full inventory behind diagnostic mode.
- `.agent0/hooks/session-start.sh`, `.agent0/hooks/reminders-readout.sh`,
  `.agent0/hooks/routines-readout.sh`, `.agent0/hooks/memory-decay-readout.sh` — legacy/helper startup
  readout sources that the aggregator calls or preserves for direct debugging.
- `.agent0/skills/vuln-audit/SKILL.md` — metadata previously contradicted the spec 121 portable-skill state;
  this spec corrects it to `agentskills-portable`.
- OpenAI Codex hooks documentation: <https://developers.openai.com/codex/hooks>
- Claude Code hooks documentation: <https://docs.claude.com/en/docs/claude-code/hooks>

## Validation evidence

- `bash .agent0/tests/context-injection/run-all.sh` — PASS.
- `bash .agent0/tests/multi-runtime-readouts/05-hooks-json-parse.sh` — PASS.
- `bash .agent0/tests/session-handoff-multi-runtime/run-all.sh` — PASS.
- `bash .agent0/tests/harness-sync/35-codex-config-example-untouched.sh` — PASS.
- `bash .agent0/tests/runtime-capabilities/run-all.sh` — PASS.
- `jq empty .codex/hooks.json .claude/settings.json` — PASS.
- Synthetic startup probe: `startup-brief.sh` emitted one `AGENT0_STARTUP_BRIEF` block at 2,096 bytes / 28
  lines in this checkout.
- Synthetic pasted-hook prompt probe: `context-inject.sh` emitted 1,046 bytes / 21 lines and selected only
  `runtime-capabilities harness-sync memory-placement`, ignoring pasted `vuln-audit`/hook output.
- Symlink metadata probe: `.agent0/skills/vuln-audit/SKILL.md`, `.claude/skills/vuln-audit/SKILL.md`, and
  `.agents/skills/vuln-audit/SKILL.md` all report `agent0-portability-tier: agentskills-portable`.
