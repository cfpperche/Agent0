# 122 — context-injection-rules-cutover — notes

## Design decisions

### 2026-05-30 — parent — hard cutover away from `.claude/rules`

The founder chose a single Agent0 context injection layer over keeping Claude Code's native rules as
a parallel channel. This means no `.claude/rules` symlink model: even symlinks would still activate
Claude's native loader and preserve the asymmetry. The neutral source is `.agent0/context/rules/`;
runtime-specific files only register the shared hydrator.

## Deviations

### 2026-05-30 — parent — startup hydrates an index, prompts hydrate fragments

The v1 hydrator does not try to emulate Claude's file-read-triggered path rules. `SessionStart` emits
an index of available fragments, while `UserPromptSubmit` emits core fragments plus keyword/path
matches. This preserves the single-channel decision without blindly loading the whole former rules
corpus into every session.

## Tradeoffs

### 2026-05-30 — parent — live runtime proof required

Local hook fixtures prove the output shapes and registrations, but they are not enough to close the
runtime claim. A real fresh runtime session must prove model-visible pickup before the live-proof row
is marked complete.

### 2026-05-30 — claude-code — live hydrator pickup confirmed

A fresh Claude Code session confirmed `.claude/rules/` is absent, `.agent0/context/rules/` contains
21 fragments, and `.claude/settings.json` registers `.agent0/hooks/context-inject.sh` for both
`SessionStart` and `UserPromptSubmit`. The context-injection suite passed 8/8. The decisive live
signal was positive hydrator output: `SessionStart` emitted an `AGENT0_CONTEXT_INJECTION` index from
`.agent0/context/rules`, and `UserPromptSubmit` emitted prompt-selected fragments from the same
source. `/memory` was not the discriminating check because Claude Code does not treat `.claude/rules`
as a native memory/import surface; the hook injection block is the meaningful runtime proof.

### 2026-05-30 — codex-cli — initial fixture proof only

Codex confirmed the opt-in template contains both context-inject registrations (`SessionStart` and
`UserPromptSubmit`), direct local invocation of `.agent0/hooks/context-inject.sh` with a
`UserPromptSubmit` payload emits `AGENT0_CONTEXT_INJECTION`, and the context-injection suite passes.
At this point the active local `.codex/config.toml` had `[features] hooks = true` but did not include
the `context-inject.sh` blocks, so that Codex prompt did not receive live hydrator context. This was
closed by the later fresh TUI proof below.

### 2026-05-30 — codex-cli — live TUI hydrator pickup confirmed

The local `.codex/config.toml` was updated with the context-inject `SessionStart` and
`UserPromptSubmit` blocks, then a fresh Codex TUI session was started with
`--dangerously-bypass-hook-trust`. A temporary sentinel proved the event path first: the TUI showed
both hook contexts and the model responded `PROMPT_SENTINEL_SEEN`. After removing the sentinel hooks,
the real dogfood prompt saw `AGENT0_CONTEXT_INJECTION` from the hydrator:

- `SessionStart`: `event: SessionStart`, `mode: index`, `source_dir: .agent0/context/rules`.
- `UserPromptSubmit`: `event: UserPromptSubmit`, `mode: prompt-selected`, `source_dir:
  .agent0/context/rules`, `selected: language user-prompt-framing spec-driven session-handoff
  runtime-capabilities harness-sync memory-placement`.

The dogfood reply was: `PASS; injected block present yes; event value(s): SessionStart,
UserPromptSubmit; mode value(s): index, prompt-selected; source_dir value(s):
.agent0/context/rules; selected: language user-prompt-framing spec-driven session-handoff
runtime-capabilities harness-sync memory-placement; gotcha: some selected fragments were omitted by
byte cap.`

A follow-up fresh Codex TUI launch without `--dangerously-bypass-hook-trust` prompted `Hooks need
review`; choosing `Trust all and continue` trusted the local hook hashes, ran the hydrator, and the
model replied `TRUSTED_CONTEXT_SEEN`.

Gotcha: `codex exec` was not a valid live proof for this path in this run. Even with the same local
config and `--dangerously-bypass-hook-trust`, `codex exec` did not expose `SessionStart` or
`UserPromptSubmit` hook context to the model; the live proof is the interactive Codex TUI session.

### 2026-05-30 — follow-up — Codex registration moved to tracked hooks.json

Spec 123 supersedes this spec's initial Codex opt-in registration shape. The context hydrator remains
the same, but Codex now receives Agent0-owned hook registrations from tracked `.codex/hooks.json`
instead of commented `[[hooks.*]]` blocks in `.codex/config.toml.example`. The local dogfood
`.codex/config.toml` was cleaned to avoid duplicate hook execution.

## Open questions

_See `spec.md`._
