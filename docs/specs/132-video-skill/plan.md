# 132 — video-skill — plan

_Drafted from `spec.md` on 2026-05-31. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Build `/video` as a portable Agent0 skill that structurally mirrors `/image` (canonical body + symlinks + `openai.yaml` + helper scripts + capacity rule + refreshable references) but routes a **required `--mode`** to two independent helper paths that share almost nothing beyond the top-level invocation and the `assets/` + manifest conventions. The build is bottom-up so each layer is testable before the next depends on it:

1. **Shared fal REST lib** — `.agent0/tools/fal-rest.sh` (non-discoverable path): pure curl/jq primitives for `submit` / `status` / `result` / `download` against `queue.fal.run`, plus a manifest-append helper. No image- or video-specific fields; callers pass model-id + JSON body. This is the DRY core the generative mode consumes (and a future decoupled spec migrates `/image` onto).
2. **Generative mode** — `scripts/gen.sh` with subcommands `prepare` (resolve tier→model from `references/video-tiers.yaml`, compute estimate, enforce `--confirm-cost-usd` gate, emit envelope), `submit` (POST → `request_id`, append to job ledger), `poll [--all|--id]` (GET status; on COMPLETED, GET response, download asset, append manifest), `record` (terminal success/failure). Async is **fire-and-forget ledger**, never a blocking loop.
3. **Code mode** — `scripts/code.sh`: scaffold a composition from an Agent0-**owned** template, render via pinned `npx hyperframes@0.6.64 render`, compute the render fingerprint, append manifest. Tracks HTML source, gitignores MP4.
4. **Skill surface** — `SKILL.md` (router + `--mode`-required error), `agents/openai.yaml` (`allow_implicit_invocation: false`), discovery symlinks, capacity rule `.agent0/context/rules/video-gen.md`, `.gitignore` + `assets/` dirs, entrypoint index blocks, runtime-capabilities row, harness-sync baseline registration.
5. **Tests + activation paths** — error-clean-when-unactivated, dependency-absent fail-clean, `--mode` required, gate refusal, multi-runtime discovery.

This shape is chosen because the two modes have genuinely disjoint failure surfaces (local deterministic render vs paid remote async) — forcing them through one helper would create a fake abstraction (the debate's R5 conclusion), while two skills would fracture the user's single "make a video" intent (R1/R5).

### Open-question resolutions (recommended; user can override before `/sdd tasks`)

- **HyperFrames pin + invocation** → pin `hyperframes@0.6.64`, invoke **ephemerally via `npx hyperframes@0.6.64`** (no forced consumer `package.json` devDependency — preserves zero-cost-if-unused; a consumer may add the devDep for render-cache speed). A `routine` tracks the pin for pre-1.0 churn.
- **Seed tiers/models** (`video-tiers.yaml`, snapshot 2026-05-31, refreshable) → 3 tiers: `draft` = Wan 2.2 class (~$0.10/s, 720p, fast iteration); `standard` = Kling class (multi-angle consistency, ~$0.11/s, 1080p); `premium` = Veo 3.1 class (4K + audio, $0.20–0.60/s). Exact current endpoint IDs resolved at implementation via fal discovery — the table is the oracle, not the skill body.
- **Job ledger + poll UX** → JSONL ledger at `.agent0/.runtime-state/video-jobs/ledger.jsonl` (gitignored, same posture as codex-exec runtime state). Poll is **explicit** `/video poll [--all | --id=<request_id>]`; no auto-poll in v1 (keeps it runtime-neutral and simple).
- **Estimate vs actual cost** → **record-and-warn**, never hard-fail mid-flight (the job is already submitted/billed by the time overrun is detectable; failing can't un-bill). The gate is pre-submit (`--confirm-cost-usd ≥ estimate`); the manifest records both `cost_estimate_usd` and `cost_actual_usd`, and emits a `video-advisory:` if actual exceeds the ceiling.
- **Storage roots** → mirror `/image`'s split: generative throwaway → `assets/generated/videos/` (gitignored); durable → `assets/video/` (tracked). Code-mode composition **source** → `assets/video/compositions/<slug>/` (tracked HTML); its rendered MP4 → `assets/generated/videos/` (gitignored, regenerable).

## Files to touch

**Create:**
- `.agent0/skills/video/SKILL.md` — invocation surface: parse `--mode` (required), route to helper, mode-required + unactivated error messages
- `.agent0/skills/video/agents/openai.yaml` — Codex manifest; `allow_implicit_invocation: false` (paid/side-effecting)
- `.agent0/skills/video/scripts/gen.sh` — generative `prepare`/`submit`/`poll`/`record`
- `.agent0/skills/video/scripts/code.sh` — HyperFrames scaffold/render/fingerprint/record
- `.agent0/skills/video/references/video-tiers.yaml` — date-stamped tier→model table (refreshable)
- `.agent0/skills/video/references/authoring.md` — Agent0-owned HTML composition guidance (the owned authoring layer; cites HyperFrames `data-*` conventions as prior art)
- `.agent0/skills/video/references/composition-template/` — minimal starter composition(s) the skill scaffolds from
- `.agent0/tools/fal-rest.sh` — shared fal queue REST primitives (submit/status/result/download + manifest append)
- `.agent0/context/rules/video-gen.md` — capacity rule (activation, two modes, storage, manifest schema, cost gate, gotchas, Higgsfield-as-optional-provider, refresh discipline)
- `.claude/skills/video` → symlink to `../../.agent0/skills/video` (Claude discovery)
- `.agents/skills/video` → symlink to `../../.agent0/skills/video` (Codex discovery)
- `assets/video/.gitkeep`, `assets/video/compositions/.gitkeep`, `assets/generated/videos/.gitkeep` — storage roots
- `.agent0/tests/video/` — activation/error/gate/discovery tests (shellcheck + behavior)

**Modify:**
- `.gitignore` — add `assets/generated/videos/*` (with `!.gitkeep`) and `.agent0/.runtime-state/video-jobs/`
- `CLAUDE.md` — add `## Video generation` entry to the managed index block (mirrors the `## Image generation` entry)
- `AGENTS.md` — same index entry (Codex entrypoint; baseline-tracked)
- `.agent0/context/rules/runtime-capabilities.md` — add a `video generation` capability row (`native-opt-in` / `native-opt-in`), owner files, multi-runtime note
- `.mcp.json.example` / `.codex/config.toml.example` — annotate that the existing `fal-ai` block already covers video model discovery (no new block; reuse)
- `.agent0/harness-sync-baseline.json` — register the new managed files so sync-harness propagates them
- `.agent0/memory/MEMORY.md` + a new memory entry — only if a non-obvious project fact emerges during build (optional; capacity itself ships via the rule, not memory)

**Delete:**
- none

## Alternatives considered

### Remotion instead of HyperFrames for code mode
Rejected — debate-locked. Remotion's per-org paid license (free only ≤3 employees) creates a per-consumer activation gate that fights harness propagation; HyperFrames is Apache-2.0 with no threshold, and HTML authoring is more reliable for LLM-generated compositions.

### Vendor the upstream HyperFrames agent-skill into `.agent0/skills/video/`
Rejected (debate R1) — it is a second agentskills.io discovery surface Agent0 can't version-control inside its one-canonical + symlink model, and activating it implies a checkout-mutating `npx skills add`. We depend on the pinned npm **engine** and **own** the authoring layer instead.

### Blocking poll loop inside `exec` (one invocation renders + waits)
Rejected (debate R2) — serializes a multi-clip storyboard into 40+ minutes of held session and depends on background semantics that differ across runtimes. Fire-and-forget ledger + explicit `poll` is non-blocking, batch-friendly, and runtime-neutral.

### Reuse `/image`'s `gen.sh` for generative video
Rejected (debate Q5) — `gen.sh` bakes image-specific fields (`image_size`, `.images[0].url`, aspect tables, dimension reconciliation). Shared logic goes in a clean `.agent0/tools/fal-rest.sh`; `/image` migrates onto it in a decoupled follow-up, not here.

### Two separate skills (`/video` = code, video tiers folded into `/image`)
Rejected (debate R5) — fractures the cohesive "make a video" intent and overloads `/image` with synchronous-image assumptions. One `/video` with required `--mode` and honestly-separated internals.

## Risks and unknowns

- **HyperFrames render CLI flag surface is under-documented** — settings come from HTML `data-*` attributes + project config, and `npx hyperframes init` implies a *project* scaffold, not a loose-HTML render. Implementation must verify the exact `render` invocation (input/output/fps/duration flags) via `npx hyperframes@0.6.64 --help` and may need to scaffold a per-composition project dir. **First task is a spike** to pin this down.
- **HyperFrames is pre-1.0 (v0.6.x)** — API/flags may shift between minors; the pin + a refresh routine mitigate, but a major bump could require helper changes.
- **fal video endpoint IDs drift** — `video-tiers.yaml` is refreshable and discovery-backed; the warn-after-45–60-days mechanism surfaces staleness.
- **Determinism is conditional** — HyperFrames' "same input, same output" assumes pinned Chromium + identical font availability; fonts especially drift across machines. The render fingerprint *records* this but cannot *prevent* cross-machine divergence. Document as a known limit, don't over-promise reproducibility.
- **Heavy local deps in CI** — code-mode render needs Node 22+/Chromium/ffmpeg; consumer CI may lack them. The skill declares deps and fails clean; we will NOT add a render step to Agent0's own CI gates (keeps CI light) — tests cover the wrapper logic, not an actual MP4 render, unless a deps-present guard passes.
- **Generative cost runaway from a delegated sub-agent loop** — the confirm gate is per-call; no per-session counter in v1 (accepted, mirrors `/image`). Revisit if empirical drift appears.
- **`assets/` directory propagation** — sync-harness ships the `.gitkeep` skeleton but not content (same posture as `/image`); confirm the baseline registration doesn't try to sync rendered output.

## Research / citations

- HyperFrames — [github.com/heygen-com/hyperframes](https://github.com/heygen-com/hyperframes) (Apache-2.0, v0.6.64, 2026-05-31; `npx hyperframes init|preview|render`, `data-*` composition settings, Node 22+/ffmpeg/Chromium, deterministic, audio).
- fal.ai queue REST — [fal.ai/docs/model-endpoints/queue](https://fal.ai/docs/model-endpoints/queue) (`POST queue.fal.run/{model}` → `request_id`/`status_url`/`response_url`; `GET .../status`; `GET .../response`; `PUT .../cancel`; `Authorization: Key $FAL_KEY`; optional `?fal_webhook=`).
- fal.ai video model pricing/capabilities — [fal.ai/learn/tools/ai-video-generators](https://fal.ai/learn/tools/ai-video-generators), [fal.ai/pricing](https://fal.ai/pricing) (Wan/Kling/Veo per-second bands for tier seeding).
- `/image` exemplar — `.agent0/skills/image/SKILL.md`, `.agent0/context/rules/image-gen.md`, `.agent0/skills/image/scripts/gen.sh` (prepare/exec/record, cost gate, manifest, REST-not-MCP generation per spec 088).
- Multi-runtime skill pattern — `.agent0/context/rules/runtime-capabilities.md` (spec 121), `.claude/skills/skill/references/portability-tiers.md`.
- Cross-model debate — `docs/specs/132-video-skill/debate.md` (Claude Code ↔ Codex CLI, converged); motivator [dfolloni substack](https://dfolloni.substack.com/p/como-eu-faco-videos-profissionais).
