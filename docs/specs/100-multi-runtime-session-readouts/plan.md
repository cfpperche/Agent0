# 100 — multi-runtime-session-readouts — plan

_Drafted from `spec.md` on 2026-05-27. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Mirror spec 099's per-capacity port shape: move three SessionStart readout scripts from `.claude/hooks/` to `.agent0/hooks/`, source the existing `_memory-hook-lib.sh` for project-dir resolution (no new shared lib), repoint Claude's `.claude/settings.json` registrations, and add three commented-out `[[hooks.SessionStart]]` blocks to `.codex/config.toml.example` paralleling the existing `memory-decay-readout` block. The `mcp-recipes-hint.sh` script gets one extra step beyond the other two: its output text "copy + uncomment from `.mcp.json.example`" becomes runtime-aware so Codex sessions see `.codex/config.toml.example` instead. Two doc files update (`mcp-recipes.md` revises the explicit Claude-only line; `runtime-capabilities.md` promotes three matrix rows). The synthetic-SessionStart fixture pattern from `.claude/tests/` validates each hook produces the expected framed block without requiring a live Codex session for acceptance.

Implementation runs in **five sequential phases** matching the spec 099 cadence — each independently shippable and verifiable before the next starts. The sequencing keeps readouts functional at every commit boundary; no flag-day cutover. Phase A creates the two pure-readout ports (reminders + routines) — mechanical lift+shift with `memory_project_dir` substitution. Phase B ports `mcp-recipes-hint.sh` with the install-pointer wording adaptation, the harder of the three. Phase C wires the registrations on both runtimes. Phase D updates the two affected rule files. Phase E adds the synthetic fixture tests and runs at least one dogfood on a real Codex session in this repo.

Resolutions to the three remaining open questions, each locked at the start of plan-phase:

- **OQ1 (compat shim vs hard cutover) — hard cutover.** Spec 099 proved the shim-removal follow-up cost was effectively zero (same-day removal in this same session). Three hooks is below the threshold where shim complexity pays off. Consumers run the same manual migration as 099 (`git mv` on the consumer side is unnecessary — sync-harness adds the new `.agent0/hooks/` paths; consumers update their own `.claude/settings.json` references and remove the old paths). No `.claude/hooks/<name>.sh → .agent0/hooks/<name>.sh` shims ship.
- **OQ3 (shared lib for readouts) — no new `_readout-hook-lib.sh`.** All three readouts source `_memory-hook-lib.sh` for `memory_project_dir` (the one concrete shared piece). Framed-block emit logic stays inlined per script — duplication is `printf '=== %s ===\n' "$NAME"` shape, ~3 lines each, below the rule-of-three threshold for extraction. Revisit when a fourth readout surfaces.
- **OQ4 (env var naming `CLAUDE_*` vs `AGENT0_*`) — dual-name, `CLAUDE_*` retained as canonical contract.** Hooks honor both `CLAUDE_SKIP_<NAME>` (canonical) AND `AGENT0_SKIP_<NAME>` (alias) — and the same for `CLAUDE_MCP_RECIPES_WORKSPACE_DIRS` / `AGENT0_MCP_RECIPES_WORKSPACE_DIRS`. Documented in the hook header comment of each script. The canonical-name flip is a cross-cutting question that affects memory hooks too; defer to a separate follow-up spec rather than re-naming inconsistently across the codebase here.

## Files to touch

**Create:**

- `.agent0/hooks/reminders-readout.sh` (~80 LOC) — port of `.claude/hooks/reminders-readout.sh`. Source `_memory-hook-lib.sh`; replace `PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"` with `PROJECT_DIR="$(memory_project_dir "$INPUT")"`. Helper invocation env-export updated to also set `AGENT0_PROJECT_DIR`. Honor both `CLAUDE_SKIP_REMINDERS_READOUT` and `AGENT0_SKIP_REMINDERS_READOUT`. Emit `reminders-degraded-advisory:` on stderr when the PyYAML/yq tier ladder falls all the way through to raw-YAML.
- `.agent0/hooks/routines-readout.sh` (~135 LOC) — port of `.claude/hooks/routines-readout.sh`. Same `memory_project_dir` substitution; same dual env-var honor (`CLAUDE_SKIP_ROUTINES_READOUT` + `AGENT0_SKIP_ROUTINES_READOUT`). No advisory needed (routines readout has no PyYAML dependency).
- `.agent0/hooks/mcp-recipes-hint.sh` (~300 LOC) — port of `.claude/hooks/mcp-recipes-hint.sh`. Same `memory_project_dir` substitution; dual env vars (`CLAUDE_SKIP_MCP_RECIPES` + `AGENT0_SKIP_MCP_RECIPES`, `CLAUDE_MCP_RECIPES_WORKSPACE_DIRS` + `AGENT0_MCP_RECIPES_WORKSPACE_DIRS`). **One material change:** detect runtime via stdin payload shape (`tool_name == "apply_patch"` OR `$CLAUDE_PROJECT_DIR` absent) and emit `Suggested MCP recipes (copy + uncomment from .codex/config.toml.example):` instead of `.mcp.json.example` when invoked from Codex. Runtime detection uses the existing `memory_runtime` helper in `_memory-hook-lib.sh`.
- `.claude/tests/multi-runtime-readouts/01-reminders-fixture.sh` — drives `reminders-readout.sh` with a synthetic stdin payload + temp project dir, asserts `=== REMINDERS ===` block in stdout.
- `.claude/tests/multi-runtime-readouts/02-routines-fixture.sh` — same shape, asserts `=== ROUTINES ===`.
- `.claude/tests/multi-runtime-readouts/03-mcp-recipes-fixture.sh` — same shape; runs twice (once with Claude-style payload, once with Codex-style) and asserts the install-pointer text differs accordingly.
- `.claude/tests/multi-runtime-readouts/04-subdir-launch.sh` — drives each of the three hooks with a stdin payload whose `.cwd` is a subdir; asserts they resolve the git root.
- `.claude/tests/multi-runtime-readouts/05-toml-parse.sh` — uncomments the three `[[hooks.SessionStart]]` blocks in `.codex/config.toml.example` via a temp file + assertion that `python3 -c "import tomllib; tomllib.loads(open(...).read())"` succeeds.

**Modify:**

- `.claude/settings.json` — three `SessionStart.hooks[].command` entries repointed from `.claude/hooks/reminders-readout.sh` / `routines-readout.sh` / `mcp-recipes-hint.sh` to `.agent0/hooks/<same>.sh`. Done when grep `.claude/hooks/reminders-readout\|.claude/hooks/routines-readout\|.claude/hooks/mcp-recipes-hint` against settings.json returns zero matches.
- `.codex/config.toml.example` — three new commented `[[hooks.SessionStart]]` blocks added under the existing `memory-decay-readout` block, each matching the same shape (matcher `startup|resume|clear|compact`, command resolves via `git rev-parse --show-toplevel`, statusMessage one-liner naming the readout).
- `.claude/rules/mcp-recipes.md` — § *How it works* updated: the bullet "**`.claude/hooks/mcp-recipes-hint.sh`** (`SessionStart`) — Claude-only hint" becomes runtime-neutral wording ("…fires on both Claude Code via `.claude/settings.json` and Codex CLI via `.codex/config.toml`"). § *Hint output shape* example updates to show the runtime-aware install-pointer line.
- `.claude/rules/runtime-capabilities.md` — three matrix rows update (mcp recipes, reminders, routines, OR equivalent capability lines if rows don't exist yet for the latter two — likely need to be added). Re-audit-pending note (line 43) shortens by removing the three rows now closed.

**Delete:**

- `.claude/hooks/reminders-readout.sh`
- `.claude/hooks/routines-readout.sh`
- `.claude/hooks/mcp-recipes-hint.sh`

## Alternatives considered

### Option A — Compat shims left at `.claude/hooks/<name>.sh`

Each old path becomes a 2-line `exec` redirect to the canonical `.agent0/hooks/<name>.sh`, mirroring the spec 099 transitional shape. Removed in a follow-up commit after consumer migration windows close.

**Rejected because** spec 099 demonstrated the shim-removal cost was effectively zero (same-day removal in commit `c16677d`, this session). With only three hooks and a single SessionStart event, the shim complexity buys nothing — the migration is mechanical (`git mv` + settings.json path swap), takes ~3 minutes per consumer, and shims would introduce a second namespace cleanup follow-up. Hard cutover is simpler and the consumer manual-migration cost is identical in either mode.

### Option B — Sync-manifest exemption for `.claude/hooks/` during transition

Curate the sync-harness manifest to keep both `.claude/hooks/<name>.sh` and `.agent0/hooks/<name>.sh` files in scope during a migration window; never delete the old paths until consumers opt in.

**Rejected because** this was already rejected in spec 099 for the same reason: the 3-way baseline reconciliation in `sync-harness.sh` would detect the file-removed-from-upstream condition and delete the consumer's `.claude/hooks/<name>.sh` files. The consumer's `.claude/settings.json` (refused as customized) would still reference those paths → broken hooks until manual migration. Manual migration is the user's stated constraint; "broken until you migrate" is hostile UX even with a migration window.

### Option C — Always-emit-both install pointers in `mcp-recipes-hint.sh`

Instead of runtime-aware detection, the hook always emits `Suggested MCP recipes (copy + uncomment from .mcp.json.example for Claude or .codex/config.toml.example for Codex):`. Single output shape, no runtime detection.

**Rejected because** the output noise is real: a Claude user sees `.codex/config.toml.example` mentioned for no reason (and vice versa). Runtime detection adds ~3 lines (`memory_runtime` helper already exists in `_memory-hook-lib.sh`) and produces cleaner output. The cost-benefit favors detection.

### Option D — Extract a new `_readout-hook-lib.sh`

Create a shared shell lib for the three readouts paralleling `_memory-hook-lib.sh`: framed-block emit, common `=== <NAME> ===` headers, dual-env-var honor.

**Rejected because** three readouts is below the rule-of-three threshold for extraction. The shared logic is `printf '=== %s ===\n' "$NAME"` framing (3 lines × 3 hooks = 9 lines) and the dual-env-var honor pattern (~4 lines × 2 hooks that have env vars = 8 lines). Extraction would create a new file + sourcing line × 3 hooks for ~17 lines of duplication. Revisit when a fourth readout surfaces.

## Risks and unknowns

- **Codex SessionStart payload shape on subdir launch.** The `memory_project_dir` precedence chain handles this in theory (`AGENT0_PROJECT_DIR` → `CLAUDE_PROJECT_DIR` → stdin `.cwd` → `git rev-parse` → `pwd`), but Codex sessions started with `-C <repo>/apps/web` may inject `.cwd` differently than expected. Mitigation: test `04-subdir-launch.sh` covers this. Real-world validation requires a Codex session started from a subdir — dogfood in Phase E.
- **Runtime detection in `mcp-recipes-hint.sh` may misfire in mixed environments.** If `$CLAUDE_PROJECT_DIR` is set in the shell (e.g. a dev launches Codex from a Claude-Code-aware shell), the runtime detection could report "Claude" when the actual runtime is Codex. Mitigation: use `tool_name == "apply_patch"` from stdin payload as the primary signal (Codex-specific); fall back to env-var inspection only when stdin doesn't reveal the runtime. `memory_runtime` helper already does this.
- **`runtime-capabilities.md` matrix may not have rows for `reminders` / `routines` today.** The matrix has `mcp recipes`, but `reminders` and `routines` may be implicit (covered by `lifecycle hooks` row). Decision in Phase D: add explicit rows for clarity, OR document under a single "SessionStart readouts" composite row. Lean toward explicit rows — each capacity has its own user-visible behavior.
- **Sync-harness manifest may already cover `.agent0/hooks/*.sh` via glob from spec 099.** Need to verify before Phase E. If glob is in place, no manifest edit needed; if not, add explicit globs. Check `.claude/tools/sync-harness.sh` and `.claude/harness-sync-baseline.json`.
- **Codex hook trust posture is environment-specific.** A consumer with `.codex/config.toml` opted in but not yet trusted in Codex's prompt-on-first-run won't see readouts. Acceptance scenario (the extended "hook-disabled or pending-trust" one) covers this with documentation; no code change needed unless the trust-review path requires an explicit advisory.
- **`mcp-recipes.md` § *Hint output shape* example bakes in the Claude-style output.** A copy-edit pass updates the example block; risk is forgetting to keep the example in sync if the actual hook output evolves. Mitigation: test `03-mcp-recipes-fixture.sh` asserts the exact strings, so any drift surfaces as a test failure.
- **PyYAML dependency unknown on Codex consumer dev machines.** The new "degraded raw-YAML" acceptance scenario documents the fallback honestly. Risk is that consumer users see the degraded output in practice more often than expected. Mitigation: the advisory line names the dependency explicitly so the user can install PyYAML/yq once and silence it.

## Research / citations

- `docs/specs/099-memory-multi-runtime/plan.md` — direct precedent for the per-capacity port shape (5-phase cadence, shared lib usage, `.codex/config.toml.example` block pattern, sync-harness propagation, hard cutover decision).
- `docs/specs/098-codex-mcp-recipes-parity/spec.md` § *Open questions* — the formalized Claude-only decision being reversed (resolved OQ: "leave runtime hints unchanged"). Spec 098's reasoning was scope discipline (MCP activation only), not runtime constraint.
- `docs/specs/100-multi-runtime-session-readouts/debate.md` — Round 1 cross-model review with Codex CLI confirmed no Codex runtime reason to keep the stack-detector Claude-only; surfaced the PyYAML fallback bug and project-dir resolution gap, both addressed in this plan.
- `.agent0/hooks/_memory-hook-lib.sh` — reused for `memory_project_dir` and `memory_runtime` helpers; no new shared lib needed.
- `.agent0/hooks/memory-decay-readout.sh` — exact shape precedent for a clean SessionStart hook (sources lib, exits 0 always, honors runtime-neutral project-dir resolution).
- `.codex/config.toml.example` (current state) — single existing `[[hooks.SessionStart]]` block for `memory-decay-readout`; three new blocks parallel that shape.
- `.claude/rules/mcp-recipes.md` § *How it works* and § *Hint output shape* — copy targets for the wording revisions.
- `.claude/rules/runtime-capabilities.md` § *Capability matrix* line 34 (lifecycle hooks `native` both) and line 43 (re-audit pending) — the matrix rows this spec closes part of.
