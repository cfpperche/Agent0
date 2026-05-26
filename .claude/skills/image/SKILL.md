---
name: image
description: AI image generation via fal.ai (opt-in MCP recipe). Use when the user wants to produce a mockup, brand asset, or hero image for the project. Three tiers cover the cost/quality spectrum - draft (FLUX schnell, ~$0.003/img, jpg, throwaway), brand-text (gpt-image-2, $0.04-0.20/img, png, crisp typography), brand-photo (Imagen 4 Ultra, ~$0.06/img, png, photo-real). Tier flag is REQUIRED - omitted tier errors with the three options. Optional --aspect=square|landscape|portrait (default square) sets image_size. Output paths are mechanical (draft → gitignored assets/generated/mockups/, brand-* → tracked assets/brand/), extension matches tier's default content-type. Every call prints estimated cost BEFORE invoking the MCP. Activation - copy fal-ai block from .mcp.json.example, set FAL_KEY env var, restart session. See .claude/rules/image-gen.md.
argument-hint: <--tier=draft|brand-text|brand-photo> [--aspect=square|landscape|portrait] [--name=<slug>] "<prompt>"
license: MIT
compatibility: Designed for Claude Code. Body references `.claude/` conventional paths and CC-specific MCP tool invocation; portable to any runtime that surfaces a fal.ai MCP server (official hosted at mcp.fal.ai/mcp, or community packages like piebro/fal-ai-mcp-server). Requires bash + jq; no Python dependency. Network connectivity required (hosted MCP) unless using a stdio community fallback.
metadata:
  agent0-portability-tier: cc-native
  version: "0.1"
---

# /image — AI image generation

Generate images via fal.ai's hosted MCP. Opt-in capacity — forks that don't activate the `fal-ai` recipe in `.mcp.json` pay zero cost. The skill is a thin wrapper: it parses the tier flag, derives the output path, prints the estimated cost, then delegates to the MCP. Cost discipline: every call prints `estimated: $X.XXX for <model> at <resolution>` BEFORE the MCP fires, so a parent agent or human can ctrl-c if the estimate is wrong-shape.

See `.claude/rules/image-gen.md` for the full capacity rule (activation, tier semantics, storage policy, manifest shape, override marker, trust posture, community fallbacks). This SKILL.md documents the invocation surface only.

## Argument parsing

User invokes as `/image <--tier=...> [--name=<slug>] "<prompt>"`. The raw argument string is `$ARGUMENTS`. Parse it yourself: extract `--tier=<value>`, optional `--name=<value>`, and the prompt (the remaining non-flag tokens, typically a quoted string). Do not rely on `$1` / `$2` — order is flag-then-prompt OR prompt-then-flag, both work.

Required flag:

- `--tier=draft` — `fal-ai/flux/schnell`, ~$0.003/img, returns JPEG, output to `assets/generated/mockups/<YYYY-MM-DD>-<slug>.jpg` (gitignored)
- `--tier=brand-text` — `fal-ai/gpt-image-2`, $0.04-0.20/img, returns PNG, output to `assets/brand/<slug>.png` (tracked)
- `--tier=brand-photo` — `fal-ai/imagen4/ultra`, ~$0.06/img, returns PNG, output to `assets/brand/<slug>.png` (tracked)

Optional flags:

- `--aspect=square|landscape|portrait` — image aspect ratio (default `square`). Maps to fal.ai's `image_size` enum: square→`square_hd` (1024×1024), landscape→`landscape_16_9` (1024×576, ideal for banners/heroes), portrait→`portrait_16_9` (576×1024, ideal for mobile/vertical).
- `--name=<slug>` — override the auto-derived slug. Use when the prompt produces a messy or non-ASCII filename. Kebab-case required (`^[a-z][a-z0-9-]*$`); script errors if invalid.

If `--tier` is missing, error with the three-option message:

```
/image error: --tier is required. Pick one:
  --tier=draft       cheap mockup       (~$0.003/img, FLUX schnell)
  --tier=brand-text  premium with text  ($0.04-0.20/img, gpt-image-2)
  --tier=brand-photo premium photo-real (~$0.06/img, Imagen 4 Ultra)
```

If `FAL_KEY` is unset OR `.mcp.json` is missing the `fal-ai` block, error with a one-screen message pointing at `.mcp.json.example` and `.claude/rules/image-gen.md` § *Activation*. No silent fallback.

## Invocation flow

1. **Parse args.** Validate `--tier`, extract prompt, resolve `--name` or auto-derive (`kebab(first 5 words)`).
2. **Resolve model + cost.** Read tier → model endpoint and approx cost from `.claude/skills/image/references/tier-pricing.md`. Compute output path.
3. **Print cost estimate.** Emit `estimated: $X.XXX for <model> at <dims>` to stdout BEFORE the generation call. This is the contract surface; do not skip. (Done by `gen.sh prepare`.)
4. **Invoke `gen.sh exec`.** Pass the JSON envelope emitted by `prepare` to `bash .claude/skills/image/scripts/gen.sh exec --envelope='<json>'`. The helper POSTs to `https://fal.run/<model>` with `Authorization: Key $FAL_KEY`, downloads the returned image to `output_path`, and on gpt-image-2 dim drift auto-downscales via `ffmpeg` (or emits an advisory if ffmpeg is absent). Generation goes through REST curl, NOT the `mcp__fal-ai__run_model` tool — see § *Notes* for the hybrid rationale and spec 088 for the diagnosis. Collision suffix (`-2`, `-3`, ...) is applied at `prepare` time.
5. **Append manifest.** Call `gen.sh record` with the envelope's tier/model/cost/prompt + the exec receipt's output_path + dimensions. One JSONL line per call into `assets/generated/.manifest.jsonl` with the 9-field schema (`ts`, `session_id`, `tier`, `model`, `cost_usd`, `prompt`, `output_path`, `dimensions`, `status`). On `exec` failure, still call `record` with `--status=failure` so the audit trail survives.
6. **Report.** Print the output path and a brief one-line summary.

## Helper script

All logic lives in `.claude/skills/image/scripts/gen.sh`. Three subcommands form the agent-driven pipeline:

```bash
# 1. prepare — validate inputs, print cost estimate, emit JSON envelope
CLAUDE_PROJECT_DIR="$CLAUDE_PROJECT_DIR" \
  bash .claude/skills/image/scripts/gen.sh prepare \
    --tier=<value> [--name=<slug>] [--aspect=<...>] "<prompt>"
# (capture the JSON envelope from stdout's last line)

# 2. exec — POST to fal.run REST, download image, reconcile dims, emit JSON receipt
FAL_KEY="$FAL_KEY" CLAUDE_PROJECT_DIR="$CLAUDE_PROJECT_DIR" \
  bash .claude/skills/image/scripts/gen.sh exec --envelope='<json-from-prepare>'

# 3. record — append manifest line (success or failure, both are recorded)
bash .claude/skills/image/scripts/gen.sh record \
  --tier=<from-envelope> --model=<...> --cost=<...> --prompt="<...>" \
  --output=<from-receipt> --dims=<from-receipt> [--status=success|failure]
```

The 3-stage shape is deliberate — generation is the network-bound step, `prepare` is the contract surface (cost print + path derivation), `record` is the audit step. The agent coordinates the three calls and surfaces failures from `exec` verbatim.

## Examples

```bash
# Cheap mockup for prototype work (default square)
/image --tier=draft "dashboard with three charts and a sidebar nav"

# Landscape banner mockup (1024×576)
/image --tier=draft --aspect=landscape "developer at desk with code on screens, banner composition"

# Brand logo with crisp text (default square)
/image --tier=brand-text --name=hero-logo "minimalist logo for Agent0, monospace 'A0', deep blue"

# Photo-real hero banner for marketing page (1024×576)
/image --tier=brand-photo --aspect=landscape --name=hero "team of engineers collaborating in a sunlit modern office, candid photo"

# Portrait mobile-screen mockup (576×1024)
/image --tier=draft --aspect=portrait "mobile app onboarding flow screen, clean modern design"
```

## Cross-references

- `.claude/rules/image-gen.md` — capacity rule (activation, semantics, gotchas, community fallbacks)
- `.claude/skills/image/references/tier-pricing.md` — static cost table (refresh quarterly)
- `.claude/skills/image/scripts/gen.sh` — runtime helper
- `.claude/rules/mcp-recipes.md` § *fal.ai MCP* — MCP recipe documentation

## Notes

_Fork-extension surface — append fork-local bullets to this section. Sync flags the file as `!! customized` (sha-compare is section-blind), but the conflict region is mechanically this section: take new upstream verbatim, re-add fork bullets at the end. See `.claude/rules/harness-sync.md` § Fork-extension convention._

- **Hybrid MCP + REST architecture.** The `.mcp.json` fal-ai recipe (optional now) covers discovery tools — `mcp__fal-ai__search_models`, `get_model_schema`, `get_pricing`, `recommend_model` — which the agent uses to pick the right tier intelligently. Generation routes through `gen.sh exec` (curl POST to `https://fal.run/<model>`) instead of `mcp__fal-ai__run_model`. The split exists because the hosted MCP's generation path was empirically diagnosed broken on 2026-05-25 (hangs ≥990s on gpt-image-2; CC client mis-renders the timeout as "user rejected"). See spec 088 for the full diagnosis. Forks without the MCP recipe still get full generation capability — only discovery is unavailable.
- **Brand-tier prompts should compose from a fork-local brand contract** (e.g. `docs/brand/styleguide.md`), not be ad-hoc. Image generators drift toward the stock median for vague prompts ("a banner" → generic SaaS banner, not your brand); the contract turns prompt-writing into transcription and makes drift visible at the contract level instead of at the asset. If your fork has no contract document, the prompt is ad-hoc — flag this in the call summary. `draft` tier is exempt. See `.claude/rules/image-gen.md` § *Brand-tier prompt composition*.
- The skill does NOT integrate with `/product` or `/prototype` in v1. Standalone — user invokes explicitly. Cross-skill coupling is deferred until either skill explicitly asks for image-gen.
- The skill does NOT enforce per-session cost budgets in v1. Pre-call cost printing is the only signal. Add a counter if empirical sub-agent drift surfaces.
- The skill does NOT cache prompt → output mappings. Every call hits fal.run. Deduplication is the user's responsibility.
