# 132 — video-skill

_Created 2026-05-31._

**Status:** shipped

## Intent

Add `/video` — an opt-in, multi-runtime Agent0 skill for producing video, mirroring how `/image` handles image generation. The skill exposes **two mechanically disjoint modes under one required `--mode` flag**: `code` (deterministic — HyperFrames renders HTML/CSS/JS → MP4 via headless Chrome + ffmpeg, zero marginal inference cost) and `generative` (paid, async — fal.ai video models via REST queue). The motivator is a study of AI-video workflows ([dfolloni substack](https://dfolloni.substack.com/p/como-eu-faco-videos-profissionais)) plus the observation that `/image` already rides fal.ai, which already hosts video models — so the generative side is an extension of an existing mechanism, not a new integration. The capacity serves engineering/product asset jobs (product demos, changelog/release videos, animated explainers, killer-flow walkthroughs), not creator content. It ships **mechanisms, not frozen stack opinions**: no model IDs baked into the skill body; the human picks at contract time; a consumer project that never activates pays zero cost.

## Acceptance criteria

- [x] **Scenario: `--mode` is required, no default**
  - **Given** a user invokes `/video "<brief>"` with no `--mode` flag
  - **When** the skill parses arguments
  - **Then** it errors clean listing the two modes (`code` / `generative`) and their cost posture, mirroring `/image`'s `--tier`-required error — no silent default

- [x] **Scenario: one portable skill, multi-runtime discovery**
  - **Given** the skill is installed
  - **When** either Claude Code or Codex CLI resolves it
  - **Then** the canonical body lives at `.agent0/skills/video/SKILL.md` with discovery symlinks `.claude/skills/video` and `.agents/skills/video`, and `agents/openai.yaml` sets `allow_implicit_invocation: false` (paid/side-effecting), exactly as `/image` does (spec 121 pattern)

- [x] **Scenario: code mode renders deterministically with owned authoring**
  - **Given** `--mode=code` and an authoring composition
  - **When** the skill renders
  - **Then** it depends only on a **pinned HyperFrames npm engine** (`hyperframes@<pinned>`), uses **Agent0-owned** authoring guidance + templates under `references/` (NOT the upstream agent-skill — no second discovery surface, no implicit `npx skills add`), tracks the HTML composition source in git, gitignores the rendered MP4, and records a render fingerprint to the manifest

- [x] **Scenario: generative mode is ledger-based async over fal REST**
  - **Given** `--mode=generative` with a resolved tier
  - **When** a clip is requested
  - **Then** the helper `submit`s to `queue.fal.run` (REST + `Authorization: Key $FAL_KEY`, NOT the MCP `run_model`), returns a `request_id` persisted to a gitignored job ledger, and a separate `poll [--all]` invocation reaps terminal jobs and downloads assets — no dependency on any runtime's native background execution

- [x] **Scenario: strong cost gate on paid generation**
  - **Given** a `generative` clip whose estimated cost is computed from tier × duration
  - **When** the user has not passed `--confirm-cost-usd=<max>` ≥ the estimate
  - **Then** the skill refuses to execute (a passive cost print is insufficient for 100–1000× image cost); the confirmation binds to the prepared envelope (cost/model/duration), and `code` mode is exempt from this friction

- [x] **Scenario: tier→model resolution is refreshable, not baked**
  - **Given** the generative tiers
  - **When** `prepare` resolves a tier to a concrete model
  - **Then** it reads a date-stamped, refreshable `references/video-tiers.yaml` (snapshot date, candidate models, price bands, duration/resolution constraints), optionally consults fal discovery/pricing tools when available, writes the resolved model into the envelope + manifest, and warns when the snapshot is older than 45–60 days — no model IDs in the skill body

- [x] **Scenario: zero-cost-if-unused with clean errors**
  - **Given** a consumer project that has not activated the capacity
  - **When** `/video` is invoked
  - **Then** it errors clean pointing at activation (FAL_KEY for generative; Node 22+/Chromium/ffmpeg for code), declares the local dependencies, and fails cleanly if a required dependency is absent — no partial/silent execution

- [x] Shared fal REST primitives live in a non-discoverable lib (`.agent0/tools/fal-rest.sh`), NOT in `/image`'s `gen.sh` (which bakes image-specific fields)
- [x] Portability tier is declared `agentskills-portable` (depends on local Node/Chromium/ffmpeg), not `runtime-agnostic`
- [x] A manifest records every render/clip (success and failure) with cross-domain field naming aligned to `/image`'s manifest + `.agent0/delegation-audit.jsonl`

## Non-goals

- **Not a general video studio.** No editing of real/recorded footage (the blog's "Video Use" transcript-edit approach is out of scope).
- **No drift-checker tool in v1.** The render fingerprint is recorded as manifest fields, but a tool that re-hashes committed source vs last render and warns is *speculative observability* — deferred until rule-of-three demand (per `.agent0/context/rules` discipline).
- **No `/image` refactor in this spec.** Extracting `fal-rest.sh` is in scope; migrating `/image` onto it (plus fixing `/image`'s stale MCP-delegation wording in its frontmatter) is a **decoupled follow-up spec**, not a blocker for `/video`.
- **No `/product` or `/prototype` coupling in v1.** Standalone, user-invoked — same posture as `/image` v1. Cross-skill wiring (e.g. killer-flow demo handoff) is deferred until a skill explicitly asks.
- **Higgsfield is not the foundation.** Documented only as an optional alternative generative provider (same role as `/image`'s community-MCP fallbacks); the fal.ai REST path is canonical.
- **No per-session cost-budget enforcement** beyond the per-call confirm gate (mirrors `/image` v1; add a counter only if empirical sub-agent drift surfaces).

## Open questions

- [ ] **HyperFrames version pin** — which `0.6.x` (pre-1.0, fast churn) does v1 pin, and is the engine a consumer `package.json` devDependency or invoked ephemerally via `npx hyperframes@<pin>`? Resolve at `/sdd plan`.
- [ ] **Seed tier set + models** — how many generative tiers (e.g. `draft` / `standard` / `premium`) and which models populate `video-tiers.yaml` at snapshot time (e.g. Wan draft → Kling standard → Veo premium)? Resolve at `/sdd plan` via fal discovery, not guessed here.
- [ ] **Job-ledger location + poll UX** — gitignored under `.agent0/.runtime-state/` vs `assets/generated/`; and is reaping a single explicit `/video poll --all`, or is there an auto-poll convenience? Owner: plan.
- [ ] **Estimate vs actual cost reconciliation** — when fal's actual bill exceeds the `--confirm-cost-usd` ceiling (audio on, resolution upscale), does the run record-and-warn or hard-fail mid-flight? Owner: plan.
- [ ] **Storage roots** — confirm the split: generative throwaway `assets/generated/videos/` (gitignored) vs durable `assets/video/` (tracked); code-mode source root for tracked compositions. Owner: plan.

## Context / references

- **Motivator study:** [dfolloni — "Como eu faço vídeos profissionais"](https://dfolloni.substack.com/p/como-eu-faco-videos-profissionais) (Higgsfield MCP workflow); cross-model debate in `debate.md`.
- **Exemplar:** `/image` — `.agent0/context/rules/image-gen.md`, `.agent0/skills/image/SKILL.md`, `.agent0/skills/image/scripts/gen.sh` (prepare/exec/record pipeline, cost gate, manifest, MCP-optional/REST-generation split).
- **Multi-runtime pattern:** `.agent0/context/rules/runtime-capabilities.md` (skills row, spec 121); `.claude/skills/skill/references/portability-tiers.md` (3 tiers).
- **Engines:** HyperFrames (HeyGen, Apache-2.0, [github.com/heygen-com/hyperframes](https://github.com/heygen-com/hyperframes)); fal.ai video models (Kling/Veo/Sora/Wan, REST queue API).
- **Prior specs:** 088 (image curl-exec — why generation is REST not MCP); 121 (multi-runtime skills); 128 (codex-exec — the bridge used to run this spec's cross-model debate).
- **Decision provenance:** every acceptance criterion + non-goal traces to a `DECISION:` in `debate.md` (2-round Claude↔Codex CLI debate, converged).
