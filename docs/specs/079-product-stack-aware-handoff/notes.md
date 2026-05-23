# 079 — product-stack-aware-handoff — notes

_Created 2026-05-22._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.claude/rules/spec-driven.md` § The four artifacts for purpose, and `.claude/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-05-23 — parent — stack-aware matrix validated live: Expo matrix is genuinely Expo-shaped, not relabeled-Next

The 079 ship moment was the SKILL.md/template rewrite + the static spec-079 test suite. The remaining question was empirical: does the Phase 5 matrix that comes out the other end actually reflect the declared `--stack` at the level of integration choices, not just at the level of the `--stack` label? Validated 2026-05-23 as part of the spec-075 task-14 dogfood (`/product "habit tracker" --stack=expo --out=/tmp/product-dogfood-2026-05-23-expo`). The umbrella spec at `docs/specs/001-habit-tracker/spec.md` came out with **13 children, infra block-precede shape intact**:

- Child #1 `002-foundation` — scaffolded; **explicitly cites `.claude/rules/research-before-proposing.md`** with the verbatim phrasing "no Agent0-bundled template is consumed — none ships" + mandates web research at `/sdd plan` time for the declared Expo stack. This is the spec-079 contract front-and-center in the only spec the founder reads first.
- Child #2 `component-library` — matrix-only, named.
- Children #3..#10 (8 infra rows) — every one is Expo-specific: `schema-rls` (Postgres + Drizzle), `auth-foundation` (Apple OAuth + Google OAuth + JWT rotation), `anthropic-coach-integration` (Claude Sonnet via SSE + Whisper), `iap-validation` (**Apple StoreKit 2 + Google Play Billing**), `railway-deploy` (Hono on Railway + Postgres + Redis), `observability-floor`, `eas-pipeline` (**EAS Build + EAS Submit + TestFlight + Play Console**), `reflection-encryption` (libsodium HKDF). Every row labeled "Phase 1 — infra (**block-precedes #11**)" per the contract.
- Children #11..#13 — per-phase visual children sliced by `docs/roadmap.md` phases verbatim, each scoped to the screens whose `covers_us` maps to that phase's US-NN tier.
- `## Open questions` populated with the system-design § Trade-off Triggers + § Open Decisions rows, each prefixed `**Architecture — <topic>:**` per `sdd-handoff.md § Open questions migration`.
- `## Standing constraints` lists the 5 standing constraints from `sdd-handoff.md § Standing constraints` (stack-conditional styling / no inline style for layout / mobile-first 375 px / fixture coherence via `docs/fixture-spec.md` / Playwright visual verification).

The integration-shape choices are the load-bearing test. A `--stack=next` run would produce a fundamentally different infra set — no IAP child (web payments use Stripe, not native receipt validation), no EAS pipeline (Vercel deploy + Next build), no expo-sqlite local-only reflection storage (Web Storage API + IndexedDB), `auth-foundation` uses NextAuth.js or Auth.js conventions. The Expo run's matrix is a real artifact of the declared stack, not a Next.js matrix wearing Expo labels.

Skipped the side-by-side `--stack=next` second run (user decision 2026-05-23) — the existence of stack-specific integration choices in this run already proves the mechanism. A second-stack run is a "comparative data" follow-up worth doing when the first real user needs the other stack, not a validation gate.

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — what was ambiguous, what was decided, why}}

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

### 2026-05-23 — parent — historical mention of `app-skeleton` retained in SKILL.md v0.5.0 changelog paragraph

Task 12 said `grep -n 'app-skeleton' .claude/skills/product/SKILL.md` should return nothing. The v0.5.0 paragraph I added in task 11 names the deleted dirs explicitly ("the bundled `templates/app-skeleton/{next,expo}/` directories and `references/stack-defaults.md` snapshot are deleted") to mirror the v0.4.0 paragraph shape ("the v2/v3 36-route per-route screen-writer fan-out is **deleted**"). The match is historical-context, not a live consumer reference — readers landing on the changelog see what changed and why.

Equally, the description in the frontmatter was tightened to "No stack code ships — Phase 5 reads system-design + roadmap to compute a stack-aware umbrella matrix; the foundation child's `/sdd plan` researches the declared stack." (replacing "Standalone (bundled templates)."), and the version pointer bumped from "v0.4.0 per spec 066." to "v0.5.0 per spec 079." — both correctness fixes not explicitly in tasks.md but follow-through on the version bump.

The verification at task 33 (`rg -F 'app-skeleton' .claude/ docs/specs/`) accepts historical specs as known matches; the SKILL.md changelog paragraph belongs in the same category — past-behavior reference in living documentation. No corrective action taken.

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — options considered in-flight, chosen path, accepted cost}}

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — the question, why it surfaced, what's blocked on it, who can decide}}
