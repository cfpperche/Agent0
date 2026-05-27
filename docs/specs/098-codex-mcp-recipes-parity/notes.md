# 098 — codex-mcp-recipes-parity — notes

_Created 2026-05-27._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-05-27 — Codex CLI — Parseable disabled TOML

Use parseable `[mcp_servers.<id>]` blocks with `enabled = false` in `.codex/config.toml.example`. Evidence: this trusted repo loads project-scoped `.codex/config.toml` under `codex exec --strict-config`, and a disabled stdio probe with a command that would write `.codex/disabled-started.txt` exited cleanly without creating the marker or emitting MCP startup/failure lines. This preserves machine-validated TOML instead of falling back to commented examples.

### 2026-05-27 — Codex CLI — `codex mcp add` is global by default

`codex mcp add` is documented as operator convenience, not as the project-scoped propagation contract. With temp `CODEX_HOME` and a temp trusted project, `codex -C <tmp> mcp add agent0-scope-probe -- sh -c 'cat >/dev/null'` printed `Added global MCP server 'agent0-scope-probe'.`, wrote `$CODEX_HOME/config.toml`, and did not create `<project>/.codex/config.toml`.

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

### 2026-05-27 — Codex CLI — Dogfood used trusted Agent0 repo

The plan described a temp consumer-style project for the Playwright dogfood. The implementation used `/home/goat/Agent0` with a temporary, restored `.codex/config.toml` instead. Reason: Codex project-scoped config is trust-gated, and this repo is already trusted in the installed Codex config; temp projects required trust bootstrapping, while `codex mcp list` only observed global config. The dogfood still used real project-scoped `.codex/config.toml`, real Codex CLI, and a real Playwright MCP tool call.

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

None yet.

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._

None yet.

## Implementation evidence

- 2026-05-27, Codex CLI field support: `codex --version` reports `codex-cli 0.133.0`. `codex mcp add --help` exposes stdio command form plus `--env`, `--url`, and `--bearer-token-env-var`; it does not expose a project-scope flag.
- 2026-05-27, official docs check: OpenAI Codex MCP docs still document user-global `~/.codex/config.toml` and trusted-project `.codex/config.toml`; OpenAI Codex config reference still documents `mcp_servers.<id>.env_vars`, `mcp_servers.<id>.env`, `mcp_servers.<id>.url`, `mcp_servers.<id>.bearer_token_env_var`, and `mcp_servers.<id>.enabled`.
- 2026-05-27, trusted project config load: placing an unknown field in `/home/goat/Agent0/.codex/config.toml` and running `codex exec --strict-config -C /home/goat/Agent0 ...` fails with `unknown configuration field`, proving project-scoped config is loaded in this trusted repo.
- 2026-05-27, disabled-block side-effect probe: with `/home/goat/Agent0/.codex/config.toml` containing `[mcp_servers.agent0_disabled_probe] enabled = false` and a command that would write `.codex/disabled-started.txt`, `codex exec --strict-config --dangerously-bypass-approvals-and-sandbox -C /home/goat/Agent0 'Reply exactly: OK'` exited 0, returned `OK`, did not create the marker file, and emitted no probe/MCP startup/failure lines.
- 2026-05-27, `codex mcp add` scope: using temp `CODEX_HOME` and temp trusted project, `codex -C <tmp> mcp add agent0-scope-probe -- sh -c 'cat >/dev/null'` exited 0, printed `Added global MCP server 'agent0-scope-probe'.`, wrote the entry to `$CODEX_HOME/config.toml`, and did not create `<project>/.codex/config.toml`.
- 2026-05-27, fal.ai HTTP shape validation: with project `.codex/config.toml` containing disabled `[mcp_servers.fal-ai] url = "https://mcp.fal.ai/mcp"` and `bearer_token_env_var = "FAL_KEY"`, `codex exec --strict-config --dangerously-bypass-approvals-and-sandbox -C /home/goat/Agent0 'Reply exactly: OK'` exited 0, returned `OK`, and emitted no fal-ai/MCP startup/failure lines.
- 2026-05-27, Playwright Codex dogfood: with project `.codex/config.toml` containing enabled `[mcp_servers.playwright] command = "npx" args = ["-y", "@playwright/mcp@latest"]`, `codex exec --json --strict-config --dangerously-bypass-approvals-and-sandbox -C /home/goat/Agent0 'Use the Playwright MCP browser tool to navigate to about:blank...'` exited 0. JSONL showed `mcp_tool_call` server `playwright`, tool `browser_navigate`, status `completed`, result page URL `about:blank`, then final agent message `PLAYWRIGHT_MCP_OK`.
