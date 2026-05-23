# 079 — product-stack-aware-handoff — plan

_Drafted from `spec.md` on 2026-05-23. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Phase 5 is **parent-orchestrated** (no `delegation-briefs.md § Phase 5` sub-agent brief exists — `SKILL.md § Phase 5` executes the 6 steps directly), so the change is concentrated: the orchestrator reads two more artifacts (`docs/system-design.md` and the existing `docs/roadmap.md`) and uses them to (a) compute the child-spec matrix conditionally and (b) populate the umbrella's § Open questions from system-design's Open Decisions. The bundled `app-skeleton/{next,expo}/` templates and their `stack-defaults.md` snapshot file are deleted entirely — Agent0 stops shipping stack code; the foundation child's `spec.md § Context` points the founder's later `/sdd plan` at `docs/system-design.md § Stack` + `.claude/rules/research-before-proposing.md` instead of at a frozen template.

Execution order matches the dependency chain — contract first, then orchestration, then upstream brief, then deletions, then dismissals:

1. **`sdd-handoff.md`** rewritten — the contract doc that `SKILL.md` reads at Phase 5 entry. Defines new umbrella-matrix logic (foundation + component-library + N infra children + N per-phase visual children), the research-driven foundation `spec.md` shape, and the stack-conditional standing constraints.
2. **`SKILL.md § Phase 5`** updated to match — adds the `system-design.md` + roadmap-Fase-1-deliverable reads; updates the handoff message footer; removes the template-path reference.
3. **`delegation-briefs.md § Step 08`** (system-design producer) gains a `{{stack_hint}}` substitution that the orchestrator fills from `.state.json.flags.stack` — turns `--stack=expo` into "Stack hint from invocation: expo" prose in the brief, which the producer either justifies or overrides in the final § Stack section. `state.flags.stack` is already in the state shape; only the brief substitution + SKILL.md plumbing change.
4. **Delete** `templates/app-skeleton/next/` (8 files) + `templates/app-skeleton/expo/` (8 files) + parent `app-skeleton/` dir + `references/stack-defaults.md` (1 file). The harness-sync deletion pass (spec 068) handles fork propagation cleanly.
5. **REMINDERS dismissal** — drop the "Re-research /product stack defaults quarterly" item (line 9 of `.claude/REMINDERS.md`); the capacity it tracked no longer exists.
6. **`/sdd plan` migration advisory** (OQ#4 accepted) — one-line addition to `.claude/skills/sdd/SKILL.md § Subcommand: plan` that greps the target spec's `spec.md § Context` for `app-skeleton/` and, if found, emits `migration-advisory: foundation spec references the deleted app-skeleton template; re-run research at /sdd plan time per spec 079`.

Each step is independently revertible and testable; one commit per step keeps `git log` legible. The 4 OQ defaults from `spec.md` (no granularity cap, infra block-precedes visual, keep `--stack` name, emit migration advisory) all stand — none surfaced new contradictions during the file-cross-check.

## Files to touch

**Create:**
- (none) — Agent0 doesn't ship stack code

**Modify:**
- `.claude/skills/product/references/sdd-handoff.md` — major rewrite:
  - § What Phase 5 produces — add infra-children-conditional logic to the table description
  - § The umbrella spec — § Child-spec matrix section gains an "infra children" row group between #2 component-library and #3..N per-phase; numbering block-precedes per OQ#2 default
  - § Standing constraints — "Styling: Tailwind utility classes" rewritten to be stack-conditional ("the styling system declared in `system-design.md § Stack`; if Tailwind, then …; if styled-components / vanilla-extract / Panda CSS / etc., the foundation child's `/sdd plan` researches the canonical token-binding pattern")
  - § Child #1 — `002-foundation/spec.md` — § Context section points at `docs/system-design.md § Stack` (not at `app-skeleton/`); § Acceptance becomes stack-neutral; remove the `pnpm install && pnpm dev` literal, replace with "dev server starts clean per the declared stack's canonical command (researched at `/sdd plan` time)"
  - § Fallback — unchanged (roadmap-degenerate fallback still emits one `app-build` child)
  - New § Open questions migration — paragraph documenting that umbrella OQs are auto-populated from system-design's § Trade-off Triggers → Open Decisions

- `.claude/skills/product/SKILL.md` — three edits in § Phase 5:
  - Step 1 — the umbrella scaffold instruction gains "read `docs/system-design.md` § Stack + § Services + § Trade-off Triggers/Open Decisions + `docs/roadmap.md` Fase 1 `| Deliverable | Owner | Status |` rows; emit infra children for Fase 1 deliverables that don't map to per-phase visual children; copy Open Decisions into umbrella `## Open questions` prefixed `**Architecture — <topic>:**`"
  - Step 2 — foundation child fill instruction now references the new § Child #1 (research-driven) shape in `sdd-handoff.md`
  - Step 6 — handoff message footer's `Start here: <out>/docs/specs/002-foundation/` line gains a parenthetical: `(research-driven — /sdd plan researches the stack declared in docs/system-design.md § Stack)`
  - Top-of-file version line bumped from `v0.4.0 — spec 066` to `v0.5.0 — spec 079`

- `.claude/skills/product/references/delegation-briefs.md` — Step 08 brief gains a `{{stack_hint}}` substitution slot in the CONTEXT block (between the existing PRD + sitemap reads and the schema-doc reference): "**Stack hint from invocation:** `{{stack_hint}}` — the founder passed `--stack={{stack_hint}}` at invocation; treat as a default the product class either justifies or overrides in § Stack. The final § Stack section is the binding contract — Phase 5 reads only what you write there." Substitution falls back to "_(none declared)_" when `state.flags.stack` is empty.

- `.claude/skills/sdd/SKILL.md` — § Subcommand: `plan`: one-line addition (step 2.5 between "Read spec.md" and "Draft plan.md"): "if the spec's § Context still references `app-skeleton/<stack>/` (the deleted Agent0 template), emit `migration-advisory: foundation spec references the deleted app-skeleton template; re-run research at /sdd plan time per spec 079`. Non-blocking — `/sdd plan` proceeds."

- `.claude/REMINDERS.md` — delete the bullet starting "Re-research `/product` stack defaults quarterly" (currently the 6th item under § Reminders, dated 2026-08-20). The capacity it gates (the `stack-defaults.md` cache + the templates) no longer exists.

**Delete:**
- `.claude/skills/product/templates/app-skeleton/next/` — 8 files: `next.config.ts`, `pnpm-workspace.yaml`, `tsconfig.json`, `biome.json`, `postcss.config.mjs`, `.gitignore`, `package.json`, `app/{layout,page,not-found,loading,error}.tsx`, `app/globals.css`
- `.claude/skills/product/templates/app-skeleton/expo/` — 8 files: `nativewind-env.d.ts`, `app.json`, `babel.config.js`, `tsconfig.json`, `biome.json`, `tailwind.config.js`, `.gitignore`, `package.json`, `app/{_layout,index}.tsx`
- `.claude/skills/product/templates/app-skeleton/` — parent dir (empty after children deleted)
- `.claude/skills/product/references/stack-defaults.md` — the frozen-snapshot research cache; same anti-pattern as the templates (centralized stale opinion vs per-fork fresh research)

## Alternatives considered

### Keep `stack-defaults.md` as a deprecated "historical snapshot"

Rejected. Same anti-pattern that motivated deleting the templates — a centralized snapshot that ages predictably and creates a maintenance dance (the quarterly reminder). Forks that want a historical reference can `git log --all -- .claude/skills/product/references/stack-defaults.md` after the delete. A "deprecated" file in the live tree invites accidental use by sub-agents that grep for "Next.js" or "Expo" without reading the deprecation banner; cleaner to remove entirely.

### Rewrite `stack-defaults.md` as a meta-guide to stack research at `/sdd plan` time

Rejected. `.claude/rules/research-before-proposing.md` already mandates research and citations; a duplicate "how to research a stack specifically" file would just paraphrase the rule. The foundation child's `spec.md § Context` (rewritten in this plan) is the natural place to mention research, in the context of the specific spec — not in a shared reference.

### Extend `/product` to N more pipeline steps (Caminho B from the carryover memory)

Rejected at memory-time (`/product` should stay design partner, not become monorepo generator). This spec confirms that rejection by keeping the 15-step pipeline intact — the change is one phase reading two more artifacts, not a new pipeline.

### Build a `/promote <product-dir>` skill (Caminho C from the carryover memory)

Rejected as documented in `spec.md § Non-goals`. Splitting the SDD handoff into a separate skill loses the moment-of-freshest-intent (right after `/product` finishes) without buying real separation — Phase 5 is already a discrete phase with a clean entry/exit shape. A separate skill would also force the founder to remember-and-run a second invocation, adding friction.

## Risks and unknowns

- **Cold-start friction for the foundation child.** Without the bundled `app-skeleton/next/`, the founder running `/sdd plan` on `002-foundation/` waits for the agent to web-research the current canonical Next.js (or Bun/Turborepo, or whatever) setup — minutes + tokens vs. the prior near-instant template copy. Accepted: that "instant" was misleading whenever the system-design declared anything non-trivial (the mei-saas2 case); the research cost buys correctness.
- **Web research quality is the new floor.** The foundation child's `spec.md § Acceptance` says "research-driven via `research-before-proposing.md`". If the agent doing `/sdd plan` skips research and confabulates, the foundation is wrong. Mitigation: `research-before-proposing.md` is already mandatory; this spec just exercises it harder. No new mechanism.
- **The orchestrator parsing `roadmap.md` Fase 1 deliverables is loose.** The schema requires `| Deliverable | Owner | Status |` columns but the deliverable text is free-prose — Phase 5 has to extract semantic intent ("monorepo backbone" → infra child `monorepo-backbone`). A noisy roadmap can produce noisy children. Accepted: same imprecision as today's parsing of sitemap chrome values; the umbrella matrix is reviewable by the founder before they start the build.
- **`--stack=expo` passed through to Step 8 might confuse the producer** if the product class doesn't match. Mitigation: the brief addition explicitly says "treat as a default the product class either justifies or overrides"; Step 8's existing quality judge (spec 075) catches contradictions.
- **Existing forks that already consumed the templates** keep them in their tree (not silently broken). Sync-harness deletion pass (spec 068) handles propagation cleanly: forks where the template files match the baseline get auto-removed; customized copies get a `customized-upstream-removed` advisory and stay until manually resolved. No forced migration.
- **Spec 076 lands in parallel** — `/product` skill files are touched by both (delegation-briefs.md, SKILL.md). 076's edits are local (Phase 4 visual check + brief sections); 079's edits are in different sections (Phase 5 + Step 8 brief). No expected merge conflict, but order-of-merge matters: 076 first (smaller, ships first), then 079.
- **Unknown:** does any sub-agent dispatched by `/product` other than Phase 5's parent grep for `app-skeleton/` paths or read `stack-defaults.md`? Grep-verified during implementation as task #1, before any delete.

## Research / citations

- **mei-saas2 session diagnose (2026-05-22)** — `~/.claude/projects/-home-goat-mei-saas/ea991098-546d-482a-8294-2b4f339935c7.jsonl`; framed handoff at `/home/goat/mei-saas/.claude/SESSION.md`. The originating concrete failure.
- `.claude/skills/product/references/sdd-handoff.md` — the contract this plan rewrites. Read 2026-05-23 — key insight: Phase 5 is parent-orchestrated, not sub-agent-dispatched (no `delegation-briefs.md § Phase 5` brief exists).
- `.claude/skills/product/SKILL.md § Phase 5` (lines 149-180) — confirms 6-step parent-orchestrated structure; confirms the handoff-message shape.
- `.claude/skills/product/references/delegation-briefs.md` line 9 — confirms `state.flags.stack` is already available via substitution; no new state-machine field needed.
- `.claude/skills/product/templates/pipeline/08-system-design/schema.md` — confirms § Stack is free-prose (not machine-parseable); Phase 5's read must be semantic, not regex.
- `.claude/skills/product/templates/pipeline/10-roadmap/schema.md` — confirms `| Deliverable | Owner | Status |` is the load-bearing Fase 1 contract Phase 5 reads.
- `.claude/skills/product/references/stack-defaults.md` — the file being deleted. Read 2026-05-23 to confirm its only consumers were the templates and the quarterly reminder.
- `docs/specs/068-harness-sync-baseline-reconciliation/` — proves the deletion-pass for `templates/app-skeleton/` will propagate cleanly to forks; canonical example documented in spec 068's own § Acceptance ("templates/monorepo-skeleton/ after the app-skeleton rename").
- `docs/specs/066-product-ui-quality/` — established Phase 5 as the SDD-handoff phase; the precedent this spec extends.
- `docs/specs/060-harness-gaps-2026/` — canonical umbrella + child-matrix example with no infra children (the lean case this spec preserves).
- `.claude/rules/research-before-proposing.md` — the rule that makes research-driven foundation children honest.
- `.claude/memory/MEMORY.md` REMINDERS carryover — the Caminho A/B/C rejection of Caminho B + deferral of Caminho C, which this spec narrows past by changing scope (read two more artifacts, not 17 new steps).
