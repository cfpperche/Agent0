---
meeting: descacoplar-harness-agent0-do-playwright
topic: "Descacoplar totalmente o harness Agent0 da dependência do Playwright (visual contracts + auth-gated reads)"
created: 2026-06-05T17:44:44Z
convener: claude
mode: human-orchestrated
roster: claude,codex,human
rotation: claude,codex
tier: light
blind_phase: none
turn_counter: 2
next_speaker: codex
synthesis: accepted
---

# Meeting: Descacoplar totalmente o harness Agent0 da dependência do Playwright (visual contracts + auth-gated reads)

_A multi-party, multi-model deliberation. The front-matter above is the machine-readable state: `roster` is every participant id, `rotation` is the deterministic **fallback order** of model participants (human excluded), `next_speaker` is the **derived default** speaker (set by a turn's trailing `Next: <id>` directive; not enforced legality), `turn_counter` counts written turns, `synthesis` tracks the close-out. Speaker selection is context-driven: a turn may end with an explicit `Next: <roster-id>` line to hand the floor; otherwise the human directs with `--speaker`. The body below is the chronological transcript._

## Participants

- claude — Claude Code (web: allowed)
- codex — Codex CLI (web: allowed)
- human — Carlos Perche / founder (web: n/a)

## Transcript

_Turns are appended below in order. Each turn header is `### Turn N — <runtime> (<id>)`; a research-backed turn carries a `Sources:` block listing the URLs used. A turn may end with a single trailing `Next: <roster-id>` line to hand the floor to a specific participant (the directive stays visible here; it sets the default next speaker)._


### Turn 1 — Claude Code (claude)

## Framing

Founder intent (2026-06-05): make the Agent0 **harness** depend on `agent-browser` *exclusively* for any browser-driven functionality. Playwright / Chrome DevTools MCP survive **only** as opt-in `.mcp.json.example` / `.codex/config.toml.example` templates (consumer choice) — never as a path the harness routing or any first-party skill *degrades to*. This partially reverses spec 152's "permanent MCP fallback" convergence, deliberately.

This continues spec 152 (browser-primitive-consolidation, currently UNCOMMITTED) and would likely become **spec 153**.

## Scope I found (the thing to validate before we build)

I swept the repo (`grep -rIl -i playwright` + targeted grep over `.agent0/{context/rules,tools,hooks}`, `.claude/skills`). I split hits into three buckets:

**A. Functional harness dependencies on Playwright — MUST decouple (4 surfaces):**

1. **`/product` visual gate — hard-wired to `mcp__playwright__*`.** This is the one the handoff's "next action" did NOT list, and it's the most concrete coupling:
   - `SKILL.md:58` seeds `<out>/.mcp.json` with the Playwright server block.
   - `SKILL.md:151`, `references/quality-checklist.md:133`, `references/sdd-handoff.md:69`, `scripts/serve-hifi.sh`, `templates/report.md.tmpl:77` all screenshot 375/1280px via Playwright MCP + check `scrollWidth>clientWidth`; emit `visual-gate-skipped` if the MCP isn't loaded.
   - → convert to call `agent-browser.sh verify-contract`/`audit`.
2. **`browser-auth.md` — auth-gated reads still LED by Playwright MCP** (headed-login → `context.storageState({path})` via the RCE-equivalent `browser_run_code_unsafe` → headless reuse). Spec 152.2 already built the replacement (`browser-login.sh` + `agent-browser.sh adopt` over CDP, validated end-to-end on real GitHub/X/LinkedIn) but this rule was never converted — it still presents Playwright as primary.
3. **`browser-primitive.md` § Routing** — the `route` → `fallback:{no-binary,...}` lane that degrades to MCP.
4. **`runtime-capabilities.md`** — the `browser auth` matrix row (line ~57) + any browser-primitive row that names MCP as a harness fallback.

**B. Template / example only — STAYS (not a harness dependency):**
- `.mcp.json.example`, `.codex/config.toml.example` (commented Playwright/Chrome-DevTools blocks).
- Tests that assert those templates stay byte-stable: `tests/harness-sync/11-mcp-json-untouched.sh`, `35-codex-config-example-untouched.sh`, `tests/codex-mcp-recipes/*`.
- Incidental "pairs with the playwright block" mentions in `image-gen.md`, `php-laravel-support.md`.

**C. History — DO NOT touch:** specs (011/012/021/066/075/152…), the spec-152 meeting transcript, memory entries.

## The load-bearing decision the build hinges on

After decoupling, what does `route` (and the `/product` gate) do when `agent-browser` is unavailable (`no-binary` / `no-chrome`)?
- **(i) fail-closed** — hard error, "agent-browser or nothing" for first-party visual contracts; OR
- **(ii) skip-advisory** — emit `visual-gate-skipped`-style advisory and continue (never blocks), but with NO MCP fallback path.

I lean (ii) for the `/product` gate (it's already best-effort/non-blocking) and (i) for explicit `verify-contract` invocations (a UI acceptance artifact that silently no-ops is worse than a hard error). But that's exactly what I want challenged.

## Asks for Codex (validate the scope BEFORE we build)

1. **Is bucket A complete?** Independently sweep — did I miss any harness surface that drives or observes a browser through Playwright/Chrome-DevTools MCP (hooks, validators, other skills, `doctor.sh`, the `agent-browser.sh` wrapper itself)?
2. **Is the A-vs-B boundary right?** Anything I put in "template, stays" that is actually a load-bearing harness dependency, or vice-versa?
3. **fail-closed vs skip-advisory** — react to my split (i)/(ii). Is a per-call-site policy coherent, or should it be one uniform rule?
4. **Sequencing** — does this rest on spec 152 being committed first, or can 153 stack on the uncommitted tree?

Next: codex


### Turn 2 — Codex CLI (codex)

Validated against active source, excluding specs/history/runtime-state. Bucket A is basically right, but it should explicitly include the wrapper implementation and test expectations, not only the rule prose:

1. `/product` is a real functional dependency: it seeds an enabled Playwright block into the generated target at `.claude/skills/product/SKILL.md:58`, gates on loaded `mcp__playwright__*` at `.claude/skills/product/SKILL.md:151`, drives Playwright tool names at `.claude/skills/product/SKILL.md:161`, and skips with a Playwright-specific advisory at `.claude/skills/product/SKILL.md:164`. Same surface is echoed in `.claude/skills/product/references/quality-checklist.md:133`, `.claude/skills/product/references/sdd-handoff.md:69`, `.claude/skills/product/templates/report.md.tmpl:77-79`, `.claude/skills/product/scripts/serve-hifi.sh:4-6`, and `.claude/skills/product/references/state-machine.md:113`.

2. Auth-gated reads are still Playwright-led: `.agent0/context/rules/browser-auth.md:11-15` says MCP is the fallback/prereq, `.agent0/context/rules/browser-auth.md:30-32` expects `mcp__playwright__*`, `.agent0/context/rules/browser-auth.md:57-58` tells the human to use headed Playwright + `browser_run_code_unsafe`, `.agent0/context/rules/browser-auth.md:96-107` saves state via Playwright `storageState`, `.agent0/context/rules/browser-auth.md:115-145` documents `--storage-state`/mid-session reuse, and `.agent0/context/rules/browser-auth.md:159-163` still chooses Chrome DevTools MCP for observation. The replacement target already exists: `.agent0/tools/browser-login.sh:1-9` launches the human-owned CDP Chrome, and `.agent0/tools/agent-browser.sh:311-364` implements `adopt`.

3. Routing is not just docs; it is code. `.agent0/context/rules/browser-primitive.md:35-43` documents MCP fallback, but `.agent0/tools/agent-browser.sh:147-162` implements `fallback:override/no-binary/no-chrome`, `.agent0/tools/agent-browser.sh:213-216` tells `run` to use MCP fallback, `.agent0/tools/agent-browser.sh:257-258` and `.agent0/tools/agent-browser.sh:401` refuse verify/audit “on the MCP fallback path.” Tests enforce that old contract at `.agent0/tests/agent-browser/02-route.sh:2-13` and `.agent0/tests/agent-browser/04-audit.sh:26-29`.

4. Capability docs are in A: `.agent0/context/rules/runtime-capabilities.md:56-57` still says browser primitive routes to MCP and browser auth is Playwright headed-login. Also update diagnostic wording: `.agent0/tools/doctor.sh:144` and `.agent0/tools/doctor.sh:152` say absent binary falls back to Playwright/DevTools MCP. Doctor is not a browser driver, but leaving it stale would preserve the old harness contract in the health surface.

I found no additional active hook/tool/validator that drives a browser through MCP. The active-source sweep was over `.agent0/hooks`, `.agent0/tools`, `.agent0/context/rules`, `.claude/skills`, `.agent0/tests`, plus validator-named files; validator search returned no Playwright/DevTools hits. `.agent0/hooks/context-inject.sh:122` only selects `browser-auth` on browser/auth/playwright prompts, so it can stay if `browser-auth.md` becomes agent-browser-native.

A-vs-B boundary: Claude’s boundary is right for templates. `.mcp.json.example:22-28` and `.codex/config.toml.example:23-31` are disabled/commented recipes, and harness-sync tests intentionally preserve those recipes at `.agent0/tests/harness-sync/11-mcp-json-untouched.sh:20-25` and `.agent0/tests/harness-sync/35-codex-config-example-untouched.sh:21-25`. Keep them. Misbucket risk is not the templates; it is `/product` writing a live `<out>/.mcp.json` at `.claude/skills/product/SKILL.md:58`, which is definitely A. Incidental docs like `.agent0/context/rules/image-gen.md:19`, `.agent0/context/rules/image-gen.md:163`, and `.agent0/context/rules/php-laravel-support.md:49` can stay as template/adjacent mentions. I would also clean `.agent0/context/rules/secrets-scan.md:97`: not a dependency, but it currently frames credential state as Playwright-produced only.

Policy: I agree with Claude’s split, with one addition. Explicit browser commands (`agent-browser.sh run`, `verify-contract`, `audit`, auth `adopt` / auth-gated read) should fail closed when agent-browser is unavailable: no MCP fallback, actionable “install/doctor/caps” message, rc 4 where applicable. `/product` Phase 4 should remain skip-advisory because its current contract is explicitly best-effort/non-blocking; the skip reason should become `visual-gate-skipped: agent-browser unavailable ...`, and it must not seed or mention MCP. Strongest objection to this split: it lets a missing agent-browser silently reduce visual evidence in the most founder-facing workflow, which can look like “exclusive dependency” only on paper. Mitigation: the skip must be loud in REPORT, doctor must report browser functionality unavailable without offering MCP, and explicit verification commands must fail.

Sequencing: live repo does not match the transcript’s “152 uncommitted” claim. `git status --short --untracked-files=all` shows only this meeting transcript untracked, and recent log has `f31e6b8 feat(152): agent-browser as primary browser primitive (+ audit, human-in-the-loop auth)` plus `ef6b815 chore(handoff): 152 shipped + real GitHub/X/LinkedIn auth dogfood; next actions`. So spec 153 can start cleanly on current `main`. If someone is operating from the stale uncommitted view, commit 152 first; 153 touches the same files and should not be mixed with the accepted 152 baseline.
## Synthesis

_Written when a participant is asked to synthesize. Names the synthesizing runtime, the convergence, recorded disagreements, and a recommended next step (graduate to `/sdd refine` as seed context, or no-op). The human then accepts / redirects / ends._

_Decision-grade tier (spec 149): convergence is gated by the claim/evidence ledger (`meeting.sh ledger-check` — a point with only `assertion-only` claims is UNRESOLVED regardless of agreement), and a **minority report** (any residual objection) is preserved verbatim, never smoothed into consensus._

**Synthesizing runtime:** Claude Code (claude). **Tier:** light (a scope-validation meeting; the one load-bearing policy call below converged with file-anchored evidence, not bare agreement).

**Purpose served.** This meeting existed to *validate the decouple scope before any build* — the founder's explicit ask. Codex took a read-only sandbox turn and independently swept the repo, so the convergence below is grounded in `file:line` evidence both participants can point to, not mutual assertion.

### Convergence (what both agreed, with anchors)

1. **The decouple-set is 5 surfaces, and the coupling is in CODE — not just rule prose.** Claude's opening listed 4 doc-centric surfaces; Codex's independent sweep confirmed them and *hardened* the scope by anchoring the real load-bearing coupling in executable code + tests:
   - **`/product` visual gate** — seeds a *live* `<out>/.mcp.json` (`SKILL.md:58`) and drives `mcp__playwright__*` (`SKILL.md:151/161/164`, `quality-checklist.md:133`, `sdd-handoff.md:69`, `state-machine.md:113`, `serve-hifi.sh`, `report.md.tmpl:77`). → repoint to `agent-browser.sh verify-contract`/`audit`.
   - **`browser-auth.md`** — still Playwright-led across `:11-15`, `:30-32`, `:57-58`, `:96-107`, `:115-145`, `:159-163`; replacement already exists/validated (`browser-login.sh`, `agent-browser.sh adopt` `:311-364`).
   - **Routing CODE** (the surface Claude under-weighted) — `agent-browser.sh:147-162` (`fallback:override/no-binary/no-chrome`), `:213-216`, `:257-258`, `:401`, plus the **tests that lock the old contract**: `tests/agent-browser/02-route.sh`, `04-audit.sh`. Decoupling rewrites these asserts, not just `browser-primitive.md` § Routing.
   - **`runtime-capabilities.md:56-57`** + **`doctor.sh:144,152`** (health-surface wording that says "absent binary → falls back to MCP").
   - **`secrets-scan.md:97`** cleanup ("Playwright-produced" credential framing) — not a dependency, but stale.
2. **The A-vs-B boundary is correct.** Templates stay: `.mcp.json.example:22-28`, `.codex/config.toml.example:23-31`, and the harness-sync untouched-tests (`11-mcp-json-untouched.sh`, `35-codex-config-example-untouched.sh`) intentionally preserve them. The only misbucket *risk* is `/product` writing a live `<out>/.mcp.json` — and that is correctly in A.
3. **Policy (load-bearing, decided):** explicit browser commands (`run`/`verify-contract`/`audit`/`adopt`) **fail-closed** when agent-browser is unavailable (rc 4, actionable install/doctor/caps message, NO MCP fallback); the **`/product` Phase-4 gate stays skip-advisory** (its contract is already best-effort/non-blocking) but must NOT seed or mention MCP, and the skip reason becomes `visual-gate-skipped: agent-browser unavailable …`. Per-call-site split, not one uniform rule — coherent because the two call-sites have *different existing contracts*.
4. **Sequencing:** 153 starts clean on `main`. Verified live: `git log` shows `f31e6b8 feat(152)` + `ef6b815`, spec 152 `Status: shipped`, working tree clean. The "152 uncommitted" claim in the session handoff was **stale** — corrected this session.

### Minority report / residual objection (preserved, not smoothed)

Codex named the strongest objection to the agreed policy *against its own position*: fail-closed + skip-advisory lets a **missing agent-browser silently reduce visual evidence in the most founder-facing workflow** (`/product`), so "exclusive dependency" can be true on paper while visual coverage quietly degrades. **Agreed mitigation (binds the build):** the skip must be *loud* in REPORT.md; `doctor` must report browser-functionality-unavailable **without offering MCP**; and every explicit verification command must hard-fail rather than no-op. This objection is not resolved by the policy — it is *managed* by the mitigation, and spec 153 must carry it as an acceptance constraint.

### Recommended next step

**Graduate to a spec.** Hand this synthesis to `/sdd refine` as seed context for spec **153 `decouple-harness-from-playwright`** (link this `meeting.md` from the spec's `## Context / references`). The interview should pin: (a) the exact `agent-browser.sh verify-contract`/`audit` call shape `/product` Phase 4 adopts; (b) the rc-4 fail-closed contract + message text for explicit commands; (c) the test rewrites for `02-route.sh`/`04-audit.sh`; (d) the "loud skip" REPORT requirement as an AC.
