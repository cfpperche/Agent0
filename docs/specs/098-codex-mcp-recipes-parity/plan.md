# 098 — codex-mcp-recipes-parity — plan

_Drafted from `spec.md` on 2026-05-27. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Implement the Codex MCP port as a **provider-neutral recipe/documentation upgrade plus one safe propagated template**, not as runtime automation. The shape is intentionally narrow: Agent0 teaches Codex users how to opt in to the existing six MCP recipes with native Codex config, syncs only an inert example file to consumers, and promotes the runtime capability row only after the template has been validated under a real Codex CLI.

The work lands in eight reviewable layers:

1. **Create the Codex MCP template.** Add `.codex/config.toml.example` as an MCP-only template. Its header must say it is not a full Codex project config and must not set model/provider/approval/sandbox defaults. The file uses one `[mcp_servers.<id>]` block per existing recipe: Playwright, Chrome DevTools, DBHub, Laravel Boost, Next.js DevTools, and fal.ai. Default posture is `enabled = false` for every block, pending the disabled-block side-effect dogfood below. Secret-bearing recipes use environment indirection only: DBHub uses the verified Codex `env_vars = ["DATABASE_URL"]` pattern, and fal.ai uses the verified streamable HTTP `bearer_token_env_var = "FAL_KEY"` pattern. No literal credential, URL with embedded credential, or static `Authorization` header lands in the repo.

2. **Validate the Codex config shape before treating it as the contract.** Use the installed Codex CLI and the official config/MCP docs to validate the field names already identified during planning: `env_vars` for local environment forwarding, nested `[mcp_servers.<id>.env]` for static non-secret environment values where needed, `url` for streamable HTTP servers, `bearer_token_env_var` for bearer-token HTTP auth, and `enabled = false` for disabled servers. Then run a local disabled-template probe in a temp trusted project and record the result in `notes.md`: the template must parse and must not spawn server commands, resolve packages, do DNS/network work, fail startup, or emit per-server startup noise. If this probe fails, switch the template to commented TOML recipe blocks before implementation continues.

3. **Document both activation paths, with honest scope.** Update `.claude/rules/mcp-recipes.md` so each recipe has three activation surfaces: Claude `.mcp.json`, Codex TOML, and `codex mcp add` where the CLI supports it. Planning research found `codex mcp add` exposes `--env`, `--url`, and `--bearer-token-env-var`, but no project-scope flag in local help, so docs must not imply it writes project-scoped config unless implementation proves that. Treat `codex mcp add` as operator convenience and `.codex/config.toml.example` as the consumer-propagated project artifact. Add the trusted-project explanation near the Codex section: project-scoped `.codex/config.toml` is honored only once the Codex project is trusted.

4. **Wire the template into safe consumer sync.** Add `.codex/config.toml.example` to `COPY_CHECK_FILES` in `.claude/tools/sync-harness.sh` as the only `.codex/*` path introduced by this spec. Do not add `.codex/.gitkeep`: the tracked example file materializes the directory, and omitting a sentinel keeps the manifest precedent as narrow as the spec requires. Update `.claude/rules/harness-sync.md` to explain that the template is synced while real `.codex/config.toml` remains local, and add the duplicate-ID gotcha for user-global plus project-scoped Codex configs defining the same MCP server name.

5. **Protect real operator config.** Update `.gitignore` to ignore `.codex/config.toml` while allowing `.codex/config.toml.example` to be tracked. Add a harness-sync regression mirroring the existing `.mcp.json.example` / `.mcp.json` safety contract: sync copies or updates the example file but byte-preserves an existing real `.codex/config.toml`. The test should also cover a pre-existing tracked/local config scenario enough to prove sync does not overwrite it; the docs carry the separate warning that `.gitignore` does not untrack or scrub already committed secrets.

6. **Add focused template checks.** Create a small `.claude/tests/codex-mcp-recipes/` test suite that validates the template without needing real credentials: six expected MCP IDs are present; every recipe is disabled or inert by default; no literal secret placeholders look like real credentials; DBHub and fal.ai use environment-variable indirection; the file parses as TOML under the chosen disabled-block strategy. Keep these tests structural and fast. They complement, but do not replace, the real Codex dogfood.

7. **Update entrypoints and runtime registry only after validation.** Keep the shared `AGENTS.md` / `CLAUDE.md` managed MCP section concise: point users to `.claude/rules/mcp-recipes.md` and `.codex/config.toml.example`, and mention that Codex does not receive Claude's `SessionStart` hint. After the template, docs, sync, and at least one real Codex dogfood pass, update `.claude/rules/runtime-capabilities.md`: `MCP recipes` becomes Codex `native-opt-in`, Claude remains `native-opt-in`, and owner-file notes name both `.mcp.json.example` and `.codex/config.toml.example`.

8. **Dogfood one stdio recipe and one HTTP auth shape.** Use Playwright as the stdio dogfood because it is the recommended low-risk recipe in the spec. In a temp consumer-style project, copy the example to `.codex/config.toml`, enable only Playwright, and prove Codex sees/starts that MCP path without relying on Claude. Separately validate the fal.ai HTTP block shape with `enabled = false` and `bearer_token_env_var = "FAL_KEY"` so the full six-recipe claim is not based only on stdio behavior. Record the exact commands and observed result in `notes.md`.

## Files to touch

**Create:**

- `.codex/config.toml.example` — MCP-only Codex project template with six disabled/inert recipe blocks and no credentials.
- `.claude/tests/codex-mcp-recipes/run-all.sh` — focused template validation runner.
- `.claude/tests/codex-mcp-recipes/01-template-safe-defaults.sh` — verifies recipe IDs, disabled/inert defaults, and absence of literal credentials.
- `.claude/tests/codex-mcp-recipes/02-template-codex-config-shape.sh` — verifies parseable TOML and expected Codex field names for stdio, env forwarding, HTTP URL, and bearer-token env auth.
- `.claude/tests/harness-sync/35-codex-config-example-untouched.sh` — regression proving sync propagates `.codex/config.toml.example` while preserving real `.codex/config.toml`.

**Modify:**

- `.claude/rules/mcp-recipes.md` — add Codex-native activation sections per recipe: direct TOML, `codex mcp add` where supported, project-trust note, duplicate-ID warning, and recipe-specific security notes.
- `.mcp.json.example` — likely no behavior change; inspect only to keep recipe IDs/security comments aligned with the Codex template. Modify only if an existing recipe comment is stale.
- `.claude/tools/sync-harness.sh` — add `.codex/config.toml.example` to `COPY_CHECK_FILES`; do not add any other `.codex/*` path.
- `.claude/rules/harness-sync.md` — document synced example vs local real config, `.gitignore` limitation for already tracked secrets, and duplicate MCP server ID gotcha.
- `.gitignore` — ignore `.codex/config.toml` while leaving `.codex/config.toml.example` trackable.
- `AGENTS.md` — managed MCP section gains the Codex static pointer to `.claude/rules/mcp-recipes.md` and `.codex/config.toml.example`.
- `CLAUDE.md` — same managed MCP section edit as `AGENTS.md` so the managed blocks stay byte-identical.
- `.claude/rules/runtime-capabilities.md` — after validation, promote only the `MCP recipes` row for Codex CLI to `native-opt-in` and name both activation surfaces.
- `docs/specs/098-codex-mcp-recipes-parity/notes.md` — record disabled-template side-effect probe, `codex mcp add` write-scope observation, Playwright dogfood result, and fal.ai HTTP config-shape validation.

**Delete:**

- Nothing. Existing Claude MCP artifacts stay in place; real Codex config files are not created, modified, or deleted.

## Alternatives considered

### Ship only prose docs, no `.codex/config.toml.example`

Rejected because it would make Codex parity depend on every consumer translating recipe prose by hand. The whole point of this spec is a consumer-propagated, reviewable context surface. A checked-in inert template gives Codex users the same "copy/edit to activate" affordance Claude users already have with `.mcp.json.example`.

### Ship an active `.codex/config.toml`

Rejected because it would cross the operator-local boundary. Codex project config may contain model/provider choices, sandbox/approval posture, MCP credentials, and user-specific server IDs. Agent0 owns a template and guidance, not a consumer's real runtime config.

### Add `.codex/.gitkeep` to sync

Rejected for v1. The tracked `.codex/config.toml.example` already creates the directory, and the acceptance criteria explicitly constrain this spec to one `.codex/*` path. A sentinel would create a second namespace precedent without adding user value.

### Prefer `codex mcp add` over direct TOML

Rejected as the primary contract because local `codex mcp add --help` does not show a project-scope flag. The command remains useful operator UX, but the propagated artifact is direct TOML in `.codex/config.toml.example`. If implementation proves a project-scoped command path, the docs can say so per recipe.

### Use commented recipe blocks instead of parseable `enabled = false` blocks from the start

Rejected unless the disabled-block probe fails. Parseable TOML lets tests and Codex itself validate field names continuously. Commented examples are safer only if Codex treats disabled MCP servers with side effects; the spec already defines that fallback.

### Place the Codex template under `.claude/`

Rejected because the file would become a Claude-owned reference artifact instead of a Codex-native activation surface. Codex users should find the template where Codex project config lives: `.codex/config.toml.example`.

## Risks and unknowns

- **Disabled-block side effects.** `enabled = false` is documented, but the implementation must prove disabled MCP servers do not start, resolve packages, call DNS/network, or emit noisy startup errors. Mitigation: validate before hardening the template; fall back to commented TOML blocks if needed.
- **`codex mcp add` write scope.** Local help exposes useful flags but no project-scope selector. Mitigation: document observed scope honestly and make direct TOML the canonical project template.
- **Duplicate MCP server IDs.** A user may define `playwright` globally and in project config. Mitigation: document the gotcha in `mcp-recipes.md` and `harness-sync.md`, and avoid auto-writing real config.
- **Pre-existing tracked `.codex/config.toml`.** `.gitignore` will not untrack or remove secrets from an already committed file. Mitigation: docs call this out directly; sync tests prove Agent0 does not overwrite the file.
- **Codex trusted-project posture.** Project-scoped `.codex/config.toml` depends on the project trust model, which differs from Claude's `.mcp.json` flow. Mitigation: put the trust note in the Codex activation section, not buried in the spec only.
- **HTTP auth field drift.** `bearer_token_env_var` and `env_vars` are current documented fields, but Codex is evolving. Mitigation: cite the official docs in the recipe docs and keep the structural tests narrow enough to update when Codex changes.
- **Runtime registry overclaim.** Promoting Codex to `native-opt-in` before dogfood would turn aspirational parity into a false capability claim. Mitigation: update the registry only after template, docs, sync, and real Codex validation pass.

## Research / citations

- Local Codex CLI, `codex mcp add --help` on 2026-05-27 — confirmed command shape: `codex mcp add [OPTIONS] <NAME> (--url <URL> | -- <COMMAND>...)`, plus `--env`, `--url`, and `--bearer-token-env-var`; no project-scope flag shown in help.
- Local Codex CLI, `codex mcp get context7` and redacted `~/.codex/config.toml` inspection on 2026-05-27 — confirmed installed config uses `[mcp_servers.<id>]`, stdio `command`/`args`, and nested `[mcp_servers.<id>.env]` for environment values.
- OpenAI Codex MCP docs — confirms Codex supports MCP in CLI/IDE, stdio and streamable HTTP servers, `codex mcp add --env`, bearer-token auth, and project-scoped `.codex/config.toml` for trusted projects: https://developers.openai.com/codex/mcp
- OpenAI Codex config reference — confirms `mcp_servers.<id>` fields including `command`, `args`, `env`, `env_vars`, `url`, `bearer_token_env_var`, and shared `enabled`: https://developers.openai.com/codex/config-reference
- `.claude/rules/mcp-recipes.md` — current provider-specific recipe docs to be expanded into Claude/Codex activation paths.
- `.mcp.json.example` — existing six-recipe Claude template; source of recipe IDs and current security posture.
- `.claude/tools/sync-harness.sh` — `COPY_CHECK_FILES` manifest where `.codex/config.toml.example` must be added as the only new `.codex/*` path.
- `.claude/rules/harness-sync.md` — propagation contract and docs surface for synced examples vs consumer-local config.
- `.claude/tests/harness-sync/11-mcp-json-untouched.sh` — test shape to mirror for `.codex/config.toml.example` / `.codex/config.toml` safety.
- `.gitignore` — currently ignores `.mcp.json`; needs the analogous real Codex config ignore for `.codex/config.toml`.
- `AGENTS.md` and `CLAUDE.md` — shared managed MCP section must point Codex users at static docs/template because Codex does not receive Claude's MCP SessionStart hint.
- `.claude/rules/runtime-capabilities.md` — current matrix row to promote only after real validation, preserving the spec's anti-overclaim constraint.
