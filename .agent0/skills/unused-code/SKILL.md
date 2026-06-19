---
name: unused-code
description: On-demand detector for UNUSED/dead code in this project — unused files, exports, dependencies, unreferenced members, and unreachable code. Use when the user wants to find dead code, do code housekeeping, or check what can be removed ("find unused code", "any dead code?", "what exports are unused", "unused dependencies", "clean up the codebase"). Wraps the runtime-neutral .agent0/tools/unused-code.sh — one engine per stack (JS/TS=knip, Python=vulture, Go=deadcode; --stack to force; polyglot repos surface unaudited_stacks). Reports + proposes "candidate unused" items; never deletes, never gates edit/commit/install. Rust/PHP deferred (their tools find unused deps, not dead code). NOT vulnerability scanning (that is the sibling /vuln-audit); NOT complexity/refactor smells (deferred). Flags - [path] --json --exit-code --stack <js|python|go>. See .agent0/context/rules/unused-code-audit.md.
argument-hint: "[path] [--json] [--exit-code] [--stack <js|python|go>]"
license: MIT
compatibility: Designed for Claude Code. Core logic is the runtime-neutral bash tool `.agent0/tools/unused-code.sh` (knip/vulture/deadcode + jq); the skill is a thin invocation wrapper, portable to any runtime that can run the tool. Codex CLI invokes the tool directly.
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
   - `--stack <js|python|go>` — force which stack to audit (overrides first-match). Use in polyglot repos.

2. **Invoke the tool:**
   ```bash
   bash .agent0/tools/unused-code.sh $ARGUMENTS
   ```

3. **Surface the result** — relay the tool's report. The first line is `status=<no-stack|clean|findings|unconfigured|unavailable|failed>`; the engine is one per stack (JS/TS=knip, Python=vulture, Go=deadcode):
   - **`clean`** — say so plainly: no unused code found *by the engine* under its boundaries.
   - **`findings`** — summarise per finding by kind (unused file / export / dependency / unreferenced member / unreachable code / other). For Python (vulture), **report the `confidence`** and note findings are heuristic. Frame every item as a **candidate** — exports may be intentional public API, code may be reached dynamically. **Propose** removals for the human to confirm; do NOT delete anything yourself.
   - **`unconfigured`** — the engine lacks its boundary/entry model: knip with no config, or Go deadcode with no executable `main` (library-only). Relay the hint; do not work around it with bare defaults. For knip, offer to scaffold a minimal `knip.json`.
   - **`unavailable`** — the stack's engine isn't installed. Relay the ecosystem-correct install hint; offer to proceed once installed. Do not treat this as "clean".
   - **`no-stack`** — no supported stack (JS/TS, Python, Go) detected; say so honestly rather than implying the project is clean.
   - **`failed`** — the engine errored. Relay the diagnostic; suggest re-running the raw command.

4. **Polyglot + coverage caveat** — if the JSON carries `unaudited_stacks` (or the human output a "not audited" note), tell the user other stacks were detected but not audited, and offer to re-run with `--stack=<name>`. When reporting `clean`, frame it honestly: "no unused code found *by the engine* under its boundaries", not "there is no dead code". Rust/PHP are out of scope (their tools find unused deps, not dead code — deferred).

## Removal discipline

The capacity proposes; the human disposes. Never delete files, remove exports, or strip dependencies as part of this skill, and never run a knip `--fix`-style auto-removal. "Unused" is a candidate signal, not proof of safety (public API, dynamic imports, framework entry points). If the user wants removals applied, that is a separate, explicit action they confirm.

## Notes

_Consumer-extension surface — append consumer-local bullets here. Sync flags the file as customized but the conflict region is mechanically this section._

- A recurring cadence is out of scope for v1 — to run this periodically, wire `/routine` to invoke the tool (the documented deferred path; see `.agent0/context/rules/unused-code-audit.md`).
- Suppressing individual false positives is engine-native, not an Agent0 marker — `knip.json` (entry/`ignore`/plugins) for JS/TS, a vulture whitelist or `--min-confidence` for Python, deadcode's reachability model for Go.
- References: knip https://knip.dev/overview/configuration · vulture https://github.com/jendrikseipp/vulture · Go deadcode https://pkg.go.dev/golang.org/x/tools/cmd/deadcode
