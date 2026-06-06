---
meeting: frontend-designer-image-integration
topic: "Integrate /image into /frontend-designer (the artist): narrow, opt-in, draft-only on-brand placeholders for built surfaces — with graceful degradation to neutral placeholder when FAL_KEY is absent OR present-but-no-credits/failed, never brand assets (that is /product), never a hard dep"
created: 2026-06-06T16:04:56Z
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

# Meeting: Integrate /image into /frontend-designer (the artist): narrow, opt-in, draft-only on-brand placeholders for built surfaces — with graceful degradation to neutral placeholder when FAL_KEY is absent OR present-but-no-credits/failed, never brand assets (that is /product), never a hard dep

_A multi-party, multi-model deliberation. The front-matter above is the machine-readable state: `roster` is every participant id, `rotation` is the deterministic **fallback order** of model participants (human excluded), `next_speaker` is the **derived default** speaker (set by a turn's trailing `Next: <id>` directive; not enforced legality), `turn_counter` counts written turns, `synthesis` tracks the close-out. Speaker selection is context-driven: a turn may end with an explicit `Next: <roster-id>` line to hand the floor; otherwise the human directs with `--speaker`. The body below is the chronological transcript._

## Participants

- claude — Claude Code (web: allowed)
- codex — Codex CLI (web: allowed)
- human — founder (web: n/a)

## Transcript

_Turns are appended below in order. Each turn header is `### Turn N — <runtime> (<id>)`; a research-backed turn carries a `Sources:` block listing the URLs used. A turn may end with a single trailing `Next: <roster-id>` line to hand the floor to a specific participant (the directive stays visible here; it sets the default next speaker)._

## Blind submissions (commit/reveal)

_Commitments recorded before any opening is revealed — de-anchors round 1 (spec 149)._

- commit claude — `sha256:b7f6d832fc373908` (3506 bytes)
- commit codex — `sha256:4e03427a6a388736` (3606 bytes)

### Turn 1 — claude (blind opening) (claude)

**Claude — blind opening.**

**Grounding (this is not a from-scratch question — it's backed by a dogfood).** I just proved the demand: regenerated the Patudo landing hero, swapping the emoji 🐶 for a `/image --tier=draft` on-brand illustration (~$0.003, gitignored). The result is dramatically better *and* the spec-155 contract still passes 6/6 (the image is decorative `alt=""`/`aria-hidden`; meaning stays in the text). So the question isn't "should we" but "what are the exact limits."

**My position — integrate, narrow + opt-in. Guidance, not new machinery (`/image` already exists):**

1. **Trigger.** A surface that genuinely needs imagery (hero, empty-state, illustration, og-image, avatar) AND `FAL_KEY` is set AND the account can actually generate → the artist MAY produce an on-brand placeholder via `/image --tier=draft`.
2. **Graceful degradation is the spine (founder directive).** Fall back to a **neutral placeholder** (SVG/CSS/solid/emoji) on ANY of: key absent, **key present but no credits / 402 / quota**, network/timeout, or non-image response. Generation failure must NEVER break the build or the visual contract. The neutral path is the default; `/image` is the enhancement.
3. **draft-only by default.** Cheap (~$0.003), JPEG, gitignored, throwaway. Paid tiers (`brand-*`, $0.04–0.20) require explicit **human confirmation** — the artist never auto-spends at brand-tier.
4. **Hard boundary with `/product`.** `/frontend-designer` generates *disposable placeholders for the surface it's building* — NEVER brand assets (logo, brand photography, the wordmark). Logo/brand = `/product`'s brand phase. If the surface needs a real logo, reference the project's, don't generate one here.
5. **Generated imagery is decorative in the contract.** `alt=""` + `aria-hidden` (or a real `alt` if it conveys content), meaning carried by text — same honesty posture as the WebGL canvas. The image never becomes a contract assertion.
6. **Never a hard dep.** `/image` is fal (paid, remote-only) → it violates the skill's "free + local AND remote" hard-dep floor. It stays an optional upgrade, exactly as the deps section already says. The neutral placeholder is what makes the skill work with zero key/credits/cost.
7. **Cost discipline.** `/image` already prints cost before every call; the artist surfaces it, defaults to one draft image per surface, and records it in the gitignored manifest. No silent fan-out of generations.

**Shape of the change:** a `references/imagery.md` (when/how/limits + the degradation ladder), one step in `craft-loop.md` ("if the surface needs imagery → imagery decision: generate-or-neutral"), a line in SKILL.md, and a `caps`-style check for FAL_KEY presence (note: presence ≠ has-credits — only an attempted generation reveals credits, so the fallback must be at call-time, not just a pre-check).

**Rubric:** (a) neutral path is the default and always works (zero key/credits/cost); (b) every failure mode (absent/no-credits/network) degrades, never breaks; (c) draft-only auto, brand-* human-gated; (d) hard `/product` boundary (no brand assets); (e) generated image decorative, contract unaffected; (f) no new machinery — guidance over `/image`. **Do not regress these (founder directive).**

**Risk I'm watching:** scope creep into brand-asset generation (that's `/product`); silent cost fan-out; treating FAL_KEY presence as "can generate" (the no-credits case the founder flagged — must be a call-time fallback).

Next: codex


### Turn 2 — codex (blind opening) (codex)

Opening — codex

I agree with integrating `/image`, but only as a narrow optional embellishment inside `/frontend-designer`, not as a new design pipeline. One dogfood is not enough under the rule-of-three to justify moodboards, prompt iteration, budget machinery, or generated brand assets. It is enough to justify a small integration with an existing mechanism: one decorative draft image can materially improve a built UI, and fallback keeps the UI shippable.

Exact limit: `/frontend-designer` may use `/image --tier=draft` only after explicit opt-in for that surface. No `brand-text` or `brand-photo` from `frontend-designer`. Durable logos, brand photos, typography-bearing assets, and anything intended to become tracked brand memory stay in `/product` plus explicit standalone `/image`, ideally from a brand contract. `explore` stays no-code and no image-gen; its job is direction choice, not moodboard production.

The generated image must be decorative/progressive enhancement. Meaning remains in real text, controls, labels, and layout. The spec-155 contract should assert the semantic surface, not the bitmap. If the image is absent, failed, gitignored, or visually mediocre, the build and contract still pass with a neutral placeholder. This matters because draft outputs live under gitignored mockup storage; committed UI must not depend on a missing draft asset as a build-critical import.

Degradation ladder should be both pre-check and call-time catch:

1. Default/off: use existing assets or a neutral CSS/SVG/solid placeholder.
2. If image opt-in is present, pre-check only cheap facts: helper exists, `FAL_KEY` is set, required shell tools are present. If not, skip generation and use the placeholder.
3. If `FAL_KEY` is present, attempt exactly one `draft` call. Only the call can reveal no credits, quota, bad key, 402, provider failure, network failure, or timeout.
4. On any non-zero `exec`, stderr containing `HTTP 402`, quota/payment text, curl timeout, malformed response, or download failure is classified as `image-fallback:<reason>`, not as a frontend failure.
5. Record the fallback in `design-direction.md` acceptance/evidence. Standalone `/image` can remain fail-explicit; the graceful behavior belongs in the `/frontend-designer` optional-image wrapper.

Cost discipline: no silent fan-out. One draft attempt per surface invocation, outside the critique loop. No “try three prompts,” no regenerate-on-vibes, no sub-agent loops. The cost estimate still prints before the call, but for autonomous craft work the real guard is the count cap plus explicit opt-in. Any retry, multiple candidate set, or brand-tier call requires a separate human instruction or standalone `/image` invocation.

What I would refuse: making fal a hard dependency of `frontend-designer`; adding image-gen to `explore`; asserting generated image content in the visual contract; importing gitignored draft assets in a way that breaks builds; generating brand/logotype/product-critical assets automatically; adding provider discovery, credit probing, caching, or budget dashboards before three real demands; and prompt-iteration loops where the agent spends money until it “likes” the result.

Decision rubric:

Use integrated draft image only when all are true: `create` or `refine`; user opted in; no suitable existing asset; image is decorative; one attempt is enough; neutral fallback is already implemented; semantic contract does not depend on the bitmap; total cost is visible and capped.

Otherwise: use existing assets, placeholder, `/product`, or standalone `/image`.

Next: claude
## Claim/evidence ledger

_Convergence GATE: a point with only `assertion-only` claims is NOT resolved, regardless of agreement (spec 149)._

| claim | tag | anchor |
| --- | --- | --- |
| the image-fallback wrapper must REDACT stderr (no FAL_KEY/headers/provider payload) before recording image-fallback:<reason> in tracked docs | supported | path:.agent0/context/rules/secrets-scan.md |
| done-proof must be verified with the generated draft DISABLED/missing, so a local successful draft never masks the neutral fallback path | supported | path:.agent0/context/rules/visual-contract.md |
| brand assets (logo/brand photo/wordmark) are /product's brand phase -> frontend-designer must NOT auto-generate brand assets, only disposable draft placeholders | supported | path:.claude/skills/product/SKILL.md |
| /image prints cost before each call + draft tier writes gitignored throwaway JPEG; graceful degradation belongs in the frontend-designer wrapper, /image stays fail-explicit | supported | path:.agent0/skills/image/SKILL.md |
| /image is paid+remote-only (FAL_KEY, fal.run) -> cannot be a hard dep of frontend-designer (free+local-AND-remote floor); stays optional upgrade | supported | path:.agent0/context/rules/image-gen.md |
| dogfood proved demand: /image draft hero (Patudo) beat emoji; verify-contract still PASS 6/6 (image decorative) | supported | path:assets/generated/mockups/2026-06-06-patudo-mascot.jpg |

### Turn 3 — Claude Code (claude)

**Claude — convergence + decisions.**

Near-total convergence. I'm adopting codex's two sharpest additions wholesale:

- **The gitignored-draft-as-build-critical-import hazard.** A draft image lives under gitignored mockup storage, so committed UI must **never hard-import it as a build dependency** (a fresh clone wouldn't have it). Consequence: a generated draft is a *preview/placeholder asset*, and the surface must still render with a **neutral placeholder** when the file is absent. For surfaces meant to be committed, prefer a referenced-but-degrades pattern (CSS background with fallback, `<img onerror>` to neutral, or the neutral SVG by default) over a bare `import hero from './mockup.jpg'`.
- **Graceful degradation lives in the `frontend-designer` wrapper, not in `/image`.** `/image` stays **fail-explicit** (its existing contract — errors loudly on missing key/credits). The artist wraps the single call and classifies any non-zero exec / `HTTP 402` / quota / timeout / malformed response as `image-fallback:<reason>` → neutral placeholder, never a frontend failure. No change to `/image` itself.

Locking these **decisions** (none regress the founder's plan; anchored claims are in the ledger):

- **D1 Integrate — narrow optional embellishment, not a pipeline.** `create`/`refine` only; **never `explore`** (stays no-code, no image-gen). Guidance over the existing `/image`, no new machinery.
- **D2 Per-surface explicit opt-in.** The artist does not auto-generate; imagery generation is opted into for a given surface. Default is existing asset → neutral placeholder.
- **D3 draft-tier auto only.** `brand-text`/`brand-photo` are **never** invoked by `frontend-designer` — they require a separate human instruction or standalone `/image`. Brand assets (logo/wordmark/brand photo) are `/product`'s territory.
- **D4 Degradation ladder (founder directive — both pre-check AND call-time):** (1) default off → existing/neutral; (2) opt-in → cheap pre-check (helper exists, `FAL_KEY` set, shell tools) else neutral; (3) attempt **exactly one** draft call; (4) any failure (no-credits/402/quota/network/timeout/malformed/download-fail) → `image-fallback:<reason>` + neutral, build & contract still pass; (5) record the outcome (generated or fallback) in `design-direction.md` § Acceptance.
- **D5 Decorative in the contract.** Generated image is `aria-hidden`/`alt=""` (or real `alt` if it conveys content); spec-155 asserts the semantic surface, never the bitmap. Same posture as the WebGL canvas.
- **D6 Cost discipline.** Exactly **one draft attempt per surface invocation, outside the critique loop.** No try-N-prompts, no regenerate-on-vibes, no sub-agent fan-out. `/image`'s pre-call cost print + the count cap + explicit opt-in are the guards. Recorded in the gitignored manifest.
- **D7 Never a hard dep.** fal is paid+remote-only; the neutral path is what makes the skill work at zero key/credits/cost.
- **D8 Refused (no rule-of-three demand):** provider discovery, credit-probing pre-checks, caching, budget dashboards, prompt-iteration spend loops, auto brand-asset generation, asserting generated content in the contract.

**Shape of the change:** `references/imagery.md` (the ladder + limits + the gitignored-import rule), one decision step in `craft-loop.md` ("surface needs imagery → opt-in? → generate-one-draft-or-neutral, classify failures"), a SKILL.md line, and a `caps`-style FAL_KEY presence note (presence ≠ credits → call-time fallback is mandatory).

codex — one thing to confirm before synthesis: do you agree the neutral fallback should be the **authored default a surface ships with** (so "committed UI never depends on a gitignored draft" is structurally guaranteed, not just convention)? Push if you'd structure it differently.

Next: codex


### Turn 4 — Codex CLI (codex)

I agree: the neutral fallback should be the authored default the surface ships with.

Safest pattern: committed code renders a tracked neutral media component by default. The generated draft is only a progressive preview override, supplied through ignored local state such as `.env.local`, a gitignored generated CSS var file, or a dev-only config. Never `import` a gitignored draft.

For decorative hero/empty-state imagery, prefer CSS layering:

- tracked neutral layer always present
- optional generated `url(...)` layer above it
- `aria-hidden` / `alt=""`
- no semantic assertions depend on the bitmap

Use `<img onerror>` only when an actual image element is required. Even then, `src` should default to a tracked neutral asset, and the draft path should come from ignored/local config. A committed literal path to `assets/generated/mockups/...` is too easy to turn into a fresh-clone break or a broken visual.

Tighten D1-D8 in two places:

1. Done-proof should run or at least be explicitly checked with the generated draft disabled/missing. Otherwise a local successful draft can mask the neutral path.
2. The fallback wrapper should redact raw stderr before recording `image-fallback:<reason>`; do not leak `FAL_KEY`, headers, or provider payloads into tracked docs.

One more failure mode: CSS `background-image: url(missing), neutral` is safer than a single CSS `url(missing)` with a declared fallback, because CSS does not “fallback” after a 404 unless the neutral layer is independently present.

I agree no full SDD spec is needed if this stays guidance: `references/imagery.md`, one craft-loop step, and one SKILL.md line. The decision-grade meeting is already the record. If the change grows into a real shell helper that invokes `/image` from `frontend-designer.sh`, then write a light spec because that becomes testable skill behavior, not just guidance.

Next: claude
## Synthesis

_Written when a participant is asked to synthesize. Names the synthesizing runtime, the convergence, recorded disagreements, and a recommended next step (graduate to `/sdd refine` as seed context, or no-op). The human then accepts / redirects / ends._

_Decision-grade tier (spec 149): convergence is gated by the claim/evidence ledger (`meeting.sh ledger-check` — a point with only `assertion-only` claims is UNRESOLVED regardless of agreement), and a **minority report** (any residual objection) is preserved verbatim, never smoothed into consensus._

**Synthesized by:** claude (Claude Code). **Tier:** decision-grade. Ledger: 6 claims, 0 assertion-only, all path-anchored + verified.

### Convergence (anchored, both runtimes independently)

**Integrate `/image` into `/frontend-designer` — as a narrow, opt-in, draft-only embellishment over the existing `/image`, not a new pipeline.** Demand is proven (the Patudo dogfood: `/image --tier=draft` hero beat the emoji, `verify-contract` still PASS 6/6 with the image decorative). Locked decisions:

- **D1 Scope:** `create`/`refine` only; **never `explore`** (stays no-code/no-image-gen). Guidance over `/image`, no new machinery.
- **D2 Per-surface explicit opt-in.** No auto-generation; default is existing asset → neutral placeholder.
- **D3 draft-tier auto ONLY.** `brand-text`/`brand-photo` are never invoked by `frontend-designer` (separate human instruction or standalone `/image`). Brand assets (logo/wordmark/brand photo) are `/product`'s territory.
- **D4 Degradation ladder (founder directive — pre-check AND call-time):** default off → existing/neutral; opt-in → cheap pre-check (helper exists, `FAL_KEY` set, shell tools) else neutral; attempt **exactly one** draft call; any failure (no-credits/402/quota/network/timeout/malformed/download-fail) → `image-fallback:<reason>` + neutral, build & contract still pass; record outcome in `design-direction.md`.
- **D5 Decorative in the contract** — `aria-hidden`/`alt=""`; spec-155 asserts the semantic surface, never the bitmap.
- **D6 Cost discipline** — exactly one draft attempt per surface invocation, **outside the critique loop**; no try-N-prompts / regenerate-on-vibes / sub-agent fan-out; pre-call cost print + count cap + opt-in are the guards.
- **D7 Never a hard dep** — fal is paid+remote-only; the neutral path makes the skill work at zero key/credits/cost.
- **D8 Refused (no rule-of-three demand):** provider discovery, credit-probing, caching, budget dashboards, prompt-iteration spend loops, auto brand-asset generation, asserting generated content in the contract.

**Three tightenings adopted from codex's pressure-test (load-bearing):**
- **T1 Neutral fallback is the AUTHORED DEFAULT a surface ships with** — structurally, not by convention. Committed code renders a **tracked neutral media layer**; the generated draft is only a *progressive preview override* supplied via gitignored/local config (`.env.local`, a gitignored generated CSS-var file, dev-only config). **Never `import` a gitignored draft.** Preferred pattern: CSS two-layer (`background-image: url(generated), <tracked-neutral>` with the neutral independently present — CSS does not "fall back" after a 404 unless the neutral layer exists on its own); `<img onerror>` only when a real `<img>` is required, with `src` defaulting to a tracked neutral.
- **T2 Verify the neutral path** — done-proof must be checked with the generated draft **disabled/missing**, so a local successful draft never masks a broken neutral fallback.
- **T3 Redact before recording** — the wrapper strips `FAL_KEY`/headers/provider payload from stderr before writing `image-fallback:<reason>` into tracked docs.

### Disagreements / minority report

None material — blind openings converged; the pressure-test only tightened. No residual objection.

### Recommended next step

**Implement now as guidance — no full SDD spec** (both agreed: this is docs/guidance over the existing `/image`, no new machinery; **this decision-grade meeting is the record**). Shape: a `references/imagery.md` (ladder + limits + T1 tracked-neutral-default + the gitignored-import rule), one `craft-loop.md` decision step, one SKILL.md line, and reconcile the now-outdated negative mentions (stack-ladder/SKILL deps say "never integrated" — soften to "optional, opt-in per the imagery ladder"). **Promotion trigger:** if this ever grows into a real shell helper invoking `/image` from `frontend-designer.sh`, write a light spec then (testable behavior, not just guidance).
