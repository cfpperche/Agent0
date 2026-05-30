# 127 — site-content-refactor — debate

_Created 2026-05-30._

**Initiating agent:** Claude Code
**Reviewing agent:** Codex CLI
**Initiated by:** Claude Code session 2026-05-30

Cross-model review of `spec.md` between two tool-calling CLI agents in separate sessions, each running its own port of `/sdd debate`. Both agents read and write **this file directly**; no copy-paste, no broker.

**Roles:** the agent that scaffolded this file is the `initiating agent` (named above); the other runtime, when first invoked against this file, becomes the `reviewing agent` and fills its identity into the metadata block. Each agent's port determines its role on every invocation by comparing the `**Initiating agent:**` metadata to its own runtime-identity literal.

**Orchestration:** the human alternates which runtime is active and decides when the debate ends. Each agent's turn: read this file, find the next empty placeholder belonging to its role (`initiating agent (position)` / `initiating agent (counter)` for the initiator; `reviewing agent (critique)` for the reviewer), write it, save. Then the human invokes the other runtime.

**Stop criteria:** human-decided. Default suggested cadence is ~3 rounds; the human asks either agent to "synthesize" when the disagreement is exhausted or the value diminishes. If more than 3 rounds are useful, append `## Round 4 — …` headers manually; the round-handling logic in both skills keys on placeholder presence, not round number.

**Audit trail:** this file IS the audit trail. Git-tracked alongside the spec. No separate state file.

---

## Round 1 — initiating agent (position)

_Pre-populated from `spec.md` key claims at scaffold time. Structure: intent (1 paragraph) → top 3 acceptance scenarios → top 3 open questions → "where the initiating agent wants pushback"._

**Intent (condensed).** Spec 126 fixed the site's *surface* currency (counts, multi-runtime copy, og:image, redirect) but the content still misrepresents the harness at a deeper level: capacity cards carry `spec NNN` badges + links pointing at **early specs (001/002/003…) long since refactored/superseded**, so a click lands on stale original intent, not current behavior; and the only "learn more" path is raw GitHub markdown — there's **no on-site explanatory surface**. This spec refactors all content to the harness's current multi-runtime reality and adds on-site explanatory pages (per-capacity + a "how the harness works" overview). It's an **IA expansion** (new routes) beyond 126's single-page in-place pass — same stack (Astro 5 + Tailwind 4 + i18n), same OSS-landing-for-developers identity.

**Top 3 acceptance scenarios (most load-bearing):**
1. *No card links to a superseded/early spec as if current* — "learn more" lands on current canonical truth (on-site page or current rule), never an early refactored spec; misleading `spec NNN` badges removed or re-pointed.
2. *On-site explanatory content exists for capacities* — a visitor understands a capacity (what it does, current multi-runtime behavior, how to use it) without reading raw repo markdown.
3. *"How the harness works" overview exists* — explains how hooks ↔ rules ↔ skills ↔ runtimes fit as a system, not just a per-capacity list.

**Top 3 open questions:**
1. *Explanatory-page granularity* — per-capacity (~23 pages × locales) vs grouped-by-theme vs a single rich capabilities page + the overview? Drives effort/IA/maintenance hardest.
2. *Source-of-truth / anti-re-staling* — hand-authored (drifts again) vs build-time derive from repo (CLAUDE.md/rules) vs hybrid + a currency check. How do we not be back here in 6 months — this is the same drift that produced the stale "Eighteen" and the stale badges.
3. *i18n scope for new pages* — full 3-locale parity (heavy) vs en-first with pt/es tracked follow-on (tension with no-untranslated-fallback + no-dropping-locales)?

**Where I (initiating agent) want pushback — least confident here:**
- **Granularity × i18n is the real cost bomb.** ~23 capacities × a per-capacity page × 3 locales = ~69 hand-authored pages that re-stale the moment a rule changes. I suspect grouped-by-theme pages (5–6) + the overview is the right altitude, but I'm not sure — push hard on whether per-capacity depth is actually worth it for an OSS landing's audience, or whether it's doc-bloat that duplicates the rules and guarantees drift. This is the crux.
- **Anti-re-staling is the spec's whole reason to exist.** If we hand-author 23–69 pages, we've just built a bigger version of the exact staleness problem 126 hit. Is a build-time currency check (fail the build if a referenced rule/spec path 404s, or if the capacity list diverges from a manifest) in scope, or scope-creep? Without *some* mechanism, this spec's value decays fast.
- **Should this reuse the repo's own content rather than re-author it?** The rules in `.agent0/context/rules/` and `CLAUDE.md` are the living source. Is the honest move to *render* curated excerpts of those at build time (single source of truth) rather than write parallel prose that diverges? Tension with "no auto-generated docs dump." Where's the line?
- **Does adding multi-page IA conflict with the OSS-landing-is-one-page instinct?** Stress whether explanatory pages belong on the marketing site at all, vs. just linking to a well-structured `/docs` in the repo. I lean on-site (the user asked for it), but argue the counter.

---

## Round 1 — reviewing agent (critique)

_The reviewing agent reads this file, finds this slot empty, writes its critique directly. Should be concrete: name spec sections, quote unclear phrases, point to missing non-goals or weak acceptance scenarios._

Codex CLI critique:

1. **"All page content" is broader than the acceptance contract.**
   `spec.md` says the refactor covers "all page content", but the acceptance criteria mostly cover capacity cards plus new explanatory pages. The current site also has `Hero`, `WhyBuilt`, `QuickStart`, `HowToExtend`, `Faq`, `McpGrid`, header/footer copy, and route/meta surfaces under `site/src/i18n/strings.ts`, `site/src/i18n/capacities.ts`, and `site/src/i18n/mcps.ts`. An implementation could add grouped capacity pages, remove stale spec badges, and still leave old single-page copy like "Register new hooks in .claude/settings.json" or "the agent cannot drift out of" uncorrected for Codex realities. Spec change: enumerate the content surfaces that must be audited/updated, not just "all content" in prose.

2. **The open questions are plan-blocking, but the spec does not make them a gate.**
   Granularity, card-link target, i18n scope, anti-restaling, and spec badges determine the route tree, component model, content schema, and verification strategy. `plan.md` already exists but is still templated, which is fine, but the spec should explicitly say `/sdd plan` is blocked until these OQs are resolved or narrowed to one branch. Otherwise the plan can bake in a random IA shape and treat the debate as decorative.

3. **"Current canonical source" needs a hierarchy, not a vibe.**
   The live `CAPACITIES` model has `ruleDoc` and optional `spec`, but those targets vary: current rules, early specs, `.mcp.json.example`, `AGENTS.md`, and even `.claude/skills/product/SKILL.md`. The acceptance criterion says "on-site explanatory page, or the current rule/doc" but does not define which wins when both exist, whether a skill body counts as a source, or what happens for capacities whose canonical truth is split between `runtime-capabilities.md` and a specific rule. Spec change: define the link hierarchy, e.g. card -> on-site page -> "source on GitHub" links; source links prefer current `.agent0/context/rules/*` or canonical `.agent0/skills/*`, with early historical specs allowed only as "history" links, never as the primary current link.

4. **Anti-restaling is the value proposition, but the verification is still hand-wavy.**
   "Content is anchored to a durable source-of-truth strategy" is not executable. If the chosen approach is hybrid, name the durable artifact and checks now: for example a typed capacity/content manifest with `id`, `slug`, `sourcePaths`, `runtimeStatus`, `localeCoverage`, and `historySpec` fields, plus a build/test script that fails when a source path 404s locally, a card points directly at `docs/specs/00*`, a capacity lacks an explanatory route, or a locale page is missing. I am not insisting on this exact design, but the spec needs a concrete pass/fail mechanism; otherwise this is just a bigger hand-authored stale surface.

5. **The i18n OQ currently conflicts with 126's no-locale-reduction contract.**
   Spec 126 explicitly preserved three locales. Spec 127 lists "en-first with pt/es as tracked follow-on" as an option, but the non-goals say the current i18n approach stays and the acceptance criterion says locale parity is preserved "per the resolved locale-scope question." If en-first is allowed, define exactly what ships: are `/pt/...` and `/es/...` routes absent, hidden from nav, stubbed with no fallback, or tracked as blocking follow-up? My recommendation: full locale route parity for any public route in v1, even if grouped pages reduce the page count. If the user chooses en-first, mark it as an explicit exception to 126, not an implicit loophole.

6. **Runtime accuracy must be per-capacity, not just globally "multi-runtime".**
   The runtime matrix says some capacities are native in Codex, some are native-opt-in, some are convention-only, and debate itself is `planned: 091-sdd-debate-runner` even though human-brokered file debate works. A generic page saying "works on Claude Code and Codex CLI" will become inaccurate fast. Spec change: require each explanatory page/group to state the current Claude/Codex status class using `.agent0/context/rules/runtime-capabilities.md` as the source, and require copy to distinguish enforcement, advisory, read-only, convention, and planned support. This also catches overclaims already visible in current copy, such as phrasing that implies every pipeline piece is enforceable in both runtimes.

7. **The new IA needs route/nav/meta acceptance, not only content acceptance.**
   Adding pages under GitHub Pages base path `/Agent0/` affects localized routes, language switching, internal links, canonical URLs, sitemap-ish discoverability if present, and per-page title/description/OG metadata. The spec only says "new routes" and "`bun run build` succeeds." Add acceptance that every new public route exists for the resolved locale set, has a working language switch equivalent, is linked from the landing flow, preserves the root redirect behavior, and does not strand users on raw GitHub markdown as the first explanatory surface.

8. **"No auto-generated docs dump" needs a sharper boundary.**
   Claude's position is right that reusing the repo's own content may be the honest move, but the spec only bans a "machine-generated reference." Define what can be derived versus what must be curated. A practical boundary: derive identifiers, counts, source links, runtime status, and last-known source paths; hand-author the explanatory prose and examples. That gives us anti-restaling without turning the site into a rendered copy of `.agent0/context/rules/`.

Net: I agree with the direction, but I would not move to implementation until the spec resolves three decisions: grouped-vs-per-capacity IA, full-locale-vs-exception, and the concrete currency check/manifest. The lowest-risk branch looks like grouped-by-theme pages plus a "how it works" overview, full route parity for `en`/`pt`/`es`, and a typed manifest/check that makes stale links and missing locale pages fail verification.

---

## Round 2 — initiating agent (counter)

_The initiating agent addresses each critique point: accept (will change spec) / reject (with reasoning) / defer (open question)._

Excellent critique — it sharpened every soft edge and caught stale copy I missed. I **accept all 8**; nuances on #4 (schema is plan-detail) and #6 (a meta-insight about the matrix itself).

**1. "All page content" broader than the acceptance contract → ACCEPT.** Right, and your examples are real defects: `howToExtend` says "Register new hooks in .claude/settings.json" (Codex registers in `.codex/hooks.json`) and `whyBuilt`'s "the agent cannot drift out of" overclaims enforceability. Spec change: add a **content-surface inventory** to acceptance — every surface in `strings.ts` (hero/whyBuilt/quickStart/howToExtend/faq/mcps/nav/footer/meta) + `capacities.ts` + `mcps.ts` must be audited, not "all content" in prose.

**2. OQs are plan-blocking but not a gate → ACCEPT.** Same fix as 126: add an explicit **Planning gate** — `/sdd plan` is blocked until granularity, i18n scope, and the currency-check mechanism are resolved. The debate is not decorative.

**3. "Current canonical source" needs a hierarchy → ACCEPT.** Spec change: define the link hierarchy — **card → on-site explanatory page → "source on GitHub"**; the source link prefers current `.agent0/context/rules/*` or canonical `.agent0/skills/*`; early specs (`docs/specs/00*`) are allowed **only** as a labeled "history" link, never the primary current target. Capacities whose truth splits (e.g. runtime-capabilities.md + a specific rule) link the rule as primary and the matrix as the runtime-status source.

**4. Anti-restaling verification is hand-wavy → ACCEPT (mechanism), nuance on schema.** This is the spec's reason to exist, so it must be executable. Accept: a **typed content manifest + a build-time currency check** that FAILS when — a `sourcePath` 404s locally, a card targets `docs/specs/00*` as primary, a capacity lacks an explanatory route, or a locale page is missing. Your field list (`id/slug/sourcePaths/runtimeStatus/localeCoverage/historySpec`) is a strong starting point; I'd pin the *checks* (the pass/fail conditions) in the spec and leave the *exact schema* to `plan.md` — but the manifest + check is now an acceptance criterion, not a vibe.

**5. i18n OQ conflicts with 126's no-locale-reduction → ACCEPT.** Right — en-first can't be an implicit loophole. Spec change: default to **full route parity for `en`/`pt`/`es` on any public route in v1** (feasible precisely because grouped pages keep the count low). If the user chooses en-first, it ships as an **explicit, documented exception to 126**, with the pt/es routes tracked as blocking follow-up — not absent/stubbed/silently-falling-back. Final call is the user's at the gate.

**6. Runtime accuracy must be per-capacity → ACCEPT, + a meta-refinement.** Each explanatory page/group states its current Claude/Codex status class sourced from `runtime-capabilities.md`, distinguishing **enforcement / advisory / read-only / convention / planned**. Meta-insight worth baking in: the matrix itself has currency nuance — e.g. it may class cross-model debate as `planned: 091-sdd-debate-runner`, yet **human-brokered file debate works today** (this very artifact proves it; 091 is the *automated runner*, not the capability). So the status copy must distinguish "works now (human-brokered/native)" from "automation planned" — and surfacing that will catch matrix staleness too.

**7. New IA needs route/nav/meta acceptance → ACCEPT.** Spec change: add acceptance that every new public route (a) exists for the resolved locale set, (b) has a working language-switch equivalent, (c) is linked from the landing flow (not orphaned), (d) preserves the root redirect, (e) carries its own title/description/OG. No route may strand the user on raw GitHub markdown as the *first* explanatory surface.

**8. "No auto-generated docs dump" needs a sharper boundary → ACCEPT.** This resolves my OQ4 tension cleanly. The line: **derive** identifiers, counts, source links, runtime status, and source paths (the things that re-stale); **hand-author** the explanatory prose and examples (the things that need judgment). Anti-restaling without turning the site into a rendered mirror of `.agent0/context/rules/`.

**Convergence.** I agree with your net: lowest-risk branch = **grouped-by-theme pages + a "how it works" overview, full `en`/`pt`/`es` parity, and a typed manifest + currency check**. The derive/curate split (#8) + link hierarchy (#3) + per-capacity runtime status (#6) are accepted into the spec outright — no model disagreement there. The only genuine **gate decisions left to the user** are (a) grouped-by-theme vs per-capacity granularity, and (b) full-parity vs en-first-with-exception. I'm ready to synthesize on the next turn; I don't think a Round 3 critique is needed unless you reject one of these mechanics.

---

## Round 2 — reviewing agent (critique)

{{round 2 critique — reviewing agent writes directly, OR leave blank if user opted to synthesize}}

---

## Round 3 — initiating agent (counter)

{{round 3 counter — initiating agent fills if debate continues past round 2}}

---

## Round 3 — reviewing agent (critique)

{{round 3 critique — final reviewing-agent slot in the template; append Round 4+ headers manually if needed}}

---

## Synthesis

_Written when the human explicitly asks an agent to synthesize ("synthesize the debate", "wrap up"). Either agent can perform synthesis — whichever one the human asks. Lists what changes in `spec.md` and why; flags unresolved disagreements._

**Resolution:** converged

_Synthesized by Claude Code (initiating agent). One round each; Codex's critique sharpened every soft edge and I accepted all 8. User resolved the two gate decisions. No unresolved disagreements._

**Resolved gate (to be recorded as a § Resolved decisions block at the top of `spec.md`):**
- **Page granularity:** grouped-by-theme pages (≈5–6: safety gates / spec workflow / validators / runtime & session / skills & tooling) + a "how the harness works" overview. NOT per-capacity.
- **i18n scope:** en-first for the new explanatory routes, with `pt`/`es` as a **tracked, blocking follow-up** — documented as an **explicit, named exception to spec 126's no-locale-reduction contract** (not an implicit loophole; routes are not silently absent/stubbed). The existing landing stays full 3-locale.

**Proposed spec changes:**

- **Add § Resolved decisions** — the gate above + the accepted mechanisms (link hierarchy, derive/curate split, manifest+check, per-capacity runtime status).
- **§ Acceptance — add a content-surface inventory** (Codex #1): every surface in `strings.ts` (hero/whyBuilt/quickStart/howToExtend/faq/mcps/nav/footer/meta), `capacities.ts`, `mcps.ts` must be audited; explicitly fix the caught defects — `howToExtend` "Register new hooks in .claude/settings.json" (Codex uses `.codex/hooks.json`) and `whyBuilt` "the agent cannot drift out of" (enforceability overclaim).
- **§ Acceptance — add Planning gate** (Codex #2): `/sdd plan` blocked until granularity + i18n + currency-check are resolved (now resolved → unblocked).
- **§ Acceptance — define the link hierarchy** (Codex #3): card → on-site explanatory page → "source on GitHub"; source prefers current `.agent0/context/rules/*` or `.agent0/skills/*`; early `docs/specs/00*` only as a labeled "history" link, never primary.
- **§ Acceptance — make anti-restaling executable** (Codex #4): a typed content manifest + a build-time currency check that FAILS when a `sourcePath` 404s, a card targets `docs/specs/00*` as primary, a capacity lacks an explanatory route, or a resolved-locale page is missing. Exact schema → `plan.md`; the pass/fail conditions are pinned in the spec.
- **§ Acceptance + § Non-goals — i18n en-first exception** (Codex #5): documented as an explicit exception to 126; pt/es tracked as blocking follow-up.
- **§ Acceptance — per-capacity runtime status** (Codex #6): each page/group states Claude/Codex status from `runtime-capabilities.md`, distinguishing enforcement / advisory / read-only / convention / planned, AND "works-now (human-brokered/native)" vs "automation-planned" (the debate-vs-091 nuance) — which also surfaces matrix staleness.
- **§ Acceptance — route/nav/meta** (Codex #7): every new public route exists for the resolved locale set, has a language-switch equivalent, is linked from the landing flow, preserves the root redirect, and carries its own title/description/OG.
- **§ Acceptance — derive/curate boundary** (Codex #8): derive ids/counts/source-links/runtime-status/source-paths; hand-author prose/examples. Sharpens the "no auto-generated docs dump" non-goal.
- **§ Open questions — collapse**: granularity + i18n resolved (→ § Resolved decisions); link-target, anti-restaling, and spec-badges folded into acceptance. Section emptied (or left with none).

**Unresolved disagreements:** none. The two gate items (granularity, i18n) were user decisions, now resolved; all 8 critique points accepted.

---

## Applied changes

_Filled after user confirms the synthesis. List the actual edits made to `spec.md` (or "synthesis rejected — no changes applied")._

User answered the two gate decisions; synthesis applied to `spec.md`:

- **Added § Resolved decisions** — granularity (grouped-by-theme + overview), i18n (en-first + tracked exception to 126), link hierarchy, derive/curate boundary, currency mechanism.
- **§ Acceptance rewritten to 8 scenarios + 2 static criteria** — card-link hierarchy, grouped pages + overview, content-surface audit (with the two caught defects named), per-capacity runtime status, anti-restaling currency check (pinned fail conditions), route/nav/meta wiring, build/stack preserved, derive/curate, no business-result claims.
- **§ Non-goals — added** no-per-capacity-pages, pt/es-not-in-v1 (explicit 126 exception), sharpened the no-docs-dump boundary.
- **§ Open questions — collapsed** (all resolved; none block `/sdd plan`).
- **Status** → `in-progress`.
