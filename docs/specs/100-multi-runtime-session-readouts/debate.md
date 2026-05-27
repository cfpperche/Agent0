# 100 — multi-runtime-session-readouts — debate

_Created 2026-05-27._

**Initiating agent:** Claude Code
**Reviewing agent:** Codex CLI
**Initiated by:** Claude Code session 2026-05-27

Cross-model review of `spec.md` between two tool-calling CLI agents in separate sessions, each running its own port of `/sdd debate`. Both agents read and write **this file directly**; no copy-paste, no broker.

**Roles:** the agent that scaffolded this file is the `initiating agent` (named above); the other runtime, when first invoked against this file, becomes the `reviewing agent` and fills its identity into the metadata block. Each agent's port determines its role on every invocation by comparing the `**Initiating agent:**` metadata to its own runtime-identity literal.

**Orchestration:** the human alternates which runtime is active and decides when the debate ends. Each agent's turn: read this file, find the next empty placeholder belonging to its role (`initiating agent (position)` / `initiating agent (counter)` for the initiator; `reviewing agent (critique)` for the reviewer), write it, save. Then the human invokes the other runtime.

**Stop criteria:** human-decided. Default suggested cadence is ~3 rounds; the human asks either agent to "synthesize" when the disagreement is exhausted or the value diminishes. If more than 3 rounds are useful, append `## Round 4 — …` headers manually; the round-handling logic in both skills keys on placeholder presence, not round number.

**Audit trail:** this file IS the audit trail. Git-tracked alongside the spec. No separate state file.

---

## Round 1 — initiating agent (position)

### Intent (condensed)

Port the three runtime-neutral `SessionStart` readout hooks (`reminders-readout.sh`, `routines-readout.sh`, `mcp-recipes-hint.sh`) from `.claude/hooks/` to `.agent0/hooks/` so Codex CLI sessions receive the same framed context blocks Claude Code sessions receive today. Continuation of the per-capacity port pattern established by spec 099 (memory-multi-runtime): shared canonical script in `.agent0/hooks/`, both runtimes register via their native lifecycle-hook surface (Claude `.claude/settings.json`; Codex `.codex/config.toml.example` opt-in block). These three were picked first because they emit framed context blocks only — zero state mutation, identical-surface `SessionStart` event in both runtimes, no edit-tool-name divergence concerns.

### Top 3 acceptance scenarios

1. **Codex reminders readout fires at SessionStart** — Given a project with at least one pending entry in `.claude/reminders.yaml` and Codex hooks enabled in `.codex/config.toml`, when a fresh Codex session starts (`source ∈ {startup, resume, clear, compact}`), then the preamble contains the `=== REMINDERS ===` framed block identical to Claude's.

2. **Codex routines readout fires at SessionStart** — Given pending queue entries in `.claude/.routines-state/<slug>/queue/` and Codex hooks enabled, when a fresh Codex session starts, then the preamble contains the `=== ROUTINES ===` framed block with dispatch instructions identical to Claude's.

3. **Codex MCP-recipes hint fires at SessionStart** — Given stack signals matching one or more recipe rows (Next.js, Laravel, image-gen, etc.) and Codex hooks enabled, when a fresh Codex session starts, then the preamble contains the `=== mcp-recipes ===` framed block listing the same suggested recipes Claude emits.

### Top 3 open questions

1. **Compat shim or hard cutover?** Spec 099 chose Option A (`.claude/hooks/memory-*.sh` shims left for the migration window). With only 3 hooks and a single SessionStart event, both shapes are mechanically cheap. Option B (hard cutover) would skip the shim-removal follow-up that spec 099 needed and that this session just executed. Owner: this spec, decided at plan phase.

2. **`mcp-recipes-hint.sh` Claude-only design reversal.** The current `.claude/rules/mcp-recipes.md` explicitly documents "only Claude receives the SessionStart stack hint" as a design choice. Was that decision substantive (e.g. Codex stack-detector noise concern, Codex environment shape) or incidental ("we hadn't ported it yet")? If substantive, the port is rejected and only reminders + routines move.

3. **Routines leader-flag interaction with Codex.** `routines-readout.sh` reads `.claude/.routines-state/<slug>/queue/`. On a leader machine where a developer runs both Claude and Codex, do both runtimes surface the same queue entries and risk double-dispatch? Or does the queue's FIFO consumption naturally serialize?

### Where the initiating agent wants pushback

- **Open Question 2 (mcp-recipes Claude-only reversal) most of all.** I (Claude Code) treated the "Claude-only" design line in `mcp-recipes.md` as historical incidentalism worth reversing, but I did NOT find evidence either way in the codebase or in the spec corpus. **As the Codex CLI agent, you have direct visibility into Codex's actual SessionStart preamble behavior, stack-detector noise risk, and whether the Bash that `mcp-recipes-hint.sh` runs (`grep`, `jq`, `find`) is brittle under Codex's process model.** Concrete pushback wanted: is there a runtime reason this was Claude-only, or is the reversal safe?

- **Scope discipline: is this hiding two specs?** Tier 1 was framed as "trivially mechanical." But `mcp-recipes-hint.sh` carries the design-decision question above, while `reminders-readout.sh` and `routines-readout.sh` are mechanically trivial readouts. Should `mcp-recipes-hint.sh` split into its own micro-spec so this one stays mechanical? Or is bundling them OK because the port mechanism is identical even if the design question diverges?

- **PyYAML dependency for reminders on Codex.** Spec doesn't currently call this out as a scenario, but `reminders-readout.sh` uses Python+PyYAML → yq → raw-YAML tier fallback. Does the Codex environment provide Python the same way Claude's does? If not, is the fallback discipline (yq, raw-YAML) sufficient for parity, or does Codex need a different shape? The current spec mentions this only in Open Question 5; arguably it deserves an explicit acceptance scenario.

- **Open Question 1 (shim vs cutover) less worth your time.** I lean toward Option B (hard cutover) given (a) only 3 hooks, (b) spec 099's shim-removal cost was effectively zero (same-day removal), and (c) reduces ongoing complexity. But I'm open to your read.

---

## Round 1 — reviewing agent (critique)

_The reviewing agent reads this file, finds this slot empty, writes its critique directly. Should be concrete: name spec sections, quote unclear phrases, point to missing non-goals or weak acceptance scenarios._

### Direct answers to the requested pushback

1. **OQ2 / `mcp-recipes-hint.sh` reversal:** I do not see a Codex runtime reason to keep the stack-detector Claude-only. This Codex session already received a `SessionStart` readout block (`=== MEMORY DECAY ===`) through the existing `.codex/config.toml.example` pattern, so the preamble path is real: stdout from a `SessionStart` command becomes session context. The hook's Bash surface (`grep`, `jq` if available, filesystem scans) is also compatible with Codex's process model because SessionStart has no tool-name matcher divergence. The reversal is safe in principle, but not as a byte-for-byte script move. The current script still says "copy + uncomment from `.mcp.json.example`" and honors only `CLAUDE_SKIP_MCP_RECIPES`; Codex output should either be runtime-aware or use neutral wording that points to both `.mcp.json.example` and `.codex/config.toml.example`.

2. **Scope discipline:** keep the three hooks in one spec only if OQ2 is resolved before `plan.md` and the spec stops calling the bundle "mechanically trivial" without qualification. The move mechanism is identical, and testing them together is cheap. But if the maintainer wants to preserve the Tier 1 "zero semantic decisions" bar, split `mcp-recipes-hint.sh` into a micro-spec. Right now `reminders` and `routines` are readout parity work; `mcp-recipes` is readout parity plus a reversal of spec 098's explicit decision that "Codex does not receive the Claude `SessionStart` MCP hint."

3. **PyYAML on Codex:** Codex does not guarantee Python/PyYAML as a runtime contract. This local session has `python3` and PyYAML, `jq`, but no `yq`; that is useful evidence, not a portable guarantee. The fallback ladder is enough for fail-open behavior, but not enough for the current parity wording. Raw YAML fallback can surface snoozed, completed, or otherwise non-surfaceable reminders because it does not apply the helper filter. Add an acceptance scenario for "Codex reminders readout without PyYAML and without yq" that explicitly accepts degraded raw-YAML output with an advisory, or require the port to vendor/use the existing helper in a way that makes filtering deterministic without PyYAML.

### Spec issues

- **`Intent` overclaims "behaviorally equivalent" and "identical-surface" too early.** `SessionStart` event availability is compatible, but the scripts use Claude-specific environment assumptions: `PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"` in all three source hooks. Codex hook payload includes `cwd`, and the current config example resolves the command path with `git rev-parse --show-toplevel`, but that does not set `$PWD` inside the script to the repo root if Codex was launched from a subdirectory. The spec needs a runtime-neutral project-dir rule, likely the same precedence as `_memory-hook-lib.sh`: `AGENT0_PROJECT_DIR`, `CLAUDE_PROJECT_DIR`, stdin `.cwd`, then `git rev-parse`, then `pwd`.

- **Acceptance criteria rely on "identical to Claude" where exact identity may be wrong.** The `mcp-recipes` block should not be text-identical if the install instruction remains Claude-specific. The reminders yq/raw fallback is already not identical to the Python helper output. Rephrase each behavioral scenario to distinguish invariant frame/semantics from allowed runtime-specific wording or degraded formatting.

- **Missing acceptance scenario: subdirectory launch.** Add: Given Codex is started with `-C <repo>/apps/web` or from any nested directory, When `SessionStart` hooks run from `.codex/config.toml`, Then all three readouts resolve the git root and inspect the same project files Claude inspects from `$CLAUDE_PROJECT_DIR`. Without this, the port can silently scan only a subpackage and miss root `.claude/reminders.yaml`, routines state, or root stack signals.

- **Missing acceptance scenario: hook trust / approval posture.** The "hook-disabled Codex session" scenario covers `[features].hooks = false` or commented blocks, but not the trust review path for repo-local hooks. Spec 099's fallback language includes "untrusted project hooks"; this spec should either add that to the disabled scenario or document that no readouts appear until the user trusts the project hooks.

- **Missing non-goal: no runtime-neutral namespace migration for readout state.** The spec ports hook scripts to `.agent0/hooks/`, but the data remains under `.claude/reminders.yaml`, `.claude/routines/`, `.claude/.routines-state/`, and MCP docs remain under `.claude/rules/`. That is probably correct, but it should be explicit: no move of reminders/routines/MCP recipe source-of-truth paths to `.agent0/` in this spec.

- **Routines double-dispatch is under-specified.** The current acceptance says the block has "pending dispatch instructions identical to Claude's", but the implementation only reads queue files; it does not consume them. If both runtimes surface the same queue, the double-dispatch risk is human/process-level, not FIFO-serialized by the readout. OQ3 should not assume "queue's FIFO consumption naturally serialize[s]" unless `/routine run` removes or locks entries and the scenario names that behavior. Add either a non-goal ("readout parity does not prevent two sessions from seeing the same queue") or an acceptance scenario proving dispatch consumption is idempotent.

- **`mcp-recipes` skip and workspace env vars remain Claude-named.** `CLAUDE_SKIP_MCP_RECIPES` and `CLAUDE_MCP_RECIPES_WORKSPACE_DIRS` can remain as backward-compatible aliases, but a shared `.agent0/hooks/` script should document neutral names (`AGENT0_SKIP_MCP_RECIPES`, `AGENT0_MCP_RECIPES_WORKSPACE_DIRS`) or explicitly state that legacy `CLAUDE_*` env names are retained as public compatibility knobs.

- **Static criteria should require config parse validation.** `.codex/config.toml.example` is parseable today with commented hook blocks plus active MCP blocks. Adding three `[[hooks.SessionStart]]` blocks can easily create TOML shape mistakes. Add a verification criterion using `tomllib`/equivalent to parse the uncommented example fragment or a generated temp config, not just grep for strings.

- **Consumer resync criterion is too broad for a draft spec.** "At least one of `mei-saas` / `codexeng` consumer projects re-synced post-port and verified the three readouts fire on a fresh Codex session" is valuable dogfood, but it binds the implementation to external repo state and fresh interactive Codex startup. Keep it if this spec is intentionally dogfood-heavy; otherwise split into "sync-harness check proves propagation" plus "one local fixture/synthetic SessionStart run proves hook output", and leave downstream resync as notes evidence.

---

## Round 2 — initiating agent (counter)

_The initiating agent addresses each critique point: accept (will change spec) / reject (with reasoning) / defer (open question)._

Classifying each of Codex's 12 distinct points. Eleven accepts, one defer. Reasoning in one line per point; concrete spec deltas land in synthesis.

### Responses to the 3 pushback-ask answers

1. **OQ2 reversal — output must be runtime-aware OR neutral, not byte-for-byte.** **Accept.** Concrete: the script should detect the runtime (presence of `$CLAUDE_PROJECT_DIR` vs Codex hook payload) and emit a runtime-appropriate "copy + uncomment from `<right file>`" pointer, OR fall back to neutral wording pointing at both `.mcp.json.example` and `.codex/config.toml.example`. Decision (which shape) belongs in plan.md, but the spec needs an acceptance scenario that distinguishes invariant block frame/recipe list from runtime-specific install pointers (see also point 5 below).

2. **Scope — `mcp-recipes-hint.sh` is "parity PLUS reversal of spec 098's explicit decision".** **Accept the framing; defer the bundle-vs-split decision to plan.** I underweighted this — spec 098 (`codex-mcp-recipes-parity`) explicitly chose not to ship the Claude-side hint to Codex. Treating spec 100 as "trivial Tier 1" while it overturns that decision is exactly the kind of scope blur the survey was supposed to avoid. Plan-phase decision: (a) drop `mcp-recipes-hint.sh` from spec 100 and scaffold a separate micro-spec that revisits 098's decision openly, OR (b) keep it bundled but rewrite the spec's Intent to name the 098 reversal explicitly. I lean (a) — it preserves Tier 1's "no semantic decisions" character. Updating the Intent paragraph at synthesis to acknowledge this.

3. **PyYAML on Codex — raw-YAML fallback leaks non-surfaceable entries.** **Accept; the fix is darker than the spec currently admits.** Two truths: (a) this bug exists in the current Claude implementation too — raw-YAML tier runs in any environment missing both Python+PyYAML and yq. So it is not a port-introduced regression, but a port-amplified one (Codex environments will hit the fallback more often). (b) The honest fix is making filtering single-source: either the helper accepts yq input (so the helper applies the filter even in the no-PyYAML branch), OR the hook documents raw-YAML as degraded with an advisory. Lean toward documenting degradation explicitly + adding an acceptance scenario "Codex reminders readout without PyYAML and without yq emits raw-YAML with a `reminders-degraded-advisory:` line; non-surfaceable entries MAY appear in the block" — same shape as `tdd-advisory:` / `lint-advisory:`. The helper refactor is plan-phase optional.

### Responses to the 9 spec issues

- **PROJECT_DIR resolution `${CLAUDE_PROJECT_DIR:-$PWD}` is Claude-bound.** **Accept.** Will adopt the `_memory-hook-lib.sh` precedence (`AGENT0_PROJECT_DIR` → `CLAUDE_PROJECT_DIR` → stdin `.cwd` → `git rev-parse --show-toplevel` → `pwd`). Spec 099 already shipped this lib; cleanest fix is each of the three readouts sourcing the same helper. Acceptance criterion: zero literal `$CLAUDE_PROJECT_DIR` references in the moved scripts.

- **"Identical to Claude" overclaims in scenarios.** **Accept.** Rephrase each Codex-side scenario to "the preamble contains the `=== <NAME> ===` framed block with the same recipe list / reminder set / queue entries Claude emits, allowing runtime-specific install pointers and YAML-fallback degradation as advised". Distinguishes invariant semantics from allowed wording divergence.

- **Missing scenario: subdirectory launch.** **Accept.** Adding scenario: Given Codex started with `-C <repo>/apps/web` (or hook command resolved at depth-N), When SessionStart hooks fire, Then all three readouts resolve the git root and operate against root-relative state files (`.claude/reminders.yaml`, `.claude/.routines-state/`, root stack signals).

- **Missing scenario: hook trust / approval posture.** **Accept.** Either extend the "hook-disabled" scenario to include "or hooks not yet trusted in repo", or add a discrete scenario: Given the Codex repo trust review is pending, When the user starts Codex, Then no readout blocks appear AND a one-line advisory directs the user to the Codex trust review path. Lean toward extending the existing scenario (lower scenario count, same coverage).

- **Missing non-goal: no namespace migration for readout state.** **Accept.** Adding explicit non-goal: "No move of `.claude/reminders.yaml`, `.claude/routines/`, `.claude/.routines-state/`, or `.claude/rules/mcp-recipes.md` to `.agent0/` in this spec. Only the three hook scripts move; the data they read stays under `.claude/`."

- **OQ3 double-dispatch — readout reads, doesn't consume; FIFO doesn't serialize.** **Accept fully; my framing was wrong.** Adding non-goal: "Readout parity does NOT prevent two sessions (Claude + Codex on the same leader machine, or two parallel sessions) from seeing the same queue. Dispatch consumption happens in `/routine run <slug>`, not in the readout. Idempotency of dispatch is a separate concern owned by routines, not this spec." Removing OQ3 — it was based on a false premise.

- **`CLAUDE_SKIP_MCP_RECIPES` / `CLAUDE_MCP_RECIPES_WORKSPACE_DIRS` env var naming.** **Defer.** This is a cross-cutting question (memory hooks have similar `CLAUDE_*` env vars in places). Adding open question to spec 100: "Should `.agent0/hooks/*` documented canonical env var names move to `AGENT0_*` with `CLAUDE_*` kept as aliases, or are `CLAUDE_*` names retained as the public contract?" Resolution probably belongs in a separate spec, but flagging it here.

- **Add TOML parse-validation criterion.** **Accept.** Adding static fact: "Adding the three `[[hooks.SessionStart]]` blocks (uncommented) to `.codex/config.toml.example` parses successfully via `python3 -c 'import tomllib; tomllib.loads(open(\".codex/config.toml.example\").read().replace(\"# [\", \"[\"))'` (or equivalent). Mechanical guard against TOML shape errors."

- **"Consumer resync" criterion too broad for draft.** **Accept partial.** Splitting into: (a) static fact "sync-harness manifest carries the three new `.agent0/hooks/` paths AND a dry-run on a fixture project shows the files propagate" (mechanical), and (b) acceptance scenario "a synthetic `SessionStart` fixture (stdin payload + temp project dir) drives each of the three hooks and produces the expected framed block to stdout" (mechanical, no live Codex needed). Downstream mei-saas / codexeng resync demotion to "Evidence (not acceptance): at least one consumer re-synced and reported the readouts firing" in the spec's notes or context, not as a checkbox.

### Net effect on the spec

11 of 12 accepts will land as concrete deltas (acceptance scenarios, non-goals, intent rephrasing, one new open question, one OQ removal). The deferred env-var question is the only contested item. Asking for synthesis when you're ready, or another reviewing round if there's more — I think Codex's critique is substantively complete and a Round 2 reviewing pass would add diminishing returns.

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

11 of 12 critique points accepted by the initiating agent; 1 deferred to a new open question (cross-cutting env-var naming question). No fundamental disagreement; the user stopped after Round 2 counter judging diminishing returns on a Round 2 critique.

**Proposed spec changes:**

§ Intent — rewrite paragraph 2 to acknowledge that `mcp-recipes-hint.sh` overturns spec 098's explicit "Codex does not receive the Claude SessionStart MCP hint" decision; remove the unqualified "mechanically trivial" framing for the bundle.

§ Acceptance criteria — rephrase the 3 Codex-side behavioral scenarios (reminders / routines / mcp-recipes) to distinguish invariant block frame + content semantics from allowed runtime-specific install pointers and YAML-fallback degradation (replaces literal "identical to Claude").

§ Acceptance criteria — add scenario "Codex SessionStart fired from a subdirectory launch": Given Codex started with `-C <repo>/apps/web` or hook command resolved at depth-N, When SessionStart fires, Then all three readouts resolve the git root and operate against root-relative state files.

§ Acceptance criteria — extend the existing "hook-disabled Codex session does not emit readouts" scenario to also cover the pending-trust-review path (no readouts appear until the user trusts repo-local hooks; one-line advisory pointing at the trust review).

§ Acceptance criteria — add scenario "Codex reminders readout without PyYAML and without yq": Given the environment lacks both Python+PyYAML and yq, When the readout fires, Then it emits raw-YAML output with a `reminders-degraded-advisory:` line; non-surfaceable entries (snoozed/done) MAY appear in the block. Documents the degradation honestly.

§ Acceptance criteria — replace static fact "Sync-harness picks up the three new paths AND a consumer re-syncs and verifies" with two narrower mechanical facts: (a) "Sync-harness manifest carries the three `.agent0/hooks/` paths; a dry-run on a fixture project shows propagation", (b) "A synthetic `SessionStart` fixture (stdin payload + temp project dir) drives each hook and produces the expected framed block on stdout". Demote downstream mei-saas/codexeng resync to § Context / references as evidence, not as a checkbox.

§ Acceptance criteria — add static fact: "The three `[[hooks.SessionStart]]` blocks in `.codex/config.toml.example`, when uncommented, parse successfully via `python3 -c 'import tomllib; tomllib.loads(...)'` or equivalent. Mechanical guard against TOML shape errors."

§ Acceptance criteria — add static fact: "Zero literal `$CLAUDE_PROJECT_DIR` references in the moved scripts. Project-dir resolution uses the `_memory-hook-lib.sh` precedence chain (`AGENT0_PROJECT_DIR` → `CLAUDE_PROJECT_DIR` → stdin `.cwd` → `git rev-parse --show-toplevel` → `pwd`)."

§ Non-goals — add: "No move of `.claude/reminders.yaml`, `.claude/routines/`, `.claude/.routines-state/`, or `.claude/rules/mcp-recipes.md` to `.agent0/`. Only the three hook scripts move; the data and rules they read stay under `.claude/`."

§ Non-goals — add: "Readout parity does NOT prevent two sessions (Claude + Codex on the same machine, or two parallel sessions) from seeing the same routines queue. Dispatch consumption happens in `/routine run <slug>`; idempotency there is a separate concern owned by routines, not this spec."

§ Open questions — remove OQ3 ("Routines leader-flag interaction with Codex") — it was based on a false premise (FIFO does not serialize; readout doesn't consume). Replaced by the non-goal above.

§ Open questions — add new OQ: "Should `.agent0/hooks/*` documented canonical env var names move to `AGENT0_*` (e.g. `AGENT0_SKIP_MCP_RECIPES`, `AGENT0_MCP_RECIPES_WORKSPACE_DIRS`) with `CLAUDE_*` kept as aliases, or are `CLAUDE_*` names retained as the public contract? Cross-cutting (memory hooks have similar surface); resolution likely belongs in a separate spec, but flagged here so plan.md can name the choice it's adopting locally."

§ Open questions — sharpen OQ2 to name the bundle-vs-split decision explicitly: "Resolve OQ2 before plan.md locks; if the decision is 'mcp-recipes-hint.sh is a substantive 098 reversal', split it to a separate micro-spec and shrink spec 100 to the two trivial readouts. If 'incidental, safe to bundle', keep it in scope but reword § Intent."

**Unresolved disagreements:**

None. The 1 defer (env-var naming `CLAUDE_*` vs `AGENT0_*`) is documented as a new open question, not as an active disagreement — Codex flagged a real cross-cutting choice that's bigger than spec 100, and the initiating agent agreed it belongs in a separate resolution path.

---

## Applied changes

_Filled after user confirms the synthesis. List the actual edits made to `spec.md` (or "synthesis rejected — no changes applied")._

- `spec.md` § Intent — rewrote paragraph to split the three hooks (2 pure-readout + 1 spec-098 reversal), acknowledged the reversal explicitly, removed "mechanically trivial" framing.
- `spec.md` § Acceptance criteria — rephrased the 3 Codex-side scenarios (reminders/routines/mcp-recipes) to distinguish invariant frame/semantics from allowed runtime-specific wording and YAML-fallback degradation.
- `spec.md` § Acceptance criteria — extended the "hook-disabled" scenario to also cover the pending-trust path.
- `spec.md` § Acceptance criteria — added new scenario "Codex SessionStart fired from subdirectory launch".
- `spec.md` § Acceptance criteria — added new scenario "Codex reminders readout without PyYAML and without yq" documenting the degraded raw-YAML output with a `reminders-degraded-advisory:` line.
- `spec.md` § Acceptance criteria — added static fact "Zero literal `$CLAUDE_PROJECT_DIR` references; project-dir resolution uses `_memory-hook-lib.sh` precedence chain".
- `spec.md` § Acceptance criteria — added static fact "TOML parse validation of uncommented `[[hooks.SessionStart]]` blocks".
- `spec.md` § Acceptance criteria — replaced "Sync-harness picks up..." + "consumer re-synced..." with two narrower mechanical facts (manifest carries paths + dry-run; synthetic SessionStart fixture).
- `spec.md` § Non-goals — added "No move of `.claude/reminders.yaml`, `.claude/routines/`, `.claude/.routines-state/`, or `.claude/rules/mcp-recipes.md` to `.agent0/`".
- `spec.md` § Non-goals — added "Readout parity does NOT prevent multiple sessions from seeing the same routines queue; dispatch consumption owned by `/routine run`, not this spec".
- `spec.md` § Open questions — removed OQ3 (routines leader-flag) — based on false premise that readout consumes queue.
- `spec.md` § Open questions — removed OQ5 (PyYAML dependency story) — answered by the new degraded-fallback scenario.
- `spec.md` § Open questions — sharpened OQ2 to a two-part decision (substantive vs incidental + bundle vs split) that MUST resolve before plan.md locks.
- `spec.md` § Open questions — added new OQ4 (env var naming `CLAUDE_*` vs `AGENT0_*` canonical question, cross-cutting).
