# 054 — In-flight notes

## Design decisions

### 2026-05-19 — parent — OQ-1 resolution: ask-at-Phase-0.5 with heuristic-proposed default

**Decided:** language is resolved at a NEW Phase 0.5 step (between Init and Phase 1 Discovery). Orchestrator runs a heuristic against the idea string (Portuguese cues: `R$`, `LGPD`, diacritics; Spanish cues: `€`, `IVA`, `ñ`; else `en`), proposes the result as the (Recommended) option in an `AskUserQuestion`, founder confirms or overrides. Stored in `.state.json.target_language`. Threaded as `{{target_language}}` substitution into every brief that produces user-facing text.

**Why ask-at-Phase-0.5 (not later):** language affects every artifact from Step 01 onward (concept-brief, PRD, OST, brand-book, screen copy). Asking at gate_discovery (Phase 1 close) means Phase 1 artifacts already written in default-heuristic language — if founder picks a different language, Phase 1 has to re-iterate. Asking at Phase 0.5 (before Step 01) avoids the re-iterate cost entirely.

**Why ask (not inferred-with-flag):** the original spec recommendation was "inferred + `--locale` flag override". On critique: the flag is dead weight (founder won't remember to pass it on the initial invocation), and silent heuristic-mis-language is the exact Vetro failure mode (anglicisms shipped because nobody asked). The Phase 0.5 question is one extra prompt up front; cheap insurance against the silent-mis-language regression.

### 2026-05-19 — parent — OQ-2 resolution: 4-column table format

**Decided:** `| Term | Replacement | Reason | Applies to |`. The 4th column (`Applies to`) lets downstream sub-agents scope entries to specific surfaces (e.g. `applies_to: marketing, pricing` excludes the entry from `/settings/integrations` where English `API` is correct).

**Why table (not bullets):** machine-readable for downstream Step 15 screen-writer's string-replace lookup. Bullets work for human review but require parsing-by-eye on the writer side; table is canonical.

**Why 20-entry cap:** beyond 20 entries, downstream sub-agents ignore the budget (cognitive load + token budget). Less is more — focus on terms the voice positioning actually trips on.

### 2026-05-19 — parent — OQ-3 resolution: NO auto-seed from positioning Unlike-clause

**Decided:** sub-agent identifies Glossary entries ORGANICALLY from concept-brief + positioning + product domain. Does NOT mechanically derive from positioning Unlike-clause.

**Why not auto-seed:** positioning Unlike-clause (April Dunford methodology) operates at product-vs-product level — "we're not enterprise sales-cycle vendors". Glossary operates at copy-trap level — "Most Popular → Mais escolhido". The translation between the two is not mechanical. Auto-seed would produce pseudo-derived entries that LOOK related but aren't load-bearing — pure noise.

The sub-agent's job is to read positioning + concept-brief + voice posture and identify *domain-specific* traps that real downstream sub-agents would otherwise drift on. That's a judgment call, not a derivation.

### 2026-05-19 — parent — Glossary timing constraint: Step 13 emits, only Step 15 consumes

Phase 1 + 2 sub-agents (Steps 02, 05, 12) listed in the spec problem statement as "downstream consumers" actually run BEFORE Step 13. They CANNOT read brand-book Glossary — it doesn't exist yet.

The spec's voice-drift problem in those steps is solved instead by **`{{target_language}}` substitution** (Phase 0.5 → every brief). Glossary specifically fixes Step 15 screen-writer drift (the most visible UI artifact + the only sub-agent that runs after Step 13).

This is a deviation from the spec's original framing but preserves the spec's intent — voice fidelity downstream. Spec.md's enumeration of `Step 02 / 05 / 12 / 15` was descriptive of where drift was observed, not prescriptive of where Glossary must be consumed.

## Deviations

### 2026-05-19 — parent — Phase 0.5 added as new orchestrator phase

The original SKILL.md flow had 4 phases (Discovery / Specification / Identity / Visual-contract) + a Phase 0 setup. Spec 054 adds **Phase 0.5 — Target language resolution** as a new pre-Phase-1 step.

**Why Phase 0.5 (not folding into Phase 0 or Phase 1):** Phase 0 is mechanical (mkdir + .state.json init); adding `AskUserQuestion` there feels out of place. Phase 1 starts with Step 01 dispatch, which needs `target_language` already resolved. The half-phase numbering (0.5) signals it's a "between-init-and-dispatch" interlude — not a major phase with its own gate.

### 2026-05-19 — parent — Phase 4.5 simplified to read state instead of re-running heuristic

Pre-054, SKILL.md Phase 4.5 had its own heuristic for `lang="<bcp47>"` substitution in `app/layout.tsx`. With Phase 0.5 resolving language canonically + storing it in state, Phase 4.5 now just reads `.state.json.target_language`. The duplicate heuristic is gone.

## Tradeoffs

- **Extra `AskUserQuestion` at Phase 0.5 adds friction.** Founders have to answer one more question before Step 01 runs. Trade: silent language drift cost is real (Vetro shipped anglicisms because nobody asked); one explicit question prevents the failure mode. The question is fast (4 options max, default proposed) and runs once per fresh project.
- **`{{target_language}}` substitution in 6+ briefs (Step 01, 02, 03, 05, 12, 13).** Each brief grows by ~1-2 lines. Trade: alternative is sub-agents reading `.state.json.target_language` themselves (more sub-agent code paths). Brief substitution is simpler + more visible.
- **Glossary consumed only by Step 15 (despite spec listing more consumers).** Pragmatic — Phase 1-2 sub-agents predate Step 13. Trade: `{{target_language}}` substitution covers the broader language-drift problem in those phases; Glossary handles the term-replacement drift specifically in user-facing UI copy.
- **Schema enforces Glossary presence (`min_size` bumped, contains-checks added).** Trade: a brand-book without Glossary fails Layer 1. This is the discipline — if Glossary is optional, sub-agents skip it. Enforcement at submit makes the requirement visible.

## Open questions

None remaining at ship — OQ-1/2/3 resolved.

Forward-looking:

- **Does Step 15 actually read Glossary correctly?** The constraint is mechanical (`grep -L "<term>" page.tsx`); failure mode is sub-agent skips the grep self-check. Watch the next /product dogfood for compliance.
- **Is the heuristic right?** Phase 0.5 heuristic covers pt-BR, es-ES, en clearly. Watch for failures with other languages (fr-FR, de-DE, zh-CN, etc) — they fall through to `en` proposal currently, and founders must override via "Other" option.
- **Does Glossary cap (≤ 20) hold?** A complex product domain may want more entries. If next dogfood produces a brand-book with 18-20 entries that feel cramped, raise to 30. If at 10-15 entries the discipline holds, cap is right.
- **Should Step 14 design-system also read Glossary?** Currently the design-system step doesn't generate user-facing copy (just tokens + components.md), so no direct consumer. If components.md grows usage examples with copy strings, it should respect Glossary too. Add later if needed.
