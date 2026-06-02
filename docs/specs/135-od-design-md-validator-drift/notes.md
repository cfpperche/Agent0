# 135 — od-design-md-validator-drift — notes

_Created 2026-06-01._

_In-flight design memory for this spec — decisions, deviations, tradeoffs, and open questions surfaced **while building** that weren't pre-empted by `spec.md` or `plan.md`. Append-only by convention. See `.agent0/context/rules/spec-driven.md` § The four artifacts for purpose, and `.agent0/context/rules/delegation.md` § The 5-field handoff for how sub-agents integrate._

**Entry shape:** `### YYYY-MM-DD — <author> — <one-line title>` followed by free-prose body. `<author>` is `parent` for the orchestrating agent, or the `subagent_type` (e.g. `general-purpose`, `Explore`) for delegated work.

**Routing rubric:** decision made under ambiguity → §1 Design decisions. Intentional departure from `plan.md` → §2 Deviations. Alternative weighed and chosen mid-flight → §3 Tradeoffs. Question surfaced during build, no answer yet → §4 Open questions. Sections may stay empty; the rubric is a guide, not a quota.

## Design decisions

_Choices made where the spec/plan was ambiguous. The decision itself + why this option over others considered in the moment._

### 2026-06-01 — parent — Consumer audit: nothing depends on the exact H2 heading text

Preflight inventory of every reader of the vendored `design-systems/<name>/DESIGN.md` catalogue (the files `validateDesignMd` gates during `--apply`). Two buckets:

**Machine-parsed** — `generateDsIndex` (`sync-open-design.ts`) is the only structured reader. It extracts exactly:
- `mood` — first blockquote line that is NOT `> category:` (regex `^>\s*category:` is skipped); fallback to the first `# ` title; final fallback to the directory name.
- `palette_summary` — the first 6 unique `#RRGGBB` hex codes found anywhere in the file (`/#[0-9a-fA-F]{6}\b/g`).
It writes `vendor/open-design/.cache/ds-index.json`, consumed downstream by `vendor/open-design/prompts/directions.ts`. **It reads no H2 heading text whatsoever.**

**LLM-read** — step `02-prototype/prompt.md` (line 81) instructs sub-agents to `Read` 1-4 chosen `design-systems/<system>/DESIGN.md` paths whole, as the "compositional source (palette roles, typography rules, component stylings, layout principles)", taking palette tokens "verbatim" (= the hex values). An LLM reading prose is robust to heading renames: `## 2. Color` and `## 2. Color Palette & Roles` both read as the palette section; `## Spacing System` reads as layout. The verbatim tokens are hex values, which are heading-independent.

**Conclusion:** no consumer — machine or LLM — depends on the literal substring `'color palette'` (or any of the other four). The `REQUIRED_H2_SUBSTRINGS` gate enforces a contract nothing reads, and produces false rejections on legitimate, consumable systems.

### 2026-06-01 — parent — Q2 resolved: `wechat` is valid, not malformed → must pass

Fetched `design-systems/wechat/DESIGN.md` @ upstream HEAD `bfcac4e0` via `gh api`. It has `## Color Palette`, `## Typography`, `## Components`, 15 unique hex colors, 8 H2 sections, 302 lines. It simply lacks a heading literally containing "layout" (uses `## Spacing System`) or "visual theme" (uses `## Brand Identity`). It is fully consumable (palette + prose). The validator's "missing H2: layout, visual theme" is a false rejection. **Q2 disposition: `wechat` passes** — it is a different-but-valid section vocabulary, not a defect; no upstream filing needed.

### 2026-06-01 — parent — Q1 + Q3 decision: substance gate derived from consumers, not heading text

Chosen policy (refinement of resolution (a), grounded in the audit rather than "loosen one substring"): **replace the exact-phrase `REQUIRED_H2_SUBSTRINGS` gate with a "consumable substance" gate** whose required surface IS the consumed surface (Q3 source of truth = the consumer contract, documented inline):
- **≥ `MIN_PALETTE_HEX` `#RRGGBB` hex colors** — the one hard machine dependency (`palette_summary`); a reference with no palette is useless to the prototype step.
- **≥ `MIN_H2_SECTIONS` H2 headings of any name** — a structure/corruption tripwire (a truncated tarball file has ~0), name-agnostic so legitimate vocabulary differences (wechat) pass.

Thresholds calibrated well below real systems (claude 9 / flat 9 / wechat 8 sections; wechat 15 hex) so corruption is caught but no legitimate system is rejected. Proposed floor: `MIN_PALETTE_HEX = 3`, `MIN_H2_SECTIONS = 3`.

Rejected alternatives:
- **(b) keep strict / treat upstream as regressed** — the audit shows the strict contract guards nothing real; "regressed" is the wrong diagnosis (wechat is valid). Keeping it would permanently wedge the OD sync.
- **(c) per-system allowlist** — adds a hand-maintained exception list, the same drift-prone pattern in a new shape. The substance gate needs no per-system entries.
- **naive (a) `'color palette' → 'color'`** — fixes only the one substring that happened to fail; the other four would drift next. Codex's point 3.

## Deviations

_Places where implementation intentionally departed from `plan.md`. The departure + the reason it was necessary or better._

### 2026-06-01 — parent — Phase-A atomic-invariant: empirical, not a unit fixture

`spec.md` and `tasks.md` (task 4) called for a Phase-A integration fixture asserting the atomic invariant on a validation failure. Implementing it as a pure unit test requires decoupling `cmdApply` from the network (it `fetch`es the upstream tarball before staging) — i.e. refactoring the two-phase apply mechanism, which `spec.md` § Non-goals explicitly excludes. Instead the invariant is verified **empirically** during the Verification step via a degenerate-perturbation `--apply` (the same method the original 2026-06-01 dogfood used to confirm live-vendor-untouched / manifest-not-updated / staging-preserved). The invariant is also structurally guaranteed: in `cmdApply`, `if (report.schemaFailures.length > 0) throw` precedes the entire Phase B rename loop. Net: intent (invariant verified) satisfied without a refactor the spec ruled out.

## Tradeoffs

_Alternatives weighed during implementation (not at plan time). The chosen path + what was given up + why the tradeoff was worth it._

### 2026-06-01 — parent — `MIN_PALETTE_HEX` recalibrated 3 → 2 (validation caught it)

The plan proposed `MIN_PALETTE_HEX = 3`. The validation `--apply` against upstream HEAD passed 729/731 files but rejected `spacex` and `figma` — both with exactly 2 unique hex. Fetching them showed they are **legitimately monochrome** by design (`spacex`: `#000000` + spectral white `#f0f0fa`, "no color"; `figma`: `#000000` + `#ffffff`, "the design system itself is colorless"). A 3-hex floor false-rejects mono systems. Lowered to 2 — the minimum for fg/bg contrast — which still catches a palette-less/truncated file (0-1 hex) and the structure tripwire catches the rest. Added a monochrome-accept regression test. Cost: a hypothetical 1-color system would pass the palette check on its single color, but a 1-color design system isn't a usable visual reference and would almost certainly trip the structure floor or be obviously degenerate. Worth it — the floor must not reject valid mono systems, which are a common pattern. This is exactly the kind of calibration error a real end-to-end validation exists to surface before shipping.

### 2026-06-01 — parent — Hex-only color detection kept (not broadened to oklch/hsl)

Considered broadening the palette count to `oklch()`/`hsl()`/`rgb()` since step 02's prompt mentions those formats. Rejected: `generateDsIndex.palette_summary` is `#RRGGBB`-only, so the validator must match it — a system expressing colors only as oklch would also yield an empty `palette_summary` and break the index, so the validator failing is the correct coupled early signal. At HEAD, all 731 staged files use hex; none are oklch-only. Documented inline so a future divergence updates both together.

## Open questions

_Questions surfaced during build that the implementer couldn't resolve alone. Owner (who decides) or path to resolution if known. Promote answered questions to `spec.md` § Open questions or as retroactive acceptance scenarios when the spec is updated._

### {{YYYY-MM-DD}} — {{author}} — {{one-line title}}

{{free-prose body — the question, why it surfaced, what's blocked on it, who can decide}}
