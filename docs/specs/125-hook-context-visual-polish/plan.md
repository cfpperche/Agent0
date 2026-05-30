# 125 — hook-context-visual-polish — plan

_Drafted from `spec.md` on 2026-05-30. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

The feasibility check (see `notes.md`, 2026-05-30) ruled out spec options (a) preserve-newlines and (b) hide-from-human as infeasible — Claude Code exposes no field to control how `additionalContext` renders, and the display-only `displayContent` mechanism applies only to the `MessageDisplay` event, not `SessionStart` / `UserPromptSubmit`. That leaves option (c): restructure the emitted text so its structure survives the renderer collapsing newlines. We do this with a single additive inline marker — `▸` — introduced only on the sub-structure boundaries that currently flatten into indistinguishable lines, while leaving every test-pinned substring (`=== handoff ===`, `=== context ===`, `^source:`, `mode: prompt-capsules`, `capsule:`) untouched so the existing suites pass unchanged.

Concretely: in the startup brief the handoff block has three nesting levels (`=== section ===` → `- Heading:` → `  - content`); when newlines drop, the `- Heading:` sub-section labels (Current State / Active Work / Next Actions) become indistinguishable from `- content` bullets. Prefixing the sub-section headers with `▸` gives a three-tier inline vocabulary (`=== … ===` section / `▸` sub-section / `-` content) that is reconstructable on one physical line. In the per-turn capsule block, each capsule is already delimited by `---` (one per capsule, countable — scenario 2 is essentially already met); we add the same `▸` glyph to that separator so the boundary pops inline and the visual vocabulary is consistent across both emitters. Model-visible semantic content is unchanged; only marker glyphs are added.

## Files to touch

**Create:**
- `.agent0/tests/context-injection/12-flatten-safe-markers.sh` — asserts the new `▸` sub-section marker appears in the startup brief handoff block AND on the capsule separator, and that all spec-124 pinned substrings still co-exist (guards against regressing the additive contract).

**Modify:**
- `.agent0/hooks/startup-brief.sh` — `summarize_handoff_section()`: change the sub-section header line from `- $heading:` to `▸ $heading:`. Single line. Keeps `=== handoff ===` etc. (emitted elsewhere) intact.
- `.agent0/hooks/context-inject.sh` — `append_capsule()`: change the capsule separator from `\n---\n` to `\n▸ ---\n` (both the normal and the byte-cap-`omitted` branch), preserving the `---` substring and the `^source:`/`title:`/`capsule:` line-start prefixes.
- `docs/specs/125-hook-context-visual-polish/tasks.md` — filled by `/sdd tasks`.
- `docs/specs/125-hook-context-visual-polish/notes.md` — append implementation notes as they surface (already carries the feasibility finding).

**Delete:**
- _None._

## Alternatives considered

### Resolve to `abandoned` (documented kill, Ramo B)

Rejected because option (c) is a genuine, low-risk, propagatable improvement, not theater — the handoff nesting genuinely collapses under flattening and the marker reconstructs it. A kill would be the right call only if (c) also offered no real gain; it does. (Kept as a live fallback only if live dogfood shows the `▸` marker does not survive the renderer — see Risks.)

### Change the top-level `=== section ===` markers themselves

Rejected because `09-startup-brief-budget.sh` pins `=== handoff ===` / `=== context ===` verbatim, and scenario 3 requires the suite pass unchanged. Touching them forces a test edit, violating the additive contract. The `=== … ===` labels already survive flattening; they don't need changing.

### Use the CC `suppressOutput` / a model-only channel

Rejected on the feasibility finding: `suppressOutput` hides stdout (not `additionalContext`, which is our path), and no model-only channel exists for these two events. Documented in `notes.md` with verbatim doc quotes.

## Risks and unknowns

- **The `▸` glyph might itself flatten poorly or render as tofu in some terminals.** Mitigation: it is non-ASCII (U+25B8) but the repo already ships non-ASCII in hook output (`•`, `—`); the live CC dogfood (acceptance scenario 5) is the gate that confirms it actually pops in the flattened view. If it renders as a box, fall back to an ASCII marker (`>>`).
- **Codex consumption (scenario: Codex does not regress).** Codex receives raw stdout; `▸` is inert text there and nothing machine-parses the sub-section/separator lines (no test greps `- Current State` or `^---`). Confirmed low-risk; still gated by the Codex probe artifact.
- **Proportionality.** This is a deliberately small change; the value is legibility of an already-working readout, not a capability. Named openly so a reviewer doesn't expect a larger diff.
- **Unknown until dogfood:** whether the founder's flattened "hook context" block is the `additionalContext` system-reminder render (expected) or some other surface. The dogfood prompt is written to answer this empirically.

## Research / citations

- Claude Code hooks reference — `https://code.claude.com/docs/en/hooks` (verbatim `additionalContext`, `suppressOutput`, `displayContent`/`MessageDisplay` field quotes captured in `notes.md`, 2026-05-30). Satisfies `.agent0/context/rules/research-before-proposing.md` and `feedback_verify_runtime_capabilities`.
- `docs/specs/124-hook-context-noise-control/` — predecessor (volume fix; deferred this cosmetics follow-up).
- `.agent0/tests/context-injection/09-startup-brief-budget.sh`, `03/05/10-*.sh` — the pinned-string constraints driving the additive marker design.
