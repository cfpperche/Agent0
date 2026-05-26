# 088 — image-skill-curl-exec — plan

_Drafted from `spec.md` on 2026-05-25. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Add a third subcommand `exec` to `.claude/skills/image/scripts/gen.sh` that consumes the `prepare`-shape JSON envelope and performs the generation via curl: POST to `https://fal.run/<endpoint>` with `Authorization: Key $FAL_KEY` + JSON body `{prompt, image_size, quality (for gpt-image-2)}`, parse `images[0].url` from the response, follow-up GET to download the image bytes into `output_path`. The helper also performs **post-generation dimension reconciliation** for the gpt-image-2 min-pixel-floor case (1024×576 → 1088×608 upscale): if `ffmpeg` is available and actual ≠ expected dims, downscale in place; otherwise emit `image-skill-advisory:` to stderr and leave the file untouched. The SKILL.md `## Invocation flow` § step 4 is rewritten from "Invoke MCP" to "Invoke `gen.sh exec`" — the agent now calls bash, not a fal-ai MCP tool, for generation. Steps 5 (write output) and 6 (append manifest) collapse: write happens inside `exec`; manifest still uses `record` as today.

The MCP recipe in `.mcp.json.example` is unchanged — fal-ai stays activatable for discovery tools (`search_models`, `get_model_schema`, `get_pricing`, `recommend_model`). Discovery is HTTP-fast and a genuine value-add for agents picking the right tier; only `run_model` was broken. `.claude/rules/image-gen.md` is updated in two places: § *Activation* clarifies that MCP recipe activation is now **optional** for generation (required only for discovery), and § *Gotchas* gets a new bullet documenting the 2026-05-25 diagnosis with a pointer to this spec. `references/tier-pricing.md` adds a § *gpt-image-2 min-pixel floor* note + bumps brand-text approx cost from `~$0.04 (low)` to `~$0.20 (high)` to match the schema default.

## Files to touch

**Create:**
- (none — all changes are in-place)

**Modify:**
- `.claude/skills/image/scripts/gen.sh` — add `sub_exec()` (~80 LOC: arg parse → curl POST → response parse → download → dim-check + optional ffmpeg downscale → JSON receipt on stdout). Dispatch case at bottom adds `exec) shift; sub_exec "$@" ;;`. Help text updated to list 3 subcommands.
- `.claude/skills/image/SKILL.md` — § *Invocation flow* step 4 rewritten (MCP → exec); § *Helper script* updated to mention the 3 subcommands; § *Notes* gets a sentence on the hybrid pattern (MCP for discovery, curl for execution).
- `.claude/rules/image-gen.md` — § *Activation* note that step 1 (`.mcp.json` recipe) is now optional for generation; § *Gotchas* new entry `MCP run_model is broken upstream — execution goes through curl`.
- `.claude/skills/image/references/tier-pricing.md` — bump brand-text approx cost to `~$0.20`; add § *gpt-image-2 min-pixel floor* explaining the dim drift + downscale convention.

**Delete:**
- (none — backward-compatible refactor; no removals)

## Alternatives considered

### Full MCP-only fallback (community stdio MCP)

Replace `https://mcp.fal.ai/mcp` with `piebro/fal-ai-mcp-server` (community stdio) as the default. Rejected because:

1. **Same broken substrate.** Both servers ultimately POST to fal.ai's REST. The hosted-MCP failure mode is a transport/auth bug specific to the Vercel-hosted server; switching to a community MCP would likely sidestep this specific instance, but introduces a new failure mode (`npx -y` supply-chain risk, maintenance status of a single-individual repo, content-type drift between server implementations).
2. **Still goes through the CC MCP-client.** The mis-render of MCP timeout as `"user doesn't want to proceed"` is a CC bug (see partial issues #16837 / #20335 / #3273). Any MCP-based path inherits it.
3. **No discovery upside.** Community MCPs lack `search_models` / `get_pricing` / etc. — they're generation-only wrappers. Switching loses the discovery value that motivates keeping the official MCP.

Hybrid (this spec) preserves discovery + bypasses both bugs with a 60-LOC bash addition.

### Pure-Python rewrite via `httpx` / `requests`

Replace bash gen.sh with a Python helper invoking fal.ai via `fal-client` (their official SDK) or raw `httpx`. Rejected because:

1. **Dependency cost.** The skill currently has zero Python runtime dep (only bash + jq + python3 inline for json_escape). Adding `pip install fal-client` re-introduces the supply-chain-scan friction the dogfood already hit today (Pillow case). Forks would need to provision Python deps.
2. **No reasoning gain.** The curl path is ~30 lines of bash + jq parse. A Python rewrite is the same logic in 50 lines + the dep cost.
3. **Future-proofing for async is not a blocker now.** When the async path is added (separate spec), Python may become attractive — but for sync execution at the v1 tier list, bash + curl is the lighter primitive.

### Inline the curl call in SKILL.md prose (no helper subcommand)

Have the agent invoke curl directly via Bash tool calls per SKILL.md instructions, no `gen.sh exec` wrapper. Rejected because:

1. **Loss of test surface.** A subcommand can be smoke-tested in isolation (`bash gen.sh exec '<envelope>'`); inline prose is only verifiable end-to-end through the agent.
2. **Drift risk.** Three forks could diverge on how the curl call is shaped (auth header, response parsing, dim handling). The helper is the canonical implementation.
3. **Manifest cohesion.** Today `prepare` and `record` are the two helper subcommands; `exec` slotting between them is the natural extension. Splitting execution out to prose breaks the 3-stage symmetry.

## Risks and unknowns

- **`gpt-image-2` content-type assumption.** Spec 085 documented it as `image/png` "documented assumption, verify on first invocation". Codexeng's empirical dogfood confirms PNG (568 KB / 408 KB post-downscale, all PNG). `imagen4/ultra` is still unverified empirically — the helper should not assume PNG body parsing; it should treat the response as opaque bytes and use the `extension` from the prepare envelope.
- **`fal.run` does NOT redirect to a CDN URL pre-baked into the response.** The actual returned shape is `{"images":[{"url":"https://v3b.fal.media/files/...", "content_type":"image/png", ...}]}` — the URL is to fal.media (CDN), separate request. `sub_exec` needs the two-hop flow: POST to fal.run, GET to fal.media. Codexeng's manual workaround confirms this shape; the helper inherits the pattern.
- **Rate limits / 429.** fal.ai has per-key rate limits not documented as hard numbers. The helper does not implement retry-with-backoff in v1 — a 429 surfaces as failure and the agent decides whether to retry. Adding retry is straightforward future work.
- **Auth header word.** REST uses `Authorization: Key $FAL_KEY` (per fal.ai docs); MCP uses `Authorization: Bearer $FAL_KEY` (per CC's `.mcp.json` config). The helper MUST use `Key`. `image-gen.md` § *Gotchas* already documents this (line 144); the helper code needs an inline comment so future maintainers don't "fix" it to Bearer.
- **`ffmpeg` detection.** `command -v ffmpeg` is the canonical check; on WSL2 and many minimal Linux setups ffmpeg is not installed by default. The graceful-degrade path is the safe answer — the file is still usable at 1088×608; AC ceilings tolerate 6% drift in flat-vector outputs (codexeng's V2 verification confirmed this empirically).
- **CC session resumability.** This refactor changes the SKILL.md prose. A long-running CC session that loaded the OLD SKILL.md doesn't pick up the new prose without restart. Not a blocker — the next call after a session restart uses the new flow; old sessions just won't benefit from the fix.

## Research / citations

- **codexeng `docs/specs/004-brand-visual-style/notes.md`** § Deviations — primary evidence base (today's diagnosis logs).
- **fal.ai REST sync endpoint docs** — [`https://docs.fal.ai/model-apis/model-endpoints/sync`](https://docs.fal.ai/model-apis/model-endpoints/sync) — confirms `https://fal.run/<model_id>` shape + `Authorization: Key` header.
- **fal.ai MCP setup docs** — [`https://fal.ai/docs/documentation/setting-up/mcp`](https://fal.ai/docs/documentation/setting-up/mcp) — confirms closed-source Vercel-hosted server + `submit_job` recommendation for long-running models.
- **gpt-image-2 schema** — `mcp__fal-ai__get_model_schema` output (during codexeng dogfood) — declared `total pixels between 655,360 and 8,294,400`; explains the upsampling of 1024×576 → 1088×608.
- **Agent0 spec 085** — `docs/specs/085-image-gen-opt-in/` — the predecessor capacity this refactor amends.
- **CC partial-match issues** — anthropics/claude-code [#16837](https://github.com/anthropics/claude-code/issues/16837), [#20335](https://github.com/anthropics/claude-code/issues/20335), [#3273](https://github.com/anthropics/claude-code/issues/3273) — none cover composite signature; inform diagnosis only.
