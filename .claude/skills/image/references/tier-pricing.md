# Tier pricing (fal.ai image models)

_Static reference table consumed by `.claude/skills/image/scripts/gen.sh`. Approx values — refresh quarterly via the routine described in § Refresh discipline._

**Snapshot date:** 2026-05-24

## Tiers

| Tier | Model endpoint | Default content-type | Approx cost (USD/img) | Strengths |
|---|---|---|---|---|
| `draft` | `fal-ai/flux/schnell` | `image/jpeg` → `.jpg` | ~$0.003 | Sub-second inference, open-weights (Black Forest Labs). Best for high-volume throwaway mockups. |
| `brand-text` | `fal-ai/gpt-image-2` | `image/png` → `.png` | ~$0.04 (low) / ~$0.20 (high) | Crisp typography rendering. Best for logos, banners, anything with text. Quality tier configurable via fal.ai params; v1 of the skill uses the default-quality midpoint. |
| `brand-photo` | `fal-ai/imagen4/ultra` | `image/png` → `.png` | ~$0.06 | Photo-real fidelity. Best for hero images, illustrations, marketing visuals. |

Content-type per tier is empirically verified for FLUX schnell (2026-05-24 dogfood — returns JPEG). The brand tiers' PNG defaults are documented assumption; verify on first invocation by checking the response's `content_type` field.

## Aspect ratios

The `--aspect` flag maps to fal.ai's `image_size` enum. Three values supported in v1:

| Aspect | `image_size` enum | Dimensions | Best for |
|---|---|---|---|
| `square` (default) | `square_hd` | 1024×1024 | Avatars, square mockups, icon-like assets |
| `landscape` | `landscape_16_9` | 1024×576 | Banners, hero images, blog post covers |
| `portrait` | `portrait_16_9` | 576×1024 | Mobile screens, vertical posters, story-format |

The default of `square` matches the v1 hardcoded behavior; existing callers without `--aspect` continue to get 1024×1024.

## Why these models

- **draft → FLUX schnell**: cheapest production-grade text-to-image in fal.ai's catalog as of 2026-05-24 (~10× cheaper than OAI/Imagen tiers). Open-weights licence — no usage-rights friction for prototype/mockup work.
- **brand-text → gpt-image-2**: OpenAI's text-rendering remains state-of-art for typography (verified empirically across the 2026 community benchmarks cited in `docs/specs/085-image-gen-opt-in/plan.md`).
- **brand-photo → imagen4/ultra**: Google's flagship photo-real model. Imagen 4 Ultra wins on consistent realism; FLUX 2 pro wins on artistic flexibility — the skill defaults to Imagen 4 Ultra for "brand" semantics where realism matters more than stylization.

## Model ID resolution

The skill resolves the tier → endpoint mapping at call time using the values above. If fal.ai renames an endpoint (e.g. `fal-ai/imagen4/ultra` → `fal-ai/imagen-4/ultra`), the MCP's `search_models` tool returns the current canonical ID and the table here gets bumped on next refresh.

## Refresh discipline

Pricing on fal.ai changes occasionally — model providers adjust, fal.ai's margins shift, new tiers appear.

**Refresh trigger:** quarterly (90 days), via a routine in `.claude/routines/`. Procedure:

1. Open [fal.ai/models](https://fal.ai/models) for each endpoint in the table.
2. Read the current per-image price.
3. If any tier has moved >20% from the snapshot above, update the row and bump `Snapshot date` at the top.
4. If a model ID has shifted, update the endpoint reference (rare).
5. Commit with message body referencing the refresh date.

**Drift posture:** if the `Snapshot date` is >180 days old, treat displayed costs as a **lower bound**. The `gen.sh` script can still derive a current price by calling the MCP's pricing tool at runtime, but the static table is the source of truth for pre-call cost printing.

## Cross-references

- `.claude/rules/image-gen.md` § *Tier table* — user-facing tier semantics
- `.claude/skills/image/SKILL.md` — invocation surface
- `.claude/skills/image/scripts/gen.sh` — runtime consumer
