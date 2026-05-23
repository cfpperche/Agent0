# 079 — product-stack-aware-handoff

_Created 2026-05-23._

**Status:** draft

## Intent

`/product`'s Phase 5 (SDD handoff) scaffolds the umbrella + foundation child from a fixed visual-only template menu (`templates/app-skeleton/{next,expo}/`) that ignores the architecture `/product` itself produced in Phase 2 Step 8. Concrete failure: mei-saas2 session (2026-05-22) ran `/product` cleanly, then hit `system-design.md` D-03 **locked** as Turborepo + Bun workspaces + 9 packages while the scaffolded `002-foundation` spec described a flat Next.js + pnpm shell. The two artifacts of the same run contradict — the founder caught it before committing and paused, but the underlying gap is that Phase 5 doesn't close the loop on its own upstream output.

The fix is principled: Agent0 stops shipping stack code. Phase 5 reads `system-design.md` + `roadmap.md` Fase 1 + the existing visual contract, then emits an umbrella whose child matrix reflects what the architecture actually demands — visual-only when the product is a single-app frontend, full-stack-aware (extra infra children for monorepo backbone / schema+RLS / auth / etc.) when system-design locks a richer architecture. Foundation child becomes research-driven at `/sdd plan` time — the agent doing the planning web-researches the current canonical setup for the declared stack (per `.claude/rules/research-before-proposing.md`) instead of consuming a frozen template that ages. This closes the carryover Caminho-A/B/C decision recorded in `MEMORY.md` (rejected B as proposed because it bloated `/product` to ~17 pipeline steps; this is narrower — only Phase 5 changes, no new pipeline steps).

## Acceptance criteria

- [ ] **Scenario: full-stack architecture produces infra children**
  - **Given** a `/product` run whose `docs/system-design.md` § Stack locks a monorepo + multiple backend services (e.g. mei-saas D-03: Turborepo + Bun + 9 packages: `shared, db, core, integrations, llm, notifications, api, workers, web`) AND whose `docs/roadmap.md` Fase 1 lists deliverables like "monorepo backbone", "schema + RLS", "auth", "BrasilAPI integration"
  - **When** Phase 5 runs
  - **Then** the umbrella `spec.md` § Child-spec matrix carries (a) child #1 foundation, (b) child #2 component-library, **(c) one infra child per Fase 1 deliverable that has no owner among the per-phase visual children** — e.g. `003-monorepo-backbone`, `004-schema-rls`, `005-auth-foundation`, `006-brasilapi-integration` — sliced before the per-phase visual children (which renumber accordingly); the foundation child #1 `spec.md` § Acceptance is stack-neutral and references `docs/system-design.md § Stack` as the source of truth (not a bundled template path)

- [ ] **Scenario: simple visual-only product keeps the lean matrix**
  - **Given** a `/product` run whose `docs/system-design.md` § Stack declares a single Next.js (or Expo) frontend with no backend services beyond a BaaS dependency, AND whose `docs/roadmap.md` Fase 1 deliverables are visual/UX-shaped
  - **When** Phase 5 runs
  - **Then** the umbrella matrix carries only child #1 foundation + child #2 component-library + N per-phase visual children (no infra children inserted); identical to the current behavior for that input shape — no regression on the simple case

- [ ] **Scenario: roadmap Fase 1 deliverables get owner-or-deferral**
  - **Given** any `/product` run with a non-degenerate `docs/roadmap.md`
  - **When** Phase 5 runs
  - **Then** every row of `roadmap.md` Fase 1's `| Deliverable | Owner | Status |` table either (a) maps to a child in the umbrella matrix (named explicitly in that child's scope cell), or (b) is documented in the umbrella's `## Open questions` with `**Deferral reason:**` prose — no Fase 1 deliverable is silently orphaned

- [ ] **Scenario: system-design Open Decisions become umbrella OQs**
  - **Given** `docs/system-design.md § Trade-off Triggers → Open Decisions` carries N undecided architectural rows
  - **When** Phase 5 runs
  - **Then** the umbrella `spec.md § Open questions` carries one bullet per undecided row, prefixed `**Architecture — <topic>:**`, so the build picks them up before the relevant child is implemented

- [ ] **Scenario: foundation child is research-driven, not template-driven**
  - **Given** the Phase-5-scaffolded `002-foundation/spec.md`
  - **When** the founder later runs `/sdd plan` on it
  - **Then** the spec's § Context section points at `docs/system-design.md § Stack` (not at `.claude/skills/product/templates/app-skeleton/<stack>/`); the spec's § Acceptance criteria are stack-neutral (`dev server starts clean`, `typecheck exits 0`, `lint exits 0`, `token utilities resolve`) and name no package manager / framework version / config file path; `/sdd plan` invokes web research per `.claude/rules/research-before-proposing.md` to determine the current canonical setup for the declared stack and cites sources

- [ ] **Scenario: `--stack` flag becomes upstream hint**
  - **Given** a `/product` run invoked with `--stack=expo`
  - **When** Phase 2 Step 8 (system-design) runs
  - **Then** Step 8's brief receives the flag value as a `**Stack hint from invocation:**` line; the producer treats it as a default the product class should justify or override (e.g. a B2B internal-tool product class may still override to `next` even when `--stack=expo` was passed); the final `system-design.md § Stack` is the binding contract; Phase 5 reads ONLY system-design (the flag is not re-read downstream)

- [ ] `.claude/skills/product/templates/app-skeleton/next/` and `.claude/skills/product/templates/app-skeleton/expo/` directories are removed; no broken references remain (`rg -F 'app-skeleton' .claude/ docs/specs/ --files-with-matches` returns only spec 079 itself and historical specs that reference past behavior)

- [ ] `.claude/skills/product/references/sdd-handoff.md § Child #1` and § Standing constraints are reworded: the child #1 § Context section now points at `docs/system-design.md § Stack` and mandates research; § Standing constraints' "Styling: Tailwind utility classes" paragraph is rewritten to be stack-conditional ("the styling system declared in `system-design.md § Stack`; if Tailwind, then v4 with `@theme` block from `docs/design-system/tokens.css`; if styled-components / vanilla-extract / Panda CSS / etc., the foundation child's `/sdd plan` researches the canonical token-binding pattern for that system")

- [ ] The `.claude/REMINDERS.md` item "Re-research `/product` stack defaults quarterly" (currently dated 2026-08-20) is dismissed in the same PR that ships 079 (the reminder is obsoleted by the templates-removal; research happens at `/sdd plan` time per-fork, not centrally per-quarter in Agent0)

## Non-goals

- **No new templates ship.** Agent0 does not gain `templates/app-skeleton/next-monorepo/` or `bun-turborepo/` or any other stack template. The principle is Agent0 doesn't ship stack code — and that includes "monorepo opinion code" as much as it does "Next.js opinion code".
- **No `/promote` skill (Caminho C from the carryover memory).** Splitting the SDD handoff into a separate skill loses the moment-of-freshest-intent (right after `/product` finishes) without buying real separation — Phase 5 is already a discrete phase. The memory's framing was that `/product` shouldn't bloat into a stack generator; this spec doesn't bloat it (Phase 5 stays focused on the handoff, just reads two more artifacts).
- **No new `/product` pipeline steps.** Step 16 / 17 / ... are not added. The 15-step pipeline stays; Phase 5 is the only changed phase.
- **No rework of the lo-fi or hi-fi mood-screen generation.** Phase 4 visual contract is unaffected — those produce self-contained static HTML that doesn't depend on the app's framework.
- **No automated migration for existing forks** with in-progress `/product` runs that used the templates. Existing forks that have already consumed the templates aren't broken — they own that code now. Future `/product` runs in those forks won't have the templates; they'll do the research path.

## Open questions

- [ ] **Granularity ceiling on infra children — is there a sane cap?** mei-saas Fase 1 has 4-5 backend deliverables → 4-5 infra children plus foundation + component-library + per-phase = ~10-14 child rows. Acceptable for that product. A hypothetical massive enterprise system-design could declare 15+ infra deliverables — at what point does the matrix become noise vs signal? Default proposal: no cap (let the matrix reflect reality; the founder can dismiss-or-merge rows in the umbrella before starting). _Owner: founder before `plan.md` locks._

- [ ] **Should infra children numbering interleave or block-precede the visual children?** Two shapes possible: (a) `001-umbrella`, `002-foundation`, `003-component-library`, `004-monorepo-backbone`, `005-schema-rls`, `006-auth`, `007-brasilapi`, `008-fase-1-cnpj-dashboard`, ... (infra block-precedes visual); (b) interleaved per implementation-order dependency. Default proposal: (a) — block-precede, because every infra child unblocks ALL downstream visual children, so they need to land first regardless. _Owner: founder before `plan.md` locks._

- [ ] **Does the `--stack` flag get renamed (e.g. `--stack-hint`, `--target-platform`) since it's no longer a template selector?** Default proposal: keep the name `--stack` (rename is a breaking-CLI change for marginal clarity benefit; the change in meaning is documented in `SKILL.md` § Usage); add a `## Notes` paragraph clarifying the new semantics. _Owner: founder before `plan.md` locks._

- [ ] **Migration messaging for users with in-flight foundation children** scaffolded from the old templates — does the `/sdd plan` skill emit a one-line advisory when it sees an `002-foundation/spec.md` whose § Context still points at `app-skeleton/<stack>/`? Default proposal: yes, a one-line `migration-advisory: foundation spec references the deleted app-skeleton template; re-run research at /sdd plan time per spec 079` is cheap and surfaces the situation. _Owner: founder before `plan.md` locks._

## Context / references

- **Conversation 2026-05-22** — mei-saas2 session diagnose; transcript at `~/.claude/projects/-home-goat-mei-saas/ea991098-546d-482a-8294-2b4f339935c7.jsonl`; framed handoff at `/home/goat/mei-saas/.claude/SESSION.md`
- `.claude/skills/product/references/sdd-handoff.md` — current Phase 5 contract (the file this spec rewrites most of)
- `.claude/skills/product/references/delegation-briefs.md § Phase 5` — Phase 5 dispatch brief
- `.claude/skills/product/SKILL.md § Phase 5` — Phase 5 orchestration
- `.claude/skills/product/templates/app-skeleton/{next,expo}/` — the bundled templates being deleted (16 files total)
- `.claude/skills/product/templates/pipeline/08-system-design/schema.md` — what § Stack semantically carries (free-prose locked choices, not machine-parseable)
- `.claude/skills/product/templates/pipeline/10-roadmap/schema.md` — Fase 1 `| Deliverable | Owner | Status |` table shape (the input Phase 5 cross-references to find unmatched deliverables)
- `.claude/rules/research-before-proposing.md` — the research mandate the foundation child's `/sdd plan` invokes
- `.claude/rules/spec-driven.md` § The four artifacts — the `**Type:** umbrella` convention used here
- `docs/specs/060-harness-gaps-2026/` — canonical umbrella + child-matrix example (no infra children — pure tracking matrix)
- `docs/specs/066-product-ui-quality/` — established Phase 5 as the SDD-handoff phase; this spec extends it with stack-awareness
- `docs/specs/076-product-dogfood-fixes/` — sibling in-flight `/product` work; 079 lands after 076 (or in parallel — no file overlap with 076's 6 findings)
- `.claude/memory/MEMORY.md` — REMINDERS carryover "Discutir expansão full-stack do `/product` (3 caminhos)" — this spec is the resolution
- `~/.claude/projects/-home-goat-Agent0/memory/feedback_agent0_changes_ship_via_rules_not_memory.md` — discipline behind why removing templates over time is fine (capacities ship via rules + skills, not opinionated code)
