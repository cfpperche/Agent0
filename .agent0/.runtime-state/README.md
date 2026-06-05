# `.agent0/.*-state/` + `.claude/.*-state/` — runtime state subsystems

Catalogue of the per-machine, per-project ephemeral-state directories the Agent0 harness writes. Each is owned by exactly one capacity and is gitignored — only this README is git-tracked (via an explicit `.gitignore` exception), so a fresh clone has an entry point into "what's that hidden state and who owns it" without grepping rules. Since umbrella spec 102, the **runtime-neutral** state lives under `.agent0/` (read/written by any runtime); the **Claude-exclusive** state stays under `.claude/` (delegation — surfaces with no cross-runtime analogue).

Lives at `.agent0/.runtime-state/README.md` rather than a top-level `STATE-LAYOUT.md` because the discovery angle is "I see `.agent0/.*-state/` / `.claude/.*-state/` dirs — what's here?". Pattern borrowed from Anthill's `.anthill/runtime/README.md` (shape only — Agent0's surface is smaller and the storage-substrate framing is Anthill-specific).

## Current subsystems

| Path | Owner rule | Purpose |
| --- | --- | --- |
| `.agent0/.runtime-state/agent-browser/state/` | [`browser-auth`](../rules/browser-auth.md) | agent-browser session state (`<host>.json` cookie/localStorage snapshots) saved by `adopt` and reused for headless reads after the human-in-the-loop `browser-login.sh` login. Credential-class, gitignored. |
| `.agent0/.delegation-state/` | [`delegation`](../rules/delegation.md) § Post-edit validator loop | Per-`agent_id` consecutive-failure counters for the post-edit validator loop budget (default cap 5). Reset on a passing validation; consulted at SubagentStop to mark `exit: loop-budget-exceeded` in the audit log. |
| `.agent0/.routines-state/` | [`routines`](../rules/routines.md) | Per-`<slug>` recurring-routine state — `queue/<unix-ts>.md` (pending renders awaiting dispatch), `completed/<unix-ts>.md` (FIFO cap 50), `last-completed.json`, `last-queue.json`, plus shared `cron.log`. Populated by `.agent0/tools/run-routine.sh` at cron-fire time. |

## Discipline

Future state subsystems update this README in the same commit that ships them. The README enumerates only what is present at write-time — speculative or planned subsystems (a `.claude/.skill-state/`, `.claude/.memory-events/` from a future event-sourcing spec, etc.) are NOT listed here until they actually exist. Owner pointers go to the canonical doc for the capacity — `.agent0/context/rules/<topic>.md` when the consumer-side agent acts on it, or `.claude/memory/<topic>.md` when only the upstream maintainer does — not to the hook or tool that writes the state. The doc is the durable contract; hook paths can move.

If a subsystem is removed, drop its row in the same commit that removes the writer. A row referring to a path that no longer has a writer is the failure mode this discipline avoids.
