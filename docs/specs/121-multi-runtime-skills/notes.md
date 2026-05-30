# 121 — multi-runtime-skills — notes

_Created 2026-05-30._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-05-30 — parent — image is the 6th migration; "Codex-MCP-parity" blocker dissolved

The HANDOFF flagged `image` as blocked: _"fal.ai MCP — answer Codex-MCP-parity first, not just relocate."_ Investigation showed the blocker was a non-issue, and the analysis is the new content this migration adds vs the prior five (`vuln-audit`/`remind`/`routine`/`sdd`/`skill`, none of which had an MCP dependency):

1. **Generation never used the MCP.** Since spec 088, `gen.sh exec` generates via `curl` POST to the `fal.run` REST API (the hosted MCP's `run_model` was diagnosed broken). That path is bash + curl + jq — runtime-neutral by construction. The MCP only ever covered the *optional* discovery tools (`search_models`, `get_model_schema`, `get_pricing`, `recommend_model`).
2. **Codex has full MCP parity for the fal-ai server.** Confirmed against official docs (developers.openai.com/codex/mcp + /config-reference): `[mcp_servers.NAME]` accepts `url`, `bearer_token_env_var`, `enabled` — the exact shape Agent0 already ships in `.codex/config.toml.example`, and which the maintainer's local `.codex/config.toml` already had `enabled = true`. So discovery works identically in both runtimes; only the per-runtime tool *namespace* differs (`mcp__fal-ai__*` in Claude Code vs Codex's own), which is why the body now refers to the tools by their fal.ai names, not the CC-prefixed spellings.

Net: `image` is `agentskills-portable`, not `cc-native`. The only genuinely new neutralization vs the prior five was the `mcp__fal-ai__*` tool-name spellings (now de-prefixed) — there was no `${CLAUDE_SKILL_DIR}` in the body, so no collision with the `port-frontmatter.sh` detection token.

### 2026-05-30 — parent — image estreia `agents/openai.yaml` (first skill with one)

`image` is the first migrated skill with both (a) a real MCP dependency and (b) a hard reason not to auto-fire (paid, side-effecting generation). Per the runbook step 5, that's exactly when `agents/openai.yaml` is warranted, so `image` ships the first one: `policy.allow_implicit_invocation: false` (explicit `$image` / `/skills` only) + a `dependencies.tools` entry declaring the optional fal-ai MCP. It is written to read as the reference template for future skills-with-MCP. Schema taken from developers.openai.com/codex/skills (`interface` / `policy` / `dependencies.tools[].{type,value,description,transport,url}`).

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

### 2026-05-30 — parent — fixed a pre-existing stale assertion in `02-brand-text-workflow.sh`

The path-only edit to the four `.agent0/tests/image-gen/*.sh` files surfaced that `02-brand-text-workflow.sh` was already failing before this migration: it asserts `estimated: $0.040` / `approx_cost_usd == 0.04`, but `gen.sh` has emitted `$0.200` for `brand-text` since spec 088 baked `quality: "high"` as the default (documented in `tier-pricing.md` footnote `[^1]`; the table lists brand-text at `~$0.20 (high default)`). The test predated that decision and drifted. Since it sat in the suite this migration touches and would otherwise read as a regression I introduced, I aligned the three stale assertions (cost-line, `approx_cost_usd` check, and the mock `--cost`) to the documented `0.200`. Oracle = the tier-pricing table + the script's deliberate quality:high default; the test was simply stale, not catching a real bug. All four image-gen scenarios pass post-fix.

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — options considered in-flight, chosen path, accepted cost}}

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — the question, why it surfaced, what's blocked on it, who can decide}}
