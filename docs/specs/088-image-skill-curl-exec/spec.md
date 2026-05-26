# 088 — image-skill-curl-exec

_Created 2026-05-25._

**Status:** shipped

## Intent

Refactor the `/image` skill so the image-generation call goes through **direct curl to `fal.run` REST** instead of `mcp__fal-ai__run_model`. The fal.ai hosted MCP at `https://mcp.fal.ai/mcp` was empirically diagnosed today (2026-05-25, codexeng dogfood, spec 004) to hang ≥990s server-side on `gpt-image-2` while the same `FAL_KEY` against the REST endpoint returns HTTP 200 in ~80s. Claude Code's MCP-client compounds the failure by surfacing the timeout as the canonical `"The user doesn't want to proceed with this tool use"` string — making the MCP path actively misleading, not just slow. The fal.ai MCP is closed-source (Vercel-hosted stateless API; no upstream fix path), so the architectural response is to move execution off the MCP transport. Discovery tools (`search_models`, `get_model_schema`, `get_pricing`, `recommend_model`) stay on MCP — they're HTTP-fast and useful for agent-side model selection. Hybrid: **MCP for introspection, REST for generation.**

## Acceptance criteria

- [x] **Scenario: draft tier end-to-end via curl**
  - **Given** `FAL_KEY` is set and `.claude/skills/image/scripts/gen.sh exec` is invoked with a `prepare`-shape JSON envelope for `draft`
  - **When** the helper POSTs to `https://fal.run/fal-ai/flux/schnell` with `Authorization: Key $FAL_KEY`
  - **Then** the response returns HTTP 200 within 10s, the image is downloaded to the resolved `output_path`, and exit code is 0

- [x] **Scenario: brand-text dimension drift auto-handled**
  - **Given** a `brand-text` call with `--aspect=landscape` (asks for 1024×576) and `ffmpeg` available on PATH
  - **When** `gpt-image-2` returns 1088×608 (above 655,360-pixel floor) and the helper detects actual ≠ expected dims
  - **Then** the helper invokes `ffmpeg -vf scale=1024:576` in place and reports both dims (`returned: 1088x608 → downscaled: 1024x576`) on stdout

- [x] **Scenario: ffmpeg absent on dimension drift**
  - **Given** the same drift case as above but `ffmpeg` is NOT on PATH
  - **When** the helper detects the dim mismatch
  - **Then** the helper emits `image-skill-advisory: returned 1088x608, expected 1024x576; install ffmpeg to auto-downscale` on stderr, leaves the file at the returned dims, and exits 0 (the file is still usable; the advisory is informational)

- [x] **Scenario: FAL_KEY absent fails clean before curl**
  - **Given** `FAL_KEY` is unset when `gen.sh exec` is invoked
  - **When** the helper enters the exec dispatch
  - **Then** the helper exits 2 with the same `die_no_fal_key` template `prepare` uses today (no network call attempted, no manifest line written)

- [x] **Scenario: fal.run returns non-200**
  - **Given** the curl POST returns HTTP 4xx or 5xx (bad prompt, rate limit, fal.ai outage)
  - **When** the helper parses the response
  - **Then** the helper emits the response body to stderr, exits non-zero, AND `gen.sh record` (called by the agent) writes a manifest line with `"status":"failure"` so the audit trail survives

- [x] **Scenario: cost pre-print contract preserved**
  - **Given** any tier invocation through the agent flow
  - **When** the user reads stdout
  - **Then** the `estimated: $X.XXX for <model> at <dims>` line appears BEFORE the curl POST fires (same shape, same position as before the refactor) — the contract surface defined in `.claude/rules/image-gen.md` § *Error on omitted tier* / *Trust posture* stays intact

- [x] **Scenario: MCP recipe still useful for discovery**
  - **Given** a fork has `.mcp.json` with the fal-ai recipe active
  - **When** the agent invokes `mcp__fal-ai__get_model_schema` or `mcp__fal-ai__get_pricing` (NOT `run_model`)
  - **Then** the calls succeed normally — the refactor does not break discovery-tool access; only generation moves off MCP

- [x] `.claude/skills/image/scripts/gen.sh` exposes a third subcommand `exec` (alongside `prepare`/`record`)
- [x] `.claude/skills/image/SKILL.md` § *Invocation flow* updates step 4 from "Invoke MCP" to "Invoke `gen.sh exec`"; step 5 is absorbed into exec (download happens inside the helper, not as a separate agent action)
- [x] `.claude/rules/image-gen.md` § *Gotchas* adds an entry documenting the 2026-05-25 MCP fal-ai diagnosis with a one-line summary + pointer to this spec
- [x] `.claude/skills/image/references/tier-pricing.md` adds a § *gpt-image-2 min-pixel floor* note explaining the dimension drift cause (655,360 px floor → landscape/portrait upscale)
- [x] The skill no longer fails at "MCP not registered" — it runs end-to-end with only `FAL_KEY` set (MCP recipe activation becomes optional for the generation path, required only for discovery)
- [x] A draft-tier smoke test (`/image --tier=draft "a red circle"`) succeeds end-to-end on the Agent0 repo using the new path, evidenced by an `assets/generated/.manifest.jsonl` entry with `"status":"success"`

## Non-goals

- **Async path** (`submit_job` + `check_job`). All 3 current tiers complete in <2 min synchronously; async is over-engineering for v1. When/if `brand-video` or `brand-3d` tiers are added, async becomes a real requirement — separate spec.
- **MCP recipe removal.** The fal-ai MCP block stays in `.mcp.json.example`; it just no longer covers generation. Discovery tools remain valuable.
- **Multi-image generation** (`num_images > 1`). Single image per call, same as today.
- **Provider abstraction beyond fal.ai.** Community fallback MCPs documented in `image-gen.md` § *Trust posture* are unchanged. The curl path is fal.ai-specific by design; abstracting it would require a generic image-provider interface — out of scope.
- **Re-doing tier selection logic.** Same 3 tiers, same flag shape, same path derivation, same naming convention. The refactor is execution-only.
- **Filing the upstream bugs.** The founder will manually file the fal.ai Discord post + `anthropics/claude-code` issue (see codexeng spec 004 § Deviations). This spec lands the workaround; the upstream-issue tracking lives in `r-` reminders, not here.

## Open questions

- [ ] **Quality flag for brand-text** — `gpt-image-2` defaults to `quality=high` ($0.20) per the fal.ai schema. The current `TIER_TABLE` hardcodes $0.040 (low). Options:
  1. Bake `quality=high` + update TIER_TABLE cost to $0.20 (worst-case, no surprises, AC ceiling aligns).
  2. Add `--quality=low|medium|high` flag with `high` default + lookup table mapping (tier, quality) → cost.
  Recommendation: **option 1** for v1 (simpler, matches what codexeng dogfood needed). Promote to option 2 if a fork asks for cost-sensitive low/medium runs. Owner: founder.
- [ ] **Auto-downscale strategy** — graceful-degrade (advisory + leave-as-is) vs hard-require ffmpeg. Recommendation: **graceful-degrade** — keeps the skill installable on minimal environments; the advisory is high-signal. Owner: founder.
- [ ] **Promotion of `image-gen.md` Gotcha** — the codexeng note flagged "one more independent confirmation" before promoting from notes → rule. This spec IS that second confirmation (Agent0 is fixing the default to avoid the bug). Recommendation: **promote in this spec's commit**. Owner: founder.

## Context / references

- **codexeng `docs/specs/004-brand-visual-style/notes.md` § Deviations** entry `2026-05-25 (late) — MCP fal-ai diagnosis closed` — full log evidence (21,655 `"No token data found"` polls in 1.14s cadence; `run_model still running 990s+`; curl HTTP 200 in 80s).
- **Agent0 spec 085** (`image-gen-opt-in`) — what this evolves. Shipped 2026-05-24; this spec is the empirically-driven correction.
- **fal.ai docs** [`https://fal.ai/docs/documentation/setting-up/mcp`](https://fal.ai/docs/documentation/setting-up/mcp) — confirms hosted MCP is closed-source Vercel-hosted, recommends `submit_job`+`check_job` for long-running models.
- **fal.ai REST API** [`https://docs.fal.ai/model-apis/model-endpoints/sync`](https://docs.fal.ai/model-apis/model-endpoints/sync) — synchronous endpoint at `https://fal.run/<model_id>`, header `Authorization: Key $FAL_KEY`.
- **Partial CC issue matches** (none cover composite signature, but inform diagnosis):
  - [anthropics/claude-code#16837](https://github.com/anthropics/claude-code/issues/16837) — MCP_TIMEOUT ignored
  - [anthropics/claude-code#20335](https://github.com/anthropics/claude-code/issues/20335) — Streamable SSE HTTP timeout
  - [anthropics/claude-code#3273](https://github.com/anthropics/claude-code/issues/3273) — `"No token data found"` tied to servers without DCR
- **`.claude/rules/image-gen.md`** — the capacity rule this spec amends.
- **`.claude/rules/spec-driven.md`** — the SDD discipline this spec follows.
