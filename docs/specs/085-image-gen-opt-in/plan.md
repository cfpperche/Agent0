# 085 — image-gen-opt-in — plan

_Drafted from `spec.md` on 2026-05-24. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Ship the capacity as **one new MCP recipe + one new skill + one new rule**, following the existing `mcp-recipes.md` pattern verbatim (Playwright / Chrome DevTools / DBHub / Next-devtools precedent). The MCP is fal.ai's **official hosted MCP** at `https://mcp.fal.ai/mcp` (HTTP transport, maintained by fal.ai team, free, 1000+ models across image / video / audio / 3D / LLM categories). The `/image` skill is intentionally **thin**: it parses `--tier`, resolves tier → fal.ai model endpoint, prints estimated cost from a static table baked into the skill, then delegates to the MCP. Tier-to-path routing is what makes the storage policy mechanical — `draft` writes to gitignored `assets/generated/mockups/`, `brand-text` and `brand-photo` write to git-tracked `assets/brand/`. The rule documents activation, override, the official-vs-community trust comparison, and documented fallback packages for forks that prefer local/stdio MCPs. No edits to `/product`, `/prototype`, or any other shipping skill — standalone v1 per the user's choice.

Build order: rule first (doc-driven), then `.mcp.json.example` block + recipe section + hint-table row, then skill SKILL.md + scripts, then CLAUDE.md pointer + sync-harness manifest registration, then validation against `/skill validate image` and the spec scenarios.

## Files to touch

**Create:**

- `.claude/rules/image-gen.md` — capacity rule. Activation (cp `.mcp.json.example` → `.mcp.json`, set `FAL_KEY`, restart session), tier table (`draft` / `brand-text` / `brand-photo` → model + approx cost + output path), error-on-omitted-tier behaviour, manifest shape (`{ts, session_id, model, cost_usd, prompt, output_path, dimensions, tier}`), override marker grammar (`# OVERRIDE: image-gen-exempt: <reason>`), trust posture re community MCP, alternative MCPs documented for swap (lansespirit, monsoft, mseep)
- `.claude/skills/image/SKILL.md` — slash-command definition, agentskills.io-compliant frontmatter, subcommand grammar (`/image --tier=<draft|brand-text|brand-photo> [--name=<slug>] "<prompt>"`), pre-call cost estimate format, error-on-omitted-tier with 3-option listing, references to rule
- `.claude/skills/image/scripts/gen.sh` (or `.py` if simpler) — runtime: parse args, resolve tier→model, compute estimated cost from static price table, print `estimated: $X.XXX for <model> at <resolution>`, invoke MCP tool, write file to tier-mapped path, append `.manifest.jsonl` line. Errors clean when tier missing or `FAL_KEY` unset.
- `.claude/skills/image/references/tier-pricing.md` — static price table (date-stamped, "approx" prefix), refresh procedure pointer
- `assets/.gitkeep` + `assets/brand/.gitkeep` + `assets/generated/.gitkeep` + `assets/generated/mockups/.gitkeep` — bootstrap dir tree

**Modify:**

- `.mcp.json.example` — add commented-out `fal-ai` block using HTTP transport: `{ "type": "http", "url": "https://mcp.fal.ai/mcp", "headers": { "Authorization": "Bearer ${FAL_KEY}" } }`. Distinct from the other 4 existing recipes which use stdio `command`/`args` shape — first HTTP-transport entry in the example file, so the comment header may need a one-line note about transport variability.
- `.claude/rules/mcp-recipes.md` — add `### fal.ai MCP (image / video / audio)` recipe section (alongside the other 4), add row to § *Stack-detector signal table* for "image-gen hint", document the HTTP-transport shape (precedent-setting: first such recipe), note documented community fallbacks (piebro et al) for forks that prefer stdio/local
- `.claude/hooks/mcp-recipes-hint.sh` — add signal detection for image-gen-applicable forks. Candidate signals: presence of `assets/brand/` or `assets/generated/`, README contains `![hero]` / `<img` for hero usage, `/product` skill is installed. Recipe suggestion: `fal-ai`. Conservative — only emit when ≥1 signal fires.
- `.gitignore` — add `assets/generated/mockups/*` with `!.gitkeep` exclusion to keep the sentinel tracked; leave `assets/brand/*` and other `assets/` paths tracked
- `CLAUDE.md` — add `## Image generation` section (one paragraph), pointer to `.claude/rules/image-gen.md`. Placed adjacent to `## MCP recipes` for topical proximity.
- `.claude/harness-sync-baseline.json` — register the new files so `sync-harness.sh` reconciles them. Verify the existing manifest globs cover `.claude/skills/*/` and `.claude/rules/*.md` per `.claude/rules/harness-sync.md`; explicit baseline-hash entries needed only for the new files.

**Delete:** none.

## Alternatives considered

### Multi-MCP — ship two recipes (FLUX-cheap + OAI/Imagen-premium)

Rejected. fal.ai aggregates all three providers (FLUX, OpenAI gpt-image, Google Imagen, Nano Banana) under one API key. One MCP entry + one `FAL_KEY` covers the entire premium+draft spectrum. Two separate MCPs would double the surface (two packages to trust, two API keys, two recipe sections to maintain) for zero coverage gain. The fallback if fal.ai becomes unreliable — swap `.mcp.json` to `lansespirit/image-gen-mcp` (OAI+Imagen direct) — is documented in the rule.

### Build our own MCP server

Rejected. fal.ai ships an **official hosted MCP** at `https://mcp.fal.ai/mcp` (verified 2026-05-24 via fal.ai docs), maintained by the fal.ai team itself. Plus ≥4 community options on npm (`fal-ai-mcp-server`, `@monsoft/mcp-fal-ai`, `mcp-fal-ai-image`, `@mseep/mcp-fal-ai-image`) and 3+ GitHub-only TS/Python implementations. No empirical pain that justifies a sixth implementation.

### Community-maintained MCP package (e.g. `piebro/fal-ai-mcp-server`)

Rejected as default; documented as fallback. Earlier draft of this plan recommended `piebro/fal-ai-mcp-server` under the wrong premise that no official MCP existed. Once the official hosted MCP was confirmed, trust posture flipped: fal.ai team maintains the official endpoint with guaranteed API tracking; the piebro package is one individual's project (MIT-licensed, well-featured — cost-estimation native — but single-maintainer risk). The community packages stay in the rule as documented alternatives for two real cases: (a) forks that want a fully-local/stdio MCP with no network call to fal.ai at MCP startup; (b) a fallback if fal.ai's hosted endpoint suffers an outage or policy change.

### Skill calling fal.ai REST API directly via `curl`, no MCP

Rejected. (a) `fal-ai-mcp-server` already bundles retry / error handling / cost estimation / schema inspection — reinventing is dead weight; (b) secrets handling at the shell layer (`FAL_KEY` exported through curl) creates more audit surface than MCP env-var indirection; (c) every other external-service integration in Agent0 (Playwright, Chrome DevTools, DBHub, Next DevTools, Laravel Boost) uses the MCP pattern — single architectural shape pays off in cognitive load.

### Integrate with `/product` and `/prototype` directly

Rejected per the user's explicit choice in conversation (2026-05-24): standalone v1, no cross-skill integration. Cross-skill integration is a separate question with its own design surface (when does `/product` decide to call `/image`? does `/prototype` consume images or just placeholders?). Defer until either skill explicitly asks for image-gen — no speculative coupling.

### Single tier-less skill — let user pass model name directly

Rejected. `/image --model=fal-ai/flux/schnell "<prompt>"` is what the MCP already exposes; the skill's value-add is the *tier abstraction* (draft / brand-text / brand-photo) that maps to durability semantics and path conventions. Without the tier layer, the storage-policy split (gitignored vs tracked) has no mechanical signal and collapses into manual user discipline.

## Risks and unknowns

- **Hosted MCP is network-dependent at startup.** Unlike the stdio recipes (Playwright, Chrome DevTools, DBHub, Next-devtools) that spawn locally, `https://mcp.fal.ai/mcp` requires a session-start HTTPS handshake. If fal.ai's endpoint is down or the fork is offline / behind a strict egress firewall, the MCP simply doesn't register and `/image` errors at call time. Mitigation: rule's § *Activation* documents this and points at the community-package fallback (`piebro/fal-ai-mcp-server` via npx) as the offline-capable alternative. Sub-millisecond cost in the happy path.
- **HTTP transport is the first such recipe in `.mcp.json.example`.** All 4 existing recipes use stdio (`command`/`args`). This shape mismatch is documentation-only — Claude Code supports both transports per spec — but the recipe section needs to explicitly call out the HTTP shape so a fork reading the file doesn't pattern-match the wrong block. The `.mcp.json.example` header comment may also need a one-line note.
- **fal.ai pricing drifts.** The skill's estimated-cost numbers are baked into `.claude/skills/image/references/tier-pricing.md` (date-stamped) and prefixed `approx`. Refresh discipline: a quarterly entry in `.claude/routines/` (per `.claude/rules/routines.md`) re-runs the lookup against fal.ai's pricing page. If pricing has moved >20%, update the table and bump the date stamp. Lower risk with the official MCP than with community packages because pricing tracks the platform itself, not a wrapper's possibly-stale assumptions.
- **Cost runaway from delegated sub-agents.** A sub-agent calling `/image` in a loop is not caught by the post-edit validator (image-gen creates files but the validator gates on prod-vs-test classification, not on cost). v1 ships with pre-call estimate as the only signal. If empirical observation shows drift, add a per-session call counter to the skill (rule-of-three).
- **Model endpoints may rename.** Confirm at implementation time that `fal-ai/flux/schnell`, `fal-ai/gpt-image-2`, and `fal-ai/imagen4/ultra` are all addressable via the official MCP's `search_models` / `recommend_model` tools. Lower risk than with community packages (official MCP tracks the catalog directly) but model IDs do shift across fal.ai's catalog updates. If any v1-targeted ID is missing, document the gap and route around it (e.g. use a current FLUX pro variant for brand-photo).
- **Sync-harness glob coverage.** `.claude/skills/image/` directory needs to be picked up by `harness-sync.sh`'s manifest. Verify against `.claude/rules/harness-sync.md` § propagation: existing glob `.claude/skills/*/` should cover it, but the new `.claude/rules/image-gen.md` is a file-level addition requiring an explicit baseline entry.
- **Path-policy may surprise forks.** A fork that doesn't want any durable image storage will need to add `.gitignore` entries locally to suppress `assets/brand/*`. Documented in the rule's § *Storage policy*. `CLAUDE_SKIP_IMAGE_GEN=1` suppresses the hint at session start; there's no fork-level enforcement to block the skill itself.
- **Q5 doubly moot.** (a) Hosted MCP has no `npx`/package install path at all — the entire supply-chain concern dissolves. (b) Even with the community-fallback path, MCPs spawn from `.mcp.json` outside the `PreToolUse(Bash)` hook surface, so `npx -y` would never reach the gate. No whitelist needed, no override needed in either configuration.
- **fal.ai key shape unknown to gitleaks default rules.** Unlike OpenAI's `sk-*` prefix or AWS's `AKIA*`, fal.ai keys (`<uuid>:<secret>` shape) may not match gitleaks' built-in regexes. Verify during implementation — if not caught, propose adding a custom rule per `.claude/rules/secrets-scan.md`. Mitigated meanwhile by the `.mcp.json.example` using `${FAL_KEY}` indirection (no literal key ever sits in a tracked file).

## Research / citations

Sources consulted 2026-05-24 (web research conducted before drafting `spec.md`, expanded + corrected during this plan):

- [fal.ai official MCP setup docs — hosted HTTP MCP at `mcp.fal.ai/mcp`, 1000+ models](https://fal.ai/docs/documentation/setting-up/mcp) — primary source; corrected the initial mistaken premise that no official MCP existed
- [fal.ai blog — "Connect your AI to 1,000+ models with the fal MCP Server"](https://blog.fal.ai/connect-your-ai-to-1-000-models-with-the-fal-mcp-server/) — announcement / context
- [fal.ai Models page (multi-provider hosting confirmed)](https://fal.ai/models)
- [piebro/fal-ai-mcp-server (GitHub) — community alternative for offline/stdio use](https://github.com/piebro/fal-ai-mcp-server)
- [@monsoft/mcp-fal-ai (npm) — 8 tools, dual transport, community](https://www.npmjs.com/package/@monsoft/mcp-fal-ai)
- [mcp-fal-ai-image (npm) — image-only community variant](https://www.npmjs.com/package/mcp-fal-ai-image)
- [lansespirit/image-gen-mcp (GitHub) — alt path carrying OAI gpt-image-1 + Imagen 4 direct (multi-provider, non-fal.ai)](https://github.com/lansespirit/image-gen-mcp)
- [fal.ai vs Replicate 2026 comparison](https://www.teamday.ai/blog/fal-ai-vs-replicate-comparison)
- [OpenAI Image pricing 2026 — DALL-E 3 discontinued 2026-05-12](https://invertedstone.com/calculators/dall-e-pricing)
- [Google Imagen 4 pricing](https://developers.googleblog.com/imagen-4-now-available-in-the-gemini-api-and-google-ai-studio/)
- [AI Image API pricing comparison 2026](https://www.digitalapplied.com/blog/ai-image-generation-api-pricing-comparison-2026)

Internal references:

- `.claude/rules/mcp-recipes.md` — pattern this spec follows verbatim
- `.claude/rules/supply-chain.md` § *What fires, what advises* — confirms supply-chain hook scope is Bash-only; Q5 dissolution
- `.claude/rules/delegation.md` § *Why DONE_WHEN exists* — contract-not-promise frame for pre-call cost printing
- `.claude/skills/skill/` — `/skill validate image` will gate compliance
- Conversation 2026-05-24 — provider survey, multi-provider→single-aggregator pivot, standalone v1 choice, OQ resolutions
