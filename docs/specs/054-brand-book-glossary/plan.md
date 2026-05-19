# 054 — Plan

## Approach

Make the Glossary a structural requirement of Step 13's deliverable. Downstream consumer briefs (Steps 02, 05, 12, 15) gain a CONTEXT line "read brand-book.md § Glossary" + a CONSTRAINT line "if a term in § We don't say appears, replace with the § We say equivalent". Language detection heuristic already lives in `SKILL.md § Phase 4.5 stitch step`; extract it to run earlier so Step 13 receives `target_language` as input.

## Files to touch

- `.claude/skills/product/templates/pipeline/13-brand/prompt.md` — add Glossary + Language section requirements.
- `.claude/skills/product/templates/pipeline/13-brand/schema.md` — define Glossary structure (bullet or table — see open question #2).
- `.claude/skills/product/references/delegation-briefs.md` — Step 13 brief gains Glossary obligation; Steps 02 / 05 / 12 / 15 briefs gain `read brand-book.md § Glossary` line.
- `.claude/skills/product/SKILL.md` § Phase 3 — Step 13 dispatch gets `target_language` substitution from concept-brief heuristic.
- `.claude/skills/product/SKILL.md` § Phase 4.5 — keep the lang substitution as-is (still does last-mile pt-BR vs en for layout.tsx); no double-trigger.

## Alternatives considered

- **Glossary as separate file `docs/glossary.md`.** Rejected — fragments the brand-book; downstream consumers would need two refs.
- **Glossary as YAML frontmatter on brand-book.md.** Viable but harder for human review; H2 section is simpler for both human and grep.
- **Skip glossary; rely on sub-agent reading brand-book prose more carefully.** Rejected — three independent sub-agents drifted in dogfood-2 despite the prose being clear. Machine-readable surface is the fix.

## Risks

- **Glossary inflation.** If Step 13 emits 50 terms, downstream sub-agents ignore the budget. Cap at ~20 entries in the schema.
- **False positives downstream.** Legitimate English in code-flavored surfaces (e.g. "API" in `/settings/integrations`) shouldn't trip the constraint. Surface-aware exemption: glossary entries can declare `applies_to: [marketing, auth]` to scope.
- **Language detection mis-fire.** A pt-BR product whose concept-brief happens to skip currency/regulation cues defaults to `en`. Mitigation: explicit `--locale` flag overrides detection.
