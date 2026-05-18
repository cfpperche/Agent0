# 036 — prototype-skill-refactor — tasks

_Generated from `plan.md` on 2026-05-18. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Pass A — Bundle templates

- [ ] 1. **Verify `packages/mcp-product-pipeline/src/templates/` exists + enumerate the 13 step dirs.** `ls packages/mcp-product-pipeline/src/templates/` should list 01-ideation through 13-prototype-v3. Refuse to proceed if any step is missing (would indicate the pipeline package is in a bad state — needs investigation upstream first).
- [ ] 2. **Verify `packages/mcp-product-pipeline/design-systems/` exists (OD catalog).** `ls packages/mcp-product-pipeline/design-systems/ | wc -l` should report ≥ 5 vendor dirs. If absent, log finding and note that Step 6 (design-system) catalog-path falls back to custom-only mode in `delegation-briefs.md`.
- [ ] 3. **Create `.claude/skills/prototype/templates/pipeline/` directory tree.** `mkdir -p` the 13 step subdirs.
- [ ] 4. **Copy each step's templates verbatim into the bundle.** For step in 01-ideation … 13-prototype-v3: `cp -r packages/mcp-product-pipeline/src/templates/<step>/. .claude/skills/prototype/templates/pipeline/<step>/`. Verify file count parity after each copy (`diff -rq`).
- [ ] 5. **Copy OD vendor index.** If `packages/mcp-product-pipeline/design-systems/` exists: produce `.claude/skills/prototype/references/od-catalog-index.json` with `{ vendor_name, mood, palette_summary, vendor_path }` per vendor (extracted from each `DESIGN.md` first 50 lines). Do NOT copy full `DESIGN.md` files — only the index. Total target size ≤ 50 KB.
- [ ] 6. **Validator gate A — `bash .claude/skills/skill/scripts/validate.sh .claude/skills/prototype` → exit 0.** If non-zero, surface stderr and abort. Pass A is a prerequisite for B.

### Pass B — Rewrite skill body

- [ ] 7. **Create `.claude/skills/prototype/references/pipeline-coverage.md`.** Document: phase-to-step mapping (Phase 1 = steps 1-4, Phase 2 = steps 5-7, Phase 3 = steps 8-12, Phase 4 = step 13); per-step lightening op applied ("standard" tier — see plan.md Approach); per-step output artifact list + size targets (concept-brief 4-10KB at standard, functional-spec 10-15KB at standard, etc — calibrated lighter than canonical pipeline's 12-25KB / 15KB / 20KB targets).
- [ ] 8. **Create `.claude/skills/prototype/references/state-machine.md`.** Document: `.state.json` shape v2 (`{slug, idea, flags, phase, step, started_at, gates_passed[], blocked_steps[], completed_at?}`); 4-phase progression; gate semantics (continue/iterate/abort options per `AskUserQuestion`); resume support via `--from-step=NN` (validates `.state.json.slug` matches argument-derived slug, idea matches, then jumps to step N).
- [ ] 9. **Rewrite `.claude/skills/prototype/SKILL.md`.** Replace v1 5-phase body with v2 4-phase body. New shape:
  - **Phase 0 — Setup + idempotency:** `--out=<path>` flag (required); collision prompt matches v1 pattern; init `.state.json` with v2 shape.
  - **Phase 1 — Discovery (steps 1-4):** dispatch Step 1 (opus) first (concept brief blocks downstream); then steps 2/3/4 in parallel (sonnet × 3 in one message — include literal "5 Agent tool calls in one message" worked example here). Gate `AskUserQuestion` with continue/iterate/abort.
  - **Phase 2 — Identity (steps 5-7):** Step 5 (brand) → Step 6 (design-system) → Step 7 (prototype-v2 screen-writer fan-out, cap=5). Gate.
  - **Phase 3 — Specification (steps 8-12):** Step 8 (PRD) → steps 9/10/11/12 in parallel (sonnet × 4). Gate.
  - **Phase 4 — Synthesis (step 13):** atlas writer + per-route screen fan-out (cap=5). No gate; closes with `/sdd new <slug>` handoff.
  - **Phase 5 — Handoff:** print final report message.
  - Stitch step (in Phase 4 or end of each phase): verify `@import "../tokens.css"` line exists via `grep -qE '^@import.*tokens\.css' app/globals.css` (not loose substring).
  - OVERRIDE marker inline for any `pnpm install` dispatch.
- [ ] 10. **Rewrite `.claude/skills/prototype/references/delegation-briefs.md`.** v2 needs briefs for: 13 step-specific sub-agents + 1 per-stack screen-writer (steps 02/07/13 prototype passes). Each brief:
  - Uses 5-field handoff per `.claude/rules/delegation.md`.
  - Includes a `model:` field (Step 1=opus; Steps 2-13=sonnet by default per Q1 resolution).
  - References its bundled template at `.claude/skills/prototype/templates/pipeline/<step>/`.
  - States outputs with size floors matching `pipeline-coverage.md`.
  - For dispatches that fan-out (steps 02/07/13 screen-writers), declares concurrency cap=5.
- [ ] 11. **Extend `.claude/skills/prototype/references/quality-checklist.md`.** Add per-step gate criteria (Step 1 concept-brief size floor 4KB, Step 4 audit findings count ≥ 3, Step 9 system-design size floor 12KB at "standard" tier, etc). Keep the v1 4-dim rubric (Token/Voice/Component/Brief-fit) for screen scoring.
- [ ] 12. **Extend `.claude/skills/prototype/templates/report.md.tmpl`.** New sections beyond v1: per-step pass/fail status; gate-pass log; dogfood findings; PRD coverage matrix (US-NN × screens); legal-surface checklist; iteration log when user picked "iterate" at any gate.
- [ ] 13. **Validator gate B — `bash .claude/skills/skill/scripts/validate.sh .claude/skills/prototype` → exit 0.** Verify SKILL.md body did NOT exceed the ~5000-token cap (Risk 2 mitigation: if it did, factor more of the orchestration logic into `pipeline-coverage.md` / `state-machine.md`).

### Pass C — Fix 5 dogfood-surfaced template bugs

- [ ] 14. **Fix `.claude/skills/prototype/templates/monorepo-skeleton/next/pnpm-workspace.yaml`.** Replace `'@biomejs/biome': set this to true or false` with `'@biomejs/biome': true`; same for `sharp`. (Dogfood finding #1.)
- [ ] 15. **Fix `.claude/skills/prototype/templates/monorepo-skeleton/next/package.json`.** Add `"test": "echo 'no tests yet' && exit 0"` to `scripts` block (Dogfood finding #2.)
- [ ] 16. **Fix `.claude/skills/prototype/templates/monorepo-skeleton/expo/package.json`.** Same `test` script addition for stack symmetry.
- [ ] 17. **Fix `.claude/skills/prototype/templates/monorepo-skeleton/next/app/globals.css`.** Prepend `@import "../tokens.css";` as line 1. Replace the misleading "tokens.css is generated by Phase 2…" comment with `/* tokens.css must exist at the prototype root by Phase 4 stitch; verify with: grep -qE '^@import.*tokens\.css' app/globals.css */`. (Dogfood finding #5 + scenario 4 acceptance.)
- [ ] 18. **Surface `tdd-advisory: validator scope` in skill body.** SKILL.md Notes section adds a one-line callout: "the post-edit validator runs over the WHOLE prototype dir, not just the sub-agent's edited file — one bad Biome format error blocks all subsequent sub-agents until cleaned. Run `biome check --write .` between batches if multiple sub-agents are queued." (Dogfood finding #4.)
- [ ] 19. **Validator gate C — `bash .claude/skills/skill/scripts/validate.sh .claude/skills/prototype` → exit 0.**

### Pass D — Ops + docs hygiene

- [ ] 20. **Add quarterly REMINDERS item.** Append to `.claude/REMINDERS.md`: `Diff .claude/skills/prototype/templates/pipeline/ vs packages/mcp-product-pipeline/src/templates/; sync if drift. From spec 036 Q2 resolution.  ·  due: 2026-08-18`.
- [ ] 21. **Supersede spec 034.** Update `docs/specs/034-prototype-skill/spec.md` `**Status:**` line to `superseded by 036-prototype-skill-refactor`.
- [ ] 22. **CLAUDE.md pointer.** Add 1-paragraph pointer to spec 036 in the most natural location (likely a new `## Prototype skill` section, or a callout under the existing `## Spec-driven development` block). Explain: v2 covers all 13 pipeline steps in agile mode; single-tier "standard" calibration; standalone (templates bundled); supersedes 034.
- [ ] 23. **Delete v1 `.claude/skills/prototype/templates/prd-1pager.md.tmpl`.** Replaced by bundled `templates/pipeline/08-prd/`. Confirm `delegation-briefs.md` no longer references this path before deleting.

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria._

- [ ] 24. **Scenario 1 (end-to-end 13-step coverage) — paper verify.** After Pass A-C complete, walk the SKILL.md + delegation-briefs.md by hand: every one of the 13 pipeline steps has a corresponding sub-agent dispatch with declared model + bundled template ref + output artifact. Check off only when 13/13 are present.
- [ ] 25. **Scenario 2 (standalone — no MCP dep) — code-inspection verify.** Grep `.claude/skills/prototype/` for any `mcp__product-pipeline__` token. Expect zero matches. Grep for `packages/mcp-product-pipeline/` references — should appear only in `pipeline-coverage.md` documentation context (canonical-pipeline pointer), NOT as a runtime dependency in SKILL.md or `delegation-briefs.md`.
- [ ] 26. **Scenario 3 (`--out` flag works) — dry-run verify.** Smoke-test parser: invoke `/prototype "test" --stack=next --out=/tmp/spec036-smoke` and observe Phase 0 creates the dir and writes `.state.json` (does not need to complete full pipeline — Phase 0 success is enough).
- [ ] 27. **Scenario 4 (tokens.css import verified, not grep-guessed) — strict-regex inspection.** Inspect SKILL.md Phase 4 stitch step body: must contain literal `grep -qE '^@import.*tokens\.css'` or equivalent strict pattern, NOT `grep -q 'tokens.css'`. Confirm bundled `globals.css` ships with the `@import` line as line 1 (`head -1 .claude/skills/prototype/templates/monorepo-skeleton/next/app/globals.css` returns the import).
- [ ] 28. **Scenario 5 (4 phase gates, single user-confirm each) — code-inspection.** Inspect SKILL.md: exactly 3 `AskUserQuestion` invocations (Phase 1, 2, 3 gates). Phase 4 closes without `AskUserQuestion`. Phase 0 is local (collision prompt is per-stack, not via AskUserQuestion).
- [ ] 29. **Scenario 6 (resumable via `--from-step=NN`) — dry-run verify.** Smoke-test: invoke `/prototype "test" --stack=next --out=/tmp/spec036-resume --from-step=05`. Phase 0 + .state.json check should pass; orchestration should skip steps 1-4 and start at step 5. Verify in dry-run mode (the sub-agent dispatch for step 5 fires, but actual sub-agent work can be aborted by the user).
- [ ] 30. **Scenario 7 (5 dogfood bugs absent from bundled templates) — checklist.** Verify file-by-file: pnpm-workspace.yaml has literal `true`/`false` (not "set this to..."); package.json has `"test":` line; SKILL.md has the "5 Agent tool calls in one message" worked example; SKILL.md Notes has the validator scope hint; globals.css line 1 is the `@import "../tokens.css";`.
- [ ] 31. **Scenario 9 (skill validate exit 0) — `bash .claude/skills/skill/scripts/validate.sh .claude/skills/prototype`.** Exit 0 required.
- [ ] 32. **Scenario 10 (live dogfood — design system renders).** Replay the 2026-05-17 brief: `/prototype "Claude Code governance dashboard" --stack=next --out=/tmp/dogfood-v2`. Wait for Phase 4 completion. Run `pnpm dev` in the output dir. `curl http://localhost:3000/` returns HTML; inspect the linked CSS chunk and confirm `--color-background:` token is defined (not just Tailwind reset). User visually inspects in browser and confirms dark theme + cyan accents + monospace typography apply.
- [ ] 33. **Static facts checklist:** verify 13 step template dirs exist (`ls .claude/skills/prototype/templates/pipeline/ | wc -l` returns 13); REMINDERS quarterly item present; spec 034 `**Status:**` updated; concurrency cap=5 still declared in `delegation-briefs.md`.
- [ ] 34. **Spec 036 → status flip.** Update `docs/specs/036-prototype-skill-refactor/spec.md` `**Status:**` from `draft` to `shipped` only after tasks 1-33 are all green AND the live dogfood (task 32) passes user visual inspection.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._

- **Implementation effort estimate:** Pass A (~30 min, mostly mechanical copy + validate). Pass B (~2-3 hrs, the bulk of the work — rewriting SKILL.md + delegation-briefs.md for 13 sub-agents). Pass C (~30 min). Pass D (~30 min). Live dogfood (task 32, ~30-45 min wall-time real run). **Total: ~4-5 hrs focused work + 1 dogfood session = 1 long session or 2 normal sessions.**
- **Dogfood replay = acceptance proof.** Scenario 10 (replay the 2026-05-17 brief on v2) is the single highest-signal acceptance check. If v2 renders the design system properly AND covers all 13 steps' artifacts in the output, the refactor is real. All other checks are necessary but not sufficient.
- **Sub-agent dispatch wall-clock** for v2 will be 30-45 min vs v1's ~25 min. The new planning steps add real work. This is expected; user picked depth over speed (no `--fast` tier).
- **Spec 034 supersede order:** flip `**Status:**` AFTER v2 dogfood passes. Until then, v1 is the working `/prototype` — premature supersede could break the catalog for fork users who pull mid-refactor.
- **CLAUDE.md pointer placement decision** (task 22): if a new `## Prototype skill` section feels too prominent for what's still a niche skill, alternative is a callout-line under `## Spec-driven development` block ("...spec 036 documents the `/prototype` v2 agile frontend to the 13-step `mcp-product-pipeline`"). Resolve at task 22 time.
- **OD catalog index size:** if Step 6 design-system catalog path proves too thin without full `DESIGN.md` per vendor, consider a follow-up REMINDERS item to fetch full vendors on-demand via the MCP `product_design_system_path()` tool (which IS available even if the rest of the MCP isn't being used — narrow exception to "no MCP deps" rule). Out of scope for spec 036.
