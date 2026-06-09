# 179 — sdd-close-advisory — tasks

_Generated from `plan.md` on 2026-06-09. Work top-to-bottom. Check boxes as tasks complete._

## Implementation

- [x] 1. Create `.agent0/tools/sdd-close.sh`: arg parse (`[<spec-dir>]`, `--json`, `-h`, unknown→64); repo-root resolution (git then script-relative) mirroring `spec-verify.sh`. Read-only.
- [x] 2. In `sdd-close.sh`, implement per-spec finding computation for shipped/`shipped-partial` specs: `tasks-unchecked` (count `- [ ]` in tasks.md), `acceptance-unchecked` (`- [ ]` only under `## Acceptance criteria` in spec.md), `placeholders` (surviving `{{` in spec.md/tasks.md), `missing-closure` (no `**Closure:**` line). Target = single spec-dir arg, else all `docs/specs/*`.
- [x] 3. In `sdd-close.sh`, implement output: human summary by default, single JSON object with `--json`; exit `0` (no findings) / `1` (findings) / `64` (usage). `chmod +x`.
- [x] 4. Extend `.agent0/validators/run.sh` with the `sdd-close-advisory:` pass (after the spec-verify block): **opt-in via `**Closure:**`** — only shipped specs that declare a closure line are checked (unchecked tasks/acceptance + placeholders; `missing-closure` excluded). Emit one aggregated stderr line per such spec with ≥1 finding; never alter `ok`; opt-out `CLAUDE_VALIDATOR_SKIP_SDD_CLOSE=1`. (Pivoted from recency — see notes.md.)
- [x] 5. Create `.agent0/context/rules/sdd-close.md` (frontmatter `paths:`, lead + spec ref, H2s: the four findings / the tool / the advisory + opt-in-via-Closure noise model / opt-out / consumer-extension note).
- [x] 6. Add the managed-index entry to `CLAUDE.md` and `AGENTS.md` in the `## Spec verify advisory` style.
- [x] 7. Create `.agent0/tests/sdd-close/run-all.sh` + scenario scripts covering all acceptance scenarios over throwaway fixture spec dirs (tool: clean / unchecked-tasks / placeholder+missing-closure / `--json` parses / exit codes / placeholder backtick-strip; advisory: opt-in fires only with `**Closure:**`, legacy-without-closure silent).

## Verification

**Verify:** `bash .agent0/tests/sdd-close/run-all.sh`

- [x] All acceptance scenarios pass via `.agent0/tests/sdd-close/run-all.sh`.
- [x] `bash .agent0/tools/sdd-close.sh docs/specs/179-sdd-close-advisory` runs read-only and (once this spec is closed) exits 0 (self-dogfood).
- [x] `bash .agent0/tools/doctor.sh` stays green.

## Notes
