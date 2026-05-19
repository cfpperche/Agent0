# 054 — brand-book glossary

**Status:** draft

## Problem

Step 13 brand-book produces voice posture (we are / we are not, voice samples) as free-form prose. Downstream consumers — Step 02 lo-fi mood writer, Step 05 PRD, Step 12 GTM, Step 15 screen-writer — re-derive voice ad-hoc from the prose, producing voice drift:

- Dogfood-2 (Vetro): brand-book declares "warm-confident pt-BR" voice. Landing copy ships `Sem upstream-conflito com a sua margem` (engineering jargon) and `retail bundled` (anglicism). Pricing badge ships untranslated `Most Popular` in a pt-BR product. Three independent downstream sub-agents made three independent voice-drift errors.

The brand-book has the answer ("we don't sound like enterprise sales-cycle vendors"); downstream sub-agents can't grep for it. There is no machine-readable surface that says `Most Popular → Mais escolhido` or `upstream-conflito → conflito de interesse`.

## Acceptance criteria

- [ ] **Scenario: brand-book exports machine-readable Glossary**
  - **Given** Step 13 brand-book is dispatched
  - **When** the sub-agent returns `brand-book.md`
  - **Then** a `## Glossary` H2 exists with two sub-sections — `### We say` (preferred terms) and `### We don't say` (avoided terms with native replacement)
- [ ] **Scenario: target language is declared explicitly**
  - **Given** a project with concept-brief containing `R$` / `LGPD` / `NFS-e` / `Pix`
  - **When** brand-book is dispatched
  - **Then** brand-book ships a `## Language` H2 declaring `target_language: pt-BR` (or detected language)
- [ ] **Scenario: downstream sub-agents read and respect the Glossary**
  - **Given** brand-book declares `Most Popular | Mais escolhido` in `### We don't say`
  - **When** Step 15 screen-writer dispatched for `/precos`
  - **Then** rendered badge uses `Mais escolhido`, not `Most Popular`

## Non-goals

- Auto-enforcement of glossary by validator or post-write QA (post-write QA was rejected this session)
- Multi-language glossaries (target language is singular per project)
- Glossary auto-derivation from positioning Unlike-clause (left as open question)

## Open questions

1. Language detection: declared by founder upfront (flag `--locale`), inferred by orchestrator (regex on concept-brief for currency/regulation cues — heuristic already exists in SKILL.md § Phase 4.5 stitch step), or asked at the discovery gate?
2. Glossary format: bullet list (simpler) vs table (`term | replacement | reason` triplet — better for reviewer)?
3. Should the orchestrator pre-seed the Glossary from the positioning Unlike-clause (Step 12) before Step 13 dispatches?
