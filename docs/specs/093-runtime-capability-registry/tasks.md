# 093 — runtime-capability-registry — tasks

_Generated from `plan.md` on 2026-05-26. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

### Layer 0 — Vocabulary lock-in (gate)

- [ ] 1. Re-confirm the 12-row × 2-runtime dry-run table from `plan.md § Approach` step 1. For each row, assign a cell value from the six-state vocabulary (`native`, `native-opt-in`, `convention`, `read-only`, `planned`, `unsupported`). If any row resists the vocabulary — i.e. you cannot pick a single state without inventing a 7th or adding a footnote that changes the row's meaning — STOP: update `spec.md § Acceptance criteria / Scenario: status vocabulary` to expand the vocabulary FIRST, then resume. Spec Scenario 5 mandates this gate; no implementation files land until it passes. Verify `.claude/hooks/mcp-recipes-hint.sh` exists at that path (named in spec Scenario 5) — if the actual filename differs, update both the registry plan and `spec.md` Scenario 5's owner-file list in the same commit.

### Layer 1 — Write the registry

- [ ] 2. Create `.claude/rules/runtime-capabilities.md`. Section structure: §What (one-paragraph purpose: what the registry is, what it answers, who edits it); §Status vocabulary (the six terms with operational definitions copied verbatim from `spec.md § Scenario: status vocabulary`); §Capability matrix (the 12-row table from Layer 0 with three columns minimum — `Capability`, `Claude Code`, `Codex CLI` — plus an `Owner files` column carrying a list per row, and a `Notes` column for activation prerequisites where non-trivial); §Update rule (verbatim from `spec.md § Acceptance criteria` static-fact bullet on the update rule); §Drift enforcement (the five anchor-level invariants from spec Scenario 7, named (a)-(e), with a one-line pointer at `.claude/tools/check-instruction-drift.sh`); §Future runtimes (named placeholders only — `Cursor`, `Aider`, `Hermes Agent` — with explicit "no asserted support" caveat). Target size ≤ 10 KB.

- [ ] 3. Inside the §Capability matrix from task 2, verify the MCP recipes row pressure-tests the vocabulary correctly: Claude cell = `native-opt-in` (not plain `native`), Codex cell = `convention` or `planned: <slug>`, owner files include `.claude/rules/mcp-recipes.md`, `.mcp.json.example`, and the MCP-hint hook (exact filename per task 1's verification). Spec Scenario 5 elevates this single row to a gate — if it cannot be expressed cleanly, the vocabulary changes here, not in plan/tasks.

### Layer 2 — Prune AGENTS.md

- [ ] 4. Delete lines 5-13 of `AGENTS.md` (the `## Codex Capability Tiers` heading, the 3-row table, and the trailing prose paragraph that points readers at the tiers). In the same position, insert a one-paragraph bootstrap pointer + skeptical default: "For non-trivial work, consult `.claude/rules/runtime-capabilities.md` before assuming any `.claude/*` capacity is Codex-native. Default skeptical: assume `convention` or `planned` until the registry's Codex column says otherwise." Keep section heading style consistent with the rest of `AGENTS.md`.

- [ ] 5. Inside the `<!-- AGENT0:BEGIN ... AGENT0:END -->` managed block of `AGENTS.md`, add a new `## Runtime capabilities` paragraph naming `.claude/rules/runtime-capabilities.md` as canonical. Match the style of the sibling `## Session handoff`, `## Spec-driven development`, etc. paragraphs already in the block (one sentence describing the capacity, one sentence with the path). Insert position: alphabetical or topical adjacency — place near `## Runtime entrypoints` to keep the runtime-related entries grouped.

### Layer 3 — Mirror CLAUDE.md managed block

- [ ] 6. In `CLAUDE.md`, add the identical `## Runtime capabilities` paragraph from task 5 inside the corresponding `<!-- AGENT0:BEGIN ... AGENT0:END -->` managed block, in the same relative position. AGENTS.md and CLAUDE.md managed blocks must remain byte-identical (the existing drift check enforces this on every run); use the same wording verbatim — a single character difference fails CI.

### Layer 4 — Extend the drift check

- [ ] 7. In `.claude/tools/check-instruction-drift.sh`, add a new helper function `check_runtime_capabilities_registry` after the existing `AGENTS.md baseline check` block. The function implements the five anchor-level invariants from spec Scenario 7:
  - (a) `[ -f "$ROOT/.claude/rules/runtime-capabilities.md" ]` → `ok` / `fail "registry file missing: .claude/rules/runtime-capabilities.md"`.
  - (b) Both `$claude` and `$agents` files contain the literal string `.claude/rules/runtime-capabilities.md` inside their managed-block region → `ok` per file / `fail "<entrypoint>: managed block missing registry pointer"`.
  - (c) `$agents` does NOT contain the line `## Codex Capability Tiers` anywhere → `ok` / `fail "AGENTS.md: legacy '## Codex Capability Tiers' table still present"`.
  - (d) The registry file contains each of the six backtick-quoted vocabulary terms (`` `native` ``, `` `native-opt-in` ``, `` `convention` ``, `` `read-only` ``, `` `planned` ``, `` `unsupported` ``) at least once → `ok` per term / `fail "registry: vocabulary term \`<T>\` missing"`.
  - (e) For each label in a hard-coded `MINIMUM_SET` bash array (12 labels from spec Scenario 1: `instruction entrypoints`, `session handoff`, `SDD`, `debate`, `lifecycle hooks`, `runtime introspect`, `delegation/subagents`, `MCP recipes`, `image generation`, `memory`, `harness sync`, `customization/sync surfaces`), grep the registry for that label appearing at least once and at most once → `ok` per label / `fail "registry: required row '<L>' missing"` or `fail "registry: required row '<L>' duplicated"`. Extra rows beyond the minimum set are permitted and not asserted.
  
  Call `check_runtime_capabilities_registry` from `main()` after `check_agents_md_baseline`. Use the existing `ok`/`fail` accumulator pattern — no new framework required.

- [ ] 8. Add a comment above the `MINIMUM_SET` array literal in `check-instruction-drift.sh` pointing at `docs/specs/093-runtime-capability-registry/spec.md § Scenario: users can inspect one canonical capability matrix` as the source of truth. The comment names the drift risk explicitly: this array must agree with the spec's minimum-set enumeration; a future spec promoting a 13th row updates both in the same commit.

### Layer 5 — Tests

- [ ] 9. Create `.claude/tests/runtime-capabilities/` with a `run-all.sh` runner mirroring the shape of `.claude/tests/instruction-drift/run-all.sh`. Each scenario test is a numbered bash file (`01-*.sh`, `02-*.sh`, ...) that builds a deliberate-drift fixture in a temp dir, invokes `check-instruction-drift.sh --root <tmpdir> --agent0-path <repo>` (or equivalent), and asserts the exit code + the expected `drift:` / `ok:` lines.

- [ ] 10. Add scenario tests under `.claude/tests/runtime-capabilities/`:
  - `01-happy-path.sh` — fixture mirrors the real repo state; check exits 0 with all five invariants reporting `ok`.
  - `02-registry-missing.sh` — fixture omits `.claude/rules/runtime-capabilities.md`; check fails on invariant (a).
  - `03-pointer-missing-from-agents.sh` — fixture has registry but the managed-block paragraph naming it is absent from `AGENTS.md`; check fails on invariant (b).
  - `04-legacy-tier-table-resurrected.sh` — fixture re-introduces `## Codex Capability Tiers` in `AGENTS.md`; check fails on invariant (c).
  - `05-vocab-term-missing.sh` — fixture's registry omits one of the six vocabulary terms (rotate per run, or hardcode one); check fails on invariant (d).
  - `06-required-row-missing.sh` — fixture's registry omits one minimum-set label; check fails on invariant (e) with "missing".
  - `07-required-row-duplicated.sh` — fixture's registry contains `## lifecycle hooks` twice; check fails on invariant (e) with "duplicated".
  - `08-extra-row-allowed.sh` — fixture's registry adds a 13th capability row beyond the minimum set; check exits 0 (extra rows are permitted).

### Layer 6 — Sync-harness baseline refresh

- [ ] 11. Run `bash .claude/tools/sync-harness.sh --check --agent0-path "$(pwd)" "$(pwd)"` and confirm it reports `AGENTS.md` and `CLAUDE.md` managed-block changes as expected (not as `customized` refusals on the upstream itself). Then refresh `.claude/harness-sync-baseline.json` per the standard post-implementation flow — the new managed-block content + the new rule file land in the baseline. This is the only mechanical (non-hand-edited) file change in the diff.

## Verification

- [ ] 12. Run `bash .claude/tests/runtime-capabilities/run-all.sh` — all eight scenarios pass.
- [ ] 13. Run `bash .claude/tests/instruction-drift/run-all.sh` — all existing scenarios still pass (non-regression; the new helper function must not break the existing AGENTS.md baseline check).
- [ ] 14. Run `bash .claude/tools/check-instruction-drift.sh --root "$(pwd)" --agent0-path "$(pwd)"` against the real repo state — exit 0; all five new anchor invariants report `ok` alongside the pre-existing checks.
- [ ] 15. **Dogfood verification** — open `.claude/rules/runtime-capabilities.md` directly and confirm the MCP recipes row's Claude cell is `native-opt-in` (not plain `native`), the Codex cell carries `convention` or `planned: <slug>`, and the owner-file column lists at least three files. Confirm `## Codex Capability Tiers` does not appear anywhere in `AGENTS.md` (`grep -c '^## Codex Capability Tiers' AGENTS.md` returns `0`). Confirm AGENTS.md and CLAUDE.md managed blocks remain byte-identical (the existing managed-block parity check passes).
- [ ] 16. **Spec 093 acceptance scenarios** — walk every checklist bullet in `spec.md § Acceptance criteria` (7 scenarios + 3 static-fact bullets). Each must be satisfied by the diff this implementation produced. The five anchor-level invariants in Scenario 7 should be empirically validated by the tests added in task 10, not just asserted in prose.
- [ ] 17. Update `docs/specs/093-runtime-capability-registry/spec.md` `**Status:**` from `draft` to `shipped` and check off every `- [ ]` acceptance bullet to `- [x]`. Commit the spec update in the same change.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._
