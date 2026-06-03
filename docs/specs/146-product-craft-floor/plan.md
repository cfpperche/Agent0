# 146 — product-craft-floor — plan

_Drafted from `spec.md` on 2026-06-03 (OQs resolved with Codex). Update if implementation reveals the plan is wrong._

## Approach

A small, testable deterministic check + a judge criterion, both inside the `/product` package. `scripts/craft-floor-check.ts` (bun/TS, sibling to `sync-open-design.ts`) takes a `DESIGN.md` path + a list of HTML files, scans for the **5 deterministically-safe** P0 anti-slop tells, suppresses brand-declared exceptions, and emits a JSON report (`findings` + `suppressed` + `summary`). The orchestrator (`SKILL.md`) runs it before the judge for the two authored-visual judge-units (`02-prototype`, `15b-hifi-mood`), stores the report, and includes it in the judge brief; the judge scores a new `craft-floor` criterion (`fail` iff `active_p0>0`) plus the 2 judge-only guidance tells. A short anti-slop reminder is added only to the two visual briefs. The rule list is Agent0-authored (not vendored), with attribution to OD's `craft/anti-ai-slop.md`.

## Files to touch

**Create:**
- `.claude/skills/product/scripts/craft-floor-check.ts` — the deterministic check. Exports pure functions (rule matchers, DESIGN.md token parse, report builder) for unit testing; a CLI entry (`bun scripts/craft-floor-check.ts --design <DESIGN.md> <html...> [--json]`).
- `.claude/skills/product/scripts/craft-floor-check.test.ts` — bun tests over 3 fixture sets (slop / purple-brand / noisy).
- `.claude/skills/product/references/craft-floor.md` — the Agent0-authored P0 rule list (5 deterministic + the 2 judge-only guidance tells), with OD attribution. The judge brief + visual briefs point here.

**Modify:**
- `.claude/skills/product/references/quality-checklist.md` — add a `- **craft-floor** — …` criterion bullet under `### 02 — Prototype …` and under the `15b-hifi-mood` visual-contract rubric; explicitly note it is NOT applied to 15a/15c or steps 01-14.
- `.claude/skills/product/references/quality-judge.md` — document that for judge-units `02-prototype`/`15b-hifi-mood` the orchestrator runs `craft-floor-check.ts` first and passes its JSON into the judge brief; the judge sets `craft-floor` from `summary.active_p0` (does not re-discover).
- `.claude/skills/product/SKILL.md` — in the judge-dispatch orchestration (the "anti-stub pre-filter → dispatch judge" sequence), add: for the two visual units, run the craft-floor check on the unit's HTML artifacts and attach the report to the judge dispatch.
- `.claude/skills/product/templates/pipeline/02-prototype/{prompt.md or references/od-bridge.md}` and the Step 15b hi-fi brief — add a short "anti-slop floor" reminder pointing at `references/craft-floor.md`.

**Rule patterns (the 5 deterministic):**
- `default-indigo-accent` — exact hex set `#6366f1|#4f46e5|#4338ca|#3730a3` (case-insensitive), suppressed if the hex is in the DESIGN.md declared-color set.
- `trust-gradient` — `linear-gradient(...)` whose two stops are both in the purple/blue/cyan families (hex→HSL hue bins), unless both stops are declared tokens.
- `emoji-feature-icon` — emoji (Unicode ranges) inside `<h1-3>`, `<button>`, or `class~="icon|feature"` text nodes.
- `filler-copy` — `/lorem ipsum/i`, `/feature (one|two|three)/i`, `placeholder text`, `sample content`.
- `sans-display-when-serif-bound` — only when DESIGN.md binds a serif display/heading font: flag `h1|h2|h3|.hero*` rules assigning a known sans (or `font-family` lacking the bound serif).

## Alternatives considered

### Fold the checks into the judge sub-agent (no standalone script)
Rejected (Codex + Claude): the judge is an LLM grader; deterministic string/CSS detection belongs in a testable script. Folding it in re-introduces non-determinism and loses the Layer-1-vs-judge separation. The judge consumes findings, doesn't compute them.

### Ship all 7 P0 rules as deterministic
Rejected: `rounded-card-colored-left-border` and `invented-metrics` are false-positive-prone (legit dashboards use left-border cards; metric legitimacy needs semantic context). They downgrade to judge-only guidance prose.

### Apply craft-floor to 15a-screen-atlas too (it's HTML)
Rejected (Codex): 15a is a contract/inventory artifact; its doc-shell styling shouldn't be graded for authored aesthetics. Only 02 + 15b are authored visual direction.

### Harness-wide validator
Rejected (spec Non-goal): would flag fixtures/prototypes/legit-purple apps. `/product`-internal only.

## Risks and unknowns

- **Gradient hue-family detection** is the trickiest matcher — needs hex→HSL + hue bins for purple(260-290)/blue(210-250)/cyan(170-200). Keep conservative (only flag clear two-stop purple→blue / blue→cyan) to avoid false positives; bias toward under-flagging.
- **DESIGN.md token parse** — DESIGN.md is prose + hex literals scattered in paragraphs, not a strict token block (verified: Linear's hexes are inline in prose). Parse = harvest all `#[0-9a-fA-F]{3,8}` + `--custom-prop: value` + `var(--x)` usages; over-collecting declared colors only makes suppression more lenient (safe direction).
- **Emoji ranges** — use a maintained range set; avoid flagging legit symbol glyphs (→, ✓ in non-icon contexts) — scope to heading/button/feature positions.
- **No HTML parser dependency** — stay regex/string-based over the raw HTML (bun, no deps), consistent with the existing scripts; accept that detection is heuristic, not DOM-perfect (advisory anyway).

## Research / citations

- Codex convergence (2026-06-03, `codex-exec`): rule triage, judge-units, output shape, brand-exception, test shape — recorded in `notes.md`.
- OD `craft/anti-ai-slop.md` (the 7 P0 tells) + `apps/daemon/src/lint-artifact.ts` (deterministic-check reference) — `github.com/nexu-io/open-design`.
- `.claude/skills/product/references/quality-judge.md` (judge mechanics, judge-units), `quality-checklist.md` (criterion shape), `design-systems/linear-app/DESIGN.md` (accent encoding → brand-exception design).
