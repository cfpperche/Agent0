# 098 — codex-mcp-recipes-parity — tasks

_Generated from `plan.md` on 2026-05-27. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Layer 0 — Codex behavior gates

- [x] 1. Re-confirm local Codex MCP field support before writing the template contract. Capture command/output summary in `docs/specs/098-codex-mcp-recipes-parity/notes.md`: `codex mcp add --help` exposes stdio command form, `--env`, `--url`, and `--bearer-token-env-var`; official Codex docs still document `mcp_servers.<id>`, `env_vars`, nested `.env`, `url`, `bearer_token_env_var`, and shared `enabled`. If field names changed, update `plan.md` and `spec.md` before continuing.

- [x] 2. Probe `enabled = false` side effects in a temp trusted-project-style directory before locking the template style. Use a minimal `.codex/config.toml` with one disabled stdio server whose command would be obvious if started. Run a local Codex command that loads project config without making a model call if possible. Record whether the disabled server parses without startup, package resolution, DNS/network, failure, or per-server noise. If it has side effects, update `plan.md` and switch `.codex/config.toml.example` to commented TOML recipe blocks.

- [x] 3. Determine `codex mcp add` write scope empirically with a temp `CODEX_HOME` and temp project. Add a harmless MCP entry, inspect which config file changed, then remove the temp state. Record the result in `notes.md`. Docs must say "user/global" or "project-scoped" according to this observation; do not infer project scope from CLI existence.

### Layer 1 — Codex MCP template

- [x] 4. Create `.codex/config.toml.example` with a top header stating: MCP-only template; not a full Codex config; Agent0 does not set model/provider/approval/sandbox/tool-permission defaults; copy to `.codex/config.toml` and enable recipes explicitly.

- [x] 5. Add six recipe blocks to `.codex/config.toml.example`: `playwright`, `chrome-devtools`, `dbhub`, `laravel-boost`, `nextjs-devtools`, and `fal-ai` (or exact IDs aligned with `.mcp.json.example`). Every block is disabled/inert by default under the strategy proven in task 2. No block contains literal credentials, embedded credential URLs, or static `Authorization` headers.

- [x] 6. In the template, use verified secret-safe Codex patterns: DBHub forwards `DATABASE_URL` through `env_vars = ["DATABASE_URL"]`; fal.ai uses streamable HTTP `url` plus `bearer_token_env_var = "FAL_KEY"`. Keep any non-secret static environment values in nested `[mcp_servers.<id>.env]` only when a recipe actually needs them.

### Layer 2 — Template tests

- [x] 7. Create `.claude/tests/codex-mcp-recipes/run-all.sh` following the existing test-runner style in adjacent `.claude/tests/*/run-all.sh` directories.

- [x] 8. Create `.claude/tests/codex-mcp-recipes/01-template-safe-defaults.sh`: assert `.codex/config.toml.example` exists; all six MCP IDs are present exactly once; every recipe block is disabled or inert by default; no obvious credential literals or `Authorization` header are present; DBHub and fal.ai use environment-variable indirection.

- [x] 9. Create `.claude/tests/codex-mcp-recipes/02-template-codex-config-shape.sh`: assert the template is valid TOML under the chosen strategy and contains the expected Codex field shapes for stdio, env forwarding, streamable HTTP URL, and bearer-token env auth. Prefer standard tooling already available in the repo/runtime; if a parser dependency is missing, use a small shell-compatible fallback and document the limitation in the test.

### Layer 3 — Safe sync and local config protection

- [x] 10. Update `.gitignore` to ignore `.codex/config.toml` while keeping `.codex/config.toml.example` trackable. Do not ignore the whole `.codex/` directory.

- [x] 11. Update `.claude/tools/sync-harness.sh` `COPY_CHECK_FILES` to include `.codex/config.toml.example` as the only `.codex/*` path introduced by this spec. Do not add `.codex/.gitkeep`.

- [x] 12. Add `.claude/tests/harness-sync/35-codex-config-example-untouched.sh`, mirroring the `.mcp.json.example` safety contract: a consumer receives/updates `.codex/config.toml.example`, while an existing `.codex/config.toml` remains byte-identical after sync. Include a fixture with a realistic user/provider/MCP setting in `.codex/config.toml` to prove sync does not touch real config.

- [x] 13. Update `.claude/rules/harness-sync.md` manifest docs: list `.codex/config.toml.example`; state that real `.codex/config.toml` is operator-local and never synced; warn `.gitignore` does not untrack or scrub a previously committed config; document duplicate MCP server ID risk between user-global and project-scoped Codex config.

### Layer 4 — Provider-neutral recipe docs

- [x] 14. Update `.claude/rules/mcp-recipes.md` overview to explain the two native activation surfaces: Claude uses `.mcp.json` / `.mcp.json.example`; Codex uses project `.codex/config.toml` derived from `.codex/config.toml.example` after the project is trusted in Codex.

- [x] 15. For each existing recipe in `.claude/rules/mcp-recipes.md`, add Codex activation details: TOML snippet or pointer to the corresponding template block; `codex mcp add` command where task 3 proves it is appropriate; runtime prerequisites; recipe-specific security notes; and whether the command writes user/global or project config.

- [x] 16. Inspect `.mcp.json.example` against the six Codex template recipe IDs and security notes. Modify `.mcp.json.example` only if an existing comment or recipe ID is stale; otherwise leave it unchanged.

### Layer 5 — Entrypoints and capability registry

- [x] 17. Update the managed MCP section in `AGENTS.md`: keep it concise, point Codex users at `.claude/rules/mcp-recipes.md` and `.codex/config.toml.example`, and mention Codex does not receive Claude's SessionStart MCP hint.

- [x] 18. Mirror the same managed MCP section wording in `CLAUDE.md`. Managed blocks between `AGENTS.md` and `CLAUDE.md` must remain byte-identical.

- [x] 19. After tasks 1-18 and the real dogfood in task 21 pass, update `.claude/rules/runtime-capabilities.md`: promote only the `MCP recipes` row for Codex CLI from `convention` to `native-opt-in`; keep Claude Code `native-opt-in`; update owner-file notes to include `.mcp.json.example`, `.codex/config.toml.example`, and `.claude/rules/mcp-recipes.md`.

### Layer 6 — Dogfood and notes

- [x] 20. Validate the fal.ai HTTP/bearer-token config shape without requiring a real `FAL_KEY`: use the disabled template block or an isolated temp config to prove Codex accepts `url` + `bearer_token_env_var = "FAL_KEY"` structurally. Record command and result in `notes.md`.

- [x] 21. Dogfood one stdio recipe with real Codex CLI. In a temp consumer-style project, copy `.codex/config.toml.example` to `.codex/config.toml`, enable only Playwright, and prove Codex sees/starts the MCP path without relying on Claude. Record exact command, result, and any caveat in `notes.md`.

- [x] 22. Update `docs/specs/098-codex-mcp-recipes-parity/notes.md` with the final implementation evidence: disabled-block probe, `codex mcp add` scope, fal.ai shape validation, Playwright dogfood, and any template fallback decision.

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria. Each one should map to a checklist item there._

- [x] 23. Run `bash .claude/tests/codex-mcp-recipes/run-all.sh` — all template checks pass.

- [x] 24. Run `bash .claude/tests/harness-sync/run-all.sh` — all harness-sync tests pass, including the new Codex config safety regression.

- [x] 25. Run `bash .claude/tools/check-instruction-drift.sh --root "$(pwd)" --agent0-path "$(pwd)"` — managed block parity, runtime-capability anchors, and sync baseline checks remain clean after the `AGENTS.md` / `CLAUDE.md` edits.

- [x] 26. Run `bash .claude/tools/sync-harness.sh --check --agent0-path "$(pwd)" "$(pwd)"` — upstream source repo reports `.codex/config.toml.example` as covered and clean; no `.codex/config.toml` appears in the managed manifest.

- [x] 27. Manual acceptance walk: verify every checkbox in `docs/specs/098-codex-mcp-recipes-parity/spec.md § Acceptance criteria` is satisfied by the diff and recorded evidence. Pay special attention to no auto-enable, no non-MCP Codex config, no real config writes, and no runtime registry overclaim.

- [x] 28. If all checks pass, update `docs/specs/098-codex-mcp-recipes-parity/spec.md`: mark satisfied acceptance criteria with `[x]` and change `**Status:** draft` only when the implementation is fully shipped and ready for audit.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._
