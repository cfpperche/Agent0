# 108 — secrets-scan-multi-runtime — notes

_Created 2026-05-28._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-05-28 — parent — Claude preflight registration must use a BARE `matcher: Bash`, not an `if`-pipe glob (V8 live-dogfood bug)

Live Claude dogfood (cold session) surfaced that the preflight **never fired** on a real `git commit` — neither a compound `git add foo.txt && git commit -m x` (no block) nor a plain `git commit -m y` (no `passthrough`/`reject-shape` row in the Agent0 audit). The native layer worked (`allow` rows in the scratch repo) and the hook script itself blocks correctly on direct invocation (exit 2 + template), so the fault was purely the settings.json registration.

Root cause, confirmed against the official permissions docs (<https://code.claude.com/docs/en/permissions.md>): the registration's filter `"if": "Bash(git commit *|git commit|*git commit *|*git commit)"` uses **pipe-alternation inside a single `Bash(...)` specifier, which Claude Code does not support**. `|` is a recognized shell *command separator* in permission-rule syntax ("a rule must match each subcommand independently"), not an alternation operator — multi-pattern rules are expressed as separate array elements (`"Bash(npm run *)", "Bash(git commit *)"`), never `Bash(a|b|c)`. So the specifier can never match a real `git commit` (which contains no literal `|`), and the conditional hook silently never runs. This is NOT a stale-session/cold-restart issue — a perfect restart would still never match the broken pattern.

Decision: **drop the `if` entirely and use a bare `"matcher": "Bash"`** (identical to the governance gate, and to the Codex `^Bash$` registration). Justification: (a) the spec-108 script was already redesigned to self-filter — it exits silently on non-commit Bash — precisely so it can run under a broad matcher; (b) Codex already runs it this way and its live preflight rows (`reject-shape`/`compound-and` + `override-pass-through`) landed correctly today (2026-05-28 21:21–21:22); (c) the governance gate (bare matcher) fired correctly on a *compound* `rm -rf` this same session, proving bare-matcher + in-script detection handles compound commands; (d) a narrow single-pattern `if` (`Bash(git commit *)`) was rejected because `if`-on-compound semantics are undocumented and would likely miss the V4 compound-block case (git commit as the 2nd subcommand). Cost accepted: the hook process now spawns on every Bash call (fast: jq + grep + early exit; latency suite green).

Fix applied to `.claude/settings.json` this session; **the same latent `if`-pipe bug exists in the supply-chain registration** (`Bash(npm *|pnpm *|...)`, line ~80) — out of 108 scope, flagged for spec 109. **V8 Claude live re-verification still requires a genuine cold restart** so the corrected registration loads.

**2026-05-28 (cold-restart follow-up) — V8-Claude live: PASS.** After the cold restart loaded the bare-matcher registration, the dogfood re-ran in scratch `/tmp/sp108v`:
- PASSO 1 BLOCK: `git add foo.txt && git commit -m x` (single Bash) → blocked by PreToolUse with the two-invocation template. Agent0 preflight row: `runtime:"claude-code"`, `decision:"reject-shape"`, `cmd_shape:"compound-and"`, real `session_id:"bef8ea61-…"` (not the prior `direct-test` manual probe).
- PASSO 2 OVERRIDE (the previously-unrun V8 crux): `git add fixture.env && git commit -m "fixture"` + two-line `# OVERRIDE: live dogfood spec 108 override path claude`, with `fixture.env` carrying a fake non-stopword AWS-shaped key (`AKIA…`, redacted here so this tracked doc stays scan-clean) → commit ENTERED. Agent0 preflight row: `decision:"override-pass-through"`, `override_reason` populated; scratch native row: `runtime:"native-git"`, `decision:"override"`, `finding_count:1`. Proves the env-var bridge (`export CLAUDE_SECRETS_OVERRIDE_REASON='…'; `) survives the rewrite and reaches the native gitleaks layer on Claude.

Both Claude and Codex live PreToolUse dispatch now confirmed. The dormant-`if`-pipe bug is the headline finding of this spec — it would have shipped silently (zero `claude-code` preflight rows ever) had the V8 live dogfood not been run; harness tests + direct invocation both passed while the registration was dead, because neither exercises CC's real `if`-filter evaluation.

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — what the plan said, what was done instead, why}}

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — options considered in-flight, chosen path, accepted cost}}

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — the question, why it surfaced, what's blocked on it, who can decide}}
