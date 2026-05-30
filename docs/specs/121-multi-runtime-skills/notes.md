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

### 2026-05-30 — parent — brainstorm migrated (7th) + render-script refinement

`brainstorm` had no hard blocker — no `${CLAUDE_SKILL_DIR}`, no `AskUserQuestion`, state already
under `.agent0/.brainstorm-state/` (neutral), HTML rendered browser-side. The `$ARGUMENTS` + `Write`/`Edit`/`Read`
tool-name references stay, consistent with the precedent set by the already-shipped portable skills
(`remind`/`routine`/`sdd` all keep them); this repo's `agentskills-portable` bar targets `.claude/` paths,
`${CLAUDE_SKILL_DIR}`, and `AskUserQuestion`, none of which brainstorm had.

**Refinement (port = refinement, not transcription):** the `done` step used to hand-substitute eight HTML
placeholders in prose — the single most error-prone step on *any* runtime. Inspection of the template showed
every placeholder is a deterministic function of the finalised state JSON (all judgment — tagging, lens
application — happens during the session, not at render). So the whole render was extracted into
`scripts/render.py` (pure `state.json → HTML`). This (a) makes `done` deterministic, (b) gives brainstorm its
first testable surface (`.agent0/tests/brainstorm/`, previously SKILL-RUBRIC-EXEMPT with zero tests), and (c)
fixes two real hand-render bugs found in the shipped smoke artifact: an **empty `{{MINDMAP_MARKDOWN}}`** (the
agent skipped it) and the mermaid **`:` field-delimiter collision** (mermaid `timeline` parses `:` as a field
separator, so colons in summaries must be replaced — the script does it, a hand-render forgot once). python3
(already a dependency precedent via image's `gen.sh`); template resolved relative to the script path, no
`${CLAUDE_SKILL_DIR}`. The product skill stays the only intentionally `cc-native` skill (`AskUserQuestion` ×7).

### 2026-05-30 — parent — image estreia `agents/openai.yaml` (first skill with one)

`image` is the first migrated skill with both (a) a real MCP dependency and (b) a hard reason not to auto-fire (paid, side-effecting generation). Per the runbook step 5, that's exactly when `agents/openai.yaml` is warranted, so `image` ships the first one: `policy.allow_implicit_invocation: false` (explicit `$image` / `/skills` only) + a `dependencies.tools` entry declaring the optional fal-ai MCP. It is written to read as the reference template for future skills-with-MCP. Schema taken from developers.openai.com/codex/skills (`interface` / `policy` / `dependencies.tools[].{type,value,description,transport,url}`).

### 2026-05-30 — parent — Live-Codex verification: pilot discovery + `$`-invocation confirmed end-to-end

Closes reminder `r-2026-05-30-live-codex-confirm-spec-121` (the live counterpart to the offline symlink/discovery tests). Two halves, both confirmed against a real Codex CLI 0.135.0 at repo root:

**Half 1 — discovery (headless, `codex debug prompt-input`):** the rendered model-visible prompt-input lists 6 implicitly-invocable Agent0 skills (`brainstorm, remind, routine, sdd, skill, vuln-audit`), each with its realpath-resolved `…/.agent0/skills/<slug>/SKILL.md` reached through the `.agents/skills/<slug>` symlinks. `vuln-audit` present with full description + path. `image` is **correctly absent** from the implicit list — `agents/openai.yaml` `policy.allow_implicit_invocation: false` (paid/side-effecting) suppresses it from auto-fire while `$image` stays explicit. The 6-listed-vs-7-symlinked gap is the designed behavior, not a regression.

**Half 2 — `$vuln-audit` triggers the tool (live TUI turn, human-run):** typing `$vuln-audit` in a real Codex TUI session produced all three expected signals: (a) Codex **announced** "Using the vuln-audit skill now"; (b) it **opened** `SKILL.md` + the `vuln-audit.md` rule and followed the workflow; (c) it **executed** `bash .agent0/tools/vuln-audit.sh` — the real wrapper, not an inlined re-implementation. The run returned `status=unavailable` because the `osv-scanner` binary isn't installed on this machine (the tool degraded cleanly, naming the npm/bun ecosystems it *would* have scanned). That is the separate open smoke-test (`r-2026-05-30-run-vuln-audit-once-against`), **not** a spec-121 failure — the discovery→trigger→wrapper-exec wiring is fully proven.

**Bonus:** the same Codex TUI turn injected the SessionStart brief + per-turn capsule carrying spec 125's `▸` markers, giving a live (TUI, not headless) confirmation of the 125 Codex path on top of scenario 5b.

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
