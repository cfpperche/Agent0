# 090 — multi-runtime-entrypoints

_Created 2026-05-26._

**Status:** draft

## Intent

Refactor Agent0's agent-instruction entrypoints so the same repository can be operated transparently by Claude Code and Codex without the user maintaining two divergent sets of rules. Today `CLAUDE.md` is both the Claude Code entrypoint and the always-loaded Agent0 capacity index; Codex expects `AGENTS.md`, so Codex does not get a native, first-contact instruction surface. This spec introduces `AGENTS.md` as the Codex-facing entrypoint and refactors `CLAUDE.md` so both files clearly separate runtime-specific guidance from shared Agent0 behavior. V1 is intentionally limited to instruction entrypoints and drift discipline; Codex hook, skill, MCP, and subagent parity belong to follow-up specs.

## Acceptance criteria

- [ ] **Scenario: Codex first-contact entrypoint**
  - **Given** a fresh Agent0 checkout is opened with Codex
  - **When** Codex reads `AGENTS.md`
  - **Then** it sees the project purpose, the spec-first workflow, the **3-tier capability classification preamble** (`native-now` / `manual/read-only-now` / `Claude-only-until-follow-up`), the Codex-specific runtime surface, and pointers to shared Agent0 rules wrapped in the appropriate tier qualifier so Claude-only tool names and hook payloads are never presented as if already available in Codex; AND the root `AGENTS.md` is self-contained, fits within Codex's default project-doc byte budget, and remains semantically safe when concatenated after a hypothetical user-global `AGENTS.md`

- [ ] **Scenario: Claude Code entrypoint remains correct**
  - **Given** a fresh Agent0 checkout is opened with Claude Code
  - **When** Claude Code reads `CLAUDE.md`
  - **Then** it still sees correct Claude Code instructions and also understands that Codex uses `AGENTS.md`, with no conflicting guidance about which file owns shared Agent0 behavior

- [ ] **Scenario: shared Agent0 guidance does not silently drift (5 concrete static checks)**
  - **Given** `CLAUDE.md` and `AGENTS.md` both carry shared Agent0 guidance inside `<!-- AGENT0:BEGIN -->` / `<!-- AGENT0:END -->` markers
  - **When** a drift-detection pass runs (CI step, local script, or `sync-harness.sh --check`)
  - **Then** all five of the following hold, and any failure blocks "shipped":
    - (i) both root entrypoints (`CLAUDE.md`, `AGENTS.md`) exist
    - (ii) each file contains exactly one `<!-- AGENT0:BEGIN -->` / `<!-- AGENT0:END -->` pair in valid order
    - (iii) the managed-block content (text **inside** the markers only) compares byte-equal across the two files; runtime-specific preambles **outside** the markers are intentionally non-identical and are NOT compared
    - (iv) `AGENTS.md` contains no Claude-only command claims without a Codex caveat — `/sdd` references and similar Claude-native tool names must be wrapped in the 3-tier qualifier
    - (v) `sync-harness.sh --check` detects `AGENTS.md` drift on the baseline-tracked path (same code path as other Agent0-owned harness files)

- [ ] **Scenario: fork-facing instruction hygiene**
  - **Given** `CLAUDE.md` and `AGENTS.md` are fork-facing instruction files
  - **When** their shared Agent0 guidance is scanned
  - **Then** it contains no **concrete** Agent0-internal `docs/specs/0NN-<concrete-slug>` pointers and no **concrete** `.claude/memory/<specific-topic>.md` references (e.g. `cc-platform-hooks.md`, `propagation-hygiene.md`); **generic placeholder forms** are allowed when describing the convention (e.g. `docs/specs/NNN-<slug>/`, `.claude/memory/<topic>.md`, `.claude/memory/<slug>.md`)

- [ ] `AGENTS.md` exists at repo root, is written as the Codex runtime entrypoint, and carries the 3-tier capability classification preamble before any pointer to shared rules

- [ ] `CLAUDE.md` includes an explicit runtime-entrypoint section explaining its relationship to `AGENTS.md` AND the asymmetric file-structure contract: `CLAUDE.md` uses structured marker-aware merge (existing 058/071 design) because Claude Code has no override-file chain; `AGENTS.md` is plain baseline-tracked because Codex provides the native override chain (`AGENTS.override.md` and nested `AGENTS.md` files)

- [ ] Ownership model for shared guidance is **byte-identical managed block inside `<!-- AGENT0:BEGIN -->` / `<!-- AGENT0:END -->`** in both files, validated by a comparison check. A generator / provider-neutral source file is deferred to a follow-up spec if the first implementation shows the shared block needs templating or transformation.

- [ ] Marker layout is **asymmetric per file**: `CLAUDE.md` has (runtime-specific preamble outside markers) + (shared managed block inside markers) + (optional fork narrative outside markers). `AGENTS.md` has (runtime-specific preamble outside markers) + (shared managed block inside markers) — **no root-file fork-narrative section**. Fork-side Codex customization belongs in `AGENTS.override.md` or nested-directory `AGENTS.md` files per Codex's native instruction-chain model; this customization path is documented in `AGENTS.md`'s body as the sanctioned surface.

- [ ] `AGENTS.md` enters `sync-harness.sh` in this same implementation as a plain baseline-tracked file. Root-file edits by a fork are treated as harness customization and refused by sync without `--force`, identical to other Agent0-owned harness files.

- [ ] Managed-block byte size stays within the current `CLAUDE.md` managed-block envelope; an exact byte threshold + verification script lands in `plan.md` (e.g. `wc -c` against a stored baseline). The discipline is **index-shaped**, not expanded rule copies.

- [ ] The 3-tier capability classification is documented in `spec.md` as the canonical Codex-safety contract:
  - **native-now** — capabilities Codex can use directly: instructions in `AGENTS.md` + direct file/shell workflow
  - **manual / read-only-now** — capabilities Codex can read for context but not execute as harnessed commands: SDD artifacts + `.claude/rules/*` as behavioral references
  - **Claude-only-until-follow-up** — capabilities reserved for future Codex-port specs: hooks, slash skills, subagents, MCP recipes

- [ ] `README.md` quick start mentions that Agent0 can be opened in Claude Code or Codex once the corresponding runtime surface exists

## Non-goals

- **Codex hook parity.** Mapping `PreToolUse`, `PostToolUse`, `SessionStart`, `Stop`, and related hooks into `.codex/` is a follow-up. This spec only makes the instruction surface native and non-ambiguous.
- **Codex skill/subagent/MCP parity.** Porting `.claude/skills/`, custom subagents, and MCP recipes to Codex-specific locations is future scope.
- **Renaming `.claude/` to `.agent0/`.** The existing harness stays where it is for v1. A neutral namespace may be worth debating later, but forcing it into this spec would expand blast radius.
- **Making `CLAUDE.md` and `AGENTS.md` identical end-to-end.** Runtime-specific preambles are expected. The shared behavior must be synchronized or explicitly differentiated; the whole files do not need to be byte-identical.
- **Supporting every agent runtime.** Codex is the second runtime. Cursor, Aider, and other tools are useful prior art but not implementation targets for this spec.
- **Changing the public capacity set.** This spec changes how instructions are surfaced, not which Agent0 capacities exist.
- **Structured marker-aware merge for `AGENTS.md`.** Deferred to a follow-up spec if real fork customization demand surfaces (rule-of-three demand test). v1 treats root `AGENTS.md` as Agent0-owned + plain baseline-tracked; fork-specific Codex guidance uses Codex's native override chain (`AGENTS.override.md` / nested `AGENTS.md`).
- **Generator / provider-neutral source for the shared block.** Deferred. v1 default is byte-identical duplication + comparison test. A generator path (e.g. `.agent0/instructions/managed-block.md` rendering into each runtime entrypoint) is documented as a future-upgrade route conditional on the shared block needing templating or non-trivial transformation.
- **Codex smoke command in CI / required verification.** A manual `codex --ask-for-approval never "Summarize the current instructions."` dogfood may land in `plan.md` / `tasks.md` as optional verification, but is NOT a required spec gate.

## Open questions

- [x] ~~Should shared Agent0 guidance be byte-identical inside `<!-- AGENT0:BEGIN -->` / `<!-- AGENT0:END -->` in both files, or should there be a new provider-neutral source such as `.agent0/instructions/managed-block.md` that renders into each runtime entrypoint?~~ **Resolved by debate (2026-05-26):** byte-identical for v1 + comparison test. Generator is deferred (see § Non-goals).
- [x] ~~Should `sync-harness.sh` propagate `AGENTS.md` in the same implementation, or should `AGENTS.md` first land only in Agent0 and become fork-syncable after the Codex hook/skill parity shape is clearer?~~ **Resolved by debate (2026-05-26):** propagate in this same implementation as plain baseline-tracked file. Structured-merge support deferred (see § Non-goals).
- [ ] How much Codex-specific capability should `AGENTS.md` claim before `.codex/config.toml`, Codex hooks, and `.agents/skills/` are actually implemented? **Constrained by debate (2026-05-26):** bounded by the 3-tier capability classification — `AGENTS.md` may claim nothing in the `Claude-only-until-follow-up` tier without a future spec implementing it. Plan uses the 3-tier table as the rubric for what to include vs defer.
- [ ] Should `CLAUDE.md` mention Codex only in a short runtime preamble, or should the managed Agent0 block itself become runtime-neutral enough to be shared verbatim? (Depends on resolution of the Codex-capability question above at plan time.)
- [x] ~~What local verification is sufficient for drift: shell test comparing managed-block content, sync-harness test fixture, or a future generator command?~~ **Resolved indirectly by debate (2026-05-26):** the 5-check static list under § Acceptance criteria. Exact threshold + scripting lands in `plan.md`.

## Context / references

- `CLAUDE.md` — current Claude Code entrypoint and Agent0 managed block.
- `.claude/rules/spec-driven.md` — SDD artifact rules and the optional `debate.md` flow used by this spec.
- `.claude/skills/sdd/SKILL.md` — `/sdd new` and `/sdd debate` protocol followed to create this spec.
- `docs/specs/058-claude-md-managed-block/` — introduced `AGENT0:BEGIN/END` markers and managed-region merge semantics.
- `docs/specs/071-claude-md-capacity-index/` — compressed `CLAUDE.md` managed block into an index, relevant to any shared-block reuse.
- `.claude/memory/propagation-hygiene.md` — maintainer discipline for fork-facing files: do not leak Agent0-internal concrete spec or memory pointers into propagated instructions.
- OpenAI Codex `AGENTS.md` guide — Codex's native repository instruction file: https://developers.openai.com/codex/guides/agents-md
- OpenAI Codex hooks guide — relevant follow-up surface, explicitly out of v1 scope here: https://developers.openai.com/codex/hooks
- OpenAI Codex skills guide — relevant follow-up surface, explicitly out of v1 scope here: https://developers.openai.com/codex/skills
- OpenAI Codex MCP guide — relevant follow-up surface, explicitly out of v1 scope here: https://developers.openai.com/codex/mcp
- `docs/specs/090-multi-runtime-entrypoints/debate.md` — cross-model debate (Claude Code initiating, Codex CLI reviewing) over Rounds 1–3 that resolved Open Q1 / Q2 / Q5, constrained Q3 to the 3-tier classification, narrowed the ownership model to byte-identical + comparison test, and established the asymmetric file-structure contract between `CLAUDE.md` and `AGENTS.md`.
