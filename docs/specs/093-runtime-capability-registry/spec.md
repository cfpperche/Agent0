# 093 — runtime-capability-registry

_Created 2026-05-26._

**Status:** shipped

## Intent

Create a single runtime-capability registry that makes Agent0's multi-agent support honest, discoverable, and evolvable across Claude Code, Codex CLI, and future tool-calling runtimes. Specs 090 and 092 established two shared surfaces: runtime entrypoints (`CLAUDE.md` / `AGENTS.md`) and neutral session handoff (`.agent0/HANDOFF.md`). The next gap is a canonical matrix that says which Agent0 capacities are `native`, `native-opt-in`, `convention`, `read-only`, `planned`, or `unsupported` in each runtime (vocabulary defined in Scenario 3). This registry should prevent capability claims from drifting across `AGENTS.md`, `CLAUDE.md`, `.claude/rules/*`, and future MCP/runner specs, while giving users a transparent answer to "what works here with Claude, what works with Codex, and what is still planned?"

The immediate purpose is not to make every Claude-only feature work in Codex. It is to define the map that future specs use, with MCP parity as the first likely follow-up row rather than a one-off port. The v1 canonical path is `.claude/rules/runtime-capabilities.md` — Agent0-managed policy that ships to forks via the existing `.claude/rules/*` sync glob. The directory name is a propagation convention; the registry content is deliberately provider-neutral.

## Acceptance criteria

- [x] **Scenario: users can inspect one canonical capability matrix**
  - **Given** Agent0 is used by Claude Code and Codex CLI
  - **When** a user or agent wants to know whether a capability is `native`, `native-opt-in`, `convention`, `read-only`, `planned`, or `unsupported` in a runtime
  - **Then** one canonical registry answers that question for the current first-party capability set, including at minimum: instruction entrypoints, session handoff, SDD, debate, lifecycle hooks, runtime introspect, delegation/subagents, MCP recipes, image generation, memory, harness sync, and customization/sync surfaces. `planned` cells carry a future spec slug where known (e.g. `planned: NNN-mcp-parity`) or `planned: untracked` otherwise.

- [x] **Scenario: runtime entrypoints point at the registry instead of duplicating roadmap claims**
  - **Given** `CLAUDE.md` and `AGENTS.md` are the first-contact files for Claude Code and Codex CLI
  - **When** either entrypoint mentions multi-runtime support or capability tiers
  - **Then** it points to the canonical registry for detailed status and keeps only a bootstrap pointer plus skeptical-default guidance (agents should assume `convention` or `planned` until the registry's runtime column says otherwise). Tier definitions, capability rows, and status vocabulary live exclusively in the registry; the current `AGENTS.md` Codex Capability Tiers table is removed in the same change.

- [x] **Scenario: status vocabulary is provider-neutral and testable**
  - **Given** a capability row in the registry
  - **When** it assigns support state for Claude Code, Codex CLI, or a future runtime
  - **Then** the cell value is one of six documented vocabulary terms with operational meaning: `native` (works on clone; runtime has a primitive that consumes the capacity), `native-opt-in` (runtime has the primitive but user must enable it via env var, config copy, or credential), `convention` (no primitive; entrypoint instructs the agent to perform the capacity manually following a documented rule), `read-only` (agent can read the artifacts the capacity produces but cannot invoke or extend it), `planned` (explicitly scoped for a future spec; carries spec slug or `untracked`), or `unsupported` (no path forward declared). Runtime-specific labels such as `Claude-only-until-follow-up` are not used.

- [x] **Scenario: Codex is not over-promised**
  - **Given** Codex reads `AGENTS.md` before doing non-trivial work
  - **When** the task touches a capability that is still Claude-hook-native, slash-skill-native, subagent-native, or MCP-activation-specific
  - **Then** the registry and entrypoint wording make clear whether Codex may use it directly, only emulate it manually with file/shell work, only read it as reference, or must wait for a follow-up spec

- [x] **Scenario: MCP parity has an obvious next-step shape**
  - **Given** MCP recipes currently live in `.claude/rules/mcp-recipes.md`, `.mcp.json.example`, and Claude `SessionStart` hints
  - **When** the v1 registry ships
  - **Then** it already contains a non-implementation worked-example row for MCP recipes that pressure-tests the v1 vocabulary before any MCP parity work starts. The row lists owner files (`.claude/rules/mcp-recipes.md`, `.mcp.json.example`, `.claude/hooks/mcp-recipes-hint.sh`), marks Claude support as `native-opt-in` (not plain `native` — recipes require user activation), marks Codex support as `convention` or `planned`, and carries the follow-up spec slug. If the row cannot be expressed in the proposed vocabulary, the vocabulary changes before this spec moves to plan/tasks.

- [x] **Scenario: registry ownership does not conflict with handoff ownership**
  - **Given** spec 092 made `.agent0/HANDOFF.md` per-project state and explicitly rejected sync-by-default for `.agent0/**`
  - **When** this spec introduces an Agent0-owned capability registry
  - **Then** the registry lives at `.claude/rules/runtime-capabilities.md` — an already Agent0-managed surface that propagates via the existing `.claude/rules/*` sync glob. No `.agent0/<file>` exception is introduced; `.agent0/HANDOFF.md` and `.agent0/**` remain per-project state per spec 092.

- [x] **Scenario: drift checks protect the new source of truth**
  - **Given** the registry becomes canonical
  - **When** `AGENTS.md`, `CLAUDE.md`, or adjacent rules make capability-tier claims
  - **Then** `.claude/tools/check-instruction-drift.sh` (or a nearby helper/test invoked alongside it) verifies five anchor-level invariants without parsing per-cell values: (a) `.claude/rules/runtime-capabilities.md` exists; (b) both `AGENTS.md` and `CLAUDE.md` point to it; (c) the old `AGENTS.md` Codex Capability Tiers table is gone; (d) the six documented vocabulary terms appear in the registry; (e) the minimum-set capability row labels from Scenario 1 each appear at least once. Extra rows for newly-added capabilities are permitted; duplicate required labels are errors.

- [x] The registry includes at least two concrete runtime columns for v1: `Claude Code` and `Codex CLI`. Additional runtime columns (`Cursor`, `Aider`, `Hermes Agent`, etc.) may appear only as explicitly future/unknown placeholders, not as asserted support.

- [x] The registry includes an owner-file reference **list** for each first-party capability row so future specs know which files actually implement or document the capability. Several capabilities span rules, hooks, tools, tests, and specs; single-file references are insufficient.

- [x] The registry states its update rule: every future spec that changes runtime support for a capability must update `.claude/rules/runtime-capabilities.md` in the same change. New capability rows may be added without expanding the drift check's minimum-required-labels set; that set grows only when a follow-up spec explicitly promotes a row to the minimum.

## Non-goals

- **Implementing MCP parity.** This spec prepares the row and ownership model; a follow-up spec decides whether Codex can consume the same `.mcp.json`, needs another config, or only gets documentation.
- **Resuming or automating spec 091.** The debate runner remains paused. This registry may reference 091 as planned work but does not build the runner.
- **Porting Claude hooks, skills, or subagents to Codex.** The matrix can mark those as planned/manual/read-only; implementation belongs to separate specs.
- **Replacing `.agent0/HANDOFF.md`.** Handoff remains the live work-state file from spec 092.
- **Creating a lock server, broker, daemon, or agent router.** This is documentation/control-plane clarity, not orchestration runtime.
- **Declaring support for runtimes not actually dogfooded.** Future runtimes can be placeholders only.
- **Documenting Codex equivalents for Claude hooks/skills/subagents.** Per-runtime parity design (which Codex primitive could replace which Claude hook) belongs in follow-up parity specs, not this registry. The registry maps current state and planned work; it does not propose replacement architectures.
- **Turning the registry into a versioned machine API or structured sidecar in v1.** Markdown is canonical; a YAML/JSON sidecar was considered and rejected in `debate.md` Round 2 because two canonical files for one registry would reintroduce the drift risk this spec is built to eliminate. Promote to a schema only when a future spec has a real machine-read use case.

## Open questions

_All five OQs resolved during debate (see `debate.md` § Synthesis):_

- [x] ~~**Canonical path.** Should the registry live under a neutral namespace such as `.agent0/capabilities.md`, under the existing managed documentation surface such as `.claude/rules/runtime-capabilities.md`, or somewhere else?~~ → **resolved**: `.claude/rules/runtime-capabilities.md`. `.agent0/<file>` rejected because spec 092 made `.agent0/**` per-project state; mixing Agent0-managed policy in would blur that contract. The `.claude/` directory name is a propagation convention, not a runtime-exclusivity claim.
- [x] ~~**Status vocabulary.** Should the v1 vocabulary reuse `native-now`, `manual/read-only-now`, and `Claude-only-until-follow-up` from `AGENTS.md`, or replace them with provider-neutral states such as `native`, `convention`, `read-only`, `planned`, and `unsupported`?~~ → **resolved**: replaced with the six provider-neutral cell states defined in Scenario 3 (`native`, `native-opt-in`, `convention`, `read-only`, `planned`, `unsupported`). The `-now` suffix is dropped; `native-opt-in` is added to separate activation cost from runtime nativeness.
- [x] ~~**Entry-point shape.** Should the current Codex Capability Tiers table stay in `AGENTS.md` as a bootstrap summary, or should it move entirely into the registry with only a pointer left in `AGENTS.md`?~~ → **resolved**: `AGENTS.md` (and `CLAUDE.md`'s managed block) keep only a pointer plus skeptical-default guidance. Tier definitions, capacity rows, and vocabulary live exclusively in the registry; the current `AGENTS.md` Codex Capability Tiers table is removed.
- [x] ~~**Sync behavior.** If the registry lives under `.agent0/`, should `sync-harness.sh` gain a single-file exception for it, or should `.agent0/` remain entirely per-project state until a broader neutral-namespace spec?~~ → **resolved (moot)**: the registry does not live under `.agent0/`; no sync-harness exception is introduced. `.agent0/HANDOFF.md` and `.agent0/**` remain per-project state per spec 092.
- [x] ~~**Data shape.** Is a markdown matrix enough, or do we need a tiny machine-readable sidecar to make drift checks reliable without parsing a human table?~~ → **resolved**: markdown canonical, no sidecar in v1. A YAML/JSON sidecar was considered and rejected because two canonical files would reintroduce the drift risk this spec is built to eliminate. The five anchor-level drift checks in Scenario 7 do not parse per-cell values, so the parsing-fragility concern that motivated the sidecar is moot. Promote to a schema only when a future spec has a real machine-read use case.

## Context / references

- `docs/specs/090-multi-runtime-entrypoints/` — introduced `AGENTS.md`, the asymmetric Claude/Codex entrypoint model, and the current Codex capability tier preamble.
- `docs/specs/092-multi-runtime-handoff/` — introduced `.agent0/HANDOFF.md` and explicitly made `.agent0/**` per-project state unless a future spec opts a file into sync.
- `docs/specs/091-sdd-debate-runner/` — paused runner spec; a capability registry should mark it planned rather than active.
- `AGENTS.md` — Codex-native first-contact surface and current place where capability tiers are explained.
- `CLAUDE.md` — Claude Code first-contact surface and managed shared Agent0 index.
- `.claude/rules/session-handoff.md` — documents asymmetric enforcement: Claude hooks vs Codex convention.
- `.claude/rules/mcp-recipes.md` — current MCP recipe surface; likely first follow-up capability after the registry.
- `.claude/rules/runtime-introspect.md` — example of a Claude-hook-native capability with manual/read-only implications for Codex.
- `.claude/tools/check-instruction-drift.sh` — existing drift check that may need extension once the registry becomes canonical.
- `.claude/skills/skill/references/portability-tiers.md` — separate axis: skill-body portability tiers (`cc-native`, `agentskills-portable`, `runtime-agnostic`) remain the source of truth for skill body code portability. The registry covers runtime support for Agent0 capabilities and may cite skill tiers as evidence without replacing them.
- `docs/specs/093-runtime-capability-registry/debate.md` — cross-model debate (Codex CLI initiating, Claude Code reviewing) over Rounds 1-2 that resolved path, vocabulary, entrypoint-shape, sync-behavior, and data-shape questions; converged on markdown-canonical with anchor-level drift checks.
