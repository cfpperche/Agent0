# 079 — product-stack-aware-handoff — tasks

_Generated from `plan.md` on 2026-05-23. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Pre-flight — verify no hidden consumers

- [ ] 1. Run `rg -F 'app-skeleton' .claude/ docs/specs/ --files-with-matches | grep -v '079-product-stack-aware-handoff'` and `rg -F 'stack-defaults' .claude/ docs/specs/ --files-with-matches | grep -v '079-product-stack-aware-handoff'`. Expected: only the files plan.md already lists (SKILL.md, sdd-handoff.md, delegation-briefs.md, REMINDERS.md, historical specs 048/066/068) and `templates/app-skeleton/` itself. ANY surprise hit (script under `tools/`, validator, hook) must be added to plan.md § Files to touch before continuing.

### Block A — `sdd-handoff.md` rewrite (the contract doc)

- [ ] 2. Edit `.claude/skills/product/references/sdd-handoff.md § What Phase 5 produces` — append a paragraph after the existing table: *"When `docs/system-design.md § Stack` declares non-trivial backend services or a monorepo, Phase 5 emits additional **infra children** between child #2 component-library and the per-phase visual children — one per `docs/roadmap.md` Fase 1 deliverable that has no owner among the per-phase visual children. Children #3..M are infra (block-precede); children #(M+1)..N are the per-phase visual children, renumbered accordingly."*
- [ ] 3. Edit `sdd-handoff.md § The umbrella spec § Child-spec matrix` — extend the example table after the existing rows to show the infra-children pattern (rows 3-6 for the mei-saas-shaped case: `monorepo-backbone`, `schema-rls`, `auth-foundation`, `brasilapi-integration`), then a final illustrative `7 | <roadmap phase 1 title> | Phase 1 | matrix-only` row. Add a note immediately under the table: *"Infra children are derived from `docs/roadmap.md § Phases § Fase 1 | Deliverable | Owner | Status |` rows that don't map to any per-phase visual child. Their slugs are short kebab-case names extracted from the deliverable prose (e.g. \"Monorepo Turborepo + Bun workspaces\" → `monorepo-backbone`). One infra child per unmatched deliverable; no granularity cap (the founder can dismiss-or-merge rows in the umbrella before starting per OQ#1 default)."*
- [ ] 4. Edit `sdd-handoff.md § Standing constraints` — rewrite the existing "Styling: Tailwind utility classes" bullet to be stack-conditional: *"**Styling.** The styling system is whatever `docs/system-design.md § Stack` declares. If Tailwind, then v4 with `@theme` from `docs/design-system/tokens.css` (Next: `app/globals.css` `@import`s tokens.css; Expo/NativeWind v4: translate to `tailwind.config.js theme.extend`). If styled-components / vanilla-extract / Panda CSS / etc., the foundation child's `/sdd plan` researches the canonical token-binding pattern for that system and cites sources. **No inline `style={{}}` for layout or positioning** regardless of styling system — inline style cannot carry a breakpoint."*
- [ ] 5. Edit `sdd-handoff.md § Child #1 — 002-foundation/spec.md`:
  - § Context — replace the existing bullet pointing at `app-skeleton/<stack>/` with: *"`docs/system-design.md § Stack` (the binding stack contract — read it BEFORE planning), `docs/sitemap.yaml`, `docs/design-system/tokens.css`, `docs/fixture-spec.md`. **The foundation child's `/sdd plan` runs web research per `.claude/rules/research-before-proposing.md`** to determine the current canonical setup (package manager, framework version pins, config files, dev scripts) for the declared stack; cites sources in `plan.md § Research / citations`. No Agent0-bundled template is consumed — none ships."*
  - § Acceptance — rewrite to be stack-neutral. Replace the `pnpm install && pnpm dev` literal with: *"dev server starts clean per the declared stack's canonical command (researched at `/sdd plan` time and recorded in `plan.md`)"*. Replace the typecheck/lint literals with: *"typecheck exits 0 (the typechecker the declared stack uses)"* and *"lint exits 0 (the linter the declared stack uses)"*. Replace the Next/Expo token-utility resolution criterion with: *"a token utility (`bg-primary` or the styling-system equivalent identified during research) resolves to the value in `docs/design-system/tokens.css`"*.
- [ ] 6. Add `sdd-handoff.md § Open questions migration` (new H2 between § Standing constraints and § Fallback): one paragraph stating *"Phase 5 copies every row from `docs/system-design.md § Trade-off Triggers → Open Decisions` into the umbrella `spec.md § Open questions`, prefixed `**Architecture — <topic>:**`, so undecided architectural choices surface before any child consumes them. The umbrella's existing OQs from `docs/screen-atlas.md § Open Decisions` remain (integration-shape decisions); the two sources interleave by topic. No de-duplication — if the same decision appears in both, leave both rows so the build sees both surfaces."*
- [ ] 7. Verify the rewrite is internally consistent: `grep -n 'app-skeleton' .claude/skills/product/references/sdd-handoff.md` returns nothing (every former reference replaced). Commit as `feat(079): rewrite sdd-handoff.md for stack-aware Phase 5`.

### Block B — `SKILL.md § Phase 5` orchestration

- [ ] 8. Edit `.claude/skills/product/SKILL.md` Phase 5 Step 1 — replace the existing "Scaffold the umbrella spec" instruction with the expanded version: read `docs/system-design.md` (especially § Stack, § Services, § Trade-off Triggers/Open Decisions) + `docs/roadmap.md` Fase 1 `| Deliverable | Owner | Status |` rows; emit infra children for Fase 1 deliverables that don't map to per-phase visual children (block-precede numbering); copy Open Decisions into umbrella `## Open questions` prefixed `**Architecture — <topic>:**`. Reference `sdd-handoff.md § What Phase 5 produces` and § Open questions migration as the authoritative shapes.
- [ ] 9. Edit `SKILL.md` Phase 5 Step 2 — replace the foundation-child fill reference to point at the rewritten `sdd-handoff.md § Child #1` (research-driven). One-sentence reminder in the step body: *"the foundation child's `spec.md § Context` mandates research at `/sdd plan` time — no Agent0 template is consumed."*
- [ ] 10. Edit `SKILL.md` Phase 5 Step 6 (handoff message) — extend the `Start here:` line: `Start here:  <out>/docs/specs/002-foundation/      (child #1 — research-driven; /sdd plan researches the stack declared in docs/system-design.md § Stack)`. Also add (between the existing `Umbrella:` and `Start here:` lines) a new line listing the infra children when present: `Infra children: <out>/docs/specs/003-* … 00N-*    (N infra children — backbone first, per the umbrella matrix)`. The line is conditional on infra children existing — omit entirely when zero infra children (simple-visual case).
- [ ] 11. Edit `SKILL.md` top-of-file version line — `v0.4.0 — spec 066 product-ui-quality` → `v0.5.0 — spec 079 product-stack-aware-handoff` (preserve the existing v0.4.0 history paragraph below as historical context; add a new paragraph above it for v0.5.0 mirroring the spec 066 paragraph shape).
- [ ] 12. Verify: `grep -n 'app-skeleton' .claude/skills/product/SKILL.md` returns nothing. Commit as `feat(079): SKILL.md Phase 5 reads system-design + roadmap for stack-aware scaffolding`.

### Block C — `delegation-briefs.md § Step 08` upstream hint

- [ ] 13. Edit `.claude/skills/product/references/delegation-briefs.md § Step 08` CONTEXT block — insert a new line immediately after the existing PRD + sitemap reads, before the `Read .claude/skills/product/templates/pipeline/08-system-design/prompt.md` line: *"**Stack hint from invocation:** `{{stack_hint}}` — the founder passed `--stack={{stack_hint}}` at invocation. Treat as a default the product class either justifies (record in § Stack rationale) or overrides (record the rationale for override in § Alternatives Considered). The final § Stack section is the binding contract — Phase 5 reads only what you write there; the flag is not re-read downstream."*
- [ ] 14. Verify the substitution semantics: confirm `delegation-briefs.md` line 9 already declares `flags.stack` as a state-derived substitution variable (it does — read at task-time). Add a one-line note at line 9 if needed clarifying the fallback: *"If `state.flags.stack` is empty (founder did not pass `--stack`), the substituted value is the literal `(none declared)`."* If the orchestrator's substitution layer already handles empty-fallback (verify by grepping `SKILL.md` for `{{stack_hint}}` or similar substitution patterns), skip this clarification.
- [ ] 15. Commit as `feat(079): Step 08 brief receives --stack as upstream hint`.

### Block D — Deletes

- [ ] 16. Delete `.claude/skills/product/templates/app-skeleton/next/` directory and all 8 files within (`next.config.ts`, `pnpm-workspace.yaml`, `tsconfig.json`, `biome.json`, `postcss.config.mjs`, `.gitignore`, `package.json`, `app/{layout,page,not-found,loading,error}.tsx`, `app/globals.css`). Use `rm -r` (not `-rf` per the governance-gate gotcha).
- [ ] 17. Delete `.claude/skills/product/templates/app-skeleton/expo/` directory and all 8 files (`nativewind-env.d.ts`, `app.json`, `babel.config.js`, `tsconfig.json`, `biome.json`, `tailwind.config.js`, `.gitignore`, `package.json`, `app/{_layout,index}.tsx`). Same `rm -r` discipline.
- [ ] 18. Delete the now-empty parent `.claude/skills/product/templates/app-skeleton/` directory.
- [ ] 19. Delete `.claude/skills/product/references/stack-defaults.md`.
- [ ] 20. Verify final state: `rg -F 'app-skeleton' .claude/ docs/specs/ --files-with-matches` returns ONLY (a) `docs/specs/079-product-stack-aware-handoff/{spec,plan,tasks,notes}.md` (this spec), (b) historical specs that reference past behavior — `docs/specs/048-product-skill-foundation/`, `docs/specs/066-product-ui-quality/`, `docs/specs/068-harness-sync-baseline-reconciliation/`. Same check for `rg -F 'stack-defaults'`.
- [ ] 21. Commit as `feat(079): delete app-skeleton templates + stack-defaults.md cache`.

### Block E — REMINDERS dismissal

- [ ] 22. Open `.claude/REMINDERS.md`. Locate the bullet starting "Re-research `/product` stack defaults quarterly" (was line 9, dated 2026-08-20). Delete that single bullet (one line). Do not renumber others — `/remind` uses line position, not stable IDs.
- [ ] 23. Commit as `chore(079): dismiss quarterly stack-defaults reminder (obsolete)`.

### Block F — `/sdd plan` migration advisory

- [ ] 24. Edit `.claude/skills/sdd/SKILL.md § Subcommand: plan`. Between the existing steps 2 (`Read spec.md`) and 3 (`Draft plan.md`), insert a new step 2.5: *"**Migration advisory** — if the spec's `## Context / references` (or any § Context section in `spec.md`) literally contains the substring `app-skeleton/`, emit a one-line advisory to stderr: `migration-advisory: foundation spec references the deleted app-skeleton template; re-run research at /sdd plan time per spec 079`. Non-blocking — `/sdd plan` proceeds with step 3."*
- [ ] 25. Smoke-test the advisory shape: create a temporary fixture `/tmp/migration-test/spec.md` containing `## Context / references\n- .claude/skills/product/templates/app-skeleton/next/`. Manually trace the new step 2.5 against the fixture — confirm the substring match works. (Functional test; no need to actually invoke `/sdd plan` end-to-end.)
- [ ] 26. Commit as `feat(079): /sdd plan emits migration-advisory for stale app-skeleton refs`.

## Verification

Each verification task maps to one `spec.md § Acceptance criteria` scenario or static-fact bullet.

- [ ] 27. **Scenario #1 — full-stack architecture produces infra children**: re-read the rewritten `sdd-handoff.md § What Phase 5 produces` + § Child-spec matrix + `SKILL.md` Phase 5 Step 1. Confirm the documented flow for a mei-saas-shaped input (Bun monorepo D-03 + 9 packages + Fase 1 with monorepo/schema/auth/integration deliverables) names children `003-monorepo-backbone`, `004-schema-rls`, `005-auth-foundation`, `006-brasilapi-integration` (or equivalent extracted slugs) before per-phase visual children at #7..N. Walk a sub-agent dispatch trace mentally — the instructions must be unambiguous.
- [ ] 28. **Scenario #2 — simple visual-only product keeps lean matrix**: re-read same files. Confirm for a single-Next.js-no-backend input the matrix has only foundation + component-library + per-phase visual children — zero infra children, identical to current behavior.
- [ ] 29. **Scenario #3 — roadmap Fase 1 owner-or-deferral**: confirm `SKILL.md` Phase 5 Step 1 explicitly instructs "every Fase 1 row maps to a child OR appears in umbrella OQs as `**Deferral reason:**`". Grep for the literal phrase.
- [ ] 30. **Scenario #4 — system-design Open Decisions migration**: confirm `SKILL.md` Phase 5 Step 1 explicitly instructs "copy Open Decisions into umbrella `## Open questions` prefixed `**Architecture — <topic>:**`". Cross-check with `sdd-handoff.md § Open questions migration` paragraph.
- [ ] 31. **Scenario #5 — foundation child research-driven**: read the rewritten `sdd-handoff.md § Child #1`. Confirm § Context names `docs/system-design.md § Stack` + `research-before-proposing.md`; confirm § Acceptance contains zero literals from {`pnpm`, `bun`, `npm`, `next.config`, `tailwind.config`} — fully stack-neutral.
- [ ] 32. **Scenario #6 — `--stack` flag becomes upstream hint**: re-read `delegation-briefs.md § Step 08`. Confirm the new "Stack hint from invocation" line appears in CONTEXT; confirm SKILL.md substitution layer fills `{{stack_hint}}` from `state.flags.stack`.
- [ ] 33. **Static fact: templates removed**: `rg -F 'app-skeleton' .claude/ docs/specs/ --files-with-matches` returns ONLY the expected file set (spec 079 + historical specs 048/066/068 + any session-state files that captured the deletion event itself). No `templates/app-skeleton/` directory exists.
- [ ] 34. **Static fact: sdd-handoff rewrite**: `grep -n 'app-skeleton' .claude/skills/product/references/sdd-handoff.md` returns nothing; `grep -n 'system-design.md § Stack' .claude/skills/product/references/sdd-handoff.md` matches in both § Child #1 § Context AND § Standing constraints.
- [ ] 35. **Static fact: REMINDERS dismissed**: `grep -F 'Re-research /product stack defaults' .claude/REMINDERS.md` returns nothing.
- [ ] 36. Final sweep: bump `spec.md` `**Status:**` from `draft` to `shipped`; verify every `## Acceptance criteria` checkbox is `- [x]`.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._
