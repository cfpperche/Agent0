# 054 — Tasks

1. [ ] Resolve open question #1 (language detection: declared / inferred / asked) — recommend inferred-with-flag-override.
2. [ ] Resolve open question #2 (bullet vs table) — recommend table.
3. [ ] Resolve open question #3 (auto-seed from positioning Unlike-clause) — recommend yes, sub-agent pre-fills `### We don't say` from positioning anti-patterns.
4. [ ] Edit `templates/pipeline/13-brand/prompt.md`: require `## Language` + `## Glossary` (with `### We say` + `### We don't say` sub-sections).
5. [ ] Edit `templates/pipeline/13-brand/schema.md`: define Glossary table shape (`| term | replacement | reason | applies_to |`).
6. [ ] Extract Phase 4.5 language detection regex into a SKILL.md helper section called before Step 13 dispatch; substitute `{{target_language}}` into Step 13 brief.
7. [ ] Edit `delegation-briefs.md`: Step 13 brief gains Glossary obligation; Steps 02 / 05 / 12 / 15 briefs gain Glossary-read CONTEXT + Glossary-respect CONSTRAINT.
8. [ ] Verify with a dry-run on a pt-BR brand-book — confirm at least one Step 15 screen-writer produces glossary-conformant copy.
9. [ ] Commit: `feat(054): brand-book Glossary + Language — voice fidelity across downstream sub-agents`.
