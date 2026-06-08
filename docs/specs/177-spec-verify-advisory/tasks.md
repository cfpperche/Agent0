# 177 — spec-verify-advisory — tasks

_Generated from `plan.md` on 2026-06-08. Work top-to-bottom. Check boxes as tasks complete. If a task reveals the plan is wrong, update `plan.md` before continuing._

## Implementation

- [x] 1. Create `.agent0/tools/spec-verify.sh`: arg parse (`<spec-dir>`, `--json`, `--quiet`, `-h`, unknown→exit 64); extract `**Verify:** \`<cmd>\`` lines from `tasks.md` (fallback `spec.md`); run each via `bash -c` from repo root; collect pass/fail.
- [x] 2. In `spec-verify.sh`, append a timestamped `## Verification log` block to the spec's `notes.md` recording each command + `pass`/`fail` (skip when none declared; never edit existing sections).
- [x] 3. In `spec-verify.sh`, implement output: human summary by default, single JSON object with `--json`; exit 0 (all pass) / 1 (any fail) / 2 (none declared) regardless of `--json`.
- [x] 4. Create `.agent0/tests/spec-verify/run-all.sh` covering: declared+pass→0+record, declared+fail→1+record, none→2+no-write, `--json` shape, advisory fires (shipped+verify+no-record), advisory silent (shipped+no-verify). Use a throwaway fixture spec dir under a temp path.
- [x] 5. Extend `.agent0/validators/run.sh` with the non-blocking `spec-verify-advisory:` emission: scan `docs/specs/*/spec.md` for `**Status:** shipped`; for each whose `tasks.md` declares `**Verify:**` and whose `notes.md` lacks a passing latest record, emit one advisory to stderr (Codex JSON path reused); never alter `ok`.
- [x] 6. Create `.agent0/context/rules/spec-verify.md` (frontmatter `paths:`, lead paragraph + spec ref, H2 sections: declaration syntax / the tool / the advisory / when to override / Gotchas / consumer-extension note).
- [x] 7. Add the managed-index entry to `CLAUDE.md` and `AGENTS.md` if the convention requires it (match the `## Typecheck advisory` index style); otherwise note in `notes.md` that the rule doc suffices.
- [x] 8. Create `docs/specs/177-spec-verify-advisory/squad.json` with `gate[]` = run the test harness + `spec-verify.sh` on this spec dir; roster `["claude","codex"]`.

## Verification

_Acceptance checks tied to `spec.md` acceptance criteria. Each one should map to a checklist item there._

**Verify:** `bash .agent0/tests/spec-verify/run-all.sh`

- [x] All six `spec.md` acceptance scenarios pass via `.agent0/tests/spec-verify/run-all.sh`.
- [x] `bash .agent0/tools/spec-verify.sh docs/specs/177-spec-verify-advisory` exits 0 and writes a `## Verification log` to this spec's `notes.md` (self-dogfood).
- [x] `bash .agent0/tools/doctor.sh` stays green (no regressions to harness health).

## Notes

_Anything that came up during execution that doesn't belong in plan.md but is useful for the PR description or future readers._
