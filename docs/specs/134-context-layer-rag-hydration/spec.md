# 134 — context-layer-rag-hydration

_Created 2026-05-31._

**Status:** shipped

## Intent

Build Agent0's v1 context retrieval and hydration layer. This is not semantic RAG in v1: no embeddings, vector DB, hosted service, or second memory store. The feature adds a deterministic local retriever that returns provenance-labeled source pointers from Agent0's existing context corpus, then lets `context-inject.sh` use that retrieval lane inside the current `AGENT0_CONTEXT_INJECTION` budget without flooding the prompt. Source files remain canonical: `.agent0/context/rules/*.md`, `.agent0/memory/MEMORY.md` plus memory entry metadata, `docs/specs/*/spec.md`, and `.agent0/HANDOFF.md`.

The core contract is context engineering, not memory replacement. A hydrated item identifies its source class and authority, explains why it was selected, reports freshness where available, and tells the agent whether to read the source file before acting. Consumer projects receive the retrieval mechanism through the harness, but each project owns its own corpus and any generated local cache.

## Acceptance criteria

- [x] **Scenario: Explicit retrieval returns provenance-labeled candidates**
  - **Given** a prompt or operator command asks about Agent0 context, memory, specs, or handoff state
  - **When** `bash .agent0/tools/context-retrieve.sh search --query "<text>"` runs
  - **Then** it returns deterministic ranked candidates with `source_class`, `authority`, source path, title or anchor, score/reason, freshness status, and a read-before-acting expectation.

- [x] **Scenario: Retrieval has no paid or heavyweight default dependency**
  - **Given** a fresh checkout without embedding credentials, vector extensions, hosted services, or optional native databases
  - **When** `context-retrieve.sh` searches the default corpus
  - **Then** the lexical local fallback works with the repo's normal shell/Python floor.

- [x] **Scenario: Memory participates as a read-through adapter**
  - **Given** `.agent0/memory/MEMORY.md` and memory entry metadata exist
  - **When** retrieval searches memory
  - **Then** memory results are produced from the existing memory projection/metadata path and never from a second token/text index over `.agent0/memory/*.md`.

- [x] **Scenario: Prompt hydration is substitutive and bounded**
  - **Given** `UserPromptSubmit` runs `.agent0/hooks/context-inject.sh`
  - **When** retrieval adds candidates to the prompt context
  - **Then** the output remains one `AGENT0_CONTEXT_INJECTION` block under the existing `MAX_FRAGMENTS` and `MAX_BYTES` limits, with no second retrieval dump.

- [x] **Scenario: Deterministic floor cannot be evicted**
  - **Given** the prompt explicitly matches a routing or governance rule selected by the existing deterministic keyword/path logic
  - **When** retrieval ranking also produces candidates
  - **Then** the deterministic rule capsule stays in the hydrated output and retrieval competes only for the remaining fragment/byte budget.

- [x] **Scenario: Diagnostics explain selection**
  - **Given** a maintainer debugs unexpected or missing context
  - **When** `context-retrieve.sh` runs in debug mode or `context-inject.sh` runs with diagnostic context enabled
  - **Then** the output shows the query, corpus adapters, floor reservations, ranking reasons, omitted candidates, budget limits, and freshness/staleness labels.

- [x] **Scenario: Runtime-neutral parity is default**
  - **Given** Claude Code and Codex CLI run the same checkout
  - **When** retrieval is invoked through the tool or through `context-inject.sh`
  - **Then** both runtimes use the same `.agent0/` implementation and deterministic lexical fallback; runtime differences are limited to hook registration/envelope.

- [x] The generated retrieval cache location, if used, is documented as gitignored project-local state under `.agent0/.context-index/`; v1 may reserve the path without writing cache files.
- [x] The sync-harness manifest propagates retrieval mechanisms/tests/docs but not project memory content or generated retrieval state.
- [x] Focused tests cover explicit retrieval, memory adapter behavior, prompt hydration budget/floor behavior, diagnostics, and sync-harness propagation.

## Non-goals

- Build semantic/vector retrieval in v1.
- Require a hosted retrieval service, API key, paid embeddings, sqlite-vec, or other heavyweight dependency in the default path.
- Replace `.agent0/memory/*.md`, `.agent0/memory/MEMORY.md`, `.agent0/context/rules/*.md`, specs, or handoff files as source of truth.
- Build a second canonical memory index or token/text index over `.agent0/memory/*.md`.
- Ship Agent0's factual project memory, generated embeddings, or retrieval cache content into consumer projects.
- Index arbitrary product/source code in v1.
- Run a background daemon, automatic re-index-on-every-edit hook, or commit-time indexing step.
- Retrieve across projects or share memory between projects.
- Build a human dashboard for memory/context observability.
- Let retrieval override explicit user instructions, runtime capability rules, or SDD/handoff contracts.

## Open questions

- [x] Should v1 include semantic embeddings? No. V1 is deterministic lexical retrieval only; semantic/vector retrieval is deferred to a future opt-in spec.
- [x] Is memory in v1? Yes, as a read-through adapter over existing memory artifacts and metadata, not as a second textual index.
- [x] Does `context-inject.sh` call retrieval? Yes, as a bounded retrieval lane after deterministic floor selection. It must not emit a second model-visible block.
- [x] What is the cache policy? Generated cache state is project-local and gitignored under `.agent0/.context-index/` if/when used. V1 may avoid persistent cache.
- [x] What corpus classes are in v1? Context rules, project memory index/metadata, spec files, and handoff. Product code, reminders, and routines are deferred.

## Context / references

- `docs/specs/134-context-layer-rag-hydration/debate.md` — Claude/Codex debate and convergence.
- `.agent0/context/rules/memory-placement.md` — project memory is project-local and not shipped as content to consumers.
- `.agent0/context/rules/runtime-capabilities.md` — context injection, hooks, memory, and skills are tracked across Claude Code and Codex CLI.
- `.agent0/hooks/context-inject.sh` — current prompt-time context hydrator.
- `.agent0/hooks/startup-brief.sh` — current bounded startup context aggregator.
- `.agent0/tools/memory-query.sh` and `.agent0/tools/memory-project.sh` — current memory query/projection primitives.
- `.agent0/memory/harness-home.md` — runtime-neutral mechanisms belong under `.agent0/`; runtime-specific files should only register or envelope them.
- `.agent0/memory/agent0-core-thesis.md` — Agent0's durable value is context engineering and governance, not breadth of agents/skills.
- `docs/specs/099-memory-multi-runtime/` — memory moved to runtime-neutral `.agent0/` and gained multi-runtime hooks.
- `docs/specs/122-context-injection-rules-cutover/` — context rules moved to `.agent0/context/rules/` and are hydrated by hooks.
- `docs/specs/124-hook-context-noise-control/` — startup/prompt hydration became bounded and capsule-based.
