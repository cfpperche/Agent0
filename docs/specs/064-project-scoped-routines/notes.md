# 064 — project-scoped-routines — notes

_Created 2026-05-19._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-05-19 — parent — leader-flag filename uses `.agent0-` prefix

Resolved `spec.md` Open Q via task 1. **Decision: `~/.claude/.agent0-routines-leaders.json`** (NOT `~/.claude/.routines-leaders.json`).

Rationale: `~/.claude/` is Anthropic's user-config dir for Claude Code itself. A future CC release could ship its own `routines-*` config file (the native `/schedule` skill already lives there in some shape), and a bare `.routines-leaders.json` would be a collision waiting to happen. The `.agent0-` namespace prefix mirrors the same discipline used in `metadata.agent0-portability-tier` (per `.claude/skills/skill/references/portability-tiers.md`) — when Agent0 writes to a shared filesystem location, the prefix declares ownership and avoids future ambiguity.

Implication for downstream tasks: `install-routines.sh`, `uninstall-routines.sh`, `run-routine.sh` all read/write `~/.claude/.agent0-routines-leaders.json`. The `.claude/rules/routines.md` § Leader-flag model documents this filename verbatim.

### 2026-05-19 — parent — cron validator scope is 30-line bash regex, no deps

Resolved `spec.md` Open Q via task 2. **Decision: ship the 30-line bash regex validator** (5 fields, each matching `*|N|N-N|N/N|N,N`), document its limits explicitly in `.claude/rules/routines.md`.

Rationale: pulling a dep (e.g. `cron-validator`, `croniter`) would violate the `agentskills-portable` portability tier the `/routine` skill targets (per `.claude/skills/skill/references/portability-tiers.md` — universal primitives only: file IO, shell, web). The 30-line regex covers ~95% of real cron expressions; the long tail (`@reboot`, `@yearly`, named days `MON-FRI`, special chars `L`/`W`/`#` for advanced schedulers like Quartz) is out of scope for v1. If a fork needs those, they can author the routine with a bare `*/5 * * * *`-style expression OR override the validator via `# OVERRIDE: cron-syntax-extended: <reason>` on the routine file's first body line.

Documented limits in `routines.md`: (a) 5 fields only (no 6/7-field Quartz extensions); (b) special strings `@reboot`/`@yearly`/`@monthly`/`@weekly`/`@daily`/`@hourly` rejected (use `0 0 * * *` etc.); (c) named day-of-week (`MON`-`SUN`) rejected (use numeric); (d) advanced Quartz chars (`L`/`W`/`#`) rejected.

### 2026-05-19 — parent — `idempotent: false` is hard-rejected by validate

Resolved `spec.md` Open Q via task 3. **Decision: hard reject** at `/routine validate <slug>`; not warn-with-override.

Rationale: a recurring action that is NOT idempotent is by construction wrong-shape for this capacity — running it twice would cause harm (duplicate commits, duplicate PRs, duplicate emails), which the 4-layer N-fold defense in `spec.md` exists to prevent. Allowing `idempotent: false` with an override would create a class of routines where the override has to fire on every run, which is no override at all — it's just disabling the discipline. Cleaner: route non-idempotent recurring work to `/remind` (manual fire, human-in-loop every time) or to `/sdd new` (one-shot work, not recurring).

Exit code convention: `exit 1` with stderr `validate: idempotent: false is not allowed for routines. Use /remind for one-shot deferred work, or wrap the action in an idempotency-preserving guard (e.g. check-then-act).`

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

### 2026-05-19 — parent — validate.sh cron loop glob-expansion bug + fix

`plan.md` task 11 specified "ship a 30-line bash regex validator". First-pass implementation iterated cron fields via `for field in $expr`, which bash word-splits AND glob-expands. Unquoted `*` in a cron expression (e.g. `0 9 * * *`) got expanded against the script's invocation CWD, yielding spurious "field" values like `CLAUDE.md`. Smoke test caught it immediately on the scaffolded template's default schedule.

**Fix:** use `read -ra fields <<< "$expr"` to populate an array, then `for field in "${fields[@]}"` — array iteration is glob-safe. No deviation from the 30-line target; the fix was 2 lines (replace the for loop's iterator). Documented for future maintainers: any bash script that tokenises cron expressions must use array iteration or `set -f`/`set +f` around the loop.

Validator now passes 6 dogfood edge cases: scaffold default (`0 9 * * *`), idempotent-false-rejected, special-string-rejected (`@daily`), missing-done-block-rejected, missing-done-block-with-override-accepted, complex-expression-accepted (`0,15,30,45 9-17 * * 1-5`).

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

### 2026-05-19 — parent — list.sh script vs prose-only subcommand

Tasks 17-19 (list / run / dismiss subcommands) were ambiguously specified in `plan.md` — could be implemented as standalone bash scripts under `scripts/` (like `validate.sh` + `new.sh`) OR as prose instructions in `SKILL.md` for Claude to execute (like `/remind`'s subcommands).

**Decision: hybrid.** `list` got `scripts/list.sh` (deterministic enumeration, format-stable output — script gives consistent UX across sessions); `run` and `dismiss` stay prose-only in SKILL.md because they require Claude to dispatch the prompt into the current session (run) or apply context-aware policy (dismiss skip rationale). The script-for-deterministic, prose-for-agent-judgment split mirrors how the broader Agent0 skills folder is organized.

**Tradeoff:** consistency would have argued for prose-only across the board (matches `/remind`); robustness argues for scripts wherever output is deterministic. The hybrid pays a small consistency cost (two patterns in the same skill) to gain deterministic `list` output that downstream consumers (humans grepping, sub-agents parsing) can depend on.

### 2026-05-19 — parent — sync-harness manifest gap (`.claude/routines/.gitkeep`)

Discovered during Phase 5 dogfood verification: the sync-harness's `COPY_CHECK_FILES` listed `.claude/memory/.gitkeep` and `.claude/.browser-state/.gitkeep` but NOT `.claude/routines/.gitkeep`. Without it, a fresh fork after sync would lack the empty `.claude/routines/` directory; `/routine new` would still work (it `mkdir -p`s) but `/routine list` and the `routines-readout.sh` hook would silently report "no routines directory" instead of "no routines defined" — a discoverability regression for forks.

**Fix:** added `.claude/routines/.gitkeep` to `COPY_CHECK_FILES`, plus a documentation paragraph above the array explaining the "directory ships via .gitkeep, content stays project-local" convention (mirrors the existing memory + browser-state comments).

Verified end-to-end via `bash sync-harness.sh --check` against an isolated test fork in `/tmp`: drift report correctly listed all 12 new files (5 skill scripts, 1 hook, 1 rule, 3 tools, 1 `.gitkeep`, 1 CLAUDE.md merge).

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._

### 2026-05-19 — parent — routine prompt specificity affects "what's drift"

Dogfood finding from 2nd `/routine run cc-platform-audit` invocation. The 1st run reported "drift-detected: 29 → 32 events" and applied event-table edits — but missed payload-shape drift (`effort` / `agent_id` / `agent_type` / `CLAUDE_ENV_FILE` field additions) that a deeper WebFetch + comparison surfaced on the 2nd run. The 2nd run was NOT a false-positive — those fields are genuinely undocumented in the memo's *Payload shape* section.

The 2nd run reported drift not because the routine is non-idempotent, but because the **routine's prompt was underspecified about WHICH dimensions to audit**. "Compare against memo" is too broad; "compare event names" naturally surfaces tabular drift first; "compare payload shapes" requires explicit re-direction.

**Question for future iteration**: should routine prompts be MORE specific (enumerate audit dimensions: events / payload shape / exit-code semantics / matcher coverage), accepting that they become longer/harder to author? Or should the prompt stay terse and accept that "convergence to no-drift" may take 2-3 runs as the agent's attention naturally rotates through dimensions?

**Owner**: founder, after observing 3-5 more cc-platform-audit cycles. If convergence consistently takes 2+ runs, tighten the prompt. If 1 run reliably catches everything, leave terse.

This isn't a bug in spec 064's mechanism — the routine prompt + idempotency mandate work as designed. It IS a finding about routine-author discipline that's worth documenting for the next person writing a routine.
