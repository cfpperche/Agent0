# 098 — codex-mcp-recipes-parity — debate

_Created 2026-05-27._

**Initiating agent:** Codex CLI
**Reviewing agent:** Claude Code
**Initiated by:** Codex CLI session 2026-05-27

Cross-model review of `spec.md` between two tool-calling CLI agents in separate sessions, each running its own port of `/sdd debate`. Both agents read and write **this file directly**; no copy-paste, no broker.

**Roles:** the agent that scaffolded this file is the `initiating agent` (named above); the other runtime, when first invoked against this file, becomes the `reviewing agent` and fills its identity into the metadata block. Each agent's port determines its role on every invocation by comparing the `**Initiating agent:**` metadata to its own runtime-identity literal.

**Orchestration:** the human alternates which runtime is active and decides when the debate ends. Each agent's turn: read this file, find the next empty placeholder belonging to its role (`initiating agent (position)` / `initiating agent (counter)` for the initiator; `reviewing agent (critique)` for the reviewer), write it, save. Then the human invokes the other runtime.

**Stop criteria:** human-decided. Default suggested cadence is ~3 rounds; the human asks either agent to "synthesize" when the disagreement is exhausted or the value diminishes. If more than 3 rounds are useful, append `## Round 4 — …` headers manually; the round-handling logic in both skills keys on placeholder presence, not round number.

**Audit trail:** this file IS the audit trail. Git-tracked alongside the spec. No separate state file.

---

## Round 1 — initiating agent (position)

**Intent**

Spec 098 should make Agent0's existing MCP recipe capacity truly multi-runtime by adding a Codex-native activation path alongside Claude's `.mcp.json` path. The motivating gap is concrete: Codex CLI supports MCP natively through `codex mcp` and `config.toml`, including project-scoped `.codex/config.toml` in trusted projects, but Agent0 currently tells Codex users to follow `.claude/rules/mcp-recipes.md` manually. The proposed v1 adds a safe Codex template, updates docs and sync propagation, and only then upgrades the runtime capability registry to Codex `native-opt-in`.

**Top 3 acceptance scenarios**

1. **Codex user can activate the same MCP recipe set natively** — a consumer project receives the harness update, trusts the project in Codex, and can enable Playwright, Chrome DevTools, DBHub, Laravel Boost, Next.js DevTools, and fal.ai without translating from Claude `.mcp.json` by hand.
2. **Consumer sync propagates the Codex MCP template safely** — sync-harness copies or updates the Agent0-authored Codex MCP template while preserving any real consumer `.codex/config.toml`.
3. **MCP recipes remain opt-in and secret-safe** — all shipped recipe blocks are disabled or inert by default, contain no literal credentials, and use environment-variable indirection for DBHub and fal.ai.

**Top 3 open questions**

1. Should the Codex template live at `.codex/config.toml.example` or a neutral root path such as `.codex-mcp.toml.example`?
2. Should the template contain disabled real TOML blocks or commented TOML blocks?
3. Should docs prefer `codex mcp add ...` commands or direct TOML snippets?

**Where the initiating agent wants pushback**

- The highest-risk design choice is shipping a top-level `.codex/` directory via sync-harness. It is the honest native Codex shape, but it expands the manifest into a new runtime namespace.
- The second-risk choice is parseable disabled TOML blocks. This is testable and safer than comments, but we need confidence that disabled MCP blocks in a project-scoped Codex config create no startup friction.
- The spec assumes consumer propagation is part of the value, not a later step. Push back if this should stay documentation-only until after dogfooding in Agent0 itself.

---

## Round 1 — reviewing agent (critique)

**Framing**

The motivating gap is real and the v1 shape (template + docs + sync + gated registry upgrade) is the right granularity. The critique below targets six load-bearing assumptions in `spec.md` that I think are weaker than the surface reads.

**1. `.codex/config.toml.example` overclaims the surface**

Open Question 1's default ("closest to Codex's project-scoped config path") is true *for MCP-only consumers* but quietly assumes Agent0 wants to own the entire Codex project-scoped config namespace. A real `.codex/config.toml` carries `model`, `provider`, `approval_policy`, `mcp_servers.*`, sandbox/identity, and tool allowlists — far more than MCP. If we ship `.codex/config.toml.example` containing only `mcp_servers.*`, the file's name implies "this is your Codex project config" while the contents cover ~10% of it. Two failure modes follow:

- A user `cp`s the example to `.codex/config.toml` and is now committed to a TOML file they'll grow (model, approval, etc.); subsequent Agent0 syncs of `.example` no longer match what they expanded into.
- A future Agent0 feature wants to ship a `model` or `approval_policy` default — there is now path ambiguity between "Agent0 ships the whole `.codex/config.toml.example`" and "Agent0 ships only its MCP block." Spec 098 should declare this scope explicitly.

Suggested resolution path: either (a) rename to `.codex/mcp.toml.example` (sub-namespace, scope-honest) if Codex's parser supports a partial-config include — needs verification — or (b) keep `.codex/config.toml.example` but **add a non-goal**: "Agent0 does not ship non-MCP Codex config (model, approval, providers); the example carries `mcp_servers.*` only." Otherwise the spec is silently claiming a much larger surface than it intends.

**2. Sync-harness namespace expansion is under-discussed**

The current manifest is anchored to `.claude/` plus a curated list of top-level files (`AGENTS.md`, `.mcp.json.example`, `.gitleaks.toml`, `.githooks/pre-commit`). `.codex/config.toml.example` opens a new top-level hidden directory in the sync surface and sets precedent: when Cursor, Aider, or Hermes Agent rows are added to `runtime-capabilities.md`, do we ship `.cursor/`, `.aider/`, `.hermes/`? The spec treats this as a one-line manifest edit; it's actually a **runtime-namespace policy decision** that affects every future runtime. Open Question 4 names this risk but defaults to "expand explicitly" without addressing the precedent. Two things would tighten this:

- An AC stating "the manifest entry for `.codex/config.toml.example` is the single point of extension; any other `.codex/*` path is out-of-scope and would require a follow-up spec" — mirrors the discipline `harness-sync.md § Manifest scope` already encodes.
- An open question (or non-goal) on whether the directory + `.gitkeep` ship at all to consumer projects that have not opted into Codex. Currently every consumer project receiving this sync gets a `.codex/` directory whether or not Codex is used — pure noise for Claude-only consumer projects. Compare `.mcp.json.example` at repo root: lighter footprint, no top-level dir.

**3. "Disabled real TOML blocks" is asserted without verification**

Open Question 2's default — "disabled real TOML blocks because parseable templates are easier to validate" — needs evidence Codex actually supports such a shape. Concrete failure modes:

- TOML has no native "disabled block" concept. The likely candidates are `enabled = false` per-server (does Codex honor this?), or namespacing under `[disabled.mcp_servers.<id>]` (almost certainly NOT what Codex's loader expects). Without a documented disable flag, "disabled real TOML" is a fiction.
- Codex's `config.toml` is parsed at session start. A `[mcp_servers.dbhub]` block with `command = "npx"` + `args = ["@bytebase/dbhub@latest"]` + a deliberately invalid placeholder URL **may attempt to spawn** at session start, fail, and emit startup-noise on every Codex launch in the consumer project, even though the user never activated dbhub.

TOML supports `#` comments natively (unlike JSON, where `.mcp.json.example` uses the same workaround we already accept). The **consistent** activation shape is "cp + uncomment + restart" across both runtimes. Commented TOML keeps parity with the Claude flow that users already know; "disabled real TOML" is novel discipline carrying unverified Codex-loader assumptions. I'd flip the default.

**4. `codex mcp add` is treated as auxiliary; that may be inverted**

Open Question 3 defaults to "provide both, template is canonical." `codex mcp add` is the native ergonomic surface (analog of `claude mcp add` already shown in `mcp-recipes.md` § Laravel Boost MCP, § fal.ai MCP). The template's main value is **reproducibility across a team via the repo**; `codex mcp add` writes to a specific scope (user-global or project-scoped — the spec doesn't pin this) and is per-developer. Two refinements:

- Spec should pin which **scope** `codex mcp add` writes to and whether that scope is propagatable. If it writes to `~/.codex/config.toml`, it does NOT propagate; the template is then the genuinely canonical path. If it can write to `.codex/config.toml` project-scoped, `codex mcp add` becomes a writeable shortcut to the same file the template seeds.
- Either way, AC 4 ("docs make Claude and Codex activation paths symmetrical but honest") should say *which command* and *which file path* per recipe. Currently AC 4 names the surfaces (`config.toml` and/or `codex mcp add`) but does not require per-recipe documentation of both — a Codex user reading the Playwright recipe today won't know which is recommended.

**5. Consumer-project protection — gaps**

AC 2 covers byte-preservation of an existing real `.codex/config.toml`, and the spec adds a `.gitignore` line for it. Two scenarios are not addressed:

- **Pre-existing tracked `.codex/config.toml`**: a consumer project that *already* committed `.codex/config.toml` before this spec lands is not retroactively untracked by the new `.gitignore` entry. Sync won't touch it (good), but the secret-leak risk if they've committed a real `FAL_KEY` or `DATABASE_URL` in there is not surfaced. Either add a secrets-scan-style advisory ("if `.codex/config.toml` is tracked AND contains a credential, warn") or explicitly call this out as a non-goal with mitigation pointer.
- **The duplicate-ID failure mode**: a Codex user who already has `[mcp_servers.playwright]` in `~/.codex/config.toml` and copies our template to `.codex/config.toml` now has two definitions. Codex's behavior on duplicates is undefined in the spec. Worth either an AC ("template documents the duplicate-resolution behavior") or a Gotcha-equivalent prose line.

For secrets specifically: AC 3 says "fal.ai uses Codex's bearer-token environment variable mechanism." Pin the exact TOML shape. Codex MCP env-var indirection is `env = { FAL_KEY = "$FAL_KEY" }` (or whatever the actual grammar is — the spec doesn't say). Lock this to a concrete syntax so the template review at implementation time has a contract.

**6. Capability matrix upgrade — under-conditioned**

AC 5 currently lists: documentation + template + sync validation → upgrade to `native-opt-in`. The matrix file itself encodes a stricter policy (`runtime-capabilities.md § Future runtimes`): *"Do not add support claims for a runtime until a spec dogfoods or verifies that runtime's actual behavior."* MCP recipes is an existing row, not a new column, but the discipline applies to the upgrade: **none of the ACs require a real Codex session activating at least one recipe end-to-end**. The closest is AC 1 (scenario form), but it's a contract scenario, not a verification step. Add an AC: "at least one MCP recipe (suggested: Playwright, since it has the lowest activation cost) has been verified end-to-end in a real Codex CLI session against a consumer project, with the result captured in `notes.md`." Without this, the `native-opt-in` upgrade rests on docs reads, not behavior.

**7. Acceptance / non-goal / open-question gaps**

Concrete additions worth considering:

- **AC missing**: documentation hand-off. The current `mcp-recipes-hint.sh` is Claude-only (`SessionStart`); Codex sessions never see the recipe nudge. Open Question 5 defers Codex-side runtime hints, which is fine, but then **AGENTS.md** should carry a static line directing Codex users at the recipe docs and the template path. This isn't an AC anywhere; it falls into the "managed MCP section" of AC 7 by implication, but the implication is too soft.
- **Non-goal missing**: HTTP-transport parity for Codex. The fal.ai recipe uses HTTP (`type: "http"`) — the only HTTP recipe in `.mcp.json.example`. Codex's `mcp_servers.<id>` TOML shape for HTTP transport may differ from stdio (different keys, different auth header injection). If Codex supports HTTP MCPs cleanly, AC 1 holds; if not, fal.ai is silently excluded from the Codex parity claim. Spec should pin or non-goal this.
- **Non-goal missing**: this spec promotes ONLY the MCP recipes row. Lifecycle hooks, delegation, runtime introspect, and image-gen rows in `runtime-capabilities.md` remain `unsupported`/`convention`/`read-only` for Codex. Worth saying explicitly to prevent scope creep during review.
- **Open question worth adding**: should the template include the same per-recipe security prose that the Claude `.mcp.json.example` carries inline (header block + per-block notes)? Symmetry argument: yes. Surface cost: TOML comments are heavier than JSON's `//` workaround. Worth a decision before implementation.
- **Open question worth adding**: trust posture. Codex's project-scoped `.codex/config.toml` only loads in **trusted projects**. AC 1 references "trusts the project in Codex" as a Given, but `mcp-recipes.md` for Claude has no trust-prompt; this asymmetry deserves a documented note (in `mcp-recipes.md` or `harness-sync.md`) so consumer-project operators know the activation friction differs.

**Where I'm aligned with the spec**

- The v1 scope (port the existing curated set, no new recipes) is correct discipline.
- The non-goal on auto-installation is the right contract — keep activation explicit on both runtimes.
- Gating the capability-matrix upgrade behind propagation + safety is the right ordering. The only question is whether the gate's bar (AC 5) is strong enough — see point 6.
- Keeping `.mcp.json.example` untouched is correct; this is parity, not replacement.

**Summary of asks**

Tighten ACs 1, 3, 4, 5, and 7; add 2 ACs (dogfood verification; AGENTS.md Codex-pointer line); add 2-3 non-goals (HTTP-transport parity scope, non-MCP Codex config out of scope, other runtime-capability rows unchanged); add 2 open questions (trust-prompt asymmetry, in-template security prose); flip Open Question 2's default to commented TOML unless Codex's loader behavior on disabled-but-parsed blocks is verified before lock-in; restructure Open Question 1 to pick between `.codex/config.toml.example` (with explicit scope non-goal) or `.codex/mcp.toml.example` (if partial-config supported).

---

## Round 2 — initiating agent (counter)

_The initiating agent addresses each critique point: accept (will change spec) / reject (with reasoning) / defer (open question)._

**1. `.codex/config.toml.example` overclaims the surface — accept.**

The critique is right that the filename can imply "Agent0 owns the whole Codex project config" while the intended surface is only `mcp_servers.*`. The synthesis should add a non-goal: Agent0 does not ship or recommend non-MCP Codex project config such as model, provider, approval policy, sandbox, or permissions defaults. The template path can still be `.codex/config.toml.example` because Codex's project-scoped config is the native load path, but the docs and header must say "MCP-only fragment/template" clearly. If partial config includes are not supported, `.codex/mcp.toml.example` is less useful because users still have to merge it manually into real config.

**2. Sync-harness namespace expansion is under-discussed — accept.**

This must be treated as a runtime-namespace policy decision, not a trivial manifest edit. Add an AC that `.codex/config.toml.example` is the only `.codex/*` path this spec may add to the sync manifest; any further `.codex/*` file requires a follow-up spec. Also add harness-sync documentation that real `.codex/config.toml` remains consumer-local and invisible to sync. I accept the consumer-noise concern for Claude-only projects, but still think consumer propagation is part of the value: a static template with all servers disabled/inert is comparable to `.mcp.json.example`, just under Codex's native namespace.

**3. "Disabled real TOML blocks" asserted without verification — accept with correction.**

The risk is valid, but one technical premise needs correction: Codex config docs do define per-server `enabled` as an optional field where `false` disables the server. So "disabled real TOML" is not fiction if the template uses `enabled = false` inside each `[mcp_servers.<id>]` table. Still, the critique is right that the spec must verify loader behavior instead of assuming it. Add an AC requiring the template to parse under Codex and a real Codex startup/prompt-input check to show disabled servers do not spawn, fail, or emit startup noise. If that dogfood fails, synthesis should flip the implementation default to commented TOML blocks. Until then, I would not preemptively flip the default away from parseable TOML.

**4. `codex mcp add` positioning may be inverted — accept.**

The docs should treat `codex mcp add` as first-class operator UX, while the template remains the propagated/team-reviewable artifact. The spec should pin the scope question: if `codex mcp add` writes only user-global config by default, then it is convenience, not propagation. If it can target project-scoped `.codex/config.toml`, document the exact invocation. AC 4 should require each recipe to show both the TOML block and the corresponding CLI command where the command is supported by Codex.

**5. Consumer protection gaps — accept.**

Add two protections. First, document the pre-existing tracked `.codex/config.toml` case: sync will not touch it and `.gitignore` will not untrack it, so the mitigation is an audit/gotcha line plus a secret-scan validation if feasible. Second, document duplicate MCP IDs across user-global and project-scoped config: the template header should warn users to run `codex mcp list` / inspect active config before copying a server block with the same ID. For concrete secret syntax, synthesis should require exact Codex TOML shapes: stdio DBHub should forward `DATABASE_URL` through `env_vars = ["DATABASE_URL"]` or the verified equivalent, and fal.ai HTTP should use `bearer_token_env_var = "FAL_KEY"`, not static `http_headers`.

**6. Capability matrix upgrade under-conditioned — accept.**

The registry should not move Codex from `convention` to `native-opt-in` on docs alone. Add an AC requiring at least one real Codex CLI dogfood against a consumer-style project before the matrix upgrade lands. Playwright is the right default candidate because it has no credential requirement and exercises stdio MCP. If fal.ai HTTP support is in scope for the parity claim, there should also be a lightweight config-shape validation for HTTP/bearer-token support, even if no paid generation call runs.

**7. Acceptance / non-goal / open-question gaps — accept.**

Add the AGENTS.md static pointer as an explicit AC: because Codex does not get the Claude `SessionStart` MCP hint, `AGENTS.md` must point Codex users to `.claude/rules/mcp-recipes.md` and `.codex/config.toml.example` from the shared MCP section. Add non-goals clarifying that this spec changes only the MCP recipes row and does not promote lifecycle hooks, delegation, runtime introspect, or image generation execution for Codex. HTTP transport should not be a non-goal if fal.ai remains in the six-recipe parity claim; instead, pin the Codex HTTP TOML shape and validate it. Add open questions for trust posture and whether inline TOML comments should mirror the security prose from `.mcp.json.example`.

**Bottom line**

The critique does not change the direction: Codex MCP parity is still the right next port, and consumer propagation should stay in scope. It does raise the bar for calling this `native-opt-in`: the final spec should require exact Codex config syntax, a single-path `.codex/*` manifest policy, real-config preservation, duplicate-ID/tracked-config gotchas, a Codex startup/dogfood check, and an explicit AGENTS.md pointer. The only point I would not accept as written is flipping to commented TOML immediately; `enabled = false` is a real Codex config field, so the right move is to verify it before plan lock rather than discard parseable templates now.

---

## Round 2 — reviewing agent (critique)

**Framing**

Round 2 converges on 6 of 7 points cleanly. The one push-back (point 3) introduces a real correction I want to acknowledge, and the resolution path Codex proposes is actually stronger than my Round 1 ask. A handful of small asks remain before synthesis; none warrants a Round 3.

**1. Filename + MCP-only scope — accepted as resolved, with one anchor ask**

Codex's path (keep `.codex/config.toml.example`, add a non-goal pinning the surface to `mcp_servers.*` only) is the right resolution. The counter's argument against my `.codex/mcp.toml.example` alternative — "less useful because users still have to merge it manually into real config" — is a fair point about partial-config friction that I hadn't weighed.

One small reinforcement: the non-goal alone is necessary but not sufficient — the **template's own header comment** should also lead with "MCP-only fragment" so a user opening the file at clone time sees the scope claim at first read, not buried in a spec they may never load. Without that, the filename's implication still races the spec's non-goal at point-of-use. Treat this as a one-line plan note, not a new AC.

**2. Sync-harness namespace AC — accepted, one structural pin still needed**

The "`.codex/config.toml.example` is the only `.codex/*` path; further additions require a follow-up spec" AC is the right anchor and mirrors `harness-sync.md § Manifest scope` discipline. Accepting.

One unaddressed sub-question: does the sync ship a `.codex/.gitkeep` sentinel (creating the `.codex/` directory in every consumer project at apply time), or does the directory materialize as a side effect of writing `.codex/config.toml.example` only? Compare the existing pattern: `.claude/.browser-state/.gitkeep` is in `COPY_CHECK_FILES`, so the dir always lands. If `.codex/` lands unconditionally, the Claude-only-consumer footprint cost from Round 1 holds at a directory + one file. If it materializes only as a write side-effect, the footprint is one file. Plan should pin this; it's a one-line manifest decision but visible in every consumer-project clone.

**3. `enabled = false` correction — accepted; converged path is stronger than my original ask**

The technical correction is fair: if Codex documents a per-server `enabled` field, "disabled real TOML" is not fiction. My Round 1 "TOML has no disabled concept" framing was wrong about Codex's loader specifically, even if the broader point (TOML has no *native* concept) stands.

Codex's proposed AC structure — verify the template parses + verify disabled servers don't spawn/fail/noise on startup, and fall back to commented TOML if that dogfood fails — is **stronger discipline than my "flip to commented now" ask**. It anchors on Codex's behavior rather than my hedge on it. Accepting.

Two reinforcements before synthesis:

- The fallback contingency ("if dogfood shows disabled blocks emit startup noise → switch to commented TOML") should be an **explicit clause in the dogfood AC**, not just prose in the counter. Otherwise the spec ships with one default and no codified branch for the failed-verification case.
- The verification needs to confirm both `enabled = false` shape and absence of side-effects on disabled servers (no `npx` resolution attempt, no DNS lookup for HTTP servers, no log line per disabled block). The plan should enumerate these probes; "the template parses" alone is too weak.

**4. `codex mcp add` first-class + scope pin — accepted, scope still open**

The "first-class + per-recipe document both TOML block and CLI command" resolution is clean. One thread remains: Codex's counter says "pin the scope question" but doesn't resolve it. Concretely: does `codex mcp add` default to writing user-global `~/.codex/config.toml`, project-scoped `.codex/config.toml`, or does it have a flag? This is a small docs lookup against the Codex CLI reference, but the answer changes whether `codex mcp add` is "ergonomic alternative to copying the template" (project-scoped) or "personal-account convenience that does NOT propagate" (user-global). Should be pinned before plan, not deferred.

**5. Consumer protection — accepted, with one verification ask on TOML shapes**

The two new documentation additions (pre-tracked config gotcha; duplicate-ID across user/project scope warning) cover the gaps I named. Accepting.

The exact TOML shapes Codex named — `env_vars = ["DATABASE_URL"]` for DBHub forwarding, `bearer_token_env_var = "FAL_KEY"` for fal.ai — are sharper than my Round 1 ask and would lock the implementation contract cleanly. **However**: these field names need verification against Codex's actual config-reference docs (the spec already cites `https://developers.openai.com/codex/config-reference`). If they exist there, lock the spec on them. If not — i.e. if I'm reading "Codex's bearer-token environment variable mechanism" from AC 3 as a real documented field name when it's an aspirational synthesis — the plan needs a verification step before AC 3 hardens. One sentence in the spec: "TOML shapes verified against [config-reference URL] before plan finalization."

This is the only point where I'd flag a residual risk: an unverified specific field name is worse than a deliberately vague handwave, because review will assume the spec was double-checked.

**6. Capability matrix upgrade gating — accepted cleanly**

Playwright dogfood + lightweight HTTP/bearer-token config-shape validation for fal.ai is the right wedge. No further ask.

**7. AC/non-goal/OQ gaps — accepted, including the HTTP-transport handling improvement**

Codex's counter on HTTP transport (pin + validate rather than make it a non-goal) is sharper than my original framing. Accept the inversion.

One residual ask on the AGENTS.md pointer AC: it should specify that the pointer lives in the **managed-block region** (per the `CLAUDE.md` ↔ `AGENTS.md` shared-MCP-section discipline in AC 7), not as a free-floating sentence. Otherwise consumer-project sync may flag it as drift later. Trivial to encode in the spec edit; just don't leave it ambiguous.

**Anything still missing**

Three thin gaps remain that I don't think justify a Round 3, but that synthesis should surface as plan-time checkpoints rather than acceptance-criteria additions:

1. The Codex CLI `mcp add` scope question (point 4 above).
2. The TOML shape verification against the Codex config-reference docs (point 5 above).
3. The `.codex/.gitkeep` decision (point 2 above).

All three are mechanical lookups, each ~1-5 min of work. They're better answered in `plan.md` / `notes.md` during implementation than re-debated here.

**Round 3 — not needed**

Six of seven points fully converged. The seventh (`enabled = false` vs commented TOML) converged on a verify-first AC that is stronger than either party's Round 1 position. No active disagreements remain. The residual gaps (scope of `codex mcp add`, TOML field-name verification, `.gitkeep` decision) are implementation specifics, not contract questions.

**Synthesis-readiness**

Ready. Either agent can synthesize when the human asks. The synthesis should land:

- 1 new non-goal: MCP-only scope (no Codex `model`/`provider`/`approval_policy`/sandbox defaults).
- 1 new non-goal: only the MCP recipes row in `runtime-capabilities.md` is promoted; lifecycle hooks, delegation, runtime introspect, image-gen rows stay as currently labeled.
- 1 new AC: `.codex/config.toml.example` is the sole `.codex/*` manifest entry; further `.codex/*` additions require a follow-up spec.
- 1 new AC: Codex CLI dogfood of ≥1 recipe (Playwright recommended) + lightweight HTTP/bearer-token config-shape validation for fal.ai before the capability-matrix upgrade.
- 1 new AC (or AC 5 extension): the template parses under Codex AND disabled servers (`enabled = false`) do not spawn, fail, or emit startup noise; if either probe fails, the implementation defaults to commented TOML blocks.
- 1 new AC: per-recipe docs in `mcp-recipes.md` show both the Codex TOML block and the `codex mcp add` command (where supported), with the user-global vs project-scoped scope pinned.
- 1 new AC: `AGENTS.md` managed-block region carries a static pointer to `.claude/rules/mcp-recipes.md` and `.codex/config.toml.example` for Codex users (who don't get the SessionStart hint).
- 1 new AC: exact Codex TOML secret-indirection shapes pinned and verified against Codex's config-reference docs (DBHub stdio env forwarding; fal.ai HTTP bearer-token env-var indirection).
- AC 2 augmentation: also cover the pre-existing tracked `.codex/config.toml` case (sync does not touch it; `.gitignore` does not retroactively untrack it; gotcha line + secrets-scan pointer).
- 2 new open questions: trust-prompt asymmetry between Claude (no trust prompt) and Codex (trusts project required); whether template carries inline per-recipe security prose mirroring `.mcp.json.example`.
- Open Question 1 resolution: keep `.codex/config.toml.example`, defended by the MCP-only-scope non-goal.
- Open Question 2 resolution: keep `enabled = false` parseable blocks as the default, contingent on dogfood verification; fall back to commented TOML if disabled-server side-effects surface.
- Open Question 4 resolution: expand the manifest to include `.codex/config.toml.example` (only); single-path AC encodes the precedent guard.

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

**Proposed spec changes:**

- **Intent** — keep the direction unchanged, but clarify that the Codex template is MCP-only and that the capability upgrade depends on verified Codex behavior, not documentation alone.
- **Acceptance criteria / Codex activation scenario** — sharpen the scenario so Codex users get both per-recipe TOML snippets and `codex mcp add` commands where supported, with the command's user-global vs project-scoped scope pinned.
- **Acceptance criteria / consumer sync safety** — expand the sync scenario to cover pre-existing tracked `.codex/config.toml`: sync must not touch it, `.gitignore` will not retroactively untrack it, and docs must warn users to audit tracked config for secrets.
- **Acceptance criteria / opt-in and secret safety** — require exact Codex TOML secret-indirection shapes to be verified against the Codex config reference before plan lock: DBHub stdio env forwarding and fal.ai HTTP `bearer_token_env_var = "FAL_KEY"` or the verified equivalent.
- **Acceptance criteria / disabled-template behavior** — add a verification criterion that `.codex/config.toml.example` parses under Codex and that `enabled = false` servers do not spawn, fail, perform DNS/network/package resolution, or emit startup noise; if this probe fails, the implementation must fall back to commented TOML blocks.
- **Acceptance criteria / runtime capability registry** — require at least one real Codex CLI dogfood of an MCP recipe before changing the registry row to Codex `native-opt-in`; Playwright is the recommended stdio dogfood, plus a lightweight fal.ai HTTP/bearer-token config-shape validation.
- **Acceptance criteria / sync manifest scope** — add a single-path precedent guard: `.codex/config.toml.example` is the only `.codex/*` path this spec may add to `sync-harness.sh`; any further `.codex/*` propagation requires a follow-up spec.
- **Acceptance criteria / managed entrypoint pointer** — require the managed MCP section in `AGENTS.md` / `CLAUDE.md` to point Codex users at `.claude/rules/mcp-recipes.md` and `.codex/config.toml.example`, because Codex does not receive the Claude `SessionStart` MCP hint.
- **Acceptance criteria / per-recipe docs** — require each recipe in `.claude/rules/mcp-recipes.md` to document Claude activation, Codex TOML activation, Codex CLI activation where supported, runtime requirements, and recipe-specific security notes.
- **Non-goals** — add an MCP-only Codex config scope non-goal: Agent0 does not ship or recommend Codex `model`, provider, `approval_policy`, sandbox, or permissions defaults in this spec.
- **Non-goals** — add a runtime-capability boundary non-goal: this spec promotes only the MCP recipes row; lifecycle hooks, delegation/subagents, runtime introspect, and image-generation execution remain at their current Codex support levels.
- **Open questions / resolved defaults** — record that `.codex/config.toml.example` remains the default path, defended by the MCP-only scope non-goal and by the lack of a verified partial-config include mechanism.
- **Open questions / resolved defaults** — record that parseable `enabled = false` TOML blocks remain the default only if the disabled-server dogfood is clean; otherwise implementation switches to commented TOML.
- **Open questions / manifest decision** — record that sync-harness expands to `.codex/config.toml.example` only; plan must decide whether a `.codex/.gitkeep` sentinel is necessary or whether the directory materializes only through the example file.
- **Open questions / trust posture** — add a question or doc requirement explaining Codex's trusted-project prerequisite for project-scoped `.codex/config.toml`, since Claude `.mcp.json` has no identical trust-prompt asymmetry.
- **Open questions / inline security prose** — add a question on whether `.codex/config.toml.example` should carry inline per-recipe security comments mirroring `.mcp.json.example`, or keep comments terse and defer details to `.claude/rules/mcp-recipes.md`.
- **Plan-time checkpoints** — carry three mechanical lookups into `plan.md` rather than more debate: `codex mcp add` write scope, exact Codex TOML field names, and whether `.codex/.gitkeep` should ship.

**Unresolved disagreements:** (only if cap-reached or abandoned)

- None. Both agents converged in Round 2. The remaining items are implementation lookups/checkpoints, not unresolved design disagreements.

---

## Applied changes

_Filled after user confirms the synthesis. List the actual edits made to `spec.md` (or "synthesis rejected — no changes applied")._

- `docs/specs/098-codex-mcp-recipes-parity/spec.md` § Intent — clarified that the Codex template is MCP-only and that the `native-opt-in` upgrade depends on verified Codex behavior.
- `docs/specs/098-codex-mcp-recipes-parity/spec.md` § Acceptance criteria — tightened Codex activation, consumer-sync safety, secret-safety, disabled-template side-effect checks, dogfood gating, single `.codex/*` manifest scope, managed-entrypoint pointers, and per-recipe docs.
- `docs/specs/098-codex-mcp-recipes-parity/spec.md` § Non-goals — added MCP-only Codex config scope and the boundary that only the MCP recipes capability row is promoted by this spec.
- `docs/specs/098-codex-mcp-recipes-parity/spec.md` § Open questions — resolved the path, template-shape, `codex mcp add`, sync-manifest, and Codex-static-pointer questions; added trust posture, inline security prose, and `.codex/.gitkeep` as remaining implementation questions.
