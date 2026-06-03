# 146 — product-craft-floor

_Created 2026-06-03._

**Status:** draft

## Intent

Give `/product` a **brand-agnostic quality floor** that mechanically catches the recurring "AI-slop" tells in its emitted visual artifacts — the one genuinely-valuable, non-replaceable-by-a-prompt idea in Open Design's `craft/` axis (established by the 2026-06-03 Claude↔Codex meeting, `.agent0/meetings/open-design-overengineering-for-agent0-2026-06-03T16-24-35Z/meeting.md`). OD's `craft/` is a third layer beside `skills/` (artifact shape) and `design-systems/` (brand language): universal design rules, of which `anti-ai-slop.md` carries a small set of **deterministic, checkable P0 rules** targeting exactly the LLM default-aesthetic failure mode. Today `/product` injects brand (`design-systems/`) + the 5 design "schools" (`directions.ts`) at the visual steps and grades with a quality-judge, but has **no floor that flags slop** — so a run can drift into generic SaaS styling and only a human notices. This spec ports the *mechanism* (a tiny deterministic anti-slop check + a judge dimension), not OD's content: Agent0's ethos is "ship mechanisms, not frozen templates," and the meeting set firm red lines against importing OD's prose corpus or building a harness-wide aesthetic linter.

## Acceptance criteria

- [ ] **Scenario: deterministic anti-slop advisory over `/product` visual artifacts**
  - **Given** a `/product` run that emitted visual artifacts (`docs/direction-a.html`, `docs/screens/**`, `docs/screens/hifi/**`)
  - **When** the craft-floor check runs
  - **Then** it flags the P0 anti-slop tells with file + snippet: default Tailwind indigo accent (`#6366f1` / `#4f46e5` / `#4338ca` / `#3730a3`), a two-stop "trust" hero gradient (purple→blue / blue→cyan), emoji used as feature/section icons (`✨🚀🎯…`) in headings/buttons, the rounded-card-with-colored-left-border "AI dashboard tile", invented metrics ("10× faster", "99.9% uptime") with no source, and lorem / "feature one|two|three" filler — emitting an **advisory by default** (does not hard-block artifact persistence)

- [ ] **Scenario: a legitimate brand exception is not a false positive**
  - **Given** the bound `design-systems/` `DESIGN.md` legitimately specifies a purple/indigo accent (e.g. a brand whose `--accent` is in that range)
  - **When** the check runs
  - **Then** that brand's accent does not fire the indigo-default rule (the rule targets the *un-bound Tailwind default*, not a brand-declared token) — i.e. the check reads the bound design system's tokens before flagging

- [ ] **Scenario: `craft-floor` judge dimension on visual steps only**
  - **Given** the `/product` quality-judge runs on Step 02 (lo-fi mood) and Step 15b (hi-fi mood)
  - **When** it grades
  - **Then** it scores a `craft-floor` dimension against the deterministic findings (it consumes them, does not re-discover them) + any legitimate brand exception; the dimension is **absent** from non-visual steps (PRD, roadmap, system-design, the general right-sizing criterion)

- [ ] **Scenario: P0 may fail Step 15b, never hard-blocks persistence**
  - **Given** Step 15b hi-fi output with an unexempted P0 violation
  - **When** the judge grades
  - **Then** it MAY return a quality `fail` for that step (absent a brand/design-system exemption), but the artifact is still written to disk — the floor gates *quality verdict*, not *persistence*

- [ ] **Scenario: short anti-slop reminder injected only into visual briefs**
  - **Given** the Step 02 and Step 15b briefs
  - **When** they are composed
  - **Then** they carry a short anti-slop reminder; non-visual step briefs are unchanged

- [ ] The P0 rule list is **authored under Agent0 ownership** (rewritten, not vendored from OD's `craft/`), with attribution if any wording is copied; it lives inside the `/product` package (per `[[feedback_mcp_package_self_contained]]`), not under Agent0's shared `.claude/hooks|rules|tools/`.

## Non-goals

- **Vendoring OD's 12 `craft/` files** — rewrite only the compact P0 anti-slop list under Agent0 ownership; do not import the guidance prose (would become a second frozen design-doctrine corpus; against "ship mechanisms, not frozen templates").
- **A harness-wide HTML/CSS validator** — the check is `/product`-internal; it must NOT run against arbitrary repo HTML/CSS (would flag fixtures, prototypes, and apps where indigo/purple is legitimate). If ever promoted, an explicit opt-in `visual-craft-advisory` gated on a manifest signal or a product-generated artifact path — never the default lint-validator.
- **Cloning OD's `od.craft.requires` frontmatter / selective-injection framework** — defer until multiple subskills demonstrably need it (rule-of-three).
- **The other 11 craft files** (typography, color, accessibility, state-coverage, …) — out of scope; this spec is the anti-slop floor only. They are backlog, evaluated on demand.
- **Re-deciding the OD vendor posture** — the meeting affirmed keeping `design-systems/` as a curated asset + the small consumed files; that is settled, not this spec.

## Open questions

- [ ] **Implementation surface:** a `/product`-internal script (e.g. `scripts/craft-floor-check.*`) invoked at the visual steps, vs. folding the checks into the existing quality-judge invocation. Lean: a small standalone deterministic check whose findings the judge consumes (clean separation: mechanical detection vs. graded verdict).
- [ ] **Exact P0 rule set + thresholds** — which of OD's ~7 P0 rules port verbatim-in-spirit, and concrete match patterns (hex lists, gradient detection, emoji ranges, metric regex). To be fixed at `/sdd plan`.
- [ ] **Brand-exception mechanism** — how the check reads the bound `DESIGN.md` tokens to suppress legitimate-brand false positives (parse `--accent` / palette section).

## Context / references

- `.agent0/meetings/open-design-overengineering-for-agent0-2026-06-03T16-24-35Z/meeting.md` — the deliberation that produced this (synthesis: graduate; scope (b)+slice-of-(c); red lines).
- OD source (curated content + OSS runtime, no proprietary tech): `github.com/nexu-io/open-design` `craft/` (esp. `anti-ai-slop.md`), `apps/daemon/src/lint-artifact.ts` (the deterministic-check reference).
- `.claude/skills/product/references/{quality-judge.md,quality-checklist.md}` — existing judge surface the `craft-floor` dimension extends.
- `.claude/skills/product/templates/pipeline/{02-prototype,15b-*}/` — the visual steps that bind design-systems + inject briefs.
- `.agent0/context/rules/lint-validator.md` — the validator pattern the deterministic check echoes (but stays `/product`-internal, NOT harness-wide).
- `docs/specs/145-od-vendor-skills-bundles-fate/` — the prior OD-prune that surfaced craft as the layer worth keeping.
- `[[feedback_mcp_package_self_contained]]`, `[[feedback_no_shipped_stack_opinions]]` — placement + ethos constraints.
