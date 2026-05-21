# 070 — propagation-hygiene — tasks

_Generated from `plan.md` on 2026-05-21. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. **Inventory sweep.** Grep `docs/specs/0[0-9][0-9]` and `[Ss]pecs? [0-9]` across `CLAUDE.md` and all `.claude/rules/*.md`; also check the other fork-bound files (`.mcp.json.example`, `.gitleaks.toml`, `.githooks/pre-commit`, `.gitignore`). Record the per-file pointer worklist in `notes.md` and resolve spec OQ3 (does scope extend beyond CLAUDE.md + 15 rules?). Flip `spec.md` Status `draft` → `in-progress`.
- [x] 2. **Create `.claude/memory/capacity-spec-index.md`.** Map every capacity to its originating spec(s) using the inventory data — built before the de-leak so no linkage is lost. Add a one-line index pointer in `.claude/memory/MEMORY.md`.
- [x] 3. **De-leak CLAUDE.md capacity sections.** Strip `Spec NNN:` lead-ins, mid-paragraph `spec NNN` mentions, and `docs/specs/0NN-*` pointers from the ~11 capacity sections. Each edit is a minimal pointer-removal, not a rewrite. Excludes `## Spec-driven development` (task 6) and `## PHP / Laravel` (task 4).
- [x] 4. **Delete the `## PHP / Laravel` section from CLAUDE.md.** Remove the section entirely.
- [x] 5. **Fold PHP/Laravel detection inline.** Add a short PHP/Laravel clause to the CLAUDE.md capacity sections that enumerate stacks (validator/lint reference, supply-chain managers list, runtime-introspect allowlist, TDD patterns) — the same inline shape `## Lint validator` already uses for JS/TS + Python.
- [x] 6. **Handle CLAUDE.md `## Spec-driven development` (special case).** Strip concrete `docs/specs/0NN-*` pointers but KEEP the `docs/specs/NNN-<slug>/` convention scheme (literal `NNN`).
- [x] 7. **De-leak the 14 standard rule files.** Strip concrete-spec pointers (`docs/specs/0NN-*`, `Spec NNN`, `specs NNN+NNN`) from: `harness-sync.md`, `session-handoff.md`, `routines.md`, `lint-validator.md`, `memory-placement.md`, `php-laravel-support.md`, `user-prompt-framing.md`, `runtime-introspect.md`, `artifact-budgets.md`, `supply-chain.md`, `delegation.md`, `mcp-recipes.md`, `secrets-scan.md`, `tdd.md`. Replace each pointer with nothing — do NOT point at the index (it does not propagate either).
- [x] 8. **De-leak `.claude/rules/spec-driven.md` (special case).** Strip concrete pointers (`docs/specs/060-harness-gaps-2026/`, etc.) but KEEP the `docs/specs/NNN-<slug>/` convention scheme — `spec-driven.md` documents the convention itself.
- [x] 9. **Resolve spec OQ2 — `memory-placement.md` carve-out.** Decide whether to add a one-line carve-out acknowledging memory may hold a non-propagating maintainer discipline, or rely on the `agent0-purpose.md` precedent. Apply or skip; record the decision + reasoning in `notes.md`.
- [x] 10. **Create `.claude/memory/propagation-hygiene.md`.** Document the fork-bound file class (sync-harness manifest + CLAUDE.md capacity sections), the no-Agent0-internal-pointer mandate, the pointer to non-propagated buckets (`.claude/memory/`, `docs/specs/`), and the append-only-merge orphan limitation (already-synced forks keep stale sections). Add a one-line index pointer in `.claude/memory/MEMORY.md`.

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria._

- [x] 11. **AC1** — `grep -rE 'docs/specs/0[0-9][0-9]' .claude/rules/*.md CLAUDE.md` returns zero matches; the literal `docs/specs/NNN-<slug>/` convention still present in `spec-driven.md` + `## Spec-driven development`.
- [x] 12. **AC2** — no CLAUDE.md capacity section begins with a `Spec NNN:` prefix; `grep -nE '[Ss]pecs? [0-9]' CLAUDE.md .claude/rules/*.md` surfaces no surviving concrete-spec prose pointer outside the spec-driven convention text.
- [x] 13. **AC3 + AC4** — `## PHP / Laravel` is absent from `CLAUDE.md`; PHP/Laravel detection appears inline in the relevant capacity sections; `.claude/rules/php-laravel-support.md` is retained with its `paths:` frontmatter unchanged.
- [x] 14. **AC5–AC8** — `.claude/memory/capacity-spec-index.md` and `.claude/memory/propagation-hygiene.md` exist with the required content; both have `MEMORY.md` index lines; `grep` of `.claude/tools/sync-harness.sh` confirms neither path is in the propagation manifest (`.claude/memory/` ships only `.gitkeep`). Then tick the `spec.md` acceptance boxes, flip Status `in-progress` → `shipped`, and append any deviations to `notes.md`.

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._
