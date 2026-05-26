# 093 — runtime-capability-registry — plan

_Drafted from `spec.md` on 2026-05-26. Update this file if implementation reveals the plan is wrong; do NOT silently diverge._

## Approach

Build the registry, prune the entrypoints, and extend the drift check in one PR. The work splits cleanly into six mechanical layers stacked bottom-up; each can be reviewed independently in the PR diff:

1. **Pressure-test the vocabulary against every minimum-set row before writing the file.** Spec Scenario 5 mandates an MCP worked-example; the plan extends that to the full 12-row minimum set (instruction entrypoints / session handoff / SDD / debate / lifecycle hooks / runtime introspect / delegation/subagents / MCP recipes / image generation / memory / harness sync / customization-sync surfaces). For each row, assign a cell value for Claude Code and Codex CLI using the six-state vocabulary. If a row resists the vocabulary, the vocabulary changes here, before any file lands. Dry-run cell assignments (subject to refinement during implementation):

   | Capacity | Claude Code | Codex CLI |
   |---|---|---|
   | instruction entrypoints (CLAUDE.md / AGENTS.md) | `native` | `native` |
   | session handoff (`.agent0/HANDOFF.md`) | `native` (hooks) | `convention` (AGENTS.md instructs) |
   | SDD (`/sdd` skill + rule) | `native` (slash skill) | `convention` (rule-driven, manual) |
   | debate (`/sdd debate` skill) | `native` | `planned: 091-sdd-debate-runner` |
   | lifecycle hooks (`.claude/hooks/*.sh`) | `native` | `unsupported` (no hook surface) |
   | runtime introspect (`probe.sh` + state hooks) | `native` (hooks write, probe reads) | `read-only` (Codex can read state, not trigger) |
   | delegation / subagents (`Agent` tool + gate) | `native` | `unsupported` (no native subagent dispatch) |
   | MCP recipes (`.mcp.json` + hint hook) | `native-opt-in` (recipe copy + cred required) | `convention` (manual setup following rule) |
   | image generation (`/image` skill + fal.ai) | `native-opt-in` (`FAL_KEY` + `.mcp.json` edit) | `convention` (manual via shell + MCP) |
   | memory (`.claude/memory/<topic>.md`) | `native` (lazy-read via CLAUDE.md) | `convention` (read manually) |
   | harness sync (`sync-harness.sh`) | `native-opt-in` (script invocation) | `native-opt-in` (same script; both runtimes can shell out) |
   | customization / sync surfaces | `native` (settings, skills, hooks) | `convention` (`AGENTS.override.md` + nested `AGENTS.md`) |

   This trial fits the vocabulary cleanly — no state forced; `native-opt-in` distinguishes activation-cost rows (MCP, image-gen, harness-sync) from cost-free `native`; `convention` covers Codex's universal fallback; `planned` carries a real spec slug; `read-only` and `unsupported` each have at least one row. The vocabulary is locked once this table is in the registry file.

2. **Write `.claude/rules/runtime-capabilities.md`.** Single file; structure: §What (one-paragraph purpose), §Status vocabulary (the six terms with the operational definitions copied verbatim from spec Scenario 3), §Capability matrix (the table above, expanded with owner-file lists per row and per-row notes where activation is non-trivial), §Update rule (every future spec touching runtime support edits this file in the same change; minimum-required-labels set grows only by explicit promotion), §Drift enforcement (lists the five anchor-level invariants Scenario 7 names and points at the check script), §Future runtimes (named placeholders only — Cursor, Aider, Hermes Agent; no asserted support). MCP worked-example row sits inside the §Capability matrix as a regular row, not a separate section — the worked-example role is implicit by being the first row that hits `native-opt-in`.

3. **Prune AGENTS.md.** Remove lines 5-13 entirely (`## Codex Capability Tiers` heading + 3-row table + the trailing prose paragraph that points readers at the tiers). Replace with a short bootstrap paragraph: "For non-trivial work, consult `.claude/rules/runtime-capabilities.md` before assuming any `.claude/*` capacity is Codex-native. Default skeptical: assume `convention` or `planned` until the registry's Codex column says otherwise." The `<!-- AGENT0:BEGIN -->` managed block (lines 15-118 today) gains a new `## Runtime capabilities` paragraph naming the registry path. The managed block is byte-identical between AGENTS.md and CLAUDE.md by sync convention, so this paragraph lands in CLAUDE.md too in the same commit.

4. **Prune CLAUDE.md managed block.** Pure mirror of step 3's managed-block edit — same paragraph, same position. The managed block's own machinery (sync-harness, drift check) enforces byte-identity, so any deviation will surface in CI.

5. **Extend `.claude/tools/check-instruction-drift.sh`.** Add five anchor-level checks after the existing `AGENTS.md baseline check`. Each is grep-trivial — no markdown table parser, no per-cell value inspection:
   - (a) `[ -f "$ROOT/.claude/rules/runtime-capabilities.md" ]` → `ok` / `fail: registry file missing`.
   - (b) Both `AGENTS.md` and `CLAUDE.md` contain the literal string `.claude/rules/runtime-capabilities.md` in the managed-block region → `ok` / `fail: entrypoint pointer missing`.
   - (c) `AGENTS.md` does NOT contain the line `## Codex Capability Tiers` → `ok` / `fail: legacy tier table still present`.
   - (d) The registry file contains each of the six vocabulary terms (`` `native` ``, `` `native-opt-in` ``, `` `convention` ``, `` `read-only` ``, `` `planned` ``, `` `unsupported` ``) at least once → `ok` per term / `fail: vocabulary term <T> missing`.
   - (e) For each label in a hard-coded MINIMUM_SET array (12 entries from Scenario 1), grep the registry for exactly that label exactly once → `ok` / `fail: required row <L> missing or duplicated`. Extra rows are fine; duplicates of the minimum set are errors.

   Implementation lives in a new helper function (e.g. `check_runtime_capabilities_registry`) called from `main()` after `check_agents_md_baseline`. The five checks compose against the existing `ok`/`fail` accumulator pattern — no new framework needed.

6. **Add test fixtures + a runner under `.claude/tests/runtime-capabilities/`.** Mirror the shape of `.claude/tests/instruction-drift/`: one or more bash test files that build deliberate-drift fixtures (registry missing → check fails; legacy `## Codex Capability Tiers` reintroduced → check fails; duplicate `lifecycle hooks` row → check fails; novel-vocab term `convention` removed from the registry → check fails) and one happy-path test against the real repo state. The test runner uses the existing project pattern: `bash run-all.sh` per dir.

The build order matters because (5) and (6) test against (2) and (3); (2)'s vocabulary lock-in happens in (1); (4) is pure parity with (3). Layer-by-layer commit history is recommended but a single squashed commit is also acceptable per the project's commit convention.

## Files to touch

**Create:**

- `.claude/rules/runtime-capabilities.md` — canonical registry. Sections: §What, §Status vocabulary, §Capability matrix (12 rows + future-runtime placeholders + per-row owner-file lists), §Update rule, §Drift enforcement, §Future runtimes. Size target: ≤ 10 KB (well under the 200 KB catastrophe cap; not a hard limit, just discipline).
- `.claude/tests/runtime-capabilities/run-tests.sh` — test runner mirroring the existing per-dir pattern.
- `.claude/tests/runtime-capabilities/*.sh` — individual test cases for the five anchor invariants (one happy-path test + four deliberate-drift fixtures).

**Modify:**

- `AGENTS.md` — delete lines 5-13 (`## Codex Capability Tiers` heading, 3-row table, trailing prose). Insert a one-paragraph bootstrap pointer + skeptical-default in the same position. Inside the `<!-- AGENT0:BEGIN ... AGENT0:END -->` managed block, add a `## Runtime capabilities` paragraph naming `.claude/rules/runtime-capabilities.md`.
- `CLAUDE.md` — mirror managed-block edit. Same `## Runtime capabilities` paragraph in the corresponding position inside its managed block. AGENTS.md and CLAUDE.md managed blocks must remain byte-identical (existing drift check enforces this).
- `.claude/tools/check-instruction-drift.sh` — add a new `check_runtime_capabilities_registry` function with the five anchor invariants; call it from `main()` after the existing `AGENTS.md baseline check`.
- `.claude/tools/sync-harness.sh` (manifest) — verify the new registry path is covered by the existing `.claude/rules/*` glob (it is — the glob is unconditional). No manifest edit needed; just confirm during implementation.

**Delete:**

- Nothing. The `## Codex Capability Tiers` table in AGENTS.md is overwritten in place, not as a file deletion.

## Alternatives considered

Most design alternatives went through the debate (`debate.md`) and are already resolved there — for the implementation-time record, the audit trail names them but does not relitigate.

### YAML / JSON structured sidecar alongside the markdown registry

Rejected during debate Round 2 because two canonical files for one registry would reintroduce the drift risk the spec is built to eliminate. Recorded here for the audit trail; the anchor-level drift checks in step 5 don't parse cells, so the parsing-fragility concern that motivated the sidecar proposal is moot. Promote to a schema only when a future spec has a real machine-read use case.

### Path under `.agent0/capabilities.md`

Rejected during debate Round 2 because `.agent0/**` is per-project state per spec 092; mixing Agent0-managed policy in would blur the namespace contract. The implementation uses `.claude/rules/runtime-capabilities.md`, which the existing `.claude/rules/*` sync glob already covers — zero manifest edits required.

### Keep the `## Codex Capability Tiers` table in AGENTS.md as a bootstrap summary

Rejected during debate Round 2. The current table doubles as Codex orientation AND as the source-of-truth for tier definitions. Splitting those roles is the entire point of this spec — let the registry own definitions, let AGENTS.md own the orientation. Any in-AGENTS.md tier rows or vocabulary become guaranteed drift.

### Skip extending the drift check in v1; rely on PR review discipline

Rejected because spec Scenario 7 + criterion 9 jointly require concrete enforcement; "we'll catch drift in review" is the failure mode the existing drift check (`AGENTS.md` ↔ `CLAUDE.md` managed-block byte parity) was built to prevent. The five anchor checks are ~30 LOC of bash on top of the existing pattern — cheap insurance, expensive omission.

### Pre-populate the registry with all 12 rows now, vs ship with only the MCP worked-example row

Rejected the "MCP-only" shape because spec Scenario 1 + criterion 8 require the minimum set to be present (drift check (e) enforces it). A registry that ships with one row would fail its own drift check on day one. The 12 rows are required.

### Use one big test file instead of one-test-per-invariant

Rejected for parity with `.claude/tests/instruction-drift/` and `.claude/tests/session-handoff/`, both of which use per-scenario test files. Per-scenario files make individual regressions easier to bisect and report.

## Risks and unknowns

- **Vocabulary lock-in during step 1 may surface a row that resists the six states.** The dry-run table above fits cleanly, but a 13th row added later (e.g. routines, brainstorm, /product) might force a new state. Mitigation: spec Scenario 5 already mandates the vocabulary changes here, before the file lands, if pressure-testing fails. The 12 minimum-set rows are the contract; anything beyond is post-spec and can drive vocabulary evolution.
- **Managed-block resync risk for forks.** A fork that has edited the AGENTS.md or CLAUDE.md managed block in-place (instead of using `AGENTS.override.md` per spec 090) will see `sync-harness.sh` flag the new `## Runtime capabilities` paragraph as a customization-refused merge. This is the standard managed-block contract — forks must use the override mechanism. Agent0 upstream itself does not carry a local `.claude/harness-sync-baseline.json`; implementation verifies sync coverage with `sync-harness.sh --check` instead of creating a fork baseline in the source repo. Forks see the normal sync-refusal behavior; the upstream change is not a fork-breaking event.
- **The MINIMUM_SET array hardcoded in the drift check is a second source of truth.** Scenario 1's enumeration in `spec.md` and the array in `check-instruction-drift.sh` must agree. If a future spec promotes a 13th row, both must update. Mitigation: the array literal is a single ~12-line block in the shell script; a comment above it points at spec Scenario 1 as the source of truth, and a test case asserts the array's length matches the spec-listed minimum set. Drift here is visible and grep-trivial.
- **Hermes Agent as a placeholder may invite scope creep.** A contributor seeing the placeholder might add a Hermes column with asserted support, defeating the "future/unknown placeholders only" non-goal. Mitigation: the registry's §Future runtimes section explicitly names the placeholders as "future/unknown — no asserted support". Drift check (a) covers file presence but cannot enforce semantic content; PR review remains the line of defense for this specific drift.
- **Hook hint for MCP recipes (`.claude/hooks/mcp-recipes-hint.sh`) may not exist under that exact name.** The spec scenario lists it as an owner file; verify during implementation. If the actual filename differs, update both the registry row and the spec scenario in the same commit (spec edits during implementation are allowed by SDD; silently diverging is not).
- **Unknown: how `.claude/rules/runtime-capabilities.md` interacts with `.claude/memory/MEMORY.md`'s lazy-read pattern.** Rules ship to forks; memory does not. The registry is correctly a rule. But forks consuming the new rule on first sync may not immediately know the rule exists — they discover it via the managed-block paragraph that ships in the same change. No additional discoverability hook is needed; the existing instruction-loaded surface covers it.

## Research / citations

- `docs/specs/093-runtime-capability-registry/spec.md` § Acceptance criteria — drives the 12-row minimum set, the six-state vocabulary, and the five anchor-level drift invariants.
- `docs/specs/093-runtime-capability-registry/debate.md` Rounds 1-2 + Synthesis — provenance for path choice, vocabulary, entrypoint shape, sync behavior, and data-shape rejections (YAML sidecar, `.agent0/` path, tier-table retention).
- `AGENTS.md` lines 5-13 (current `## Codex Capability Tiers` table being removed) + lines 15-118 (`<!-- AGENT0:BEGIN ... AGENT0:END -->` managed block where the new pointer paragraph lands).
- `CLAUDE.md` lines 29-132 (corresponding managed block; byte-identical mirror).
- `.claude/tools/check-instruction-drift.sh` (existing AGENTS.md baseline check, lines 127-146) — the pattern the new five-invariant function follows.
- `.claude/tools/sync-harness.sh` — confirms `.claude/rules/*` is covered by the existing manifest glob; the new registry file requires no manifest edit.
- `.claude/tests/instruction-drift/` — shape reference for the new `.claude/tests/runtime-capabilities/` test dir.
- `docs/specs/092-multi-runtime-handoff/plan.md` — sibling spec plan; shape reference for this file (mechanical layer decomposition + managed-block coordination).
- `docs/specs/090-multi-runtime-entrypoints/` — established `AGENTS.md` as Codex entrypoint + the managed-block contract this plan extends.
- `.claude/rules/harness-sync.md` § Fork-extension convention — informs the managed-block resync risk above.
- `.claude/skills/skill/references/portability-tiers.md` — separate axis (skill-body portability); the plan cites this as context but does not modify it.
