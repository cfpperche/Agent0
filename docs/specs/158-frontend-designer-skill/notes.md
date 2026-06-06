# 158 — frontend-designer-skill — notes

_In-flight design memory. Append-only by convention._

## Design decisions

### 2026-06-05 — parent — Deterministic mechanics vs prompt-driven craft
Split the skill: `scripts/frontend-designer.sh` owns the testable, repeatable parts (caps/detect/artifacts-dir/scaffold-docs/verify); the craft (taste, code, design judgment) is prompt-driven in SKILL.md + references. Keeps the agent free to be the "artist" while detection/paths/verify stay drift-free and unit-tested (20/20).

### 2026-06-05 — parent — verify is a fail-closed thin wrapper, not a new gate
`verify` shells `agent-browser.sh verify-contract` (spec 155) and fail-closes (rc 4, BLOCKER) when `agent-browser route` ≠ primary. No new acceptance machinery — done-proof is spec 155 verbatim. `FD_AGENT_BROWSER` env override makes fail-closed testable with a stub.

## Deviations

_(none — built as planned.)_

## Tradeoffs

### 2026-06-05 — parent — design docs into the target repo (git-tracked)
Chose to write `reference-research.md` + `design-direction.md` into the target project (SDD spec dir or `docs/design/<surface>/`), git-tracked, over a gitignored scratch area. They are decision records, not throwaway. Screenshots/reports stay gitignored evidence. Codex's pressure-test confirmed this for refine mode too (value is grounded judgment, not just CSS edits).

## Open questions

### 2026-06-05 → RESOLVED 2026-06-06 — parent — does `explore` mode earn its place?
`explore` (research + direction, no code) was spec'd narrow and not exercised in the first dogfood. **Resolved by dogfood E** (`/tmp/fd-demo-e`, a personal-finance home with an undecided audience): **KEEP, narrowed.** Findings: explore produced 2–3 distinct directions (Calm Trust / Warm Progress / Pro Cockpit) + tradeoffs + a recommendation + an explicit decision gate, with **zero code** — a deliverable genuinely different from `create` (which researches *one* direction then codes). It earns its place *only* when (a) multiple directions are viable AND (b) a human must choose before code; otherwise it collapses into `create`'s research phase (the predicted risk is real, so the narrow scope is load-bearing). Refinement applied: SKILL.md + `frontend-designer.md` now state explore's defining shape is the **multi-direction decision gate**, not a code-less `create`, with an explicit "if direction is already implicit, use `create`" guard.

## Dogfood outcome (2026-06-05)

Six `/tmp` demos, all proven (summary: `/tmp/FD-DOGFOOD-SUMMARY.md`). A/B/C cover the required capability matrix; D/E/F are founder-added (creativity / explore mode / animated-3D):
- **A** `fd-demo-a` — create, web, **reused** existing design system → green `verify-contract` 6/6. Output visibly uses the project's `tokens.json` (zero new colors).
- **B** `fd-demo-b` — refine, web → before **FAIL** 3 / after **PASS** 7/7 (interaction tier); bounded diff (only `checkout.html`, all field ids + submit behavior preserved). The drive-and-see loop caught a real accessible-name bug (trailing space from an `aria-hidden` asterisk span) on iteration 1, fixed iteration 2 — concrete evidence the see-and-critique loop works.
- **C** `fd-demo-c` — create, **native** Expo/RN, no DS → proposed tokens; **native-honesty path**: `node --test` 7/7 over pure logic + token invariants (44pt tap target, 8px spacing), **no visual-contract claimed**, no new native tooling added. (A web preview from the same tokens, `fd-demo-c/.evidence/preview.png`, was later produced on request — explicitly NOT the native runtime.)
- **D** `fd-demo-d` — create, web, no DS → **proposed a full brand system** for "Patudo" (fictional largest Brazilian pet-shop chain): coral/teal/sun palette, Poppins+Nunito, complete conversion landing (hero/stats/services/Clube/testimonials/app/footer). Green `verify-contract` 6/6. Proves the skill handles **brand/marketing craft**, not just app/dashboard UI. Founder-requested ("use a criatividade").
- **E** `fd-demo-e` — **explore**, personal-finance home, undecided audience → 3 distinct directions (Calm Trust / Warm Progress / Pro Cockpit) + tradeoffs + recommendation + decision gate, **zero code** (verified: no html/tsx/css produced). Resolved the spec's open question (KEEP explore, narrowed). Founder-requested, to test whether explore earns its place.
- **F** `fd-demo-f` — create, web, no DS → **animated WebGL hero** (Three.js 0.160 via CDN, rotating icosahedron). Tests the skill on **motion/3D**. Findings: (1) Three.js fits detect-don't-impose (free, local+remote) and WebGL renders in agent-browser's headless Chrome; (2) `verify-contract` PASS 6/6 on the **semantic+interaction surface** (heading/CTAs/click/console) but **cannot assert the canvas** — a painting WebGL canvas is not in the a11y tree (correct browser behavior), so it was marked `aria-hidden` (decorative; meaning carried by the `<h1>`); (3) render+motion proven **programmatically** (eval: `hasWebGL:true`, frames 189→293 ≈69fps, rotY 1.134→1.758) — labeled build/runtime evidence, **not** visual-contract proof of motion fidelity. The drive-and-see loop also surfaced an **accessibility refinement live with the founder**: the scene respected `prefers-reduced-motion` and started static on the founder's machine (reduce-motion ON) → added an explicit Play/Pause control (aria-pressed) so motion is opt-in for reduced-motion users yet visible to everyone — the correct accessible-motion pattern. Confirms the earlier honesty claim: the skill **builds** Three.js/GSAP UI; motion-fidelity proof is out of the spec-155 gate (a new gate would be rule-of-three-gated).

All acceptance scenarios in `spec.md` satisfied; `/skill validate` exit 0; doctor 18 ok. The dogfood demos live in `/tmp` (not versioned) — proof artifacts, not shipped code.

### 2026-06-06 — parent — animated/3D surfaces: proof boundary (from dogfood F)
For motion/3D UI the spec-155 gate proves the **semantic + interaction surface** (and, programmatically via `eval`, that the scene renders+animates), but **not motion fidelity** (no pixel/frame diff). A live WebGL `<canvas>` is invisible to the a11y tree while painting, so it is treated as decorative (`aria-hidden`) with meaning carried by real text — assert text/controls, not the canvas. Same honesty posture as the native-only path (demo C): build it, show evidence, label what is and isn't contract-verified. Animation libs (Three.js/GSAP/Framer Motion/Lottie/…) are detect-don't-impose, added only when the researched direction calls for motion. A dedicated "motion gate" stays deferred behind the rule-of-three demand test.
