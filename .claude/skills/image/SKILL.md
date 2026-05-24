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
3. **Print cost estimate.** Emit `estimated: $X.XXX for <model> at 1024x1024` to stdout BEFORE any MCP tool call. This is the contract surface; do not skip.
4. **Invoke MCP.** Use the `mcp__fal-ai__*` tool surface (exact tool name depends on which fal.ai MCP is active — the official `mcp__fal-ai__run_model` or the community `mcp__fal-ai__generate_image`, depending on configuration). Pass the prompt and resolved endpoint.
5. **Write output.** Save the returned PNG bytes to the derived output path. Apply collision suffix (`-2`, `-3`, ...) if the path already exists.
6. **Append manifest.** Add one JSONL line to `assets/generated/.manifest.jsonl` with the 8-field schema (`ts`, `session_id`, `tier`, `model`, `cost_usd`, `prompt`, `output_path`, `dimensions`).
7. **Report.** Print the output path and a brief one-line summary.

## Helper script

All logic lives in `.claude/skills/image/scripts/gen.sh`. Invoke as:

```bash
CLAUDE_PROJECT_DIR="$CLAUDE_PROJECT_DIR" bash .claude/skills/image/scripts/gen.sh --tier=<value> [--name=<slug>] "<prompt>"
```

The script handles validation, cost printing, MCP invocation (via Claude Code's tool surface), file write, and manifest append. Forward stdout/stderr verbatim.

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

- The skill does NOT integrate with `/product` or `/prototype` in v1. Standalone — user invokes explicitly. Cross-skill coupling is deferred until either skill explicitly asks for image-gen.
- The skill does NOT enforce per-session cost budgets in v1. Pre-call cost printing is the only signal. Add a counter if empirical sub-agent drift surfaces.
- The skill does NOT cache prompt → output mappings. Every call hits the MCP. Deduplication is the user's responsibility.
