---
meeting: frontend-designer-skill-design
topic: "Design of the Agent0 frontend-designer skill: a frontend 'artist' that researches references, uses product-domain context + the project design system, works across web/mobile/desktop, picks free local+remote tool deps, and integrates with product/visual-contract/agent-browser/image"
created: 2026-06-06T01:30:48Z
convener: claude
mode: human-orchestrated
roster: claude,codex,human
rotation: claude,codex
tier: decision-grade
blind_phase: revealed
turn_counter: 4
next_speaker: claude
synthesis: accepted
---

# Meeting: Design of the Agent0 frontend-designer skill: a frontend 'artist' that researches references, uses product-domain context + the project design system, works across web/mobile/desktop, picks free local+remote tool deps, and integrates with product/visual-contract/agent-browser/image

_A multi-party, multi-model deliberation. The front-matter above is the machine-readable state: `roster` is every participant id, `rotation` is the deterministic **fallback order** of model participants (human excluded), `next_speaker` is the **derived default** speaker (set by a turn's trailing `Next: <id>` directive; not enforced legality), `turn_counter` counts written turns, `synthesis` tracks the close-out. Speaker selection is context-driven: a turn may end with an explicit `Next: <roster-id>` line to hand the floor; otherwise the human directs with `--speaker`. The body below is the chronological transcript._

## Participants

- claude — Claude Code (web: allowed)
- codex — Codex CLI (web: allowed)
- human — founder (web: n/a)

## Transcript

_Turns are appended below in order. Each turn header is `### Turn N — <runtime> (<id>)`; a research-backed turn carries a `Sources:` block listing the URLs used. A turn may end with a single trailing `Next: <roster-id>` line to hand the floor to a specific participant (the directive stays visible here; it sets the default next speaker)._

## Blind submissions (commit/reveal)

_Commitments recorded before any opening is revealed — de-anchors round 1 (spec 149)._

- commit claude — `sha256:ebf23053ec1a2e56` (3947 bytes)
- commit codex — `sha256:075721a2124b4b6b` (4240 bytes)

### Turn 1 — claude (blind opening) (claude)

**Claude — blind opening.**

**Framing.** Agent0 already has two adjacent UI capacities: `/product` (docs-first planning → generates a *design system doc* + a *visual contract* mood/atlas, but explicitly **does not** produce a runnable app) and the **visual-contract acceptance gate** (spec 155 — proves a built UI works by *driving* it). The unfilled gap between them is **implementation craft**: the agent that, given a product domain and an (optional) design system, actually *designs and builds the real screens with taste*, then refines them. `frontend-designer` should fill exactly that gap — not re-do `/product`'s planning, not replace the acceptance gate, but be the **craft loop** that turns intent + tokens into good-looking, working frontend code.

**My position on the load-bearing questions:**

1. **New skill, not a `/product` mode.** `/product` is idea→spec planning; `frontend-designer` is the build-time artisan. Distinct lifecycles, distinct invocation. But it must *consume* `/product` output when present (design-system doc, brand, fixture-spec) rather than regenerate it.

2. **It produces runnable frontend code**, scoped to UI surfaces (screens/components/flows), not full backend scaffolding. "Create or refine a frontend" is the verb. Refine mode (operate on an existing codebase's UI) is as important as greenfield.

3. **Detect-and-adapt on stack, never impose** (repo rule: no shipped stack opinions). The skill detects the project's framework (React/Vue/Svelte/Expo/Tauri/plain HTML) and design system (Tailwind config, tokens, shadcn/Radix, `/product`'s DS doc); if none exists it *proposes* a minimal token set at a contract gate, it does not freeze a default. Cross-platform = adapt to what's there, not ship N templates.

4. **The "artist" is a loop, not a one-shot generator:** research references → establish a design direction (tokens/mood grounded in the domain) → implement → **drive the UI to see it** → critique against the references → refine. Taste comes from the *grounding + the see-and-critique iteration*, not from a persona prompt (repo rule: no persona/role-prompting; this is context-engineering).

5. **Reference research must be real, free, local+remote.** Two free mechanisms already in-repo or trivially available: **web search** (design patterns, component conventions, accessibility norms for the domain) and **`agent-browser.sh`** (the native Rust CLI, spec 152/153) to *actually visit and screenshot exemplar sites/patterns* and to drive our own rendered output. No paid dep is required; `/image` (fal) stays an optional mood-board upgrade, never a hard dep.

6. **"Done" reuses the visual-contract gate.** The skill declares `UI impact: render|interaction|flow` and its output is proven by a passing `agent-browser.sh verify-contract` report — no new acceptance machinery. This is the anti-drift anchor.

**Dependency stance:** minimal and detect-don't-impose. Hard deps: `agent-browser` (already here) + web. Soft/detected: the project's own framework + DS, plus free, universally-installable, local+remote tools — token tooling (Style Dictionary), Google Fonts/Fontsource, an open-licensed icon set (lucide), a local dev/preview server (vite or the project's). All free, all run local and remote.

**Rubric for judging the design (decision-grade):** (a) fills a *real* gap vs `/product`/visual-contract, no overlap; (b) reference research is real + free + local+remote, not speculative tooling (rule-of-three demand test); (c) zero frozen stack opinions; (d) "done" provable via the existing visual-contract gate; (e) dependency footprint minimal + justified; (f) greenfield **and** refine both first-class.

**Risks I'm watching:** scope creep into `/product` (planning) or into a full app generator; harness-drift via a bespoke "design dashboard"/reference-cache nobody asked for; smuggling stack defaults in through "sensible starter templates."

Next: codex


### Turn 2 — codex (blind opening) (codex)

Codex opening position:

1. **Scope & Boundaries**
`frontend-designer` should be a new skill, not a `/product` mode. If it only emits mood boards, screen atlases, tokens, or fixture specs, it is redundant with `/product`. `/product` deliberately produces a docs-first foundation and design-time visual contract, then hands off to SDD. Spec 155 deliberately proves the built UI later by driving it.

The unfilled gap is the design-aware implementation pass: taking product/domain context, references, existing design-system constraints, and a target platform, then producing or refining runnable frontend UI with evidence. It should live between `/product` and the visual-contract gate, or inside an SDD implementation task.

2. **Runnable Code vs Designs**
It should emit runnable frontend code when the task is implementation or refinement. Greenfield means “create a runnable UI slice/prototype in the selected stack,” not “generate an entire product.” Refine-existing means “modify the current app in its current stack.” If the user only wants exploration, it can emit design artifacts, but that is a secondary mode and should be named plainly.

3. **Stack Stance**
Agent0 must not ship stack opinions. The skill’s stack ladder should be:

- existing project stack and design system win;
- `/product` system-design stack wins if present;
- explicit user platform/stack hint wins next;
- otherwise research current canonical options and ask or record an open decision before code;
- never consume an Agent0-bundled app skeleton or frozen default.

Dogfood demos in `/tmp` may choose stacks for testing, but those are test fixtures, not shipped defaults.

4. **Reference Research**
Make research mandatory and artifacted. The skill should write a `reference-research.md` or equivalent with: source URL/path, product-domain relevance, pattern borrowed, pattern rejected, and implementation consequence.

Mechanism:

- web search/fetch for public references, official platform conventions, accessibility guidance, and current setup docs;
- `bash .agent0/tools/agent-browser.sh run -- open/snapshot/screenshot ...` for visiting exemplars and capturing rendered evidence when available;
- `agent-browser.sh audit` or screenshots for our own output;
- local repo scan via `rg` for tokens, component libraries, Storybook/Ladle, app routes, existing UI primitives, brand docs, `/product` artifacts, and SDD specs.

No paid tool should be required. Figma, Playwright, Storybook, simulators, or platform screenshot tools are detect-and-use only.

5. **Done Proof**
Reuse spec 155. Do not invent a new “design quality gate” yet. For browser-renderable output, done requires `UI impact: render|interaction|flow` plus `agent-browser.sh verify-contract` and a green `report.json`.

For mobile/desktop/native-only surfaces, be honest: use a project-provided browser-renderable harness if it exists, such as Expo web, Storybook, a web preview, or an existing screenshot/test command. If none exists, the skill may ship code plus native build/test evidence, but it must not claim visual-contract proof. New native visual tooling needs rule-of-three dogfood evidence first.

6. **Dependency Footprint**
Hard deps should stay tiny: shell, `rg`, `jq` where needed, existing project package manager, and Agent0’s `agent-browser.sh` for browser visual proof. `agent-browser` can be opt-in at machine level, but absence is not a pass.

Detect-don’t-impose: Next, Vite, Expo, React Native, Tauri, Electron, Tailwind, shadcn, Storybook, Playwright, platform simulators, Figma, icon packs. Add libraries only when the project stack or researched plan justifies them.

7. **Decision Rubric**
I would judge the final design by:

- it does not reopen `/product` runnable-app generation;
- every design pass has cited reference research;
- existing design systems are used before invention;
- stack choice is project-derived or explicitly decided, never hidden;
- runnable output is verified by the existing visual-contract path where possible;
- unsupported native proof is labeled, not papered over;
- 3 `/tmp` dogfoods cover greenfield, refine-existing, and no-design-system fallback without adding speculative harness machinery.

Next: claude
## Claim/evidence ledger

_Convergence GATE: a point with only `assertion-only` claims is NOT resolved, regardless of agreement (spec 149)._

| claim | tag | anchor |
| --- | --- | --- |
| agent-browser unavailable = BLOCKER for browser visual proof, never a pass (spec 155 advisory precedent: unavailable != pass) | supported | path:.agent0/tools/agent-browser.sh |
| repo rule no-shipped-stack-opinions: frontend-designer must detect-and-adapt stack via a project-derived ladder, never freeze defaults | supported | path:.agent0/context/rules/runtime-capabilities.md |
| agent-browser.sh is the in-repo free local browser primitive for reference screenshots + driving our own output | supported | path:.agent0/tools/agent-browser.sh |
| spec 155 proves built UI by DRIVING it (agent-browser verify-contract to report.json); reuse as frontend-designer done-proof, not a new gate | supported | path:.agent0/context/rules/visual-contract.md |
| /product is docs-first planning + design-time visual contract and does NOT generate a runnable app — leaves an implementation-craft gap | supported | path:.claude/skills/product/SKILL.md |

### Turn 3 — Claude Code (claude)

**Claude — convergence + decisions.**

Strong convergence with codex. Both openings independently landed on: new skill (not a `/product` mode), it emits *runnable* UI for create/refine, detect-don't-impose on stack, mandatory reference research, and reuse spec 155 for done-proof. I'm adopting codex's two sharpest additions wholesale: the **artifacted `reference-research.md`** (source · domain relevance · pattern borrowed · pattern rejected · implementation consequence) and the **native-surface honesty rule** (no false visual-contract claims for native-only surfaces; new native visual tooling needs rule-of-three first). Anchored convergence is in the ledger (all four claims path-verified).

Locking these **decisions**:

- **D1 Identity.** New skill `frontend-designer` — the build-time *craft loop* sitting between `/product` (planning) and the spec-155 gate (acceptance). Invokable standalone **and** referenceable from an SDD implementation task. It never reopens `/product` runnable-app generation.
- **D2 Modes.** `create` (greenfield UI slice in the selected stack) and `refine` (modify existing app UI in its stack) are primary; `explore` (design artifacts only — direction + references, no code) is a plainly-named secondary mode.
- **D3 Stack ladder** (codex's, verbatim): existing project stack+DS → `/product` system-design stack → explicit user hint → research canonical options + **record an open decision / ask** before code → *never* a bundled skeleton or frozen default.
- **D4 Reference research = mandatory + artifacted.** Every design pass writes `reference-research.md`. Mechanisms, all free/local+remote: web search/fetch (patterns, platform conventions, a11y, current setup docs) · `agent-browser.sh run` to visit + screenshot exemplars · repo scan (`rg`) for tokens / component libs / Storybook / routes / brand / `/product` artifacts / specs.
- **D5 Design direction.** Before code, a short `design-direction.md` — domain-grounded tokens + chosen references + rationale. **Reuse** `/product`'s design-system doc and the open-design vendor when present; only *propose* tokens when none exist.
- **D6 Done-proof.** Reuse spec 155. Browser-renderable output ⇒ `UI impact: render|interaction|flow` + green `agent-browser verify-contract` `report.json`. Native-only surfaces ⇒ use a project-provided browser-renderable harness (Expo web, Storybook, web preview) if it exists; else ship code + native build/test evidence **labeled honestly** — never claim visual-contract proof, never add new native visual tooling absent rule-of-three.
- **D7 Dependencies.** Hard deps tiny: shell, `rg`, `jq`, the project's package manager, `agent-browser.sh` (machine-opt-in; absence ≠ pass). Everything else (Next/Vite/Expo/RN/Tauri/Electron/Tailwind/shadcn/Storybook/icons/fonts) detect-don't-impose — added only when the project stack or the researched plan justifies. All free, local+remote.
- **D8 The "artist" is a loop, not a persona:** research → design-direction → implement → drive-and-see (`agent-browser`) → critique vs references → refine. Context-engineering, no role-prompting.
- **D9 Portability:** `agentskills-portable` (shell + agent-browser + web; no Claude-only primitive in the core loop).

Two **deltas I'm resolving** that neither opening pinned:

- **Artifact location.** `reference-research.md` + `design-direction.md` are *decision records*, not throwaway — they go **into the target project, git-tracked** (under the SDD spec dir when SDD-driven, else `docs/design/<surface>/`). The `agent-browser` screenshots/reports are evidence → gitignored runtime state. No bespoke "design dashboard"/global reference cache (that would be harness-drift).
- **Dogfood matrix.** The 3 `/tmp` demos map 1:1 to the modes/edges we must prove: (a) **greenfield + existing design system** (web), (b) **refine-existing** UI, (c) **no-design-system fallback** (skill proposes tokens) — on a *different* platform to exercise the native-honesty rule. The web demos must produce a green `verify-contract` report; the non-web one demonstrates the honest-evidence path.

codex — pressure-test this before we synthesize: (1) does the `explore` secondary mode earn its place or is it scope creep? (2) is writing design docs into the target repo right, or should refine-mode stay code-only? (3) anything in the dogfood matrix that fails to *prove* a capability rather than just exercise it? Push where you disagree.

Next: codex


### Turn 4 — Codex CLI (codex)

1. Keep `explore`, but make it narrow and opt-in. It earns v1 if it is only “research + design direction, no code” for pre-SDD or uncertain UI direction. It should not become `/product`-lite, moodboard generation, image work, or a planning pipeline.

2. Git-tracked docs are the right call. `refine` should not be code-only, because the value is grounded design judgment, not just CSS edits. Constraint: write one compact pair per surface, prefer the active SDD spec dir, otherwise `docs/design/<surface>/`; update them only when decisions change.

3. Dogfood proofs:
(a) Greenfield + DS web proves capability only if the fixture has real tokens/components first, and the output visibly reuses them with a green visual-contract report.
(b) Refine-existing proves capability only with before/after evidence, a bounded diff, preserved behavior, and a critique loop that stops on explicit criteria.
(c) Non-web/no-DS is weakest. Without render evidence it only proves honest fallback, not design craft. Make it Expo/Storybook/web-preview if possible; otherwise label it as proving token proposal + native-honesty, not visual acceptance.

4. Spec must nail: exact mode contracts; required inputs/outputs; artifact paths; when to ask vs abort; `agent-browser` unavailable = blocker for browser visual proof, not pass; loop stop criteria; max refinement iterations; native evidence labels; and acceptance criteria per mode.

Next: claude
## Synthesis

_Written when a participant is asked to synthesize. Names the synthesizing runtime, the convergence, recorded disagreements, and a recommended next step (graduate to `/sdd refine` as seed context, or no-op). The human then accepts / redirects / ends._

_Decision-grade tier (spec 149): convergence is gated by the claim/evidence ledger (`meeting.sh ledger-check` — a point with only `assertion-only` claims is UNRESOLVED regardless of agreement), and a **minority report** (any residual objection) is preserved verbatim, never smoothed into consensus._

**Synthesized by:** claude (Claude Code). **Tier:** decision-grade. Ledger: 5 claims, 0 assertion-only, all path-anchored and verified.

### Convergence (what both runtimes independently agreed on, anchored)

`frontend-designer` is a **new skill** — the build-time **craft loop** that sits between `/product` (docs-first planning; does not emit a runnable app — `path:.claude/skills/product/SKILL.md`) and the **spec-155 visual-contract gate** (proves built UI by *driving* it — `path:.agent0/context/rules/visual-contract.md`). It fills the unfilled **implementation-craft gap**: turn product/domain context + references + (optional) existing design system + a target platform into **runnable, good-looking frontend UI with evidence**. It never reopens `/product`'s runnable-app generation and invents no new acceptance gate.

Locked decisions:

- **Modes.** `create` (greenfield UI slice in the selected stack) and `refine` (modify existing app UI in its stack) are primary. `explore` (research + design-direction only, **no code**) is a narrow, opt-in secondary mode for pre-SDD/uncertain direction — explicitly **not** `/product`-lite, moodboards, or image work.
- **Stack ladder (no frozen defaults — `path:.agent0/context/rules/runtime-capabilities.md`).** existing project stack+DS → `/product` system-design stack → explicit user hint → research canonical options + **record an open decision / ask** before code → *never* a bundled skeleton or default.
- **Reference research = mandatory + artifacted.** Every design pass writes a compact `reference-research.md` (source URL/path · domain relevance · pattern borrowed · pattern rejected · implementation consequence). Mechanisms, all free/local+remote: web search/fetch · `agent-browser.sh run` to visit + screenshot exemplars (`path:.agent0/tools/agent-browser.sh`) · repo scan (`rg`) for tokens/components/Storybook/routes/brand/`/product` artifacts/specs.
- **Design direction.** Before code, a compact `design-direction.md` (domain-grounded tokens + chosen references + rationale). **Reuse** `/product`'s design-system doc + the open-design vendor when present; only *propose* tokens when none exist.
- **Artifact location.** The `reference-research.md` + `design-direction.md` pair are git-tracked decision records — one compact pair per surface, in the active SDD spec dir if SDD-driven, else `docs/design/<surface>/`; updated only when decisions change. Screenshots/reports are gitignored runtime evidence. No bespoke design dashboard / global reference cache (that would be harness-drift).
- **Done-proof reuses spec 155.** Browser-renderable output ⇒ `UI impact: render|interaction|flow` + green `agent-browser verify-contract` `report.json`. **`agent-browser` unavailable = BLOCKER for browser visual proof, never a pass.** Native-only surfaces ⇒ use a project-provided browser-renderable harness (Expo web, Storybook, web preview) if it exists; else ship code + native build/test evidence **labeled honestly** — never claim visual-contract proof, never add new native visual tooling absent rule-of-three.
- **Dependencies.** Hard deps tiny: shell, `rg`, `jq`, the project's package manager, `agent-browser.sh` (machine-opt-in). Everything else detect-don't-impose. All free, local+remote.
- **The "artist" is a context-engineered loop, not a persona:** research → design-direction → implement → drive-and-see → critique vs references → refine, stopping on **explicit, declared criteria** with a **max-iteration bound**.
- **Portability:** `agentskills-portable`.
- **Dogfood matrix (must *prove*, not just exercise):** (a) greenfield + DS web — fixture has *real* tokens/components first; output *visibly reuses* them + green report; (b) refine-existing — before/after evidence, bounded diff, preserved behavior, critique loop stopping on explicit criteria; (c) no-DS fallback on a non-web platform — prefer Expo/Storybook/web-preview for render evidence; otherwise labeled as proving token-proposal + native-honesty, **not** visual acceptance.

### Disagreements / minority report

None material — the blind openings converged and the pressure-test produced only operational tightening, all adopted. Residual caution (preserved, not smoothed): **dogfood (c) is the weakest proof** — without browser-renderable render evidence it proves only *honest fallback*, not design craft. The spec must label it as such and not overclaim.

### Recommended next step

**Graduate to a spec** via `/sdd refine`, using this synthesis as seed context. The SDD spec MUST nail (codex's checklist): exact per-mode contracts; required inputs/outputs; artifact paths; when-to-ask vs when-to-abort; `agent-browser`-unavailable = blocker (not pass); refine-loop stop criteria + max iterations; native-evidence honesty labels; and per-mode acceptance criteria.
