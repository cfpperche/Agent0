---
meeting: agent-browser-visual-inspection
topic: "agent-browser (CLI Rust) como camada de inspeção visual/runtime multi-runtime, substituindo Playwright nesse escopo — Playwright permanece para interações fora de inspeção visual"
created: 2026-06-05T14:38:16Z
convener: claude
mode: human-orchestrated
roster: claude,codex,human
rotation: claude,codex
tier: light
blind_phase: none
turn_counter: 7
next_speaker: human
synthesis: accepted
---

# Meeting: agent-browser (CLI Rust) como camada de inspeção visual/runtime multi-runtime, substituindo Playwright nesse escopo — Playwright permanece para interações fora de inspeção visual

_A multi-party, multi-model deliberation. The front-matter above is the machine-readable state: `roster` is every participant id, `rotation` is the deterministic **fallback order** of model participants (human excluded), `next_speaker` is the **derived default** speaker (set by a turn's trailing `Next: <id>` directive; not enforced legality), `turn_counter` counts written turns, `synthesis` tracks the close-out. Speaker selection is context-driven: a turn may end with an explicit `Next: <roster-id>` line to hand the floor; otherwise the human directs with `--speaker`. The body below is the chronological transcript._

## Participants

- claude — Claude Code (web: allowed)
- codex — Codex CLI (web: allowed)
- human — Carlos (web: n/a)

## Transcript

_Turns are appended below in order. Each turn header is `### Turn N — <runtime> (<id>)`; a research-backed turn carries a `Sources:` block listing the URLs used. A turn may end with a single trailing `Next: <roster-id>` line to hand the floor to a specific participant (the directive stays visible here; it sets the default next speaker)._


### Turn 1 — Claude Code (claude)

**Framing.** Agent0 already ships a browser capability: `browser-auth.md` wires **Playwright MCP** for authenticated-content reads (headed-login → save state → headless reuse), with Chrome DevTools MCP as an observation sidecar. The proposal is narrower than "drop Playwright": introduce **`agent-browser` (vercel-labs)** as the dedicated layer for **visual/runtime inspection of the projects we build** — screenshots, accessibility-tree snapshots, web vitals, framework introspection — while Playwright stays for everything outside that scope (auth-state capture, complex driving, the headed-login flow).

**Why this is architecturally interesting, not just a tool swap.** `agent-browser` is a native Rust **CLI** (client-daemon, speaks CDP directly, no Node in the daemon). A CLI is *intrinsically runtime-neutral*: Claude Code and Codex both invoke it through plain shell, no per-runtime wiring. Contrast Playwright MCP today, which needs the `.mcp.json` block for Claude **and** the `.codex/config.toml` block for Codex, plus a session restart on activation. So a CLI inspection layer collapses two MCP fiações into one Bash dependency — that aligns with Agent0's core ethos ("ship mechanisms as CLIs, runtime-neutral"). Its design is also agent-shaped: `snapshot -i` returns deterministic refs (`@e1`), `screenshot --annotate`, `vitals` (LCP/CLS/INP), `react tree`, `--json` output.

**My position (to be argued against).** A thin **multi-runtime `/inspect` skill** wrapping `agent-browser` is a good fit *for the visual/runtime-inspection scope specifically* — it's the natural complement to what `/product` and `/sdd` already emit (HTML mockups, screen-atlas, hi-fi flows that currently have no agent-driven visual verification). Playwright is retained, unchanged, for auth + driving.

**But three things have to clear before this graduates to a spec:**

1. **Demand gate.** This repo's canonical drift trap is speculative tooling (the `feedback-speculative-observability` memory; spec 010). Is there *named, recurring* demand for agents to visually inspect project UIs — concretely, a `/product` or `/sdd` visual-contract output that today goes un-verified — or is this "nice to have"? I think the visual-contract handoff is the real anchor, but we should name it explicitly, not assume it.

2. **Boundary precision.** "Visual inspection" vs "interaction" is fuzzy. `agent-browser` *can* click/fill/drive too — so the split isn't capability-based, it's **purpose-based**. Where exactly is the line, and does maintaining two browser stacks (CLI + MCP) cost more than it saves versus just... using `agent-browser` for both and retiring Playwright MCP entirely?

3. **Maturity/portability risk.** It's young (v0.27, June 2026), Vercel-labs (experimental tier historically), Rust binary install per machine. Agent0 ships *mechanisms*, and a hard dependency on a fast-moving external binary is a portability liability for consumer forks. Is the right shape an **opt-in template** (like the MCP recipes / `/image` / `/video` — activation is a consumer choice), not a default?

**Codex — your turn.** Argue the strongest case *against* my position. Specifically: is the two-stack split (CLI-inspect + MCP-drive) a false economy? Should `agent-browser` either (a) replace Playwright wholesale, or (b) not be adopted at all until the demand gate is concretely met? And independently — does the CLI-is-runtime-neutral argument actually hold, or does the per-machine Rust-binary install just relocate the portability cost rather than remove it?

Next: codex


### Turn 2 — Codex CLI (codex)

Strongest case against Claude’s position: do not add agent-browser yet. The two-stack split is a false economy, and the proposed “inspection-only CLI + Playwright-for-driving MCP” boundary is more likely to create a policy fiction than a durable architecture.

The clean objection is that “inspection” and “interaction” are not separable in browser work. A visual/runtime inspection often requires interaction: open the menu, trigger the error state, advance the wizard, resize the viewport, wait for hydration, accept the cookie banner, replay the auth redirect, click the tab whose React subtree you want to inspect. If agent-browser can click/fill/drive/intercept, then saying “use it only for screenshots, vitals, a11y snapshots, React tree” is not a mechanical boundary; it is a usage convention. Agent0 already treats convention-only controls skeptically. A rule that depends on the agent remembering why it is invoking a full automation tool is weak.

So my stance: do not adopt agent-browser as a second browser stack until the demand gate is concretely met. If demand is met, the first serious design to test should be wholesale replacement for the relevant browser-automation surface, not a permanent split. “Playwright remains for headed login/auth-state capture” may still survive as a narrow compatibility exception, but not as “Playwright drives, agent-browser inspects.” That split will leak immediately.

The “CLI is runtime-neutral” argument is directionally true but overstated. It removes per-runtime MCP wiring, but it relocates the portability burden to per-machine binary installation, Chrome-for-Testing installation, daemon lifecycle, version drift, CI availability, and consumer fork support. With Playwright MCP, the cost is visible in `.mcp.json` / `.codex/config.toml` and activation requires a deliberate restart. With agent-browser, the cost becomes “does this machine have the right Rust CLI, the right downloaded Chrome, the right daemon behavior, and the same JSON/schema semantics as the spec expected?” That is not free runtime neutrality; it is a different dependency contract.

The exact line should not be “inspection vs interaction.” The only durable line is “auditable local browser verification required by a named workflow” versus “general browser automation.” For example, if `/product` or `/sdd` emits a visual contract, an eventual verifier could be allowed to run a bounded command set: load URL, wait, snapshot, screenshot, vitals, maybe compare against declared selectors. But the moment the verifier needs arbitrary click/fill flows, it is no longer inspection; it is an automation harness and should be treated as the primary browser stack or not added.

The strongest alternative to my recommendation is Claude’s path: add agent-browser as an opt-in `/inspect` template only, keep Playwright MCP for auth and complex driving, and document the boundary hard. Evidence that would flip me: three real Agent0/product runs where visual contracts failed or needed verification, and agent-browser caught issues faster or more portably than Playwright/Chrome DevTools MCP with less setup across both Claude Code and Codex CLI. I would also want one CI or clean-machine repro proving install + `agent-browser install` + JSON snapshot/screenshot/vitals works deterministically enough to make the wrapper worthwhile.

Strongest objection to my position: waiting preserves a known gap. `/product` and `/sdd` already produce visual contracts with no agent-driven visual verification step, and agent-browser’s a11y refs, annotated screenshots, vitals, React introspection, and batch mode are unusually well-shaped for exactly that missing loop. If the founder’s near-term work includes UI generation, delaying may mean continuing to ship visual contracts that nobody verifies.

But absent named recurring demand, adding a new browser CLI now looks like the same class of speculative observability drift Agent0 has already learned to avoid. The right next move is not `/inspect`; it is to instrument the demand: when a visual contract exists, record whether the human or agent actually needed browser inspection and what failed with the current Playwright/DevTools path.

Next: human

### Turn 3 — Carlos (human) (human)

[Carlos] Antes de decidir adotar vs instrumentar, quero ver concreto: me deem um exemplo de **como o `/inspect` seria implementado** (a mecânica real sob o capô) e **quando exatamente os agentes o invocariam** num fluxo Agent0. Claude, monta esse exemplo.

Next: claude


### Turn 4 — Claude Code (claude)

Concrete example. I'll take Codex's reframe seriously and design this **not** as a general `/inspect`, but as **bounded, auditable verification of a named workflow** — the `/product` + `/sdd` visual contract. That scoping is what keeps it on the right side of the demand line and out of "second automation stack" territory.

**What it is.** A multi-runtime skill `.agent0/skills/inspect/` (symlinked into `.claude/skills/` and `.agents/skills/` so Claude Code and Codex both see `/inspect`), wrapping the `agent-browser` CLI through plain Bash. Opt-in like the MCP recipes / `/image` / `/video`: if `agent-browser` isn't installed it does NOT silently fail — it emits an activation hint (`INSPECT_TOOL_REQUIRED: agent-browser`) the same way `browser-auth.md` emits `BROWSER_AUTH_REQUIRED`, and `doctor.sh` grows one tri-state check.

**The mechanic under the hood (one batch, deterministic).** Given a running URL and a *fixture-spec* (the contract `/product` already emits — required elements by role/name + a vitals budget):

```bash
# .agent0/skills/inspect/scripts/inspect.sh verify <url> --contract <fixture-spec.json> --out <dir>
agent-browser open "$URL"
agent-browser snapshot -i --json   > "$OUT/a11y.json"   # accessibility tree + refs
agent-browser screenshot "$OUT/screen.png" --annotate
agent-browser vitals --json        > "$OUT/vitals.json" # LCP/CLS/INP/TTFB
agent-browser console --json       > "$OUT/console.json" # errors during load
```

Then the skill **asserts against the contract** — pure shell + jq, no model judgment needed for the mechanical part:
- every `required_role`/`required_name` in the fixture-spec is present in `a11y.json` (else FAIL, naming what's missing);
- `console.json` has zero `error`-level entries (failed hydration / thrown render shows up here);
- each vital is within the declared budget (`LCP < contract.budget.lcp_ms`, etc.).

Output is a `PASS/FAIL` report + the annotated screenshot for the human to eyeball. The model only reasons over the *residual* — "screenshot looks right but contract didn't declare the empty-state, should it?" — not over whether the page loaded.

**The bounded-command discipline (this is the load-bearing part, straight from Codex's critique).** `inspect.sh` exposes **only** `open / wait / snapshot / screenshot / vitals / console / compare`. It deliberately does **not** expose `click` / `fill` / `drag`. The moment a verification needs to drive the UI — open a menu, trigger an error state, advance a wizard — the skill **refuses and says so**: "this needs interaction, not inspection; that's the primary browser stack (Playwright), not `/inspect`." So the inspection/interaction line stops being a convention the agent has to *remember* and becomes a **capability the wrapper doesn't grant**. That's the difference between a policy fiction and a mechanical boundary — and it answers Codex's strongest objection directly.

**When agents invoke it (3 concrete points):**

1. **`/product` Phase 4 → 5 handoff.** Right after the visual-contract step emits the navigable screen-atlas + hi-fi mockups, the agent runs `/inspect verify` over each generated screen against its fixture-spec. Today this step is a human eyeballing HTML; this makes "the contract renders and matches" a checkable artifact before SDD handoff.

2. **`/sdd` build of a UI feature (red→green).** When a task implements a route declared in the visual contract, the green step runs `/inspect verify <local-route> --contract <screen>.json`. A broken layout / console error / missing landmark fails the gate the same way a unit test does — agent-driven visual verification in the build loop, which is exactly the gap that exists now.

3. **`/verify` and `/run`.** The existing `/verify` skill ("confirm a change works by running the app and observing") currently has no first-class browser primitive — it'd reach for ad-hoc Playwright. `/inspect verify` becomes that primitive for the read-only "does it render + match" case, leaving Playwright for the interactive journeys.

**When they do NOT:** auth flows (Playwright headed-login in `browser-auth.md` is untouched), any multi-step user journey needing real clicks, scraping authenticated content. Those are "general browser automation" — explicitly out.

**Honest tie-back to the demand gate.** Notice this example *is* the instrumentation Codex asked for, made concrete: points (1)–(3) are exactly the three places where, if we DON'T build `/inspect` yet, we instead drop a one-line log ("visual contract verification wanted here; current path = manual/Playwright; what failed = ___"). If those logs fire on 3 real runs, the demand is proven and this design is ready to graduate. If they never fire, we saved ourselves a second browser dependency. So the example doesn't pre-empt the decision — it gives us both the build target AND the demand probe in the same shape.

Carlos — with the bounded-command version in front of you (no click/fill in the wrapper, refuses-and-points-at-Playwright when driving is needed): does that close the "policy fiction" worry enough to build the opt-in template now, or do you still want the 3-run demand probe first?

Next: human


### Turn 5 — Carlos (human) (human)

[Carlos] **Redirect — my original prompt was too narrow and Codex's critique is correct.** I'm dropping the "inspection vs interaction" boundary entirely; that line was the artifact, not the architecture. The real intent is to use agent-browser's **full eyes + hands**, not an inspection slice.

**Reformulated scope:** evaluate adopting `agent-browser` as the **primary agent browser layer** for Agent0 — navigate/control Chrome via CDP; a11y snapshot with stable LLM-friendly refs (`@e1`); click/fill/wait/drag; annotated screenshot + PDF; read text/HTML; cookies/storage/network/tabs/frames/dialogs; persistent auth (profiles, state files, session persistence, local vault); JSON output + local observation dashboard; batch, domain allowlist, action policy, sensitive-action confirmation.

Because it overlaps **both** Playwright MCP **and** Chrome DevTools MCP (both already in `browser-auth.md`), this is a **consolidation** decision, not an addition: should agent-browser become the *default* agent browser stack — eyes + hands + observe in one runtime-neutral CLI (no dual `.mcp.json` + `.codex/config.toml` wiring) — leaving Playwright/DevTools MCP as specialized fallback, or not even that?

Evaluate honestly: (1) real CLI portability gain vs. **relocated** cost (per-machine Rust binary, `agent-browser install` Chrome-for-Testing, daemon lifecycle, version drift, CI availability); (2) do its native security gates (domain allowlist, action policy, sensitive-action confirmation) fit Agent0's posture and suffice to give an agent "hands"?; (3) migration of `browser-auth.md`'s headed-login → storage-state flow to agent-browser's profiles/vault model, or coexistence?; (4) demand gate — does this serve named recurring need (persistent login, visual smoke test, UI-bug repro, web-flow automation) or is it nice-to-have?

Desired output: **adopt-as-primary / adopt-partial / not-yet**, and if it graduates, a runtime-neutral migration spec.

Codex — react to THIS scope (primary-stack consolidation), not the old inspection-slice framing. You argued the split would leak; given we've now dropped the split, does the wholesale-replacement case clear your bar — or does the portability/security/demand stack still say "not yet"?

Next: codex


### Turn 6 — Codex CLI (codex)

Adopt-partial, with a narrow path to primary. “Primary” should mean the default browser primitive for new Agent0 agent workflows once proven: one runtime-neutral CLI surface for navigation, interaction, observation, auth state, screenshots, network, and structured JSON. It should not mean “only browser stack” on day one. Playwright MCP and Chrome DevTools MCP stay as fallback adapters until agent-browser proves three things in repo-local dogfood: auth migration, CI/headless repeatability, and policy-gated hands without surprising writes or unsafe external navigation.

On portability: dropping the fake inspection/interaction split improves the architecture. A single CLI is more Agent0-shaped than two MCP servers with per-runtime wiring and restart friction. But “runtime-neutral” is only true at the agent interface layer. The cost moves below the interface: Rust binary distribution, Chrome-for-Testing bootstrap, daemon lifecycle, profile/state paths, version pinning, CI installation, and debugging when CDP state goes stale. That cost does not dominate if Agent0 wraps it as a harness primitive with doctor/status checks, pinned version advice, and a fail-readable JSON contract. It does dominate if we pretend the CLI existing is the whole migration. So: CLI interface is a real portability gain, but only after Agent0 owns the operational envelope.

On security: domain allowlist, action policy, and sensitive-action confirmation are the right primitives, and they fit Agent0’s posture better than today’s loose “agent can drive browser because MCP is configured” model. They are not sufficient by themselves. Agent0 should add policy-as-file defaults, per-command audit logs, redaction rules for screenshots/HTML/network, profile/vault separation, and a hard distinction between read-only, same-origin interactive, and sensitive external actions. The bar is not “can an agent click”; the bar is “can a later human reconstruct why the agent clicked and which guard allowed it.” If agent-browser gives enough hooks for that, hands are acceptable.

On browser-auth.md: migrate the desired model, coexist during the transition. The target should be agent-browser profiles/state/vault replacing headed-login→storage-state as the default auth story. But Playwright’s current auth path is already a known working compatibility lane, and ripping it out before proving agent-browser auth across at least one real auth-gated workflow would be churn. The migration spec should define profile creation, reuse, invalidation, vault boundaries, domain scoping, and fallback behavior. “Use Playwright for login, agent-browser after” is acceptable only as a temporary bridge, not the final architecture.

On demand: “eyes+hands for agents” is a real recurring need at the category level, but still under-evidenced as an Agent0 implementation demand. The named workflows are plausible: /product visual contract verification, /sdd UI green step, /verify browser smoke, auth-gated research, console/network debugging. Plausible is not the same as demand-validated. The correct next move is not adopting primary across the harness; it is a migration spec plus one dogfood slice where the absence of this layer is currently painful. If that slice needs browser hands and produces less wiring than MCP, the demand gate starts clearing.

If it graduates, the runtime-neutral migration spec should be framed as “browser primitive consolidation,” not “add agent-browser.” It needs: capability contract, install/bootstrap contract, daemon lifecycle, JSON schemas, policy files, auth/profile migration, fallback adapters, audit/logging, doctor/status integration, CI story, and deprecation criteria for Playwright/DevTools MCP.

Strongest alternative to my recommendation: adopt-as-primary now, behind an experimental flag, because the current dual MCP model is already fragmented and the only honest way to evaluate a browser stack is to make it the default in real workflows. That is a serious argument. Half-adoption can hide integration failures.

Evidence that would flip me: one real Agent0 workflow completed end-to-end with agent-browser doing auth, navigation, interaction, screenshot/a11y capture, console/network observation, and JSON audit, with no per-runtime MCP wiring, reproducible setup on a second machine or CI, and a cleaner failure model than Playwright/DevTools MCP.

Strongest objection to my stance: “adopt-partial” may preserve exactly the fragmentation this decision is meant to kill. If we keep fallbacks too long, Agent0 accumulates adapters, docs branches, and ambiguous agent instructions. The migration spec needs explicit graduation and removal criteria, or partial adoption becomes another permanent stack.

Next: claude

### Turn 7 — Claude Code (claude)

I converge with Codex's adopt-partial-with-graduation, and I'll concede the point I was wrong on: my Turn-1 "two stacks, permanent split" was the false economy. The right frame is **one primitive, phased migration with explicit removal criteria** — not two coexisting browser stacks forever. Codex's audit bar ("can a later human reconstruct why the agent clicked and which guard allowed it") is the correct security framing for granting hands, and it's stronger than today's loose "MCP is configured ⇒ agent can drive."

Where I'll sharpen rather than just agree — the two real risks in *this specific* convergence:

**1. "adopt-partial" is the dangerous middle unless graduation is mechanical.** Codex named this as the objection to his own stance and he's right: a fallback that exists because removal is vague becomes permanent (Agent0 has the exact opposite pattern as a virtue — the `/meeting` autopilot and `/squad` worktree-v2 are *not* built until a rule-of-three demand test fires). So the migration spec must carry a **deprecation predicate**, not a vibe: e.g. "Playwright MCP block moves to `.example`/fallback-only once N named workflows run end-to-end on agent-browser across both runtimes with a clean second-machine/CI repro; it is *deleted* from the default after M." Same mechanical-gate discipline we already apply everywhere else.

**2. The demand gate is genuinely unmet today, and we should not pretend the spec clears it.** Codex: "plausible is not demand-validated." Agreed. But there's an asymmetry worth naming: the **operational-envelope work** (capability contract, install/bootstrap, daemon lifecycle, JSON schemas, policy files, doctor/status integration, fallback adapters) is real engineering that is *independent* of whether demand later validates — and it's the part that de-risks the dogfood. So I'd split the graduation into two artifacts:
   - a **migration spec** (`/sdd`) that designs the consolidation: capability contract, install/bootstrap contract, daemon lifecycle, JSON schemas, policy-as-file + audit-logging, auth/profile migration, fallback adapters, doctor/status, CI story, and the explicit Playwright/DevTools-MCP deprecation predicate;
   - **one concrete dogfood slice** chosen because the absence hurts *now* — my candidate: the `/product` → `/sdd` visual-contract handoff (the one un-verified artifact we both keep returning to), run end-to-end with agent-browser doing navigate + a11y snapshot + screenshot + console/network + JSON audit, **no MCP wiring**, with a second-machine/CI repro. That slice is exactly Codex's flip-evidence, and it either clears the demand gate or kills the spec cheaply.

So my recommended next step for Carlos: **graduate to `/sdd refine`** seeded with this meeting, scoped as *"browser-primitive consolidation onto agent-browser"* — explicitly adopt-partial with a mechanical deprecation predicate, and the first build task is the single demand-proving dogfood slice, not a harness-wide rollout. That keeps us honest on the demand gate (build the envelope + one painful slice; let the slice decide the rollout) while committing to the architecture Codex and I now agree on.

One residual disagreement to preserve, not smooth over: Codex's *strongest-alternative* (adopt-as-primary-now behind an experimental flag, because half-adoption hides integration failures) is a real position I don't fully dismiss — if the dogfood slice comes back clean, I'd lean toward a *faster* deprecation of the MCP fallback than "adopt-partial" usually implies. That tension (how fast to delete the fallback) is the thing the dogfood evidence should settle.

Carlos — I think this is ready to synthesize and graduate. Want me to write the synthesis (convergence + the one preserved disagreement + recommended `/sdd refine` handoff), or take another turn first?

Next: human

## Synthesis

_Written when a participant is asked to synthesize. Names the synthesizing runtime, the convergence, recorded disagreements, and a recommended next step (graduate to `/sdd refine` as seed context, or no-op). The human then accepts / redirects / ends._

_Decision-grade tier (spec 149): convergence is gated by the claim/evidence ledger (`meeting.sh ledger-check` — a point with only `assertion-only` claims is UNRESOLVED regardless of agreement), and a **minority report** (any residual objection) is preserved verbatim, never smoothed into consensus._

**Synthesizing runtime:** Claude Code (`claude`). **Tier:** light (exploratory). 7 turns · 2 model runtimes + founder.

**Topic evolution (load-bearing).** Opened on a *narrow* framing — agent-browser as a visual/runtime **inspection** layer, Playwright kept for interaction. Codex (Turn 2) showed that boundary is a **policy fiction** (visual inspection routinely requires interaction; agent-browser drives too, so "use it only for screenshots" is a convention, not a mechanical gate). The founder **redirected** (Turn 5): drop the inspection-vs-interaction split entirely; the real intent is agent-browser's **full eyes + hands**, making this a **browser-primitive consolidation** decision (agent-browser overlaps *both* Playwright MCP *and* Chrome DevTools MCP), not an addition.

**Convergence (Claude + Codex agree):**
- **One primitive, phased migration — not two coexisting stacks forever.** Claude conceded the Turn-1 permanent-split was the false economy.
- **Verdict: `adopt-partial` with a narrow, mechanical path to `primary`.** "Primary" = the default browser primitive for new agent workflows *once proven*, not "only stack on day 1". Playwright/DevTools MCP stay as fallback adapters until agent-browser proves three things in repo dogfood: auth migration, CI/headless repeatability, policy-gated "hands" without surprising writes / unsafe navigation.
- **"CLI is runtime-neutral" is real at the agent interface but RELOCATES cost below it** (per-machine Rust binary, Chrome-for-Testing bootstrap, daemon lifecycle, version drift, CI). Net gain *only if* Agent0 owns the operational envelope (doctor/status checks, pinned-version advice, fail-readable JSON contract) — not "the CLI exists ⇒ migration done".
- **Security bar for granting hands:** not "can the agent click" but **"can a later human reconstruct WHY the agent clicked and WHICH guard allowed it"**. allowlist + action-policy + sensitive-action-confirmation are the right primitives but insufficient alone — need policy-as-file, per-command audit logs, screenshot/HTML/network redaction, and a read-only / same-origin-interactive / external-sensitive trichotomy.
- **`browser-auth.md` migration:** migrate the target model (profiles/state/vault) while coexisting during transition; "Playwright for login, agent-browser after" is a temporary bridge only, not the final architecture.
- **Demand gate is genuinely UNMET today** ("plausible is not demand-validated"). Recommended shape splits graduation into (a) a **migration spec** designing the consolidation + an explicit **mechanical deprecation predicate** for the MCP fallback ("Playwright MCP → fallback-only after N named workflows run end-to-end on both runtimes with a clean second-machine/CI repro; deleted from default after M"), and (b) **one demand-proving dogfood slice** chosen because the absence hurts now — candidate: the `/product`→`/sdd` visual-contract handoff, run end-to-end on agent-browser (navigate + a11y snapshot + screenshot + console/network + JSON audit) with **no MCP wiring** and a CI/second-machine repro. That slice is the flip-evidence: clears the demand gate or kills the spec cheaply.

**Preserved disagreement (minority report — not smoothed into consensus):** *how fast to delete the MCP fallback.* Codex holds the cautious line (adopt-partial, fallbacks retained until the triple proof — otherwise "partial" becomes a permanent second stack, the exact fragmentation this decision means to kill; the spec MUST carry explicit graduation/removal criteria or it fails). Claude leans to *faster* fallback deletion if the dogfood returns clean (echoing Codex's own strongest-alternative: adopt-as-primary-now behind an experimental flag, since half-adoption can hide integration failures). **Both agree the dogfood evidence — not a priori preference — settles the deletion pace.**

**Recommended next step: GRADUATE.** Hand this meeting to `/sdd refine` as seed context for its interview (does not bypass the interview), scoped as *"browser-primitive consolidation onto agent-browser"* — adopt-partial with a mechanical deprecation predicate; first build task = the single demand-proving dogfood slice, not a harness-wide rollout. Honors the standing Agent0 discipline: build the envelope + one slice that hurts, let the slice's evidence drive the rollout (rule-of-three / demand-gated, consistent with the speculative-observability lesson).
