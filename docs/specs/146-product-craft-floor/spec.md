# 146 — product-craft-floor

_Created 2026-06-03._

**Status:** shipped (2026-06-03 — implemented + validated, 9/9 craft-floor tests + 46/46 OD-engine; OQs resolved with Codex)

## Intent

Give `/product` a **brand-agnostic quality floor** that mechanically catches the recurring "AI-slop" tells in its emitted visual artifacts — the one genuinely-valuable, non-replaceable-by-a-prompt idea in Open Design's `craft/` axis (established by the 2026-06-03 Claude↔Codex meeting, `.agent0/meetings/open-design-overengineering-for-agent0-2026-06-03T16-24-35Z/meeting.md`). OD's `craft/` is a third layer beside `skills/` (artifact shape) and `design-systems/` (brand language): universal design rules, of which `anti-ai-slop.md` carries a small set of **deterministic, checkable P0 rules** targeting exactly the LLM default-aesthetic failure mode. Today `/product` injects brand (`design-systems/`) + the 5 design "schools" (`directions.ts`) at the visual steps and grades with a quality-judge, but has **no floor that flags slop** — so a run can drift into generic SaaS styling and only a human notices. This spec ports the *mechanism* (a tiny deterministic anti-slop check + a judge dimension), not OD's content: Agent0's ethos is "ship mechanisms, not frozen templates," and the meeting set firm red lines against importing OD's prose corpus or building a harness-wide aesthetic linter.

## Acceptance criteria

- [x] **Scenario: deterministic anti-slop advisory over `/product` visual artifacts**
  - **Given** a `/product` run that emitted visual artifacts (`docs/direction-{a,b,c}.html`, `docs/screens/hifi/**`)
  - **When** the craft-floor check (`scripts/craft-floor-check.ts`) runs
  - **Then** it flags the **5 deterministically-safe** P0 tells (resolved with Codex) with file + snippet — `default-indigo-accent` (exact Tailwind defaults `#6366f1`/`#4f46e5`/`#4338ca`/`#3730a3`, brand-token-exempt), `trust-gradient` (literal two-stop purple→blue / blue→cyan `linear-gradient(...)`, brand-token-exempt), `emoji-feature-icon` (emoji in heading/button/feature-icon positions), `filler-copy` (`lorem ipsum`, `feature one|two|three`, placeholder text), `sans-display-when-serif-bound` (default sans on `h1-h3`/hero when the DESIGN.md binds a serif display font) — emitting JSON, **advisory by default** (does not hard-block artifact persistence)
  - **And** the two **noisy** tells (`rounded-card-colored-left-border`, `invented-metrics`) are NOT auto-checked — they are downgraded to judge-only guidance prose (too false-positive-prone for regex)

- [x] **Scenario: a legitimate brand exception is not a false positive**
  - **Given** the bound `design-systems/` `DESIGN.md` legitimately specifies a purple/indigo accent (e.g. a brand whose `--accent` is in that range)
  - **When** the check runs
  - **Then** that brand's accent does not fire the indigo-default rule (the rule targets the *un-bound Tailwind default*, not a brand-declared token) — i.e. the check reads the bound design system's tokens before flagging

- [x] **Scenario: `craft-floor` judge criterion on the two authored-visual judge-units only**
  - **Given** the `/product` quality-judge runs on judge-units `02-prototype` (lo-fi mood) and `15b-hifi-mood`
  - **When** it grades
  - **Then** it scores a `craft-floor` criterion (in `quality-checklist.md`) against the deterministic findings (consumes the JSON, does not re-discover them: `fail` if `active_p0 > 0`) plus the two judge-only guidance tells; the criterion is **absent** from `15a-screen-atlas` (a contract/inventory artifact, not authored aesthetics — resolved with Codex) and from all non-visual judge-units (01-14, 15c)

- [x] **Scenario: P0 may fail Step 15b, never hard-blocks persistence**
  - **Given** Step 15b hi-fi output with an unexempted P0 violation
  - **When** the judge grades
  - **Then** it MAY return a quality `fail` for that step (absent a brand/design-system exemption), but the artifact is still written to disk — the floor gates *quality verdict*, not *persistence*

- [x] **Scenario: short anti-slop reminder injected only into visual briefs**
  - **Given** the Step 02 and Step 15b briefs
  - **When** they are composed
  - **Then** they carry a short anti-slop reminder; non-visual step briefs are unchanged

- [x] The P0 rule list is **authored under Agent0 ownership** (rewritten, not vendored from OD's `craft/`), with attribution if any wording is copied; it lives inside the `/product` package (per `[[feedback_mcp_package_self_contained]]`), not under Agent0's shared `.claude/hooks|rules|tools/`.

## Non-goals

- **Vendoring OD's 12 `craft/` files** — rewrite only the compact P0 anti-slop list under Agent0 ownership; do not import the guidance prose (would become a second frozen design-doctrine corpus; against "ship mechanisms, not frozen templates").
- **A harness-wide HTML/CSS validator** — the check is `/product`-internal; it must NOT run against arbitrary repo HTML/CSS (would flag fixtures, prototypes, and apps where indigo/purple is legitimate). If ever promoted, an explicit opt-in `visual-craft-advisory` gated on a manifest signal or a product-generated artifact path — never the default lint-validator.
- **Cloning OD's `od.craft.requires` frontmatter / selective-injection framework** — defer until multiple subskills demonstrably need it (rule-of-three).
- **The other 11 craft files** (typography, color, accessibility, state-coverage, …) — out of scope; this spec is the anti-slop floor only. They are backlog, evaluated on demand.
- **Re-deciding the OD vendor posture** — the meeting affirmed keeping `design-systems/` as a curated asset + the small consumed files; that is settled, not this spec.

## Open questions

_All resolved with Codex (2026-06-03, `codex-exec` convergence — recorded in `notes.md`)._

- [x] **Implementation surface → standalone `scripts/craft-floor-check.ts`** (bun/TS, sibling to `sync-open-design.ts`), JSON findings the judge consumes. Preserves the Layer-1-vs-judge boundary; mechanical detection is testable in isolation.
- [x] **Rule triage → ship 5 deterministic, downgrade 2 to judge-only.** Deterministic: `default-indigo-accent`, `trust-gradient`, `emoji-feature-icon`, `filler-copy`, `sans-display-when-serif-bound`. Judge-only guidance (too noisy for regex): `rounded-card-colored-left-border`, `invented-metrics`.
- [x] **Judge-units → `02-prototype` + `15b-hifi-mood` only** (not `15a-screen-atlas` — contract/inventory artifact, not authored aesthetics).
- [x] **Brand exception → parse the bound `DESIGN.md` for exact hex + CSS custom-props** (`--accent`/`--primary`/`--secondary`/`--brand-*`) and the heading/display font; suppress a color finding when the flagged literal exactly matches a declared token or the artifact uses a declared `var(...)`; run `sans-display-when-serif-bound` only when a serif display font is bound. The check takes the `DESIGN.md` path as input.
- [x] **Output → JSON** `{version, unit, files, design_system:{declared_colors, serif_display_bound}, summary:{active_p0, suppressed}, findings:[{id, severity, file, line, snippet}], suppressed:[{id, file, reason}]}`. Orchestrator runs it before the judge for the two units, stores the report in run state, includes it in the judge brief; judge sets `craft-floor` = `fail` iff `active_p0 > 0`.

## Context / references

- `.agent0/meetings/open-design-overengineering-for-agent0-2026-06-03T16-24-35Z/meeting.md` — the deliberation that produced this (synthesis: graduate; scope (b)+slice-of-(c); red lines).
- OD source (curated content + OSS runtime, no proprietary tech): `github.com/nexu-io/open-design` `craft/` (esp. `anti-ai-slop.md`), `apps/daemon/src/lint-artifact.ts` (the deterministic-check reference).
- `.claude/skills/product/references/{quality-judge.md,quality-checklist.md}` — existing judge surface the `craft-floor` dimension extends.
- `.claude/skills/product/templates/pipeline/{02-prototype,15b-*}/` — the visual steps that bind design-systems + inject briefs.
- `.agent0/context/rules/lint-validator.md` — the validator pattern the deterministic check echoes (but stays `/product`-internal, NOT harness-wide).
- `docs/specs/145-od-vendor-skills-bundles-fate/` — the prior OD-prune that surfaced craft as the layer worth keeping.
- `[[feedback_mcp_package_self_contained]]`, `[[feedback_no_shipped_stack_opinions]]` — placement + ethos constraints.
