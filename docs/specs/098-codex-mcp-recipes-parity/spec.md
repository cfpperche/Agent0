# 098 — codex-mcp-recipes-parity

_Created 2026-05-27._

**Status:** shipped

## Intent

Port Agent0's MCP recipe capacity from Claude-only activation guidance to a provider-neutral, consumer-propagated MCP recipe surface that works for both Claude Code and Codex CLI. Today `.claude/rules/mcp-recipes.md` and `.mcp.json.example` give Claude users an opt-in recipe set, while Codex users only get convention-level prose even though the installed Codex CLI supports native MCP configuration through `codex mcp` and `config.toml`. This spec adds Codex-native recipe documentation and an MCP-only project-scoped Codex config template, updates sync-harness so consumer projects receive that template, and changes the runtime capability registry from Codex `convention` to `native-opt-in` only after real Codex behavior is verified. This aligns with the Agent0 thesis: improve context engineering and governance surfaces, not create a catalog of agents or skills.

## Acceptance criteria

- [x] **Scenario: Codex user can activate the same MCP recipe set natively**
  - **Given** a consumer project has received the Agent0 harness update and trusts the project in Codex
  - **When** the user reads the MCP recipe docs and the Codex template
  - **Then** they can enable Playwright, Chrome DevTools, DBHub, Laravel Boost, Next.js DevTools, and fal.ai through Codex-native MCP configuration without translating from Claude `.mcp.json` by hand, using both per-recipe TOML snippets and `codex mcp add` commands where Codex supports them

- [x] **Scenario: consumer sync propagates the Codex MCP template safely**
  - **Given** a consumer project may already have a local or tracked `.codex/config.toml` with user/provider/MCP settings
  - **When** `bash .claude/tools/sync-harness.sh --apply --agent0-path=/home/goat/Agent0 <consumer-path>` runs after this spec lands
  - **Then** the Agent0-authored Codex MCP template is copied or updated, any real consumer `.codex/config.toml` remains untouched, and docs warn that `.gitignore` does not retroactively untrack a pre-existing committed config file or remove secrets from it

- [x] **Scenario: MCP recipes remain opt-in and secret-safe**
  - **Given** the shipped template is checked into Agent0 and consumer projects
  - **When** an agent or human inspects it
  - **Then** every MCP server is disabled or inert by default, no literal credential is present, DBHub uses a verified Codex environment-variable forwarding pattern rather than a real `DATABASE_URL`, and fal.ai uses a verified Codex bearer-token environment-variable mechanism such as `bearer_token_env_var = "FAL_KEY"` rather than a static `Authorization` header

- [x] **Scenario: disabled Codex template blocks have no side effects**
  - **Given** `.codex/config.toml.example` uses parseable TOML blocks with `enabled = false`
  - **When** the template is validated under Codex before plan lock
  - **Then** it parses successfully and disabled servers do not spawn commands, fail startup, resolve packages, perform DNS/network calls, or emit per-server startup noise; if any side effect appears, the implementation switches to commented TOML blocks instead

- [x] **Scenario: docs make Claude and Codex activation paths symmetrical but honest**
  - **Given** a maintainer reads `.claude/rules/mcp-recipes.md`
  - **When** they inspect any individual MCP recipe
  - **Then** that recipe documents Claude activation (`.mcp.json`), Codex TOML activation, Codex CLI activation where supported, whether `codex mcp add` writes user-global or project-scoped config, runtime requirements, and recipe-specific security notes

- [x] **Scenario: runtime capability registry reflects proven support**
  - **Given** Codex MCP parity has documentation, template, sync validation, and at least one real Codex CLI dogfood of an MCP recipe
  - **When** `.claude/rules/runtime-capabilities.md` is updated
  - **Then** the `MCP recipes` row marks Codex CLI as `native-opt-in`, keeps Claude Code as `native-opt-in`, and names both activation surfaces in the owner files / notes; Playwright is the recommended stdio dogfood, with a lightweight fal.ai HTTP/bearer-token config-shape validation before claiming the full six-recipe set

- [x] A Codex MCP template exists at a path that is safe to version and safe to sync to consumer projects; the current recommended path is `.codex/config.toml.example`.

- [x] `.codex/config.toml.example` is explicitly labeled in its header as an MCP-only fragment/template. It must not imply Agent0 owns the whole Codex project config surface.

- [x] `.gitignore` ignores real operator-local Codex project config (`.codex/config.toml`) while allowing the example template to be tracked.

- [x] `sync-harness.sh` includes `.codex/config.toml.example` in its propagation manifest as the only `.codex/*` path introduced by this spec; any further `.codex/*` propagation requires a follow-up spec.

- [x] `harness-sync.md` documents that the Codex MCP template is shipped while real `.codex/config.toml` remains consumer-local, and documents the duplicate-ID gotcha when user-global and project-scoped Codex config define the same MCP server ID.

- [x] A harness-sync regression test verifies `.codex/config.toml.example` is copied while `.codex/config.toml` is byte-preserved, mirroring the existing `.mcp.json.example` / `.mcp.json` safety contract.

- [x] Focused template checks verify the six MCP IDs are present, all recipe blocks are disabled or inert by default, and secret-bearing recipes use environment-variable indirection.

- [x] `AGENTS.md` and `CLAUDE.md` continue to share the managed MCP section and point to the provider-neutral recipe docs without duplicating the full matrix; the managed block must point Codex users at `.claude/rules/mcp-recipes.md` and `.codex/config.toml.example` because Codex does not receive the Claude `SessionStart` MCP hint.

## Non-goals

- **Auto-installing or auto-enabling MCP servers.** Activation remains an explicit user/operator step in both Claude and Codex.
- **Shipping non-MCP Codex config.** Agent0 does not ship or recommend Codex `model`, provider, `approval_policy`, sandbox, permission, or tool-approval defaults in this spec; `.codex/config.toml.example` is MCP-only.
- **Writing to `~/.codex/config.toml` or a consumer's real `.codex/config.toml`.** Agent0 ships a template and docs; user-local config stays user-local.
- **Replacing `.mcp.json.example`.** Claude's existing activation path remains supported.
- **Porting `/image` as a Codex skill.** This spec only ports the MCP discovery/config surface; image generation execution remains governed by the existing image-gen architecture.
- **Codex hook/governance adapter work.** Lifecycle hooks, payload adaptation, and automatic gates belong to a separate follow-up spec.
- **Promoting unrelated Codex capability rows.** This spec promotes only the `MCP recipes` row in `.claude/rules/runtime-capabilities.md`; lifecycle hooks, delegation/subagents, runtime introspect, memory, SDD, debate, and image-generation execution remain at their current support levels unless another spec changes them.
- **Adding new MCP recipes.** V1 ports the existing curated set; new servers require separate product/safety justification.
- **Creating agents, subagents, or skills.** This work is context/tooling parity, not an agent catalog.

## Open questions

- [x] ~~Should the Codex template live at `.codex/config.toml.example` or at a neutral root path such as `.codex-mcp.toml.example`?~~ → **Resolved:** use `.codex/config.toml.example`, defended by the MCP-only scope non-goal and by the lack of a verified partial-config include mechanism.
- [x] ~~Should the template contain disabled `[mcp_servers.<id>]` blocks, or commented TOML blocks?~~ → **Resolved:** use parseable `enabled = false` TOML blocks only if Codex dogfood proves disabled servers have no side effects; otherwise switch to commented TOML blocks.
- [x] ~~Should docs prefer `codex mcp add ...` commands or direct TOML snippets?~~ → **Resolved:** document both. The template is the consumer-propagated artifact; `codex mcp add` is first-class operator UX where supported, with its write scope pinned per recipe.
- [x] ~~Should the sync manifest treat `.codex/config.toml.example` as a plain baseline-tracked file immediately, or should it ship under `.claude/` first?~~ → **Resolved:** expand the manifest explicitly to include `.codex/config.toml.example` only. The single-path manifest AC is the precedent guard.
- [x] ~~Should `mcp-recipes-hint.sh` remain Claude-only SessionStart behavior, or should this spec add a Codex-readable static hint in `AGENTS.md` only?~~ → **Resolved:** leave runtime hints unchanged and add a static managed-block pointer for Codex users in `AGENTS.md` / `CLAUDE.md`.
- [x] ~~Codex trusted-project posture: where should docs explain that project-scoped `.codex/config.toml` requires the project to be trusted in Codex, unlike Claude's `.mcp.json` activation path?~~ → **Resolved:** document it in `.claude/rules/mcp-recipes.md` overview and Codex activation workflow, and keep `.codex/config.toml.example` header focused on copy/enable mechanics.
- [x] ~~Inline template security prose: should `.codex/config.toml.example` carry per-recipe security comments mirroring `.mcp.json.example`, or keep the template terse and defer full security notes to `.claude/rules/mcp-recipes.md`?~~ → **Resolved:** keep the template terse and secret-safe; full per-recipe security notes live in `.claude/rules/mcp-recipes.md`.
- [x] ~~`.codex/.gitkeep`: should sync-harness ship a sentinel, or should the `.codex/` directory materialize only as the parent of `.codex/config.toml.example`?~~ → **Resolved:** no `.codex/.gitkeep`; `.codex/config.toml.example` is the only `.codex/*` path shipped by this spec.

## Context / references

- `.claude/rules/mcp-recipes.md` — current Claude-oriented MCP recipe documentation.
- `.mcp.json.example` — current Claude activation template.
- `.claude/hooks/mcp-recipes-hint.sh` — Claude SessionStart recipe suggestion hook.
- `.claude/rules/runtime-capabilities.md` — capability matrix promoted by this spec from Codex `convention` to Codex `native-opt-in` for MCP recipes.
- `.claude/tools/sync-harness.sh` and `.claude/rules/harness-sync.md` — propagation mechanism that must carry the new template to consumer projects without touching real local config.
- `docs/specs/012-mcp-recipes/` — original MCP recipes capacity.
- `docs/specs/014-mcp-recipes-extras/` — later MCP recipe expansions.
- `docs/specs/085-image-gen-opt-in/` and `docs/specs/088-image-skill-curl-exec/` — fal.ai MCP context and the hybrid MCP-discovery / REST-execution decision for image generation.
- `docs/specs/093-runtime-capability-registry/` — established MCP parity as a likely follow-up row and introduced the `native-opt-in` vocabulary.
- OpenAI Codex MCP docs — Codex supports MCP in CLI/IDE, stdio and streamable HTTP servers, bearer-token auth, OAuth, server instructions, and project-scoped `.codex/config.toml` in trusted projects: https://developers.openai.com/codex/mcp
- OpenAI Codex config reference — `mcp_servers.<id>` fields, HTTP auth, tool approval modes, and MCP allowlist / identity controls: https://developers.openai.com/codex/config-reference
