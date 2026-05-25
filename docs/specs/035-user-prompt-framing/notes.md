# 035 — user-prompt-framing — notes

_In-flight design memory. Decisions, deviations, tradeoffs, open questions surfaced while building. Append-only._

## Design decisions

_(none)_

## Deviations

_(none)_

## Tradeoffs

_(none)_

## Open questions

### 2026-05-25 — parent — dogfood window Phase 1 scan: 1/3 missed at 8/21 days

Empirical scan of `~/.claude/projects/-home-goat-Agent0/*.jsonl` over 2026-05-17 → 2026-05-25 (8 of 21 days).

**Universe:** 59 transcripts → 27 top-level user-facing sessions (after stripping sub-agent transcripts, identified via the absence of session-level chat history shape — initial filter on `agent-name` was wrong; agent-name is a custom session title, not a sub-agent marker; final filter relied on first-user-prompt shape + transcript size).

**Method:** extracted the first non-system user message of each session; classified against the rule's threshold table (skip / exploratory / substantive). For substantive prompts with ≥2 ambiguities, checked whether the assistant's first action was `AskUserQuestion` (discipline applied) or a direct work tool (discipline missed).

**Findings:**

- **1 confirmed missed-clarification:** session `81ff0eb9` (named "product"), 2026-05-22, first prompt `report` — single word, no antecedent, 3 ambiguities (TASK/CONTEXT/DONE). Assistant's first action was `ls docs/specs/073-product-report-html/` — inferred topic without asking. User's 2nd message added scope ("quero discutir sobre o REPORT.html que desenvolvemos, o report do mei-saas parece estar faltando artefatos…") — the clarification the rule would have prompted up-front. Counts as 1 against the `≥3` threshold.
- **1 borderline-but-cleared:** session `497fe72e` (named "dores"), 2026-05-17, "quero encher meu github de repositorios publicos e uteis…". Half-exploratory shape — covered by the exploratory carve-out (recommendation, not framing). Assistant did eventually ask `Nome do repositório?` later in the flow.
- **2 N/A:** `646c1f6d` "refatora isso pra ficar mais limpo" — session abandoned (1 user turn, zero assistant); `a660ec97` "onde estao os artefatos? suba o devserver…" — pronoun "os artefatos" had implicit antecedent via SESSION.md context (the /product dogfood flow was active across recent sessions).

**Score at 8/21 days:** 1 missed-clarification confirmed against threshold `≥3`. Discipline is holding.

**Pattern observed:** the single miss fits the exact edge case spec.md § Open Q3 anticipated — *first-message-of-session + single-word + no-antecedent*. If 2 more misses of the same shape accumulate before 2026-06-07, that's a sharply-scoped follow-up spec ("first-msg ambiguity hook") rather than a broad `UserPromptSubmit` for the whole rule.

**Caveats:**

- Scan covered first prompts only. Mid-session prompts (≈170+ turns in `81ff0eb9` alone) not audited. If Phase 2 needs higher statistical confidence, a full sweep is 1-2h of mechanical work.
- "Missed" is subjective for `81ff0eb9` — someone could argue the SESSION.md context made the inference reasonable. The rule's strict reading ("2+ ambiguities → ask") is what counts the miss; the founder gets tiebreaker in Phase 2.

**Decision path:**

- If Fase 2 (founder review) surfaces 0-1 additional misses by 2026-06-07 → bump spec 035 status to `shipped`, dismiss reminder `r-2026-05-17-revisar-spec-035-dogfood`.
- If Fase 2 surfaces ≥2 additional misses → scaffold follow-up spec (next available number after 087, so 088+) for the `UserPromptSubmit` hook. Scope based on the shape of the misses (e.g., if all are first-msg-ambiguity, scope narrowly there).

**Resume point:** Phase 2 — founder reviews whether any session-level misses were experienced subjectively that the first-prompt scan didn't catch. Then Phase 3 — decision at 2026-06-07 or earlier if threshold tripped.
