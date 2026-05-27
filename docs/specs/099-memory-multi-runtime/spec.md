# 099 — memory-multi-runtime

_Created 2026-05-27._

**Status:** draft

## Intent

Port Agent0's project-memory bucket (`.claude/memory/<topic>.md` plus the derived `.claude/memory/MEMORY.md` index) from a Claude Code-centered capacity into an explicitly multi-runtime convention that Claude Code and Codex CLI can both use without inventing a second memory store. The target shape mirrors the `.agent0/HANDOFF.md` precedent: one canonical file set, two enforcement mechanisms. Claude Code keeps native hooks for discovery-adjacent signals, journaling, projection, validation, index gating, and decay readout; Codex gets a clear `AGENTS.md` convention that tells it when to read memory, which shared shell primitives to run, how to keep the index converged after edits, and which asymmetries are intentionally not automatic in v1. The goal is runtime-neutral project knowledge and predictable maintenance behavior, not full Codex lifecycle hook parity.

## Acceptance criteria

- [ ] **Scenario: Codex discovers project memory through its own entrypoint**
  - **Given** a Codex CLI session starts in Agent0 and reads root `AGENTS.md`
  - **When** the task is non-trivial or may depend on prior project facts, decisions, gotchas, or platform constraints
  - **Then** `AGENTS.md` directs Codex to use `.claude/memory/MEMORY.md` as the lazy-read index, follow only the specific entries relevant to the task, and treat `.claude/rules/memory-placement.md` as the bucket contract

- [ ] **Scenario: both runtimes read the same project-memory source**
  - **Given** a memory entry exists under `.claude/memory/<topic>.md` and appears in `.claude/memory/MEMORY.md`
  - **When** Claude Code follows the `CLAUDE.md` memory block and Codex follows the `AGENTS.md` memory block
  - **Then** both runtimes are pointed at the same entry files and the same derived index; no Codex-only mirror, Claude-only source, or generated duplicate memory tree is introduced

- [ ] **Scenario: Codex keeps the derived index converged after memory edits**
  - **Given** Codex creates, edits, renames, or deletes a project-memory entry under `.claude/memory/`
  - **When** it follows the documented Codex post-edit memory convention
  - **Then** `.claude/memory/MEMORY.md` is regenerated with `bash .claude/tools/memory-project.sh`, the projected index reflects the current entry frontmatter, and `git diff` makes any entry/index drift visible before the session ends

- [ ] **Scenario: Codex has an explicit frontmatter validation path**
  - **Given** Codex writes a malformed memory entry missing `name`, `description`, or `metadata.type`
  - **When** it runs the documented runtime-agnostic frontmatter validation command for that entry
  - **Then** the command emits a `memory-frontmatter-advisory:`-style message, exits non-blocking, and points back to `.claude/rules/memory-placement.md` § `Frontmatter schema`

- [ ] **Scenario: Codex sees decay without a SessionStart hook**
  - **Given** a Codex session is doing memory-relevant work and `.claude/memory/` contains stale or confirmed entries
  - **When** Codex follows the documented readout convention and runs `bash .claude/tools/memory-query.sh decay --readout`
  - **Then** it sees the same `=== MEMORY DECAY ===` framed output Claude Code receives from its SessionStart hook, including the `(no stale entries)` empty case

- [ ] **Scenario: raw `MEMORY.md` edits are discouraged even without a Codex gate**
  - **Given** Codex needs to add or change project-memory content
  - **When** it consults `AGENTS.md` or `.claude/rules/memory-placement.md`
  - **Then** it is instructed to edit `.claude/memory/<topic>.md` source entries and rerun projection, not hand-edit `.claude/memory/MEMORY.md`; the docs explicitly state that Codex has no PreToolUse gate in v1 and that a later projection re-converges accidental raw-index drift

- [ ] **Scenario: journal posture is explicit across runtimes**
  - **Given** a memory entry is edited by Claude Code or Codex
  - **When** a maintainer reads `.claude/rules/memory-placement.md` after this spec ships
  - **Then** the rule states exactly which runtime actions append `.claude/.memory-events.jsonl` events, whether Codex uses a manual journaling command or remains unjournaled in v1, and which durable audit trail still exists through git history

- [ ] **Scenario: capability matrix remains truthful**
  - **Given** `.claude/rules/runtime-capabilities.md` is read after implementation
  - **When** the reader checks the `memory` row
  - **Then** Claude Code is still described as hook-native, Codex CLI is described as convention-driven unless a real Codex primitive exists, and the Notes column names the shared shell primitives and the remaining lifecycle-hook asymmetry

- [ ] `AGENTS.md` contains a Codex-facing memory protocol covering: lazy-read discovery, `memory-query.sh` search/list/decay usage, post-edit projection, frontmatter validation, confirm semantics, and "do not raw-edit `MEMORY.md`" guidance.

- [ ] `CLAUDE.md` and `AGENTS.md` continue to point at the same project-memory bucket and do not fork the conceptual model.

- [ ] `.claude/rules/memory-placement.md` gains a `## Multi-runtime usage` or equivalent section documenting the Claude Code hook path and the Codex convention path side by side.

- [ ] Runtime-agnostic memory tools remain shell-invocable from the project root with no Claude Code tool-surface dependency: `memory-project.sh`, `memory-query.sh`, `memory-query-helper.py`, and any new validation or journaling helper introduced by this spec.

- [ ] Tests or verification scripts cover the Codex-manual path at least at the shell level: frontmatter validation advisory, projection idempotence after an entry edit, and decay readout command output.

## Non-goals

- **No Codex lifecycle hook parity.** Codex does not gain automatic SessionStart, PreToolUse, or PostToolUse hooks in this spec. Any Codex maintenance step is an explicit convention or shell command.
- **No second memory store.** Do not create a Codex-only memory directory, duplicate index, generated mirror, database, daemon, or broker process.
- **No automatic memory-content propagation to consumer projects.** Project-memory content remains project-local; sync-harness still ships only the memory bucket scaffold unless a separate spec changes that contract.
- **No per-user Claude Code memory port.** Bucket 1 (`~/.claude/projects/<path>/memory/`) remains Claude Code-specific user preference storage and is not made Codex-readable.
- **No read-tracking bump on ordinary file reads.** Reading or grepping a memory entry does not mutate `last_accessed`; `memory-query.sh confirm` remains the explicit validation signal unless a later spec changes that.
- **No auto-archive, auto-delete, or staleness mutation.** Decay remains observation only.
- **No hard prevention of raw Codex edits to `MEMORY.md`.** Without Codex PreToolUse hooks, v1 can document and verify convergence, but cannot block every bad edit path.
- **No broad `.claude/` namespace migration outside the memory bucket.** If the debate chooses a neutral memory path or alias, that decision is scoped to project memory only.

## Open questions

- [ ] **OQ-1 — Keep `.claude/memory/` as the canonical path, or introduce a neutral memory namespace?** Owner: debate + user. Lean: keep `.claude/memory/` in v1 because existing specs, rules, tools, sync-harness exclusions, and entrypoint text already converge there; optionally document that the path is historical, not Claude-only. Pushback wanted if runtime-neutrality requires `.agent0/memory/` or a compatibility alias analogous to `.agent0/HANDOFF.md`.

- [ ] **OQ-2 — Should Codex edits append `.claude/.memory-events.jsonl` events?** Owner: debate + implementer. Lean: do not require manual journaling in the first Codex convention unless the plan can provide one low-friction post-edit command that both regenerates the index and appends a Codex-attributed event. Audit completeness is valuable, but a fussy manual JSONL step may be skipped more often than followed.

- [ ] **OQ-3 — What is the smallest ergonomic command surface Codex should run after memory edits?** Owner: implementer after debate. Options include: (a) keep separate commands (`memory-project.sh`, validation command, optional journal command), (b) add a single `memory-maintain.sh <entry>` wrapper for validate + project + optional journal, or (c) refactor the existing hooks to call shared helpers while Codex invokes those helpers directly.

- [ ] **OQ-4 — Should the `memory` capability matrix cell for Codex remain `convention` or move to `native-opt-in`?** Owner: debate + maintainer. Lean: keep `convention`; shell-invocable tools are not a Codex-native lifecycle primitive, and the runtime-capabilities vocabulary should not overstate support.

- [ ] **OQ-5 — When should Codex run decay readout?** Owner: debate + implementer. Candidate default: at the start of memory-relevant or non-trivial work, not every trivial Q&A turn. Claude Code remains always-fire because its SessionStart hook can surface the empty case cheaply.

## Context / references

- `.claude/rules/runtime-capabilities.md` — current matrix: `memory` is `native` for Claude Code and `convention` for Codex CLI; lifecycle hooks are `unsupported` for Codex.
- `.claude/rules/memory-placement.md` — canonical three-bucket model, frontmatter schema, event journal, index projection, cap/query/decay, and current gotchas.
- `.claude/rules/session-handoff.md` and `docs/specs/092-multi-runtime-handoff/` — precedent for one runtime-neutral artifact with Claude hooks and Codex convention as asymmetric mechanisms.
- `docs/specs/019-project-memory/` — introduced the project-memory bucket and lazy-read index.
- `docs/specs/082-memory-frontmatter-schema/` — frontmatter schema and Claude Code advisory validator.
- `docs/specs/083-memory-events-journal/` — event journal, raw-index gate, and derived-index projection.
- `docs/specs/086-memory-cap-query-decay/` — `memory-query.sh`, confirm semantics, decay readout, and the known `confirm` journaling gap.
- `.claude/tools/memory-project.sh` — deterministic index projection and cap advisory.
- `.claude/tools/memory-query.sh` / `.claude/tools/memory-query-helper.py` — runtime-agnostic query, confirm, and decay command surface.
- `.claude/hooks/memory-events-journal.sh`, `.claude/hooks/memory-index-gate.sh`, `.claude/hooks/memory-frontmatter-validate.sh`, `.claude/hooks/memory-decay-readout.sh` — Claude Code-native automation that Codex cannot receive automatically in v1.
- `AGENTS.md` — Codex entrypoint to expand with the memory convention.
- `CLAUDE.md` — Claude Code entrypoint; current memory discovery precedent.
