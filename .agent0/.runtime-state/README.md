# `.agent0/.*-state/` + `.claude/.*-state/` — runtime state subsystems

Catalogue of the per-machine, per-project ephemeral-state directories the Agent0 harness writes. Each is owned by exactly one capacity and is gitignored — only this README is git-tracked (via an explicit `.gitignore` exception), so a fresh clone has an entry point into "what's that hidden state and who owns it" without grepping rules. Since umbrella spec 102, the **runtime-neutral** state lives under `.agent0/` (read/written by any runtime); the **Claude-exclusive** state stays under `.claude/` (delegation, rule-load-debug, compact-history — surfaces with no cross-runtime analogue).

Lives at `.agent0/.runtime-state/README.md` rather than a top-level `STATE-LAYOUT.md` because the discovery angle is "I see `.agent0/.*-state/` / `.claude/.*-state/` dirs — what's here?". Pattern borrowed from Anthill's `.anthill/runtime/README.md` (shape only — Agent0's surface is smaller and the storage-substrate framing is Anthill-specific).

## Current subsystems

| Path | Owner rule | Purpose |
| --- | --- | --- |
| `.agent0/.runtime-state/` | [`runtime-introspect`](../rules/runtime-introspect.md) | Verifier last-run snapshot (`last-run.json`) + per-`tool_use_id` in-flight start marks under `in-flight/`. Captured by `runtime-pre-mark.sh` / `runtime-capture.sh`; read back by `bash .claude/tools/probe.sh last-run`. |
| `.agent0/.browser-state/` | [`browser-auth`](../rules/browser-auth.md) | Playwright MCP session state (`<host>.json` cookie/localStorage snapshots) reused for headless reads after an interactive login. Empty `.gitkeep` sentinel travels via git so the dir exists in fresh forks; actual `*.json` files are project-local. |
| `.claude/.delegation-state/` | [`delegation`](../rules/delegation.md) § Post-edit validator loop | Per-`agent_id` consecutive-failure counters for the post-edit validator loop budget (default cap 5). Reset on a passing validation; consulted at SubagentStop to mark `exit: loop-budget-exceeded` in the audit log. |
| `.agent0/.routines-state/` | [`routines`](../rules/routines.md) | Per-`<slug>` recurring-routine state — `queue/<unix-ts>.md` (pending renders awaiting dispatch), `completed/<unix-ts>.md` (FIFO cap 50), `last-completed.json`, `last-queue.json`, plus shared `cron.log`. Populated by `.claude/tools/run-routine.sh` at cron-fire time. |
| `.claude/.rule-load-debug.jsonl` | [`rule-load-debug`](../memory/rule-load-debug.md) | Opt-in (`CLAUDE_RULE_LOAD_DEBUG=1`) instrumentation log for the `InstructionsLoaded` hook event — one JSONL row per loaded CLAUDE.md / rule file. Read back via `bash .claude/tools/probe.sh rule-loads`. |
| `.claude/.compact-history/` | [`compaction-continuity`](../memory/compaction-continuity.md) | Per-compaction snapshot files (`<ISO>-<pid>-<rand>.md`), one per `/compact` event. Written by `pre-compact.sh`; the lex-greatest snapshot is injected by `session-start.sh` on `source=compact`. Retention cap is `compactHistory.keepLast` in `.claude/settings.json` (default 20). Replaced the single-file `.claude/COMPACT_NOTES.md` model under spec 081. |

## Discipline

Future state subsystems update this README in the same commit that ships them. The README enumerates only what is present at write-time — speculative or planned subsystems (a `.claude/.skill-state/`, `.claude/.memory-events/` from a future event-sourcing spec, etc.) are NOT listed here until they actually exist. Owner pointers go to the canonical doc for the capacity — `.claude/rules/<topic>.md` when the consumer-side agent acts on it, or `.claude/memory/<topic>.md` when only the upstream maintainer does — not to the hook or tool that writes the state. The doc is the durable contract; hook paths can move.

If a subsystem is removed, drop its row in the same commit that removes the writer. A row referring to a path that no longer has a writer is the failure mode this discipline avoids.
