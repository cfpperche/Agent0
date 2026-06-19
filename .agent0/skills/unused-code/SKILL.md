---
name: unused-code
description: On-demand detector for UNUSED/dead code in this project — unused files, exports, dependencies, and unreferenced members. Use when the user wants to find dead code, do code housekeeping, or check what can be removed ("find unused code", "any dead code?", "what exports are unused", "unused dependencies", "clean up the codebase"). Wraps the runtime-neutral .agent0/tools/unused-code.sh (engine - knip; JS/TS only in v1). Reports + proposes "candidate unused" items; never deletes, never gates edit/commit/install. NOT vulnerability scanning (that is the sibling /vuln-audit); NOT complexity/refactor smells (deferred). Flags - [path] --json --exit-code. See .agent0/context/rules/unused-code-audit.md.
argument-hint: "[path] [--json] [--exit-code]"
license: MIT
compatibility: Designed for Claude Code. Core logic is the runtime-neutral bash tool `.agent0/tools/unused-code.sh` (knip + jq); the skill is a thin invocation wrapper, portable to any runtime that can run the tool. Codex CLI invokes the tool directly.
metadata:
  agent0-portability-tier: agentskills-portable
  version: "0.1"
---

# /unused-code — unused/dead-code detector

Thin wrapper over `.agent0/tools/unused-code.sh`. The tool is the engine; this skill decides when to run it and how to surface the result. See `.agent0/context/rules/unused-code-audit.md` for the full capacity contract (trigger surface, engine choice, status model, the `unconfigured` caveat, non-goals).

## When to run

Run on demand when the user asks to find unused/dead code, do code housekeeping, or assess what can be removed — or proactively before a cleanup pass / when reviewing a PR that deletes or refactors a module. **Do not** wire this into the per-edit validator path, a commit hook, or an install gate — it is whole-program analysis, noisy, and needs human triage. It is detection + proposal only; the human decides what to remove. (Twin of `/vuln-audit`; same on-demand, report-never-act philosophy — spec 208.)

A consumer that genuinely wants inline enforcement can declare a custom command in `.agent0/validator.json` (e.g. `{ "name": "deadcode", "run": "npx knip" }`) — that is consumer-owned, not something this skill or Agent0 wires up.

## What to do

1. **Parse `$ARGUMENTS`** — pass them straight through to the tool. All are optional:
   - `[path]` — directory to scan (default: repo root `.`).
   - `--json` — structured output (for wrappers/tests; shape-only, not a wire contract).
   - `--exit-code` — map result status to a non-zero exit (`findings`=1, `unconfigured`=2, `unavailable`=3, `failed`=4) for consumer-owned CI. Omit for the default advisory behavior (always exit 0).

2. **Invoke the tool:**
   ```bash
   bash .agent0/tools/unused-code.sh $ARGUMENTS
   ```

3. **Surface the result** — relay the tool's report. The first line is `status=<no-stack|clean|findings|unconfigured|unavailable|failed>`:
   - **`clean`** — say so plainly: no unused code found *by knip*, given the project's knip config.
   - **`findings`** — summarise per finding by kind (unused file / unused export / unused dependency / unreferenced member / other). Frame every item as a **candidate** — exports may be intentional public API, files may be loaded dynamically. **Propose** removals for the human to confirm; do NOT delete anything yourself.
   - **`unconfigured`** — knip is installed but has no config, so it has no entry-point/boundary model and would manufacture false positives. Relay the hint to add a `knip.json`; do not run knip's bare defaults as a workaround. Offer to scaffold a minimal `knip.json` (declaring `entry` + `project`) if the user wants.
   - **`unavailable`** — knip isn't installed. Relay the install hint; offer to proceed once installed. Do not treat this as "clean".
   - **`no-stack`** — no JS/TS stack detected. v1 covers JS/TS via knip only; say so honestly rather than implying the project is clean.
   - **`failed`** — the engine errored. Relay the diagnostic; suggest re-running the raw command.

4. **Coverage caveat** — when reporting `clean`, frame it honestly: "no unused code found *by knip* under its configured boundaries", not "there is no dead code". And note v1 only covers JS/TS — other stacks are out of scope (deferred).

## Removal discipline

The capacity proposes; the human disposes. Never delete files, remove exports, or strip dependencies as part of this skill, and never run a knip `--fix`-style auto-removal. "Unused" is a candidate signal, not proof of safety (public API, dynamic imports, framework entry points). If the user wants removals applied, that is a separate, explicit action they confirm.

## Notes

_Consumer-extension surface — append consumer-local bullets here. Sync flags the file as customized but the conflict region is mechanically this section._

- A recurring cadence is out of scope for v1 — to run this periodically, wire `/routine` to invoke the tool (the documented deferred path; see `.agent0/context/rules/unused-code-audit.md`).
- Suppressing individual false positives is engine-native — configure it in `knip.json` (entry points, `ignore`, plugins), not via an Agent0 marker.
- knip configuration reference: https://knip.dev/overview/configuration
