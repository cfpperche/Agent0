# 131 — harness-entrypoint-sync — debate

_Created 2026-05-31._

**Initiating agent:** Claude Code
**Reviewing agent:** Codex CLI
**Initiated by:** Claude Code session 2026-05-31

> **Conduct note.** This debate was run within a single Claude Code session via the `codex-exec`
> bridge (`.agent0/skills/codex-exec`), not the live two-session alternating protocol the
> `/sdd debate` template assumes. Each Codex round ran on **`gpt-5.5` at reasoning effort `xhigh`**
> (rounds 2–3; round 1 ran on the Codex default model). Raw transcripts are under the gitignored
> `.agent0/.runtime-state/codex-exec/*claude-agents-sync-gap*`; the substance is captured below.
> The exercise also surfaced and fixed a real bug — neither bridge helper could set reasoning
> effort — shipped as `feat(exec-bridges): --reasoning-effort passthrough` (`d016b8e`).

---

## Round 1 — initiating agent (position)

**Intent.** Codex reads `AGENTS.md`, never `CLAUDE.md` (premise verified against the agents.md
standard). Two sub-gaps: **A** — the `AGENT0:BEGIN…END` index is physically duplicated in both
entrypoints, maintained by two sync paths (drift risk); **B** — consumer project narrative
(Overview/Stack/Conventions/Gotchas, brand/voice) lives only in `CLAUDE.md` → invisible to Codex;
`AGENTS.override.md`/nested `AGENTS.md` → invisible to Claude.

**Option space.**
- **A.** Move project narrative to a runtime-neutral file delivered by the EXISTING context-injection
  hook; entrypoints become thin pointers.
- **B.** One canonical source RENDERED into both entrypoints by a sync build step.
- **C.** A second managed block (`AGENT0:PROJECT`) authored once and mirrored into both files.
- **D.** Symlink `AGENTS.md` ↔ `CLAUDE.md`. (Rejected — kills runtime framing + override chain + Windows.)

**Lean.** Reuse the proven injection rail (A) since Agent0 already chose hook-injection as its
multi-runtime context mechanism, possibly collapsing Gap A by generating the AGENTS.md index from
one source.

**Where pushback is wanted:** is per-prompt hook injection as reliable as always-on `AGENTS.md`
content for content that must shape every turn? And Codex's own instruction-discovery chain.

---

## Round 1 — reviewing agent (critique)

Confirmed from the Codex side: loads `AGENTS.md` only (+ startup brief; the per-prompt
`AGENT0_CONTEXT_INJECTION` arrived this run), never `CLAUDE.md`. Chain: global → root `AGENTS.md`
→ nested/override → explicit prompt.

**Option A is useful but not as reliable as always-on `AGENTS.md`.** Failure modes: hook
not trusted/registered; `codex exec`/non-interactive may not surface hooks like the TUI; cold first
turn only gets the startup summary; the 6000-byte / 5-fragment budget + keyword-miss; hook output is
advisory, ordered below explicit prompts/overrides.

**Ranking:** **A+** (neutral sources for *both* narrative and index, entrypoints reduced to thin
bootstrap pointers, hooks inject summaries) > **B** (generated entrypoints; reliable but heavier) >
**C** (mirrored block; symmetric but more marker complexity) > **D** (reject).

**Recommendation: A+.** Risks: hook selection can hide neutral context; a consumer-owned
`project.md` needs seed-only or structured sync semantics to avoid permanent `!! customized`.

---

## Round 2 — initiating agent (counter)

- **Accept** the single-source instinct for Gap A — no defense for the duplicated index.
- **Reject** routing *everything* through the hook (A+). The "doesn't fire in exec" worry is weak
  (it DID fire this run); the real weakness is that the rail is **relevance-gated + byte-bounded +
  advisory-ordered**. Great for a large on-demand rule library; wrong for a small always-needed core
  (identity/voice/conventions) that must shape every turn.
- **Counter-proposal — hybrid by need:** always-on core (+ index) → authored once and **mirrored
  into both entrypoints** as an always-on managed block (C), reusing the existing marker-aware 3-way
  reconciliation; long-tail reference → `docs/` + hook on demand (A). This also kills the round-1
  risk #2 for free — the managed-block merge already does 3-way reconciliation without seed-only
  semantics.

---

## Round 2 — reviewing agent (critique)

- **Concede** the narrow reliability point: a small always-needed core should not ride only through
  `context-inject.sh` (keyword-selected, 5-frag/6000-byte cap, emits pointers not bodies). The
  "fires in exec" evidence weakens the firing worry but not relevance-gating/budget loss.
- A second marker-delimited block in `AGENTS.md` does **not** break instruction precedence. The real
  complication is **ownership, not precedence**: `AGENTS.md` is plain baseline-tracked *deliberately*
  because Codex has override surfaces. Adding managed-block semantics creates a **second ownership
  model in the same file**, and must define what happens when consumer override text conflicts with
  the mirrored core.
- 3-way merge removes the permanent `!! customized` problem **only after a baseline exists** — still
  bites on first migration, missing baseline, marker mismatch/nesting, or consumers who already
  edited the block. And the deeper point: **if the core is consumer-authored, making it Agent0-owned
  is the wrong boundary.**
- **Verdict: hybrid, but narrower** — mirror the *tiny* always-on core + a *compact index pointer*
  into both entrypoints; long-tail in docs/hook. Top spec risk: define the canonical source + merge
  boundary so `CLAUDE.md`, `AGENTS.md`, `AGENTS.override.md`, and nested `AGENTS.md` don't become
  **four competing authorities**.

---

## Round 3 — initiating agent (counter)

- **Accept** the ownership correction — it fixes a category error in my round-2 proposal. Project
  narrative is **consumer-authored**, but the existing managed block is **Agent0-owned** (sync
  overwrites it). You cannot model the consumer's brand voice as an Agent0-owned mirrored block.
- **Reframe the concrete question for resolution:** two things must reach both runtimes with
  *different* ownership — the **INDEX** (Agent0-owned, low controversy) and the **PROJECT CORE**
  (consumer-owned, always-on). For the consumer-owned core, which canonical authoring + propagation
  design, and what exact merge rule? Candidates: (1) neutral source → sync mirrors into a `PROJECT`
  region of both entrypoints; (2) author in `CLAUDE.md`, mirror into `AGENTS.md`; (3) generated
  entrypoints. And where does `AGENTS.override.md` sit relative to the mirrored core?

---

## Round 3 — reviewing agent (critique)

1. **Design 1**, with the neutral source **outside Agent0 manifest scope** (`.agent0/project-core.md`,
   NOT `.agent0/context/project-core.md` — that path is in `COPY_CHECK_RECURSIVE`). Reason: ownership
   stays aligned — consumer authors once; both entrypoints carry *derived* copies; neither is privileged.
2. **Authority order:** the neutral file is canonical; `CLAUDE.md#PROJECT` and `AGENTS.md#PROJECT` are
   rendered mirrors. For Codex: root `AGENTS.md` loads the mirrored core, then `AGENTS.override.md` /
   nested `AGENTS.md` **win on conflict** by normal layering. Intended: core always present, scoped
   local overrides remain the intentional authority.
3. **Merge rule — a new, sound category: "consumer-source mirror"** (not Agent0-managed block). On
   sync, render the consumer source verbatim into the paired `PROJECT` regions. Target missing → create.
   Target == source → leave. Target == last recorded rendered hash AND source changed → overwrite
   (stale). Target differs from BOTH source and last rendered hash → **refuse** (someone edited a
   derived region); `--force` discards + re-renders. **Sync never overwrites the neutral source.**
4. **Acceptance test:** a fixture with one sentinel sentence only in the neutral source syncs that
   sentence into both `CLAUDE.md` and `AGENTS.md`, and a simulated Claude/Codex startup read sees the
   same sentinel before any on-demand context hook runs.

---

## Synthesis

**Resolution:** converged

**Converged design.** Two layers, two ownerships, both reaching both runtimes:
- **Harness INDEX** (Agent0-owned) → one canonical source, rendered/pointer into both entrypoints (closes Gap A — no drift).
- **PROJECT CORE** (consumer-owned) → authored once in a neutral source *outside* the manifest (`.agent0/project-core.md` candidate), mirrored always-on into a `PROJECT` region of both entrypoints via the new **consumer-source mirror** merge rule (closes Gap B).
- **Long-tail reference** → stays in `docs/`, delivered on demand by the existing context-injection hook.
- **Authority:** neutral source canonical; entrypoint regions are derived mirrors; `AGENTS.override.md` / nested `AGENTS.md` win on conflict.
- **Mechanism reuse:** per-region rendered hashes recorded in `harness-sync-baseline.json` under synthetic keys (`CLAUDE.md#PROJECT`, `AGENTS.md#PROJECT`) — same pattern as the existing `CLAUDE.md#managed-block`.

**Proposed spec changes:** (already written into `spec.md` at scaffold — this debate *produced* the spec)

- § Intent — gap A/B framing + the always-on-mirror-vs-hook split
- § Acceptance criteria — sentinel test, single-sourced index, consumer-source-mirror refuse/stale rules, Codex-override-wins, manifest-exclusion + synthetic-key facts
- § Non-goals — hook-for-core, symlink, AGENTS-derived-from-CLAUDE, override-chain changes, auto-migration
- § Open questions — index mechanism, source name/location, marker naming, migration path, core/tail boundary

**Unresolved disagreements:** none of substance. Remaining choices are deferred to `/sdd plan` as the open questions above (index single-sourcing mechanism; exact source path; marker scheme), not disagreements.

---

## Applied changes

- `spec.md` — authored in full from this debate's converged design (Intent, Acceptance criteria, Non-goals, Open questions, Context / references). The spec did not pre-exist the debate; the debate is its origin record.
