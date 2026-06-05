# 153 — decouple-harness-from-playwright — notes

_Created 2026-06-05._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.agent0/context/rules/spec-driven.md` § The four artifacts for purpose, and `.agent0/context/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-06-05 — parent (claude, squad round 0) — overflow-read mechanism (OQ2 spike) resolved

The plan flagged the one genuine unknown: how `audit` reads horizontal overflow without Playwright's `browser_evaluate`, given the wrapper classifies `eval` as RCE-sensitive. Resolved by probing the real `agent-browser` 0.27.1 CLI:
- `set viewport <w> <h>` exists → drives 375/1280 responsive sizing.
- `eval <js> --json` returns `{"success":true,"data":{"origin":…,"result":<value>},"error":null}` → overflow boolean at `.data.result`.
- **Decision:** call `eval` with a FIXED internal expression (`document.documentElement.scrollWidth > document.documentElement.clientWidth`) directly inside `audit_pages()`. This is safe because (a) the expression is a hardcoded literal, never user/web-derived input; (b) `audit_pages` calls `"$bin"` directly, bypassing the policy gate by design (the policy gate guards the user-facing `run` passthrough, not internal sweep steps); (c) the grep-guard forbids MCP tool tokens, not `eval`. This is exactly the OQ2 fallback the plan pre-authorized.
- Live-validated: a 1600px fragment → `overflow_375=true, overflow_1280=true`; a tidy fragment → `false/false`. `--structure optional` passes landmark-less fragments (h1/main advisory) while `--structure strict` flags them (unchanged 152.1 gate). Shots produced: `<label>.png` (default) + `<label>-375.png` + `<label>-1280.png`.

### 2026-06-05 — parent (claude, squad round 0) — credential-file disposition (HUMAN-GATED)

`.agent0/.browser-state/{linkedin.com,x.com}.json` are the founder's real session cookies from the retired Playwright mechanism (May 12). Superseded by `.agent0/.runtime-state/agent-browser/state/`. Per the deletion-safety rule (don't delete credential-class material I didn't create without confirmation), these are NOT auto-deleted in an autonomous turn — surfaced for founder confirmation at the squad milestone. The tracked scaffold (`.gitkeep` + manifest entries) IS retired in-band; only the live `*.json` await the human's call.

## Deviations

### 2026-06-05 — codex (squad round 7, peer review) — `adopt` was missing the fail-closed guard

Band 1 added `require_primary` to `run`/`verify-contract`/`audit` but **missed `adopt`** — yet spec AC#1 names `adopt` as an explicit command that must fail closed. Codex's adversarial final-review turn (151-F2) caught it: `adopt` would have attempted its CDP poll even with no agent-browser binary / under `AGENT0_BROWSER=mcp`. Repair: `require_primary adopt || return $?` at the top of `adopt_session()`, plus two `04-audit.sh` cases (no-binary adopt → rc 4 fail-closed; mcp-override adopt → rc 3 unsupported). Validated: `04-audit.sh` 16/0. This is the peer-review value the squad exists for — a green gate (the suite passed before because no test exercised adopt's guard) was necessary but not sufficient; the independent reviewer closed the gap.

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
