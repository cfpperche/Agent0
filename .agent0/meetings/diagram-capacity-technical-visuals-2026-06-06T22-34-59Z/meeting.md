---
meeting: diagram-capacity-technical-visuals
topic: "Should Agent0 add a /diagram capacity — deterministic technical-visual generation (architecture, flow, ERD, sequence) from a text source (mermaid/graphviz/d2-class), rendered locally, zero-cost, git-trackable — as the deterministic sibling of /video code-mode and the technical counterpart to /image. Strategic pull: not Agent0-internal but via consumer products, esp. cognixse (serves software-dev companies → helps many of them); mei-saas benefits too. Decide: real+structured demand now? v1 scope (families, engine(s), structured-capacity contract)? boundary vs /image and /video code-mode? graduate to spec + sharpest OQs/kill-risks?"
created: 2026-06-06T22:34:59Z
convener: claude
mode: human-orchestrated
roster: claude,codex
rotation: claude,codex
tier: decision-grade
blind_phase: revealed
turn_counter: 3
next_speaker: claude
synthesis: accepted
---

# Meeting: Should Agent0 add a /diagram capacity — deterministic technical-visual generation (architecture, flow, ERD, sequence) from a text source (mermaid/graphviz/d2-class), rendered locally, zero-cost, git-trackable — as the deterministic sibling of /video code-mode and the technical counterpart to /image. Strategic pull: not Agent0-internal but via consumer products, esp. cognixse (serves software-dev companies → helps many of them); mei-saas benefits too. Decide: real+structured demand now? v1 scope (families, engine(s), structured-capacity contract)? boundary vs /image and /video code-mode? graduate to spec + sharpest OQs/kill-risks?

_A multi-party, multi-model deliberation. The front-matter above is the machine-readable state: `roster` is every participant id, `rotation` is the deterministic **fallback order** of model participants (human excluded), `next_speaker` is the **derived default** speaker (set by a turn's trailing `Next: <id>` directive; not enforced legality), `turn_counter` counts written turns, `synthesis` tracks the close-out. Speaker selection is context-driven: a turn may end with an explicit `Next: <roster-id>` line to hand the floor; otherwise the human directs with `--speaker`. The body below is the chronological transcript._

## Participants

- claude — Claude Code (web: allowed)
- codex — Codex CLI (web: allowed)

## Transcript

_Turns are appended below in order. Each turn header is `### Turn N — <runtime> (<id>)`; a research-backed turn carries a `Sources:` block listing the URLs used. A turn may end with a single trailing `Next: <roster-id>` line to hand the floor to a specific participant (the directive stays visible here; it sets the default next speaker)._

## Blind submissions (commit/reveal)

_Commitments recorded before any opening is revealed — de-anchors round 1 (spec 149)._

- commit claude — `sha256:4bb831c598d04cdf` (3530 bytes)
- commit codex — `sha256:169a35c38141dd58` (3588 bytes)

### Turn 1 — claude (blind opening) (claude)

**Position (claude).** Build it — but anchor the "build now" on the demand we can verify in-repo, and treat the engine/render path as the real design risk.

**(1) Demand — real and structured now, but be honest about which evidence is load-bearing.** The strongest anchor is NOT the cognixse-vertical framing (real, but it's a value-amplifier we can't verify from this repo). It's the *internal consumer that already exists*: the `/product` pipeline emits `system-design`, `sitemap-IA`, and `OST` as **prose with no diagrams**, and SDD specs routinely want an architecture/flow diagram. That is concrete, in-repo, recurring pull — rule-of-three-adjacent, not speculative. The vertical-leverage story (cognixse → software-dev companies) is the *why it's worth doing well*, layered on top. Combined with the low downside (deterministic, free, git-tracked — no paid lane to misfire, no privacy boundary), build-now clears the bar.

**(2) v1 scope — the source language is the easy call; the render engine is the hard one.** Source = **Mermaid**, because the agent *writes* these and Mermaid is the language LLMs are most fluent in and that covers the needed families in one syntax (flowchart, sequence, ER, class, state, C4-ish). That fluency is the deciding factor — it makes the capacity usable by the agent without a reference manual. The hard question is the **render path**: `@mermaid-js/mermaid-cli` (mmdc) needs headless Chrome/puppeteer — heavy. d2 (single Go binary, no Chrome, beautiful) and Graphviz (ubiquitous `dot` binary) avoid that but cost Mermaid's LLM fluency. My lean: Mermaid source + a render ladder that prefers a lighter path and degrades honestly (the `/transcribe` acquisition posture), accepting that Chrome may be the floor — we already depend on headless-Chrome for `/video --mode code`, so it's not a *new* class of dep.

**(3) Boundary — clean, no overlap.** `/image` = organic/photo/raster, paid (fal). `/video --mode code` = HTML/CSS/JS → MP4, motion, Chrome. `/diagram` = **text-spec → SVG/PNG, static, deterministic, free**. Critically, `/diagram` follows the structured-capacity contract **minus the cost apparatus** — it's a `/transcribe`-class local utility (provenance, not a cost ledger; no tiers/`--confirm-cost-usd`/`FAL_KEY`), not an `/image`-class paid one. Getting that classification right up front prevents bolting on a cost gate it doesn't need.

**(4) Graduate to spec — yes** (skill + tool + rule + tests + wiring + a render-engine decision = clearly SDD-shaped). Sharpest OQs: **(a)** render path + acquisition — the Chrome-vs-single-binary question is THE risk and deserves a real first-call probe; **(b)** output classes — diagrams are usually *keepers* (git-tracked `.mmd` source + tracked SVG), so the `/image` draft-vs-asset split may not apply — likely tracked-by-default with the source as the real artifact; **(c)** does `/product` auto-emit diagrams from system-design? — tempting but probably v2 (don't let scope creep the v1).

**Kill-risk to test:** if the capacity is *thin glue* — "agent writes `.mmd`, you run a renderer" — does it earn being a structured capacity, or is it a 5-line snippet? Counter-claim (to pressure-test): the structured value is exactly the render+acquisition+placement+`doctor`/`caps`+git-discipline contract, same reason `/transcribe` is a capacity and not just "run whisper." If Codex can show the glue is genuinely trivial with no acquisition/degradation surface, that weakens build-now.

Next: codex


### Turn 2 — codex (blind opening) (codex)

Position: **graduate to a spec and build, but only as a narrow Mermaid-first deterministic renderer/validator, not a broad visual-generation platform.**

1. **Demand:** real enough to build now, with a spec gate. The load-bearing evidence is that Agent0 already has repeated prose surfaces that naturally want technical visuals (`/product` system design / sitemap-IA / OST, SDD architecture notes), and the founder’s stronger point is consumer leverage: cognixse serves software-development companies, where diagrams are first-class work product. Softer evidence: I do not see a cited failed workflow or measured consumer request yet. So I would build now, but require v1 dogfood against 2-3 real artifacts before shipping to consumers.

2. **v1 scope:** Mermaid-only, SVG-first. Families: flowchart/architecture, sequence, ERD, class, state. Source is tracked `.mmd`; rendered `.svg` may also be tracked when referenced by docs; PNG/PDF are optional generated artifacts. Engine path: local `@mermaid-js/mermaid-cli` / `mmdc`, with explicit `caps` and `doctor` checks for Node, `mmdc`, and usable Chrome/Chromium/Puppeteer. If absent, return `status:"unavailable"` with install hints, not a fake success. This mirrors `.agent0/context/rules/transcribe.md` and `.agent0/tools/transcribe.sh`: status decoupled from exit unless `--exit-code` is requested, provenance manifest, no cost ledger.

I would not start with D2 despite the attractive single Go binary. It is operationally cleaner, but Mermaid has the stronger consumer-language fit and covers the requested families in one syntax. I would not start with Graphviz because DOT is excellent for graphs but weak as the single answer for sequence/ER/class/state. I would not use Kroki in v1: remote Kroki violates the local/free posture, and local Kroki adds a server/container surface before we have proven the need.

3. **Boundary:** `/diagram` is a local/free `/transcribe`-class utility, not a paid `/image`-class capacity. It compiles deterministic text into technical visuals. No `FAL_KEY`, no tiers, no `--confirm-cost-usd`, no organic raster promise. `/image` remains for organic/photo/brand imagery. `/video --mode code` remains HTML/CSS/JS to MP4 motion via Chrome/ffmpeg, as described in `.agent0/context/rules/video-gen.md`; `/diagram` is static technical rendering. The overlap is “deterministic source tracked, output reproducible,” not media semantics.

4. **Spec:** yes. Sharp open questions:
- exact storage convention: `docs/specs/NNN-*/diagrams/*.mmd` for spec-owned diagrams vs `assets/diagrams/` for reusable product diagrams;
- whether rendered SVG is always tracked or only when embedded in user-facing docs;
- whether the wrapper may auto-acquire `mmdc` or only report install hints;
- how much styling/theme config is allowed before this stops being deterministic documentation and becomes design work.

Kill-risks:
- if v1 is only “write `.mmd` and run `mmdc`,” it may be thin glue. It earns structured-capacity status only if it standardizes paths, provenance, `caps`/`doctor`, result JSON, unavailable behavior, doc embedding, and skill guidance;
- if most real docs are happy with raw Mermaid fenced blocks rendered by GitHub, local SVG rendering may be unnecessary;
- Mermaid’s Chrome/Puppeteer dependency may be too heavy for the “local utility” feel. If dogfood shows that pain dominates, reopen D2-first;
- semantic correctness cannot be delegated to the renderer. The skill must frame diagrams as generated documentation requiring review, not proof of architecture truth.

Next: claude


## Claim/evidence ledger

_Convergence GATE: a point with only `assertion-only` claims is NOT resolved, regardless of agreement (spec 149)._

| claim | tag | anchor |
| --- | --- | --- |
| Demand has no cited FAILED workflow or measured consumer request yet (codex minority caution) — gate consumer-ship on a v1 dogfood against 2-3 real artifacts before harness-sync to consumers. | unresolved | test:dogfood-2-3-real-artifacts |
| Thin-glue kill-risk (agent writes .mmd + runs mmdc): earns structured-capacity status ONLY if it standardizes paths/provenance/caps/doctor/result-JSON/unavailable-behavior/doc-embedding/skill-guidance — both raised it independently. | unresolved | test:dogfood-2-3-real-artifacts |
| Graduate to a spec (skill + tool + rule + tests + wiring + render-engine decision = SDD-shaped); both agents agree. | supported | path:.agent0/context/rules/spec-driven.md |
| Primary render path = mmdc (@mermaid-js/mermaid-cli) which needs headless Chrome/Puppeteer — the dep RISK; acquisition via npx (the /video HyperFrames-npx precedent), degrade honestly to status:unavailable + hint when absent. | supported | path:.agent0/context/rules/video-gen.md |
| Source language = Mermaid (LLM fluency + one syntax covers flowchart/sequence/ER/class/state); both agents converged independently, rejecting d2/graphviz/kroki for v1. | supported | path:.agent0/context/rules/video-gen.md |
| /diagram is a /transcribe-class LOCAL/FREE utility (provenance manifest, NOT a cost ledger; no FAL_KEY/tiers/--confirm-cost-usd), not an /image-class paid capacity — both agents independently classified it so. | supported | path:.agent0/context/rules/transcribe.md |
| Build-now is justified by an existing in-repo consumer: /product emits system-design/sitemap-IA/OST as prose with no diagrams, and SDD specs want architecture diagrams (rule-of-three-adjacent, not speculative). | supported | path:.claude/skills/product/SKILL.md |

### Turn 3 — Claude Code (claude)

We converged independently on every structural call (build-now-with-spec-gate, Mermaid source, /transcribe-class local/free, clean boundary, thin-glue as the kill-risk). Three of codex's points are sharper than mine and I adopt them; one kill-risk needs a real answer.

**The "GitHub renders Mermaid fenced blocks natively, so why render locally?" kill-risk — this is the sharpest, and answering it actually clarifies v1's scope.** The answer is exactly the founder's framing: the value is NOT replacing a GitHub README's live renderer — it's producing a **tracked SVG/PNG asset** for surfaces that have *no* live Mermaid renderer: a consumer product's UI/docs/slides/PDF, a marketing page, a system-design doc rendered outside the repo host. Software-dev companies (cognixse's customers) ship diagrams as *product artifacts*, not as README fenced blocks. So v1's center of gravity = **`.mmd` source → deterministic, pinned, offline `.svg`/`.png` asset**, with two sub-values that hold even where GitHub would render: (a) **validation/lint** of the `.mmd` (catch a syntax error deterministically, in CI, with no host renderer), and (b) **reproducibility** (GitHub's renderer version drifts; a pinned local engine doesn't). That reframes the kill-risk into a scope statement rather than refuting build-now.

**Render path — bridge between codex's "mmdc floor" and my "ladder."** Mermaid source is fixed; primary render = `mmdc` via **npx** (the `/video` HyperFrames-npx precedent, no global install). But Chrome/Puppeteer should not be a hard *all-or-nothing* gate: add a **validation-only degradation** — when Chrome/mmdc is absent, the tool still **parses/validates the `.mmd` and keeps the tracked source**, returning `status:unavailable` for the *render* with an honest install hint, not a dead capacity. That preserves value on a Chrome-less box and matches the `/transcribe` "degrade, don't crash" posture. **d2-first stays a documented reopen-trigger** on codex's exact condition (if dogfood shows Chrome pain dominates) — not v1.

**Adopt from codex (sharper than my opening):** (1) **storage split** — spec-owned diagrams under `docs/specs/NNN-*/diagrams/*.mmd`, reusable product diagrams under `assets/diagrams/` (tracked; diagrams are keepers — this *replaces* the /image draft-vs-asset split, source is the real artifact); (2) **theme/styling boundary** — minimal built-in-theme passthrough only; anything past that is design work and belongs to `/frontend-designer`, not here (keeps it deterministic documentation); (3) **acquire-vs-hint** — npx-ephemeral acquire + hint, never a destructive global install.

**Minority report I accept and carry:** codex is right that we have no *cited failed workflow* or *measured consumer request* yet — only structural pull. So the gate is honest: **build v1, dogfood against 2–3 real artifacts (a system-design arch diagram, a sequence, an ERD), and do NOT harness-sync to consumers until that dogfood proves the asset path end-to-end.** Semantic correctness is never the renderer's job — the skill frames diagrams as *generated documentation requiring review*, not architecture truth.

I think this is spec-ready. Recommend graduating to `/sdd refine` with this meeting as seed context.

Next: claude

## Synthesis

_Written when a participant is asked to synthesize. Names the synthesizing runtime, the convergence, recorded disagreements, and a recommended next step (graduate to `/sdd refine` as seed context, or no-op). The human then accepts / redirects / ends._

_Decision-grade tier (spec 149): convergence is gated by the claim/evidence ledger (`meeting.sh ledger-check` — a point with only `assertion-only` claims is UNRESOLVED regardless of agreement), and a **minority report** (any residual objection) is preserved verbatim, never smoothed into consensus._

**Synthesized by:** claude (Claude Code). Decision-grade; convergence rests on the ledger (7 claims, **0 assertion-only**, 5 supported claims pass `check-anchors`, 2 deliberately-`unresolved` items anchored to a not-yet-existent dogfood test).

### Convergence (independent — from blind openings, no anchoring)
Both runtimes, writing blind, agreed on every structural call:

- **Build now, behind a spec gate.** Justified by an existing in-repo consumer (`/product` emits `system-design`/`sitemap-IA`/`OST` as prose with no diagrams; SDD specs want architecture diagrams) — rule-of-three-adjacent, not speculative — amplified by the founder's consumer-vertical leverage (cognixse → software-dev companies ship diagrams as product artifacts). Low downside (deterministic, free, no paid lane, no privacy boundary).
- **`/diagram` is a `/transcribe`-class LOCAL/FREE utility**, not an `/image`-class paid one: provenance manifest (not a cost ledger), no `FAL_KEY`/tiers/`--confirm-cost-usd`, `status` decoupled from exit, `doctor`/`caps`, rule as propagation vehicle. Both classified it identically.
- **Source language = Mermaid** (LLM fluency + one syntax covers flowchart/sequence/ER/class/state). Both explicitly rejected d2/graphviz/Kroki for v1 (Kroki violates local/free; d2/graphviz lose Mermaid's coverage+fluency).
- **Clean boundary:** `/image` = organic raster (paid); `/video --mode code` = HTML→MP4 motion (Chrome); `/diagram` = text-spec → static SVG/PNG (deterministic, free).
- **Graduate to a spec** (SDD-shaped: skill + tool + rule + tests + wiring + a render-engine decision).
- **Kill-risk both raised independently:** "thin glue" — it earns structured-capacity status only by standardizing paths/provenance/`caps`/`doctor`/result-JSON/unavailable-behavior/doc-embedding/skill-guidance.

### Resolutions reached in critique (claude moved toward codex on each)
- **The "GitHub renders Mermaid natively → why render locally?" kill-risk** is answered by scoping, not refutation: v1's center of gravity is a **tracked SVG/PNG asset** for surfaces with no live renderer (product UI/docs/slides/PDF, marketing) — the consumer-artifact case — plus `.mmd` validation/lint and pinned reproducibility (which hold even where GitHub would render). Not a README-renderer replacement.
- **Render path:** Mermaid source fixed; primary render `mmdc` (`@mermaid-js/mermaid-cli`) via **npx** (the `/video` HyperFrames-npx precedent, no global install). Bridge between codex's "mmdc floor" and claude's "ladder": a **validation-only degradation** — Chrome/mmdc absent ⇒ still parse/validate the `.mmd` and keep the tracked source, returning `status:unavailable` for the *render* with an install hint (not a dead capacity). **d2-first stays a documented reopen-trigger** on codex's exact condition (dogfood shows Chrome pain dominates).
- **Storage (codex's split, adopted):** spec-owned diagrams `docs/specs/NNN-*/diagrams/*.mmd`; reusable product diagrams `assets/diagrams/` — tracked (diagrams are keepers; this *replaces* the /image draft-vs-asset split, source is the real artifact).
- **Theme/styling boundary:** minimal built-in-theme passthrough only; past that is design work → `/frontend-designer`, not here. Keeps it deterministic documentation.
- **Acquisition:** npx-ephemeral + hint, never a destructive global install.

### Minority report (preserved verbatim, not smoothed)
codex: *"I do not see a cited failed workflow or measured consumer request yet."* The demand is **structural pull, not measured pull.** Therefore the honest gate — accepted by both — is: build v1, **dogfood against 2–3 real artifacts** (an arch diagram, a sequence, an ERD) end-to-end, and **do NOT harness-sync to consumers until that dogfood proves the asset path.** Corollary (codex): semantic correctness is never the renderer's job — the skill frames diagrams as *generated documentation requiring review*, not architecture truth.

### Recommended next step
**Graduate to `/sdd refine`** with this meeting as seed context (not bypassing the interview). Sharpest OQs to carry into the spec: (a) render path + acquisition + the validation-only degradation contract; (b) storage convention exactness (spec-owned vs `assets/diagrams/`; when rendered SVG is tracked vs draft); (c) result-JSON / `caps` / `doctor` shape that lifts it above thin glue; (d) `/product` auto-emit from system-design = explicitly **v2**, out of v1 scope. **Kill-condition if reopened:** if v1 dogfood shows the glue is genuinely trivial with no real acquisition/degradation/placement surface, downgrade to a documented snippet rather than a capacity.
