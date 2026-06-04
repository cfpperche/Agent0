# 147 — image-manifest-gitignore — notes

_Created 2026-06-04._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.agent0/context/rules/spec-driven.md` § The four artifacts for purpose, and `.agent0/context/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) of the delegated worker.

## Design decisions

### 2026-06-04 — parent — Treat image manifest as local audit state

The founder clarified that `assets/generated/.manifest.jsonl` should be gitignored in both Agent0 and consumers. This intentionally reverses the previous live rule text that called it git-tracked. Brand assets remain tracked; only the call ledger becomes local state.

## Deviations

## Tradeoffs

## Open questions
