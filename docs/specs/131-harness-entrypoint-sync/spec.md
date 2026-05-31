# 131 — harness-entrypoint-sync

_Created 2026-05-31._

**Status:** draft

## Intent

Claude Code reads `CLAUDE.md`; Codex (and the ~20 other AGENTS.md-standard tools) reads `AGENTS.md` and never `CLAUDE.md`. Today the Agent0 harness keeps two parallel realities across those entrypoints. **Gap A — duplicated index:** the shared capacity index lives physically inside the `<!-- AGENT0:BEGIN -->…END` block of *both* files (byte-identical now, but maintained by two different sync paths — drift is a matter of time). **Gap B — orphaned project narrative:** consumer project context (Overview / Stack / Conventions / Gotchas, and project-specific sections like a brand/voice block) lives only in `CLAUDE.md`'s narrative region, so it is invisible to Codex; symmetrically `AGENTS.override.md` / nested `AGENTS.md` is invisible to Claude. A consumer hit this immediately — the `cognixse` project's `Brand & voice` section, authored in `CLAUDE.md`, would never reach a Codex session. This spec closes the gap so both runtimes — in Agent0 itself and in every consumer synced by `sync-harness.sh` — see the same harness index and the same always-on project core, without breaking Codex's native override chain. The design is the converged output of a 3-round Claude × Codex (gpt-5.5/xhigh) debate (see `debate.md`): an **always-on mirror** for the small core that must shape every turn, and the **existing relevance-gated context-injection hook** for the long-tail reference.

## Acceptance criteria

- [ ] **Scenario: project core reaches both runtimes (sentinel test)**
  - **Given** a single sentinel sentence authored only in the neutral, consumer-owned project-core source
  - **When** `sync-harness.sh --apply` runs
  - **Then** the sentence appears verbatim inside an always-on `PROJECT` region of BOTH `CLAUDE.md` and `AGENTS.md`, and a simulated Claude and Codex startup read both see it *before* any on-demand context-injection hook fires

- [ ] **Scenario: shared index is single-sourced (Gap A)**
  - **Given** the harness capacity index has one canonical source
  - **When** `sync-harness.sh --apply` renders the entrypoints
  - **Then** the index region in `CLAUDE.md` and `AGENTS.md` is byte-derived from that one source, so the two copies cannot drift

- [ ] **Scenario: consumer edit to a derived region is refused (consumer-source mirror merge)**
  - **Given** a consumer hand-edits the rendered `PROJECT` region inside `AGENTS.md` (a derived mirror), diverging from both the neutral source and the last recorded rendered hash
  - **When** `sync-harness.sh --apply` runs without `--force`
  - **Then** sync refuses that region (reports it), leaves it untouched, and never overwrites the neutral source; `--force` discards the derived edit and re-renders from source

- [ ] **Scenario: stale derived region auto-updates**
  - **Given** the neutral source changed and the consumer never touched the rendered region (region sha == last recorded rendered hash)
  - **When** `sync-harness.sh --apply` runs
  - **Then** the region is re-rendered from source with no `--force`, counted as a stale update

- [ ] **Scenario: Codex local override still wins**
  - **Given** an `AGENTS.override.md` or nested `AGENTS.md` whose guidance conflicts with the mirrored project core
  - **When** Codex loads its instruction chain
  - **Then** the override wins on conflict (native layering preserved); the mirrored core only guarantees the baseline is always present

- [ ] The neutral, consumer-owned project-core source lives OUTSIDE the `COPY_CHECK_*` manifest scope, so `sync-harness.sh` never treats it as Agent0-owned and never overwrites it
- [ ] The per-region rendered hash is recorded in `.agent0/harness-sync-baseline.json` under synthetic keys (e.g. `CLAUDE.md#PROJECT`, `AGENTS.md#PROJECT`), reusing the existing `CLAUDE.md#managed-block` baseline pattern
- [ ] Long-tail reference (full brand book, detailed conventions) is NOT mirrored into entrypoints; it stays in `docs/` and is delivered on demand by the existing context-injection hook

## Non-goals

- Routing the always-on project core through the relevance-gated context-injection hook (rejected in debate: bounded to 6000 bytes / 5 fragments, keyword-selected, advisory-ordered — wrong mechanism for always-needed framing; the hook stays for the long-tail).
- Symlinking `AGENTS.md` ↔ `CLAUDE.md` (rejected: forces identical bytes, kills runtime-specific framing + the Codex override chain, symlink-hostile on Windows checkouts).
- Making `AGENTS.md` a derived artifact of `CLAUDE.md` (Design 2, rejected: neither entrypoint is privileged; both derive from the neutral source).
- Changing how `AGENTS.override.md` / nested `AGENTS.md` layer — their precedence is preserved; override wins on conflict.
- Auto-migrating existing consumers' `CLAUDE.md`-only narrative into the new neutral source — hard-cutover posture (consumer does a one-time manual move), same as specs 101/102-105/130.

## Open questions

- [ ] **Index single-sourcing mechanism** — render the index region from one canonical source into both files, vs keep `CLAUDE.md`'s existing `AGENT0:BEGIN/END` managed block as the source and mirror it into `AGENTS.md`. (Owner: maintainer at `/sdd plan`.)
- [ ] **Neutral source name/location** — `.agent0/project-core.md` is the candidate (must be outside `COPY_CHECK_*`; note `.agent0/context/` IS in `COPY_CHECK_RECURSIVE`, so the source must not live under `context/`). Confirm filename + whether Agent0 ships a template stub for fresh consumers.
- [ ] **Region marker naming + coexistence** — `AGENT0:PROJECT:BEGIN/END` vs another scheme, and how it sits alongside the existing `AGENT0:BEGIN/END` managed block in the same file (two ownership models, one file).
- [ ] **Migration path for existing consumers** — e.g. `cognixse` already has `Brand & voice` only in `CLAUDE.md`. Define the documented one-time move into the neutral source + first `--apply` that seeds the mirror.
- [ ] **Core/tail boundary** — what belongs in the always-on mirrored core vs the on-demand hook tail (size discipline; the core must stay small enough to justify always-on).

## Context / references

- `.agent0/context/rules/harness-sync.md` — managed-block merge, 3-way reconciliation, baseline synthetic keys (`CLAUDE.md#managed-block`), § Manifest scope, § "No upstream auto-migration of consumer content"
- `.agent0/context/rules/runtime-capabilities.md` — provider-neutral capability matrix (consult before asserting a runtime behavior)
- `CLAUDE.md` / `AGENTS.md` — the two entrypoints; `AGENTS.md` § "Codex Customization" (the override chain)
- `.agent0/hooks/context-inject.sh`, `.agent0/hooks/startup-brief.sh` — the existing runtime-neutral injection rail (the long-tail delivery)
- `agents.md` standard (https://agents.md) — confirms Codex reads `AGENTS.md`, not `CLAUDE.md` (verified 2026-05-31)
- `debate.md` (this spec) — the 3-round Claude × Codex (gpt-5.5/xhigh) debate that produced this design
- Migration precedent: specs 101 (SESSION.md removal), 102/103/104/105 (`.claude`→`.agent0` relocations), 130 (baseline relocate) — hard-cutover, no upstream auto-migration of consumer content
