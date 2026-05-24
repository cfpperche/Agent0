# 085 — image-gen-opt-in

_Created 2026-05-24._

**Status:** shipped

_2026-05-24 — all 11 acceptance criteria validated. Scenarios 1-3 verified via `.claude/tests/image-gen/{01,02,03}-*.sh` (mocked MCP response — same boundary the secrets-scan tests use to exercise the preflight without a real git commit). End-to-end against real fal.ai still requires a fork-side `FAL_KEY` + activation; that's a per-fork integration step, not a spec gate._

## Intent

Instrument Agent0 with an opt-in image-generation capacity that ships through the harness to any fork. Claude has no native image generation; forks today either reach for `picsum.photos` placeholders (in `/prototype`) or hand-author hero/brand assets — both are friction. The capacity should give the agent a sanctioned way to produce both **throwaway UI mockups** (cheap, high-volume) and **durable brand assets** (premium quality, text-rendering + photo-real) without picking a winner upfront. Provider is **fal.ai** as a single unified aggregator (hosts FLUX, OpenAI gpt-image, Google Imagen, etc. under one API key), exposed via an **MCP recipe** in `.mcp.json.example` and wrapped by a thin `/image` skill that handles file-naming conventions, manifest logging, and pre-call cost visibility. Pure opt-in — forks that don't activate the recipe pay zero cost.

## Acceptance criteria

- [ ] **Scenario: cheap mockup workflow (draft tier)**
  - **Given** the `fal-ai` recipe is copied into `.mcp.json` and `FAL_KEY` is in env
  - **When** the agent invokes `/image --tier=draft "<prompt>"`
  - **Then** `fal-ai/flux/schnell` produces a 1024×1024 PNG at `assets/generated/mockups/<YYYY-MM-DD>-<slug>.png`, a manifest line is appended to `assets/generated/.manifest.jsonl` recording prompt+model+cost+ts, and the estimated cost (~$0.003) was printed before the call

- [ ] **Scenario: brand text-rendering workflow**
  - **Given** the `fal-ai` recipe is active
  - **When** the agent invokes `/image --tier=brand-text "<prompt>"`
  - **Then** `fal-ai/gpt-image-2` produces an image at `assets/brand/<slug>.png` with manifest entry, estimated cost (~$0.04-0.20) printed pre-call

- [ ] **Scenario: brand photo-real workflow**
  - **Given** the `fal-ai` recipe is active
  - **When** the agent invokes `/image --tier=brand-photo "<prompt>"`
  - **Then** `fal-ai/imagen4/ultra` produces an image at `assets/brand/<slug>.png` with manifest entry, estimated cost (~$0.06) printed pre-call

- [ ] **Scenario: opt-in posture — no silent activation**
  - **Given** `FAL_KEY` is NOT set in env AND `.mcp.json` does not carry the `fal-ai` entry
  - **When** the agent invokes `/image "<prompt>"`
  - **Then** the skill errors with a one-screen message pointing at `.mcp.json.example` + `.claude/rules/image-gen.md` § Activation; nothing is generated; no silent fallback to a different provider

- [ ] **Scenario: cost visibility — pre-call confirmation surface**
  - **Given** any tier is invoked
  - **When** `/image` resolves the model selection
  - **Then** stdout prints `estimated: $X.XXX for <model> at <resolution>` BEFORE the MCP call fires, so a parent agent or human can ctrl-c if the estimate is wrong-shape

- [ ] **Scenario: sync-harness propagation — capacity ships, content doesn't**
  - **Given** a fork runs `.claude/tools/sync-harness.sh` after this spec lands
  - **When** the sync reconciles
  - **Then** `.claude/skills/image/SKILL.md`, `.claude/rules/image-gen.md`, and the `fal-ai` block in `.mcp.json.example` update if stale; `.mcp.json` (live config with secrets) and `assets/generated/*` are untouched

- [ ] `.claude/skills/image/SKILL.md` exists and passes `/skill validate image`
- [ ] `.claude/rules/image-gen.md` exists and is referenced from `CLAUDE.md` § (new section)
- [ ] `.mcp.json.example` carries a `fal-ai` entry using HTTP transport (`url: https://mcp.fal.ai/mcp`, `headers.Authorization: "Bearer ${FAL_KEY}"`) — no `command`/`args`/`npx` install path, no literal key
- [ ] `assets/generated/.gitkeep` exists; gitignore policy for `assets/generated/*` is resolved per Open Q1
- [ ] `.claude/tools/sync-harness.sh` manifest covers the three new artifacts
- [ ] Existing capacities NOT touched: no edits to `/product`, `/prototype`, or any other shipping skill

## Non-goals

- **Building an MCP server.** Three mature options exist (lansespirit, mikeyny, sarthakkimtani); rule-of-three demand test fails for a fourth.
- **Multi-provider auto-fallback.** v1 picks fal.ai. Alternatives are documented in the rule for manual swap; no auto-routing logic if fal.ai is degraded.
- **Image editing / inpainting / variations.** v1 is text-to-image only. Edits ship if a real need surfaces (rule-of-three).
- **Video generation.** Distinct provider economics + use-cases; out of scope.
- **Cost budget enforcement.** v1 prints estimates pre-call; no per-session cap, no loop-budget for `/image` calls. Add only if drift observed.
- **Integration with `/product` or `/prototype`.** Standalone in v1 per the user's choice. Cross-skill integration deferred until either skill explicitly asks for image-gen.
- **Persistent caching of prompt→image mapping.** No deduplication on identical prompts; every call hits the API.
- **NSFW / safety filtering at the skill layer.** fal.ai + underlying provider enforce their own policies; the skill does not re-implement filters.

## Open questions

- [x] **Q1 — Storage policy for `assets/generated/`.** _RESOLVED 2026-05-24:_ path-based split. `assets/generated/mockups/*` is gitignored (throwaway draft tier); `assets/brand/*` is git-tracked (durable). Tier flag at call-time IS the durability signal — gitignore policy is mechanical, not policy-laden. Promotion mockup→brand is manual `git mv` + `.gitignore` edit, accepted as rare-and-explicit.
- [x] **Q2 — Default tier when `--tier` omitted.** _RESOLVED 2026-05-24:_ **(a) error with the 3 tier options listed.** Cost mistakes accumulate silently; quality mistakes are visible and self-correcting — fail-explicit on cost is the right asymmetry. Matches the contract-not-promise discipline used by `delegation.md`, `supply-chain.md`, `governance-gate.sh`.
- [x] **Q3 — Output naming convention.** _RESOLVED 2026-05-24:_ `<YYYY-MM-DD>-<kebab-first-5-words>.png`, with `-2`/`-3` collision suffix (same shape as `reminders.yaml` id collision per spec 084). `--name=<explicit>` flag overrides for messy / non-ASCII prompts.
- [x] **Q4 — Fallback path when MCP unavailable.** _RESOLVED 2026-05-24:_ NO `--no-mcp` curl fallback in v1. Single surface = single audit path; CI invocation is niche. Add only if real CI dogfood demands it (rule-of-three).
- [x] **Q5 — Provider package selection.** _RESOLVED 2026-05-24:_ use fal.ai's **official hosted MCP** at `https://mcp.fal.ai/mcp` (HTTP transport, maintained by fal.ai team, free, covers 1000+ models). Initial premise "no official exists" was wrong — verified during `/sdd plan` research via [fal.ai docs](https://fal.ai/docs/documentation/setting-up/mcp). Supply-chain hook is doubly moot: (a) HTTP transport means no `npx`/package install at all; (b) even if a community package were used, MCPs spawn from `.mcp.json` outside the `PreToolUse(Bash)` hook surface. Community packages (`piebro/fal-ai-mcp-server`, `@monsoft/mcp-fal-ai`, et al.) become documented fallbacks in the rule, not the default.
- [x] **Q6 — Manifest format vs sibling capacities.** _RESOLVED 2026-05-24:_ partial alignment. Core fields `ts`, `session_id`, `cost_usd`, `model` match `.claude/delegation-audit.jsonl` for cross-domain forensics queries (`jq 'select(.session_id == X)'`). Domain-specific fields (`prompt`, `output_path`, `dimensions`, `tier`) stay fresh. Do NOT force `tool_use_id` / `agent_id` — image-gen is not an Agent dispatch.

## Context / references

- `.claude/rules/mcp-recipes.md` — sibling capacity pattern; this spec is a new recipe following the same opt-in posture (`.mcp.json.example` + SessionStart hint + BYO API key)
- `.claude/rules/secrets-scan.md` — `FAL_KEY` handling; gitleaks should already cover generic API-key patterns, verify fal.ai key shape
- `.claude/rules/supply-chain.md` — npm-install gate triggers on MCP package install; relates to Open Q5
- `.claude/rules/delegation.md` § Why DONE_WHEN exists — contract-not-promise frame motivates pre-call cost printing (the user has a verifier before the side-effect happens)
- `.claude/skills/skill/` — `/skill validate image` will gate compliance per agentskills.io spec
- Research conducted 2026-05-24 (cited in `plan.md`):
  - [fal.ai official MCP setup docs — hosted HTTP MCP at `mcp.fal.ai/mcp`, 1000+ models](https://fal.ai/docs/documentation/setting-up/mcp)
  - [fal.ai blog — "Connect your AI to 1,000+ models with the fal MCP Server"](https://blog.fal.ai/connect-your-ai-to-1-000-models-with-the-fal-mcp-server/)
  - [fal.ai Models page — confirms multi-provider hosting (OAI gpt-image, Imagen 4, FLUX, etc.)](https://fal.ai/models)
  - [piebro/fal-ai-mcp-server — community alternative (npm/PyPI)](https://github.com/piebro/fal-ai-mcp-server)
  - [lansespirit/image-gen-mcp — alt MCP carrying OAI + Imagen directly](https://github.com/lansespirit/image-gen-mcp)
  - [fal.ai vs Replicate 2026 comparison](https://www.teamday.ai/blog/fal-ai-vs-replicate-comparison)
  - [OpenAI Image pricing 2026 — DALL-E 3 discontinued 2026-05-12](https://invertedstone.com/calculators/dall-e-pricing)
  - [Google Imagen 4 announcement](https://developers.googleblog.com/imagen-4-now-available-in-the-gemini-api-and-google-ai-studio/)
- Conversation 2026-05-24 — initial provider survey, multi-provider vs single-aggregator decision, standalone-skill-no-cross-integration choice
