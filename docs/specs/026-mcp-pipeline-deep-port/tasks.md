# 026 — mcp-pipeline-deep-port — tasks

_Generated from `plan.md` on 2026-05-13. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Phase A — Plumbing extensions

Foundation. Must land + ship green tests BEFORE Phase B starts (content port can't be persisted/validated without these)._

- [x] 1. **Extend `STEPS` array in `src/pipeline.ts`** — add 13th entry `{ n: 13, slug: "prototype-v3", phase: "specification" }`. Confirm `GATE_AFTER` stays `[4, 7, 12]`. Helper functions (`stepByN`, `isGateAfter`, `gateClosingPhase`) auto-cover because they operate on the array — no manual case-by-case edit. Smoke test: `stepByN(13)` returns the new entry; `isGateAfter(13)` returns false.

- [x] 2. **Extend `getTemplate(n)` in `src/templates.ts`** — load `references/*.md` siblings into a `Record<string, string>` map keyed by basename-without-extension. References subdir is optional per step; missing dir → empty map. Add `parseRequiredFiles(schemaBody)` helper that extracts a YAML fenced block declaring either `required_files: [{path, min_size, contains[]}]` (exact-path mode) OR `required_glob: {pattern, min_count, per_match_min_size, per_match_contains[]}` (glob mode for step 13's `screens/*.html`). Both fields can appear together. Return `null` when no fenced block is present.

- [x] 3. **Extend `product_step_get(N)` response payload in `src/tools.ts`** — return `{ prompt, schema, mode, references, required_files }`. Backwards-compat: agents reading the old shape (`{prompt, schema}`) get the new fields as additive extension. Run existing 31 tests; only `templates.test.ts` should need to learn the new keys.

- [x] 4. **Extend `product_step_submit(N, content, extra_files?)` in `src/tools.ts`** — add optional `extra_files: Array<{path: string, content: string}>` param (default `[]`). Validation pipeline:
   1. Read `required_files` + `required_glob` from step's schema.md (via `parseRequiredFiles`)
   2. Collect all paths: primary output filename + every `extra_files[].path`
   3. Layer 1 checks per file: path matches a required entry (exact or glob), `content.length >= min_size`, every `contains[]` substring present
   4. If any check fails: return `{ code: "schema-incomplete", missing_or_invalid: [...] }`, write NO file
   5. If all pass: write each file via `mktemp + rename` (existing atomic pattern from `state.ts`); mark state.completed only after all writes succeed
   Single-file submits (no `extra_files`) continue working identically to today.

- [x] 5. **Update `product_done` message in `src/tools.ts`** — when pipeline completes after step 13, the message names `13-prototype-v3/<slug>/screen-atlas.md` as the visual contract handed to engineering; the canonical handoff command stays `/sdd new <slug>` but the message body now emphasizes screen-atlas as primary reference. Drop the per-phase deliverable inventory shape from spec 025; replace with phase-grouped one-liner + "visual contract: screen-atlas.md".

- [x] 6. **Write `tests/extra-files.test.ts`** — coverage:
   - atomic-write: 5 extra_files succeed together
   - rollback: 1 of 5 fails Layer 1 → 0 files written
   - validates against required_files exact-path entries
   - validates against required_glob with min_count
   - empty extra_files array = backwards-compat single-file flow

- [x] 7. **Write `tests/required-files-schema.test.ts`** — coverage:
   - YAML fenced block parsing happy-path
   - missing fenced block → `null` (no validation; backwards-compat for steps that don't declare required_files)
   - edge cases in `contains`: special chars (`</style>`, `--color-`), single-quote required
   - glob matching: `screens/[0-9]+-*.html` with `min_count: 8`
   - per_match_min_size + per_match_contains applied per glob hit

- [x] 8. **Write `tests/step13.test.ts`** — coverage:
   - `product_step_get(13)` returns step 13 template
   - `product_advance` after step 13 submit fires `product_done`
   - `STEPS.length === 13`
   - state.test.ts existing fixtures extended (or fork-fixture for step-13 case)

- [x] 9. **Confirm Phase A green** — run full test suite (existing 31 + new ~15-20); ALL must pass. Compile via `bun build` clean (no TS errors). Smoke-test the `product_*` tools via stdio JSON-RPC against a scratch dir; verify `product_step_get(13)` returns the (still placeholder) template, `product_step_submit(2, body, extra_files=[...])` accepts shape.

## Phase B — Content port (13 templates)

Each task: read anthill source skill(s) + references → rewrite `templates/<NN-slug>/prompt.md` with equivalent depth → update `templates/<NN-slug>/schema.md` with `required_files` (or `required_glob`) YAML block → port relevant references to `templates/<NN-slug>/references/` (strip `.anthill/` runtime refs; replace anthill-route/halt protocols with `product_step_submit` validation errors). Visual steps (2, 6, 7, 13) additionally encode Layer 2 critique-section requirements in schema + Layer 3 human-checkpoint instructions in prompt.

- [x] 10. **Step 1 — ideation port** (`anthill-product-ideator`). Single-artifact `04-concept-brief.md`; content depth increases (hook, target audience, differentiation, risks, validation_mode extraction). No HTML, no extra_files. References: founder-interview discipline, concept-brief examples.

- [ ] 11. **Step 2 — prototype port** (`anthill-prototype` html-mockup mode). **HIGHEST PRIORITY VISUAL STEP.** Required_files: `direction-a.html`, `direction-b.html`, `direction-c.html`, `compare.html`, `REPORT.md`. References: `visual-constraints.md`, `a11y-checklist.md`, `design-fidelity-checklist.md`, `anti-patterns.md`, `examples.md`, `od-bridge.md` (HTML-mockup pipeline). Layer 2: REPORT must contain `5-dimension critique` per direction + `Recommendation` section. Layer 3: prompt instructs `surface file:// URLs + await user confirmation`. Strip anthill's `--mode=stack-native` branch (out-of-scope per spec).

- [x] 12. **Step 3 — spec port** (`anthill-feature-refiner` + `anthill-spec`). Required_files: `functional-spec.md` (min 15 KB), `architecture.md`, AND one of `architecture.html` or `architecture.json`. References: `functional-spec-template.md`, `architecture-shape.md` (multi-artifact patterns; how `.md`/`.html`/`.json` stay in sync via derivation chain).

- [x] 13. **Step 4 — ux-testing port** (`anthill-ux-audit`). Single-artifact `validation-report.md`; richer content (heuristic scoring, observation log, recommendation). References: confirm whether anthill has `references/` for ux-audit — if light, omit references subdir.

- [ ] 14. **Step 5 — brand port** (`anthill-brand-designer`). Single-artifact `brand-book.md` with multi-section depth (voice samples ON+OFF brand, motion principles, imagery posture, anti-patterns). References: voice-samples corpus, anti-patterns gallery.

- [ ] 15. **Step 6 — design-system port** (`anthill-design-system` + `anthill-design-system-lead`). **HIGHEST PRIORITY for downstream steps 7 + 13** (tokens consumed there). Required_files: `tokens.css` (must contain `:root`, `--color-`, `--font-`, `--space-`), `components.md`, `design-system.md`. References: `examples.md` (real shadcn-derived token examples), `anti-patterns.md`, `checklist.md`. Tokens.css must be CSS-valid and importable into HTML files in step 7/13.

- [ ] 16. **Step 7 — prototype-v2 port** (`anthill-prototype` re-invoked + step 6 token mapping). **VISUAL STEP.** Required_files: `direction-final.html` + `screens/*.html` (4-8 screens of killer flow; brand+tokens applied). References: `token-mapping.md` (how step 6 tokens land in HTML), `design-fidelity-checklist.md` (Layer 2 scoring rubric vs. step 6). Layer 2: REPORT contains `design-fidelity score` per screen. Layer 3: same as step 2 (file:// URLs + user confirmation).

- [ ] 17. **Step 8 — PRD port** (`anthill-prd`). **Must establish user-story ID convention** (consumed by step 13's PRD-coverage scoring). Single-artifact `prd.md` with sections: user stories (each with stable ID `US-NN`), scope cuts, success metrics, must-haves vs. nice-to-haves. References: prd-format.md (user-story ID convention), scope-cut-discipline.md.

- [ ] 18. **Step 9 — system-design port** (`anthill-system-design-bridge` + `anthill-principal-engineer`). Required_files: `system-design.md` (min 20 KB), one of `architecture.json` / `architecture.html`, `security.md` (or security block in system-design with OWASP/threat-model). References: `architecture-shape.md`, `security-section.md`, `scale-assumptions.md`.

- [ ] 19. **Step 10 — cost-estimate port** (`anthill-fpa` or `anthill-bizops-analyst` — pick richer one during port). Single-artifact `cost-estimate.md` with build cost + run cost + unit economics + sensitivity analysis. References: if anthill skill is light, skip references subdir.

- [ ] 20. **Step 11 — roadmap port** (`anthill-roadmap` + `anthill-roadmap-bridge`). Single-artifact `roadmap.md` with phases, milestones, dependencies, risks, buffer. References: phasing-discipline.md, milestone-format.md.

- [ ] 21. **Step 12 — legal port** (`anthill-corporate-counsel` + `anthill-privacy-dpo` + `anthill-ip-counsel`). Single-artifact `legal-posture.md` with multi-section coverage (terms posture, privacy, data handling, licensing, regulated aspects, AI-specific section reserved for future). References: regulated-aspects-checklist.md, sub-processors-template.md.

- [ ] 22. **Step 13 — prototype-v3 NEW** (synthesis from anthill-prototype + anthill-prd + anthill-design-system). **NEW STEP; depends on steps 5, 6, 8 templates being ported first.** Required_glob: `screens/[0-9]+-*.html` with `min_count: 8`, `per_match_min_size: 8192`, `per_match_contains: ["<html", "<style"]`. Required_files: `screen-atlas.md`, `REPORT.md`. Optional: `flow.html`. References: `screen-atlas-format.md`, `states-coverage.md` (loading/empty/error/disabled/success matrix), `prd-coverage-rubric.md` (how to map user-story IDs from step 8 to screens). Layer 2: REPORT contains `PRD coverage X/Y`, `Design fidelity score per screen`, `States coverage matrix`. Layer 3: prompt instructs `surface screen-atlas.md as navigable index + await user walkthrough confirmation before product_advance`.

## Phase C — Docs + decisions

- [ ] 23. **Decide dogfood product slug.** Options: (a) re-Linear-clone (apples-to-apples regression against `/home/goat/linear-clone-poc/`), (b) fresh product (avoid bias from agent memorizing prior decisions). Recommend (a) for direct volume comparison; document choice in spec.md context section before Phase D starts.

- [ ] 24. **Update `packages/mcp-product-pipeline/README.md`** — 13-step pipeline diagram, per-step artifact bundles table (mirror plan.md mapping), 3-layer quality discipline section, screen-atlas as `/sdd` handoff visual contract, `extra_files` shape documented with example, references map documented.

- [ ] 25. **Update `.mcp.json.example`** — header note acknowledges 13 steps (cosmetic; spec 025 said 12).

## Phase D — End-to-end dogfood validation

Activates the MCP in the chosen dogfood dir; walks 1 → 13 producing the full bundle; measures against acceptance criteria.

- [ ] 26. **Activate MCP + cold-start pipeline** in the chosen dogfood dir. `product_start(<slug>)`, confirm `.state.json` initialized at `{current_step:1, phase:"discovery", completed:[], gates_passed:[]}`.

- [ ] 27. **Walk steps 1 → 12** with the new templates. For each visual step (2, 6, 7): submit via `extra_files`, verify Layer 1 passes, observe Layer 3 prompt surfacing file:// URLs, mark advance only after explicit (simulated or real) user confirmation. Pass discovery + identity + specification gates at the appropriate points.

- [ ] 28. **Walk step 13** — synthesis from prior 12 outputs. Verify screen-atlas.md generated with one row per PRD user-story; `screens/*.html` count ≥ 8; REPORT.md contains PRD-coverage scorecard mapping user-story IDs to screens.

- [ ] 29. **Verify `product_done` after step 13** — fires automatically on `product_advance`; emitted message points engineering at `13-prototype-v3/<slug>/screen-atlas.md` as visual contract, recommends `/sdd new <slug>`.

- [ ] 30. **Measure artifact volume** — `du -sh docs/product/`; total must be ≥ 285 KB. Per-step breakdown captured. If a step is anomalously small, audit the template prompt — usually a missing reference or stripped checklist.

- [ ] 31. **Ship dogfood evidence** — copy artifacts (or summary if hosted in separate dir) to `docs/specs/026-mcp-pipeline-deep-port/dogfood/`. README in that dir explains: chosen slug, total volume vs. baseline, sample HTML screenshots, summary of Layer 2 critique blocks observed, sample of Layer 3 human-checkpoint interaction.

## Verification

Each item maps to a spec.md acceptance scenario; check off only when the scenario can be answered yes with reference to concrete evidence (file path, test output, dogfood artifact).

- [ ] V1. **Step 2 produces 3 HTMLs + critique + visual checkpoint** — dogfood artifact under `02-prototype/<slug>/` shows all 4 files; REPORT.md has `5-dimension critique` section; conversation log shows Layer 3 prompt.

- [ ] V2. **Step 6 produces real tokens + components** — `tokens.css` exists, valid CSS, contains `:root`/`--color-`/`--font-`/`--space-` (verified by `grep`); `components.md` has per-component variant table.

- [ ] V3. **Step 7 re-renders HTML with brand+tokens** — `direction-final.html` exists; opens in browser; references step 6 tokens; copy matches step 5 brand voice (manual visual check).

- [ ] V4. **Step 3 multi-artifact bundle** — `functional-spec.md` ≥ 15 KB; `architecture.md` exists; `architecture.html` or `architecture.json` exists.

- [ ] V5. **Step 9 architecture bundle** — `system-design.md` ≥ 20 KB; architecture file (`.json` or `.html`) exists; security content present.

- [ ] V6. **Step 13 screen atlas** — `screen-atlas.md` exists; `screens/*.html` count ≥ 8; REPORT.md has PRD-coverage scorecard with mapped user-story IDs.

- [ ] V7. **Re-dogfood volume ≥ 5x baseline** — `du -sh docs/product/` ≥ 285 KB; per-step measurements documented in dogfood/README.md.

- [ ] V8. **3-layer quality on every visual step** — for steps 2, 6, 7, 13: floor (Layer 1) validated by test suite; critique blocks (Layer 2) verified in dogfood artifacts; human checkpoint (Layer 3) verified in conversation transcript.

- [ ] V9. **extra_files persists atomically** — `tests/extra-files.test.ts` green; manual smoke: rejected submit leaves zero files on disk.

- [ ] V10. **Spec 025 plumbing preserved** — all 31 prior tests pass green; `product_step_submit` signature is `(N, content, extra_files?)`; `STEPS.length` is 13; `GATE_AFTER` is `[4, 7, 12]`; `.state.json` schema unchanged (snapshot diff).

- [ ] V11. **Per-step references shipped** — `product_step_get(2)` response contains `references` map with all anthill-derived reference files; agent never touches package filesystem to access them (confirmed via tool-call trace).

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._

- **Task 12 (step 3 spec port) — shipped.** `templates/03-spec/{prompt.md,schema.md}` rewritten + 5 references created (`functional-spec-template.md`, `architecture-shape.md`, `anti-patterns.md`, `checklist.md`, `examples.md` — plan named only the first two; added the other three to match the 01-ideation port shape). Synthesis of `anthill-spec` (pages→components→interactions→states→nav-map + `## Decisions Pending` handoff table) and `anthill-feature-refiner` (per-feature depth + architecture section + Gherkin acceptance scenarios). 3-artifact bundle: `functional-spec.md` (≥15 KB, primary) + `architecture.md` (≥4 KB, extra_file) + one of `architecture.html`/`architecture.json` (extra_file). Architecture artifacts are *derived from* functional-spec.md (derivation chain documented in `architecture-shape.md`); `architecture.md` is the *preliminary* skeleton, step 9 deepens it (the step-3/step-9 boundary is tabled in the reference + the prompt's "What this step does NOT do"). `bun tsc --noEmit` clean, 109 tests pass, `getTemplate(3)` + `validateLayer1` smoke-tested (pass bundle / json variant / missing-diagram / undersized-spec all behave correctly).
- **Glob gotcha (`required_glob` "one of" pattern).** Expressing "one of `architecture.html` / `architecture.json`" needs `architecture.[hj][a-z]*`, NOT `architecture.[hj]*`. `globToRegExp` treats a `*` immediately after a `]` as a char-class quantifier (the `[0-9]+` feature), not a wildcard — `[hj]*` compiles to `[hj]*` (zero+ of h/j) and matches nothing useful. The trailing `[a-z]*` is the actual wildcard. Documented inline in `schema.md`.
- **Task 11 (step 2) checkbox is stale** — SESSION.md confirms step 2 shipped (4 iterations + the spec-027 OD retrofit); the `[ ]` was never flipped. Left as-is here — full closure is arguably Phase-D-gated like the other visual steps.
- **Task 13 (step 4 ux-testing port) — shipped.** `templates/04-ux-testing/{prompt.md,schema.md}` rewritten + 5 references created (`heuristics.md`, `report-template.md`, `anti-patterns.md`, `checklist.md`, `examples.md`). Synthesis: `anthill-ux-audit` (Nielsen's 10 heuristics + WCAG 2.1 AA review + severity-1–4 findings table + strengths discipline) becomes the always-on **expert audit spine**; Agent0's pre-port `validation_mode` three-mode posture (`tested`/`intuition`/`not-applicable`) is preserved as the layer declaring *user-level* validation on top. Key reframe: the heuristic audit runs for *every* mode — `not-applicable` (CLI/API) gets heuristics adapted to terminal UX, it is no longer "skip the audit". Single artifact `validation-report.md`, 10 required H2 sections (was 4). **Small positive deviation:** added a `required_files` Layer 1 block (`min_size: 8192` + `contains` anchors including `validation_mode:`) — the plan didn't specify one for step 4, but it (a) enforces the "categorically richer" mandate mechanically and (b) closes a real latent gap: the pre-port template only *extracted* the `validation_mode:` line, never *enforced* its presence. anthill-ux-audit DID have a `references/` dir (3 small files) — ported + augmented rather than omitted, consistent with the 01-ideation / 03-spec ports. `bun tsc --noEmit` clean, 109 tests pass, `getTemplate(4)` + `validateLayer1` smoke-tested.

- **Dogfood-driven corrections (tasks 11+12+13) — 3 prompt-level guidance gaps closed.** A pointed dogfood against `/home/goat/linear-clone-poc/` produced real step-3 + step-4 artifacts (passed Layer 1 + section check) and surfaced three guidance gaps that mechanical validation could not catch. All three fixed in this session:
  - **Gap A — `03-spec/prompt.md` § "Identify pages & surfaces"** — added a "Scale depth to surface importance" paragraph licensing tiered depth (full treatment on killer-flow surfaces, compact treatment on trivial onboarding micro-pages / single-form settings sub-pages). Pre-fix, a by-the-book agent producing a 12-surface spec either bloated trivia or felt off-template when cutting. Schema enforces *presence*, not parity — now stated explicitly.
  - **Gap B — `04-ux-testing/prompt.md` § "Run the accessibility review"** — split the audit method into two cases: (i) step 2 is HTML (deep-port norm) → audit is *measurable* (open file, contrast checker, tab through, observe focus), `warn` reserved for borderline measurements only; (ii) step 2 is a markdown spec (pre-deep-port or specs-only product class) → audit is *projected*, every render-dependent check becomes a `warn` with a one-line rationale, each `warn` phrased as a tracked handoff into step 6/7. Closes the latent false-confidence failure of auditing-a-spec-as-if-it-were-HTML.
  - **Gap C — `02-prototype/prompt.md`** — biggest change. The pre-fix Turn-1 flow implied a single Producer producing 3 directions sequentially; the spec-027 dogfood found that pattern empirically converges directions (the "2 of 3 dark-canvas" finding). Edits: (1) frontmatter `delegation_hint` updated to cover both Turn-1 directions and Turn-2 screens as delegable shapes; (2) Mode section rewritten to describe Turn-1 as parent-attributes-angles + dispatches-3-parallel-sub-agents + composes-cross-cutting; (3) **new § 3.5 Fan-out** prescribing the 3-parallel-with-pre-attributed-angles pattern, including the 5-field brief template per direction, the `model: opus` requirement, the dispatch-in-same-response rule, the "promote honest partial-fit + brief-specified-accent disclosure" discipline (a positive emergent property from the dogfood), and the no-Agent-tool fallback; (4) bridge paragraph at start of § 4 clarifying that the per-direction build rules apply *per sub-agent*, not parent-runs-them-all. Fan-out pattern empirically validated in this session's dogfood — 3 categorically distinct directions (Cool Brutalist / Warm Humanist / Editorial Minimalist) produced concurrently, zero axis-convergence. Sub-agents also disclosed partial-DS-fits and brief-specified accents honestly, in artifacts and in their reports back to the parent.
  - **Methodology note** — the dogfood deliberately tested-the-fix in real-time: Gap C was both *surfaced* and *empirically validated* by the same fan-out run. `bun tsc --noEmit` clean, 109 tests pass, `getTemplate(2|3|4)` all parse with the edited prompts. Dogfood artifacts kept in `/tmp/bench/026-dogfood-step2/` (wipe-able per SESSION.md convention) — they are the empirical evidence for Gap C's fix and the next-up input for re-dogfooding step 3 + step 4 against real HTML (the remaining open work).

- **Gap D — Turn-2 screen count was hardcoded at 8, now product-calibrated.** Surfaced by the user during the post-Turn-2 dogfood review: "8 telas está cravado estaticamente no nosso pipeline?". Audit found `8` hardcoded in 8 places across `02-prototype/{schema.md,prompt.md}` — the schema's `required_glob.min_count: 8` (Layer 1 gate), the frontmatter `delegation_hint`, the Goal line, the Mode-section Turn-2 description, the Output-files entry, § 7's REPORT structure, § 8's user-pick checkpoint message, and § 9's entire body + closing lines. The "8" came from the spec 026 plan as a SMB-SaaS convention, never empirically derived; it inflates micro-products / CLI tools (would need to invent 4-5 fake screens to clear the floor) and subdimensions venture-scale marketplaces (10-15 is the real range). Linear-Clone's 12 functional-spec surfaces vs. 8 rendered is itself evidence — 4 surfaces (Sign Up, Onboarding-Team, Cycle/Sprint, Roadmap) were silently dropped to fit the cap.
  - **Fix (Option D — soft floor + agent calibration):** schema floor dropped to `min_count: 3` as universal sanity (1-2 screens is "I didn't try"; 3 covers a minimal product). All 8 hardcoded references in `prompt.md` replaced with `N` calibrated per product class. `prompt.md` § 9 rewritten with: (a) a calibration table mapping `concept brief § Identity · Scale` → typical N (Micro 3-5 / Mobile 4-7 / Dev Tool 4-8 / SMB SaaS 6-10 / Venture 10-15), (b) a 5-step procedure for deriving N (enumerate surfaces → triage into killer-flow/supporting/edge-state buckets → sum → cross-check table → confirm with user), (c) two contrasting example lists (SMB SaaS N=8 + Micro N=4), (d) explicit "**confirm with user before writing**" instruction. The `## Turn 2 Plan` section in REPORT now opens with a one-line N-rationale. Section heading renamed `## Turn 2 — Hi-Fi Screens` (count-agnostic); schema's slug accepts both `turn-2-hi-fi-screens` and the historical `turn-2-8-screens-hi-fi` for backwards-compat.
  - **Validation:** `bun tsc --noEmit` clean, 109 tests pass, current 8-screen Linear-Clone dogfood bundle still validates against the new `min_count: 3` floor (8 ≥ 3, trivially). The fix preserves backwards-compatibility with all prior step-2 submissions while removing the over-prescriptive ceiling.
  - **Why this matters as a meta-finding:** Gap D was caught by the user's critical reading of the pipeline, not by mechanical dogfooding — a different failure mode than A/B/C (which the dogfood execution itself surfaced). It's the kind of design over-prescription that hides until you ask "why exactly this number?". Pattern to apply going forward on each step ported in Phase B (especially the visual + multi-artifact steps 6, 7, 13): audit every hardcoded number/count and ask whether it should be product-calibrated.
