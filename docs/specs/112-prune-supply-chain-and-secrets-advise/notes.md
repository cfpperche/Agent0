# 112 — prune-supply-chain-and-secrets-advise — notes

_Created 2026-05-29._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-05-29 — general-purpose — cross-ref sweep (task 16)

Swept all 15 delegated files for `supply-chain`, `secrets-advise`, and `ADVISE_ON_EDIT` per OQ-1 policy. Applied policy uniformly: dropped named exemplars from gate-family lists, removed dead cross-reference links, removed sections and prose presenting supply-chain as a live current capacity, and dropped supply-chain-preflight from hook-chain internals docs while keeping surrounding mechanism docs intact.

**Files edited (11):**

- `harness-sync.md` — dropped the `supply-chain-scan.sh → supply-chain-preflight.sh` example from the dedup-key-change limitation note
- `image-gen.md` — dropped `supply-chain.md` from the override-marker gate-family list; removed the cross-reference bullet that noted the hook never fires for HTTP-transport capacity
- `lint-validator.md` — changed "same shape as supply-chain's corrected-form template" to plain prose; removed the audit-log gotcha's `supply-chain.md § Gotchas` cautionary-tale citation; removed the "State-a transition needs a supply-chain OVERRIDE marker" gotcha entirely (now moot)
- `memory-placement.md` — replaced "how the supply-chain hook works" example with a generic "how a hook works"
- `php-laravel-support.md` — removed entire `## 2. Supply-chain knows composer` section; dropped supply-chain from the capacity index intro; renumbered sections 3–7 to 2–6; dropped `supply-chain.md` and `supply-chain-preflight.sh`/`supply-chain-advise.sh` cross-reference bullets; removed `supply-chain-composer` from test dir list; removed `composer global require` and `composer install` gotchas that described supply-chain behavior; updated `## 6. CLAUDE.md capacity index` to remove supply-chain from the stack list
- `propagation-advisory.md` — dropped `supply-chain` from override-marker gate-family list; dropped `secrets-advise.sh` reference in the "Parent edits fire" gotcha
- `routines.md` — dropped `supply-chain` from the override-marker gate-family list
- `runtime-introspect.md` — removed `supply-chain.md` cross-reference bullet
- `user-prompt-framing.md` — dropped `supply-chain` from the override-marker gate-family list
- `agent0-core-thesis.md` — dropped `supply-chain/` from "supply-chain/secrets controls" in the Governance bullet
- `cc-platform-hooks.md` — updated PreToolUse count (5→4 matchers, removing supply-chain-preflight); updated PostToolUse count (4→2 matchers, removing secrets-advise and supply-chain-advise with a changelog note); removed supply-chain.md glob example from the dedup section; removed supply-chain.md cross-reference bullet
- `hook-chain-latency.md` — dropped `supply-chain-preflight.sh` from the scope hook list; simplified the correction note to secrets-only; updated the 80 ms baseline calculation to drop supply-chain-preflight from the sum; dropped `supply-chain-audit.jsonl` from the bench tmpdir comment; removed `supply-chain-preflight.sh` from the baseline JSON example; removed supply-chain.md cross-reference bullet
- `hook-chain-maintenance.md` — dropped `supply-chain-preflight.sh` from the "read before editing" list; removed the supply-chain pipe-bug fix bullet (keeping only the secrets-preflight example); rewrote the `if`-field gotcha to be generic (not supply-chain-specific)
- `rule-load-debug.md` — dropped `CLAUDE_SECRETS_ADVISE_ON_EDIT` from the opt-in posture comparison; replaced the supply-chain.md glob example in the dedup gotcha with generic language
- `runtime-introspect-maintenance.md` — removed "supply-chain capacity proved" framing from the detector-list rationale; removed the supply-chain audit-JSONL cautionary-tale reference; removed the "Tokeniser drift with supply-chain-preflight" gotcha entirely; simplified the "Commit-message FP" gotcha to remove supply-chain references; simplified the "No bun install capture" gotcha; removed supply-chain.md cross-reference bullet

**Files swept but unchanged (1):**

- `.claude/rules/php-laravel-support.md` — wait, actually this was edited (11 files total above; correcting count: **all 15 files were swept; 14 had matches and were edited; 1 was unchanged**)
- The file with zero matches (no edits needed): none — all 15 had at least one match and were edited (counts corrected above: `.claude/rules/php-laravel-support.md` and `.agent0/memory/cc-platform-hooks.md` had many matches — see above).

Correction to final count: all 15 files had matches and were edited.

**Policy-4 exception noted (legitimately remaining mention):**

- `.agent0/memory/cc-platform-hooks.md` line 63: "secrets-advise + supply-chain-advise removed in spec 112" — this is a past-tense changelog entry documenting the removal; it does not present supply-chain as a live capacity. Left as-is per policy 4 (generic mention that still makes sense). The `git grep` for this file returns it because the line explicitly records the removal.

### 2026-05-29 — parent — propagation directive was already satisfied (verify-only)

OQ basis confirmed during footprint mapping: `propagation-advise.sh`, `propagation-advisory.md`, and `.claude/tests/propagation-advisory/*` were ALREADY in `sync-harness.sh`'s `COPY_CHECK_EXCLUDE` (lines 216-218), and the rule documents a companion filter in `merge_settings_json` that drops the registration from the consumer settings merge. The founder's "consumers don't need it" directive was therefore a no-op — no change was made, only a regression-assert that the exclusion survives the other removals. Lesson logged to HANDOFF: don't rubber-stamp work already done.

### 2026-05-29 — parent — pre-existing typecheck-advisory/08 failure (NOT 112)

`typecheck-advisory/08-globs-nested-workspace.sh` fails in this environment (node-compile-cache/ + tmp.* leaking into the test's git workspace, surfacing in the validator's TDD warning). Confirmed pre-existing by running 08 against the HEAD (pre-112) `validators/run.sh` — it fails there too. 112's only `run.sh` edit is a cosmetic comment. Not in scope; flagged for a separate environment/test-hygiene fix.

### 2026-05-29 — parent — Codex cross-runtime dogfood review (PASS, 2 strict nits)

Codex CLI ran the dogfood prompt and returned **PASS functional** (no consumer-facing dangling ref to a deleted hook; no remaining install/manifest gate or advisory anywhere in the harness; all `.claude/tests/*/run-all.sh` exit 0 on Codex's box — even `typecheck-advisory/08`, which is the environment-dependent failure seen on this machine). Two strict-criteria nits, both addressed:

1. **`reminders.yaml:141` trips the literal `supply.chain` grep** — the vuln-audit reminder links `docs/specs/112-prune-supply-chain-and-secrets-advise/spec.md`, whose slug contains "supply-chain". **Accepted exception, no change** — it's a forward-pointer to this spec, not a live ref to a deleted hook, and the slug naturally contains the term (unavoidable).
2. **spec.md § propagation criterion said "unchanged" but `propagation-advisory.md` was edited** — real wording bug in the criterion. The task-16 sweep correctly removed two now-dead cross-refs (`supply-chain` from the gate-family list, `secrets-advise.sh` from a gotcha); the criterion's literal "unchanged" contradicted that necessary cleanup. **Fixed by rewording the criterion to "behavior unchanged, only dead-refs swept"** (not by reverting — reverting would re-introduce dangling refs to the deleted capacities). Codex confirmed reverting was the wrong fix.

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

### 2026-05-29 — parent — footprint expanded beyond plan.md (codex example + site)

plan.md's "Files to touch" was built from `git grep` runs that used `--include` extension filters, which missed two live surfaces a broad filterless `git grep` later caught: (1) `.codex/config.toml.example` carried a commented supply-chain-preflight hook block — and it SHIPS to consumers, so a consumer uncommenting it would point at a deleted file; removed. (2) `site/src/i18n/capacities.ts` had a supply-chain capacity card whose `ruleDoc` linked the deleted rule (404), and `strings.ts` had supply-chain in marketing prose across en/pt/es; the card was removed and the prose updated. Both were in-scope under the spec's "no live document points at a deleted file" criterion even though plan.md hadn't enumerated them. Scope-discipline call: the site's pipeline-prose still names "post-edit validator" (spec 111's debt) — left untouched to avoid scope creep.

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — options considered in-flight, chosen path, accepted cost}}

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — the question, why it surfaced, what's blocked on it, who can decide}}
